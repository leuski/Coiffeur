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

protocol CoiffeurControllerDelegate: class {
	func coiffeurControllerArguments(_ controller: CoiffeurController)
		-> CoiffeurController.Arguments
	func coiffeurController(_ coiffeurController: CoiffeurController,
		setText text: String)
}

class CoiffeurController: NSObject {

	class Arguments {
		let text: String
		let language: Language
		var fragment = false

		init(_ text: String, language: Language)
		{
			self.text = text
			self.language = language
		}
	}

	enum OptionType: Swift.String {
		case signed = "signed"
		case unsigned = "unsigned"
		case string = "string"
		case stringList = "stringList"
	}

	class var availableTypes: [CoiffeurController.Type] {
		return [ ClangFormatController.self, UncrustifyController.self ] }

	class var documentType: String { return "" }
	class var localizedExecutableTitle: String { return "Executable" }
	class var currentExecutableName: String { return "" }
	class var currentExecutableURLUDKey: String { return "" }

	class var defaultExecutableURL: URL? {
		let bundle = Bundle(for: self)
		if let url = bundle.url(forAuxiliaryExecutable: self.currentExecutableName)
		{
			if FileManager.default.isExecutableFile(atPath: url.path) {
				return url
			}
		}
		return nil
	}

	class var currentExecutableURL: URL? {
		get {
			let UD = UserDefaults.standard
			if let url = UD.url(forKey: self.currentExecutableURLUDKey)
			{
				if FileManager.default.isExecutableFile(atPath: url.path) {
					return url
				} else {
					UD.removeObject(forKey: self.currentExecutableURLUDKey)
					NSApp.presentError(Error(
						"Cannot locate executable at %@. Using the default application",
						url.path))
				}
			}
			return self.defaultExecutableURL
		}
		set (value) {
			let defaults = UserDefaults.standard
			let url = self.defaultExecutableURL
			if value == nil || value == url {
				defaults.removeObject(forKey: self.currentExecutableURLUDKey)
			} else {
				defaults.set(value!, forKey: self.currentExecutableURLUDKey)
			}
		}
	}

	class var keySortDescriptor: NSSortDescriptor
	{
		return NSSortDescriptor(key: "indexKey", ascending: true)
	}

	let managedObjectContext: NSManagedObjectContext
	let managedObjectModel: NSManagedObjectModel
	let executableURL: URL

	@objc var root: ConfigRoot? {
		do {
			return try self.managedObjectContext.fetchSingle(ConfigRoot.self)
		} catch _ {
			return nil
		}
	}

	var pageGuideColumn: Int { return 0 }
	weak var delegate: CoiffeurControllerDelegate?

	class func findExecutableURL() throws -> URL
	{
		if let url = self.currentExecutableURL {
			return url
		}
		throw Error("Format executable URL is not specified")
	}

	class func createCoiffeur() throws -> CoiffeurController
	{
		let url = try self.findExecutableURL()

		let bundles = [Bundle(for: CoiffeurController.self)]
		if let originalModel = NSManagedObjectModel.mergedModel(from: bundles)
		{
			let mom = originalModel //.copyForModuleWithClass(ConfigNode.self)
			let concurrency
				= NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType
			let moc = NSManagedObjectContext(concurrencyType: concurrency)
			moc.persistentStoreCoordinator = NSPersistentStoreCoordinator(
				managedObjectModel: mom)
			if let psc = moc.persistentStoreCoordinator {
				try psc.addPersistentStore(ofType: NSInMemoryStoreType,
										configurationName: nil, at: nil, options: nil)
			} else {
				throw Error("Failed to initialize coiffeur persistent store coordinator")
			}
			moc.undoManager = UndoManager()
			return self.init(executableURL: url,
				managedObjectModel: mom, managedObjectContext: moc)
		} else {
			throw Error("Failed to initialize coiffeur managed object model")
		}
	}

	class func coiffeurWithType(_ type: String) throws -> CoiffeurController
	{
		for coiffeurClass in CoiffeurController.availableTypes  {
			if type == coiffeurClass.documentType {
				return try coiffeurClass.createCoiffeur()
			}
		}
		throw Error("Unknown document type “%@”", type)
	}

	class func contentsIsValidInString(_ string: String) -> Bool
	{
		return false
	}

