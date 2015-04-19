//
//  OutlineRowView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/16/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

class OutlineRowView : NSTableRowView {
	
	class Location {
		var index = 0
		var count = 0
		var color : NSColor {
			return NSColor(calibratedHue: CGFloat(index)/CGFloat(12), saturation: 1, brightness: 1, alpha: 1)
		}
		init(_ index:Int, of count:Int) {
			self.index = index
			self.count = count
		}
	}
	
	var locations = [Location]()
	
	override func drawBackgroundInRect(dirtyRect: NSRect)
	{
    if self.groupRowStyle {
    
      var backgroundColor = self.backgroundColor
      if self.locations.count > 1 {
        backgroundColor = backgroundColor.blendedColorWithFraction(0.1, ofColor:locations.first!.color)!
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

    for var i = 0; i < locations.count - 1; ++i {
			locations[i].color.setFill()
			NSRectFill(NSMakeRect(CGFloat(3 + i*5), CGFloat(0), CGFloat(1+1*i), self.bounds.size.height))
		}
    
    if self.groupRowStyle {
      locations.last!.color.set()
      var path = NSBezierPath()
      let lineLength = 200
      let hOffset = 3 + 5*(locations.count-1)
      path.lineWidth = CGFloat(1)
      path.moveToPoint(NSMakePoint(CGFloat(hOffset), self.bounds.size.height-path.lineWidth+0.5))
      path.lineToPoint(NSMakePoint(CGFloat(lineLength - hOffset), self.bounds.size.height-path.lineWidth+0.5))
      path.stroke()
    }
	}
	
	private func _focused() -> Bool
	{
		var outlineView : NSView? = self
		while outlineView != nil && !(outlineView is NSOutlineView) {
			outlineView = outlineView?.superview
		}
		if outlineView == nil {
			return false
		}
		var v = self.window?.firstResponder as? NSView
		while v != nil && !(v is NSOutlineView) {
			v = v?.superview
		}
		if v == nil {
			return false
		}
		return outlineView! == v!
	}
	
	override func drawSelectionInRect(dirtyRect: NSRect)
	{
    var color = NSColor.selectedMenuItemColor()
		
    color = color.blendedColorWithFraction(0.25, ofColor:locations.first!.color)!
		if !self._focused() {
			color = color.blendedColorWithFraction(0.9, ofColor:NSColor(calibratedWhite: 0.9, alpha: 1))!
		}
    color = color.colorWithAlphaComponent(1)
		color.setFill()
		NSRectFill(NSMakeRect(CGFloat(10), CGFloat(0), self.bounds.size.width-10, self.bounds.size.height))
	}
}
