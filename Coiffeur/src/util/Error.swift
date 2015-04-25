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
  
  init(localizedDescription:String)
  {
    super.init(domain: Error.Domain, code: 0,
			userInfo: [NSLocalizedDescriptionKey:localizedDescription])
  }
  
  convenience init(_ format:String, _ args: CVarArgType...)
  {
    self.init(localizedDescription:String(
			format:NSLocalizedString(format, comment:""), arguments:args))
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

// Compiler crashes if I use this as of Swift 1.2
//enum Result<T:AnyObject> {
//  case Success(T)
//  case Failure(NSError)
//	init(_ value:T)
//	{
//		self = .Success(value)
//	}
//	init(_ error:NSError)
//	{
//		self = .Failure(error)
//	}
//}

enum StringResult {
  case Success(String)
  case Failure(NSError)
	init(_ value:String)
	{
		self = .Success(value)
	}
	init(_ error:NSError)
	{
		self = .Failure(error)
	}
}

enum URLResult {
  case Success(NSURL)
  case Failure(NSError)
	init(_ value:NSURL)
	{
		self = .Success(value)
	}
	init(_ error:NSError)
	{
		self = .Failure(error)
	}
}
