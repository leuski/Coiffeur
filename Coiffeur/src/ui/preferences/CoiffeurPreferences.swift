//
//  CoiffeurPreferences.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/11/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

class CoiffeurPreferences : DefaultPreferencePane {
	
	override var toolbarItemImage : NSImage? { return NSImage(named: "Locations") }
	
	var clangFormatExecutable : NSURL? {
		get {
			return ClangFormatController.currentExecutableURL
		}
		set (value) {
			ClangFormatController.currentExecutableURL = value
		}
	}
	
	var uncrustifyExecutable : NSURL? {
		get {
			return UncrustifyController.currentExecutableURL
		}
		set (value) {
			UncrustifyController.currentExecutableURL = value
		}
	}
	
}