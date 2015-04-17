//
//  OutlineRowView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/16/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

class OutlineRowView : NSTableRowView {
	
	var colors = [NSColor]()
	
	override func drawBackgroundInRect(dirtyRect: NSRect)
	{
    if self.groupRowStyle {
    
      var backgroundColor = self.backgroundColor
      if self.colors.count > 1 {
        backgroundColor = backgroundColor.blendedColorWithFraction(0.1, ofColor:colors.first!)!
      }
      backgroundColor = backgroundColor.shadowWithLevel(0.025)!
      if self.floating {
        backgroundColor = backgroundColor.colorWithAlphaComponent(0.75)
      }
      backgroundColor.setFill()
    } else {
      self.backgroundColor.setFill()
    }
    
    NSRectFill(NSMakeRect(CGFloat(0), CGFloat(0), self.bounds.size.width, self.bounds.size.height))
   
    if self.groupRowStyle {
      var path = NSBezierPath()
      path.lineWidth = CGFloat(2)
      path.appendBezierPathWithRect(NSMakeRect(-2, 0, self.bounds.size.width+4, self.bounds.size.height+2))
      NSColor.gridColor().set()
      path.stroke()
    }

    for var i = 0; i < colors.count - 1; ++i {
			colors[i].setFill()
			NSRectFill(NSMakeRect(CGFloat(3 + i*5), CGFloat(0), CGFloat(2-1*i), self.bounds.size.height))
		}
    
    if self.groupRowStyle {
      colors.last!.set()
      var path = NSBezierPath()
      let lineLength = 200
      let hOffset = 3 + 5*(colors.count-1)
      path.lineWidth = CGFloat(1)
      path.moveToPoint(NSMakePoint(CGFloat(hOffset), self.bounds.size.height-path.lineWidth+0.5))
      path.lineToPoint(NSMakePoint(CGFloat(lineLength - hOffset), self.bounds.size.height-path.lineWidth+0.5))
      path.stroke()
    }
	}
	
	override func drawSelectionInRect(dirtyRect: NSRect)
	{
    var color = NSColor.selectedMenuItemColor()
    
    color = color.blendedColorWithFraction(0.25, ofColor:colors.first!)!
    color = color.colorWithAlphaComponent(1)
		color.setFill()
		NSRectFill(NSMakeRect(CGFloat(10), CGFloat(0), self.bounds.size.width-10, self.bounds.size.height))
	}
}
