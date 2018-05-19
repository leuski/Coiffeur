//
//  OverviewScroller.swift
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

class OverviewRegion : NSObject {
  let lineRange : NSRange
  let color : NSColor?

	init(firstLineIndex:Int, lineCount:Int, color:NSColor?)
  {
    self.lineRange = NSMakeRange(firstLineIndex, lineCount)
    self.color = color
  }
}

class OverviewScroller : NSScroller {

  var regions : [OverviewRegion] = [] {
    didSet {
      self.needsDisplay = true
    }
  }

  override var knobProportion: CGFloat {
    didSet {
      self.needsDisplay = true
    }
  }

  override init(frame:NSRect)
  {
    super.init(frame:frame)
  }

  required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

  override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
    super.drawKnobSlot(in: slotRect, highlight: flag)

    if self.regions.isEmpty {
      return
    }

    let lastRegion = self.regions.last!
    let lineCount = lastRegion.lineRange.location

    if lineCount == 0 {
      return
    }

		let margin = CGFloat(3.0)
    let height = self.frame.size.height - 2 * margin
    let width  = self.frame.size.width
    let scale  = (height-2.0) / CGFloat(lineCount)

    for region in self.regions {
      if let color = region.color {
        let regionRect = NSMakeRect(0,
          margin + scale * CGFloat(region.lineRange.location),
          width,
          max(scale * CGFloat(region.lineRange.length), 2.0))

        if NSIntersectsRect(slotRect, regionRect) {
          color.setFill()
          regionRect.fill()
        }
      }
    }

  }
}

