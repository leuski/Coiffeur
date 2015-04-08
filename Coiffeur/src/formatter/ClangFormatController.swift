//
//  ClangFormatController.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

class Error : NSError {
  class var Domain : String { return "CoiffeurErrorDomain" }
  
  init(_ localizedDescription:String)
  {
    super.init(domain: Error.Domain, code: 0, userInfo: [NSLocalizedDescriptionKey:localizedDescription])
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder:aDecoder)
  }
}

class ALClangFormatController : ALCoiffeurController {
  
  private class var DocumentationFileName : String { return "ClangFormatStyleOptions" }
  private class var DocumentationFileExtension : String { return "rst" }
  private class var ShowDefaultConfigArgument : String { return "-dump-config" }
  private class var StyleFlag : String { return "-style=file" }
  private class var SourceFileNameFormat : String { return "-assume-filename=sample.%@" }
  private class var StyleFileName : String { return ".clang-format" }
  private class var PageGuideKey : String { return "ColumnLimit" }
  private class var SectionBegin : String { return "---" }
  private class var SectionEnd : String { return "..." }
  private class var Comment : String { return "#" }
  private class var DocumentType : String { return "Clang-Format Style File" }
  private class var ExecutableName : String { return "clang-format" }
  
  private struct ALClangFormatControllerPrivate {
    static var OptionsDocumentation : String? = nil
    static var DefaultValues : String? = nil
  }
  
  override class var documentType : String { return ALClangFormatController.DocumentType }
  
  override init?(_ executableURL:NSURL?, error:NSErrorPointer)
  {
    super.init(executableURL, error: error)
    
    if ALClangFormatControllerPrivate.OptionsDocumentation == nil {
      let bundle = NSBundle(forClass: self.dynamicType)
      let docURL = bundle.URLForResource(ALClangFormatController.DocumentationFileName, withExtension: ALClangFormatController.DocumentationFileExtension)
      
      if docURL == nil {
        if error != nil {
          error.memory = Error(String(format: NSLocalizedString("Cannot find %@.%@", comment: ""), ALClangFormatController.DocumentationFileName, ALClangFormatController.DocumentationFileExtension))
        }
        return nil
      }
      
      ALClangFormatControllerPrivate.OptionsDocumentation = String(contentsOfURL: docURL!, encoding: NSUTF8StringEncoding, error: error)
      
      if ALClangFormatControllerPrivate.OptionsDocumentation == nil {
        return nil
      }
      
    }
    
    if !self.readOptionsFromString(ALClangFormatControllerPrivate.OptionsDocumentation!) {
      return nil
    }
    
    if ALClangFormatControllerPrivate.DefaultValues == nil {
      let (output, err) = self.runExecutable([ALClangFormatController.ShowDefaultConfigArgument], workingDirectory: nil, input: nil)
      if output == nil {
        if error != nil {
          error.memory = err
        }
        return nil
      }
      ALClangFormatControllerPrivate.DefaultValues = output
    }
    
    if !self.readValuesFromString(ALClangFormatControllerPrivate.DefaultValues!) {
      return nil
    }
  }
  
  convenience required init?(error:NSErrorPointer)
  {
    let bundle = NSBundle(forClass: ALClangFormatController.self)
    self.init(bundle.URLForAuxiliaryExecutable(ALClangFormatController.ExecutableName), error:error)
  }
  
  private class func _cleanUpRST(string:String?) -> String?
  {
    if string == nil {
      return nil
    }
    
    var rst = string!
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
    mutableRST.replaceOccurrencesOfString("\n*", withString:NSString(format:"%@*", nl))
    mutableRST.replaceOccurrencesOfString("\n-", withString:NSString(format:"%@-", nl))
    
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
      opt.title = ALClangFormatController._cleanUpRST(opt.title)!
      opt.documentation = ALClangFormatController._cleanUpRST(opt.documentation)
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
        newOption.name             = line.substringWithRange(match.rangeAtIndex(1))
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
            option.type = option.type?.stringByAppendingString(token, separatedBy: ConfigNode.TypeSeparator)
          }
        
          let prefix = line.substringWithRange(match.rangeAtIndex(1))
          option.documentation = option.documentation?.stringByAppendingFormat("%@``%@``", prefix, token)
          option.documentation = option.documentation?.stringByAppendingString(ALCoiffeurController.NewLine)
          continue
        }
      
        if in_title {
          option.title = option.title.stringByAppendingString(line, separatedBy:ALCoiffeurController.Space)
        }
      
        option.documentation = option.documentation?.stringByAppendingString(line)
        option.documentation = option.documentation?.stringByAppendingString(ALCoiffeurController.NewLine)
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
      
      if line.hasPrefix(ALClangFormatController.Comment) {
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
    
    data += ALClangFormatController.SectionBegin + ALClangFormatController.NewLine
    
    var allOptions = self.managedObjectContext.fetch(ConfigOption.self)
    allOptions.sort(ALClangFormatController.KeyComparator)
    
    for option in allOptions {
      if let value = option.value {
        data += "\(option.indexKey): \(value)" + ALClangFormatController.NewLine
      }
      
    }
    
    data += ALClangFormatController.SectionEnd + ALClangFormatController.NewLine
    
    return data.writeToURL(absoluteURL, atomically:true, encoding:NSUTF8StringEncoding, error:error)
  }
  
  override func format(text: String, attributes: NSDictionary, completion: (output: String?, error: NSError?) -> Void) -> Bool
  {
    
    let workingDirectory = NSTemporaryDirectory()
    let configPath = workingDirectory.stringByAppendingPathComponent(ALClangFormatController.StyleFileName)
    
    var localError : NSError?
    
    if !self.writeValuesToURL(NSURL(fileURLWithPath: configPath)!, error:&localError) {
      completion(output: nil, error: localError)
      return false
    }
    
    var args = [ALClangFormatController.StyleFlag]
    
    if let language = attributes[ALClangFormatController.FormatLanguage] as? ALLanguage {
      if let clangFormatID = language.clangFormatID {
        if let ext = language.defaultExtension {
          args.append(String(format:ALClangFormatController.SourceFileNameFormat, ext))
        }
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
    let keyValue = NSRegularExpression.aml_regularExpressionWithPattern("^\\s*[a-zA-Z_]+\\s*:\\s*[^#\\s]")
    
    let sectionRE = String(format:"^%@", ALClangFormatController.SectionBegin)
    let section = NSRegularExpression.aml_regularExpressionWithPattern(sectionRE)
    return nil != section.firstMatchInString(string)
      && nil != keyValue.firstMatchInString(string)
  }
  
  override var pageGuideColumn : Int
  {
    if let value = self.optionWithKey(ALClangFormatController.PageGuideKey)?.value {
      return value.unsignedIntegerValue
    }
    
    return super.pageGuideColumn
  }
}