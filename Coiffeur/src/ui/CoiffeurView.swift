//
//  CoiffeurView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
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

class CoiffeurView : NSViewController {
  
  @IBOutlet weak var optionsView : OutlineView!
  @IBOutlet weak var jumpMenu : NSPopUpButton!
  @IBOutlet var optionsController : NSTreeController!
	
	private var rowHeightCache = Dictionary<String,CGFloat>()
	
	override init?(nibName nibNameOrNil: String? = "CoiffeurView",
		bundle nibBundleOrNil: NSBundle? = nil)
  {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
	
  required init?(coder: NSCoder) {
    super.init(coder:coder)
  }
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
		self.addOneShotObserverForKeyPath("optionsController.content") {
			_, _ in self._finishSettingUpView()
		}
  }
	
	private func _finishSettingUpView()
	{
		self.optionsView.expandItem(nil, expandChildren:true)

		if let node: AnyObject = self.optionsController.firstLeaf  {
			self.optionsController.setSelectionIndexPath(node.indexPath)
		}
		
		for node in self.optionsController.nodes {
			if let section = node.representedObject as? ConfigSection {
				var item = NSMenuItem()
				item.title = section.title
				item.indentationLevel  = section.depth - 1
				item.representedObject = node
				self.jumpMenu.menu!.addItem(item)
			}
    }
  }
  
  @IBAction func jumpToSection(sender:AnyObject)
  {
    if let popup = sender as? NSPopUpButton {
      self.optionsView.scrollItemToVisible(
				popup.selectedItem?.representedObject)
    }
  }
}

extension CoiffeurView : NSOutlineViewDelegate {
	
  func outlineView(outlineView:NSOutlineView,
		isGroupItem item:AnyObject) -> Bool
  {
    if let node = item.representedObject as? ConfigNode {
      return !node.leaf
    }
    return false
  }
	
	private func _rowViewIdentifierForItem(item:AnyObject) -> String?
	{
		if let node = item.representedObject as? ConfigNode {
			if node is ConfigOption {
				return "row.option"
			} else if node is ConfigSection {
				return "row.section"
			}
		}
		return nil
	}
	
	private func _cellViewIdentifierForItem(item:AnyObject) -> String?
	{
		if let node = item.representedObject as? ConfigNode {
			let tokens = node.tokens
			if (tokens.count == 0) {
				return "view.section"
			} else if (tokens.count == 1
					&& tokens[0] == CoiffeurController.OptionType.Signed.rawValue) {
				return "view.signed"
			} else if (tokens.count == 1
					&& tokens[0] == CoiffeurController.OptionType.Unsigned.rawValue) {
				return "view.unsigned"
			} else if (tokens.count == 1) {
				return "view.string"
			} else {
				return "view.choice"
			}
		}
		return nil
	}
	
	func outlineView(outlineView:NSOutlineView,
		viewForTableColumn tableColumn:NSTableColumn?, item:AnyObject) -> NSView?
  {
		if let identifier = _cellViewIdentifierForItem(item),
			 let view = outlineView.makeViewWithIdentifier(identifier, owner:self) as! NSView?,
			 let node = item.representedObject as? ConfigNode
		{
			if let v = view as? ConfigChoiceCellView, let segmented = v.segmented {
				segmented.labels = node.tokens
			}
			if let v = view as? ConfigOptionCellView {
				v.leftMargin.constant = 8
			}
			return view
		}
    return nil
  }
	
	private func _outlineView(outlineView: NSOutlineView,
		heightOfRowByIdentifier identifier: String) -> CGFloat
	{
		if let height = rowHeightCache[identifier] {
			return height
		}
		if let view = outlineView.makeViewWithIdentifier(identifier,
				owner:self) as? NSView
		{
			var height = view.frame.size.height
			if height > 0 {
				rowHeightCache[identifier] = height
				return height
			}
		}
		return 10
	}
	
	// this is a very, very, very frequently called method. We need to make it
	// as fast as possible. We cache the view height based on the cell 
	// view identifier
  func outlineView(outlineView: NSOutlineView,
		heightOfRowByItem item: AnyObject) -> CGFloat
  {
		if let identifier = _cellViewIdentifierForItem(item),
			 let rowIdentifier = _rowViewIdentifierForItem(item)
		{
			return _outlineView(outlineView, heightOfRowByIdentifier:identifier)
				+ _outlineView(outlineView, heightOfRowByIdentifier:rowIdentifier)
		}
    return 10
  }
  
  func outlineView(outlineView: NSOutlineView,
		shouldSelectItem item: AnyObject) -> Bool
  {
    return !self.outlineView(outlineView, isGroupItem:item)
  }
  
  func outlineView(outlineView: NSOutlineView,
		rowViewForItem item: AnyObject) -> NSTableRowView?
  {
		if let identifier = _rowViewIdentifierForItem(item),
			 let theNode = item.representedObject as? ConfigNode,
			 var container = outlineView.makeViewWithIdentifier(identifier,
				owner:self) as? ConfigRowView
		{
			container.locations = theNode.path
			container.textField.stringValue = theNode.title
			container.leftMargin.constant = (1.5
				+ CGFloat(outlineView.levelForItem(item)))
					* outlineView.indentationPerLevel+4.0
			container.drawSeparator = theNode is ConfigSection
//				|| theNode.index == theNode.parent!.children.count-1
			if !container.drawSeparator {
				let row = outlineView.rowForItem(item) + 1
				if row < outlineView.numberOfRows {
					container.drawSeparator =
						outlineView.itemAtRow(row)?.representedObject is ConfigSection
				}
			}
			return container
		} else {
			return nil
		}
  }
	
	// the row is added as the predicate changes. Restore the expanded state
	// from the model. 
	// We do it asynchroniously, because node expansion
	// can lead to more rows being added to the view.
	func outlineView(outlineView: NSOutlineView,
		didAddRowView rowView: NSTableRowView, forRow row: Int)
	{
		let item: AnyObject? = outlineView.itemAtRow(row)
		if let section = item?.representedObject as? ConfigSection {
			if section.expanded {
				dispatch_async(dispatch_get_main_queue()) {
					outlineView.animator().expandItem(item)
				}
			}
		}
	}
	
	// records the state of the node in the model
	func outlineViewItemDidExpand(notification: NSNotification)
	{
		if var section = notification.userInfo!["NSObject"
			as NSString]!.representedObject as? ConfigSection
		{
			section.expanded = true
		}
	}
	
	func outlineViewItemDidCollapse(notification: NSNotification)
	{
		if var section = notification.userInfo!["NSObject"
			as NSString]!.representedObject as? ConfigSection
		{
			section.expanded = false
		}
	}
	
  // - (BOOL)outlineView:(NSOutlineView *)outlineView
  // shouldShowOutlineCellForItem:(id)item
  // {
  //      return false
  // }
}
