//
//  ALCoiffeurView.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ALCoiffeurModelController;
@interface ALCoiffeurView : NSViewController
@property (nonatomic, weak) IBOutlet NSOutlineView *optionsView;
@property (nonatomic, strong) IBOutlet NSTreeController *optionsController;
@property (nonatomic, strong) NSArray* optionsSortDescriptors;
@property (nonatomic, weak) ALCoiffeurModelController* model;

- (instancetype)initWithModel:(ALCoiffeurModelController*)model bundle:(NSBundle*)bundle;
- (void)embedInView:(NSView*)container;

@end
