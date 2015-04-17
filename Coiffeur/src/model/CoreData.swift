//
//  CoreData.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import CoreData

enum FetchResult<T:AnyObject> {
	case Success([T])
	case Failure(NSError)
}

enum FetchSingleResult<T:AnyObject> {
	case None
	case Success(T)
	case Failure(NSError)
}

extension NSManagedObjectContext {
  
	func entity<T:NSManagedObject>(entityClass:T.Type) -> NSEntityDescription?
	{
		let mom = self.persistentStoreCoordinator!.managedObjectModel
		let className = NSStringFromClass(entityClass)
		for entity in mom.entities {
			if className == entity.managedObjectClassName {
				return entity as? NSEntityDescription
			}
		}
		return nil
	}

	func fetch(entity:NSEntityDescription?, withPredicate predicate: NSPredicate? = nil, sortDescriptors:[AnyObject]? = nil) -> FetchResult<AnyObject>
	{
		if let theEntity = entity {
			var fetchRequest = NSFetchRequest()
			
			fetchRequest.entity = theEntity
			fetchRequest.predicate = predicate
			fetchRequest.sortDescriptors = sortDescriptors
			
			var fetchError : NSError?
			if let result = self.executeFetchRequest(fetchRequest, error: &fetchError) {
				return FetchResult<AnyObject>.Success(result)
			} else {
				return FetchResult<AnyObject>.Failure(fetchError ?? Error(format:"Unknown error"))
			}
		}
		return FetchResult<AnyObject>.Success([])
	}

	func fetch<T:NSManagedObject>(entityClass:T.Type, withPredicate predicate: NSPredicate? = nil, sortDescriptors:[AnyObject]? = nil) -> FetchResult<T>
	{
		switch fetch(entity(entityClass), withPredicate:predicate, sortDescriptors:sortDescriptors) {
		case .Success(let array):
			return FetchResult<T>.Success(array as! [T])
		case .Failure(let error):
			return FetchResult<T>.Failure(error)
		}
	}

	func fetchSingle<T:NSManagedObject>(entityClass:T.Type, withPredicate predicate: NSPredicate? = nil, sortDescriptors:[AnyObject]? = nil) -> FetchSingleResult<T>
	{
		switch fetch(entity(entityClass), withPredicate:predicate, sortDescriptors:sortDescriptors) {
		case .Success(let array):
			return array.isEmpty ? FetchSingleResult<T>.None : FetchSingleResult<T>.Success(array[0] as! T)
		case .Failure(let error):
			return FetchSingleResult<T>.Failure(error)
		}
	}
	
	func insert<T:NSManagedObject>(entityClass:T.Type) -> T
	{
		return entityClass(entity:entity(entityClass)!, insertIntoManagedObjectContext:self)
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
  
//  class func entityInContext(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription?
//  {
//    let mom = managedObjectContext.persistentStoreCoordinator!.managedObjectModel
//    let className = NSStringFromClass(self)
//    for entity in mom.entities {
//      if className == entity.managedObjectClassName {
//        return entity as? NSEntityDescription
//      }
//    }
//    return nil
//  }
//
//  class func entityNameInContext(managedObjectContext: NSManagedObjectContext) -> String?
//  {
//    return entityInContext(managedObjectContext)?.name
//  }
//  

	class func objectInContext(managedObjectContext: NSManagedObjectContext) -> Self
  {
    return managedObjectContext.insert(self)
  }
	
}

 