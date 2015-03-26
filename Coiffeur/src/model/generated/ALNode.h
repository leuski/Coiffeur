//
//  ALNode.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ALNode;

@interface ALNode : NSManagedObject

@property (nonatomic, retain) NSString * documentation;
@property (nonatomic) BOOL leaf;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) ALNode *parent;
@property (nonatomic, retain) NSSet *children;
@end

@interface ALNode (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(ALNode *)value;
- (void)removeChildrenObject:(ALNode *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

@end
