//
//  NSSegmentedControl+al.swift
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

import Cocoa

extension NSSegmentedControl {

  var labels: [String] {
    get {
      var value = [String]()
      for segment in 0 ..< self.segmentCount {
        value.append(label(forSegment: segment)!)
      }
      return value
    }

    set (value) {
      self.segmentCount = value.count

      let font       = self.font!
      let fontName = font.familyName!
      let fontSize: NSNumber = NSNumber(value: Double(font.xHeight))

      let attributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey(rawValue: NSFontDescriptor.AttributeName.family.rawValue): fontName,
        NSAttributedStringKey(rawValue: NSFontDescriptor.AttributeName.size.rawValue): fontSize
      ]

      var width = CGFloat(40.0)
      var index     = 0

      for token in value {
        let attributedString = NSAttributedString(string: token, attributes: attributes)
        let size = attributedString.size()

        if width < size.width {
          width = size.width
        }

        setLabel(token, forSegment: index)
        index += 1
      }

      for segment in 0 ..< self.segmentCount {
        setWidth(width+12, forSegment: segment)
      }
    }
  }

}
