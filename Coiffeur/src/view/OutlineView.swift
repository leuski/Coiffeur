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

class OutlineView: NSOutlineView {
  // to enable NSStepper in the outline view cells
  override func validateProposedFirstResponder(_ responder: NSResponder,
                                               for event: NSEvent?) -> Bool
  {
    return true
  }

  override func keyDown(with theEvent: NSEvent)
  {
    let mods = theEvent.modifierFlags
      .intersection([.shift, .option, .command, .control])

    if Int(theEvent.keyCode) == kVK_RightArrow {
      if mods == NSEvent.ModifierFlags.command {
        expandItem(parent(forItem: item(atRow: selectedRow)),
                   expandChildren: true)
        return
      }
      if mods == NSEvent.ModifierFlags.command.union(NSEvent.ModifierFlags.option) {
        expandItem(nil, expandChildren: true)
        return
      }
    } else if Int(theEvent.keyCode) == kVK_LeftArrow {
      if mods == NSEvent.ModifierFlags.command {
        collapseItem(parent(forItem: item(atRow: selectedRow)),
                     collapseChildren: true)
        return
      }
      if mods == NSEvent.ModifierFlags.command.union(NSEvent.ModifierFlags.option) {
        collapseItem(nil, collapseChildren: true)
        return
      }
    }
    super.keyDown(with: theEvent)
  }

  func scrollItemToVisible(_ item: Any?)
  {
    let row = self.row(forItem: item)
    let rowFrame = self.frameOfCell(atColumn: 0, row: row)
    var visRect = self.visibleRect
    visRect.origin.y = rowFrame.origin.y - 1.0
    // +1 because of the row frame? separator?, otherwise
    // it's going to scroll a bit, once you move the selection

    self.scrollToVisible(visRect)
  }
}
