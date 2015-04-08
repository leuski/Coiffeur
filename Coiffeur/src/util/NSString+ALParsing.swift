//
//  NSString+ALParsing.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

extension String {
  
  var commandLineComponents : [String] {
    
    let null_char : Character = "\0"
    var result = [String]()
    var in_arg = false
    var in_backslash = false
    var cur_quote : Character = null_char
    var current_token : String = ""
    
    for ch in self {
      
      let is_space = ch == " " || ch == "\t" || ch == "\n" || ch == "\r"
      
      if !in_arg {
        if is_space {
          continue;
        }
        
        in_arg = true;
        current_token = ""
      }
      
      if in_backslash {
        in_backslash = false;
        current_token.append(ch)
      } else if ch == "\\" {
        in_backslash = true;
      } else if ch == cur_quote {
        cur_quote = null_char;
      } else if (ch == "'") || (ch == "\"") || (ch == "`") {
        cur_quote = ch;
      } else if cur_quote != null_char {
        current_token.append(ch)
      } else if (is_space) {
        in_arg = false;
        result.append(current_token)
      } else {
        current_token.append(ch)
      }
    }
    
    if in_arg {
      result.append(current_token)
    }

    return result
  }
  
  func stringByAppendingString(s:String, separatedBy delimiter:String) -> String
  {
    var result = self
    
    if !result.isEmpty {
      result += delimiter
    }
    
    return result + s
  }
  
  func trim() -> String
  {
    return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
  }
  
  func stringByTrimmingPrefix(prefix:String) -> String
  {
    var result = self.trim()
    if prefix.isEmpty {
      return result
    }
    let length = distance(prefix.startIndex, prefix.endIndex)
    while result.hasPrefix(prefix) {
      result = result.substringFromIndex(advance(result.startIndex, length)).trim()
    }
    return result
  }
  
  func lineRangeForCharacterRange(range: Range<String.Index>) -> Range<Int>
  {
    var numberOfLines = 0
    var index = self.startIndex
    let lastCharacter = range.endIndex.predecessor();
    var start : Int = 0
    var end : Int = 0
    
    for numberOfLines = 0; index < self.endIndex; numberOfLines++ {
      let nextIndex = self.lineRangeForRange(index..<index).endIndex;
      
      if index <= range.startIndex && range.startIndex < nextIndex {
        start = numberOfLines;
        end = numberOfLines;
        
        if (lastCharacter < range.startIndex) {
          break;
        }
      }
      
      if index <= lastCharacter && lastCharacter < nextIndex {
        end = numberOfLines;
        break;
      }
      
      index = nextIndex;
    }
    return start...end;
  }
  
  func lineCountForCharacterRange(range: Range<String.Index>) -> Int
  {
    if (range.endIndex == range.startIndex) {
      return 0;
    }
    
    let lastCharacter = range.endIndex.predecessor()
    var numberOfLines : Int = 0;
    
    for var index = range.startIndex; index < self.endIndex; numberOfLines++ {
      let nextIndex = self.lineRangeForRange(index..<index).endIndex;
      
      if (index <= lastCharacter && lastCharacter < nextIndex) {
        return numberOfLines;
      }
      
      index = nextIndex;
    }
    
    return 0;
   
  }
  
  var unsignedIntegerValue : Int
  {
    if let result = self.toInt() {
      return result
    }
    return 0
  }
  
  var nsRange : NSRange {
    return NSMakeRange(0, (self as NSString).length)
  }
}

extension NSString {
  var commandLineComponents : [String] {
    return (self as String).commandLineComponents
 }
  
  func stringByAppendingString(s:String, separatedBy delimiter:String) -> String
  {
    return (self as String).stringByAppendingString(s, separatedBy: delimiter)
  }
  
  func trim() -> String
  {
    return (self as String).trim()
  }
  
  func stringByTrimmingPrefix(prefix:String) -> String
  {
    return (self as String).stringByTrimmingPrefix(prefix)
  }
  
  func lineCountForCharacterRange(range: NSRange) -> Int
  {
    let s = self as String
    return s.lineCountForCharacterRange(advance(s.startIndex, range.location)..<advance(s.startIndex, (range.location+range.length)))
  }
  
  var unsignedIntegerValue : Int
  {
    return (self as String).unsignedIntegerValue
  }
  
}

extension NSMutableString {
  func replaceOccurrencesOfString(target: String, withString replacement: String) -> Int
  {
    return self.replaceOccurrencesOfString(target, withString: replacement, options: NSStringCompareOptions(), range: NSMakeRange(0, self.length))
  }
}

extension NSRegularExpression {
  func firstMatchInString(string:String) -> NSTextCheckingResult?
  {
    return firstMatchInString(string, options: NSMatchingOptions(), range: string.nsRange)
  }
  
  class func ci_dmls_regularExpressionWithPattern(pattern: String) -> NSRegularExpression
  {
    return NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.CaseInsensitive | NSRegularExpressionOptions.DotMatchesLineSeparators, error: nil)!
  }

  class func ci_regularExpressionWithPattern(pattern: String) -> NSRegularExpression
  {
    return NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.CaseInsensitive, error: nil)!
  }

  class func aml_regularExpressionWithPattern(pattern: String) -> NSRegularExpression
  {
    return NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.AnchorsMatchLines, error: nil)!
  }
  
  func replaceMatchesInString(string: NSMutableString, withTemplate template: String) -> Int
  {
    return self.replaceMatchesInString(string, options: NSMatchingOptions(), range: NSMakeRange(0, string.length), withTemplate: template)
  }
}
















