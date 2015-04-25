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
	init(_ error:NSError)
	{
		self = .Failure(error)
	}
	
	init(_ value:[T])
	{
		self = .Success(value)
	}
}

// I get a compiler error if I try to use this type as of Swift 1.2
enum FetchSingleResult<T:AnyObject> {
	case None
	case Success(T)
	case Failure(NSError)
	
	init()
	{
		self = .None
	}
	
	init(error:NSError)
	{
		self = .Failure(error)
	}
	
	init(_ value:T)
	{
		self = .Success(value)
	}
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

	func fetch(entity:NSEntityDescription?, sortDescriptors:[AnyObject]? = nil,
		withPredicate predicate: NSPredicate? = nil) -> FetchResult<AnyObject>
	{
		if let theEntity = entity {
			var fetchRequest = NSFetchRequest()
			
			fetchRequest.entity = theEntity
			fetchRequest.predicate = predicate
			fetchRequest.sortDescriptors = sortDescriptors
			
			var fetchError : NSError?
			if let result = self.executeFetchRequest(fetchRequest,
				error: &fetchError)
			{
				return FetchResult<AnyObject>(result)
			} else {
				return FetchResult<AnyObject>(fetchError ?? Error("Unknown error"))
			}
		}
		return FetchResult<AnyObject>([])
	}

	func fetch<T:NSManagedObject>(entityClass:T.Type,
		sortDescriptors:[AnyObject]? = nil,
		withPredicate predicate: NSPredicate? = nil) -> FetchResult<T>
	{
		switch fetch(entity(entityClass), sortDescriptors:sortDescriptors,
			withPredicate:predicate)
		{
		case .Success(let array):
			return FetchResult<T>(array as! [T])
		case .Failure(let error):
			return FetchResult<T>(error)
		}
	}

	func fetch<T:NSManagedObject>(entityClass:T.Type,
		sortDescriptors:[AnyObject]? = nil,
		withFormat format: String, _ args: CVarArgType ...) -> FetchResult<T>
	{
		return fetch(entityClass, sortDescriptors:sortDescriptors,
			withPredicate:withVaList(args) {NSPredicate(format:format, arguments:$0)})
	}

	func fetchSingle<T:NSManagedObject>(entityClass:T.Type,
		withPredicate predicate: NSPredicate? = nil,
		sortDescriptors:[AnyObject]? = nil) -> FetchSingleResult<T>
	{
		switch fetch(entity(entityClass), withPredicate:predicate,
			sortDescriptors:sortDescriptors)
		{
		case .Success(let array):
			return array.isEmpty
				? FetchSingleResult<T>()
				: FetchSingleResult<T>(array[0] as! T)
		case .Failure(let error):
			return FetchSingleResult<T>(error:error)
		}
	}
	
	func fetchSingle<T:NSManagedObject>(entityClass:T.Type,
		sortDescriptors:[AnyObject]? = nil, withFormat format: String,
		_ args: CVarArgType ...) -> FetchSingleResult<T>
	{
		return fetchSingle(entityClass, sortDescriptors:sortDescriptors,
			withPredicate:withVaList(args) {NSPredicate(format:format, arguments:$0)})
	}
	
	func insert<T:NSManagedObject>(entityClass:T.Type) -> T
	{
		return entityClass(entity:entity(entityClass)!,
			insertIntoManagedObjectContext:self)
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
	
	class func objectInContext(managedObjectContext: NSManagedObjectContext)
		-> Self
  {
    return managedObjectContext.insert(self)
  }
	
}

 