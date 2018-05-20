//
//  CoreData.swift
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

import CoreData

extension NSManagedObjectContext {

  func entity<T: NSManagedObject>(_ entityClass: T.Type) -> NSEntityDescription?
  {
    let className = NSStringFromClass(entityClass)
    return persistentStoreCoordinator?.managedObjectModel
      .entities.first { $0.managedObjectClassName == className }
  }

  func fetch(
    _ entity: NSEntityDescription?,
    sortDescriptors: [NSSortDescriptor]? = nil,
    withPredicate predicate: NSPredicate? = nil) throws -> [AnyObject]
  {
    if let theEntity = entity {
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>()

      fetchRequest.entity = theEntity
      fetchRequest.predicate = predicate
      fetchRequest.sortDescriptors = sortDescriptors

      return try self.fetch(fetchRequest)
    }
    return []
  }

  func fetch<T: NSManagedObject>(
    _ entityClass: T.Type,
    sortDescriptors: [NSSortDescriptor]? = nil,
    withPredicate predicate: NSPredicate? = nil) throws -> [T]
  {
    return (try fetch(
      entity(entityClass), sortDescriptors: sortDescriptors,
      withPredicate: predicate)) as? [T] ?? []
  }

  func fetch<T: NSManagedObject>(
    _ entityClass: T.Type,
    sortDescriptors: [NSSortDescriptor]? = nil,
    withFormat format: String, _ args: CVarArg ...) throws -> [T]
  {
    return try fetch(
      entityClass,
      sortDescriptors: sortDescriptors,
      withPredicate: withVaList(args) {
        NSPredicate(format: format, arguments: $0)})
  }

  func fetchSingle<T: NSManagedObject>(
    _ entityClass: T.Type,
    sortDescriptors: [NSSortDescriptor]? = nil,
    withPredicate predicate: NSPredicate? = nil) throws -> T?
  {
    let array = try fetch(
      entity(entityClass),
      sortDescriptors: sortDescriptors,
      withPredicate: predicate)

    return array.isEmpty ? nil : (array[0] as? T)
  }

  func fetchSingle<T: NSManagedObject>(
    _ entityClass: T.Type,
    sortDescriptors: [NSSortDescriptor]? = nil,
    withFormat format: String,
    _ args: CVarArg ...) throws -> T?
  {
    return try fetchSingle(
      entityClass, sortDescriptors: sortDescriptors,
      withPredicate: withVaList(args) {
        NSPredicate(format: format, arguments: $0)})
  }

  func insert<T: NSManagedObject>(_ entityClass: T.Type) -> T
  {
    return entityClass.init(
      entity: entity(entityClass)
        ?? { fatalError("no entity for class \(entityClass)") }(),
      insertInto: self)
  }

  func disableUndoRegistration()
  {
    self.processPendingChanges()
    self.undoManager?.disableUndoRegistration()
  }

  func enableUndoRegistration()
  {
    self.processPendingChanges()
    self.undoManager?.enableUndoRegistration()
  }

  func beginActionWithName(_ name: String)
  {
    self.undoManager?.beginUndoGrouping()
    self.undoManager?.setActionName(name)
  }

  func endAction()
  {
    self.undoManager?.endUndoGrouping()
  }
}

extension NSManagedObject {

  class func objectInContext(_ managedObjectContext: NSManagedObjectContext)
    -> Self
  {
    return managedObjectContext.insert(self)
  }

}
