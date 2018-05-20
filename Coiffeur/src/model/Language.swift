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

class Language: NSObject {

  private static let FileName = "languages"
  private static let FileNameExtension = "plist"
  private static let UserDefaultsKey = "Language"

  static var supportedLanguages: [Language] = {
    let bundle = Bundle(for: Language.self)
    if let url = bundle.url(forResource: Language.FileName,
                            withExtension: Language.FileNameExtension)
    {
      if let dictionaries = NSArray(contentsOf: url) {
        var result = [Language]()
        for case let dictionary as [String: AnyObject] in dictionaries {
          result.append(Language(dictionary: dictionary))
        }
        return result
      }
    }
    return []
  }()

  class var supportedLanguageUTIs: [String] {
    var types = Set<String>()
    for  language in Language.supportedLanguages {
      types.formUnion(language.UTIs)
    }
    return [String](types)
  }

  @objc private(set) var uncrustifyID = ""
  @objc private(set) var displayName = ""
  @objc private(set) var fragariaID = ""
  @objc private(set) var UTIs = [String]()
  @objc private(set) var clangFormatID: String?

  var defaultExtension: String? {
    return UTIs.isEmpty
      ? nil
      : NSWorkspace.shared.preferredFilenameExtension(forType: UTIs[0])
  }

  class func languageWithUTI(_ uti: String) -> Language? {
    return supportedLanguages.first { $0.UTIs.contains(uti) }
  }

  class func languageFromUserDefaults() -> Language
  {
    if
      let uti = UserDefaults.standard.string(forKey: Language.UserDefaultsKey),
      let language = languageWithUTI(uti)
    {
      return language
    }
    return languageWithUTI(kUTTypeObjectiveCPlusPlusSource as String) ??
      { fatalError("Missing language description for C++") }()
  }

  private init(dictionary: [String: AnyObject])
  {
    super.init()
    setValuesForKeys(dictionary)
  }

  func saveToUserDefaults()
  {
    if !UTIs.isEmpty {
      UserDefaults.standard.setValue(UTIs[0], forKey: Language.UserDefaultsKey)
    }
  }
}
