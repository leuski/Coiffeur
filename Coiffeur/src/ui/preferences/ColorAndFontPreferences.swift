//
//  ColorAndFontPreferences.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/12/15.
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

import Cocoa

extension UserDefaults {
	func archivedObjectForKey<T:AnyObject>(_ key: String) -> T?
	{
		if let data = self.data(forKey: key) {
			return NSUnarchiver.unarchiveObject(with: data) as? T
		}
		return nil
	}
	func setArchivedObject<T:AnyObject>(_ value:T?, forKey key: String)
	{
		if value != nil {
			self.set(NSArchiver.archivedData(withRootObject: value!), forKey: key)
		} else {
			self.removeObject(forKey: key)
		}
	}
}

class FragariaColor : NSObject {
	let fragariaUDKey : String
	let displayNameUDKey : String

	var displayName : String {
		return NSLocalizedString(self.displayNameUDKey, comment: "") }
	
	var color : NSColor? {
		get {
			let UD = UserDefaults.standard
			return UD.archivedObjectForKey(self.fragariaUDKey)
		}
		set (value) {
			let UD = UserDefaults.standard
			UD.setArchivedObject(value, forKey: self.fragariaUDKey)
		}
	}
	
	init(_ fragariaKey : String, _ displayNameKey: String)
	{
		self.fragariaUDKey = fragariaKey
		self.displayNameUDKey = displayNameKey
	}
}

class ColorAndFontPreferences : DefaultPreferencePane {

	override var toolbarItemImage : NSImage? {
		return NSImage(named: NSImage.Name(rawValue: "FontAndColors")) }
	
	let colors = [
		FragariaColor(MGSFragariaPrefsBackgroundColourWell, "Background"),
		FragariaColor(MGSFragariaPrefsTextColourWell, "Plain Text"),
		FragariaColor(MGSFragariaPrefsCommentsColourWell, "Comments"),
		FragariaColor(MGSFragariaPrefsStringsColourWell, "Strings"),
		FragariaColor(MGSFragariaPrefsNumbersColourWell, "Numbers"),
		FragariaColor(MGSFragariaPrefsAttributesColourWell, "Attributes"),
		FragariaColor(MGSFragariaPrefsVariablesColourWell, "Variables"),
		FragariaColor(MGSFragariaPrefsKeywordsColourWell, "Keywords"),
		FragariaColor(MGSFragariaPrefsInstructionsColourWell, "Instructions"),
		FragariaColor(MGSFragariaPrefsCommandsColourWell, "Commands"),
		FragariaColor(MGSFragariaPrefsInvisibleCharactersColourWell, "Invisibles")
	]
	
	@objc dynamic var font : NSFont? {
		get {
			let UD = UserDefaults.standard
			return UD.archivedObjectForKey(MGSFragariaPrefsTextFont)
		}
		set (value) {
			let UD = UserDefaults.standard
			UD.setArchivedObject(value, forKey: MGSFragariaPrefsTextFont)
		}
	}
	
	class func keyPathsForValuesAffectingFontName() -> NSSet
	{
		return NSSet(object: "font")
	}
	
	var fontName : String {
		if let f = self.font {
			return "\(f.displayName!) \(f.pointSize) pts"
		}
		return ""
	}
	
	override func changeFont(_ sender: Any?)
	{
		self.font = NSFontManager.shared.convert(self.font!)
	}

	@IBAction func modifyFont(_ sender: AnyObject?)
	{
		NSFontManager.shared.setSelectedFont(self.font!,
			isMultiple: false)
		NSFontManager.shared.orderFrontFontPanel(sender)
	}
}
