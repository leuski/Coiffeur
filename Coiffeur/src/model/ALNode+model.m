//
//  ALNode+model.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ALNode+model.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
NSString* const ALNodeTitleKey = @"title";
NSString* const ALNodeTypeSeparator = @",";
static NSString* const ALNodeDocumentationKey = @"documentation";
static NSString* const ALNodeChildrenKey = @"children";
static NSString* const ALNodePredicateKey = @"predicate";
static NSString* const AL_ParentPredicateKey = @"parent.predicate";
#pragma clang diagnostic pop

@implementation ALNode (model)

+ (NSSet*)keyPathsForValuesAffectingFilteredChildren
{
	return [NSSet setWithArray:@[ALNodePredicateKey, ALNodeChildrenKey]];
}

+ (NSSet*)keyPathsForValuesAffectingPredicate
{
	return [NSSet setWithObject:AL_ParentPredicateKey];
}

+ (NSSet*)keyPathsForValuesAffectingAttributedDocumentation
{
	return [NSSet setWithObject:ALNodeDocumentationKey];
}

+ (NSSet*)keyPathsForValuesAffectingAttributedTitle
{
	return [NSSet setWithObject:ALNodeTitleKey];
}

- (NSArray*)tokens
{
	return [self.type componentsSeparatedByString:ALNodeTypeSeparator];
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

- (NSUInteger)depth
{
	return self.parent ? 1+self.parent.depth : 0;
}

@end

@implementation ALRoot (model)

- (NSSet*)filteredChildren
{
	return self.children;
}


@end