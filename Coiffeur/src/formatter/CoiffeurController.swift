//
//  CoiffeurController.swift
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

protocol CoiffeurControllerDelegate : class {
	func coiffeurControllerArguments(controller:CoiffeurController)
		-> CoiffeurController.Arguments
	func coiffeurController(coiffeurController:CoiffeurController,
		setText text:String)
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
	
	enum OptionType : Swift.String {
		case Signed = "signed"
		case Unsigned = "unsigned"
		case String = "string"
		case StringList = "stringList"
	}
	
	class var availableTypes : [CoiffeurController.Type] {
		return [ ClangFormatController.self, UncrustifyController.self ] }
	
	class var documentType : String { return "" }
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
			let UD = NSUserDefaults.standardUserDefaults()
			if let url = UD.URLForKey(self.currentExecutableURLUDKey),
				 let path = url.path
			{
				if NSFileManager.defaultManager().isExecutableFileAtPath(path) {
					return url
				} else {
					UD.removeObjectForKey(self.currentExecutableURLUDKey)
					NSApp.presentError(Error(
						"Cannot locate executable at %@. Using the default application",
						path))
				}
			}
			return self.defaultExecutableURL
		}
		set (value) {
			let UD = NSUserDefaults.standardUserDefaults()
			let url = self.defaultExecutableURL
			if value == nil || value == url {
				UD.removeObjectForKey(self.currentExecutableURLUDKey)
			} else {
				UD.setURL(value!, forKey: self.currentExecutableURLUDKey)
			}
		}
	}
	
	class var KeySortDescriptor : NSSortDescriptor
	{
		return NSSortDescriptor(key: "indexKey", ascending:true)
	}
	
	let managedObjectContext : NSManagedObjectContext
	let managedObjectModel : NSManagedObjectModel
	let executableURL : NSURL
	
	var root : ConfigRoot? {
		do {
			return try self.managedObjectContext.fetchSingle(ConfigRoot.self)
		} catch _ {
			return nil
		}
	}
	
	var pageGuideColumn : Int { return 0 }
	weak var delegate : CoiffeurControllerDelegate?
	
	class func findExecutableURL() throws -> NSURL
	{
		if let url = self.currentExecutableURL {
			return url
		}
		throw Error("Format executable URL is not specified")
	}
	
	class func createCoiffeur() throws -> CoiffeurController
	{
		let url = try self.findExecutableURL()

		let bundles = [NSBundle(forClass: CoiffeurController.self)]
		if let originalModel = NSManagedObjectModel.mergedModelFromBundles(bundles)
		{
			let mom = originalModel.copyForModuleWithClass(ConfigNode)
			let concurrency
				= NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType
			let moc = NSManagedObjectContext(concurrencyType: concurrency)
			moc.persistentStoreCoordinator = NSPersistentStoreCoordinator(
				managedObjectModel: mom)
			if let psc = moc.persistentStoreCoordinator {
				try psc.addPersistentStoreWithType(NSInMemoryStoreType,
										configuration: nil, URL: nil, options: nil)
			} else {
				throw Error("Failed to initialize coiffeur persistent store coordinator")
			}
			moc.undoManager = NSUndoManager()
			return self.init(executableURL:url,
				managedObjectModel:mom, managedObjectContext:moc)
		} else {
			throw Error("Failed to initialize coiffeur managed object model")
		}
	}
	
	class func coiffeurWithType(type: String) throws -> CoiffeurController
	{
		for coiffeurClass in CoiffeurController.availableTypes  {
			if type == coiffeurClass.documentType {
				return try coiffeurClass.createCoiffeur()
			}
		}
		throw Error("Unknown document type “%@”", type)
	}
	
	class func contentsIsValidInString(string:String) -> Bool
	{
		return false
	}

	required init(executableURL:NSURL, managedObjectModel:NSManagedObjectModel,
		managedObjectContext:NSManagedObjectContext)
	{
		self.executableURL = executableURL
		self.managedObjectModel = managedObjectModel
		self.managedObjectContext = managedObjectContext
		super.init()
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: "modelDidChange:",
			name: NSManagedObjectContextObjectsDidChangeNotification,
			object: self.managedObjectContext)
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
		var result = false
		
		if let del = self.delegate {
			let arguments = del.coiffeurControllerArguments(self)			
			result = self.format(arguments) {
				(result:StringResult) in
				switch (result) {
				case .Failure(let err):
					NSLog("%@", err)
				case .Success(let text):
					del.coiffeurController(self, setText:text)
				}
			}
		}
		return result
	}
	
	func format(args:Arguments,
		completionHandler:(_:StringResult) -> Void) -> Bool
	{
		return false
	}
	
	func readOptionsFromLineArray(lines:[String]) throws
	{
	}
	
	func readValuesFromLineArray(lines:[String]) throws
	{
	}
	
	func readOptionsFromString(text:String) throws
	{
		let lines = text.componentsSeparatedByString("\n")

		self.managedObjectContext.disableUndoRegistration()
		defer { self.managedObjectContext.enableUndoRegistration() }

		ConfigRoot.objectInContext(self.managedObjectContext, parent:nil)
		
		try self.readOptionsFromLineArray(lines)
		_clusterOptions()
	}
	
	func readValuesFromString(text:String) throws
	{
		let lines = text.componentsSeparatedByString("\n")

		self.managedObjectContext.disableUndoRegistration()
		defer { self.managedObjectContext.enableUndoRegistration() }
		
		try self.readValuesFromLineArray(lines)
	}
	
	func readValuesFromURL(absoluteURL:NSURL) throws
	{
		let data = try String(contentsOfURL:absoluteURL,
			encoding:NSUTF8StringEncoding)
		try self.readValuesFromString(data)
	}
	
	func writeValuesToURL(absoluteURL:NSURL) throws
	{
		throw Error("Unknown error while trying to write style to %@", absoluteURL)
	}
	
	func optionWithKey(key:String) -> ConfigOption?
	{
		do {
			return try self.managedObjectContext.fetchSingle(ConfigOption.self,
				withFormat:"indexKey = %@", key)
		} catch _ {
			return nil
		}
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
	
	private func _splitTokens(title:String, boundary:Int, stem:Bool = false)
		-> (head:[String], tail:[String])
	{
		let tokens = title.componentsSeparatedByString(" ")
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
			let section = child as! ConfigSection
			
			var index = [String:[ConfigOption]]()
			
			for node in section.children {
				if !(node is ConfigOption) {
					continue
				}
				let option : ConfigOption = node as! ConfigOption
				let (head, tail) = _splitTokens(option.title,
					boundary:tokenLimit, stem:true)
				
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
				
				let subsection = ConfigSection.objectInContext(
					self.managedObjectContext,
					parent:section, title:"\(key) …")
				
				var count = 0
				for option in list {
					option.parent = subsection
					let (head, tail) = _splitTokens(option.title, boundary:tokenLimit)
					option.title  = tail.reduce("") { $0.isEmpty ? $1 : "\($0) \($1)" }
					if ++count == 1 {
						let title = head.reduce("") { $0.isEmpty ? $1 : "\($0) \($1)" }
						subsection.title  = "\(title.stringByCapitalizingFirstWord) …"
					}
				}
			}
		}
	}
	
	private func _makeOthersSubsection()
	{
		for child in self.root!.children  {
			if !(child is ConfigSection) {
				continue
			}
			let section = child as! ConfigSection
			
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
			
			let Other = String(format:NSLocalizedString("Other %@", comment:""),
				section.title.lowercaseString)
			let subsection = ConfigSection.objectInContext(self.managedObjectContext,
				parent:section,
				title:"\u{200B}\(Other)")
			
			for option in index {
				option.parent = subsection
			}
		}
	}
	
}





















