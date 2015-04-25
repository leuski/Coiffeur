//
//  DocumentController.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

class DocumentController : NSDocumentController {
  
  override func beginOpenPanel(openPanel: NSOpenPanel,
		forTypes inTypes: [AnyObject], completionHandler: (Int) -> Void)
  {
    openPanel.showsHiddenFiles = true
    super.beginOpenPanel(openPanel, forTypes:inTypes,
			completionHandler:completionHandler)
  }
  
  override func typeForContentsOfURL(url: NSURL,
		error outError: NSErrorPointer) -> String?
  {
    let result = super.typeForContentsOfURL(url, error:outError)
    if let type = result {
      for aClass in CoiffeurController.availableTypes {
        if type != aClass.documentType {
          continue
        }
        if let data = String(contentsOfURL:url,
							encoding:NSUTF8StringEncoding, error:outError)
				{
          for c in CoiffeurController.availableTypes {
            if c.contentsIsValidInString(data) {
              return c.documentType
            }
          }
        } else {
          break
        }
        return nil
      }
    }
    return result
  }
  
  func openUntitledDocumentOfType(type:String, display displayDocument:Bool,
		error outError: NSErrorPointer) -> AnyObject?
  {
    let result: AnyObject? = self.makeUntitledDocumentOfType(type,
			error:outError)
    if let document = result as? NSDocument {
      self.addDocument(document)
      
      if displayDocument {
        document.makeWindowControllers()
        document.showWindows()
      }
    }
    
    return result
  }
  
}
