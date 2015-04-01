//
//  Document.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALDocument.h"

@class ALCoiffeurController;

@interface Document : ALDocument
@property (nonatomic, strong) ALCoiffeurController* model;

+ (BOOL)contentsIsValidInString:(NSString*)string error:(NSError**)outError;
@end

@interface ALUncrustifyDocument : Document
@end

@interface ALClangFormatDocument : Document
@end