//
//  ALRoot.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ALNode.h"


@interface ALRoot : ALNode
@property (nonatomic, strong) NSPredicate* predicate;
@end
