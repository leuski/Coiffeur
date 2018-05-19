//
//  Model.swift
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

import Foundation
import CoreData

class ConfigNodeLocation {
  var index = 0
  var count = 0
  init(_ index: Int, of count: Int) {
    self.index = index
    self.count = count
  }
}

extension ConfigNode {

  typealias Location = ConfigNodeLocation

  var path: [Location] {
    var node: ConfigNode = self
    var locations: [Location] = []

    while true {
      if let parent = node.parent {
        locations.insert(Location(node.index, of: parent.children.count),
                         at: 0)
        node = parent
      } else {
        break
      }
    }
    return locations
  }

  class var typeSeparator: String { return "," }

  class func keyPathsForValuesAffectingFilteredChildrenCount() -> NSSet
  {
    return NSSet(object: "filteredChildren")
  }

  class func keyPathsForValuesAffectingIndex() -> NSSet
  {
    return NSSet(object: "storedIndex")
  }

  @objc var leaf: Bool { return false }
  @objc var documentation: String { return "" }
  @objc var type: String { return "" }
  @objc var name: String { return "" }

  var tokens: [String] {
    let type = self.type
    return type.components(separatedBy: ConfigNode.typeSeparator).filter {
      !$0.isEmpty }
  }

  var predicate: NSPredicate? {
    get { return self.privateGetPredicate() }
    set (value) { self.privateSetPredicate(value) }
  }

  @objc var filteredChildrenCount: Int {
    return 0
  }

  @objc var filteredChildren: NSArray {
    return []
  }

  var depth: Int {
    if let parent = self.parent {
      return 1 + parent.depth
    } else {
      return 0
    }
  }

  // this is a an alias to hide the type conversion
  // Swift is VERY annoyning about not accepting Int and Int32 in the
  // same expression wuthout an explicit type conversion. We do it here
  // and hide the actual size from the user
  var index: Int {
    get { return Int(self.storedIndex) }
    set (value) { self.storedIndex = Int32(value) }
  }

  @objc @discardableResult
  class func objectInContext(_ managedObjectContext: NSManagedObjectContext,
                             parent: ConfigNode? = nil,
                             title: String = "") -> Self
  {
    return _insertConfigNode(managedObjectContext, parent: parent, title: title)
  }

  fileprivate class func _insertConfigNode<T: ConfigNode>(
    _ managedObjectContext: NSManagedObjectContext,
    parent: ConfigNode?,
    title: String) -> T
  {
    guard let node = super.objectInContext(managedObjectContext) as? T else {
      fatalError()
    }
    node.parent = parent
    node.title = title
    return node
  }

  @objc func sortAndIndexChildren()
  {

  }

  // HACK As of Swift 1.2 the compiler complains that
  // it cannot override declarations in extensions. Working around...
  @objc func privateSetPredicate(_ value: NSPredicate?)
  {
  }
  @objc func privateGetPredicate() -> NSPredicate?
  {
    return self.parent?.predicate
  }
}

extension ConfigOption {
  override var leaf: Bool { return true }

  // I cannot override non-stored property with a stored property
  // And I do not want to have these properties stored on Section nodes
  // so I alias them to different variables
  override var documentation: String {
    get { return self.storedDetails }
    set (value) { self.storedDetails = value }
  }

  override var type: String {
    get { return self.storedType }
    set (value) { self.storedType = value }
  }

  override var name: String {
    get { return self.indexKey }
  }

  class func keyPathsForValuesAffectingDocumentation() -> NSSet
  {
    return NSSet(object: "storedDetails")
  }

  class func keyPathsForValuesAffectingName() -> NSSet
  {
    return NSSet(object: "indexKey")
  }

  class func keyPathsForValuesAffectingType() -> NSSet
  {
    return NSSet(object: "storedType")
  }

  override class func objectInContext(
    _ managedObjectContext: NSManagedObjectContext,
    parent: ConfigNode? = nil,
    title: String = "") -> Self
  {
    return _insertConfigOption(managedObjectContext, parent: parent, title: title)
  }

  fileprivate class func _insertConfigOption<T: ConfigOption>(
    _ managedObjectContext: NSManagedObjectContext,
    parent: ConfigNode?, title: String) -> T
  {
    guard let option = super.objectInContext(managedObjectContext) as? T else {
      fatalError()
    }
    option.title = title
    option.parent = parent
    option.documentation = ""
    option.type = ""
    option.indexKey = ""
    return option
  }

}

extension ConfigSection {
  fileprivate struct Private {
    static let titleSortDescriptors = [NSSortDescriptor(key: "title",
                                                        ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))]
    // we want to put "other..." subsection at the end of each section list.
    // we add a hidden character (non-breaking space) at the beginning
    // of the "other..." title, so sorting should sort titles in the order
    // we need.
    // you cannot use localized... message to sort the titles, this trick
    // does not work. It looks like localized...compare strips the space out.
  }

  // I want to cache filtered children, so I do not run the filter unnecessarily
  // the cache goes into storedFilteredChildren
  // I need to reset the cache every time the predicate is updated
  fileprivate var _filteredChildren: NSOrderedSet {
    if let predicate = self.predicate {
      return self.children.filtered(using: predicate)
    } else {
      return self.children
    }
  }

  override var filteredChildrenCount: Int {
    return self.filteredChildren.count
  }

  override var filteredChildren: NSArray {
    if let array = self.storedFilteredChildren as? NSArray {
      return array
    }
    let array = self._filteredChildren.array as NSArray
    self.storedFilteredChildren = array
    return array
  }

  override func sortAndIndexChildren()
  {
    mutableOrderedSetValue(forKey: "children").sort(
      using: Private.titleSortDescriptors)
    var index = 0
    for case let node as ConfigNode in self.children {
      node.index = index
      index += 1
      node.sortAndIndexChildren()
      guard let section = node as? ConfigSection else { continue }

      var indexString = ""
      var sectionNode: ConfigSection? = section
      for _ in 0...self.depth {
        indexString = "\((sectionNode?.index ?? 0)+1).\(indexString)"
        sectionNode = sectionNode?.parent as? ConfigSection
      }
      let digitsInCount = _digitsIn(section.parent!.children.count)
      let digitsInIndex = _digitsIn(section.index+1)
      let numberMargin = digitsInCount - digitsInIndex
      for _ in 0 ..< numberMargin {
        indexString = "\u{2007}\(indexString)"
      }
      section.title = "\(indexString) \(section.title)"
    }
  }

  override func privateSetPredicate(_ value: NSPredicate?)
  {
    willChangeValue(forKey: "filteredChildren")
    self.storedFilteredChildren = nil
    for case let node as ConfigNode in self.children {
      node.predicate = value
    }
    didChangeValue(forKey: "filteredChildren")
  }

  fileprivate func _digitsIn(_ number: Int) -> Int
  {
    return Int(floor(log10(Double(number))))
  }
}

extension ConfigRoot {
  class func keyPathsForValuesAffectingPredicate() -> NSSet
  {
    return NSSet(object: "storedPredicate")
  }

  override func privateSetPredicate(_ value: NSPredicate?)
  {
    self.storedPredicate = value
    super.privateSetPredicate(value)
  }

  override func privateGetPredicate() -> NSPredicate?
  {
    return self.storedPredicate as? NSPredicate
  }

}
