//
//  CoiffeurController.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation
import CoreData

protocol CoiffeurControllerDelegate : class {
	func formatArgumentsForCoiffeurController(controller:CoiffeurController) -> (text:String, attributes: NSDictionary)
	func coiffeurController(coiffeurController:CoiffeurController, setText text:String)
}

enum CoiffeurControllerResult {
	case Success(CoiffeurController)
	case Failure(NSError)
}

class CoiffeurController : NSObject {
	
	class var availableTypes : [CoiffeurController.Type] { return [ ClangFormatController.self, UncrustifyController.self ] }
	
	class var NewLine : String { return "\n" }
	class var Space : String { return " " }
	class var FormatLanguage : String { return "language" }
	class var FormatFragment : String { return "fragment" }
	
	enum OptionType : Swift.String {
		case Signed = "signed"
		case Unsigned = "unsigned"
		case String = "string"
    case StringList = "stringList"
	}
	
	class var documentType : String { return "" }
	//  var documentType : String { return self.dynamicType.documentType }
	
	let managedObjectContext : NSManagedObjectContext
	let managedObjectModel : NSManagedObjectModel
	let executableURL : NSURL
	
	var root : ConfigRoot?
	var pageGuideColumn : Int { return 0 }
	weak var delegate : CoiffeurControllerDelegate?
	
	class var localizedExecutableTitle : String { return "Executable" }
	class var currentExecutableName : String { return "" }
	class var currentExecutableURLUDKey : String { return "" }
	
	class var defaultExecutableURL : NSURL? {
		let bundle = NSBundle(forClass:self)
		if let url = bundle.URLForAuxiliaryExecutable(self.currentExecutableName), let path = url.path {
			if NSFileManager.defaultManager().isExecutableFileAtPath(path) {
				return url
			}
		}
		return nil
	}
	
	class var currentExecutableURL : NSURL? {
		get {
			if let url = NSUserDefaults.standardUserDefaults().URLForKey(self.currentExecutableURLUDKey), let path = url.path {
				if NSFileManager.defaultManager().isExecutableFileAtPath(path) {
					return url
				} else {
					NSUserDefaults.standardUserDefaults().removeObjectForKey(self.currentExecutableURLUDKey)
					NSApp.presentError(Error(format:"Cannot locate executable at %@. Using the deafult application", path))
				}
			}
			return self.defaultExecutableURL
		}
		set (value) {
			let url = self.defaultExecutableURL
			if value == nil || value == url {
				NSUserDefaults.standardUserDefaults().removeObjectForKey(self.currentExecutableURLUDKey)
			} else {
				NSUserDefaults.standardUserDefaults().setURL(value!, forKey: self.currentExecutableURLUDKey)
			}
		}
	}
	
	class var KeySortDescriptor : NSSortDescriptor
	{
		return NSSortDescriptor(key: "indexKey", ascending:true)
	}

	private class func _makeCopyOfEntity(entity:NSEntityDescription!, inout cache entities: Dictionary<String, NSEntityDescription>) -> NSEntityDescription
	{
		let entityName = entity.name!
		if let existingEntity = entities[entityName] {
			return existingEntity
		}
		
		var newEntity = (entity.copy() as! NSEntityDescription)
		entities[entityName] = newEntity
		
		newEntity.managedObjectClassName = "Coiffeur.\(entity.managedObjectClassName)"
		var newSubEntities : [NSEntityDescription] = []
		
		if let oldSubentities = newEntity.subentities {
			for e in oldSubentities {
				if let se = e as? NSEntityDescription {
					newSubEntities.append(_makeCopyOfEntity(se, cache:&entities))
				}
			}
		}
		
		newEntity.subentities = newSubEntities;
		return newEntity
	}
	
	private class func _fixMOM(mom:NSManagedObjectModel) -> NSManagedObjectModel
	{
		var momCopy = NSManagedObjectModel()
		var entityCache : Dictionary<String, NSEntityDescription> = [:]
		var newEntities : [NSEntityDescription] = []
		
