//
//  ALDocument.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/31/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSDocument (shouldClose)
- (void)canCloseWithBlock:(void (^)(BOOL))block;
@end

@interface ALDocument : NSDocument
@end

