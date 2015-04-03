//
//  Document.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

@import Cocoa;

@class ALCoiffeurController;

@interface Document : NSDocument
@property (nonatomic, strong) ALCoiffeurController* model;
@property (nonatomic, assign, readonly) NSUInteger pageGuideColumn;

+ (BOOL)contentsIsValidInString:(NSString*)string error:(NSError**)outError;
- (void)embedInView:(NSView*)container;

@end

@interface ALUncrustifyDocument : Document
@end

@interface ALClangFormatDocument : Document
@end