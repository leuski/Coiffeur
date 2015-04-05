//
//  ALCodeDocument.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/27/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

@import Cocoa;

@class  ALLanguage;
@protocol ALCodeDocument<NSObject>
@property (nonatomic, strong) NSString*   string;
@property (nonatomic, strong) ALLanguage* language;
@property (nonatomic, strong) NSURL*      fileURL;
@end

