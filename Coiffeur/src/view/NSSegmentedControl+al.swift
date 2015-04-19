//
//  NSSegmentedControl+al.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

extension NSSegmentedControl {
  
  private class var SufficientlyLongWord : String { return "remove" }
  
  func setLabels(labels:[String])
  {
    self.segmentCount = labels.count;
    
    let font       = self.font!
    let fontName = font.familyName!
    let fontSize : NSNumber = font.xHeight
      
    let attributes : [NSString : AnyObject] = [
      NSFontFamilyAttribute: fontName,
      NSFontSizeAttribute: fontSize
    ];
    
    var attributedString = NSAttributedString(string: NSSegmentedControl.SufficientlyLongWord, attributes: attributes)

    var size  = attributedString.size;
    var width = size.width;
    var i     = 0;
    
    for token in labels {
      attributedString = NSAttributedString(string:token, attributes:attributes)
      size = attributedString.size;
      
      if (width < size.width) {
        width = size.width;
      }
      
      setLabel(token, forSegment: i++)
    }
    
    for var j = 0; j < self.segmentCount; ++j {
      setWidth(width+12, forSegment: j)
    }
   
  }
}