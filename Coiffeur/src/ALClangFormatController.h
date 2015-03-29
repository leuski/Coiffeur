//
//  ALClangFormatController.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/28/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALCoiffeurController.h"

@interface ALClangFormatController : ALCoiffeurController
- (instancetype)initWithExecutableURL:(NSURL*)url moc:(NSManagedObjectContext*)moc error:(NSError**)outError;

@end
