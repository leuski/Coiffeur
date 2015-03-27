//
//  Document.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ALCoiffeurModelController;
@interface Document : NSPersistentDocument
@property (nonatomic, strong) ALCoiffeurModelController* model;

- (IBAction)uncrustify:(id)sender;
- (BOOL)readCodeFromURL:(NSURL*)url error:(NSError *__autoreleasing *)error;

@end
