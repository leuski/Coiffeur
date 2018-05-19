//
//  DocumentController.swift
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

import Cocoa

class DocumentController : NSDocumentController {
  
  override func beginOpenPanel(_ openPanel: NSOpenPanel,
		forTypes inTypes: [String]?, completionHandler: @escaping (Int) -> Void)
  {
    openPanel.showsHiddenFiles = true
    super.beginOpenPanel(openPanel, forTypes:inTypes,
			completionHandler:completionHandler)
  }
	
  @discardableResult
	fileprivate func _classForType(_ type:String) throws -> CoiffeurController.Type
	{
		for aClass in CoiffeurController.availableTypes {
			if type == aClass.documentType {
				return aClass
			}
		}
		throw Error("Unknown type \(type)")
	}
	
  override func typeForContents(of url: URL) throws -> String
  {
    let type = try super.typeForContents(of: url)
		try _classForType(type)
		
		let data = try String(contentsOf:url, encoding:String.Encoding.utf8)

		for conroller in CoiffeurController.availableTypes {
			if conroller.contentsIsValidInString(data) {
				return conroller.documentType
			}
		}

		throw Error("Unknown data at URL \(url)")
  }
  
}
