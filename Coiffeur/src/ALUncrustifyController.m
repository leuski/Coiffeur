//
//  ALUncrustifyController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALUncrustifyController.h"
#import "NSString+commandLine.h"
#import "ALCoreData.h"
#import "ALLanguage.h"

#import "ALRoot.h"
#import "ALOption.h"
#import "ALSection.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
static NSString* const AL_UncrustifyShowDocumentationArgument = @"--show-config";
static NSString* const AL_UncrustifyShowDefaultConfigArgument = @"--update-config";
static NSString* const AL_UncrustifyQuietFlag = @"-q";
static NSString* const AL_UncrustifyConfigPathFlag   = @"-c";
static NSString* const AL_UncrustifyLanguageFlag     = @"-l";
static NSString* const AL_UncrustifyFragmentFlag     = @"--frag";
static NSString* const AL_UncrustifyPageGuideKey     = @"code_width";
static NSString* const AL_UncrustifyComment = @"#";
static NSString* const AL_UncrustifyNumberOptionType = @"number";
static NSString* const AL_UncrustifyDocumentType     = @"Uncrustify Style File";
static NSString* const AL_UncrustifyExecutableName   = @"uncrustify";
#pragma clang diagnostic pop

static NSString* ALOptionsDocumentation = nil;
static NSString* ALDefaultValues = nil;

@implementation ALUncrustifyController

+ (NSString*)documentType
{
  return AL_UncrustifyDocumentType;
}

- (instancetype)initWithExecutableURL:(NSURL*)url error:(NSError**)outError
{
  self = [super initWithExecutableURL:url error:outError];

  if (self) {
    if (outError) {
      *outError = nil;
    }

    if (!ALOptionsDocumentation) {
      ALOptionsDocumentation = [self runExecutableWithArguments:@[
                                  AL_UncrustifyShowDocumentationArgument]
                                               workingDirectory:nil
                                                          input:nil
                                                          error:outError];
    }

    if ([self readOptionsFromString:ALOptionsDocumentation]) {
      if (!ALDefaultValues) {
        ALDefaultValues = [self runExecutableWithArguments:@[
                             AL_UncrustifyShowDefaultConfigArgument]
                                          workingDirectory:nil
                                                     input:nil
                                                     error:outError];
      }

      [self readValuesFromString:ALDefaultValues];
    }
  }

  return self;
}

- (instancetype)initWithError:(NSError**)outError
{
  return [self initWithExecutableURL:[[NSBundle bundleForClass:[self class]]
                                      URLForAuxiliaryExecutable:
                                      AL_UncrustifyExecutableName]
                               error:outError];
}

typedef enum {
  ALNone, ALSectionHeader, ALOptionDescription
} _ALState;

- (void)AL_parseSection:(ALSection*)ioSection line:(NSString*)line
{
  line = [line stringByTrimmingPrefix:AL_UncrustifyComment];

  if ([line length]) {
    ioSection.title = [ioSection.title
                       stringByAppendingString:line
                                   separatedBy:ALSpace];
  }
}

- (void)AL_parseOption:(ALOption*)ioOption firstLine:(NSString*)line
{
  NSUInteger c = 0;

  for (NSString* v in[line componentsSeparatedByCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]])
  {
    ++c;

    if (c == 1) {
      ioOption.indexKey = ioOption.name = v;
    } else {
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"

      if ([v isEqualToString:@"{"] || [v isEqualToString:@"}"]) {
        continue;
      }

#pragma clang diagnostic pop

      ioOption.type = [ioOption.type stringByAppendingString:[v lowercaseString]];
    }
  }

  if ([ioOption.type isEqualToString:AL_UncrustifyNumberOptionType]) {
    ioOption.type = ALSignedOptionType;
  }
}

