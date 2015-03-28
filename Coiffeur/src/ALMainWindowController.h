//
//  ALMainWindowController.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ALMainWindowController : NSWindowController <NSOutlineViewDelegate>
@property (nonatomic, strong) NSMutableArray* documentViews;

+ (ALMainWindowController*)sharedInstance;
- (void)addDocument:(NSDocument*)document;
- (void)setDocument:(NSDocument*)document atIndex:(NSUInteger)index;

@end
