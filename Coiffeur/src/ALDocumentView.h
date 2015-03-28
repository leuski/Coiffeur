//
//  ALDocumentView.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/27/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ALDocumentView : NSViewController
@property (nonatomic, strong) NSString* fileType;
@property (nonatomic, strong) NSDocument* document;
@property (nonatomic, weak) IBOutlet NSView* containerView;
@property (nonatomic, weak) IBOutlet NSTextField *label;

- (IBAction)newDocument:(id)sender;

@end

