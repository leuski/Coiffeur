//
//  NSString+commandLine.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "NSString+commandLine.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
static NSString* const AL_UnicharFormat = @"%C";
#pragma clang diagnostic pop

@implementation NSString (commandLine)

- (NSArray*)commandLineComponents
{
  NSMutableArray* array   = [NSMutableArray new];
  unichar cur_quote       = 0;
  BOOL    in_backslash    = NO;
  BOOL    in_arg = NO;
  NSMutableString* target = nil;

  NSUInteger       len    = [self length];
  unichar buffer[len + 1];

  [self getCharacters:buffer range:NSMakeRange(0, len)];

  NSCharacterSet* wss = [NSCharacterSet whitespaceAndNewlineCharacterSet];

  for (int i = 0; i < len; ++i) {
    unichar ch       = buffer[i];
    BOOL    is_space = [wss characterIsMember:ch];

    if (!in_arg) {
      if (is_space) {
        continue;
      }

      in_arg = YES;
      target = [NSMutableString new];
      [array addObject:target];
    }

    if (in_backslash) {
      in_backslash = NO;
      [target appendFormat:AL_UnicharFormat, ch];
    } else if (ch == '\\') {
      in_backslash = YES;
    } else if (ch == cur_quote) {
      cur_quote = 0;
    } else if ((ch == '\'') || (ch == '"') || (ch == '`')) {
      cur_quote = ch;
    } else if (cur_quote != 0) {
      [target appendFormat:AL_UnicharFormat, ch];
    } else if (is_space) {
      in_arg = NO;
    } else {
      [target appendFormat:AL_UnicharFormat, ch];
    }
  }

  return array;
}

- (NSString*)stringByAppendingString:(NSString*)aString separatedBy:(NSString*)delimiter
{
  NSString* result = self;

  if ([result length]) {
    result = [result stringByAppendingString:delimiter];
  }

  return [result stringByAppendingString:aString];
}

static NSCharacterSet* AL_WS_SET = nil;

- (NSString*)trim
{
  if (!AL_WS_SET) {
    AL_WS_SET = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  }

  return [self stringByTrimmingCharactersInSet:AL_WS_SET];
}

- (NSString*)stringByTrimmingPrefix:(NSString*)prefix
{
  NSString* result = self;

  result = [result trim];

  if (prefix.length == 0) {
    return result;
  }

  while ([result hasPrefix:prefix]) {
    result = [result substringFromIndex:prefix.length];
    result = [result trim];
  }

  return result;
}

- (NSRange)lineRangeForCharacterRange:(NSRange)range
{
  NSUInteger numberOfLines, index, stringLength = [self length];
  NSInteger  lastCharacter = range.location + range.length - 1;
  NSRange    result = NSMakeRange(NSNotFound, 0);

  for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++) {
    NSUInteger nextIndex = NSMaxRange([self lineRangeForRange:NSMakeRange(index, 0)]);

    if (index <= range.location && range.location < nextIndex) {
      result.location = numberOfLines;
      result.length   = 1;

      if (lastCharacter <= 0) {
        break;
      }
    }

    if (index <= lastCharacter && lastCharacter < nextIndex) {
      result.length = numberOfLines - result.location + 1;
      break;
    }

    index = nextIndex;
  }

  return result;
}

- (NSUInteger)lineCountForCharacterRange:(NSRange)range
{
  NSUInteger stringLength  = [self length];
  NSInteger  lastCharacter = range.location + range.length - 1;

  if (lastCharacter < 0) {
    return 0;
  }

  for (NSUInteger index = range.location, numberOfLines = 0; index < stringLength;
       numberOfLines++)
  {
    NSUInteger nextIndex = NSMaxRange([self lineRangeForRange:NSMakeRange(index, 0)]);

    if (index <= lastCharacter && lastCharacter < nextIndex) {
      return numberOfLines;
    }

    index = nextIndex;
  }

  return 0;
}

- (NSUInteger)unsignedIntegerValue
{
  long long value = [self longLongValue];

  if (value >= 0) {
    return (NSUInteger)value;
  }

  return 0;
}

@end

@implementation NSMutableString (ALParsing)
- (NSUInteger)replaceOccurrencesOfString:(NSString*)target withString:(NSString*)replacement
{
  return [self replaceOccurrencesOfString:target
                               withString:replacement
                                  options:0
                                    range:NSMakeRange(0, self.length)];
}

@end

@implementation NSRegularExpression (ALParsing)
- (NSTextCheckingResult*)firstMatchInString:(NSString*)string
{
  return [self firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
}

+ (NSRegularExpression*)ci_dmls_regularExpressionWithPattern:(NSString*)pattern
{
  return [self regularExpressionWithPattern:pattern
                                    options:NSRegularExpressionCaseInsensitive
          | NSRegularExpressionDotMatchesLineSeparators
                                      error:nil];
}

+ (NSRegularExpression*)ci_regularExpressionWithPattern:(NSString*)pattern
{
  return [self regularExpressionWithPattern:pattern
                                    options:NSRegularExpressionCaseInsensitive
                                      error:nil];
}

+ (NSRegularExpression*)aml_regularExpressionWithPattern:(NSString*)pattern
{
  return [self regularExpressionWithPattern:pattern
                                    options:NSRegularExpressionAnchorsMatchLines
                                      error:nil];
}

@end

