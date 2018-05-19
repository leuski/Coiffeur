//
//  TableCellView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

// actually, this code is not being used currently. I keep it here for reference...

class TableCellView: NSTableCellView {

  override var backgroundStyle: NSBackgroundStyle {
    didSet {
      // If the cell's text color is black, this sets it to white
      if let cell = self.textField?.cell() as? NSCell {
        cell.backgroundStyle = self.backgroundStyle
      }

      // Otherwise you need to change the color manually
      switch (self.backgroundStyle) {
      case NSBackgroundStyle.Light:
        if let textField = self.textField {
          textField.textColor = NSColor(calibratedWhite: 0.0, alpha: 1.0)
        }

      default:
        if let textField = self.textField {
          textField.textColor = NSColor(calibratedWhite: 1.0, alpha: 1.0)
        }
      }
    }
  }
}
