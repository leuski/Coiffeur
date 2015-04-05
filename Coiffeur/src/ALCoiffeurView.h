//
//  ALCoiffeurView.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ALCoiffeurController;
@interface ALCoiffeurView : NSViewController
@property (nonatomic, weak) IBOutlet NSOutlineView*      optionsView;
@property (nonatomic, strong) IBOutlet NSTreeController* optionsController;
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedPropertyInspection"
@property (nonatomic, strong) NSArray* optionsSortDescriptors;
#pragma clang diagnostic pop
@property (nonatomic, weak) ALCoiffeurController* model;

- (instancetype)initWithModel:(ALCoiffeurController*)model bundle:(NSBundle*)bundle;
- (void)embedInView:(NSView*)container;

@end

