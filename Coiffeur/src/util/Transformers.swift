//
//  Transformers.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

class String2NumberTransformer : NSValueTransformer {

  override class func allowsReverseTransformation() -> Bool
  {
    return true;
  }
  
  override func transformedValue(value: AnyObject?) -> AnyObject?
  {
    if let string = value as? String {
			if let number = string.toInt() {
				return number
			}
      return 0
    }
    return nil
  }

  override func reverseTransformedValue(value: AnyObject?) -> AnyObject?
  {
    if let number = value as? NSNumber {
      return number.stringValue
    }
    return "0"
  }
}

class OnlyIntegers : NSNumberFormatter {
	
	override init()
	{
		super.init()
		self.allowsFloats = false
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder:aDecoder)
		self.allowsFloats = false
	}

	override func getObjectValue(obj: AutoreleasingUnsafeMutablePointer<AnyObject?>,
		forString string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool
	{
		if string.isEmpty {
			if error != nil {
				error.memory = NSLocalizedString("Empty string is not a valid number. Please provide a number", comment:"")
			}
			return false
		}
		return super.getObjectValue(obj, forString:string, errorDescription: error)
	}
}