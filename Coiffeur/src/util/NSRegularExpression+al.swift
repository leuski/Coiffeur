//
//  NSRegularExpression+al.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/17/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

/**
	Simplifies parsing by shortening the argument list
 */
extension NSRegularExpression {
	class func ci_dmls_re_WithPattern(pattern: String) -> NSRegularExpression
	{
		return NSRegularExpression(pattern: pattern,
			options: NSRegularExpressionOptions.CaseInsensitive
				| NSRegularExpressionOptions.DotMatchesLineSeparators,
			error: nil)!
	}
	
	class func ci_re_WithPattern(pattern: String) -> NSRegularExpression
	{
		return NSRegularExpression(pattern: pattern,
			options: NSRegularExpressionOptions.CaseInsensitive,
			error: nil)!
	}
	
	class func aml_re_WithPattern(pattern: String) -> NSRegularExpression
	{
		return NSRegularExpression(pattern: pattern,
			options: NSRegularExpressionOptions.AnchorsMatchLines,
			error: nil)!
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







