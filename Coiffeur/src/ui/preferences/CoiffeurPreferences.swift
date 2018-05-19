//
//  CoiffeurPreferences.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/11/15.
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

import Foundation

class CoiffeurControllerClass: NSObject {
  @objc let controllerClass: CoiffeurController.Type
  var documentType: String { return controllerClass.documentType }

  init(_ type: CoiffeurController.Type)
  {
    controllerClass = type
  }

  func contentsIsValidInString(_ string: String) -> Bool
  {
    return controllerClass.contentsIsValidInString(string)
  }

  func createCoiffeur() throws -> CoiffeurController
  {
    return try controllerClass.createCoiffeur()
  }

  @objc class func keyPathsForValuesAffectingCurrentExecutableURL() -> NSSet
  {
    return NSSet(object: "controllerClass.currentExecutableURL")
  }

  @objc dynamic var currentExecutableURL: URL? {
    get {
      return controllerClass.currentExecutableURL
    }
    set (value) {
      willChangeValue(forKey: "currentExecutableURL")
      controllerClass.currentExecutableURL = value
      didChangeValue(forKey: "currentExecutableURL")
    }
  }

  var defaultExecutableURL: URL? {
    return controllerClass.defaultExecutableURL
  }

  @objc var executableDisplayName: String {
    return controllerClass.localizedExecutableTitle
  }
}

class CoiffeurPreferences: DefaultPreferencePane {

  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var constraint: NSLayoutConstraint!

  override var toolbarItemImage: NSImage? {
    return NSImage(named: NSImage.Name(rawValue: "Locations")) }

  @objc let formatters = CoiffeurController.availableTypes.map {
    CoiffeurControllerClass($0) }

  override func viewDidLoad() {
    super.viewDidLoad()
    let height = self.tableView.bounds.size.height + 2
    let delta = self.tableView.enclosingScrollView!.frame.size.height - height
    self.constraint.constant -= delta
    self.view.frame.size.height -= delta
  }
}

extension CoiffeurPreferences: NSTableViewDelegate {
  func tableView(
    _ tableView: NSTableView,
    rowViewForRow row: Int) -> NSTableRowView?
  {
    return TransparentTableRowView()
  }
}

extension CoiffeurPreferences: NSPathControlDelegate {
  func pathControl(_ pathControl: NSPathControl, willPopUp menu: NSMenu)
  {
    if
      let tcv = pathControl.superview as? NSTableCellView,
      let ccc = tcv.objectValue as? CoiffeurControllerClass,
      let url = ccc.defaultExecutableURL
    {
      let item = menu.insertItem(
        withTitle: String(format: NSLocalizedString("Built-in %@", comment: ""),
                          url.lastPathComponent),
        action: #selector(CoiffeurPreferences.selectURL(_:)),
        keyEquivalent: "", at: 0)
      item.representedObject = [ "class": ccc, "url": url ]
        as [String: AnyObject]
    }
  }

  @objc func selectURL(_ sender: AnyObject)
  {
    if
      let dictionary = sender.representedObject as? [String: AnyObject],
      let theClass = dictionary["class"] as? CoiffeurControllerClass
    {
      theClass.currentExecutableURL = dictionary["url"] as? URL
    }
  }
}

class TransparentTableView: NSTableView {

  override func awakeFromNib()
  {
    self.enclosingScrollView!.drawsBackground = false
  }

  override var isOpaque: Bool {
    return false
  }

  override func drawBackground(inClipRect clipRect: NSRect)
  {
    // don't draw a background rect
  }
}

class TransparentTableRowView: NSTableRowView {
  override func drawBackground(in dirtyRect: NSRect)
  {

  }
  override var isOpaque: Bool {
    return false
  }
}
