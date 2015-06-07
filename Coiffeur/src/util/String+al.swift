//
//  String+al.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//

import Foundation

/**
Adds string processing utilities
*/
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
          continue
        }
        
        in_arg = true
        current_token = ""
      }
      
      if in_backslash {
        in_backslash = false
        current_token.append(ch)
      } else if ch == "\\" {
        in_backslash = true
      } else if ch == cur_quote {
        cur_quote = null_char
      } else if (ch == "'") || (ch == "\"") || (ch == "`") {
        cur_quote = ch
      } else if cur_quote != null_char {
        current_token.append(ch)
      } else if (is_space) {
        in_arg = false
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
	
	var words : [String] {
		var result = [String]()
		self.enumerateLinguisticTagsInRange(self.startIndex..<self.endIndex,
			scheme: NSLinguisticTagSchemeTokenType,
			options: NSLinguisticTaggerOptions.OmitWhitespace,
			orthography: nil) {
				(tag:String,
					tokenRange:Range<String.Index>,
					sentenceRange:Range<String.Index>, inout stop:Bool) -> () in
				result.append(self.substringWithRange(tokenRange))
		}
		return result
	}
	
	var stringByCapitalizingFirstWord : String {
		if self.isEmpty {
			return self
		}
		let nextIndex = self.startIndex.successor()
		return self.substringToIndex(nextIndex).capitalizedString +
			self.substringFromIndex(nextIndex)
	}
	
	private func _stringByQuoting(quote:Character) -> String
	{
		let bs : Character = "\\"
		var result = ""
		result.append(quote)
		
		for ch in self {
			switch ch {
			case quote, "\\", "\"", "'", "`", " ", "\t", "\r", "\n":
				result.append(bs)
				fallthrough
			default:
				result.append(ch)
			}
		}
		
		result.append(quote)
		return result
	}
	
	func stringByQuoting(quote:Character = "\"") -> String
	{
		var set = NSMutableCharacterSet(charactersInString: String(quote))
		set.addCharactersInString("\\\"'` \t\r\n")

		if self.isEmpty {
			return _stringByQuoting(quote)
		} else if let range = self.rangeOfCharacterFromSet(set) {
			return _stringByQuoting(quote)
		} else {
			return self
		}
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
    return self.stringByTrimmingCharactersInSet(
			NSCharacterSet.whitespaceAndNewlineCharacterSet())
  }
  
  func stringByTrimmingPrefix(prefix:String) -> String
  {
    var result = self.trim()
    if prefix.isEmpty {
      return result
    }
    let length = distance(prefix.startIndex, prefix.endIndex)
    while result.hasPrefix(prefix) {
			let nextIndex = advance(result.startIndex, length)
      result = result.substringFromIndex(nextIndex).trim()
    }
    return result
  }
  
	func stringByTrimmingSuffix(suffix:String) -> String
	{
		var result = self.trim()
		if suffix.isEmpty {
			return result
		}
		let length = distance(suffix.startIndex, suffix.endIndex)
		while result.hasSuffix(suffix) {
			let resultLength = distance(result.startIndex, result.endIndex)
			let nextIndex = advance(result.startIndex, resultLength-length)
			result = result.substringToIndex(nextIndex).trim()
		}
		return result
	}

	func lineRangeForCharacterRange(range: Range<String.Index>) -> Range<Int>
  {
    var numberOfLines = 0
    var index = self.startIndex
    let lastCharacter = range.endIndex.predecessor()
    var start : Int = 0
    var end : Int = 0
    
    for numberOfLines = 0; index < self.endIndex; numberOfLines++ {
      let nextIndex = self.lineRangeForRange(index..<index).endIndex
      
      if index <= range.startIndex && range.startIndex < nextIndex {
        start = numberOfLines
        end = numberOfLines
        
        if (lastCharacter < range.startIndex) {
          break
        }
      }
      
      if index <= lastCharacter && lastCharacter < nextIndex {
        end = numberOfLines
        break
      }
      
      index = nextIndex
    }
    return start...end
  }
  
  func lineCountForCharacterRange(range: Range<String.Index>) -> Int
  {
    if (range.endIndex == range.startIndex) {
      return 0
    }
    
    let lastCharacter = range.endIndex.predecessor()
    var numberOfLines : Int = 0
    
    for var index = range.startIndex; index < self.endIndex; numberOfLines++ {
      let nextIndex = self.lineRangeForRange(index..<index).endIndex
      
      if (index <= lastCharacter && lastCharacter < nextIndex) {
        return numberOfLines
      }
      
      index = nextIndex
    }
    
    return 0
  }
  
  func lineCount() -> Int
  {
    return lineCountForCharacterRange(self.startIndex..<self.endIndex)
  }
  
  var nsRange : NSRange {
    return NSMakeRange(0, (self as NSString).length)
  }
  
  func substringWithRange(range:NSRange) -> String
  {
    let start = advance(self.startIndex, range.location)
    let end = advance(start, range.length)
    return self[start..<end]
  }
  
  func stringByReplacingCharactersInRange(range:NSRange,
		withString replacement: String) -> String
  {
    let start = advance(self.startIndex, range.location)
    let end = advance(start, range.length)
    return self.stringByReplacingCharactersInRange(start..<end,
			withString:replacement)
  }
  
  init?(data:NSData, encoding:NSStringEncoding)
  {
    var buffer = [UInt8](count:data.length, repeatedValue:0)
    data.getBytes(&buffer, length:data.length)
    self.init(bytes:buffer, encoding:encoding)
  }
}











