//
//  ALMainWindowController.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ALMainWindowController : NSWindowController <NSOutlineViewDelegate>
@property (nonatomic, weak) IBOutlet NSOutlineView *optionsView;
@property (nonatomic, strong) IBOutlet NSTreeController *optionsController;
@property (nonatomic, strong) NSArray* optionsSortDescriptors;
@property (nonatomic, strong) NSString* exampleText;
@end
