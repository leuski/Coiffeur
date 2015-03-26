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

@end
