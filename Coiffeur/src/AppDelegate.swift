//
//  AppDelegate.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
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

import Cocoa

@NSApplicationMain
class AppDelegate : NSObject, NSApplicationDelegate {
  
	private struct Private {
		static private let AboutFileName = "about"
		static private let AboutFileNameExtension = "html"
		static private let UserDefaultsFileNameExtension = "plist"
		static private let UserDefaultsFileName   = "UserDefaults"
	}
	
  @IBOutlet weak var languagesMenu : NSMenu!
  @IBOutlet weak var makeNewDocumentMenu : NSMenu!
  
	var bundle : NSBundle {
		return NSBundle.mainBundle()
	}
	
	var aboutURL : NSURL? {
		return self.bundle.URLForResource(Private.AboutFileName,
			withExtension:Private.AboutFileNameExtension)
	}

	override init()
  {
    super.init()
    let _ = DocumentController() // load ours...
    
    MGSFragaria.initializeFramework()
    
    let bundle = NSBundle(forClass:self.dynamicType)
    if let UDURL = bundle.URLForResource(Private.UserDefaultsFileName,
					withExtension:Private.UserDefaultsFileNameExtension),
       let ud = NSDictionary(contentsOfURL:UDURL) as? [String:AnyObject]
    {
      NSUserDefaults.standardUserDefaults().registerDefaults(ud)
    }
  }
  
  func applicationDidFinishLaunching(aNotification:NSNotification)
  {
    for l in Language.supportedLanguages {
      let item = NSMenuItem(title: l.displayName,
				action: "changeLanguage:", keyEquivalent: "")
      item.representedObject = l
      self.languagesMenu.addItem(item)
    }
    
    var count = 0
    
    for aClass in CoiffeurController.availableTypes {
      let item = NSMenuItem(title: aClass.documentType,
				action: "openUntitledDocumentOfType:", keyEquivalent: "")
      item.representedObject = aClass.documentType
      
      if (count < 2) {
        item.keyEquivalent = "n"
        var mask = NSEventModifierFlags.CommandKeyMask
        
        if (count > 0) {
          mask = mask.union(NSEventModifierFlags.AlternateKeyMask)
        }
        
        item.keyEquivalentModifierMask = Int(mask.rawValue)
      }
      
      self.makeNewDocumentMenu.addItem(item)
      ++count
    }
  }
  
  func applicationWillTerminate(aNotification:NSNotification)
  {
    // Insert code here to tear down your application
  }
  
  @IBAction func openUntitledDocumentOfType(sender : AnyObject)
  {
    if let type = sender.representedObject as? String {
			do {
				let controller = NSDocumentController.sharedDocumentController()
				let document = try controller.makeUntitledDocumentOfType(type)
				controller.addDocument(document)
				document.makeWindowControllers()
				document.showWindows()
			} catch let err as NSError {
				NSApp.presentError(err)
			}
    }
  }
  
	
}

