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

    static var OptionsDocumentation : String? = nil
  }
  
	override class var localizedExecutableTitle : String { return NSLocalizedString(Private.ExecutableTitleUDKey, comment:"") }
  override class var documentType : String { return Private.DocumentType }
	override class var currentExecutableName : String { return Private.ExecutableName }
	override class var currentExecutableURLUDKey : String { return Private.ExecutableURLUDKey }
	
  override class func createCoiffeur() -> CoiffeurControllerResult
  {
    let result = super.createCoiffeur()
    
    switch result {
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
			
		default:
			break
		}
		
		return result
  }
  
  override func readOptionsFromLineArray(lines:[String]) -> NSError?
  {
    var count = 0
    var currentSection : ConfigSection?
		var currentComment : String = ""
    
    for  aline in lines {
      ++count
      
      if count == 1 {
        continue
      }
      
      var line = aline.trim()
      
      if line.isEmpty {

				currentComment = currentComment.trim()
				if !currentComment.isEmpty {
					if let range = currentComment.rangeOfCharacterFromSet(NSCharacterSet.newlineCharacterSet()) {
					} else {
						var section = ConfigSection.objectInContext(self.managedObjectContext)
						section.parent = self.root
						section.title = currentComment
						currentSection = section
					}
					currentComment = ""
				}
 
			} else if line.hasPrefix(Private.Comment) {

				line = line.stringByTrimmingPrefix(Private.Comment)
				currentComment += "\(line)\n"

			} else if let range = line.rangeOfString(Private.Comment) {
				
				let keyValue = line.substringToIndex(range.startIndex)
				var type = line.substringFromIndex(range.endIndex)
				
				if let (key, value) = _keyValuePairFromString(keyValue) {

					type = type.trim().stringByReplacingOccurrencesOfString("/", withString: ConfigNode.TypeSeparator)
					currentComment = currentComment.trim()
					var option = ConfigOption.objectInContext(self.managedObjectContext)
					option.parent = currentSection
					option.indexKey = key
					option.stringValue = value
					option.documentation = currentComment
					if type == "number" {
						option.type = OptionType.Signed.rawValue
					} else {
						option.type = type
					}
					option.title = currentComment.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())[0]

				}
				currentComment = ""
			}
			
    }

		return nil
  }
		
	private func _keyValuePairFromString(string:String) -> (key:String, value:String)?
	{
		var line = string
		
		if let range = line.rangeOfString(Private.Comment) {
			line = line.substringToIndex(range.startIndex)
		}
		
		if let range = line.rangeOfString("=") {
			line = line.stringByReplacingCharactersInRange(range, withString: " ")
		}
		
		while let range = line.rangeOfString(",") {
			line = line.stringByReplacingCharactersInRange(range, withString: " ")
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
		
		if head == "type" {
		} else if head == "define" {
		} else if head == "macro-open" {
		} else if head == "macro-close" {
		} else if head == "macro-else" {
		} else if head == "set" {
		} else if head == "include" {
		} else if head == "file_ext" {
		} else {
			return (key:head, value:tokens[1])
		}
		
		return nil

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
			
			if let (key, value) = _keyValuePairFromString(line) {
				if let option = self.optionWithKey(key) {
					option.stringValue = value
				} else {
					NSLog("Warning: unknown token %@ on line %@", key, line)
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
					value = value.stringByQuoting()
					data += "\(option.indexKey) = \(value)\(CoiffeurController.NewLine)"
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