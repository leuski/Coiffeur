//
//  Error.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

class Error : NSError {
  class var Domain : String { return "CoiffeurErrorDomain" }
  
  init(_ localizedDescription:String)
  {
    super.init(domain: Error.Domain, code: 0, userInfo: [NSLocalizedDescriptionKey:localizedDescription])
  }
  
  convenience init(format:String, _ args: CVarArgType...)
  {
    self.init(String(format:NSLocalizedString(format, comment:""), arguments:args))
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder:aDecoder)
  }
}

extension NSError {
  func assignTo(outError:NSErrorPointer)
  {
    if outError != nil {
      outError.memory = self
    }
  }
}

enum Result<T:AnyObject> {
  case Success(T)
  case Failure(NSError)
}

enum StringResult {
  case Success(String)
  case Failure(NSError)
}

enum TaskResult {
  case Success(NSTask)
  case Failure(NSError)
}

enum URLResult {
  case Success(NSURL)
  case Failure(NSError)
}
