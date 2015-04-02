//
//  ALMainWindowController.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

@import Cocoa;

@interface ALMainWindowController : NSWindowController <NSOutlineViewDelegate>
- (BOOL)loadSourceFormURL:(NSURL*)url error:(NSError**)outError;
- (IBAction)changeLanguage:(NSMenuItem *)anItem;

@end
