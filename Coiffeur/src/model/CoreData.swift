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
    let mom = self.persistentStoreCoordinator!.managedObjectModel
    let className = NSStringFromClass(entityClass)
    for entity in mom.entities {
      if className == entity.managedObjectClassName {
        return entity
      }
    }
    return nil
  }

  func fetch(_ entity: NSEntityDescription?, sortDescriptors: [NSSortDescriptor]? = nil,
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

  func fetch<T: NSManagedObject>(_ entityClass: T.Type,
                                 sortDescriptors: [NSSortDescriptor]? = nil,
                                 withPredicate predicate: NSPredicate? = nil) throws -> [T]
  {
    return (try fetch(entity(entityClass), sortDescriptors: sortDescriptors,
                      withPredicate: predicate)) as? [T] ?? []
  }

  func fetch<T: NSManagedObject>(_ entityClass: T.Type,
                                 sortDescriptors: [NSSortDescriptor]? = nil,
                                 withFormat format: String, _ args: CVarArg ...) throws -> [T]
  {
    return try fetch(entityClass, sortDescriptors: sortDescriptors,
                     withPredicate: withVaList(args) {NSPredicate(format: format, arguments: $0)})
  }

  func fetchSingle<T: NSManagedObject>(_ entityClass: T.Type,
                                       sortDescriptors: [NSSortDescriptor]? = nil,
                                       withPredicate predicate: NSPredicate? = nil) throws -> T?
  {
    let array = try fetch(entity(entityClass),
                          sortDescriptors: sortDescriptors, withPredicate: predicate)

    return array.isEmpty ? nil : (array[0] as? T)
  }

  func fetchSingle<T: NSManagedObject>(_ entityClass: T.Type,
                                       sortDescriptors: [NSSortDescriptor]? = nil, withFormat format: String,
                                       _ args: CVarArg ...) throws -> T?
  {
    return try fetchSingle(entityClass, sortDescriptors: sortDescriptors,
                           withPredicate: withVaList(args) {NSPredicate(format: format, arguments: $0)})
  }

  func insert<T: NSManagedObject>(_ entityClass: T.Type) -> T
  {
    return entityClass.init(entity: entity(entityClass)!,
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

//extension NSManagedObjectModel {
//
//  // HACK: Swift classes are namespaced. So when editing CoreData model
//  // we need to specify a fully-qualified class name for model classes.
//  // As of XCode 6.3, CoreData source generation fails when the class name
//  // contains a period.
//  // Moreover, if you decide to import the model into a different target,
//  // things will break as the original module name is hardcoded in the
//  // model file.
//  // Moreover, if you create a test case in the original project,
//  // the test case will have a different target name and, hence, a different
//  // module name. And, the model will break.
//  //
//  // Here we assume that the model file contains unqualified class names and
//  // we add the module name.
//  func copyForModuleWithClass(_ clazz:NSObject.Type) -> NSManagedObjectModel
//  {
//    let moduleName : String
//    let className = clazz.className()
//    if let range = className.range(of: ".") {
//      moduleName = "\(className[className.startIndex..<range.lowerBound])."
//    } else {
//      moduleName = ""
//    }
//    return copyForModuleWithName(moduleName)
//  }
//
//  func copyForModuleWithName(_ moduleName: String) -> NSManagedObjectModel
//  {
//    if moduleName.isEmpty { return self }
//
//    let momCopy = NSManagedObjectModel()
//    var entityCache : Dictionary<String, NSEntityDescription> = [:]
//    var newEntities : [NSEntityDescription] = []
//
//    for e in self.entities {
//      newEntities.append(e.copyWithModuleName(moduleName, cache:&entityCache))
//    }
//
//    momCopy.entities = newEntities
//    return momCopy
//  }
//}
//
//extension NSEntityDescription {
//
//  typealias Cache = Dictionary<String, NSEntityDescription>
//
//  func copyWithModuleName(_ moduleName: String, cache:inout Cache)
//    -> NSEntityDescription
//  {
//    if moduleName.isEmpty { return self }
//
//    let entityName = self.name!
//    if let existingEntity = cache[entityName] {
//      return existingEntity
//    }
//
//    let newEntity = copy() as! NSEntityDescription
//    cache[entityName] = newEntity
//
//    if newEntity.managedObjectClassName == NSManagedObject.className() {
//      newEntity.managedObjectClassName = self.managedObjectClassName
//    } else {
//      newEntity.managedObjectClassName
//        = "\(moduleName)\(self.managedObjectClassName)"
//    }
//    var newSubEntities : [NSEntityDescription] = []
//
//    for e in newEntity.subentities {
//      newSubEntities.append(e.copyWithModuleName(moduleName, cache:&cache))
//    }
//
//    newEntity.subentities = newSubEntities
//    return newEntity
//  }
//}
//
