//
//  OutlineView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

@objc(ALOutlineView)
class OutlineView : NSOutlineView {
  // to enable NSStepper in the outline view cells
  override func validateProposedFirstResponder(responder: NSResponder, forEvent event: NSEvent?) -> Bool {
    return true
  }
}

