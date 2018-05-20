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

enum Errors: Swift.Error {
  case unknownType(String)
  case unknownData(URL)
  case failedLocateExecutable(URL)
  case noFormatExecutableURL
  case failedToInitializeStoreCoordinator
  case failedToInitializeManagedObjectModel
  case failedToWriteStyle(URL)
  case failedToFindFile(String, String)

  case formatExecutableError(Int32?, String?)
  case cannotReadAs(String, String)
  case cannotWriteAs(String, String)

  var localizedDescription: String {
    switch self {
    case .unknownType(let type):
      return "Unknown type \(type)."
    case .unknownData(let url):
      return "Unknown data at URL \(url)."
    case .failedLocateExecutable(let url):
      return "Cannot locate executable at \(url.path). Using the default application."
    case .noFormatExecutableURL:
      return "Format executable URL is not specified."
    case .failedToInitializeStoreCoordinator:
      return "Failed to initialize coiffeur persistent store coordinator."
    case .failedToInitializeManagedObjectModel:
      return "Failed to initialize coiffeur managed object model."
    case .failedToWriteStyle(let url):
      return "Unknown error while trying to write style to \(url.path)."
    case .failedToFindFile(let name, let ext):
      return "Cannot locate \(name).\(ext)."
    case .formatExecutableError(let status, let text):
      let errText = (text ?? "an unknown error")
        + (status == nil ? "" : " (code \(status ?? 0))")
      return "Format executable returned \(errText)."
    case .cannotReadAs(let fileType, let modelType):
      return "Cannot read content of document “\(fileType)” as “\(modelType)”."
    case .cannotWriteAs(let fileType, let modelType):
      return "Cannot write content of document “\(modelType)” as “\(fileType)”."
    }
  }
}

// Compiler crashes if I use this as of Swift 1.2
enum Result<T> {
  case success(T)
  case failure(Swift.Error)
  init(_ value: T) {
    self = .success(value)
  }
  init(_ error: Swift.Error) {
    self = .failure(error)
  }
}

typealias StringResult = Result<String>
