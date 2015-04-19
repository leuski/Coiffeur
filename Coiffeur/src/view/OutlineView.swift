//
//  OutlineView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa
import Carbon

class OutlineView : NSOutlineView {
  // to enable NSStepper in the outline view cells
  override func validateProposedFirstResponder(responder: NSResponder, forEvent event: NSEvent?) -> Bool {
    return true
  }
	
	override func keyDown(theEvent: NSEvent)
	{
		let mods = theEvent.modifierFlags & (.ShiftKeyMask | .AlternateKeyMask
			| .CommandKeyMask | .ControlKeyMask)
		
		if Int(theEvent.keyCode) == kVK_RightArrow {
			if mods == .CommandKeyMask {
				expandItem(parentForItem(itemAtRow(selectedRow)), expandChildren: true)
				return
			}
			if mods == .CommandKeyMask | .AlternateKeyMask {
				expandItem(nil, expandChildren: true)
				return
			}
		} else if Int(theEvent.keyCode) == kVK_LeftArrow {
			if mods == .CommandKeyMask {
				collapseItem(parentForItem(itemAtRow(selectedRow)), collapseChildren: true)
				return
			}
			if mods == .CommandKeyMask | .AlternateKeyMask {
				collapseItem(nil, collapseChildren: true)
				return
			}
		}
		super.keyDown(theEvent)
	}
}

