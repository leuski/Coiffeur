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
	func coiffeurControllerArguments(controller:CoiffeurController) -> CoiffeurController.Arguments
	func coiffeurController(coiffeurController:CoiffeurController, setText text:String)
}

class CoiffeurController : NSObject {

	class Arguments {
		let text:String
		let language:Language
		var fragment = false

		init(_ text:String, language:Language)
		{
			self.text = text
			self.language = language
		}
	}
	
	enum Result {
		case Success(CoiffeurController)
		case Failure(NSError)
		init(_ controller:CoiffeurController)
		{
			self = .Success(controller)
		}
		init(_ error:NSError)
		{
			self = .Failure(error)
		}
	}
	
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
	
	let managedObjectContext : NSManagedObjectContext
	let managedObjectModel : NSManagedObjectModel
	let executableURL : NSURL
	
	var root : ConfigRoot? {
		switch self.managedObjectContext.fetch(ConfigRoot.self) {
		case .Success(let array):
			return array.isEmpty ? nil : array[0]
		case .Failure(let error):
			return nil
		}
	}
	
	var pageGuideColumn : Int { return 0 }
	weak var delegate : CoiffeurControllerDelegate?
	
	class var localizedExecutableTitle : String { return "Executable" }
	class var currentExecutableName : String { return "" }
	class var currentExecutableURLUDKey : String { return "" }
	
	class var defaultExecutableURL : NSURL? {
		let bundle = NSBundle(forClass:self)
		if let url = bundle.URLForAuxiliaryExecutable(self.currentExecutableName),
			 let path = url.path
		{
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
					NSApp.presentError(Error("Cannot locate executable at %@. Using the default application", path))
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

	class func findExecutableURL() -> URLResult
	{
		if let url = self.currentExecutableURL {
			return URLResult(url)
		}
		return URLResult(Error("Format executable URL is not specified"))
	}
	
	class func createCoiffeur() -> CoiffeurController.Result
	{
		switch self.findExecutableURL() {
		case .Failure(let error):
			return CoiffeurController.Result(error)
		case .Success(let url):
			if let originalModel = NSManagedObjectModel.mergedModelFromBundles([NSBundle(forClass: CoiffeurController.self)]) {
				let mom = CoiffeurController._fixMOM(originalModel)
				var moc = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
				moc.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
				if let psc = moc.persistentStoreCoordinator {
					var error: NSError?
					if nil == psc.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: &error) {
						return CoiffeurController.Result(error ?? Error("Failed to initialize coiffeur persistent store"))
					}
				} else {
					return CoiffeurController.Result(Error("Failed to initialize coiffeur persistent store coordinator"))
				}
				moc.undoManager = NSUndoManager()
				return CoiffeurController.Result(self(executableURL:url, managedObjectModel:mom, managedObjectContext:moc))
			} else {
				return CoiffeurController.Result(Error("Failed to initialize coiffeur managed object model"))
			}
		}
	}
	
	class func contentsIsValidInString(string:String) -> Bool
	{
		return false
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
	
	private func _makeOthersSubsection()
	{
		for child in self.root!.children  {
			if !(child is ConfigSection) {
				continue
			}
			var section = child as! ConfigSection
			
			var index = [ConfigOption]()
			var foundSubSection = false
			
			for node in section.children {
				if !(node is ConfigOption) {
					foundSubSection = true
				} else {
					index.append(node as! ConfigOption)
				}
			}
			
			if !foundSubSection || index.isEmpty {
				continue
			}
			
			var subsection = ConfigSection.objectInContext(self.managedObjectContext,
				parent:section,
				title:"\u{200B}" + NSLocalizedString("Other", comment:"") + " " + section.title.lowercaseString)
			
			for option in index {
				option.parent = subsection
			}
		}
	}
	
