//
//  CoiffeurView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

@objc(ALCoiffeurView)
class ALCoiffeurView : NSViewController, NSOutlineViewDelegate {
  
  @IBOutlet weak var optionsView : NSOutlineView?
  @IBOutlet var optionsController : NSTreeController?
  var optionsSortDescriptors : [NSSortDescriptor]?
  weak var model : ALCoiffeurController?
  
  @IBOutlet weak var jumpMenu : NSPopUpButton?
  
  var managedObjectContext : NSManagedObjectContext? {
    return self.model?.managedObjectContext
  }
  
  var root : ConfigRoot? {
    return self.model?.root
  }
  
  var predicate : NSPredicate? {
    get {
      return self.model?.root?.predicate
    }
    set (newPredicate) {
      self.model?.root?.predicate = newPredicate
    }
  }
  
  private var myContext : UnsafeMutablePointer<Void> { return unsafeBitCast(self, UnsafeMutablePointer<Void>.self) }
  
  init?(model:ALCoiffeurController?, bundle:NSBundle?)
  {
    super.init(nibName: "ALCoiffeurView", bundle: bundle)
    self.model = model
    self.optionsSortDescriptors = [NSSortDescriptor(key: ConfigNode.TitleKey,
      ascending: true, comparator: {(o1:AnyObject!, o2:AnyObject!) -> NSComparisonResult in
        return (o1 as NSString).compare(o2 as NSString, options:NSStringCompareOptions.CaseInsensitiveSearch)
    })]
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
    self.optionsController?.addObserver(self, forKeyPath:"content", options:NSKeyValueObservingOptions.New, context:self.myContext)
  }
  
  override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>)
  {
    if (context != self.myContext) {
      return
    }
    
    self.optionsController?.removeObserver(self, forKeyPath:"content")
    self.optionsView?.expandItem(nil, expandChildren:true)
    
    var foundNode = false
    var node : NSTreeNode?
    
    for node = self.optionsController?.arrangedObjects as? NSTreeNode;
      node?.childNodes?.count != nil && node!.childNodes!.count > 0;
      node = node!.childNodes![0] as? NSTreeNode
    {
      foundNode = true
    }
    
    if foundNode && node != nil {
      self.optionsController?.setSelectionIndexPath(node!.indexPath)
    }
    
    self._fillMenu()
  }
  
  private func allNodes() -> [AnyObject]
  {
    var array = [AnyObject]()
    
    self._fillNodeArray(&array, atNode:self.optionsController!.arrangedObjects)
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
    
    var sections = allNodes.filter { $0.representedObject is ConfigSubsection }
    
    sections.sort {
      var obj1 = $0.representedObject as ConfigNode
      var obj2 = $1.representedObject as ConfigNode
      var d1 = obj1.depth
      var d2 = obj2.depth
      
      while (d1 > d2) {
        if (obj1.parent == obj2) {
          return false
        }
        
        obj1 = obj1.parent!
        --d1;
      }
      
      while (d2 > d1) {
        if (obj2.parent == obj1) {
          return true
        }
        
        obj2 = obj2.parent!
        --d2;
      }
      
      while (obj1.parent != obj2.parent) {
        obj1 = obj1.parent!
        --d1;
        obj2 = obj2.parent!
        --d2;
      }
      
      return obj1.title.compare(obj2.title, options:NSStringCompareOptions.CaseInsensitiveSearch) == NSComparisonResult.OrderedAscending
    }
    
    for var i = self.jumpMenu!.numberOfItems - 1; i >= 1; --i {
      self.jumpMenu!.removeItemAtIndex(i)
    }
    
    for node in sections {
      var item    = NSMenuItem()
      let section = node.representedObject as ConfigSubsection
      item.title = section.title;
      item.indentationLevel  = section.depth - 1;
      item.representedObject = node;
      self.jumpMenu!.menu?.addItem(item)
    }
    
    self.jumpMenu!.preferredEdge = NSMaxYEdge;
  }
  
  @IBAction func jumpToSection(sender:AnyObject)
  {
    if let popup = sender as? NSPopUpButton {
      self.optionsView!.scrollRowToVisible(self.optionsView!.rowForItem(popup.selectedItem?.representedObject))
    }
  }
  
  func outlineView(outlineView:NSOutlineView, isGroupItem item:AnyObject) -> Bool
  {
    if let node = item.representedObject as? ConfigNode {
      return !node.leaf
    }
    return false
  }
  
  func outlineView(outlineView:NSOutlineView, viewForTableColumn tableColumn:NSTableColumn?, item:AnyObject) -> NSView?
  {
    if let node = item.representedObject as? ConfigNode {
      let tokens = node.tokens
      
      if node is ConfigRoot {
        return outlineView.makeViewWithIdentifier("view.root", owner:self) as NSView?
      } else if (tokens.count == 0) {
        return outlineView.makeViewWithIdentifier("view.section", owner:self) as NSView?
      } else if (tokens.count == 1 && tokens[0] == ALCoiffeurController.OptionType.Signed.rawValue) {
        return outlineView.makeViewWithIdentifier("view.number", owner:self) as NSView?
      } else if (tokens.count == 1 && tokens[0] == ALCoiffeurController.OptionType.Unsigned.rawValue) {
        return outlineView.makeViewWithIdentifier("view.number", owner:self) as NSView?
      } else if (tokens.count == 1) {
        return outlineView.makeViewWithIdentifier("view.string", owner:self) as NSView?
      } else {
        if let view = outlineView.makeViewWithIdentifier("view.choice", owner:self) as NSView? {
          for v in view.subviews {
            if let segmented = v as? NSSegmentedControl {
              segmented.setLabels(tokens)
              break
            }
          }
          return view
        }
      }
    }
    return nil
  }
  
  func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat
  {
    if let view = self.outlineView(outlineView, viewForTableColumn:nil, item:item) {
      return view.frame.size.height
    }
    return 0
  }
  
  func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool
  {
    return !self.outlineView(outlineView, isGroupItem:item)
  }
  
  func outlineView(outlineView: NSOutlineView, rowViewForItem item: AnyObject) -> NSTableRowView?
  {
    let aNode = item.representedObject as? ConfigNode
    if aNode == nil || !aNode!.leaf {
      return nil
    }
    
    let node = aNode!
    
    let offset = Int(CGFloat(1 + outlineView.levelForItem(item)) * outlineView.indentationPerLevel + 3)
    
    var container   = NSTableRowView()
    
    let smallSystemFontSize = NSFont.systemFontSizeForControlSize(NSControlSize.SmallControlSize)
    var childView   = NSTextField()
    childView.editable        = false
    childView.selectable      = false
    childView.bordered        = false
    childView.drawsBackground = false
    childView.font = NSFont.systemFontOfSize(smallSystemFontSize)
    childView.translatesAutoresizingMaskIntoConstraints = false
    childView.stringValue = node.title
    container.addSubview(childView)
    
    
    let views   = ["childView":childView]
    let   hFormat = String(format:"H:|-%d-[childView]|", offset)
    
    container.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(hFormat, options:NSLayoutFormatOptions(), metrics:nil, views:views))
    
    container.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-2-[childView]", options:NSLayoutFormatOptions(), metrics:nil, views:views))
    
    return container
  }
  
  // - (BOOL)outlineView:(NSOutlineView *)outlineView
  // shouldShowOutlineCellForItem:(id)item
  // {
  //      return false
  // }
}
