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
class AppDelegate: NSObject, NSApplicationDelegate {

  static private let AboutFileName = "about"
  static private let AboutFileNameExtension = "html"
  static private let UserDefaultsFileNameExtension = "plist"
  static private let UserDefaultsFileName   = "UserDefaults"

  @IBOutlet weak var languagesMenu: NSMenu!
  @IBOutlet weak var makeNewDocumentMenu: NSMenu!

  @objc var bundle: Bundle {
    return Bundle.main
  }

  @objc var aboutURL: URL? {
    return self.bundle.url(
      forResource: AppDelegate.AboutFileName,
      withExtension: AppDelegate.AboutFileNameExtension)
  }

  override init()
  {
    super.init()
    _ = DocumentController() // load ours...

    MGSFragaria.initializeFramework()

    let bundle = Bundle(for: type(of: self))
    if
      let UDURL = bundle.url(
        forResource: AppDelegate.UserDefaultsFileName,
        withExtension: AppDelegate.UserDefaultsFileNameExtension),
      let defaults = NSDictionary(contentsOf: UDURL) as? [String: Any]
    {
      UserDefaults.standard.register(defaults: defaults)
    }
  }

  func applicationDidFinishLaunching(_ aNotification: Notification)
  {
    for language in Language.supportedLanguages {
      let item = NSMenuItem(
        title: language.displayName,
        action: #selector(MainWindowController.changeLanguage(_:)),
        keyEquivalent: "")
      item.representedObject = language
      self.languagesMenu.addItem(item)
    }

    var count = 0

    for aClass in CoiffeurController.availableTypes {
      let item = NSMenuItem(
        title: aClass.documentType,
        action: #selector(AppDelegate.openUntitledDocumentOfType(_:)),
        keyEquivalent: "")
      item.representedObject = aClass.documentType

      if count < 2 {
        item.keyEquivalent = "n"
        var mask = NSEvent.ModifierFlags.command

        if count > 0 {
          mask = mask.union(.option)
        }

        item.keyEquivalentModifierMask = mask
      }

      self.makeNewDocumentMenu.addItem(item)
      count += 1
    }
  }

  func applicationWillTerminate(_ aNotification: Notification)
  {
    // Insert code here to tear down your application
  }

  @IBAction func openUntitledDocumentOfType(_ sender: AnyObject)
  {
    if let type = sender.representedObject as? String {
      do {
        let controller = NSDocumentController.shared
        let document = try controller.makeUntitledDocument(ofType: type)
        controller.addDocument(document)
        document.makeWindowControllers()
        document.showWindows()
      } catch let error {
        NSApp.presentError(error)
      }
    }
  }

}
