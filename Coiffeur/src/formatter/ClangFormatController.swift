//
//  ClangFormatController.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

class ClangFormatController : CoiffeurController {
  
  private struct Private {
    static var DocumentationFileName = "ClangFormatStyleOptions"
    static var DocumentationFileExtension = "rst"
    static var ShowDefaultConfigArgument = "-dump-config"
    static var StyleFlag = "-style=file"
    static var SourceFileNameFormat = "-assume-filename=sample.%@"
    static var StyleFileName = ".clang-format"
    static var PageGuideKey = "ColumnLimit"
    static var SectionBegin = "---"
    static var SectionEnd = "..."
    static var Comment = "#"
    static var DocumentType = "Clang-Format Style File"
    static var ExecutableName = "clang-format"
    
    static var OptionsDocumentation : String? = nil
    static var DefaultValues : String? = nil
  }
  
  override class var documentType : String { return Private.DocumentType }
  
  override init?(_ executableURL:NSURL?, error:NSErrorPointer)
  {
    super.init(executableURL, error: error)
    
    if Private.OptionsDocumentation == nil {
      let bundle = NSBundle(forClass: self.dynamicType)
      let docURL = bundle.URLForResource(Private.DocumentationFileName, withExtension: Private.DocumentationFileExtension)
      
      if docURL == nil {
        if error != nil {
          error.memory = Error(String(format: NSLocalizedString("Cannot find %@.%@", comment: ""), Private.DocumentationFileName, Private.DocumentationFileExtension))
        }
        return nil
      }
      
      Private.OptionsDocumentation = String(contentsOfURL: docURL!, encoding: NSUTF8StringEncoding, error: error)
      
      if Private.OptionsDocumentation == nil {
        return nil
      }
      
    }
    
    if !self.readOptionsFromString(Private.OptionsDocumentation!) {
      return nil
    }
    
    if Private.DefaultValues == nil {
      let result = self.runExecutable([Private.ShowDefaultConfigArgument])
      switch (result) {
      case .Failure(let err):
        if error != nil {
          error.memory = err
        }
        return nil
      case .Success(let text):
        Private.DefaultValues = text()
      }
    }
    
    if !self.readValuesFromString(Private.DefaultValues!) {
      return nil
    }
  }
  
  convenience required init?(error:NSErrorPointer)
  {
    let bundle = NSBundle(forClass: ClangFormatController.self)
    self.init(bundle.URLForAuxiliaryExecutable(Private.ExecutableName), error:error)
  }
  
  private class func _cleanUpRST(string:String) -> String
  {
    var rst = string
    rst = rst.trim()
    rst += "\n"
    
    var mutableRST = NSMutableString(string: rst)
    
    let nl  = "__NL__"
    let sp  = "__SP__"
    let par = "__PAR__"
    
    // preserve all spacing inside \code ... \endcode
    let lif = NSRegularExpression.ci_dmls_regularExpressionWithPattern("\\\\code(.*?)\\\\endcode(\\s)")
    
    while true {
      let match = lif.firstMatchInString(mutableRST)
      if match == nil {
        break
      }
      
      var code = mutableRST.substringWithRange(match!.rangeAtIndex(1))
      code = code.stringByReplacingOccurrencesOfString("\n", withString:nl)
      code = code.stringByReplacingOccurrencesOfString(" ", withString:sp)
      code += mutableRST.substringWithRange(match!.rangeAtIndex(2))
      mutableRST.replaceCharactersInRange(match!.rangeAtIndex(0), withString:code)
    }
    
    // preserve double nl, breaks before * and - (list items)
    mutableRST.replaceOccurrencesOfString("\n\n", withString:par)
    mutableRST.replaceOccurrencesOfString("\n*", withString:"\(nl)*")
    mutableRST.replaceOccurrencesOfString("\n-", withString:"\(nl)-")
    
    // un-escape escaped characters
    let esc = NSRegularExpression.ci_dmls_regularExpressionWithPattern("\\\\(.)")
    
    esc.replaceMatchesInString(mutableRST, withTemplate:"$1")
    
    // wipe out remaining whitespaces as single space
    mutableRST.replaceOccurrencesOfString("\n", withString:" ")
    
    let wsp = NSRegularExpression.ci_dmls_regularExpressionWithPattern("\\s\\s+")
    wsp.replaceMatchesInString(mutableRST, withTemplate:" ")
    
    // restore saved spacing
    mutableRST.replaceOccurrencesOfString(nl, withString:"\n")
    mutableRST.replaceOccurrencesOfString(sp, withString:" ")
    mutableRST.replaceOccurrencesOfString(par, withString:"\n\n")
    
    // quote the emphasized words
    let quot = NSRegularExpression.ci_dmls_regularExpressionWithPattern("``(.*?)``")
    quot.replaceMatchesInString(mutableRST, withTemplate:"“$1”")
    
    //      NSLog(@"%@", mutableRST);
    return mutableRST
  }
  
  private func _closeOption(inout option: ConfigOption?)
  {
    if let opt = option {
      opt.title = ClangFormatController._cleanUpRST(opt.title)
      opt.documentation = ClangFormatController._cleanUpRST(opt.documentation)
    }
  }
  
