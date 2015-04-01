//
//  NSInvocation+shouldClose.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/28/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSInvocation (shouldClose)
+ (NSInvocation*)invocationWithTarget:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector object:(id)object contextInfo:(void*)contextInfo;
- (void)invokeWithShouldClose:(BOOL)shouldClose;

@end

