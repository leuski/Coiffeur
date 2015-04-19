//
//  CoiffeurView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa
import Carbon

class CoiffeurView : NSViewController, NSOutlineViewDelegate {
  
  @IBOutlet weak var optionsView : NSOutlineView!
  @IBOutlet weak var jumpMenu : NSPopUpButton!
  @IBOutlet var optionsController : NSTreeController!

  var optionsSortDescriptors : [NSSortDescriptor]!
	weak var model : CoiffeurController?
  
	private var rowHeightCache = Dictionary<String,CGFloat>()

  private var myContext : UnsafeMutablePointer<Void> { return unsafeBitCast(self, UnsafeMutablePointer<Void>.self) }
  
  init?(model:CoiffeurController, bundle:NSBundle?)
  {
    super.init(nibName: "CoiffeurView", bundle: bundle)
    self.model = model
    let c : NSComparator = {(o1:AnyObject!, o2:AnyObject!) -> NSComparisonResult in
      return (o1 as! String).compare(o2 as! String, options:NSStringCompareOptions.CaseInsensitiveSearch)
    }
    self.optionsSortDescriptors = [NSSortDescriptor(key: ConfigNode.TitleKey, ascending: true, comparator: c)]
  }
  
  required init?(coder: NSCoder) {
    super.init(coder:coder)
  }
  
  func embedInView(container:NSView)
  {
    let childView : NSView = self.view
    
    container.addSubview(childView)
    
    childView.translatesAutoresizingMaskIntoConstraints = false
    
    container.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[childView]|",
      options:NSLayoutFormatOptions(), metrics:nil, views:["childView":childView]))
    container.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[childView]|",
      options:NSLayoutFormatOptions(), metrics:nil, views:["childView":childView]))
    container.window?.initialFirstResponder = self.optionsView
  }
  
  override func viewDidLoad()
  {
    super.viewDidLoad()
		_finishSettingUpView()
//    self.optionsController.addObserver(self, forKeyPath:"content", options:NSKeyValueObservingOptions.New, context:self.myContext)
  }
	
	override func viewWillDisappear()
	{
//		self.view.removeFromSuperviewWithoutNeedingDisplay()
//		self.optionsController.setSelectionIndexPaths([])
//		self.model = nil
//		self.optionsController = nil
		super.viewWillDisappear()
	}
	
  override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>)
  {
    if (context != self.myContext) {
      return
    }
    
    self.optionsController.removeObserver(self, forKeyPath:"content")
		
    _finishSettingUpView()
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
	
  private func allNodes() -> [AnyObject]
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
    let allNodes = self.allNodes()
    
    var sections = allNodes.filter { $0.representedObject is ConfigSection }
    
    for var i = self.jumpMenu.numberOfItems - 1; i >= 1; --i {
      self.jumpMenu.removeItemAtIndex(i)
    }
    
    for node in sections {
      var item    = NSMenuItem()
      let section = node.representedObject as! ConfigSection
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
  
  func outlineView(outlineView:NSOutlineView, isGroupItem item:AnyObject) -> Bool
  {
    if let node = item.representedObject as? ConfigNode {
      return !node.leaf
    }
    return false
  }
	
	private func _outlineView(outlineView:NSOutlineView, viewIdentifierForItem item:AnyObject) -> String?
	{
		if let node = item.representedObject as? ConfigNode {
			let tokens = node.tokens
			if node is ConfigRoot {
				return "view.root"
			} else if (tokens.count == 0) {
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
		if let identifier = _outlineView(outlineView, viewIdentifierForItem:item),
			 let view = outlineView.makeViewWithIdentifier(identifier, owner:self) as! NSView?,
			 let node = item.representedObject as? ConfigNode
		{
			if identifier == "view.choice" {
				for v in view.subviews {
					if let segmented = v as? NSSegmentedControl {
						segmented.setLabels(node.tokens)
						break
					}
				}
			}
			return view
		}
    return nil
  }
  
  func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat
  {
		if let identifier = _outlineView(outlineView, viewIdentifierForItem:item) {
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
    let optionalNode = item.representedObject as? ConfigNode
    if optionalNode == nil  {
      return nil
    }
    
    let theNode = optionalNode!
    
		var node : ConfigNode = theNode
		var locations : [OutlineRowView.Location] = []
		
		while true {
			if let parent = node.parent {
				locations.insert(OutlineRowView.Location(node.index, of:parent.children.count), atIndex:0)
				node = parent
			} else {
				break
			}
		}

		var container   = OutlineRowView()
		container.locations = locations
		
    var childView   = NSTextField()
    childView.editable        = false
    childView.selectable      = false
    childView.bordered        = false
    childView.drawsBackground = false
    childView.translatesAutoresizingMaskIntoConstraints = false
    childView.stringValue = theNode.title
    container.addSubview(childView)

		let hOffset = Int((1.5 + CGFloat(outlineView.levelForItem(item))) * outlineView.indentationPerLevel+1.0)
    var vOffset = 0
    if theNode is ConfigOption {
      let fontSize = NSFont.systemFontSizeForControlSize(NSControlSize.SmallControlSize)
      childView.font = NSFont.systemFontOfSize(fontSize)
      vOffset = 2
    } else {
      let fontSize = NSFont.systemFontSizeForControlSize(NSControlSize.RegularControlSize)
      childView.font = NSFont.boldSystemFontOfSize(fontSize)
      childView.textColor = NSColor.secondaryLabelColor()
      childView.backgroundColor = NSColor.controlBackgroundColor()
      vOffset = 3
    }
    
    let views   = ["childView":childView]
    
    container.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-\(hOffset)-[childView]|",
      options:NSLayoutFormatOptions(), metrics:nil, views:views))
    
    container.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-\(vOffset)-[childView]",
      options:NSLayoutFormatOptions(), metrics:nil, views:views))
    
    return container
  }
  
  // - (BOOL)outlineView:(NSOutlineView *)outlineView
  // shouldShowOutlineCellForItem:(id)item
  // {
  //      return false
  // }
}
