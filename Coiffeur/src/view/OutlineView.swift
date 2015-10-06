//
//  OutlineView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
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
import Carbon

class OutlineView : NSOutlineView {
  // to enable NSStepper in the outline view cells
  override func validateProposedFirstResponder(responder: NSResponder,
		forEvent event: NSEvent?) -> Bool
	{
    return true
  }
	
	override func keyDown(theEvent: NSEvent)
	{
		let mods = theEvent.modifierFlags.intersect((NSEventModifierFlags.ShiftKeyMask.union(.AlternateKeyMask).union(.CommandKeyMask).union(.ControlKeyMask)))
		
		if Int(theEvent.keyCode) == kVK_RightArrow {
			if mods == .CommandKeyMask {
				expandItem(parentForItem(itemAtRow(selectedRow)),
					expandChildren: true)
				return
			}
			if mods == NSEventModifierFlags.CommandKeyMask.union(.AlternateKeyMask) {
				expandItem(nil, expandChildren: true)
				return
			}
		} else if Int(theEvent.keyCode) == kVK_LeftArrow {
			if mods == .CommandKeyMask {
				collapseItem(parentForItem(itemAtRow(selectedRow)),
					collapseChildren: true)
				return
			}
			if mods == NSEventModifierFlags.CommandKeyMask.union(.AlternateKeyMask) {
				collapseItem(nil, collapseChildren: true)
				return
			}
		}
		super.keyDown(theEvent)
	}
  
  func scrollItemToVisible(item: AnyObject?)
  {
    let row = self.rowForItem(item)
    let rowFrame = self.frameOfCellAtColumn(0, row: row)
    var visRect = self.visibleRect
    visRect.origin.y = rowFrame.origin.y - 1.0
		// +1 because of the row frame? separator?, otherwise
    // it's going to scroll a bit, once you move the selection

    self.scrollRectToVisible(visRect)
  }
}

