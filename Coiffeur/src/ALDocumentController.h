//
//  ALDocumentController.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/30/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ALDocumentController : NSDocumentController
- (id)openUntitledDocumentOfType:(NSString*)type
                         display:(BOOL)displayDocument
                           error:(NSError**)outError;
@end

