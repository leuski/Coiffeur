//
//  ALMainWindowController.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ALDocumentView;
@interface ALMainWindowController : NSWindowController <NSOutlineViewDelegate>
@property (nonatomic, strong) NSMutableArray* documentViews;

+ (ALMainWindowController*)sharedInstance;
- (void)addDocument:(NSDocument*)document;
- (void)displayDocument:(NSDocument*)document inView:(ALDocumentView*)documentView;
- (void)removeDocument:(NSDocument*)document;

@end
