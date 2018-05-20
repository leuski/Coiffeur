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
        value.append(label(forSegment: segment) ?? "")
      }
      return value
    }

    set (value) {
      self.segmentCount = value.count

      for (index, token) in value.enumerated() {
        setLabel(token, forSegment: index)
      }

      guard let font = self.font else { return }

      var width = CGFloat(40.0)
      let attributes: [NSAttributedStringKey: Any] = [.font: font]
      
      for token in value {
        width = max(
          width,
          NSAttributedString(string: token, attributes: attributes).size().width)
      }

      for segment in 0..<self.segmentCount {
        setWidth(width+12, forSegment: segment)
      }
    }
  }

}
