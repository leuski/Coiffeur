//
//  ALOverviewScroller.h
//  Coiffeur
//
//  Created by Anton Leuski on 4/2/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ALOverviewRegion : NSObject
@property (nonatomic, assign) NSRange	lineRange;
@property (nonatomic, strong) NSColor* color;
+ (instancetype)overviewRegionWithLineRange:(NSRange)range color:(NSColor*)color;
@end

@interface ALOverviewScroller : NSScroller
@property (nonatomic, strong) NSArray* regions;
@end
