//
//  NSRegularExpression+al.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/17/15.
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
	Simplifies parsing by shortening the argument list
 */
extension NSRegularExpression {
	class func ci_dmls_re_WithPattern(pattern: String) -> NSRegularExpression
	{
		return try! NSRegularExpression(pattern: pattern,
			options: [NSRegularExpressionOptions.CaseInsensitive, NSRegularExpressionOptions.DotMatchesLineSeparators])
	}
	
	class func ci_re_WithPattern(pattern: String) -> NSRegularExpression
	{
		return try! NSRegularExpression(pattern: pattern,
			options: NSRegularExpressionOptions.CaseInsensitive)
	}
	
	class func aml_re_WithPattern(pattern: String) -> NSRegularExpression
	{
		return try! NSRegularExpression(pattern: pattern,
			options: NSRegularExpressionOptions.AnchorsMatchLines)
	}
	
	func firstMatchInString(string:String) -> NSTextCheckingResult?
	{
		return firstMatchInString(string,
			options: NSMatchingOptions(), range: string.nsRange)
	}
	
	func stringByReplacingMatchesInString(string: String,
		withTemplate template: String) -> String
	{
		return self.stringByReplacingMatchesInString(string,
			options:NSMatchingOptions(), range:string.nsRange, withTemplate: template)
	}
}







