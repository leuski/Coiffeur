//
//  Transformers.swift
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

class String2NumberTransformer: ValueTransformer {

  override class func allowsReverseTransformation() -> Bool
  {
    return true
  }

  override func transformedValue(_ value: Any?) -> Any?
  {
    if let string = value as? String {
      if let number = Int(string) {
        return number
      }
      return 0
    }
    return nil
  }

  override func reverseTransformedValue(_ value: Any?) -> Any?
  {
    if let number = value as? NSNumber {
      return number.stringValue
    }
    return "0"
  }
}

class OnlyIntegers: NumberFormatter {

  override init()
  {
    super.init()
    self.allowsFloats = false
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.allowsFloats = false
  }

  override func getObjectValue(
    _ object: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
    for string: String,
    errorDescription err: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool
  {
    if string.isEmpty {
      if err != nil {
        err?.pointee = NSLocalizedString(
          "Empty string is not a valid number. Please provide a number",
          comment: "") as NSString
      }
      return false
    }
    return super.getObjectValue(object, for: string, errorDescription: err)
  }
}
