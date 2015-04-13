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

class FragariaColorRecord : NSObject {
	let fragariaUDKey : String
	let displayNameUDKey : String

	var displayName : String { return NSLocalizedString(self.displayNameUDKey, comment: "") }
	
	var color : NSColor? {
		get {
			return NSUserDefaults.standardUserDefaults().archivedObjectForKey(self.fragariaUDKey)
		}
		set (value) {
			NSUserDefaults.standardUserDefaults().setArchivedObject(value, forKey: self.fragariaUDKey)
		}
	}
	
	init(fragariaKey : String, displayNameKey: String)
	{
		self.fragariaUDKey = fragariaKey
		self.displayNameUDKey = displayNameKey
	}
}

class ColorAndFontPreferences : DefaultPreferencePane {

	override var toolbarItemImage : NSImage? { return NSImage(named: "ProfileFontAndColor") }
	
	let colors = [
		FragariaColorRecord(fragariaKey: MGSFragariaPrefsBackgroundColourWell, displayNameKey: "Background"),
		FragariaColorRecord(fragariaKey: MGSFragariaPrefsTextColourWell, displayNameKey: "Plain Text"),
		FragariaColorRecord(fragariaKey: MGSFragariaPrefsCommentsColourWell, displayNameKey: "Comments"),
		FragariaColorRecord(fragariaKey: MGSFragariaPrefsStringsColourWell, displayNameKey: "Strings"),
		FragariaColorRecord(fragariaKey: MGSFragariaPrefsNumbersColourWell, displayNameKey: "Numbers"),
		FragariaColorRecord(fragariaKey: MGSFragariaPrefsAttributesColourWell, displayNameKey: "Attributes"),
		FragariaColorRecord(fragariaKey: MGSFragariaPrefsVariablesColourWell, displayNameKey: "Variables"),
		FragariaColorRecord(fragariaKey: MGSFragariaPrefsKeywordsColourWell, displayNameKey: "Keywords"),
		FragariaColorRecord(fragariaKey: MGSFragariaPrefsInstructionsColourWell, displayNameKey: "Instructions"),
		FragariaColorRecord(fragariaKey: MGSFragariaPrefsCommandsColourWell, displayNameKey: "Commands"),
		FragariaColorRecord(fragariaKey: MGSFragariaPrefsInvisibleCharactersColourWell, displayNameKey: "Invisibles")
	]
	
	let backgroundColor = FragariaColorRecord(fragariaKey: MGSFragariaPrefsBackgroundColourWell, displayNameKey: "Background")
	
	dynamic var font : NSFont? {
		get {
			return NSUserDefaults.standardUserDefaults().archivedObjectForKey(MGSFragariaPrefsTextFont)
		}
		set (value) {
			NSUserDefaults.standardUserDefaults().setArchivedObject(value, forKey: MGSFragariaPrefsTextFont)
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
		NSFontManager.sharedFontManager().setSelectedFont(self.font!, isMultiple: false)
		NSFontManager.sharedFontManager().orderFrontFontPanel(sender)
	}
}
