//
//  ALOption.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ALNode.h"


@interface ALOption : ALNode

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * value;

@end
