//
//  Language.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

class Language : NSObject {
    
  private class var FileName : String { return "languages" }
  private class var FileNameExtension : String { return "plist" }
  private class var UserDefaultsKey : String { return "Language" }

  private struct LanguagePrivate {
    static var supportedLanguages: [Language] = Language._supportedLanguages()
  }

  class var supportedLanguages : [Language] { return LanguagePrivate.supportedLanguages }

  private(set) var uncrustifyID = ""
  private(set) var displayName = ""
  private(set) var fragariaID = ""
  private(set) var clangFormatID : String?
  private(set) var UTIs : [ String ] = []
  var defaultExtension : String? {
    return UTIs.isEmpty ? nil : NSWorkspace.sharedWorkspace().preferredFilenameExtensionForType(UTIs[0])
  }
  
  private class func _supportedLanguages() -> [Language]
  {
    let bundle = NSBundle(forClass: self)
    if let url = bundle.URLForResource(FileName, withExtension: FileNameExtension) {
      if let dictionaries = NSArray(contentsOfURL: url) {
        var result = [Language]()
        for d in dictionaries {
          result.append(Language(dictionary:d as! [NSObject : AnyObject]))
        }
        return result
      }
    }
    return []
  }

  class func languageWithUTI(uti:String) -> Language?
  {
    for l in self.supportedLanguages {
      if let index = find(l.UTIs, uti) {
        return l
      }
    }
    return nil
  }
  
  class func languageFromUserDefaults() -> Language
  {
    if let uti = NSUserDefaults.standardUserDefaults().stringForKey(UserDefaultsKey) {
      if let language = Language.languageWithUTI(uti) {
        return language
      }
    }
    return Language.languageWithUTI(kUTTypeObjectiveCPlusPlusSource as String)!
  }
  
  private init(dictionary:[NSObject : AnyObject])
  {
    super.init()
    setValuesForKeysWithDictionary(dictionary)
  }
  
  func saveToUserDefaults()
  {
    if !UTIs.isEmpty {
      NSUserDefaults.standardUserDefaults().setValue(UTIs[0], forKey: Language.UserDefaultsKey)
    }
  }
}