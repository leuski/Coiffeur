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
    static var ExecutableURLUDKey = "ClangFormatExecutableURL"
		static var ExecutableTitleUDKey = "Clang-Format Executable"
		
    static var Options : String? = nil
    static var DefaultValues : String? = nil
  }
  
	override class var localizedExecutableTitle : String {
		return NSLocalizedString(Private.ExecutableTitleUDKey, comment:"") }
  override class var documentType : String {
		return Private.DocumentType }
	override class var currentExecutableName : String {
		return Private.ExecutableName }
	override class var currentExecutableURLUDKey : String {
		return Private.ExecutableURLUDKey }
	
	override class var currentExecutableURL : NSURL? {
		didSet {
			Private.Options = nil
			Private.DefaultValues = nil
		}
	}

	override var pageGuideColumn : Int
  {
		if let value = self.optionWithKey(Private.PageGuideKey)?.stringValue,
			let int = value.toInt()
		{
			return int
		}
		
		return super.pageGuideColumn
	}

	override class func contentsIsValidInString(string:String) -> Bool
	{
		let keyValue = NSRegularExpression.aml_re_WithPattern(
			"^\\s*[a-zA-Z_]+\\s*:\\s*[^#\\s]")
		let section = NSRegularExpression.aml_re_WithPattern(
			"^\(Private.SectionBegin)")
		return nil != section.firstMatchInString(string)
			&& nil != keyValue.firstMatchInString(string)
	}
	
	override class func createCoiffeur() -> CoiffeurController.Result
  {
    let result = super.createCoiffeur()

    switch result {
    case .Failure:
      return result
    case .Success(let controller):
      if Private.Options == nil {
        let bundle = NSBundle(forClass: self)
        if let docURL = bundle.URLForResource(Private.DocumentationFileName,
					withExtension: Private.DocumentationFileExtension) {
          var error: NSError?
          Private.Options = String(contentsOfURL: docURL,
						encoding: NSUTF8StringEncoding,
						error:&error)
          if Private.Options == nil {
            return CoiffeurController.Result(Error(
							"Failed to read the content of %@.%@ as UTF8 string",
							Private.DocumentationFileName,
							Private.DocumentationFileExtension))
          }
        } else {
          return CoiffeurController.Result(Error(
						"Cannot find %@.%@",
						Private.DocumentationFileName,
						Private.DocumentationFileExtension))
        }
      }
      if let error = controller.readOptionsFromString(Private.Options!) {
        return CoiffeurController.Result(error)
      }
      if Private.DefaultValues == nil {
				switch NSTask(controller.executableURL,
					arguments: [Private.ShowDefaultConfigArgument]).run() {
        case .Failure(let error):
          return CoiffeurController.Result(error)
        case .Success(let text):
          Private.DefaultValues = text
        }
      }
      if let error = controller.readValuesFromString(Private.DefaultValues!) {
        return CoiffeurController.Result(error)
      }
      return result
    }
  }
  
  private class func _cleanUpRST(string:String) -> String
  {
    var rst = string
    rst = rst.trim()
    rst += "\n"
    
    let nl  = "__NL__"
    let sp  = "__SP__"
    let par = "__PAR__"
    
    // preserve all spacing inside \code ... \endcode
    let lif = NSRegularExpression.ci_dmls_re_WithPattern(
			"\\\\code(.*?)\\\\endcode(\\s)")
    
    while true {
      let match = lif.firstMatchInString(rst)
      if match == nil {
        break
      }
      
      var code = rst.substringWithRange(match!.rangeAtIndex(1))
      code = code.stringByReplacingOccurrencesOfString("\n", withString:nl)
      code = code.stringByReplacingOccurrencesOfString(" ", withString:sp)
      code += rst.substringWithRange(match!.rangeAtIndex(2))
      rst = rst.stringByReplacingCharactersInRange(match!.rangeAtIndex(0),
				withString:code)
    }
    
    // preserve double nl, breaks before * and - (list items)
    rst = rst.stringByReplacingOccurrencesOfString("\n\n", withString:par)
    rst = rst.stringByReplacingOccurrencesOfString("\n*", withString:"\(nl)*")
    rst = rst.stringByReplacingOccurrencesOfString("\n-", withString:"\(nl)-")
    
    // un-escape escaped characters
    let esc = NSRegularExpression.ci_dmls_re_WithPattern("\\\\(.)")
    
    rst = esc.stringByReplacingMatchesInString(rst, withTemplate:"$1")
    
    // wipe out remaining whitespaces as single space
    rst = rst.stringByReplacingOccurrencesOfString("\n", withString:" ")
    
    let wsp = NSRegularExpression.ci_dmls_re_WithPattern("\\s\\s+")
    rst = wsp.stringByReplacingMatchesInString(rst, withTemplate:" ")
    
    // restore saved spacing
    rst = rst.stringByReplacingOccurrencesOfString(nl, withString:"\n")
    rst = rst.stringByReplacingOccurrencesOfString(sp, withString:" ")
    rst = rst.stringByReplacingOccurrencesOfString(par, withString:"\n\n")
    
    // quote the emphasized words
    let quot = NSRegularExpression.ci_dmls_re_WithPattern("``(.*?)``")
    rst = quot.stringByReplacingMatchesInString(rst, withTemplate:"“$1”")
    
    //      NSLog(@"%@", mutableRST);
    return rst
  }
  
  private func _closeOption(inout option: ConfigOption?)
  {
    if let opt = option {
      opt.title = ClangFormatController._cleanUpRST(opt.title)
      opt.documentation = ClangFormatController._cleanUpRST(opt.documentation)
    }
  }
  
  override func readOptionsFromLineArray(lines: [String]) -> NSError?
  {
		let section = ConfigSection.objectInContext(self.managedObjectContext,
			parent:self.root, title:"Options")
		
    var currentOption : ConfigOption?
    
    var in_doc = false
    
    let head = NSRegularExpression.ci_re_WithPattern(
			"^\\*\\*(.*?)\\*\\* \\(``(.*?)``\\)")
    let item = NSRegularExpression.ci_re_WithPattern(
			"^(\\s*\\* )``.*\\(in configuration: ``(.*?)``\\)")
    
    var in_title = false
    
    for aLine in lines {
      var line = aLine
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
        
				var newOption = ConfigOption.objectInContext(self.managedObjectContext,
					parent:section)
        newOption.indexKey   = line.substringWithRange(match.rangeAtIndex(1))
        in_title             = true
        let type             = line.substringWithRange(match.rangeAtIndex(2))
        
        if type == "bool" {
          newOption.type = "false,true"
        } else if type == "unsigned" {
          newOption.type = OptionType.Unsigned.rawValue
        } else if type == "int" {
          newOption.type = OptionType.Signed.rawValue
        } else if type == "std::string" {
          newOption.type = OptionType.String.rawValue
        } else if type == "std::vector<std::string>" {
          newOption.type = OptionType.StringList.rawValue
        } else {
          newOption.type = ""
        }
        
        currentOption = newOption
        
        continue
      }
      
      if line.isEmpty {
        in_title = false
      }
      
      if let option = currentOption {
      
        if let match = item.firstMatchInString(line) {
          let token = line.substringWithRange(match.rangeAtIndex(2))
        
          if !token.isEmpty {
            option.type = option.type.stringByAppendingString(token,
							separatedBy: ConfigNode.TypeSeparator)
          }
        
          let prefix = line.substringWithRange(match.rangeAtIndex(1))
          option.documentation +=
						"\(prefix)``\(token)``\(CoiffeurController.NewLine)"
          continue
        }
      
        if in_title {
          option.title = option.title.stringByAppendingString(line,
						separatedBy:" ")
        }
      
        option.documentation += line + CoiffeurController.NewLine
      }
    }
    
    self._closeOption(&currentOption)
    
    return nil
  }
  
  override func readValuesFromLineArray(lines:[String]) -> NSError?
  {
    for aLine in lines {
      var line = aLine
      line = line.trim()
      
      if line.hasPrefix(Private.Comment) {
        continue
      }
      
			if let range = line.rangeOfString(":") {
        let key = line.substringToIndex(range.startIndex).trim()
        if let option = self.optionWithKey(key) {
					var value = line.substringFromIndex(range.endIndex).trim()
					if option.type == OptionType.StringList.rawValue {
						value = value.stringByTrimmingPrefix("[")
						value = value.stringByTrimmingSuffix("]")
					} else {
						value = value.commandLineComponents[0]
					}
					option.stringValue = value
				} else {
          NSLog("Warning: unknown token %@ on line %@", key, line);
        }
      }
    }
    
    return nil
  }
  
  override func writeValuesToURL(absoluteURL:NSURL) -> NSError?
  {
    var data = ""
    
    data += "\(Private.SectionBegin)\(CoiffeurController.NewLine)"
		
		switch self.managedObjectContext.fetch(ConfigOption.self,
			sortDescriptors:[CoiffeurController.KeySortDescriptor])
		{
		case .Success(var allOptions):
			for option in allOptions {
				if var value = option.stringValue {
					if option.type == OptionType.StringList.rawValue {
						value = "[\(value)]"
					} else {
						value = value.stringByQuoting(quote: "'")
					}
					data += "\(option.indexKey): \(value)\(CoiffeurController.NewLine)"
				}
			}
		case .Failure(let error):
			return error
		}
		
		data += "\(Private.SectionEnd)\(CoiffeurController.NewLine)"
		
    var error:NSError?
    if data.writeToURL(absoluteURL, atomically:true,
			encoding:NSUTF8StringEncoding,
			error:&error)
		{
      return nil
    }
    return error ?? super.writeValuesToURL(absoluteURL)
  }
  
	override func format(arguments:Arguments,
		completionHandler: (_:StringResult) -> Void) -> Bool
  {
    let workingDirectory = NSTemporaryDirectory()
    let configPath = workingDirectory.stringByAppendingPathComponent(
			Private.StyleFileName)
    
    var localError : NSError?
    
    if let error = self.writeValuesToURL(NSURL(fileURLWithPath: configPath)!) {
      completionHandler(StringResult(error))
      return false
    }
    
    var args = [Private.StyleFlag]
    
		if let clangFormatID = arguments.language.clangFormatID,
			let ext = arguments.language.defaultExtension
		{
			args.append(String(format:Private.SourceFileNameFormat, ext))
		}
		
		NSTask(self.executableURL, arguments: args,
			workingDirectory: workingDirectory).runAsync(arguments.text) {
				(result:StringResult) in
				NSFileManager.defaultManager().removeItemAtPath(configPath, error:nil)
				completionHandler(result)
		}
		
    return true
  }
  
}