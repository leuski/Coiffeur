//
//  NSString+commandLine.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (commandLine)
- (NSArray*)commandLineComponents;
- (NSString*)stringByAppendingString:(NSString *)aString separatedBy:(NSString*)delim;
- (NSString*)trim;
- (NSString*)trimComment;
- (NSRange)lineRangeForCharacterRange:(NSRange)range;
- (NSUInteger)lineCountForCharacterRange:(NSRange)range;
- (NSUInteger)unsignedIntegerValue;
@end
