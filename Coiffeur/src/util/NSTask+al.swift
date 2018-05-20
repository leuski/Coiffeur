//
//  NSTask+al.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/17/15.
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

/**
 setup and exceute a task with arguments, working  directory, and input passed
 to the task standard input.
 */
extension Process {

  /**
   initializes the task with exetubale url, arguments, and working directory.
   Sets the standard streams to pipes
   */
  convenience init(
    _ url: URL,
    arguments: [String] = [],
    workingDirectory: String? = nil)
  {
    self.init()

    self.launchPath = url.path
    self.arguments = arguments
    if workingDirectory != nil {
      self.currentDirectoryPath = workingDirectory!
    }

    self.standardOutput = Pipe()
    self.standardInput = Pipe()
    self.standardError = Pipe()
  }

  private func _runThrowsNSException(_ input: String?) -> StringResult
  {
    let writeHandle = input != nil
      ? (self.standardInput! as AnyObject).fileHandleForWriting
      : nil

    self.launch()

    if writeHandle != nil {
      writeHandle?.write(input!.data(using: String.Encoding.utf8)!)
      writeHandle?.closeFile()
    }

    let outHandle = (self.standardOutput! as AnyObject).fileHandleForReading
    let outData = outHandle?.readDataToEndOfFile()

    let errHandle = (self.standardError! as AnyObject).fileHandleForReading
    let errData = errHandle?.readDataToEndOfFile()

    self.waitUntilExit()

    let status = self.terminationStatus

    if status == 0 {
      if let string = String(data: outData!, encoding: .utf8) {
        return StringResult(string)
      } else {
        return StringResult(Errors.formatExecutableError(nil, nil))
      }
    } else if
        let data = errData,
        let errText = String(data: data, encoding: .utf8)
    {
      return StringResult(Errors.formatExecutableError(status, errText))
    } else {
      return StringResult(Errors.formatExecutableError(status, nil))
    }
  }

  private func _run(_ input: String? = nil) -> StringResult
  {
    var result: StringResult?
    ALExceptions.`try`({
      result = self._runThrowsNSException(input)
    }, catch: { (exception: NSException?) in
      result = StringResult(Errors.formatExecutableError(nil, exception?.reason))
    }, finally: {})
    return result!
  }

  /**
   Runs the task synchroniously with the given string as the standard input.
   @return Returns a string from stadard output or an error
   */
  func run(_ input: String? = nil) throws -> String
  {
    switch _run(input) {
    case .success(let value): return value
    case .failure(let error): throw error
    }
  }

  /**
   Runs the task asynchroniously with the given string as the standard input.
   Calls the provided block with the string from stadard output or an error
   */
  func runAsync(
    _ input: String? = nil,
    completionHandler: @escaping (_:StringResult) -> Void)
  {
    DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
      let result = self._run(input)
      DispatchQueue.main.async {
        completionHandler(result)
      }
    }
  }

}
