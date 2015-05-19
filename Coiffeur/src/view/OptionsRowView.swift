//
//  OptionsRowView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/16/15.
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

class ConfigCellView : NSTableCellView {
  // prevent the state restoration mechanism to save/restore this view properties
  override class func restorableStateKeyPaths() -> [AnyObject] { return [] }
}

class ConfigOptionCellView : ConfigCellView {
	// will use this to shift the content of the cell appropriately
	@IBOutlet weak var leftMargin : NSLayoutConstraint!
}

class ConfigChoiceCellView : ConfigOptionCellView {
	@IBOutlet weak var segmented : NSSegmentedControl!
}

extension ConfigNodeLocation {
	var color : NSColor {
		// section color
		return NSColor(calibratedHue: CGFloat(index)/CGFloat(12),
			saturation: 0.7, brightness: 0.7, alpha: 1)
	}
}

class ConfigRowView : NSTableRowView {
  // prevent the state restoration mechanism to save/restore this view properties
  override class func restorableStateKeyPaths() -> [AnyObject] { return [] }

	@IBOutlet weak var leftMargin : NSLayoutConstraint!
	@IBOutlet weak var textField : NSTextField!
	
	var drawSeparator = false
	typealias Location = ConfigNode.Location
	var locations = [Location]()
	
	override func drawBackgroundInRect(dirtyRect: NSRect)
	{
    if self.groupRowStyle {
			
			// start with the background color
      var backgroundColor = self.backgroundColor
      if self.locations.count > 1 {
				// if this is a subsection, add a splash of supersection color
        backgroundColor = backgroundColor.blendedColorWithFraction(0.1,
					ofColor:locations.first!.color)!
      }
			// make it a bit darker
      backgroundColor = backgroundColor.shadowWithLevel(0.025)!
      if self.floating {
				// if the row is floating, add a bit of transparency
        backgroundColor = backgroundColor.colorWithAlphaComponent(0.75)
      }
      backgroundColor.setFill()

		} else {
			
			let tf = self.textField
			if self.interiorBackgroundStyle == .Dark {
				tf.textColor = NSColor.selectedTextColor()
				
				if self.window?.backingScaleFactor == 1 {
					// light on dark looks bad on regular resolution screen,
					// so we make the font bold to improve readability
					tf.font = NSFontManager.sharedFontManager().convertFont(
						tf.font!, toHaveTrait: NSFontTraitMask.BoldFontMask)
				} else {
					// on a retina screen the same text looks fine. no need to do bold.
					tf.font = NSFontManager.sharedFontManager().convertFont(
						tf.font!, toNotHaveTrait: NSFontTraitMask.BoldFontMask)
				}
			} else {
				tf.textColor = NSColor.textColor()
				tf.font = NSFontManager.sharedFontManager().convertFont(
					tf.font!, toNotHaveTrait: NSFontTraitMask.BoldFontMask)
			}
			
      self.backgroundColor.setFill()
    }
    
    NSRectFill(NSMakeRect(CGFloat(0), CGFloat(0),
			self.bounds.size.width, self.bounds.size.height))
   
    if drawSeparator {
			// draw the top border
      var path = NSBezierPath()
      path.lineWidth = CGFloat(1)
			path.moveToPoint(NSMakePoint(CGFloat(0),
				self.bounds.size.height-path.lineWidth+0.5))
			path.lineToPoint(NSMakePoint(self.bounds.size.width,
				self.bounds.size.height-path.lineWidth+0.5))
      NSColor.gridColor().set()
      path.stroke()
    }

		// draw the colored lines using the section colors
    for var i = 0; i < min(1, locations.count - 1); ++i {
			locations[i].color.setFill()
			NSRectFill(NSMakeRect(CGFloat(3 + i*5), CGFloat(0),
				CGFloat(3), self.bounds.size.height-1))
		}
		
		// if we are a group, underline the title with the appropriate color
    if self.groupRowStyle && locations.count == 1 {
      locations.last!.color.set()
      var path = NSBezierPath()
      let lineLength = 200
      let hOffset = 3 + 5*(locations.count-1)
      path.lineWidth = CGFloat(1)
      path.moveToPoint(NSMakePoint(CGFloat(hOffset),
				self.bounds.size.height-path.lineWidth+0.5))
      path.lineToPoint(NSMakePoint(CGFloat(lineLength - hOffset),
				self.bounds.size.height-path.lineWidth+0.5))
      path.stroke()
    }
	}
	
	override func drawSelectionInRect(dirtyRect: NSRect)
	{
		let margin = CGFloat(7)
		
		// start with the regular selection color
		var color = NSColor.selectedMenuItemColor()
		// add a hint of the current sectio color
    color = color.blendedColorWithFraction(0.25,
			ofColor:locations.first!.color)!
		if self.interiorBackgroundStyle == .Light {
			// if we are out of focus, lighten the color
			color = color.blendedColorWithFraction(0.9,
				ofColor:NSColor(calibratedWhite: 0.9, alpha: 1))!
		}
		// make sure it is not transparent
    color = color.colorWithAlphaComponent(1)

		// paint
		color.setFill()
		NSRectFill(NSMakeRect(margin, CGFloat(0),
			self.bounds.size.width-margin, self.bounds.size.height-1))
	}
}