	required init(executableURL: URL, managedObjectModel: NSManagedObjectModel,
		managedObjectContext: NSManagedObjectContext)
	{
		self.executableURL = executableURL
		self.managedObjectModel = managedObjectModel
		self.managedObjectContext = managedObjectContext
		super.init()
		NotificationCenter.default.addObserver(self,
			selector: #selector(CoiffeurController.modelDidChange(_:)),
			name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
			object: self.managedObjectContext)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc func modelDidChange(_:AnyObject?)
	{
		self.format()
	}

  @discardableResult
	func format() -> Bool
	{
		var result = false

		if let del = self.delegate {
			let arguments = del.coiffeurControllerArguments(self)
			result = self.format(arguments) {
				(result: StringResult) in
				switch (result) {
				case .failure(let err):
					NSLog("%@", err)
				case .success(let text):
					del.coiffeurController(self, setText: text)
				}
			}
		}
		return result
	}

	func format(_ args: Arguments,
		completionHandler: @escaping (_:StringResult) -> Void) -> Bool
	{
		return false
	}

	func readOptionsFromLineArray(_ lines: [String]) throws
	{
	}

	func readValuesFromLineArray(_ lines: [String]) throws
	{
	}

	func readOptionsFromString(_ text: String) throws
	{
		let lines = text.components(separatedBy: "\n")

		self.managedObjectContext.disableUndoRegistration()
		defer { self.managedObjectContext.enableUndoRegistration() }

		ConfigRoot.objectInContext(self.managedObjectContext, parent: nil)

		try self.readOptionsFromLineArray(lines)
		_clusterOptions()
	}

	func readValuesFromString(_ text: String) throws
	{
		let lines = text.components(separatedBy: "\n")

		self.managedObjectContext.disableUndoRegistration()
		defer { self.managedObjectContext.enableUndoRegistration() }

		try self.readValuesFromLineArray(lines)
	}

	func readValuesFromURL(_ absoluteURL: URL) throws
	{
		let data = try String(contentsOf: absoluteURL,
			encoding: String.Encoding.utf8)
		try self.readValuesFromString(data)
	}

	func writeValuesToURL(_ absoluteURL: URL) throws
	{
		throw Error("Unknown error while trying to write style to %@", absoluteURL as CVarArg)
	}

	func optionWithKey(_ key: String) -> ConfigOption?
	{
		do {
			return try self.managedObjectContext.fetchSingle(ConfigOption.self,
				withFormat: "indexKey = %@", key)
		} catch _ {
			return nil
		}
	}

	fileprivate func _clusterOptions()
	{
		for index in stride(from: 8, to: 1, by: -1) {
			self._cluster(index)
		}

		_makeOthersSubsection()

		// if the root contains only one child, pull its children into the root,
		// and remove it
		if
      let root = self.root,
      root.children.count == 1,
      let subroot = root.children.object(at: 0) as? ConfigNode
    {
      for case let node as ConfigNode in subroot.children.array {
        node.parent = root
      }
      self.managedObjectContext.delete(subroot)
		}

		self.root?.sortAndIndexChildren()
	}

	fileprivate func _splitTokens(_ title: String, boundary: Int, stem: Bool = false)
		-> (head: [String], tail: [String])
	{
		let tokens = title.components(separatedBy: " ")
		var head = [String]()
		var tail = [String]()
		for token in tokens  {
			if head.count < boundary {
				var lcToken = token.lowercased()
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

	fileprivate func _cluster(_ tokenLimit: Int)
	{
		for child in self.root!.children  {
      guard let section = child as? ConfigSection else { continue }

			var index = [String:[ConfigOption]]()

			for node in section.children {
        guard let option = node as? ConfigOption else { continue }

        let (head, tail) = _splitTokens(option.title,
					boundary: tokenLimit, stem: true)

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
					parent: section, title: "\(key) …")

				var count = 0
				for option in list {
					option.parent = subsection
					let (head, tail) = _splitTokens(option.title, boundary: tokenLimit)
					option.title  = tail.reduce("") { $0.isEmpty ? $1 : "\($0) \($1)" }
          count += 1
					if count == 1 {
						let title = head.reduce("") { $0.isEmpty ? $1 : "\($0) \($1)" }
						subsection.title  = "\(title.stringByCapitalizingFirstWord) …"
					}
				}
			}
		}
	}

	fileprivate func _makeOthersSubsection()
	{
		for child in self.root!.children  {
      guard let section = child as? ConfigSection else { continue }

			var index = [ConfigOption]()
			var foundSubSection = false

			for node in section.children {
        if let section = node as? ConfigOption {
          index.append(section)
        } else {
          foundSubSection = true
        }
			}

			if !foundSubSection || index.isEmpty {
				continue
			}

			let other = String(format: NSLocalizedString("Other %@", comment: ""),
				section.title.lowercased())
			let subsection = ConfigSection.objectInContext(self.managedObjectContext,
				parent: section,
				title: "\u{200B}\(other)")

			for option in index {
				option.parent = subsection
			}
		}
	}

}
