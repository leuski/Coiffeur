//
//  UncrustifyController.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

class ALUncrustifyController : ALCoiffeurController {
  
  private class var ShowDocumentationArgument : String { return "--show-config" }
  private class var ShowDefaultConfigArgument : String { return "--update-config" }
  private class var QuietFlag : String { return "-q" }
  private class var ConfigPathFlag : String { return "-c" }
  private class var LanguageFlag : String { return "-l" }
  private class var FragmentFlag : String { return "--frag" }
  private class var PageGuideKey : String { return "code_width" }
  private class var Comment : String { return "#" }
  private class var NumberOptionType : String { return "number" }
  private class var DocumentType : String { return "Uncrustify Style File" }
  private class var ExecutableName : String { return "uncrustify" }
  
  private struct Private {
    static var OptionsDocumentation : String? = nil
    static var DefaultValues : String? = nil
  }
  
  override class var documentType : String { return ALUncrustifyController.DocumentType }
  
  override init?(_ executableURL:NSURL?, error:NSErrorPointer)
  {
    super.init(executableURL, error: error)
    
    if error != nil {
      error.memory = nil
    }
    
    
    if Private.OptionsDocumentation == nil {
      let (text, err) = self.runExecutable([ALUncrustifyController.ShowDocumentationArgument], workingDirectory:nil, input:nil)
      if err != nil {
        if error != nil {
          error.memory = err
        }
        return nil
      }
      Private.OptionsDocumentation = text
    }
    
    if !self.readOptionsFromString(Private.OptionsDocumentation!) {
      return nil
    }
    
    if Private.DefaultValues == nil {
      let (text, err) = self.runExecutable([
        ALUncrustifyController.ShowDefaultConfigArgument], workingDirectory: nil, input: nil)
      if err != nil {
        if error != nil {
          error.memory = err
        }
        return nil
      }
      Private.DefaultValues = text
    }
    
    if !self.readValuesFromString(Private.DefaultValues!) {
      return nil
    }
    
  }
  
  convenience required init?(error:NSErrorPointer)
  {
    let bundle = NSBundle(forClass: ALUncrustifyController.self)
    self.init(bundle.URLForAuxiliaryExecutable(ALUncrustifyController.ExecutableName), error:error)
  }
  
  private enum State {
    case None
    case ConfigSectionHeader
    case OptionDescription
  }
  
  private func _parseSection(inout section:ConfigSection, line aline:String)
  {
    var  line = aline.stringByTrimmingPrefix(ALUncrustifyController.Comment)
    
    if !line.isEmpty {
      section.title = section.title.stringByAppendingString(line, separatedBy:ALUncrustifyController.Space)
    }
  }
  
  private func _parseOption(inout option:ConfigOption, firstLine line:String)
  {
    var c = 0
    
    for v in line.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
      ++c
      
      if (c == 1) {
        option.indexKey = v
        option.name = v
      } else {
        
        if v == "{" || v == "}" {
          continue
        }
        
        
        option.type = option.type?.stringByAppendingString(v.lowercaseString)
      }
    }
    
