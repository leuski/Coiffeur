//
//  OverviewScroller.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

@objc(ALOverviewRegion)
class ALOverviewRegion : NSObject {
  private(set) var lineRange : NSRange
  private(set) var color : NSColor?

  init(lineRange:NSRange, color:NSColor?)
  {
    self.lineRange = lineRange
    self.color = color
  }
}

typealias OverviewRegion = ALOverviewRegion

@objc(ALOverviewScroller)
class ALOverviewScroller : NSScroller {
  
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
  
  override func drawKnobSlotInRect(slotRect: NSRect, highlight flag: Bool) {
    super.drawKnobSlotInRect(slotRect, highlight: flag)
    
    if self.regions.isEmpty {
      return
    }
    
    let lastRegion = self.regions.last!
    let lineCount = lastRegion.lineRange.location
    
    if lineCount == 0 {
      return
    }
    
    let height = self.frame.size.height;
    let width  = self.frame.size.width;
    let scale  = height / CGFloat(lineCount);
    
    for region in self.regions {
      if let color = region.color {
        let regionRect = NSMakeRect(0,
          scale * CGFloat(region.lineRange.location),
          width,
          max(scale * CGFloat(region.lineRange.length), 2.0));
        
        if NSIntersectsRect(slotRect, regionRect) {
          color.setFill()
          NSRectFill(regionRect)
        }
      }
    }
  
  }
}

