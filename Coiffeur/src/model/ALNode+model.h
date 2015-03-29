//
//  ALNode+model.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALNode.h"
#import "ALRoot.h"

@interface ALNode (model)
@property (nonatomic, strong, readonly) NSPredicate* predicate;
@property (nonatomic, strong, readonly) NSArray* tokens;
@property (nonatomic, strong, readonly) NSSet* filteredChildren;
@property (nonatomic, assign, readonly) NSUInteger depth;
@property (nonatomic, strong, readonly) NSAttributedString* attributedTitle;
@property (nonatomic, strong, readonly) NSAttributedString* attributedDocumentation;
@end