- (BOOL)readOptionsFromLineArray:(NSArray*)lines
{
  NSUInteger count = 0, optionCount = 0, sectionCount = 0;
  _ALState   state = ALNone;
  ALSection* section;
  ALOption*  option;

  for (__strong NSString* line in lines) {
    ++count;

    if (count == 1) {
      continue;
    }

    line = [line trim];

    if (![line length]) {
      state = ALNone;
      continue;
    }

    switch (state) {
    case ALNone:

      if ([line hasPrefix:AL_UncrustifyComment]) {
        ++sectionCount;
        state = ALSectionHeader;
        section = [ALSection objectInContext:self.managedObjectContext];
        section.title  = @"";
        section.parent = self.root;
        [self AL_parseSection:section line:line];
      } else {
        ++optionCount;
        state = ALOptionDescription;
        option = [ALOption objectInContext:self.managedObjectContext];
        option.leaf   = YES;
        option.parent = section;
        option.title  = option.documentation = option.type = @"";
        [self AL_parseOption:option firstLine:line];
      }

      break;

    case ALSectionHeader:

      if ([line hasPrefix:AL_UncrustifyComment]) {
        [self AL_parseSection:section line:line];
      }

      break;

    case ALOptionDescription:

      if ([line hasPrefix:AL_UncrustifyComment]) {
        line = [line stringByTrimmingPrefix:AL_UncrustifyComment];
      }

      if ([option.title length] == 0) {
        option.title = line;
      }

      option.documentation = [option.documentation
                              stringByAppendingString:line
                                          separatedBy:ALNewLine];
      break;
    }
  }

  for (NSUInteger i = 8; i >= 5; --i) {
    [self AL_cluster:i];
  }

  return YES;
}

- (void)AL_cluster:(NSUInteger)tokenLimit
{
  for (ALSection* section in self.root.children) {
    NSMutableDictionary* index = [NSMutableDictionary new];

    for (ALOption* option in section.children) {
      if (![option isKindOfClass:[ALOption class]]) {
        continue;
      }

      NSString* title  = option.title;
      NSArray*  tokens = [[title lowercaseString] componentsSeparatedByString:ALSpace];
      tokens = [tokens filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:
                                                    @"SELF != 'a'"]];
      tokens = [tokens filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:
                                                    @"SELF != 'the'"]];

      if (tokens.count < (tokenLimit + 1)) {
        continue;
      }

      tokens = [tokens subarrayWithRange:NSMakeRange(0, tokenLimit)];

      NSString* key = [tokens componentsJoinedByString:ALSpace];

      if (!index[key]) {
        index[key] = [NSMutableArray new];
      }

      [index[key] addObject:option];
    }

    //          NSUInteger limit = section.children.count;
    for (NSString* key in index) {
      NSArray* list = index[key];

      if (list.count < 5) {
        continue;
      }

//                      if (list.count < 0.15 * limit) continue;
//                      if (list.count < 0.15 * limit) continue;

      ALSubsection* subsection
        = [ALSubsection objectInContext:self.managedObjectContext];
      subsection.title  = [key stringByAppendingString:@"…"];
      subsection.parent = section;

      for (ALOption* option in list) {
        NSString* title  = option.title;
        NSArray*  tokens = [title componentsSeparatedByString:ALSpace];
        tokens = [tokens filteredArrayUsingPredicate:[NSPredicate
                                                      predicateWithFormat:
                                                      @"SELF != 'a'"]];
        tokens = [tokens filteredArrayUsingPredicate:[NSPredicate
                                                      predicateWithFormat:
                                                      @"SELF != 'the'"]];
        tokens = [tokens subarrayWithRange:NSMakeRange(tokenLimit
                                                      , tokens.count - tokenLimit)];
        option.title  = [tokens componentsJoinedByString:ALSpace];
        option.parent = subsection;
      }
    }
  }
}

