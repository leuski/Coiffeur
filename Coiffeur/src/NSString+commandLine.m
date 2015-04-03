//
//  NSString+commandLine.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "NSString+commandLine.h"

@implementation NSString (commandLine)

- (NSArray*)commandLineComponents
{
	NSMutableArray*	array = [NSMutableArray new];
	unichar cur_quote    = 0;
	BOOL in_backslash = NO;
	BOOL in_arg       = NO;
	NSMutableString* target = nil;
	
	NSUInteger len = [self length];
	unichar buffer[len+1];
	
	[self getCharacters:buffer range:NSMakeRange(0, len)];
	
	NSCharacterSet* wss = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	for(int i = 0; i < len; ++i) {
		unichar ch = buffer[i];
		BOOL is_space = [wss characterIsMember:ch];
		
		if (!in_arg) {
			if (is_space) continue;
			in_arg = YES;
			target = [NSMutableString new];
			[array addObject:target];
		}
		
		if (in_backslash) {
			in_backslash = NO;
			[target appendFormat:@"%C", ch];
		} else if (ch == '\\') {
			in_backslash = YES;
		} else if (ch == cur_quote) {
			cur_quote = 0;
		} else if ((ch == '\'') || (ch == '"') || (ch == '`')) {
			cur_quote = ch;
		} else if (cur_quote != 0) {
			[target appendFormat:@"%C", ch];
		} else if (is_space) {
			in_arg = NO;
		} else {
			[target appendFormat:@"%C", ch];
		}
	}
	
	return array;
}

- (NSString*)stringByAppendingString:(NSString *)aString separatedBy:(NSString*)delim
{
	NSString* result = self;
	if ([result length]) {
		result = [result stringByAppendingString:delim];
	}
	return [result stringByAppendingString:aString];
}

static NSCharacterSet* AL_WS_SET = nil;

- (NSString*)trim
{
	if (!AL_WS_SET) AL_WS_SET = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	return [self stringByTrimmingCharactersInSet:AL_WS_SET];
}

- (NSString*)trimComment
{
	NSString* result = self;
	result = [result trim];
	while ([result hasPrefix:@"#"]) {
		result = [result substringFromIndex:1];
		result = [result trim];
	}
	return result;
}

- (NSRange)lineRangeForCharacterRange:(NSRange)range
{
	NSUInteger numberOfLines, index, stringLength = [self length];
	NSInteger lastCharacter = range.location+range.length-1;
	NSRange result = NSMakeRange(NSNotFound, 0);
	
	for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++) {
		NSUInteger nextIndex = NSMaxRange([self lineRangeForRange:NSMakeRange(index, 0)]);
		if (index <= range.location && range.location < nextIndex) {
			result.location = numberOfLines;
			result.length = 1;
			if (lastCharacter <= 0) break;
		}
		if (index <= lastCharacter && lastCharacter < nextIndex) {
			result.length = numberOfLines - result.location + 1;
			break;
		}
		index = nextIndex;
	}
	return result;
}

- (NSUInteger)lineCountForCharacterRange:(NSRange)range
{
	NSUInteger stringLength = [self length];
	NSInteger lastCharacter = range.location+range.length-1;
	if (lastCharacter < 0) return 0;

	for (NSUInteger index = range.location, numberOfLines = 0; index < stringLength; numberOfLines++) {
		NSUInteger nextIndex = NSMaxRange([self lineRangeForRange:NSMakeRange(index, 0)]);
		if (index <= lastCharacter && lastCharacter < nextIndex) {
			return numberOfLines;
		}
		index = nextIndex;
	}
	return 0;
}

@end
