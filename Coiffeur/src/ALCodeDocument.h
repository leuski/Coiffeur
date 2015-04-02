//
//  ALCodeDocument.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/27/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

@import Cocoa;

@protocol ALCodeDocument <NSObject>
@property (nonatomic, strong) NSString* string;
@property (nonatomic, strong) NSString* language;
@property (nonatomic, strong) NSURL* fileURL;
@end
