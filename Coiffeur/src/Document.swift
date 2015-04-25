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

  var model : CoiffeurController?
  
  override init()
  {
    super.init()
  }
  
  convenience init?(type typeName: String, error outError: NSErrorPointer)
  {
    self.init()
    self.fileType = typeName

    let result = CoiffeurController.coiffeurWithType(typeName)
    switch result {
    case .Failure(let error):
      error.assignTo(outError)
      return nil
    case .Success(let controller):
      self.model = controller
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
  
  private func _ensureWeHaveModelOfType(typeName:String,
		errorFormatKey:String) -> NSError?
  {
    if let model = self.model {
      let documentType = model.dynamicType.documentType
      if typeName == documentType {
        return nil
      }
      return Error(errorFormatKey, typeName, documentType)
    } else {
      let result = CoiffeurController.coiffeurWithType(typeName)
      switch result {
      case .Failure(let error):
        return error
      case .Success(let controller):
        self.model = controller
        return nil
      }
    }
  }
  
  override func readFromURL(absoluteURL: NSURL, ofType typeName: String,
		error outError: NSErrorPointer) -> Bool
  {
    if let error = self._ensureWeHaveModelOfType(typeName,
			errorFormatKey:"Cannot read content of document “%@” into document “%@”")
		{
      error.assignTo(outError)
      return false
    }
    
    if let error = self.model!.readValuesFromURL(absoluteURL) {
      error.assignTo(outError)
      return false
    }
    
    return true
  }
  
  override func writeToURL(absoluteURL: NSURL, ofType typeName: String,
		error outError: NSErrorPointer) -> Bool
  {
    if let error = self._ensureWeHaveModelOfType(typeName,
			errorFormatKey:"Cannot write content of document “%2$@” as “%1$@”")
		{
      error.assignTo(outError)
      return false
    }
    
    if let error = self.model!.writeValuesToURL(absoluteURL) {
      error.assignTo(outError)
      return false
    }
    
    return true
  }
  
  override class func autosavesInPlace() -> Bool
  {
    return true
  }
  
  override func makeWindowControllers()
  {
    self.addWindowController(MainWindowController())
  }
  
//  override func canCloseDocumentWithDelegate(delegate: AnyObject, 
//		shouldCloseSelector: Selector, contextInfo: UnsafeMutablePointer<Void>)
//  {
//    self.model?.managedObjectContext.commitEditing()
//    super.canCloseDocumentWithDelegate(delegate, 
//			shouldCloseSelector:shouldCloseSelector, contextInfo:contextInfo)
//  }
	
  override func writableTypesForSaveOperation(_: NSSaveOperationType)
		-> [AnyObject]
  {
    if let m = self.model {
      return [m.dynamicType.documentType]
    } else {
      return []
    }
  }
  
}
