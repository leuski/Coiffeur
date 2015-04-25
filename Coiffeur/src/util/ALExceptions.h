//
//  ALExceptions.h
//  Coiffeur
//
//  Created by Anton Leuski on 4/6/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 This is a hack to handle ObjC exceptions in Swift. It will go away at some
 point when Swift figures out what to do with exceptions...
 */
@interface ALExceptions : NSObject
+ (void)try:(void(^)())try
			catch:(void(^)(NSException*))catch
		finally:(void(^)())finally;
@end
