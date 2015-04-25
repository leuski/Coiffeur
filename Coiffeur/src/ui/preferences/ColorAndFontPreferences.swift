//
//  ColorAndFontPreferences.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/12/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

extension NSUserDefaults {
	func archivedObjectForKey<T:AnyObject>(key: String) -> T?
	{
		if let data = self.dataForKey(key) {
			return NSUnarchiver.unarchiveObjectWithData(data) as? T
		}
		return nil
	}
	func setArchivedObject<T:AnyObject>(value:T?, forKey key: String)
	{
		if value != nil {
			self.setObject(NSArchiver.archivedDataWithRootObject(value!), forKey: key)
		} else {
			self.removeObjectForKey(key)
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
			let UD = NSUserDefaults.standardUserDefaults()
			return UD.archivedObjectForKey(self.fragariaUDKey)
		}
		set (value) {
			let UD = NSUserDefaults.standardUserDefaults()
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
		return NSImage(named: "ProfileFontAndColor") }
	
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
	
	dynamic var font : NSFont? {
		get {
			let UD = NSUserDefaults.standardUserDefaults()
			return UD.archivedObjectForKey(MGSFragariaPrefsTextFont)
		}
		set (value) {
			let UD = NSUserDefaults.standardUserDefaults()
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
	
	override func changeFont(sender: AnyObject?)
	{
		self.font = NSFontManager.sharedFontManager().convertFont(self.font!)
	}

	@IBAction func modifyFont(sender: AnyObject?)
	{
		NSFontManager.sharedFontManager().setSelectedFont(self.font!,
			isMultiple: false)
		NSFontManager.sharedFontManager().orderFrontFontPanel(sender)
	}
}
