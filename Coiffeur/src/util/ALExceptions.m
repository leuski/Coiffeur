//
//  ALExceptions.m
//  Coiffeur
//
//  Created by Anton Leuski on 4/6/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALExceptions.h"

@implementation ALExceptions

+ (void)try:(void(^)())try catch:(void(^)(NSException*))catch finally:(void(^)())finally
{
  @try {
    if (try) try();
  } @catch (NSException* ex) {
    if (catch) catch(ex);
  } @finally {
    if (finally) finally();
  }
}

@end
