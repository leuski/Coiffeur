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
static NSString* const AL_ClangFormatDocumentationFileName = @"ClangFormatStyleOptions";
static NSString* const AL_ClangFormatDocumentationFileExtension = @"rst";
static NSString* const AL_ClangFormatShowDefaultConfigArgument = @"-dump-config";
static NSString* const AL_ClangFormatStyleFlag = @"-style=file";
static NSString* const AL_ClangFormatSourceFileNameFormat = @"-assume-filename=sample.%@";
static NSString* const AL_ClangFormatStyleFileName = @".clang-format";
static NSString* const AL_ClangFormatPageGuideKey = @"ColumnLimit";
static NSString* const AL_ClangFormatSectionBegin = @"---";
static NSString* const AL_ClangFormatSectionEnd = @"...";
static NSString* const AL_ClangFormatComment = @"#";
#pragma clang diagnostic pop

static NSString* ALcfOptionsDocumentation = nil;
static NSString* ALcfDefaultValues        = nil;


@implementation ALClangFormatController

- (instancetype)initWithExecutableURL:(NSURL*)url
																error:(NSError**)outError
{
	if (self = [super initWithExecutableURL:url error:outError]) {

		NSError* error;
		
		if (!ALcfOptionsDocumentation) {
			ALcfOptionsDocumentation
							= [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:AL_ClangFormatDocumentationFileName withExtension:AL_ClangFormatDocumentationFileExtension]
																				 encoding:NSUTF8StringEncoding
																						error:&error];
		}

		if ([self readOptionsFromString:ALcfOptionsDocumentation]) {

			if (!ALcfDefaultValues) {
				ALcfDefaultValues = [self runExecutableWithArguments:@[AL_ClangFormatShowDefaultConfigArgument] workingDirectory:nil input:nil error:&error];
			}

			[self readValuesFromString:ALcfDefaultValues];
		}
		
		if (outError) *outError = error;
	}
	return self;
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
static NSString* cleanUpRST(NSString* rst)
{
	rst = [rst trim];
	rst = [rst stringByAppendingString:@"\n"];
	NSMutableString* mutableRST = [rst mutableCopy];

//	NSLog(@"%@", mutableRST);

	NSString* const nl = @"__NL__";
	NSString* const sp = @"__SP__";
	NSString* const par = @"__PAR__";

	// preserve all spacing inside \code ... \endcode
	NSRegularExpression*	lif = [NSRegularExpression regularExpressionWithPattern:@"\\\\code(.*?)\\\\endcode(\\s)"
																																			 options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
																																				 error:nil];
	
	while (YES) {
		NSTextCheckingResult* match = [lif firstMatchInString:mutableRST
																									options:0
																										range:NSMakeRange(0,
																														mutableRST.length)];
		if (!match) break;
		NSString* code = [mutableRST substringWithRange:[match rangeAtIndex:1]];
		code = [code stringByReplacingOccurrencesOfString:@"\n" withString:nl];
		code = [code stringByReplacingOccurrencesOfString:@" " withString:sp];
		NSString* end = [mutableRST substringWithRange:[match rangeAtIndex:2]];
		code = [code stringByAppendingString:end];
		[mutableRST replaceCharactersInRange:[match rangeAtIndex:0] withString:code];
	}

	// preserve double nl, breaks before * and - (list items)
	[mutableRST replaceOccurrencesOfString:@"\n\n"
															withString:par
																 options:0
																	 range:NSMakeRange(0, mutableRST.length)];
	[mutableRST replaceOccurrencesOfString:@"\n*"
															withString:[NSString stringWithFormat:@"%@*", nl]
																 options:0
																	 range:NSMakeRange(0, mutableRST.length)];
	[mutableRST replaceOccurrencesOfString:@"\n-"
															withString:[NSString stringWithFormat:@"%@-", nl]
																 options:0
																	 range:NSMakeRange(0, mutableRST.length)];

	// un-escape escaped characters
	NSRegularExpression*	esc = [NSRegularExpression regularExpressionWithPattern:@"\\\\(.)"
																																			 options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
																																				 error:nil];
	[esc replaceMatchesInString:mutableRST
											options:0
												range:NSMakeRange(0, mutableRST.length)
								 withTemplate:@"$1"];

	// wipe out remaining whitespaces as single space
	[mutableRST replaceOccurrencesOfString:@"\n"
															withString:@" "
																 options:0
																	 range:NSMakeRange(0, mutableRST.length)];
	NSRegularExpression*	wsp = [NSRegularExpression regularExpressionWithPattern:@"\\s\\s+"
																																			 options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
																																				 error:nil];
	[wsp replaceMatchesInString:mutableRST
											options:0
												range:NSMakeRange(0, mutableRST.length)
								 withTemplate:@" "];

	// restore saved spacing
	[mutableRST replaceOccurrencesOfString:nl
															withString:@"\n"
																 options:0
																	 range:NSMakeRange(0, mutableRST.length)];
	[mutableRST replaceOccurrencesOfString:sp
															withString:@" "
																 options:0
																	 range:NSMakeRange(0, mutableRST.length)];
	[mutableRST replaceOccurrencesOfString:par
															withString:@"\n\n"
																 options:0
																	 range:NSMakeRange(0, mutableRST.length)];

	// quote the emphasized words
	NSRegularExpression*	quot = [NSRegularExpression regularExpressionWithPattern:@"``(.*?)``"
																																			 options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
																																				 error:nil];
	[quot replaceMatchesInString:mutableRST
											 options:0
												 range:NSMakeRange(0, mutableRST.length)
									withTemplate:@"“$1”"];

//	NSLog(@"%@", mutableRST);
	return mutableRST;
}
#pragma clang diagnostic pop

