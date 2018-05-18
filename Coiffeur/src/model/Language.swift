//
//  Language.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
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

class Language : NSObject {
    
  fileprivate struct Private {
    fileprivate static let supportedLanguages = Language._supportedLanguages()
		fileprivate static let FileName = "languages"
		fileprivate static let FileNameExtension = "plist"
		fileprivate static let UserDefaultsKey = "Language"
  }

  class var supportedLanguages : [Language] {
		return Private.supportedLanguages }
	
	class var supportedLanguageUTIs : [String] {
		var types = Set<String>()
		for  l in Language.supportedLanguages {
			types.formUnion(l.UTIs)
		}
		return [String](types)
	}

  fileprivate(set) var uncrustifyID = ""
  fileprivate(set) var displayName = ""
  fileprivate(set) var fragariaID = ""
	fileprivate(set) var UTIs = [String]()
	fileprivate(set) var clangFormatID : String?

	var defaultExtension : String? {
    return UTIs.isEmpty
			? nil
			: NSWorkspace.shared().preferredFilenameExtension(forType: UTIs[0])
  }
  
  fileprivate class func _supportedLanguages() -> [Language]
  {
    let bundle = Bundle(for: self)
    if let url = bundle.url(forResource: Private.FileName,
			withExtension: Private.FileNameExtension)
		{
      if let dictionaries = NSArray(contentsOf: url) {
        var result = [Language]()
        for d in dictionaries {
          result.append(Language(dictionary:d as! [String : AnyObject]))
        }
        return result
      }
    }
    return []
  }

  class func languageWithUTI(_ uti:String) -> Language?
  {
    for l in self.supportedLanguages {
      if let _ = l.UTIs.index(of: uti) {
        return l
      }
    }
    return nil
  }
  
  class func languageFromUserDefaults() -> Language
  {
		let UD = UserDefaults.standard
    if let uti = UD.string(forKey: Private.UserDefaultsKey) {
      if let language = Language.languageWithUTI(uti) {
        return language
      }
    }
    return Language.languageWithUTI(kUTTypeObjectiveCPlusPlusSource as String)!
  }
  
  fileprivate init(dictionary:[String : AnyObject])
  {
    super.init()
    setValuesForKeys(dictionary)
  }
  
  func saveToUserDefaults()
  {
    if !UTIs.isEmpty {
      UserDefaults.standard.setValue(UTIs[0],
				forKey: Private.UserDefaultsKey)
    }
  }
}
