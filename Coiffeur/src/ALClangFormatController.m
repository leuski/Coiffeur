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

#import "ALRoot.h"
#import "ALOption.h"
#import "ALSection.h"

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
							= [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:[self class]]
							URLForResource:@"ClangFormatStyleOptions" withExtension:@"rst"]
																				 encoding:NSUTF8StringEncoding
																						error:&error];
		}

		if ([self readOptionsFromString:ALcfOptionsDocumentation]) {

			if (!ALcfDefaultValues) {
				ALcfDefaultValues = [self runExecutable:@[@"-dump-config"]
																				 text:nil
																				error:&error];
			}

			[self readValuesFromString:ALcfDefaultValues];
		}
		
		if (outError) *outError = error;
	}
	return self;
}

static NSString* cleanUpRST(NSString* rst)
{
	rst = [rst trim];
	rst = [rst stringByAppendingString:@"\n"];
	NSMutableString* mutableRST = [rst mutableCopy];

//	NSLog(@"%@", mutableRST);

	NSString* nl = @"__NL__";
	NSString* sp = @"__SP__";
	NSString* par = @"__PAR__";

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
			option.name = option.key = [line substringWithRange:[match rangeAtIndex:1]];
			option.title = option.documentation = @"";
			in_title = YES;
			NSString* type = [line substringWithRange:[match rangeAtIndex:2]];
			if ([type isEqualToString:@"bool"]) {
				option.type = @"false,true";
			} else if ([type isEqualToString:@"unsigned"]) {
				option.type = @"number";
			} else if ([type isEqualToString:@"int"]) {
				option.type = @"number";
			} else if ([type isEqualToString:@"std::string"]) {
				option.type = @"string";
			} else if ([type isEqualToString:@"std::vector<std::string>"]) {
				option.type = @"string";
			} else {
				option.type = @"";
			}
			continue;
		}
		
		match = [item firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
		if (match) {
			NSString* token = [line substringWithRange:[match rangeAtIndex:2]];
			if ([token length] && option)
				option.type = [option.type stringByAppendingString:token separatedBy:@","];
			option.documentation = [option.documentation stringByAppendingFormat:@"%@``%@``\n", [line substringWithRange:[match rangeAtIndex:1]], token];
			continue;
		}
		
		if (line.length == 0) {
			in_title = NO;
		}
		
		if (in_title) {
			option.title = [option.title stringByAppendingString:line separatedBy:@" "];
		}
		
		option.documentation = [option.documentation stringByAppendingFormat:@"%@\n", line];
	}

	if (option) {
		option.title = cleanUpRST(option.title);
		option.documentation = cleanUpRST(option.documentation);
	}

	return YES;
}

- (BOOL)AL_readValuesFromLineArray:(NSArray*)lines
{
	NSRegularExpression*	keyValue = [NSRegularExpression regularExpressionWithPattern:@"^\\s*(.*?):\\s*(\\S.*)"
																																				options:NSRegularExpressionCaseInsensitive
																																					error:nil];

	NSTextCheckingResult* match;

	for (__strong NSString* line in lines) {
		line = [line trim];
		if ([line hasPrefix:@"#"]) continue;
		match = [keyValue firstMatchInString:line options:0 range:NSMakeRange(0, [line length])];
		if (match) {
			NSString* key = [line substringWithRange:[match rangeAtIndex:1]];
			NSString* value = [line substringWithRange:[match rangeAtIndex:2]];
			ALOption* option = [ALOption firstObjectInContext:self.managedObjectContext
																					withPredicate:[NSPredicate predicateWithFormat:@"key = %@", key]
																									error:nil];
			if (option) {
				option.value = value;
			} else {
				NSLog(@"Warning: unknown token %@ on line %@", key, line);
			}
			
		}
	}

	return YES;
}

- (BOOL)writeValuesToURL:(NSURL *)absoluteURL error:(NSError **)error
{
	NSMutableString*	data = [NSMutableString new];

	[data appendString:@"---\n"];
	for(ALOption* option in [[ALOption allObjectsInContext:self.managedObjectContext] sortedArrayUsingComparator:^NSComparisonResult(ALOption* obj1, ALOption* obj2) {
		return [obj1.key compare:obj2.key];
	}]) {
		if (!option.value) continue;
		[data appendFormat:@"%@: %@\n", option.key, option.value];
	};
	[data appendString:@"...\n"];
	
	return [data writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:error];
}

+ (BOOL)contentsIsValidInString:(NSString*)string error:(NSError**)outError
{
	NSRegularExpression*	keyValue = [NSRegularExpression regularExpressionWithPattern:@"^\\s*[a-zA-Z_]+\\s*:\\s*[^#\\s]"
																																						 options:NSRegularExpressionAnchorsMatchLines
																																							 error:nil];

	return (([string hasPrefix:@"---"] || [string rangeOfString:@"\n---"].location != NSNotFound) &&
					nil != [keyValue firstMatchInString:string options:0 range:NSMakeRange(0, [string length])]);
}

@end
