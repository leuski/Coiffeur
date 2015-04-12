//
//  PreferencesWindow.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/10/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

@objc protocol PreferencePaneViewController {
	var view : NSView { get set }
	func commitEditing() -> Bool
}
extension NSViewController : PreferencePaneViewController {
}

protocol PreferencePane : class, PreferencePaneViewController {
	var toolbarIdentifier : String { get }
	var toolbarItemLabel : String { get }
	var toolbarItemToolTip : String? { get }
	var toolbarItemImage : NSImage? { get }
	var initialKeyView : NSView? { get }
}

class DefaultPreferencePane : NSViewController, PreferencePane {
	
	@IBOutlet var initialKeyView : NSView?
	
	var toolbarIdentifier : String { return self._referenceClassName }

	var toolbarItemLabel : String {
		return NSLocalizedString("\(self._referenceClassName).label", comment:"")
	}
	
	var toolbarItemToolTip : String? {
		let key = "\(self._referenceClassName).tooltip"
		let tooltip = NSLocalizedString(key, comment:"")
		if key == tooltip {
			return self.toolbarItemLabel
		}
		return tooltip
	}
	var toolbarItemImage : NSImage? { return nil }
	
	private var _referenceClassName : String {
		return self._unqualifiedClassName
	}
	
	private var _unqualifiedClassName: String {
		let name = self.dynamicType.className()
		if let range = name.rangeOfString(".", options: NSStringCompareOptions(), range: name.startIndex..<name.endIndex, locale: nil) {
			return name.substringFromIndex(range.endIndex)
		}
		return name
	}
	
	override var nibName : String? {
		return self._unqualifiedClassName
	}

}

class PreferencesWindow : NSWindowController, NSWindowDelegate, NSToolbarDelegate {
	
	@IBOutlet weak var containerView: NSView!

	typealias Pane = PreferencePane
	
	var panes = [Pane]()
	var selectedPane : Pane? {
		get { return storedSelectedPane }
		set (newSelectedPane) {
			if (storedSelectedPane == nil && newSelectedPane == nil)
			|| (storedSelectedPane != nil && newSelectedPane != nil && storedSelectedPane!.toolbarIdentifier == newSelectedPane!.toolbarIdentifier) {
				return
			}

			if let currentPane = storedSelectedPane {
				if !currentPane.commitEditing() {
					self.window?.toolbar?.selectedItemIdentifier = currentPane.toolbarIdentifier
					return
				}
				currentPane.view.removeFromSuperview()
				self.window?.title = ""
			}
			
			self.storedSelectedPane = newSelectedPane
			
			if let currentPane = self.storedSelectedPane {
				self.window?.title = currentPane.toolbarItemLabel
				NSUserDefaults.standardUserDefaults().setObject(currentPane.toolbarIdentifier, forKey: selectedPaneUDKey)

				let childView = currentPane.view
				childView.translatesAutoresizingMaskIntoConstraints = false

				var childDesiredFrame = childView.frame

				var containerFrame = self.window!.contentView.frame
				self.window!.contentView = childView
				self.window!.recalculateKeyViewLoop()
				if (self.window!.firstResponder == self.window) {
					self.window?.makeFirstResponder(currentPane.initialKeyView)
				}
				
				containerFrame.size.height = childDesiredFrame.size.height
				let desiredWindowFrame = self.window!.frameRectForContentRect(containerFrame)
				var currentWindowFrame = self.window!.frame
				currentWindowFrame.origin.y += currentWindowFrame.size.height - desiredWindowFrame.size.height
				currentWindowFrame.size.height = desiredWindowFrame.size.height
				
				self.window!.setFrame(currentWindowFrame, display: true, animate: self.window!.visible)
			}
			
		}
	}

	private var storedSelectedPane : Pane?
	private let selectedPaneUDKey = "selectedPaneUDKey"
	
	var toolbarItemIdentifiers : [String] {
		return self.panes.map { $0.toolbarIdentifier }
	}
	
  override init(window: NSWindow?)
  {
    super.init(window: window)
  }
  
  required init?(coder: NSCoder)
  {
    super.init(coder:coder)
  }
  
	convenience init(panes:[Pane])
  {
    self.init(windowNibName:"PreferencesWindow")
		self.panes = panes
  }

	override func windowDidLoad() {
		if !panes.isEmpty {
			self.selectedPane = self.paneWithID(NSUserDefaults.standardUserDefaults().stringForKey(selectedPaneUDKey)) ?? self.panes[0]
		}
	}

	override func showWindow(sender: AnyObject?) {
		self.window!.makeKeyAndOrderFront(sender)
	}
	
	func windowShouldClose(sender: AnyObject) -> Bool {
		return self.selectedPane == nil || self.selectedPane!.commitEditing()
	}
	
	func paneWithID(paneIdentifier:String?) -> Pane?
	{
		if let identifier = paneIdentifier {
			let list = self.panes.filter { $0.toolbarIdentifier == identifier }
			return list.isEmpty ? nil : list[0]
		} else {
			return nil
		}
	}
	
	func toolbar(toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: String, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem?
	{
		var item = NSToolbarItem(itemIdentifier: itemIdentifier)
		if let pane = self.paneWithID(itemIdentifier) {
			item.target = self
			item.action = Selector("itemSelected:")
			item.label = pane.toolbarItemLabel
			item.image = pane.toolbarItemImage
			item.toolTip = pane.toolbarItemToolTip
		}
		return item
	}
	
	func toolbarAllowedItemIdentifiers(toolbar: NSToolbar) -> [AnyObject]
	{
		return self.toolbarItemIdentifiers
	}
	
	func toolbarDefaultItemIdentifiers(toolbar: NSToolbar) -> [AnyObject]
	{
		return self.toolbarItemIdentifiers
	}
	
	func toolbarSelectableItemIdentifiers(toolbar: NSToolbar) -> [AnyObject]
	{
		return self.toolbarItemIdentifiers
	}
	
	func itemSelected(toolbarItem:AnyObject)
	{
		self.selectedPane = self.paneWithID(toolbarItem.itemIdentifier)
	}
	
	func selectPane(#index : Int)
	{
		if index >= self.panes.startIndex && index < self.panes.endIndex {
			self.selectedPane = self.panes[index]
		}
	}
	
	func selectPane(#identifier : String)
	{
		self.selectedPane = self.paneWithID(identifier)
	}
	
}