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
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder:aDecoder)
  }
}

enum Result<T> {
  case Success(@autoclosure () -> T)
  case Failure(NSError)
}