		for e in mom.entities {
			newEntities.append(CoiffeurController._makeCopyOfEntity(e as! NSEntityDescription, cache:&entityCache))
		}
		
		momCopy.entities = newEntities
		return momCopy
	}
	
	class func findExecutableURL() -> URLResult
	{
		if let url = self.currentExecutableURL {
			return URLResult.Success(url)
		}
		return URLResult.Failure(Error(format:"Format executable URL is not specified"))
	}
	
	class func createCoiffeur() -> CoiffeurControllerResult
	{
		switch self.findExecutableURL() {
		case .Failure(let error):
			return CoiffeurControllerResult.Failure(error)
		case .Success(let url):
			if let originalModel = NSManagedObjectModel.mergedModelFromBundles([NSBundle(forClass: CoiffeurController.self)]) {
				let mom = CoiffeurController._fixMOM(originalModel)
				var moc = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
				moc.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
				if let psc = moc.persistentStoreCoordinator {
					var error: NSError?
					if nil == psc.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: &error) {
						return CoiffeurControllerResult.Failure(error ?? Error(format:"Failed to initialize coiffeur persistent store"))
					}
				} else {
					return CoiffeurControllerResult.Failure(Error(format:"Failed to initialize coiffeur persistent store coordinator"))
				}
				moc.undoManager = NSUndoManager()
				return CoiffeurControllerResult.Success(self(executableURL:url, managedObjectModel:mom, managedObjectContext:moc))
			} else {
				return CoiffeurControllerResult.Failure(Error(format:"Failed to initialize coiffeur managed object model"))
			}
		}
	}
	
	required init(executableURL:NSURL, managedObjectModel:NSManagedObjectModel, managedObjectContext:NSManagedObjectContext)
	{
		self.executableURL = executableURL
		self.managedObjectModel = managedObjectModel
		self.managedObjectContext = managedObjectContext
		super.init()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("modelDidChange:"), name: NSManagedObjectContextObjectsDidChangeNotification, object: self.managedObjectContext)
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	func modelDidChange(_:AnyObject?)
	{
		self.format()
	}
	
	func format() -> Bool
	{
		var result = false;
		
		if let del = self.delegate {
			let (text, attributes) = del.formatArgumentsForCoiffeurController(self)
			
			result = self.format(text, attributes:attributes, completion: {(result:StringResult) in
				switch (result) {
				case .Failure(let err):
					NSLog("%@", err)
				case .Success(let text):
					del.coiffeurController(self, setText:text)
				}
			})
		}
		return result;
	}
	
	func format(text:String, attributes:NSDictionary, completion:(_:StringResult) -> Void) -> Bool
	{
		return false
	}
	
	func readOptionsFromLineArray(lines:[String]) -> NSError?
	{
		return nil
	}
	
	func readValuesFromLineArray(lines:[String]) -> NSError?
	{
		return nil
	}
	
	func readOptionsFromString(text:String) -> NSError?
	{
		let lines = text.componentsSeparatedByString(CoiffeurController.NewLine)
		self.managedObjectContext.disableUndoRegistration()
		
		self.root = ConfigRoot.objectInContext(self.managedObjectContext);
		
		let result = self.readOptionsFromLineArray(lines)
		
		self.managedObjectContext.enableUndoRegistration()
		
		return result
	}
	
	func readValuesFromString(text:String) -> NSError?
	{
		let lines = text.componentsSeparatedByString(CoiffeurController.NewLine)
		self.managedObjectContext.disableUndoRegistration()
		
		let result = self.readValuesFromLineArray(lines)
		
		self.managedObjectContext.enableUndoRegistration()
		
		return result
	}
	
	func readValuesFromURL(absoluteURL:NSURL) -> NSError?
	{
		var error:NSError?
		if let data = String(contentsOfURL:absoluteURL, encoding:NSUTF8StringEncoding, error:&error) {
			return self.readValuesFromString(data)
		}
		return error ?? Error(format:"Unknown error while trying to read style from %@", absoluteURL)
	}
	
	func writeValuesToURL(absoluteURL:NSURL) -> NSError?
	{
		return Error(format:"Unknown error while trying to write style to %@", absoluteURL)
	}
	
	func optionWithKey(key:String) -> ConfigOption?
	{
//		switch self.managedObjectContext.fetchSingle(ConfigOption.self, withPredicate:NSPredicate(format: "indexKey = %@", key)) {
//		case .Success(let value):
//			return value
//		case .Failure, .None:
//			return nil
//		}
		switch self.managedObjectContext.fetch(ConfigOption.self, withPredicate:NSPredicate(format: "indexKey = %@", key)) {
		case .Success(let value):
			return value.isEmpty ? nil : value[0]
		case .Failure:
			return nil
		}
	}
	
	class func contentsIsValidInString(string:String) -> Bool
	{
		return false
	}
	
	func startExecutable(arguments:[String], workingDirectory:String?, input:String?) -> TaskResult
	{
		var result : TaskResult?
		
		ALExceptions.try({
			var task = NSTask()
			
			task.launchPath = self.executableURL.path!
			task.arguments = arguments
			if workingDirectory != nil {
				task.currentDirectoryPath = workingDirectory!
			}
			
			task.standardOutput = NSPipe()
			task.standardInput = NSPipe()
			task.standardError = NSPipe()
			
			let writeHandle = input != nil ? task.standardInput.fileHandleForWriting : nil
			
			task.launch()
			
			if writeHandle != nil {
				writeHandle.writeData(input!.dataUsingEncoding(NSUTF8StringEncoding)!)
				writeHandle.closeFile()
			}
			
			result = TaskResult.Success(task)
			
			}, catch: { (ex:NSException?) in
				
				result = TaskResult.Failure(Error(format:"An error while running format executable: %@",
					ex?.reason ?? "unknown error"))
				
			}, finally: {})
		
		return result!
	}
	
	func runTask(task:NSTask) -> StringResult
	{
		let outHandle = task.standardOutput.fileHandleForReading
		let outData = outHandle.readDataToEndOfFile()
		
		let errHandle = task.standardError.fileHandleForReading
		let errData = errHandle.readDataToEndOfFile()
		
		task.waitUntilExit()
		
		let status = task.terminationStatus
		
		if status == 0 {
			if let string = String(data:outData, encoding: NSUTF8StringEncoding) {
				return StringResult.Success(string)
			} else {
				return StringResult.Failure(Error(format:"Failed to interpret the output of the format executable"))
			}
		} else {
			if let errText = String(data: errData, encoding: NSUTF8StringEncoding) {
				return StringResult.Failure(Error(format:"Format excutable error code %d: %@", status, errText))
			} else {
				return StringResult.Failure(Error(format:"Format excutable error code %d", status))
			}
		}
	}
	
	func runExecutable(arguments:[String], workingDirectory:String? = nil, input:String? = nil, block:(_:StringResult)->Void) -> NSError?
	{
		let result = self.startExecutable(arguments, workingDirectory: workingDirectory, input: input)
		
		switch result {
		case .Failure(let err):
			return err
		case .Success(let task):
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), {
				let result = self.runTask(task)
				dispatch_async(dispatch_get_main_queue(), {
					block(result)
				});
			});
			
			return nil;
		}
		
	}
	
	func runExecutable(arguments:[String], workingDirectory:String? = nil, input:String? = nil) -> StringResult
	{
		let result = self.startExecutable(arguments, workingDirectory: workingDirectory, input: input)
		switch result {
		case .Failure(let err):
			return StringResult.Failure(err)
		case .Success(let task):
			return self.runTask(task)
		}
	}
	
}





















