//
//  ALUncrustifyController.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALCoiffeurController.h"


@interface ALUncrustifyController : ALCoiffeurController

- (instancetype)initWithUncrustifyURL:(NSURL*)url moc:(NSManagedObjectContext*)moc error:(NSError**)outError;

@end

