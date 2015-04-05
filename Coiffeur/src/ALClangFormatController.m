//
//  ALClangFormatController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/28/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALClangFormatController.h"
#import "NSString+commandLine.h"
#import "ALCoreData.h"
#import "ALLanguage.h"
#import "ALRoot.h"
#import "ALOption.h"
#import "ALSection.h"
#import "ALNode+model.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
static NSString* const AL_ClangFormatDocumentationFileName      = @"ClangFormatStyleOptions";
static NSString* const AL_ClangFormatDocumentationFileExtension = @"rst";
static NSString* const AL_ClangFormatShowDefaultConfigArgument  = @"-dump-config";
static NSString* const AL_ClangFormatStyleFlag = @"-style=file";
static NSString* const AL_ClangFormatSourceFileNameFormat       = @"-assume-filename=sample.%@";
static NSString* const AL_ClangFormatStyleFileName  = @".clang-format";
static NSString* const AL_ClangFormatPageGuideKey   = @"ColumnLimit";
static NSString* const AL_ClangFormatSectionBegin   = @"---";
static NSString* const AL_ClangFormatSectionEnd     = @"...";
static NSString* const AL_ClangFormatComment        = @"#";
static NSString* const AL_ClangFormatDocumentType   = @"Clang-Format Style File";
static NSString* const AL_ClangFormatExecutableName = @"clang-format";

#pragma clang diagnostic pop

static NSString* ALcfOptionsDocumentation = nil;
static NSString* ALcfDefaultValues = nil;

@implementation ALClangFormatController

+ (NSString*)documentType
{
  return AL_ClangFormatDocumentType;
}

- (instancetype)initWithExecutableURL:(NSURL*)url
                                error:(NSError**)outError
{
  if (self = [super initWithExecutableURL:url error:outError]) {
    NSError* error;

    if (!ALcfOptionsDocumentation) {
      NSBundle* bundle = [NSBundle bundleForClass:[self class]];
      NSURL*    docURL = [bundle URLForResource:AL_ClangFormatDocumentationFileName
                                  withExtension:AL_ClangFormatDocumentationFileExtension];

      ALcfOptionsDocumentation = [NSString stringWithContentsOfURL:docURL
                                                          encoding:NSUTF8StringEncoding
                                                             error:&error];
    }

    if ([self readOptionsFromString:ALcfOptionsDocumentation]) {
      if (!ALcfDefaultValues) {
        NSArray* arg = @[AL_ClangFormatShowDefaultConfigArgument];
        ALcfDefaultValues = [self runExecutableWithArguments:arg
                                            workingDirectory:nil
                                                       input:nil
                                                       error:&error];
      }

      [self readValuesFromString:ALcfDefaultValues];
    }

    if (outError) {
      *outError = error;
    }
  }

  return self;
}

