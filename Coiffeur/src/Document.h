//
//  Document.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ALRoot;

@interface Document : NSPersistentDocument
@property (nonatomic, strong) ALRoot* root;

- (IBAction)uncrustify:(id)sender;

@end
