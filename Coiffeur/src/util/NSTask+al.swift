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
extension NSTask {
	
	/**
		initializes the task with exetubale url, arguments, and working directory.
		Sets the standard streams to pipes
	*/
	convenience init(_ url:NSURL, arguments:[String] = [],
		workingDirectory:String? = nil)
	{
		self.init()
		
		self.launchPath = url.path!
		self.arguments = arguments
		if workingDirectory != nil {
			self.currentDirectoryPath = workingDirectory!
		}
		
		self.standardOutput = NSPipe()
		self.standardInput = NSPipe()
		self.standardError = NSPipe()
	}

	private func _run(input:String?) -> StringResult
	{
		let writeHandle = input != nil
			? self.standardInput.fileHandleForWriting
			: nil
		
		self.launch()
		
		if writeHandle != nil {
			writeHandle.writeData(input!.dataUsingEncoding(NSUTF8StringEncoding)!)
			writeHandle.closeFile()
		}
		
		let outHandle = self.standardOutput.fileHandleForReading
		let outData = outHandle.readDataToEndOfFile()
		
		let errHandle = self.standardError.fileHandleForReading
		let errData = errHandle.readDataToEndOfFile()
		
		self.waitUntilExit()
		
		let status = self.terminationStatus
		
		if status == 0 {
			if let string = String(data:outData, encoding: NSUTF8StringEncoding) {
				return StringResult(string)
			} else {
				return StringResult(
					Error("Failed to interpret the output of the format executable"))
			}
		} else {
			if let errText = String(data: errData, encoding: NSUTF8StringEncoding) {
				return StringResult(Error("Format excutable error code %d: %@",
					status, errText))
			} else {
				return StringResult(Error("Format excutable error code %d", status))
			}
		}
	}

	/**
		Runs the task synchroniously with the given string as the standard input.
		@return Returns a string from stadard output or an error
	*/
	func run(_ input:String? = nil) -> StringResult
	{
		var result : StringResult?
		ALExceptions.try({
			result = self._run(input)
		}, catch: { (ex:NSException?) in
			result = StringResult(
				Error("An error while running format executable: %@",
					ex?.reason ?? "unknown error"))
		}, finally: {})
		return result!
	}
	
	/**
		Runs the task asynchroniously with the given string as the standard input.
		Calls the provided block with the string from stadard output or an error
	*/
	func runAsync(_ input:String? = nil, completionHandler:(_:StringResult)->Void)
	{
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), {
			let result = self.run(input)
			dispatch_async(dispatch_get_main_queue(), {
				completionHandler(result)
			})
		})
	}

}