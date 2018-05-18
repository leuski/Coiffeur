//
//  PreferencesWindow.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/10/15.
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

// base protocol for a preferecne pane.
@objc protocol PreferencePaneViewController {
	var view : NSView { get set }
	func commitEditing() -> Bool
}

// NSViewController satisfies it
extension NSViewController : PreferencePaneViewController {
}

// a preference is the base plus these methods/properties
protocol PreferencePane : class, PreferencePaneViewController {
	var toolbarIdentifier : String { get }
	var toolbarItemLabel : String { get }
	var toolbarItemToolTip : String? { get }
	var toolbarItemImage : NSImage? { get }
	var initialKeyView : NSView? { get }
}

// a default implementation to support the basic fuctionality
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
	
	fileprivate var _referenceClassName : String {
		return self._unqualifiedClassName
	}
	
	fileprivate var _unqualifiedClassName: String {
		let name = type(of: self).className()
		if let range = name.range(of: ".", options: NSString.CompareOptions(),
			range: name.startIndex..<name.endIndex, locale: nil)
		{
			return String(name[range.upperBound...])
		}
		return name
	}
	
	override var nibName : NSNib.Name? {
    return NSNib.Name(rawValue: self._unqualifiedClassName)
	}
}

// the preferences window class. Manages a collection of panes and a
// toolbar to switch among them
class PreferencesWindow : NSWindowController {
	
	@IBOutlet weak var containerView: NSView!

	typealias Pane = PreferencePane
	
	var panes = [Pane]()
	var selectedPane : Pane? {
		get { return storedSelectedPane }
		set (newSelectedPane) {
			if (storedSelectedPane == nil
					&& newSelectedPane == nil)
				|| (storedSelectedPane != nil
					&& newSelectedPane != nil
					&& storedSelectedPane!.toolbarIdentifier
						== newSelectedPane!.toolbarIdentifier)
			{
				return
			}

			let w = self.window!

			if let currentPane = storedSelectedPane {
				if !currentPane.commitEditing() {
					w.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: currentPane.toolbarIdentifier)
					return
				}
				currentPane.view.removeFromSuperview()
				w.title = ""
			}
			
			self.storedSelectedPane = newSelectedPane
			
			if let currentPane = self.storedSelectedPane {
				w.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: currentPane.toolbarIdentifier)
				w.title = currentPane.toolbarItemLabel
				UserDefaults.standard.set(
					currentPane.toolbarIdentifier, forKey: selectedPaneUDKey)

				let childView = currentPane.view
				childView.translatesAutoresizingMaskIntoConstraints = false

				let childDesiredFrame = childView.frame

				var containerFrame = w.contentView!.frame
				w.contentView = childView
				w.recalculateKeyViewLoop()
				if (w.firstResponder == self.window) {
					w.makeFirstResponder(currentPane.initialKeyView)
				}
				
				containerFrame.size.height = childDesiredFrame.size.height
				let desiredWindowFrame = w.frameRect(forContentRect: containerFrame)
				var currentWindowFrame = w.frame
				currentWindowFrame.origin.y += currentWindowFrame.size.height
					- desiredWindowFrame.size.height
				currentWindowFrame.size.height = desiredWindowFrame.size.height
				
				w.setFrame(currentWindowFrame, display: true, animate: w.isVisible)
			}
			
		}
	}

	fileprivate var storedSelectedPane : Pane?
	fileprivate let selectedPaneUDKey = "selectedPaneUDKey"
	
	var toolbarItemIdentifiers : [NSToolbarItem.Identifier] {
    return self.panes.map { NSToolbarItem.Identifier(rawValue: $0.toolbarIdentifier) }
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
    self.init(windowNibName:NSNib.Name(rawValue: "PreferencesWindow"))
		self.panes = panes
  }

	override func windowDidLoad()
	{
		if !panes.isEmpty {
			self.selectedPane = self.paneWithID(
				UserDefaults.standard.string(forKey: selectedPaneUDKey))
				?? self.panes[0]
		}
	}

	override func showWindow(_ sender: Any?)
	{
		self.window!.makeKeyAndOrderFront(sender)
	}
	
	func paneWithID(_ paneIdentifier:String?) -> Pane?
	{
		if let identifier = paneIdentifier {
			return (self.panes.filter { $0.toolbarIdentifier == identifier }).first
		} else {
			return nil
		}
	}

	func selectPane(index : Int)
	{
		if index >= self.panes.startIndex && index < self.panes.endIndex {
			self.selectedPane = self.panes[index]
		}
	}
	
	func selectPane(identifier : String)
	{
		self.selectedPane = self.paneWithID(identifier)
	}
	
}

extension PreferencesWindow : NSWindowDelegate {
	func windowShouldClose(_ sender: NSWindow) -> Bool
	{
		return self.selectedPane == nil || self.selectedPane!.commitEditing()
	}
}

extension PreferencesWindow : NSToolbarDelegate {
	
	func toolbar(_ toolbar: NSToolbar,
		itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
		willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem?
	{
		let item = NSToolbarItem(itemIdentifier: itemIdentifier)
		if let pane = self.paneWithID(itemIdentifier.rawValue) {
			item.target = self
			item.action = #selector(PreferencesWindow.itemSelected(_:))
			item.label = pane.toolbarItemLabel
			item.image = pane.toolbarItemImage
			item.toolTip = pane.toolbarItemToolTip
		}
		return item
	}
	
	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier]
	{
		return self.toolbarItemIdentifiers
	}
	
	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier]
	{
		return self.toolbarItemIdentifiers
	}
	
	func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier]
	{
		return self.toolbarItemIdentifiers
	}
	
	@objc func itemSelected(_ toolbarItem:AnyObject)
	{
		self.selectedPane = self.paneWithID(toolbarItem.itemIdentifier.rawValue)
	}
	
}
