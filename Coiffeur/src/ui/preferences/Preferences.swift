//
//  Preferences.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/12/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

class Preferences : PreferencesWindow {

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

	convenience init()
	{
		self.init(panes:[CoiffeurPreferences(),
			TextPresentationPreferences(),
			ColorAndFontPreferences()])
	}

}