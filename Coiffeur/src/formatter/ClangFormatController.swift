//
//  ClangFormatController.swift
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

class ClangFormatController : CoiffeurController {
  
  fileprivate struct Private {
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
	
	override class var currentExecutableURL : URL? {
		didSet {
			Private.Options = nil
			Private.DefaultValues = nil
		}
	}

	override var pageGuideColumn : Int
  {
		if let value = self.optionWithKey(Private.PageGuideKey)?.stringValue,
			let int = Int(value)
		{
			return int
		}
		
		return super.pageGuideColumn
	}

	override class func contentsIsValidInString(_ string:String) -> Bool
	{
		let keyValue = NSRegularExpression.aml_re_WithPattern(
			"^\\s*[a-zA-Z_]+\\s*:\\s*[^#\\s]")
		let section = NSRegularExpression.aml_re_WithPattern(
			"^\(Private.SectionBegin)")
		return nil != section.firstMatchInString(string)
			&& nil != keyValue.firstMatchInString(string)
	}
	
	override class func createCoiffeur() throws -> CoiffeurController
  {
    let controller = try super.createCoiffeur()

		if Private.Options == nil {
			let bundle = Bundle(for: self)
			if let docURL = bundle.url(forResource: Private.DocumentationFileName,
				withExtension: Private.DocumentationFileExtension)
			{
				Private.Options = try String(contentsOf: docURL,
					encoding: String.Encoding.utf8)
			} else {
				throw Error(
					"Cannot find %@.%@",
					Private.DocumentationFileName,
					Private.DocumentationFileExtension)
			}
		}

		try controller.readOptionsFromString(Private.Options!)

		if Private.DefaultValues == nil {
			Private.DefaultValues = try Process(controller.executableURL,
				arguments: [Private.ShowDefaultConfigArgument]).run()
		}
	
		try controller.readValuesFromString(Private.DefaultValues!)

		return controller
  }
  
  fileprivate class func _cleanUpRST(_ string:String) -> String
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
      
      var code = rst.substringWithRange(match!.range(at: 1))
      code = code.replacingOccurrences(of: "\n", with:nl)
      code = code.replacingOccurrences(of: " ", with:sp)
      code += rst.substringWithRange(match!.range(at: 2))
      rst = rst.stringByReplacingCharactersInRange(match!.range(at: 0),
				withString:code)
    }
    
    // preserve double nl, breaks before * and - (list items)
    rst = rst.replacingOccurrences(of: "\n\n", with:par)
    rst = rst.replacingOccurrences(of: "\n*", with:"\(nl)*")
    rst = rst.replacingOccurrences(of: "\n-", with:"\(nl)-")
    
    // un-escape escaped characters
    let esc = NSRegularExpression.ci_dmls_re_WithPattern("\\\\(.)")
    
    rst = esc.stringByReplacingMatchesInString(rst, withTemplate:"$1")
    
    // wipe out remaining whitespaces as single space
    rst = rst.replacingOccurrences(of: "\n", with:" ")
    
    let wsp = NSRegularExpression.ci_dmls_re_WithPattern("\\s\\s+")
    rst = wsp.stringByReplacingMatchesInString(rst, withTemplate:" ")
    
    // restore saved spacing
    rst = rst.replacingOccurrences(of: nl, with:"\n")
    rst = rst.replacingOccurrences(of: sp, with:" ")
    rst = rst.replacingOccurrences(of: par, with:"\n\n")
    
    // quote the emphasized words
    let quot = NSRegularExpression.ci_dmls_re_WithPattern("``(.*?)``")
    rst = quot.stringByReplacingMatchesInString(rst, withTemplate:"“$1”")
    
    //      NSLog(@"%@", mutableRST)
    return rst
  }
  
  fileprivate func _closeOption(_ option: inout ConfigOption?)
  {
    if let opt = option {
      opt.title = ClangFormatController._cleanUpRST(opt.title)
      opt.documentation = ClangFormatController._cleanUpRST(opt.documentation)
    }
  }
  
  override func readOptionsFromLineArray(_ lines: [String]) throws
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
      //                      line = trimmedLine
      
      line = line.trim()
			
      if let match = head.firstMatchInString(line) {
        
        self._closeOption(&currentOption)
        
				let newOption = ConfigOption.objectInContext(self.managedObjectContext,
					parent:section)
        newOption.indexKey   = line.substringWithRange(match.range(at: 1))
        in_title             = true
        let type             = line.substringWithRange(match.range(at: 2))
        
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
          let token = line.substringWithRange(match.range(at: 2))
        
          if !token.isEmpty {
            option.type = option.type.stringByAppendingString(token,
							separatedBy: ConfigNode.TypeSeparator)
          }
        
          let prefix = line.substringWithRange(match.range(at: 1))
          option.documentation +=
						"\(prefix)``\(token)``\n"
          continue
        }
      
        if in_title {
          option.title = option.title.stringByAppendingString(line,
						separatedBy:" ")
        }
      
        option.documentation += "\(line)\n"
      }
    }
    
    self._closeOption(&currentOption)
  }
  
  override func readValuesFromLineArray(_ lines:[String]) throws
  {
    for aLine in lines {
      var line = aLine
      line = line.trim()
      
      if line.hasPrefix(Private.Comment) {
        continue
      }
      
			if let range = line.range(of: ":") {
        let key = String(line[line.startIndex..<range.lowerBound]).trim()
        if let option = self.optionWithKey(key) {
					var value = String(line[range.upperBound...]).trim()
					if option.type == OptionType.StringList.rawValue {
						value = value.stringByTrimmingPrefix("[")
						value = value.stringByTrimmingSuffix("]")
					} else {
						value = value.commandLineComponents[0]
					}
					option.stringValue = value
				} else {
          NSLog("Warning: unknown token %@ on line %@", key, line)
        }
      }
    }
  }
  
  override func writeValuesToURL(_ absoluteURL:URL) throws
  {
    var data = ""
    
    data += "\(Private.SectionBegin)\n"
		
		let allOptions = try self.managedObjectContext.fetch(ConfigOption.self,
			sortDescriptors:[CoiffeurController.KeySortDescriptor])

		for option in allOptions {
			if var value = option.stringValue {
				if option.type == OptionType.StringList.rawValue {
					value = "[\(value)]"
				} else {
					value = value.stringByQuoting("'")
				}
				data += "\(option.indexKey): \(value)\n"
			}
		}
		
		data += "\(Private.SectionEnd)\n"
		
		try data.write(to: absoluteURL, atomically:true,
					encoding:String.Encoding.utf8)
  }
  
	override func format(_ arguments:Arguments,
		completionHandler: @escaping (_:StringResult) -> Void) -> Bool
  {
    let workingDirectory = NSTemporaryDirectory()
    let configURL = URL(fileURLWithPath: workingDirectory).appendingPathComponent(
			Private.StyleFileName)
		
		do {
			try self.writeValuesToURL(configURL)
		} catch let error as NSError {
      completionHandler(StringResult(error))
      return false
    }
    
    var args = [Private.StyleFlag]
    
		if let _ = arguments.language.clangFormatID,
			let ext = arguments.language.defaultExtension
		{
			args.append(String(format:Private.SourceFileNameFormat, ext))
		}
		
		Process(self.executableURL, arguments: args,
			workingDirectory: workingDirectory).runAsync(arguments.text) {
				(result:StringResult) in
        let _ = try? FileManager.default.removeItem(at: configURL)
				completionHandler(result)
		}
		
    return true
  }
  
}
