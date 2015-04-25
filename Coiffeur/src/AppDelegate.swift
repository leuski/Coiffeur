//
//  AppDelegate.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

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
    DocumentController() // load ours...
    
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
      var item = NSMenuItem(title: l.displayName,
				action: "changeLanguage:", keyEquivalent: "")
      item.representedObject = l
      self.languagesMenu.addItem(item)
    }
    
    var count = 0
    
    for aClass in CoiffeurController.availableTypes {
      var item = NSMenuItem(title: aClass.documentType,
				action: "openUntitledDocumentOfType:", keyEquivalent: "")
      item.representedObject = aClass.documentType
      
      if (count < 2) {
        item.keyEquivalent = "n"
        var mask = NSEventModifierFlags.CommandKeyMask
        
        if (count > 0) {
          mask |= NSEventModifierFlags.AlternateKeyMask
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
      let controller = NSDocumentController.sharedDocumentController()
				as! DocumentController
      var error : NSError?
      if nil == controller.openUntitledDocumentOfType(type,
				display:true, error:&error)
			{
        if error != nil {
          NSApp.presentError(error!)
        }
      }
    }
  }
  
	
}

