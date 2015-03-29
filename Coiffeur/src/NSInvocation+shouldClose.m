//
//  NSInvocation+shouldClose.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/28/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "NSInvocation+shouldClose.h"

@implementation NSInvocation (shouldClose)
+ (NSInvocation*)invocationWithTarget:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector object:(id)object contextInfo:(void*)contextInfo
{
	if (![delegate respondsToSelector:shouldCloseSelector]) return nil;
	
	BOOL shouldClose = NO;
	NSMethodSignature* ms = [delegate methodSignatureForSelector:shouldCloseSelector];
	NSInvocation*	inv = [NSInvocation invocationWithMethodSignature:ms];
	[inv setTarget:delegate];
	[inv setSelector:shouldCloseSelector];
	[inv setArgument:&object atIndex:2];
	[inv setArgument:&shouldClose atIndex:3];
	[inv setArgument:&contextInfo atIndex:4];
	return inv;
}

- (void)invokeWithShouldClose:(BOOL)shouldClose
{
	[self setArgument:&shouldClose atIndex:3];
	[self invoke];
}

@end