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
      return string.toInt()
    }
    return nil
  }

  override func reverseTransformedValue(value: AnyObject?) -> AnyObject?
  {
    if let number = value as? NSNumber {
      return number.stringValue
    }
    return nil
  }
}
