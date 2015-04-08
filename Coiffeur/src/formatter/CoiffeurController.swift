//
//  CoiffeurController.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation
import CoreData

protocol ALCoiffeurControllerDelegate : class {
  func formatArgumentsForCoiffeurController(controller:ALCoiffeurController) -> (text:String, attributes: NSDictionary)
  func coiffeurController(coiffeurController:ALCoiffeurController, setText text:String)
}

class ALCoiffeurController : NSObject {

  class var availableTypes : [ALCoiffeurController.Type] { return [ ALClangFormatController.self, ALUncrustifyController.self ] }
  
  class var NewLine : String { return "\n" }
  class var Space : String { return " " }
  class var FormatLanguage : String { return "language" }
  class var FormatFragment : String { return "fragment" }
  
  enum OptionType : Swift.String {
    case Signed = "signed"
    case Unsigned = "unsigned"
    case String = "string"
  }
  
  class var documentType : String { return "" }
//  var documentType : String { return self.dynamicType.documentType }
  
  var managedObjectContext : NSManagedObjectContext { return storedManagedObjectContext! }
  var executableURL : NSURL { return storedExecutableURL! }
  var root : ConfigRoot?
  var pageGuideColumn : Int { return 0 }
  weak var delegate : ALCoiffeurControllerDelegate?
  
  private var storedManagedObjectModel : NSManagedObjectModel?
  private var storedManagedObjectContext : NSManagedObjectContext?
  private var storedExecutableURL : NSURL?
  
  class var KeyComparator : (ConfigOption,ConfigOption)->Bool
  {
    return { (obj1:AnyObject, obj2:AnyObject) -> Bool in
      if let o1 = obj1 as? ConfigOption {
        if let o2 = obj2 as? ConfigOption {
          return o1.indexKey < o2.indexKey
        } else {
          return false
        }
      } else {
        return true
      }
    }
  }
  
  convenience required init?(error:NSErrorPointer)
  {
    self.init(nil, error:error)
  }

  private class func _makeCopyOfEntity(entity:NSEntityDescription!, inout cache entities: Dictionary<String, NSEntityDescription>) -> NSEntityDescription
  {
    let entityName = entity.name!
    if let existingEntity = entities[entityName] {
      return existingEntity
    }
    
    var newEntity = (entity.copy() as NSEntityDescription)
    entities[entityName] = newEntity
    
    newEntity.managedObjectClassName = "Coiffeur.\(entity.managedObjectClassName)"
    var newSubEntities : [NSEntityDescription] = []

    for e in newEntity.subentities {
      if let se = e as? NSEntityDescription {
        newSubEntities.append(_makeCopyOfEntity(se, cache:&entities))
      }
    }
    
    newEntity.subentities = newSubEntities;
    return newEntity
  }
  
  private class func _fixMOM(mom:NSManagedObjectModel) -> NSManagedObjectModel
  {
    var momCopy = NSManagedObjectModel()
    var entityCache : Dictionary<String, NSEntityDescription> = [:]
    var newEntities : [NSEntityDescription] = []
    
    for e in mom.entities {
      newEntities.append(ALCoiffeurController._makeCopyOfEntity(e as NSEntityDescription, cache:&entityCache))
    }
    
    momCopy.entities = newEntities
    return momCopy
  }

  
  init?(_ executableURL:NSURL?, error:NSErrorPointer)
  {
    super.init()

    if executableURL == nil {
      return nil
    }
    
    let originalModel = NSManagedObjectModel.mergedModelFromBundles([NSBundle(forClass: ALCoiffeurController.self)])
 
    if originalModel == nil {
      return nil
    }
    var mom = ALCoiffeurController._fixMOM(originalModel!)
    
    var moc = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)

    moc.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
    
