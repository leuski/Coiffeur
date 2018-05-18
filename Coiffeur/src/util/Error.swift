//
//  Error.swift
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

import Foundation

class Error : NSError {
  class var Domain : String { return "CoiffeurErrorDomain" }
  
  init(localizedDescription:String)
  {
    super.init(domain: Error.Domain, code: 0,
			userInfo: [NSLocalizedDescriptionKey:localizedDescription])
  }
  
  convenience init(_ format:String, _ args: CVarArg...)
  {
    self.init(localizedDescription:String(
			format:NSLocalizedString(format, comment:""), arguments:args))
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder:aDecoder)
  }
}

extension NSError {
  func assignTo(_ outError:NSErrorPointer?)
  {
    if outError != nil {
      outError??.pointee = self
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
  case success(String)
  case failure(NSError)
	init(_ value:String)
	{
		self = .success(value)
	}
	init(_ error:NSError)
	{
		self = .failure(error)
	}
}

enum URLResult {
  case success(URL)
  case failure(NSError)
	init(_ value:URL)
	{
		self = .success(value)
	}
	init(_ error:NSError)
	{
		self = .failure(error)
	}
}
