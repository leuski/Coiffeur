//
//  ALDocumentView.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/27/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ALDocumentView : NSViewController
@property (nonatomic, strong) NSArray*       allowedFileTypes;
@property (nonatomic, strong) NSArray*       knownSampleURLs;
@property (nonatomic, weak) IBOutlet NSView* containerView;

@end

