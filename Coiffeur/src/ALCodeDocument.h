//
//  ALCodeDocument.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/27/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALDocument.h"

@interface ALCodeDocument : ALDocument
@property (nonatomic, strong) NSString* string;
@property (nonatomic, strong) NSString* language;

- (IBAction)changeLanguage:(id)sender;
@end
