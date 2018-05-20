//
//  Document.swift
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
//

import Cocoa

@objc(Document)
class Document: NSDocument {

  var model: CoiffeurController?

  override init()
  {
    super.init()
  }

  convenience init(type typeName: String) throws
  {
    self.init()
    self.fileType = typeName
    self.model = try CoiffeurController.coiffeurWithType(typeName)
  }

  override var undoManager: UndoManager? {
    get {
      if let model = self.model {
        return model.managedObjectContext.undoManager
      } else {
        return super.undoManager
      }
    }
    set {
      super.undoManager = newValue
    }
  }

  private func _ensureWeHaveModelOfType(
    _ typeName: String) throws -> String
  {
    if let model = self.model {
      return type(of: model).documentType
    }

    self.model = try CoiffeurController.coiffeurWithType(typeName)
    return typeName
  }

  override func read(from absoluteURL: URL, ofType typeName: String) throws
  {
    let modelTypeName = try _ensureWeHaveModelOfType(typeName)

    if modelTypeName != typeName {
      throw Errors.cannotReadAs(typeName, modelTypeName)
    }

    try self.model?.readValuesFromURL(absoluteURL)
  }

  override func write(to absoluteURL: URL, ofType typeName: String) throws
  {
    let modelTypeName = try _ensureWeHaveModelOfType(typeName)

    if modelTypeName != typeName {
      throw Errors.cannotWriteAs(typeName, modelTypeName)
    }

    try self.model?.writeValuesToURL(absoluteURL)
  }

  override class var autosavesInPlace: Bool
  {
    return true
  }

  override func makeWindowControllers()
  {
    self.addWindowController(MainWindowController())
  }

  //  override func canCloseDocumentWithDelegate(delegate: AnyObject,
  //    shouldCloseSelector: Selector, contextInfo: UnsafeMutablePointer<Void>)
  //  {
  //    self.model?.managedObjectContext.commitEditing()
  //    super.canCloseDocumentWithDelegate(delegate,
  //      shouldCloseSelector:shouldCloseSelector, contextInfo:contextInfo)
  //  }

  override func writableTypes(for _: NSDocument.SaveOperationType)
    -> [String]
  {
    if let model = self.model {
      return [type(of: model).documentType]
    } else {
      return []
    }
  }

}
