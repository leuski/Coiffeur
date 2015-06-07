//
//  ALExceptions.h
//  Coiffeur
//
//  Created by Anton Leuski on 4/6/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
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
