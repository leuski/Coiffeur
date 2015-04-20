//
//  CoiffeurView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

class CoiffeurView : NSViewController {
  
  @IBOutlet weak var optionsView : NSOutlineView!
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

		var foundNode = false
		
		var node : AnyObject?
		for node = self.optionsController.arrangedObjects;
			node?.childNodes??.count != nil && node!.childNodes!!.count > 0;
			node = node!.childNodes!![0]
		{
			foundNode = true
		}
		
		if foundNode && node != nil {
			self.optionsController.setSelectionIndexPath(node!.indexPath)
		}
		
		self._fillMenu()
	}
	
  private func _allNodes() -> [AnyObject]
  {
    var array = [AnyObject]()
    self._fillNodeArray(&array, atNode:self.optionsController.arrangedObjects)
    return array
  }
  
  private func _fillNodeArray(inout array:[AnyObject], atNode node:AnyObject)
  {
    if let nodes : [AnyObject] = node.childNodes {
      for n in nodes {
        array.append(n)
        self._fillNodeArray(&array, atNode:n)
      }
    }
  }
  
  private func _fillMenu()
  {
    for var i = self.jumpMenu.numberOfItems - 1; i >= 1; --i {
      self.jumpMenu.removeItemAtIndex(i)
    }
    
		let sections = self._allNodes().filter { $0.representedObject is ConfigSection }

		for node in sections {
      let section = node.representedObject as! ConfigSection
			var item    = NSMenuItem()
      item.title = section.title;
      item.indentationLevel  = section.depth - 1;
      item.representedObject = node;
      self.jumpMenu.menu!.addItem(item)
    }
    
    self.jumpMenu.preferredEdge = NSMaxYEdge;
  }
  
  @IBAction func jumpToSection(sender:AnyObject)
  {
    if let popup = sender as? NSPopUpButton {
      self.optionsView.scrollRowToVisible(self.optionsView.rowForItem(popup.selectedItem?.representedObject))
    }
  }
}

extension CoiffeurView : NSOutlineViewDelegate {
	
  func outlineView(outlineView:NSOutlineView, isGroupItem item:AnyObject) -> Bool
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
			} else if (tokens.count == 1 && tokens[0] == CoiffeurController.OptionType.Signed.rawValue) {
				return "view.number"
			} else if (tokens.count == 1 && tokens[0] == CoiffeurController.OptionType.Unsigned.rawValue) {
				return "view.number"
			} else if (tokens.count == 1) {
				return "view.string"
			} else {
				return "view.choice"
			}
		}
		return nil
	}
	
	func outlineView(outlineView:NSOutlineView, viewForTableColumn tableColumn:NSTableColumn?, item:AnyObject) -> NSView?
  {
		if let identifier = _cellViewIdentifierForItem(item),
			 let view = outlineView.makeViewWithIdentifier(identifier, owner:self) as! NSView?,
			 let node = item.representedObject as? ConfigNode
		{
			if let v = view as? ConfigChoiceCellView, let segmented = v.segmented {
				segmented.labels = node.tokens
			}
			return view
		}
    return nil
  }
  
  func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat
  {
		if let identifier = _cellViewIdentifierForItem(item) {
			if let height = rowHeightCache[identifier] {
				return height
			}
			if let view = outlineView.makeViewWithIdentifier(identifier, owner:self) as? NSView {
				let height = view.frame.size.height
				if height > 0 {
					rowHeightCache[identifier] = height
					return height
				}
			}
		}
    return 10
  }
  
  func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool
  {
    return !self.outlineView(outlineView, isGroupItem:item)
  }
  
  func outlineView(outlineView: NSOutlineView, rowViewForItem item: AnyObject) -> NSTableRowView?
  {
		if let identifier = _rowViewIdentifierForItem(item),
			 let theNode = item.representedObject as? ConfigNode,
			 var container  = outlineView.makeViewWithIdentifier(identifier, owner:self) as? ConfigRowView
		{
			container.locations = theNode.path
			container.textField.stringValue = theNode.title
			container.leftMargin.constant = (1.5 + CGFloat(outlineView.levelForItem(item))) * outlineView.indentationPerLevel+1.0
			return container
		} else {
			return nil
		}
  }
  
  // - (BOOL)outlineView:(NSOutlineView *)outlineView
  // shouldShowOutlineCellForItem:(id)item
  // {
  //      return false
  // }
}