    if nil == moc.persistentStoreCoordinator?.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: error) {
      return nil
    }
    
    moc.undoManager = NSUndoManager()
    
    self.storedExecutableURL = executableURL
    self.storedManagedObjectModel   = mom;
    self.storedManagedObjectContext = moc;
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("modelDidChange:"), name: NSManagedObjectContextObjectsDidChangeNotification, object: self.managedObjectContext)
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  func modelDidChange(_:AnyObject?)
  {
    self.format()
  }
  
  func format() -> Bool
  {
    var result = false;
    
    if let del = self.delegate {
      let (text, attributes) = del.formatArgumentsForCoiffeurController(self)
      
      result = self.format(text, attributes:attributes, {( output:String?, error:NSError?) -> Void in
            if let text = output {
              del.coiffeurController(self, setText:text)
            }
          })
    }
    return result;
  }
  
  func format(text:String, attributes:NSDictionary, completion:( output:String?, error:NSError?) -> Void) -> Bool
  {
    return false
  }
  
  func readOptionsFromLineArray(lines:[String]) -> Bool
  {
    return false
  }

  func readValuesFromLineArray(lines:[String]) -> Bool
  {
    return false
  }
  
  func readOptionsFromString(text:String) -> Bool
  {
    let lines = text.componentsSeparatedByString(ALCoiffeurController.NewLine)
    self.managedObjectContext.disableUndoRegistration()
  
    self.root = ConfigRoot.objectInContext(self.managedObjectContext);
  
    let result = self.readOptionsFromLineArray(lines)
  
    self.managedObjectContext.enableUndoRegistration();
  
    return result;
  }
  
  func readValuesFromString(text:String) -> Bool
  {
    let lines = text.componentsSeparatedByString(ALCoiffeurController.NewLine)
    self.managedObjectContext.disableUndoRegistration()
        
    let result = self.readValuesFromLineArray(lines)
    
    self.managedObjectContext.enableUndoRegistration();
    
    return result;
  }

  func readValuesFromURL(absoluteURL:NSURL, error:NSErrorPointer) -> Bool
  {
    let data = String(contentsOfURL:absoluteURL, encoding:NSUTF8StringEncoding, error:error)
    
    return data != nil && self.readValuesFromString(data!)
  }
  
  func writeValuesToURL(absoluteURL:NSURL, error:NSErrorPointer) -> Bool
  {
    return false
  }
 
  func optionWithKey(key:String) -> ConfigOption?
  {
    return ConfigOption.firstObjectInContext(self.managedObjectContext, withPredicate:NSPredicate(format: "indexKey = %@", key), error:nil)
  }
  
  class func contentsIsValidInString(string:String, error:NSErrorPointer) -> Bool
  {
    return false
  }
  
  func startExecutable(arguments:[String], workingDirectory:String?, input:String?) -> (task:NSTask?, error:NSError?)
  {
    var myTask : NSTask? = nil
    var myError : NSError? = nil
    
    ALExceptions.try({
      var task = NSTask()
      
      task.launchPath = self.executableURL.path!
      task.arguments = arguments
      if workingDirectory != nil {
        task.currentDirectoryPath = workingDirectory!
      }
      
      task.standardOutput = NSPipe()
      task.standardInput = NSPipe()
      task.standardError = NSPipe()
      
      let writeHandle = input != nil ? task.standardInput.fileHandleForWriting : nil
      
      task.launch()
      
      if writeHandle != nil {
        writeHandle.writeData(input!.dataUsingEncoding(NSUTF8StringEncoding)!)
        writeHandle.closeFile()
      }
      
      myTask = task
      
      }, catch: { (ex:NSException?) in
        
        let reason = (ex?.reason != nil) ? ex!.reason! : ""
        let info = [ NSLocalizedDescriptionKey: reason]
        myError = NSError(domain: NSPOSIXErrorDomain, code: 0, userInfo: info)
        
      }, finally: {})
    
    return (task:myTask, error:myError);
  }
  
  func runTask(task:NSTask) -> (output:String?, error:NSError?)
  {
    let outHandle = task.standardOutput.fileHandleForReading
    let outData = outHandle.readDataToEndOfFile()
    
    let errHandle = task.standardError.fileHandleForReading
    let errData = errHandle.readDataToEndOfFile()
    
    task.waitUntilExit()
    
    let status = task.terminationStatus
    
    if status == 0 {
      return (output:NSString(data: outData, encoding: NSUTF8StringEncoding), error:nil)
    } else {
      var errText = NSString(data: errData, encoding: NSUTF8StringEncoding)
      if errText == nil {
        errText = String(format:NSLocalizedString("Format excutable error code %d", comment:""), status)
      }
      return (output: nil, error:NSError(domain: NSPOSIXErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey : errText!]))
    }
  }
  
  func runExecutable(arguments:[String], workingDirectory:String?, input:String?, block:(output:String?, error:NSError?)->Void) -> NSError?
  {
    let (task, error) = self.startExecutable(arguments, workingDirectory: workingDirectory, input: input)
    
    if task == nil {
      return error
    }
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), {
      let (output, error) = self.runTask(task!)
      dispatch_async(dispatch_get_main_queue(), {
        block(output: output, error: error);
      });
    });
    
    return nil;
  }
  
  func runExecutable(arguments:[String], workingDirectory:String?, input:String?) -> (output:String?, error:NSError?)
  {
    let (task, error) = self.startExecutable(arguments, workingDirectory: workingDirectory, input: input)
    
    if let theTask = task {
      return self.runTask(theTask)
    } else {
      return (output:nil, error:error)
    }
  }

}





