- (instancetype)initWithError:(NSError**)outError
{
  return [self initWithExecutableURL:[[NSBundle
                                       bundleForClass:[self class]]
                                      URLForAuxiliaryExecutable:AL_ClangFormatExecutableName]
                               error:outError];
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
static NSString*
cleanUpRST(NSString* rst)
{
  rst = [rst trim];
  rst = [rst stringByAppendingString:@"\n"];
  NSMutableString* mutableRST = [rst mutableCopy];

//      NSLog(@"%@", mutableRST);

  NSString* const nl  = @"__NL__";
  NSString* const sp  = @"__SP__";
  NSString* const par = @"__PAR__";

  // preserve all spacing inside \code ... \endcode
  NSRegularExpression* lif
    = [NSRegularExpression ci_dmls_regularExpressionWithPattern:@"\\\\code(.*?)\\\\endcode(\\s)"];

  while (YES) {
    NSTextCheckingResult* match = [lif firstMatchInString:mutableRST];

    if (!match) {
      break;
    }

    NSString* code = [mutableRST substringWithRange:[match rangeAtIndex:1]];
    code = [code stringByReplacingOccurrencesOfString:@"\n" withString:nl];
    code = [code stringByReplacingOccurrencesOfString:@" " withString:sp];
    NSString* end = [mutableRST substringWithRange:[match rangeAtIndex:2]];
    code = [code stringByAppendingString:end];
    [mutableRST replaceCharactersInRange:[
       match rangeAtIndex:0]
                              withString:
     code];
  }

  // preserve double nl, breaks before * and - (list items)
  [mutableRST replaceOccurrencesOfString:@"\n\n" withString:par];
  [mutableRST replaceOccurrencesOfString:@"\n*" withString:[NSString stringWithFormat:@"%@*", nl]];
  [mutableRST replaceOccurrencesOfString:@"\n-" withString:[NSString stringWithFormat:@"%@-", nl]];

  // un-escape escaped characters
  NSRegularExpression* esc = [NSRegularExpression ci_dmls_regularExpressionWithPattern:@"\\\\(.)"];

  [esc replaceMatchesInString:mutableRST
                      options:0
                        range:NSMakeRange(0, mutableRST.length)
                 withTemplate:@"$1"];

  // wipe out remaining whitespaces as single space
  [mutableRST replaceOccurrencesOfString:@"\n" withString:@" "];
  NSRegularExpression* wsp = [NSRegularExpression ci_dmls_regularExpressionWithPattern:@"\\s\\s+"];
  [wsp replaceMatchesInString:mutableRST
                      options:0
                        range:NSMakeRange(0, mutableRST.length)
                 withTemplate:@" "];

  // restore saved spacing
  [mutableRST replaceOccurrencesOfString:nl withString:@"\n"];
  [mutableRST replaceOccurrencesOfString:sp withString:@" "];
  [mutableRST replaceOccurrencesOfString:par withString:@"\n\n"];

  // quote the emphasized words
  NSRegularExpression* quot
    = [NSRegularExpression ci_dmls_regularExpressionWithPattern:@"``(.*?)``"];
  [quot replaceMatchesInString:mutableRST
                       options:0
                         range:NSMakeRange(0, mutableRST.length)
                  withTemplate:@"“$1”"];

//      NSLog(@"%@", mutableRST);
  return mutableRST;
}

#pragma clang diagnostic pop

- (BOOL)readOptionsFromLineArray:(NSArray*)lines
{
  ALSection* section = [ALSection objectInContext:self.managedObjectContext];

  section.title  = @"All Options";
  section.parent = self.root;

  ALOption* option;

  BOOL      in_doc = NO;

  NSRegularExpression* head
    = [NSRegularExpression ci_regularExpressionWithPattern:@"^\\*\\*(.*?)\\*\\* \\(``(.*?)``\\)"];
  NSRegularExpression* item
    = [NSRegularExpression ci_regularExpressionWithPattern:
       @"^(\\s*\\* )``.*\\(in configuration: ``(.*?)``\\)"
      ];

  BOOL in_title = NO;

  for (__strong NSString* line in lines) {
    if (!in_doc) {
      if ([line hasPrefix:@".. START_FORMAT_STYLE_OPTIONS"]) {
        in_doc = YES;
      }

      continue;
    }

    if ([line hasPrefix:@".. END_FORMAT_STYLE_OPTIONS"]) {
      in_doc = NO;
      continue;
    }

//              NSString* trimmedLine = [line trim];
//              if (trimmedLine.length == 0)
//                      line = trimmedLine;

    line = [line trim];

    NSTextCheckingResult* match;

    match = [head firstMatchInString:line];

    if (match) {
      if (option) {
        option.title = cleanUpRST(option.title);
        option.documentation = cleanUpRST(option.documentation);
      }

      option = [ALOption objectInContext:self.managedObjectContext];
      option.parent           = section;
      option.leaf             = YES;
      option.name             = option.indexKey
                              = [line substringWithRange:[match rangeAtIndex:1]];
      option.title            = option.documentation = @"";
      in_title                = YES;
      NSString* type = [line substringWithRange:[match rangeAtIndex:2]];

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"

      if ([type isEqualToString:@"bool"]) {
        option.type = @"false,true";
      } else if ([type isEqualToString:@"unsigned"]) {
        option.type = ALUnsignedOptionType;
      } else if ([type isEqualToString:@"int"]) {
        option.type = ALSignedOptionType;
      } else if ([type isEqualToString:@"std::string"]) {
        option.type = ALStringOptionType;
      } else if ([type isEqualToString:@"std::vector<std::string>"]) {
        option.type = ALStringOptionType;
      } else {
        option.type = @"";
      }

#pragma clang diagnostic pop

      continue;
    }

    match = [item firstMatchInString:line];

    if (match) {
      NSString* token = [line substringWithRange:[match rangeAtIndex:2]];

      if ([token length] && option) {
        option.type = [option.type
                       stringByAppendingString:token
                                   separatedBy:ALNodeTypeSeparator];
      }

      NSString* prefix = [line substringWithRange:[match rangeAtIndex:1]];
      option.documentation
        = [option.documentation stringByAppendingFormat:@"%@``%@``", prefix, token];
      option.documentation = [option.documentation stringByAppendingString:ALNewLine];
      continue;
    }

    if (line.length == 0) {
      in_title = NO;
    }

    if (in_title) {
      option.title = [option.title stringByAppendingString:line separatedBy:ALSpace];
    }

    option.documentation = [option.documentation stringByAppendingString:line];
    option.documentation = [option.documentation stringByAppendingString:ALNewLine];
  }

  if (option) {
    option.title = cleanUpRST(option.title);
    option.documentation = cleanUpRST(option.documentation);
  }

  return YES;
}

- (BOOL)readValuesFromLineArray:(NSArray*)lines
{
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
  NSRegularExpression* keyValue
    = [NSRegularExpression ci_regularExpressionWithPattern:@"^\\s*(.*?):\\s*(\\S.*)"];
#pragma clang diagnostic pop

  NSTextCheckingResult* match;

  for (__strong NSString* line in lines) {
    line = [line trim];

    if ([line hasPrefix:AL_ClangFormatComment]) {
      continue;
    }

    match = [keyValue firstMatchInString:line];

    if (match) {
      NSString* key    = [line substringWithRange:[match rangeAtIndex:1]];
      NSString* value  = [line substringWithRange:[match rangeAtIndex:2]];
      ALOption* option = [self optionWithKey:key];

      if (option) {
        option.value = value;
      } else {
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
        NSLog(@"Warning: unknown token %@ on line %@", key, line);
#pragma clang diagnostic pop
      }
    }
  }

  return YES;
}

- (BOOL)writeValuesToURL:(NSURL*)absoluteURL error:(NSError**)error
{
  NSMutableString* data = [NSMutableString new];

  [data appendString:AL_ClangFormatSectionBegin];
  [data appendString:ALNewLine];

  NSArray* allOptions = [ALOption allObjectsInContext:self.managedObjectContext];
  allOptions = [allOptions sortedArrayUsingComparator:ALKeyComparator];

  for (ALOption* option in allOptions) {
    if (!option.value) {
      continue;
    }

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
    [data appendFormat:@"%@: %@", option.indexKey, option.value];
#pragma clang diagnostic pop
    [data appendString:ALNewLine];
  }

  [data appendString:AL_ClangFormatSectionEnd];
  [data appendString:ALNewLine];

  return [data writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:error];
}

- (BOOL)   format:(NSString*)input attributes:(NSDictionary*)attributes
  completionBlock:(void (^)(NSString*, NSError*))block
{
  NSString* workingDirectory = NSTemporaryDirectory();
  NSString* configPath
    = [workingDirectory stringByAppendingPathComponent:AL_ClangFormatStyleFileName];

  NSError* error;

  if (![self writeValuesToURL:[NSURL fileURLWithPath:configPath] error:&error]) {
    block(nil, error);
    return NO;
  }

  NSMutableArray* args = [NSMutableArray arrayWithArray:@[AL_ClangFormatStyleFlag]];

  if (attributes[ALFormatLanguage]) {
    ALLanguage* language = attributes[ALFormatLanguage];

    if (language.clangFormatID) {
      [args addObject:[NSString stringWithFormat:AL_ClangFormatSourceFileNameFormat
                       , language.defaultExtension]];
    }
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
    = [NSRegularExpression aml_regularExpressionWithPattern:@"^\\s*[a-zA-Z_]+\\s*:\\s*[^#\\s]"];

  NSString* sectionRE = [NSString stringWithFormat:@"^%@", AL_ClangFormatSectionBegin];
  NSRegularExpression* section = [NSRegularExpression aml_regularExpressionWithPattern:sectionRE];
#pragma clang diagnostic pop

  return nil != [section firstMatchInString:string]
         && nil != [keyValue firstMatchInString:string];
}

- (NSUInteger)pageGuideColumn
{
  ALOption* option = [self optionWithKey:AL_ClangFormatPageGuideKey];

  if (option) {
    return [option.value unsignedIntegerValue];
  }

  return [super pageGuideColumn];
}

@end

