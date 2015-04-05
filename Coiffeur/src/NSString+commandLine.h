//
//  NSString+commandLine.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (commandLine)
- (NSArray*) commandLineComponents;
- (NSString*)stringByAppendingString:(NSString*)aString separatedBy:(NSString*)delimiter;
- (NSString*) trim;

- (NSString*)stringByTrimmingPrefix:(NSString*)prefix;
- (NSRange)lineRangeForCharacterRange:(NSRange)range;
- (NSUInteger)lineCountForCharacterRange:(NSRange)range;
- (NSUInteger)unsignedIntegerValue;
@end

@interface NSMutableString (ALParsing)
- (NSUInteger)replaceOccurrencesOfString:(NSString*)target withString:(NSString*)replacement;
@end

@interface NSRegularExpression (ALParsing)
- (NSTextCheckingResult*)firstMatchInString:(NSString*)string;
+ (NSRegularExpression*)ci_dmls_regularExpressionWithPattern:(NSString*)pattern;
+ (NSRegularExpression*)ci_regularExpressionWithPattern:(NSString*)pattern;
+ (NSRegularExpression*)aml_regularExpressionWithPattern:(NSString*)pattern;
@end