- (BOOL)readValuesFromLineArray:(NSArray*)lines
{
  for (__strong NSString* line in lines) {
    line = [line trim];

    if (![line length]) {
      continue;
    }

    if ([line hasPrefix:AL_UncrustifyComment]) {
      continue;
    }

    NSRange comment = [line rangeOfString:AL_UncrustifyComment];

    if (comment.location != NSNotFound) {
      line = [line substringToIndex:comment.location];
    }

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"

    NSRange equal = [line rangeOfString:@"="];

    if (equal.location != NSNotFound) {
      NSString* prefix = [line substringToIndex:equal.location];
      NSString* suffix = [line substringFromIndex:equal.location + 1];
      line = [@[prefix, suffix] componentsJoinedByString:
              @" "];
    }

    NSArray* tokens = [line commandLineComponents];

    if (tokens.count == 0) {
      continue;
    }

    if (tokens.count == 1) {
      NSLog(@"Warning: wrong number of arguments %@", line);
      continue;
    }

    NSString* head = tokens[0];

    if ([head isEqualToString:@"type"]) {
    } else if ([head isEqualToString:@"define"]) {
    } else if ([head isEqualToString:@"macro-open"]) {
    } else if ([head isEqualToString:@"macro-close"]) {
    } else if ([head isEqualToString:@"macro-else"]) {
    } else if ([head isEqualToString:@"set"]) {
    } else if ([head isEqualToString:@"include"]) {
    } else if ([head isEqualToString:@"file_ext"]) {
    } else {
      ALOption* option = [self optionWithKey:head];

      if (option) {
        option.value = tokens[1];
      } else {
        NSLog(@"Warning: unknown token %@ on line %@", head, line);
      }
    }

#pragma clang diagnostic pop
  }

  return YES;
}

- (BOOL)writeValuesToURL:(NSURL*)absoluteURL error:(NSError**)error
{
  NSMutableString* data = [NSMutableString new];
  NSArray* allOptions   = [ALOption allObjectsInContext:self.managedObjectContext];
  allOptions = [allOptions sortedArrayUsingComparator:ALKeyComparator];

  for (ALOption* option in allOptions) {
    if (!option.value) {
      continue;
    }

    NSString* value = option.value;

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"

    if ([option.type isEqualToString:ALStringOptionType]) {
      value = [NSString stringWithFormat:@"\"%@\"", value];
    }

    [data appendFormat:@"%@ = %@", option.indexKey, value];
#pragma clang diagnostic pop

    [data appendString:ALNewLine];
  }

  return [data writeToURL:absoluteURL
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:error];
}

- (BOOL)   format:(NSString*)input
       attributes:(NSDictionary*)attributes
  completionBlock:(void (^)(NSString*, NSError*))block
{
  NSString* workingDirectory = NSTemporaryDirectory();
  NSString* configPath
    = [workingDirectory stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];

  NSError* error;

  if (![self writeValuesToURL:[NSURL fileURLWithPath:configPath] error:&error]) {
    block(nil, error);
    return NO;
  }

  NSMutableArray* args
    = [NSMutableArray arrayWithArray:@[AL_UncrustifyQuietFlag, AL_UncrustifyConfigPathFlag,
                                       configPath]];

  if (attributes[ALFormatLanguage]) {
    ALLanguage* language = attributes[ALFormatLanguage];

    if (language.uncrustifyID) {
      [args addObject:AL_UncrustifyLanguageFlag];
      [args addObject:language.uncrustifyID];
    }
  }

  if ([attributes[ALFormatFragment] boolValue]) {
    [args addObject:AL_UncrustifyFragmentFlag];
  }

  void (^complete)(NSString*, NSError*) = ^(NSString* text, NSError* in_error) {
    [[NSFileManager defaultManager] removeItemAtPath:configPath error:nil];
    block(text, in_error);
  };

  error = [self runExecutableWithArguments:args
                          workingDirectory:workingDirectory
                                     input:input
                           completionBlock:complete];

  if (!error) {
    return YES;
  }

  complete(nil, error);
  return NO;
}

+ (BOOL)contentsIsValidInString:(NSString*)string error:(NSError**)outError
{
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
  NSRegularExpression* keyValue
    = [NSRegularExpression aml_regularExpressionWithPattern:@"^\\s*[a-zA-Z_]+\\s*=\\s*[^#\\s]"];
#pragma clang diagnostic pop

  return nil != [keyValue firstMatchInString:string];
}

- (NSUInteger)pageGuideColumn
{
  ALOption* option = [self optionWithKey:AL_UncrustifyPageGuideKey];

  if (option) {
    return [option.value unsignedIntegerValue];
  }

  return [super pageGuideColumn];
}

@end

