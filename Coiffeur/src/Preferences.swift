//
//  Preferences.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/10/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

class Preferences : NSWindowController {
  
  override init(window: NSWindow?)
  {
    super.init(window: window)
  }
  
  required init?(coder: NSCoder)
  {
    super.init(coder:coder)
  }
  
  convenience init()
  {
    self.init(windowNibName:"Preferences")
  }

  var clangFormatExecutable : NSURL? {
    get {
      switch ClangFormatController.findExecutableURL() {
      case .Success(let url):
        return url
      case .Failure(let err):
        return nil
      }
    }
    set (value) {
      ClangFormatController.e
    }
  }
}