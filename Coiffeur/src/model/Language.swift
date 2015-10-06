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
    
  private struct Private {
    private static let supportedLanguages = Language._supportedLanguages()
		private static let FileName = "languages"
		private static let FileNameExtension = "plist"
		private static let UserDefaultsKey = "Language"
  }

  class var supportedLanguages : [Language] {
		return Private.supportedLanguages }
	
	class var supportedLanguageUTIs : [String] {
		var types = Set<String>()
		for  l in Language.supportedLanguages {
			types.unionInPlace(l.UTIs)
		}
		return [String](types)
	}

  private(set) var uncrustifyID = ""
  private(set) var displayName = ""
  private(set) var fragariaID = ""
	private(set) var UTIs = [String]()
	private(set) var clangFormatID : String?

	var defaultExtension : String? {
    return UTIs.isEmpty
			? nil
			: NSWorkspace.sharedWorkspace().preferredFilenameExtensionForType(UTIs[0])
  }
  
  private class func _supportedLanguages() -> [Language]
  {
    let bundle = NSBundle(forClass: self)
    if let url = bundle.URLForResource(Private.FileName,
			withExtension: Private.FileNameExtension)
		{
      if let dictionaries = NSArray(contentsOfURL: url) {
        var result = [Language]()
        for d in dictionaries {
          result.append(Language(dictionary:d as! [String : AnyObject]))
        }
        return result
      }
    }
    return []
  }

  class func languageWithUTI(uti:String) -> Language?
  {
    for l in self.supportedLanguages {
      if let _ = l.UTIs.indexOf(uti) {
        return l
      }
    }
    return nil
  }
  
  class func languageFromUserDefaults() -> Language
  {
		let UD = NSUserDefaults.standardUserDefaults()
    if let uti = UD.stringForKey(Private.UserDefaultsKey) {
      if let language = Language.languageWithUTI(uti) {
        return language
      }
    }
    return Language.languageWithUTI(kUTTypeObjectiveCPlusPlusSource as String)!
  }
  
  private init(dictionary:[String : AnyObject])
  {
    super.init()
    setValuesForKeysWithDictionary(dictionary)
  }
  
  func saveToUserDefaults()
  {
    if !UTIs.isEmpty {
      NSUserDefaults.standardUserDefaults().setValue(UTIs[0],
				forKey: Private.UserDefaultsKey)
    }
  }
}