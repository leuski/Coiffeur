//
//  Model.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation
import CoreData

extension ConfigNode {
  
  class var TypeSeparator : String { return "," }
  class var TitleKey : String { return "title" }
  
	class func keyPathsForValuesAffectingFilteredChildrenCount() -> NSSet
	{
		return NSSet(object:"filteredChildren")
	}

	class func keyPathsForValuesAffectingIndex() -> NSSet
	{
		return NSSet(object:"storedIndex")
	}

  var leaf : Bool { return false }
  var documentation : String { return "" }
  var type : String { return "" }
  var name : String { return "" }
  
  var tokens : [String] {
    let t = self.type
    return t.componentsSeparatedByString(ConfigNode.TypeSeparator).filter { !$0.isEmpty }
  }

	var predicate : NSPredicate? {
		get { return self._getPredicate() }
		set (value) { self._setPredicate(value) }
	}
	
	var filteredChildrenCount : Int {
		return 0
	}
	
	var filteredChildren : NSArray {
		return []
	}
	
  var depth : Int {
    if let p = self.parent {
      return 1 + p.depth
    } else {
      return 0
    }
  }
	
	// this is a an alias to hide the type conversion
	// Swift is VERY annoyning about not accepting Int and Int32 in the 
	// same expression wuthout an explicit type conversion. We do it here 
	// and hide the actual size from the user
	var index : Int {
		get { return Int(self.storedIndex) }
		set (value) { self.storedIndex = Int32(value) }
	}
	
  override class func objectInContext(managedObjectContext: NSManagedObjectContext) -> Self
  {
		return _insertConfigNode(managedObjectContext)
  }
	
	private class func _insertConfigNode<T:ConfigNode>(managedObjectContext: NSManagedObjectContext) -> T
	{
		var node = super.objectInContext(managedObjectContext) as! T
		node.title = ""
		return node
	}
	
	func sortAndIndexChildren()
	{
		
	}
	
	// this is a hack. As of Swift 1.2 the compiler complains that 
	// it cannot override declarations in extensions. Working around...
	func _setPredicate(value:NSPredicate?)
	{
	}
	func _getPredicate() -> NSPredicate?
	{
		return self.parent?.predicate
	}
}

extension ConfigOption {
  override var leaf : Bool { return true }
	
	// I cannot override non-stored property with a stored property
	// And I do not want to have these properties stored on Section nodes
	// so I alias them to different variables
  override var documentation : String {
    get { return self.storedDetails }
    set (value) { self.storedDetails = value }
  }

  override var type : String {
    get { return self.storedType }
    set (value) { self.storedType = value }
  }

  override var name : String {
    get { return self.indexKey }
  }

  class func keyPathsForValuesAffectingDocumentation() -> NSSet
  {
    return NSSet(object:"storedDetails")
  }

  class func keyPathsForValuesAffectingName() -> NSSet
  {
    return NSSet(object:"indexKey")
  }

  class func keyPathsForValuesAffectingType() -> NSSet
  {
    return NSSet(object:"storedType")
  }

  override class func objectInContext(managedObjectContext: NSManagedObjectContext) -> Self
  {
		return _insertConfigOption(managedObjectContext)
  }

	private class func _insertConfigOption<T:ConfigOption>(managedObjectContext: NSManagedObjectContext) -> T
	{
		var option = super.objectInContext(managedObjectContext) as! T
		option.title = ""
		option.documentation = ""
		option.type = ""
		option.indexKey = ""
		return option
	}

}

extension ConfigSection {
	private struct Private {
		static let titleSortDescriptors = [NSSortDescriptor(key: "title",
			ascending: true, selector: Selector("localizedCaseInsensitiveCompare:"))]
	}
	
	// I want to cache filtered children, so I do not run the filter unnecessarily
	// the cache goes into storedFilteredChildren
	// I need to reset the cache every time the predicate is updated 
	private var _filteredChildren : NSOrderedSet {
		if let p = self.predicate {
			return self.children.filteredOrderedSetUsingPredicate(p)
		} else {
			return self.children
		}
	}
	
	override var filteredChildrenCount : Int {
		return self.filteredChildren.count
	}
	
	override var filteredChildren : NSArray {
		if let array = self.storedFilteredChildren as? NSArray {
			return array
		}
		self.storedFilteredChildren = self._filteredChildren.array as NSArray
		return self.storedFilteredChildren as! NSArray
	}
	
	override func sortAndIndexChildren()
	{
		mutableOrderedSetValueForKey("children").sortUsingDescriptors(Private.titleSortDescriptors)
		var i = 0
		for node in self.children {
			(node as! ConfigNode).index = i++
			(node as! ConfigNode).sortAndIndexChildren()
		}
	}
	
	override func _setPredicate(value:NSPredicate?)
	{
		willChangeValueForKey("filteredChildren")
		self.storedFilteredChildren = nil
		for node in self.children {
			(node as! ConfigNode).predicate = value
		}
		didChangeValueForKey("filteredChildren")
	}
}

extension ConfigRoot {
	class func keyPathsForValuesAffectingPredicate() -> NSSet
  {
    return NSSet(object:"storedPredicate")
  }

	override func _setPredicate(value:NSPredicate?)
	{
		self.storedPredicate = value
		super._setPredicate(value)
	}

	override func _getPredicate() -> NSPredicate?
	{
		return self.storedPredicate as! NSPredicate?
	}

}
















