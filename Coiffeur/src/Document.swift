//
//  Document.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

@objc(Document)
class Document : NSDocument {
  var model : ALCoiffeurController?
  var coiffeur : ALCoiffeurView?
  
  override init()
  {
    super.init()
  }
  
  convenience init?(type typeName: String, error outError: NSErrorPointer)
  {
    self.init()
    self.fileType = typeName
    self.model = self._modelControllerOfType(typeName, error:outError)
    if self.model == nil {
      return nil
    }
  }
  
  override var undoManager : NSUndoManager? {
    get {
      if let model = self.model {
        return model.managedObjectContext.undoManager
      } else {
        return super.undoManager
      }
    }
    set (um) {
      super.undoManager = um
    }
  }
  
  private func _modelControllerOfType(type :String, error outError:NSErrorPointer) -> ALCoiffeurController?
  {
    for c in ALCoiffeurController.availableTypes  {
      if type == c.documentType {
        return c.self(error:outError)
      }
    }
    
    if outError != nil {
      outError.memory = Error(String(format:NSLocalizedString("Unknown document type “%@”", comment:"unknown type error"), type))
    }
    
    return nil
  }
  
  private func _ensureWeHaveModelOfType(typeName:String, errorFormatKey:String, error outError:NSErrorPointer) -> Bool
  {
    if let model = self.model {
      let documentType = model.dynamicType.documentType
      if typeName == documentType {
        return true
      }
      if outError != nil {
        outError.memory = Error(String(format:NSLocalizedString(errorFormatKey, comment:errorFormatKey), typeName, documentType))
      }
      return false
    } else {
      self.model = self._modelControllerOfType(typeName, error:outError)
      return self.model != nil
    }
  }
  
  override func readFromURL(absoluteURL: NSURL, ofType typeName: String, error outError: NSErrorPointer) -> Bool
  {
    if !self._ensureWeHaveModelOfType(typeName,
      errorFormatKey:"Cannot read content of document “%@” into document “%@”", error:outError) {
        return false
    }
    
    return self.model!.readValuesFromURL(absoluteURL, error:outError)
  }
  
  override func writeToURL(absoluteURL: NSURL, ofType typeName: String, error outError: NSErrorPointer) -> Bool
  {
    if !self._ensureWeHaveModelOfType(typeName,
      errorFormatKey:"Cannot write content of document “%2$@” as “%1$@”", error:outError) {
        return false
    }
    
    return self.model!.writeValuesToURL(absoluteURL, error:outError)
  }
  
  override class func autosavesInPlace() -> Bool
  {
    return true
  }
  
  override func makeWindowControllers()
  {
    self.addWindowController(ALMainWindowController())
  }
  
  func embedInView(container:NSView)
  {
    if let v = ALCoiffeurView(model:self.model, bundle:nil) {
      self.coiffeur = v
      v.embedInView(container)
    }
  }
  
  override func canCloseDocumentWithDelegate(delegate: AnyObject, shouldCloseSelector: Selector, contextInfo: UnsafeMutablePointer<Void>)
  {
    self.model?.managedObjectContext.commitEditing()
    super.canCloseDocumentWithDelegate(delegate, shouldCloseSelector:shouldCloseSelector, contextInfo:contextInfo)
  }
  
  override func writableTypesForSaveOperation(saveOperation: NSSaveOperationType) -> [AnyObject]
  {
    if let m = self.model {
      return [m.dynamicType.documentType]
    } else {
      return []
    }
  }
  
}
