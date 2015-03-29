//
//  Document.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ALCoiffeurController;

@interface Document : NSPersistentDocument
@property (nonatomic, strong) ALCoiffeurController* model;
@end

@interface ALUncrustifyDocument : Document
@end

@interface ALClangFormatDocument : Document
@end