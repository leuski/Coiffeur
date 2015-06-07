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

extension NSManagedObjectModel {

	// HACK: Swift classes are namespaced. So when editing CoreData model
	// we need to specify a fully-qualified class name for model classes.
	// As of XCode 6.3, CoreData source generation fails when the class name
	// contains a period.
	// Moreover, if you decide to import the model into a different target,
	// things will break as the original module name is hardcoded in the
	// model file.
	// Moreover, if you create a test case in the original project,
	// the test case will have a different target name and, hence, a different 
	// module name. And, the model will break.
	//
	// Here we assume that the model file contains unqualified class names and
	// we add the module name.
	func copyForModuleWithClass(clazz:NSObject.Type) -> NSManagedObjectModel
	{
		let moduleName : String
		let className = clazz.className()
		if let range = className.rangeOfString(".") {
			moduleName = "\(className.substringToIndex(range.startIndex))."
		} else {
			moduleName = ""
		}
		return copyForModuleWithName(moduleName)
	}
	
	func copyForModuleWithName(moduleName: String) -> NSManagedObjectModel
	{
		if moduleName.isEmpty { return self }
		
		var momCopy = NSManagedObjectModel()
		var entityCache : Dictionary<String, NSEntityDescription> = [:]
		var newEntities : [NSEntityDescription] = []

		for e in self.entities as! [NSEntityDescription] {
			newEntities.append(e.copyWithModuleName(moduleName, cache:&entityCache))
		}
		
		momCopy.entities = newEntities
		return momCopy
	}
}

extension NSEntityDescription {
	
	typealias Cache = Dictionary<String, NSEntityDescription>
	
	func copyWithModuleName(moduleName: String, inout cache:Cache)
		-> NSEntityDescription
	{
		if moduleName.isEmpty { return self }
		
		let entityName = self.name!
		if let existingEntity = cache[entityName] {
			return existingEntity
		}
		
		var newEntity = copy() as! NSEntityDescription
		cache[entityName] = newEntity
		
		if newEntity.managedObjectClassName == NSManagedObject.className() {
			newEntity.managedObjectClassName = self.managedObjectClassName
		} else {
			newEntity.managedObjectClassName
				= "\(moduleName)\(self.managedObjectClassName)"
		}
		var newSubEntities : [NSEntityDescription] = []
		
		if let oldSubentities = newEntity.subentities {
			for e in oldSubentities {
				if let se = e as? NSEntityDescription {
					newSubEntities.append(se.copyWithModuleName(moduleName, cache:&cache))
				}
			}
		}
		
		newEntity.subentities = newSubEntities
		return newEntity
	}
}


 