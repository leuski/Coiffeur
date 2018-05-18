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
    
    for ch in self.characters {
      
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
		self.enumerateLinguisticTags(in: self.startIndex..<self.endIndex,
			scheme: NSLinguisticTagSchemeTokenType,
			options: NSLinguisticTagger.Options.omitWhitespace,
			orthography: nil) {
				(tag:String,
					tokenRange:Range<String.Index>,
					sentenceRange:Range<String.Index>, stop:inout Bool) -> () in
				result.append(self.substring(with: tokenRange))
		}
		return result
	}
	
	var stringByCapitalizingFirstWord : String {
		if self.isEmpty {
			return self
		}
		let nextIndex = self.characters.index(after: self.startIndex)
		return self.substring(to: nextIndex).capitalized +
			self.substring(from: nextIndex)
	}
	
	fileprivate func _stringByQuoting(_ quote:Character) -> String
	{
		let bs : Character = "\\"
		var result = ""
		result.append(quote)
		
		for ch in self.characters {
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
	
	func stringByQuoting(_ quote:Character = "\"") -> String
	{
		let set = NSMutableCharacterSet(charactersIn: String(quote))
		set.addCharacters(in: "\\\"'` \t\r\n")

		if self.isEmpty {
			return _stringByQuoting(quote)
		} else if let _ = self.rangeOfCharacter(from: set as CharacterSet) {
			return _stringByQuoting(quote)
		} else {
			return self
		}
	}
	
  func stringByAppendingString(_ s:String, separatedBy delimiter:String) -> String
  {
    var result = self
    
    if !result.isEmpty {
      result += delimiter
    }
    
    return result + s
  }
  
  func trim() -> String
  {
    return self.trimmingCharacters(
			in: CharacterSet.whitespacesAndNewlines)
  }
  
  func stringByTrimmingPrefix(_ prefix:String) -> String
  {
    var result = self.trim()
    if prefix.isEmpty {
      return result
    }
    let length = prefix.characters.distance(from: prefix.startIndex, to: prefix.endIndex)
    while result.hasPrefix(prefix) {
			let nextIndex = result.characters.index(result.startIndex, offsetBy: length)
      result = result.substring(from: nextIndex).trim()
    }
    return result
  }
  
	func stringByTrimmingSuffix(_ suffix:String) -> String
	{
		var result = self.trim()
		if suffix.isEmpty {
			return result
		}
		let length = suffix.characters.distance(from: suffix.startIndex, to: suffix.endIndex)
		while result.hasSuffix(suffix) {
			let resultLength = result.characters.distance(from: result.startIndex, to: result.endIndex)
			let nextIndex = result.characters.index(result.startIndex, offsetBy: resultLength-length)
			result = result.substring(to: nextIndex).trim()
		}
		return result
	}

	func lineRangeForCharacterRange(_ range: Range<String.Index>) -> CountableClosedRange<Int>
  {
    var numberOfLines = 0
    var index = self.startIndex
    let lastCharacter = self.index(before: range.upperBound)
    var start : Int = 0
    var end : Int = 0
    
    while index < self.endIndex {
      let nextIndex = self.lineRange(for: index..<index).upperBound
      
      if index <= range.lowerBound && range.lowerBound < nextIndex {
        start = numberOfLines
        end = numberOfLines
        
        if (lastCharacter < range.lowerBound) {
          break
        }
      }
      
      if index <= lastCharacter && lastCharacter < nextIndex {
        end = numberOfLines
        break
      }
      
      index = nextIndex
      numberOfLines += 1
    }
    return start...end
  }
  
  func lineCountForCharacterRange(_ range: Range<String.Index>) -> Int
  {
    if (range.upperBound == range.lowerBound) {
      return 0
    }
    
    let lastCharacter = self.index(before: range.upperBound)
    var numberOfLines : Int = 0
    var index = range.lowerBound
    
    while index < self.endIndex {
      let nextIndex = self.lineRange(for: index..<index).upperBound
      
      if (index <= lastCharacter && lastCharacter < nextIndex) {
        return numberOfLines
      }
      
      index = nextIndex
      numberOfLines += 1
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
  
  func substringWithRange(_ range:NSRange) -> String
  {
    let start = self.characters.index(self.startIndex, offsetBy: range.location)
    let end = self.characters.index(start, offsetBy: range.length)
    return self[start..<end]
  }
  
  func stringByReplacingCharactersInRange(_ range:NSRange,
		withString replacement: String) -> String
  {
    let start = self.characters.index(self.startIndex, offsetBy: range.location)
    let end = self.characters.index(start, offsetBy: range.length)
    return self.replacingCharacters(in: start..<end,
			with:replacement)
  }
  
  init?(data:Data, encoding:String.Encoding)
  {
    var buffer = [UInt8](repeating: 0, count: data.count)
    (data as NSData).getBytes(&buffer, length:data.count)
    self.init(bytes:buffer, encoding:encoding)
  }
}











