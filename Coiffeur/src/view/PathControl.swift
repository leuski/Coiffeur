//
//  PathControl.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

@objc(ALPathControl)
class PathControl : NSPathControl {
  // there is a bug in NSPathControl where clicking outside of the
  // button label results in the focus not transferring to the control. Fixing.
  override func mouseDown(theEvent: NSEvent) {
    self.window?.makeFirstResponder(self)
    super.mouseDown(theEvent)
  }
}
