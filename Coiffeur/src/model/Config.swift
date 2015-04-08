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
  
  class func keyPathsForValuesAffectingFilteredChildren() -> NSSet
  {
    return NSSet(array:["predicate", "children" ])
  }
  
  class func keyPathsForValuesAffectingPredicate() -> NSSet
  {
    return NSSet(object:"parent.predicate")
  }
  
  var leaf : Bool { return false }
  
  var tokens : [String] {
    if let t = self.type {
      return t.componentsSeparatedByString(ConfigNode.TypeSeparator)
    } else {
      return []
    }
  }

  var predicate : NSPredicate? { return self.parent?.predicate }
  
  var filteredChildren : NSSet {
    if let p = self.predicate {
      return self.children.filteredSetUsingPredicate(p)
    } else {
      return self.children
    }
  }
  
  var depth : Int {
    if let p = self.parent {
      return 1 + p.depth
    } else {
      return 0
    }
  }
  
  private class func _insert<SelfType:ConfigNode>(#managedObjectContext: NSManagedObjectContext) -> SelfType
  {
    var node = super.objectInContext(managedObjectContext) as ConfigNode
    node.title = ""
    return node as SelfType
  }

  override class func objectInContext(managedObjectContext: NSManagedObjectContext) -> Self
  {
    return _insert(managedObjectContext:managedObjectContext)
  }
}

extension ConfigOption {
  override var leaf : Bool { return true }
  
  override class func objectInContext(managedObjectContext: NSManagedObjectContext) -> ConfigOption
  {
    var option = super.objectInContext(managedObjectContext) as ConfigOption
    option.title = ""
    option.documentation = ""
    option.name = ""
    option.type = ""
    option.indexKey = ""
    return option
  }

}

extension ConfigRoot {
  
  override class func keyPathsForValuesAffectingPredicate() -> NSSet
  {
    return NSSet(object:"storedPredicate")
  }

  override var predicate : NSPredicate? {
    get {
      return self.storedPredicate as NSPredicate?
    }
    set (newPredicate) {
      self.storedPredicate = newPredicate
    }
  }
  
  override var filteredChildren : NSSet {
    return self.children
  }
  
}