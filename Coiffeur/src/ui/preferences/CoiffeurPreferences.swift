//
//  CoiffeurPreferences.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/11/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

class CoiffeurControllerClass : NSObject {
	let controllerClass : CoiffeurController.Type
	var documentType : String { return controllerClass.documentType }
	
	init(_ type:CoiffeurController.Type)
	{
		controllerClass = type
	}
	
	func contentsIsValidInString(string:String) -> Bool
	{
		return controllerClass.contentsIsValidInString(string)
	}
	
	func createCoiffeur() -> CoiffeurController.Result
	{
		return controllerClass.createCoiffeur()
	}
	
  class func keyPathsForValuesAffectingCurrentExecutableURL() -> NSSet
  {
    return NSSet(object:"controllerClass.currentExecutableURL")
  }
  
	var currentExecutableURL : NSURL? {
		get {
			return controllerClass.currentExecutableURL
		}
		set (value) {
      willChangeValueForKey("currentExecutableURL")
			controllerClass.currentExecutableURL = value
      didChangeValueForKey("currentExecutableURL")
		}
	}
	
	var defaultExecutableURL : NSURL? {
		return controllerClass.defaultExecutableURL
	}
	
	var executableDisplayName : String {
		return controllerClass.localizedExecutableTitle
	}
}

class CoiffeurPreferences : DefaultPreferencePane {
	
	@IBOutlet weak var tableView: NSTableView!
	@IBOutlet weak var constraint: NSLayoutConstraint!
	
	override var toolbarItemImage : NSImage? {
		return NSImage(named: "Locations") }
	
	let formatters = CoiffeurController.availableTypes.map {
		CoiffeurControllerClass($0) }
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let height = self.tableView.bounds.size.height + 2
		let delta = self.tableView.enclosingScrollView!.frame.size.height - height
		self.constraint.constant = self.constraint.constant - delta
		self.view.frame.size.height -= delta
	}
}

extension CoiffeurPreferences : NSTableViewDelegate {
	func tableView(tableView: NSTableView,
		rowViewForRow row: Int) -> NSTableRowView?
	{
		return TransparentTableRowView()
	}
}

extension CoiffeurPreferences : NSPathControlDelegate {
	func pathControl(pathControl: NSPathControl, willPopUpMenu menu: NSMenu)
	{
		if let tcv = pathControl.superview as? NSTableCellView,
			let ccc = tcv.objectValue as? CoiffeurControllerClass,
			let url = ccc.defaultExecutableURL
		{
			let item = menu.insertItemWithTitle(
				String(format:NSLocalizedString("Built-in %@", comment:""),
					url.lastPathComponent!),
				action: Selector("selectURL:"),
				keyEquivalent: "", atIndex: 0)
			item?.representedObject = [ "class" : ccc, "url" : url ]
				as Dictionary<String, AnyObject>
		}
	}
	
	func selectURL(sender:AnyObject)
	{
		if let d = sender.representedObject as? Dictionary<String, AnyObject> {
			(d["class"] as! CoiffeurControllerClass).currentExecutableURL
				= (d["url"] as! NSURL)
		}
	}
}

class TransparentTableView : NSTableView {
	
	override func awakeFromNib()
	{
		self.enclosingScrollView!.drawsBackground = false
	}
	
	override var opaque : Bool {
		return false
	}
	
	override func drawBackgroundInClipRect(clipRect : NSRect)
	{
	// don't draw a background rect
	}
}

class TransparentTableRowView : NSTableRowView {
	override func drawBackgroundInRect(dirtyRect: NSRect)
	{
		
	}
	override var opaque : Bool {
			return false
	}
}