	func format() -> Bool
	{
		var result = false;
		
		if let del = self.delegate {
			let arguments = del.coiffeurControllerArguments(self)
			
			result = self.format(arguments, completionHandler: {(result:StringResult) in
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
	
	func format(args:Arguments, completionHandler:(_:StringResult) -> Void) -> Bool
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
		
		ConfigRoot.objectInContext(self.managedObjectContext, parent:nil)
		
		let result = self.readOptionsFromLineArray(lines)
		_clusterOptions()
		
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
		return error ?? Error("Unknown error while trying to read style from %@", absoluteURL)
	}
	
	func writeValuesToURL(absoluteURL:NSURL) -> NSError?
	{
		return Error("Unknown error while trying to write style to %@", absoluteURL)
	}
	
	func optionWithKey(key:String) -> ConfigOption?
	{
// TODO: crashes compiler in Swift 1.2
//		switch self.managedObjectContext.fetchSingle(ConfigOption.self, withFormat:"indexKey = %@", key) {
//		case .Success(let value):
//			return value
//		default:
//			return nil
//		}
		switch self.managedObjectContext.fetch(ConfigOption.self, withFormat:"indexKey = %@", key) {
		case .Success(let value):
			return value.isEmpty ? nil : value[0]
		case .Failure:
			return nil
		}
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
	
	private func _clusterOptions()
	{
		for var i = 8; i >= 2; --i {
			self._cluster(i)
		}
		
		_makeOthersSubsection()
		
		// if the root contains only one child, pull its children into the root,
		// and remove it
		if let root = self.root {
			if root.children.count == 1 {
				let subroot = root.children.objectAtIndex(0) as! ConfigNode
				for node in subroot.children.array as! [ConfigNode] {
					node.parent = root
				}
				self.managedObjectContext.deleteObject(subroot)
			}
		}
		
		self.root?.sortAndIndexChildren()
	}
	
	private func _splitTokens(title:String, boundary:Int, stem:Bool = false) -> (head:[String], tail:[String])
	{
		var tokens = title.componentsSeparatedByString(CoiffeurController.Space)
		var head = [String]()
		var tail = [String]()
		for token in tokens  {
			if head.count < boundary {
				var lcToken = token.lowercaseString
				if lcToken.isEmpty || lcToken == "a" || lcToken == "the" {
					continue
				}
				if stem {
					if lcToken.hasSuffix("ing") {
						lcToken = lcToken.stringByTrimmingSuffix("ing")
					} else if lcToken.hasSuffix("ed") {
						lcToken = lcToken.stringByTrimmingSuffix("ed")
					} else if lcToken.hasSuffix("s") {
						lcToken = lcToken.stringByTrimmingSuffix("s")
					}
				}
				head.append(lcToken)
			} else {
				tail.append(token)
			}
		}
		return (head:head, tail:tail)
	}
	
	private func _cluster(tokenLimit:Int)
	{
		for child in self.root!.children  {
			if !(child is ConfigSection) {
				continue
			}
			var section = child as! ConfigSection
			
			var index = [String:[ConfigOption]]()
			
			for node in section.children {
				if !(node is ConfigOption) {
					continue
				}
				let option : ConfigOption = node as! ConfigOption
				let (head, tail) = _splitTokens(option.title, boundary:tokenLimit, stem:true)
				
				if tail.isEmpty {
					continue
				}
				
				let key = head.reduce("") { $0.isEmpty ? $1 : "\($0) \($1)" }
				
				if index[key] == nil {
					index[key] = [ConfigOption]()
				}
				
				index[key]!.append(option)
			}
			
			for (key, list) in index {
				if list.count < 5 || list.count == section.children.count {
					continue
				}
				
				var subsection = ConfigSection.objectInContext(self.managedObjectContext,
					parent:section, title:key + " …")
				
				var count = 0
				for option in list {
					option.parent = subsection
					let (head, tail) = _splitTokens(option.title, boundary:tokenLimit)
					option.title  = tail.reduce("") { $0.isEmpty ? $1 : "\($0) \($1)" }
					if ++count == 1 {
						let title = head.reduce("") { $0.isEmpty ? $1 : "\($0) \($1)" }
						subsection.title  = title.stringByCapitalizingFirstWord + " …"
					}
				}
			}
		}
	}
	
}





















