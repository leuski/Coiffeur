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
      _adjustTextFieldFont()
      self.backgroundColor.setFill()
    }

    NSRect(x: CGFloat(0), y: CGFloat(0),
           width: self.bounds.size.width, height: self.bounds.size.height).fill()

    if drawSeparator {
      _separatorPath().stroke()
    }

    // draw the colored lines using the section colors
    for index in 0 ..< min(1, locations.count - 1) {
      locations[index].color.setFill()
      NSRect(x: CGFloat(3 + index*5), y: CGFloat(0),
             width: CGFloat(3), height: self.bounds.size.height-1).fill()
    }

    // if we are a group, underline the title with the appropriate color
    if self.isGroupRowStyle && locations.count == 1 {
      locations.last!.color.set()
      let path = NSBezierPath()
      let lineLength = 200
      let hOffset = 3 + 5*(locations.count-1)
      path.lineWidth = CGFloat(1)
      path.move(to: NSPoint(x: CGFloat(hOffset),
                            y: self.bounds.size.height-path.lineWidth+0.5))
      path.line(to: NSPoint(x: CGFloat(lineLength - hOffset),
                            y: self.bounds.size.height-path.lineWidth+0.5))
      path.stroke()
    }
  }

  private func _adjustTextFieldFont() {
    guard
      let textField = textField,
      let textFieldFont = textField.font
      else { return }

    if self.interiorBackgroundStyle == .dark {
      textField.textColor = .selectedTextColor

      if self.window?.backingScaleFactor == 1 {
        // light on dark looks bad on regular resolution screen,
        // so we make the font bold to improve readability
        textField.font = NSFontManager.shared.convert(
          textFieldFont, toHaveTrait: .boldFontMask)
      } else {
        // on a retina screen the same text looks fine. no need to do bold.
        textField.font = NSFontManager.shared.convert(
          textFieldFont, toNotHaveTrait: .boldFontMask)
      }
    } else {
      textField.textColor = NSColor.textColor
      textField.font = NSFontManager.shared.convert(
        textFieldFont, toNotHaveTrait: .boldFontMask)
    }
  }

  private func _separatorPath() -> NSBezierPath {
    // draw the top border
    let path = NSBezierPath()
    path.lineWidth = CGFloat(1)
    path.move(to: NSPoint(x: CGFloat(0),
                          y: self.bounds.size.height-path.lineWidth+0.5))
    path.line(to: NSPoint(x: self.bounds.size.width,
                          y: self.bounds.size.height-path.lineWidth+0.5))
    NSColor.gridColor.set()
    return path
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
    NSRect(
      x: margin, y: CGFloat(0),
      width: bounds.size.width-margin,
      height: bounds.size.height-1)
      .fill()
  }
}