  override func readOptionsFromLineArray(lines: [String]) -> Bool
  {
    let section = ConfigSection.objectInContext(self.managedObjectContext)
    
    section.title  = "All Options";
    section.parent = self.root;
    
    var currentOption : ConfigOption?
    
    var in_doc = false
    
    let head = NSRegularExpression.ci_regularExpressionWithPattern("^\\*\\*(.*?)\\*\\* \\(``(.*?)``\\)")
    let item = NSRegularExpression.ci_regularExpressionWithPattern("^(\\s*\\* )``.*\\(in configuration: ``(.*?)``\\)")
    
    var in_title = false
    
    for aLine in lines {
      var line = aLine as NSString
      if !in_doc {
        if line.hasPrefix(".. START_FORMAT_STYLE_OPTIONS") {
          in_doc = true
        }
        continue
      }
      
      if line.hasPrefix(".. END_FORMAT_STYLE_OPTIONS") {
        in_doc = false
        continue
      }
      
      //              NSString* trimmedLine = [line trim)
      //              if (trimmedLine.length == 0)
      //                      line = trimmedLine;
      
      line = line.trim()
      
      var match : NSTextCheckingResult?
      
      if let match = head.firstMatchInString(line) {
        
        self._closeOption(&currentOption)
        
        var newOption = ConfigOption.objectInContext(self.managedObjectContext)
        newOption.parent           = section;
        newOption.indexKey         = line.substringWithRange(match.rangeAtIndex(1))
        in_title                 = true
        let type = line.substringWithRange(match.rangeAtIndex(2))
        
        if type == "bool" {
          newOption.type = "false,true"
        } else if type == "unsigned" {
          newOption.type = OptionType.Unsigned.rawValue
        } else if type == "int" {
          newOption.type = OptionType.Signed.rawValue
        } else if type == "std::string" {
          newOption.type = OptionType.String.rawValue
        } else if type == "std::vector<std::string>" {
          newOption.type = OptionType.String.rawValue
        } else {
          newOption.type = ""
        }
        
        currentOption = newOption
        
        continue
      }
      
      if line.length == 0 {
        in_title = false
      }
      
      if let option = currentOption {
      
        if let match = item.firstMatchInString(line) {
          let token = line.substringWithRange(match.rangeAtIndex(2))
        
          if !token.isEmpty {
            option.type = option.type.stringByAppendingString(token, separatedBy: ConfigNode.TypeSeparator)
          }
        
          let prefix = line.substringWithRange(match.rangeAtIndex(1))
          option.documentation = option.documentation.stringByAppendingString("\(prefix)``\(token)``\n")
          continue
        }
      
        if in_title {
          option.title = option.title.stringByAppendingString(line, separatedBy:" ")
        }
      
        option.documentation = line + CoiffeurController.NewLine
      }
    }
    
    self._closeOption(&currentOption)
    
    return true
  }
  
  override func readValuesFromLineArray(lines:[String]) -> Bool
  {
    let keyValue = NSRegularExpression.ci_regularExpressionWithPattern("^\\s*(.*?):\\s*(\\S.*)")
    
    for aLine in lines {
      var line = aLine as NSString
      line = line.trim()
      
      if line.hasPrefix(Private.Comment) {
        continue
      }
      
      if let match = keyValue.firstMatchInString(line) {
        let key = line.substringWithRange(match.rangeAtIndex(1))
        let value = line.substringWithRange(match.rangeAtIndex(2))
        if let option = self.optionWithKey(key) {
          option.value = value
        } else {
          NSLog("Warning: unknown token %@ on line %@", key, line);
        }
      }
    }
    
    return true
  }
  
  override func writeValuesToURL(absoluteURL:NSURL, error:NSErrorPointer) -> Bool
  {
    var data = ""
    
    data += Private.SectionBegin + CoiffeurController.NewLine
    
    var allOptions = self.managedObjectContext.fetch(ConfigOption.self)
    allOptions.sort(CoiffeurController.KeyComparator)
    
    for option in allOptions {
      if let value = option.value {
        data += "\(option.indexKey): \(value)" + CoiffeurController.NewLine
      }
      
    }
    
    data += Private.SectionEnd + CoiffeurController.NewLine
    
    return data.writeToURL(absoluteURL, atomically:true, encoding:NSUTF8StringEncoding, error:error)
  }
  
  override func format(text: String, attributes: NSDictionary, completion: (_:Result<String>) -> Void) -> Bool
  {
    let workingDirectory = NSTemporaryDirectory()
    let configPath = workingDirectory.stringByAppendingPathComponent(Private.StyleFileName)
    
    var localError : NSError?
    
    if !self.writeValuesToURL(NSURL(fileURLWithPath: configPath)!, error:&localError) {
      if localError == nil {
        localError = Error("Unknown Error")
      }
      completion(Result<String>.Failure(localError!))
      return false
    }
    
    var args = [Private.StyleFlag]
    
    if let language = attributes[CoiffeurController.FormatLanguage] as? ALLanguage {
      if let clangFormatID = language.clangFormatID {
        if let ext = language.defaultExtension {
          args.append(String(format:Private.SourceFileNameFormat, ext))
        }
      }
    }
    
    let complete = { (result:Result<String>) -> Void  in
      NSFileManager.defaultManager().removeItemAtPath(configPath, error:nil)
      completion(result)
    }
    
    localError = self.runExecutable(args, workingDirectory:workingDirectory, input:text, block:complete)
    
    if let err = localError {
      completion(Result<String>.Failure(err))
      return false
    }
    
    return true
  }
  
  override class func contentsIsValidInString(string:String) -> Bool
  {
    let keyValue = NSRegularExpression.aml_regularExpressionWithPattern("^\\s*[a-zA-Z_]+\\s*:\\s*[^#\\s]")
    let section = NSRegularExpression.aml_regularExpressionWithPattern("^\(Private.SectionBegin)")
    return nil != section.firstMatchInString(string)
      && nil != keyValue.firstMatchInString(string)
  }
  
  override var pageGuideColumn : Int
  {
    if let value = self.optionWithKey(Private.PageGuideKey)?.value {
      return value.unsignedIntegerValue
    }
    
    return super.pageGuideColumn
  }
}