- (BOOL)AL_readOptionsFromLineArray:(NSArray*)lines
{
	ALSection* section = [ALSection objectInContext:self.managedObjectContext];
	section.title = @"All Options";
	section.parent = self.root;
	
	ALOption* option;
	
	BOOL in_doc = NO;

	NSRegularExpression*	head = [NSRegularExpression regularExpressionWithPattern:@"^\\*\\*(.*?)\\*\\* \\(``(.*?)``\\)"
																																				options:NSRegularExpressionCaseInsensitive
																																					error:nil];

	NSRegularExpression*	item = [NSRegularExpression regularExpressionWithPattern:@"^(\\s*\\* )``.*\\(in configuration: ``(.*?)``\\)"
																																				options:NSRegularExpressionCaseInsensitive
																																					error:nil];

	BOOL in_title = NO;
	for (__strong NSString* line in lines) {
		if (!in_doc) {
			if ([line hasPrefix:@".. START_FORMAT_STYLE_OPTIONS"])
				in_doc = YES;
			continue;
		}
		
		if ([line hasPrefix:@".. END_FORMAT_STYLE_OPTIONS"]) {
			in_doc = NO;
			continue;
		}
	
//		NSString* trimmedLine = [line trim];
//		if (trimmedLine.length == 0)
//			line = trimmedLine;

		line = [line trim];
		
		NSTextCheckingResult* match;
		
		match = [head firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
		if (match) {
			if (option) {
				option.title = cleanUpRST(option.title);
				option.documentation = cleanUpRST(option.documentation);
			}
			
			option = [ALOption objectInContext:self.managedObjectContext];
			option.parent = section;
			option.leaf = YES;
			option.name = option.indexKey = [line substringWithRange:[match rangeAtIndex:1]];
			option.title = option.documentation = @"";
			in_title = YES;
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
		
		match = [item firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
		if (match) {
			NSString* token = [line substringWithRange:[match rangeAtIndex:2]];
			if ([token length] && option)
				option.type = [option.type stringByAppendingString:token separatedBy:ALNodeTypeSeparator];
			option.documentation = [option.documentation stringByAppendingFormat:@"%@``%@``", [line substringWithRange:[match rangeAtIndex:1]], token];
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

- (BOOL)AL_readValuesFromLineArray:(NSArray*)lines
{
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
	NSRegularExpression*	keyValue = [NSRegularExpression regularExpressionWithPattern:@"^\\s*(.*?):\\s*(\\S.*)"
																																				options:NSRegularExpressionCaseInsensitive
																																					error:nil];
#pragma clang diagnostic pop

	NSTextCheckingResult* match;

	for (__strong NSString* line in lines) {
		line = [line trim];
		if ([line hasPrefix:AL_ClangFormatComment]) continue;
		match = [keyValue firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
		if (match) {
			NSString* key = [line substringWithRange:[match rangeAtIndex:1]];
			NSString* value = [line substringWithRange:[match rangeAtIndex:2]];
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

- (BOOL)writeValuesToURL:(NSURL *)absoluteURL error:(NSError **)error
{
	NSMutableString*	data = [NSMutableString new];

  [data appendString:AL_ClangFormatSectionBegin];
  [data appendString:ALNewLine];

	for(ALOption* option in [[ALOption allObjectsInContext:self.managedObjectContext] sortedArrayUsingComparator:^NSComparisonResult(ALOption* obj1, ALOption* obj2) {
		return [obj1.indexKey compare:obj2.indexKey];
	}]) {
		if (!option.value) continue;
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
		[data appendFormat:@"%@: %@", option.indexKey, option.value];
#pragma clang diagnostic pop
    [data appendString:ALNewLine];
	};

  [data appendString:AL_ClangFormatSectionEnd];
  [data appendString:ALNewLine];
	
	return [data writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:error];
}

- (BOOL) format:(NSString*)input attributes:(NSDictionary*)attributes
completionBlock:(void (^)(NSString*, NSError*)) block
{
  NSString* workingDirectory = NSTemporaryDirectory();
  NSString* configPath = [workingDirectory stringByAppendingPathComponent:AL_ClangFormatStyleFileName];

  NSError* error;
  if (![self writeValuesToURL:[NSURL fileURLWithPath:configPath] error:&error]) {
    block(nil, error);
    return NO;
  }

  NSMutableArray* args = [NSMutableArray arrayWithArray: @[AL_ClangFormatStyleFlag]];
  if (attributes[ALFormatLanguage]) {
		ALLanguage* language = attributes[ALFormatLanguage];
		if (language.clangFormatID)
			[args addObject:[NSString stringWithFormat:AL_ClangFormatSourceFileNameFormat, language.defaultExtension]];
  }

  error = [self runExecutableWithArguments:args workingDirectory:workingDirectory input:input completionBlock:^(NSString* text, NSError* in_error) {
      [[NSFileManager defaultManager] removeItemAtPath:configPath error:nil];
      block(text, in_error);
  }];

  if (!error) return YES;

  [[NSFileManager defaultManager] removeItemAtPath:configPath error:nil];
  block(nil, error);
  return NO;
}

+ (BOOL)contentsIsValidInString:(NSString*)string error:(NSError**)outError
{

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
	NSRegularExpression*	keyValue = [NSRegularExpression regularExpressionWithPattern:@"^\\s*[a-zA-Z_]+\\s*:\\s*[^#\\s]"
																																						 options:NSRegularExpressionAnchorsMatchLines
																																							 error:nil];

  NSRegularExpression*	section = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"^%@", AL_ClangFormatSectionBegin]
                                                                             options:NSRegularExpressionAnchorsMatchLines
                                                                               error:nil];
#pragma clang diagnostic pop

  return (nil != [section firstMatchInString:string options:0 range:NSMakeRange(0, [string length])] &&
					nil != [keyValue firstMatchInString:string options:0 range:NSMakeRange(0, [string length])]);
}

- (NSUInteger)pageGuideColumn
{
	ALOption* option = [self optionWithKey:AL_ClangFormatPageGuideKey];
	if (option)
		return [option.value unsignedIntegerValue];
	return [super pageGuideColumn];
}


@end
