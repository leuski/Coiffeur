//
//  ALNode+model.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
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

+ (NSSet*)keyPathsForValuesAffectingAttributedDocumentation
{
	return [NSSet setWithObject:@"documentation"];
}

+ (NSSet*)keyPathsForValuesAffectingAttributedTitle
{
	return [NSSet setWithObject:@"title"];
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

- (NSUInteger)depth
{
	return self.parent ? 1+self.parent.depth : 0;
}

static NSAttributedString* as4s(NSString* s)
{
	if (!s) return nil;
	
	NSDictionary* attributes = @{
															 NSLeftMarginDocumentAttribute: @(0),
															 NSRightMarginDocumentAttribute : @(0),
															 NSTopMarginDocumentAttribute : @(0),
															 NSBottomMarginDocumentAttribute : @(0)
															 };
	//			 "font: 11px \"HelveticaNeue-Light\", \"Helvetica Neue Light\", \"Helvetica Neue\", Helvetica, sans-serif;\n"

	s = [@"<head><style>\n"
			 "* {\n"
			 "margin:0;\n"
			 "padding:0;\n"
			 "}\n"
			 "body {\n"
			 "font: 11px HelveticaNeue;\n"
			 "}\n"
			 "p {\n"
			 "margin-bottom:5px;\n"
			 "}</style></head><body>" stringByAppendingString:s];
	
	return [[NSAttributedString alloc] initWithHTML:[s dataUsingEncoding:NSUTF8StringEncoding]
															 documentAttributes:&attributes];
}

- (NSAttributedString*)attributedTitle
{
	return as4s(self.title);
}

- (NSAttributedString*)attributedDocumentation
{
	return as4s(self.documentation);
}

@end

@implementation ALRoot (model)

- (NSSet*)filteredChildren
{
	return self.children;
}


@end