    if (option.type == ALUncrustifyController.NumberOptionType) {
      option.type = OptionType.Signed.rawValue
    }
  }
  
  override func readOptionsFromLineArray(lines:[String]) -> Bool
  {
    var count = 0, optionCount = 0, sectionCount = 0
    var state = State.None
    var currentSection : ConfigSection?
    var currentOption : ConfigOption?
    
    for  aline in lines {
      ++count
      
      if count == 1 {
        continue
      }
      
      var line = aline.trim()
      
      if line.isEmpty {
        state = State.None
        continue
      }
      
      switch (state) {
      case .None:
        
        if line.hasPrefix(ALUncrustifyController.Comment) {
          ++sectionCount
          state = State.ConfigSectionHeader
          var section = ConfigSection.objectInContext(self.managedObjectContext)
          section.parent = self.root
          self._parseSection(&section, line:line)
          currentSection = section
        } else {
          ++optionCount
          state = State.OptionDescription
          var option = ConfigOption.objectInContext(self.managedObjectContext)
          option.parent = currentSection
          self._parseOption(&option, firstLine:line)
          currentOption = option
        }
        
        break
        
      case .ConfigSectionHeader:
        
        if var section = currentSection {
          if line.hasPrefix(ALUncrustifyController.Comment) {
            self._parseSection(&section, line:line)
          }
        }
        
        break
        
      case .OptionDescription:
        
        if var option = currentOption {
          if line.hasPrefix(ALUncrustifyController.Comment) {
            line = line.stringByTrimmingPrefix(ALUncrustifyController.Comment)
          }
          
          if option.title.isEmpty {
            option.title = line
          }
          
          option.documentation = option.documentation?.stringByAppendingString(line,
            separatedBy:ALUncrustifyController.NewLine)
        }
        break
      }
    }
    
    for var i = 8; i >= 5; --i {
      self._cluster(i)
    }
    
    return true
  }
  
  private func _cluster(tokenLimit:Int)
  {
    for child in self.root!.children  {
      if !(child is ConfigSection) {
        continue
      }
      var section = child as ConfigSection
      
      var index = [String:[ConfigOption]]()
      
      for node in section.children {
        if !(node is ConfigOption) {
          continue
        }
        let option : ConfigOption = node as ConfigOption
        
        let title  = option.title
        var tokens = title.lowercaseString.componentsSeparatedByString(ALUncrustifyController.Space)
        tokens = tokens.filter { $0 != "a" && $0 != "the" }
        
        if tokens.count < (tokenLimit + 1) {
          continue
        }
        
        let key = tokens[0..<tokenLimit].reduce("") { $0.isEmpty ? $1 : ($0 + ALUncrustifyController.Space + $1) }
        
        if index[key] == nil {
          index[key] = [ConfigOption]()
        }
        
        index[key]!.append(option)
      }
      
      //          NSUInteger limit = section.children.count
      for (key, list) in index {
        
        if list.count < 5 {
          continue
        }
        
        //                      if (list.count < 0.15 * limit) continue
        //                      if (list.count < 0.15 * limit) continue
        
        var subsection = ConfigSubsection.objectInContext(self.managedObjectContext)
        subsection.title  = key + "…"
        subsection.parent = section
        
        for option in list {
          let title  = option.title
          var  tokens = title.componentsSeparatedByString(ALUncrustifyController.Space)
          tokens = tokens.filter { $0 != "a" && $0 != "the" }
          option.title  = tokens[tokenLimit..<tokens.count].reduce("") { $0.isEmpty ? $1 : ($0 + ALUncrustifyController.Space + $1) }
          option.parent = subsection
        }
      }
    }
  }
  
  override func readValuesFromLineArray(lines:[String]) -> Bool
  {
    for aline in lines {
      var line = aline.trim()
      
      if line.isEmpty {
        continue
      }
      
      if line.hasPrefix(ALUncrustifyController.Comment) {
        continue
      }
      
      if let range = line.rangeOfString(ALUncrustifyController.Comment) {
        line = line.substringFromIndex(range.startIndex)
      }
      
      if let range = line.rangeOfString("=") {
        let prefix = line.substringToIndex(range.startIndex)
        let suffix = line.substringFromIndex(range.startIndex.successor())
        line = "\(prefix) \(suffix)"
      }
      
      let tokens = line.commandLineComponents
      
      if tokens.count == 0 {
        continue
      }
      
      if tokens.count == 1 {
        NSLog("Warning: wrong number of arguments %@", line)
        continue
      }
      
      let head = tokens[0]
      
      if head == "type" {
      } else if head == "define" {
      } else if head == "macro-open" {
      } else if head == "macro-close" {
      } else if head == "macro-else" {
      } else if head == "set" {
      } else if head == "include" {
      } else if head == "file_ext" {
      } else {
        
        if let option = self.optionWithKey(head) {
          option.value = tokens[1]
        } else {
          NSLog("Warning: unknown token %@ on line %@", head, line)
        }
      }
      
    }
    
    return true
  }
  
  override func writeValuesToURL(absoluteURL:NSURL, error:NSErrorPointer) -> Bool
  {
    var data=""
    var allOptions = self.managedObjectContext.fetch(ConfigOption.self)
    allOptions.sort(ALClangFormatController.KeyComparator)
    
    for option in allOptions {
      if var value = option.value {
        
        if option.type == OptionType.String.rawValue {
          value = "\"\(value)\""
        }
        
        data += "\(option.indexKey) = \(value)" + ALClangFormatController.NewLine
        
      }
    }
    
    return data.writeToURL(absoluteURL, atomically:true, encoding:NSUTF8StringEncoding, error:error)
  }
  
  override func format(text: String, attributes: NSDictionary, completion: (output: String?, error: NSError?) -> Void) -> Bool
  {
    let workingDirectory = NSTemporaryDirectory()
    let configPath = workingDirectory.stringByAppendingPathComponent(NSUUID().UUIDString)
    
    var localError : NSError?
    
    if !self.writeValuesToURL(NSURL(fileURLWithPath:configPath)!, error:&localError) {
      completion(output: nil, error: localError)
      return false
    }
    
    var args = [ALUncrustifyController.QuietFlag, ALUncrustifyController.ConfigPathFlag, configPath]
    
    if let language = attributes[ALUncrustifyController.FormatLanguage] as? ALLanguage {
      
      args.append(ALUncrustifyController.LanguageFlag)
      args.append(language.uncrustifyID)
    }
    
    if let fragmentFlag  = attributes[ALUncrustifyController.FormatFragment] as? NSNumber {
      if fragmentFlag.boolValue {
        args.append(ALUncrustifyController.FragmentFlag)
      }
    }
    
    let complete = { (text:String?, error:NSError?) -> Void  in
      NSFileManager.defaultManager().removeItemAtPath(configPath, error:nil)
      completion(output: text, error: error)
    }
    
    localError = self.runExecutable(args, workingDirectory:workingDirectory, input:text, block:complete)
    
    if localError == nil {
      return true
    }
    
    completion(output: nil, error: localError)
    return false
  }
  
  override class func contentsIsValidInString(string:String, error:NSErrorPointer) -> Bool
  {
    let keyValue = NSRegularExpression.aml_regularExpressionWithPattern("^\\s*[a-zA-Z_]+\\s*=\\s*[^#\\s]")
    
    return nil != keyValue.firstMatchInString(string)
  }
  
  override var pageGuideColumn : Int
    {
      if let value = self.optionWithKey(ALUncrustifyController.PageGuideKey)?.value {
        return value.unsignedIntegerValue
      }
      
      return super.pageGuideColumn
  }
  
  
}