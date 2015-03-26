//
//  ALNode+model.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALNode+model.h"

@implementation ALNode (model)

+ (NSSet*)keyPathsForValuesAffectingFilteredChildren
{
	return [NSSet setWithArray:@[ @"predicate", @"children" ] ];
}

+ (NSSet*)keyPathsForValuesAffectingPredicate
{
	return [NSSet setWithObject:@"parent.predicate"];
}

- (NSArray*)tokens
{
	return [self.type componentsSeparatedByString:@","];
}

- (NSSet*)filteredChildren
{
	NSPredicate* p = self.predicate;
	return p ? [self.children filteredSetUsingPredicate:p] : self.children;
}

- (NSPredicate*)predicate
{
	return self.parent.predicate;
}

@end
