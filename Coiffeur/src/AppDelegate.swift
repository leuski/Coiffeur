//
//  AppDelegate.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

@objc(AppDelegate)
class AppDelegate : NSObject, NSApplicationDelegate {
  
  let AboutFileName = "about"
  let AboutFileNameExtension = "html"
  let UserDefaultsFileNameExtension = "plist"
  let UserDefaultsFileName   = "UserDefaults"
  
  @IBOutlet weak var languagesMenu : NSMenu!
  @IBOutlet weak var makeNewDocumentMenu : NSMenu!
  
  override init()
  {
    super.init()
    ALDocumentController()
    
    MGSFragaria.initializeFramework()
    
    let bundle = NSBundle(forClass:self.dynamicType)
    if let UDURL  = bundle.URLForResource(UserDefaultsFileName, withExtension:UserDefaultsFileNameExtension) {
      if let ud     = NSDictionary(contentsOfURL:UDURL) {
        NSUserDefaults.standardUserDefaults().registerDefaults(ud)
      }
    }
  }
  
  func applicationDidFinishLaunching(aNotification:NSNotification)
  {
    for l in ALLanguage.supportedLanguages {
      var item = NSMenuItem(title: l.displayName, action: Selector("changeLanguage:"), keyEquivalent: "")
      item.representedObject = l;
      self.languagesMenu.addItem(item)
    }
    
    var count = 0
    
    for aClass in CoiffeurController.availableTypes {
      var item = NSMenuItem(title: aClass.documentType, action: Selector("AL_openUntitledDocumentOfType:"), keyEquivalent: "")
      item.representedObject = aClass.documentType
      
      if (count < 2) {
        item.keyEquivalent = "n";
        var mask = NSEventModifierFlags.CommandKeyMask
        
        if (count > 0) {
          mask |= NSEventModifierFlags.AlternateKeyMask
        }
        
        item.keyEquivalentModifierMask = Int(mask.rawValue)
      }
      
      self.makeNewDocumentMenu.addItem(item)
      ++count;
    }
  }
  
  func applicationWillTerminate(aNotification:NSNotification)
  {
    // Insert code here to tear down your application
  }
  
  @IBAction func AL_openUntitledDocumentOfType(sender : AnyObject)
  {
    if let type = sender.representedObject as? String {
      
      var error : NSError?
      
      let controller = NSDocumentController.sharedDocumentController() as ALDocumentController
      
      if nil == controller.openUntitledDocumentOfType(type, display:true, error:&error) {
        if error != nil {
          NSApp.presentError(error!)
        }
      }
    }
  }
  
  var bundle : NSBundle
  {
  return NSBundle.mainBundle()
  }
  
  var aboutURL : NSURL?
  {
    return self.bundle.URLForResource(AboutFileName, withExtension:AboutFileNameExtension)
  }
  
}

