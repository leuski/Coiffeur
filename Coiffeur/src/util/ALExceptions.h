//
//  ALExceptions.h
//  Coiffeur
//
//  Created by Anton Leuski on 4/6/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALExceptions : NSObject

+ (void)try:(void(^)())try catch:(void(^)(NSException*))catch finally:(void(^)())finally;
//+ (void)throwString:(NSString*)string;

@end
