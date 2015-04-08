//
//  CoreData.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
  
  func fetchEntity(entity:NSEntityDescription?, withPredicate predicate: NSPredicate? = nil, error: NSErrorPointer = nil) -> [AnyObject]
  {
    if let theEntity = entity {
      
      var fetchRequest = NSFetchRequest()
      
      fetchRequest.entity = theEntity
      fetchRequest.predicate = predicate;
      
      var fetchError : NSError?
      let result = self.executeFetchRequest(fetchRequest, error: &fetchError)
      
      if let err = fetchError {
        if error != nil {
          error.memory = err
        }
        return []
      }
      
      if let res = result {
        return res
      }
    }
    
    return []
  }

  func fetch(entityName:String?, withPredicate predicate: NSPredicate? = nil, error: NSErrorPointer = nil) -> [AnyObject]
  {
    if let name = entityName {
      return fetchEntity(NSEntityDescription.entityForName(name, inManagedObjectContext: self), withPredicate:predicate, error:error)
    }
    return []
  }
  
  func fetch<T:NSManagedObject>(entityClass:T.Type, withPredicate predicate: NSPredicate? = nil, error: NSErrorPointer = nil) -> [T]
  {
    return fetchEntity(entityClass.entityInContext(self), withPredicate:predicate, error:error) as [T]
  }

  func fetchSingle(entityName:String, withPredicate predicate: NSPredicate?, error: NSErrorPointer) -> NSManagedObject?
  {
    let array = self.fetch(entityName, withPredicate: predicate, error: error)
    return array.isEmpty ? nil : (array[0] as NSManagedObject)
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
  
  func beginActionWithName(name:String)
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
  
  class func entityInContext(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription
  {
    let mom = managedObjectContext.persistentStoreCoordinator!.managedObjectModel
    let className = NSStringFromClass(self)
    for entity in mom.entities {
      if className == entity.managedObjectClassName {
        return entity as NSEntityDescription
      }
    }
    return NSEntityDescription()
  }

  class func entityNameInContext(managedObjectContext: NSManagedObjectContext) -> String
  {
    return entityInContext(managedObjectContext).name!
  }
  
  class func objectInContext(managedObjectContext: NSManagedObjectContext) -> Self
  {
    return _insert(managedObjectContext: managedObjectContext)
  }
  
  private class func _insert<SelfType>(#managedObjectContext: NSManagedObjectContext) -> SelfType
  {
    let entityName = self.entityNameInContext(managedObjectContext)
    return (NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext:  managedObjectContext) as SelfType)
  }

  class func allObjectsInContext(managedObjectContext:NSManagedObjectContext, withPredicate predicate: NSPredicate? = nil, error:NSErrorPointer = nil) -> [AnyObject]
  {
    return managedObjectContext.fetch(self, withPredicate: predicate, error: error)
  }

  private class func _allObjects<SelfType:NSManagedObject>(#managedObjectContext: NSManagedObjectContext, withPredicate predicate:NSPredicate?, error:NSErrorPointer) -> [SelfType]
  {
    return managedObjectContext.fetch(SelfType.self, withPredicate: predicate, error: error)
  }


  private class func _first<SelfType>(#managedObjectContext: NSManagedObjectContext, withPredicate predicate:NSPredicate?, error:NSErrorPointer) -> SelfType?
  {
    let entityName = self.entityNameInContext(managedObjectContext)
    return (managedObjectContext.fetchSingle(entityName, withPredicate: predicate, error: error) as SelfType?)
  }

  class func firstObjectInContext(managedObjectContext:NSManagedObjectContext, withPredicate predicate:NSPredicate? = nil, error:NSErrorPointer = nil) -> Self?
  {
    return _first(managedObjectContext: managedObjectContext, withPredicate: predicate, error: error)
  }
  
}

 