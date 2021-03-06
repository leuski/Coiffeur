//
//  UncrustifyController.swift
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

import Foundation

class UncrustifyController: CoiffeurController {

  private struct Private {
    static var VersionArgument = "--version"
    static var ShowDocumentationArgument = "--update-config-with-doc"
    static var ShowDefaultConfigArgument = "--update-config"
    static var QuietFlag = "-q"
    static var ConfigPathFlag = "-c"
    static var LanguageFlag = "-l"
    static var FragmentFlag = "--frag"
    static var PageGuideKey = "code_width"
    static var Comment = "#"
    static var NumberOptionType = "number"
    static var DocumentType = "Uncrustify Style File"
    static var ExecutableName = "uncrustify"
    static var ExecutableURLUDKey = "UncrustifyExecutableURL"
    static var ExecutableTitleUDKey = "Uncrustify Executable"

    static var Options: String?
  }

  override var pageGuideColumn: Int {
    if let value = self.optionWithKey(Private.PageGuideKey)?.stringValue,
      let int = Int(value)
    {
      return int
    }

    return super.pageGuideColumn
  }

  var versionString: String?

  override class var localizedExecutableTitle: String {
    return NSLocalizedString(Private.ExecutableTitleUDKey, comment: "") }
  override class var documentType: String {
    return Private.DocumentType }
  override class var currentExecutableName: String {
    return Private.ExecutableName }
  override class var currentExecutableURLUDKey: String {
    return Private.ExecutableURLUDKey }

  override class var currentExecutableURL: URL? {
    didSet {
      Private.Options = nil
    }
  }

  override class func contentsIsValidInString(_ string: String) -> Bool
  {
    let keyValue = NSRegularExpression.aml_re_WithPattern(
      "^\\s*[a-zA-Z_]+\\s*=\\s*[^#\\s]")
    return nil != keyValue.firstMatchInString(string)
  }

  private static func _options(_ controller: CoiffeurController) throws
    -> String
  {
    if let options = Private.Options { return options }

    let options: String = try Process(
      controller.executableURL, arguments: [Private.ShowDocumentationArgument])
      .run()

    Private.Options = options

    if let uncrustifyController = controller as? UncrustifyController {
      uncrustifyController.versionString = try Process(
        controller.executableURL, arguments: [Private.VersionArgument]).run()
    }

    return options
  }

  override class func createCoiffeur() throws -> CoiffeurController
  {
    let controller = try super.createCoiffeur()
    try controller.readOptionsFromString(try _options(controller))
    return controller
  }

  override func readOptionsFromLineArray(_ lines: [String]) throws
  {
    var count = 0
    var currentSection: ConfigSection?
    var currentComment: String = ""

    for  aline in lines {
      count += 1

      if count == 1 {
        continue
      }

      var line = aline.trim()

      if line.isEmpty {

        currentComment = currentComment.trim()
        if !currentComment.isEmpty {
          if nil != currentComment.rangeOfCharacter(
            from: CharacterSet.newlines) {
          } else {
            currentSection = ConfigSection.objectInContext(
              self.managedObjectContext, parent: self.root, title: currentComment)
          }
          currentComment = ""
        }

      } else if line.hasPrefix(Private.Comment) {

        line = line.stringByTrimmingPrefix(Private.Comment)
        currentComment += "\(line)\n"

      } else if let range = line.range(of: Private.Comment) {

        let keyValue = String(line[line.startIndex..<range.lowerBound])
        var type = String(line[range.upperBound...])

        if let (key, value) = _keyValuePairFromString(keyValue) {

          type = type.trim().replacingOccurrences(of: "/",
                                                  with: ConfigNode.typeSeparator)
          currentComment = currentComment.trim()
          let option = ConfigOption.objectInContext(
            self.managedObjectContext, parent: currentSection,
            title: currentComment.components(separatedBy: CharacterSet.newlines)[0])
          option.indexKey = key
          option.stringValue = value
          option.documentation = currentComment
          if type == "number" {
            option.type = OptionType.signed.rawValue
          } else {
            option.type = type
          }

        }
        currentComment = ""
      }

    }
  }

  private func _keyValuePairFromString(_ string: String)
    -> (key: String, value: String)?
  {
    var line = string

    if let range = line.range(of: Private.Comment) {
      line = String(line[line.startIndex..<range.lowerBound])
    }

    if let range = line.range(of: "=") {
      line = line.replacingCharacters(in: range, with: " ")
    }

    while let range = line.range(of: ",") {
      line = line.replacingCharacters(in: range, with: " ")
    }

    let tokens = line.commandLineComponents

    if tokens.count == 0 {
      return nil
    }

    if tokens.count == 1 {
      NSLog("Warning: wrong number of arguments %@", line)
      return nil
    }

    let head = tokens[0]
    switch head {
    case "type", "define", "macro-open", "macro-close",
         "macro-else", "set", "include", "file_ext":
      break
    default:
      return (key:head, value:tokens[1])
    }
    return nil
  }

  override func readValuesFromLineArray(_ lines: [String]) throws
  {
    for aline in lines {
      let line = aline.trim()

      if line.isEmpty {
        continue
      }

      if line.hasPrefix(Private.Comment) {
        continue
      }

      if let (key, value) = _keyValuePairFromString(line) {
        if let option = self.optionWithKey(key) {
          option.stringValue = value
        } else {
          NSLog("Warning: unknown token %@ on line %@", key, line)
        }
      }

    }
  }

  override func writeValuesToURL(_ absoluteURL: URL) throws
  {
    var data=""

    if let version = self.versionString {
      data += "\(Private.Comment) \(version)\n"
    }

    let allOptions = try self.managedObjectContext.fetch(ConfigOption.self,
                                                         sortDescriptors: [CoiffeurController.keySortDescriptor])

    for option in allOptions {
      if var value = option.stringValue {
        value = value.stringByQuoting()
        data += "\(option.indexKey) = \(value)\n"
      }
    }

    try data.write(to: absoluteURL, atomically: true,
                   encoding: String.Encoding.utf8)
  }

  override func format(_ arguments: Arguments,
                       completionHandler: @escaping (_:StringResult) -> Void) -> Bool
  {
    let workingDirectory = NSTemporaryDirectory()
    let configURL = URL(fileURLWithPath: workingDirectory).appendingPathComponent(
      UUID().uuidString)

    do {
      try self.writeValuesToURL(configURL)
    } catch let error {
      completionHandler(StringResult(error))
      return false
    }

    var args = [Private.QuietFlag, Private.ConfigPathFlag, configURL.path]

    args.append(Private.LanguageFlag)
    args.append(arguments.language.uncrustifyID)

    if arguments.fragment {
      args.append(Private.FragmentFlag)
    }

    Process(
      self.executableURL, arguments: args, workingDirectory: workingDirectory)
      .runAsync(arguments.text)
    {
      (result: StringResult) -> Void in
      try? FileManager.default.removeItem(at: configURL)
      completionHandler(result)
    }

    return true
  }

}
