//
//  UncrustifyController.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

class UncrustifyController : CoiffeurController {
  
  private struct Private {
    static var ShowDocumentationArgument = "--show-config"
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

    static var OptionsDocumentation : String? = nil
    static var DefaultValues : String? = nil
  }
  
	override class var localizedExecutableTitle : String { return NSLocalizedString(Private.ExecutableTitleUDKey, comment:"") }
  override class var documentType : String { return Private.DocumentType }
	override class var currentExecutableName : String { return Private.ExecutableName }
	override class var currentExecutableURLUDKey : String { return Private.ExecutableURLUDKey }
	
  override class func createCoiffeur() -> CoiffeurControllerResult
  {
    let result = super.createCoiffeur()
    
    switch result {
    case .Failure:
      return result
      
    case .Success(let controller):
      if Private.OptionsDocumentation == nil {
        switch controller.runExecutable([Private.ShowDocumentationArgument]) {
        case .Failure(let error):
          return CoiffeurControllerResult.Failure(error)
        case .Success(let text):
          Private.OptionsDocumentation = text
        }
      }
      
      if let error = controller.readOptionsFromString(Private.OptionsDocumentation!) {
        return CoiffeurControllerResult.Failure(error)
      }
      
      if Private.DefaultValues == nil {
        switch controller.runExecutable([Private.ShowDefaultConfigArgument]) {
        case .Failure(let error):
          return CoiffeurControllerResult.Failure(error)
        case .Success(let text):
          Private.DefaultValues = text
        }
      }
      
      if let error = controller.readValuesFromString(Private.DefaultValues!) {
        return CoiffeurControllerResult.Failure(error)
      }
      
      return result
    }
  }
  
  private enum State {
    case None
    case ConfigSectionHeader
    case OptionDescription
  }
  
  private func _parseSection(inout section:ConfigSection, line aline:String)
  {
    var  line = aline.stringByTrimmingPrefix(Private.Comment)
    
    if !line.isEmpty {
      section.title = section.title.stringByAppendingString(line, separatedBy:" ")
    }
  }
  
  private func _parseOption(inout option:ConfigOption, firstLine line:String)
  {
    var c = 0
    var tokens = line.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    tokens = tokens.filter { !$0.isEmpty }

    for v in tokens {
      if (++c == 1) {
        option.indexKey = v
      } else if v != "{" && v != "}" {
        option.type = option.type.stringByAppendingString(v.lowercaseString)
      }
    }
    
    if (option.type == Private.NumberOptionType) {
      option.type = OptionType.Signed.rawValue
    }
  }
  
  override func readOptionsFromLineArray(lines:[String]) -> NSError?
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
        
        if line.hasPrefix(Private.Comment) {
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
          if line.hasPrefix(Private.Comment) {
            self._parseSection(&section, line:line)
          }
        }
        
        break
        
      case .OptionDescription:
        
        if var option = currentOption {
          if line.hasPrefix(Private.Comment) {
            line = line.stringByTrimmingPrefix(Private.Comment)
          }
          
          if option.title.isEmpty {
            option.title = line
          }
          
          option.documentation = option.documentation.stringByAppendingString(line,
            separatedBy:CoiffeurController.NewLine)
        }
        break
      }
    }
    
    for var i = 8; i >= 5; --i {
      self._cluster(i)
    }
    
    return nil
  }
  
  private func _cluster(tokenLimit:Int)
  {
    for child in self.root!.children  {
      if !(child is ConfigSection) {
        continue
      }
      var section = child as! ConfigSection
      
      var index = [String:[ConfigOption]]()
      
      for node in section.children {
        if !(node is ConfigOption) {
          continue
        }
        let option : ConfigOption = node as! ConfigOption
        
        let title  = option.title
        var tokens = title.lowercaseString.componentsSeparatedByString(CoiffeurController.Space)
        tokens = tokens.filter { !$0.isEmpty && $0 != "a" && $0 != "the" }
        
        if tokens.count < (tokenLimit + 1) {
          continue
        }
        
        let key = tokens[0..<tokenLimit].reduce("") { $0.isEmpty ? $1 : "\($0) \($1)" }
        
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
          var  tokens = title.componentsSeparatedByString(CoiffeurController.Space)
          tokens = tokens.filter { !$0.isEmpty && $0 != "a" && $0 != "the" }
          option.title  = tokens[tokenLimit..<tokens.count].reduce("") { $0.isEmpty ? $1 : "\($0) \($1)" }
          option.parent = subsection
        }
      }
    }
  }
  
  override func readValuesFromLineArray(lines:[String]) -> NSError?
  {
    for aline in lines {
      var line = aline.trim()
      
      if line.isEmpty {
        continue
      }
      
      if line.hasPrefix(Private.Comment) {
        continue
      }
      
      if let range = line.rangeOfString(Private.Comment) {
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
          option.stringValue = tokens[1]
        } else {
          NSLog("Warning: unknown token %@ on line %@", head, line)
        }
      }
      
    }
    
    return nil
  }
  
  override func writeValuesToURL(absoluteURL:NSURL) -> NSError?
  {
    var data=""
		switch self.managedObjectContext.fetch(ConfigOption.self, sortDescriptors:[CoiffeurController.KeySortDescriptor]) {
		case .Success(var allOptions):
			for option in allOptions {
				if var value = option.stringValue {
					
					if option.type == OptionType.String.rawValue {
						value = "\"\(value)\""
					}
					
					data += "\(option.indexKey) = \(value)" + CoiffeurController.NewLine
					
				}
			}
			
		case .Failure(let error):
			return error
		}
		
    var error:NSError?
    if data.writeToURL(absoluteURL, atomically:true, encoding:NSUTF8StringEncoding, error:&error) {
      return nil
    }
    return error ?? super.writeValuesToURL(absoluteURL)
  }
  
  override func format(text: String, attributes: NSDictionary, completion: (_:StringResult) -> Void) -> Bool
  {
    let workingDirectory = NSTemporaryDirectory()
    let configPath = workingDirectory.stringByAppendingPathComponent(NSUUID().UUIDString)
    
    if let error = self.writeValuesToURL(NSURL(fileURLWithPath:configPath)!) {
      completion(StringResult.Failure(error))
      return false
    }
    
    var args = [Private.QuietFlag, Private.ConfigPathFlag, configPath]
    
    if let language = attributes[CoiffeurController.FormatLanguage] as? Language {
      
      args.append(Private.LanguageFlag)
      args.append(language.uncrustifyID)
    }
    
    if let fragmentFlag  = attributes[CoiffeurController.FormatFragment] as? NSNumber {
      if fragmentFlag.boolValue {
        args.append(Private.FragmentFlag)
      }
    }
    
    let complete = { (result:StringResult) -> Void  in
      NSFileManager.defaultManager().removeItemAtPath(configPath, error:nil)
      completion(result)
    }
    
    if let error = self.runExecutable(args, workingDirectory:workingDirectory, input:text, block:complete) {
      completion(StringResult.Failure(error))
      return false
    }
    
    return true
  }
  
  override class func contentsIsValidInString(string:String) -> Bool
  {
    let keyValue = NSRegularExpression.aml_regularExpressionWithPattern("^\\s*[a-zA-Z_]+\\s*=\\s*[^#\\s]")
    
    return nil != keyValue.firstMatchInString(string)
  }
  
  override var pageGuideColumn : Int
    {
      if let value = self.optionWithKey(Private.PageGuideKey)?.stringValue, let int = value.toInt() {
        return int
      }
      
      return super.pageGuideColumn
  }
  
  
}