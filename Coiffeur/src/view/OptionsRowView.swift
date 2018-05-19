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

class ConfigCellView: NSTableCellView {
  // prevent the state restoration mechanism to save/restore this view properties
  override class var restorableStateKeyPaths: [String] { return [] }
}

class ConfigOptionCellView: ConfigCellView {
	// will use this to shift the content of the cell appropriately
	@IBOutlet weak var leftMargin: NSLayoutConstraint!
}

class ConfigChoiceCellView: ConfigOptionCellView {
	@IBOutlet weak var segmented: NSSegmentedControl!
}

extension ConfigNodeLocation {
	var color: NSColor {
		// section color
		return NSColor(calibratedHue: CGFloat(index)/CGFloat(12),
			saturation: 0.7, brightness: 0.7, alpha: 1)
	}
}

class ConfigRowView: NSTableRowView {
  // prevent the state restoration mechanism to save/restore this view properties
  override class var restorableStateKeyPaths: [String] { return [] }

	@IBOutlet weak var leftMargin: NSLayoutConstraint!
	@IBOutlet weak var textField: NSTextField!

	var drawSeparator = false
	typealias Location = ConfigNode.Location
	var locations = [Location]()

	override func drawBackground(in dirtyRect: NSRect)
	{
    if self.isGroupRowStyle {

			// start with the background color
      var backgroundColor = self.backgroundColor
      if self.locations.count > 1 {
				// if this is a subsection, add a splash of supersection color
        backgroundColor = backgroundColor.blended(withFraction: 0.1,
					of: locations.first!.color)!
      }
			// make it a bit darker
      backgroundColor = backgroundColor.shadow(withLevel: 0.025)!
      if self.isFloating {
				// if the row is floating, add a bit of transparency
        backgroundColor = backgroundColor.withAlphaComponent(0.75)
      }
      backgroundColor.setFill()

		} else {

			let tf = self.textField
			if self.interiorBackgroundStyle == .dark {
				tf?.textColor = NSColor.selectedTextColor

				if self.window?.backingScaleFactor == 1 {
					// light on dark looks bad on regular resolution screen,
					// so we make the font bold to improve readability
					tf?.font = NSFontManager.shared.convert(
						(tf?.font!)!, toHaveTrait: NSFontTraitMask.boldFontMask)
				} else {
					// on a retina screen the same text looks fine. no need to do bold.
					tf?.font = NSFontManager.shared.convert(
						(tf?.font!)!, toNotHaveTrait: NSFontTraitMask.boldFontMask)
				}
			} else {
				tf?.textColor = NSColor.textColor
				tf?.font = NSFontManager.shared.convert(
					(tf?.font!)!, toNotHaveTrait: NSFontTraitMask.boldFontMask)
			}

      self.backgroundColor.setFill()
    }

    NSMakeRect(CGFloat(0), CGFloat(0),
			self.bounds.size.width, self.bounds.size.height).fill()

    if drawSeparator {
			// draw the top border
      let path = NSBezierPath()
      path.lineWidth = CGFloat(1)
			path.move(to: NSMakePoint(CGFloat(0),
				self.bounds.size.height-path.lineWidth+0.5))
			path.line(to: NSMakePoint(self.bounds.size.width,
				self.bounds.size.height-path.lineWidth+0.5))
      NSColor.gridColor.set()
      path.stroke()
    }

		// draw the colored lines using the section colors
    for index in 0 ..< min(1, locations.count - 1) {
			locations[index].color.setFill()
			NSMakeRect(CGFloat(3 + index*5), CGFloat(0),
				CGFloat(3), self.bounds.size.height-1).fill()
		}

		// if we are a group, underline the title with the appropriate color
    if self.isGroupRowStyle && locations.count == 1 {
      locations.last!.color.set()
      let path = NSBezierPath()
      let lineLength = 200
      let hOffset = 3 + 5*(locations.count-1)
      path.lineWidth = CGFloat(1)
      path.move(to: NSMakePoint(CGFloat(hOffset),
				self.bounds.size.height-path.lineWidth+0.5))
      path.line(to: NSMakePoint(CGFloat(lineLength - hOffset),
				self.bounds.size.height-path.lineWidth+0.5))
      path.stroke()
    }
	}

	override func drawSelection(in dirtyRect: NSRect)
	{
		let margin = CGFloat(7)

		// start with the regular selection color
		var color = NSColor.selectedMenuItemColor
		// add a hint of the current sectio color
    color = color.blended(withFraction: 0.25,
			of: locations.first!.color)!
		if self.interiorBackgroundStyle == .light {
			// if we are out of focus, lighten the color
			color = color.blended(withFraction: 0.9,
				of: NSColor(calibratedWhite: 0.9, alpha: 1))!
		}
		// make sure it is not transparent
    color = color.withAlphaComponent(1)

		// paint
		color.setFill()
		NSMakeRect(margin, CGFloat(0),
			self.bounds.size.width-margin, self.bounds.size.height-1).fill()
	}
}
