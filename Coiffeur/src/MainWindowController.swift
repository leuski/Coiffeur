//
//  MainWindowController.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

@objc(ALMainWindowController)
class ALMainWindowController : NSWindowController, NSOutlineViewDelegate,
  NSWindowDelegate, ALCoiffeurControllerDelegate,
NSSplitViewDelegate {
  
  typealias ALScrollLocation = CGFloat
  
  @IBOutlet weak var splitView : NSSplitView?
  var documentView : ALDocumentView?
  var fragaria : MGSFragaria
  var codeString : NSString = ""
  var newString : Bool = false
  
  var sourceTextViewScrollLocation : ALScrollLocation {
    get {
      // we will try and preserve visible frame position in the document
      // across changes.
      
      let      textView :NSTextView     = self.fragaria.textView()
      let  textStorage   = textView.textStorage!
      let layoutManager = textView.layoutManager!
      
      // first we need the document height.
      // textView lays text out lazily, so we cannot just use the textView frame
      // to get the height. It's not computed yet.
      
      // Here we are taking advantage of two assumptions:
      // 1. the text is not wrapping, so we only count hard line breaks
      let oldDocumentLineCount
      = textStorage.string.lineCountForCharacterRange(textStorage.string.startIndex..<textStorage.string.endIndex)
      
      // 2. the text is laid out in one font size, so the line height is constant
      let lineHeight        = layoutManager.defaultLineHeightForFont(textView.font!)
      
      let frameHeight       = CGFloat(oldDocumentLineCount) * lineHeight
      let  visRect           = textView.visibleRect
      let maxScrollLocation = frameHeight - visRect.size.height
      let relativeScrollLocation
      = (maxScrollLocation > 0) ? visRect.origin.y / maxScrollLocation : 0
      
      //              NSLog("%f %f %f %f %f %ld", frameHeight, visRect.size.height,
      //                                      visRect.origin.y, maxScrollLocation,
      // relativeScrollLocation, textStorage.string.length);
      
      return relativeScrollLocation
    }
    set (relativeScrollLocation) {
      let      textView :NSTextView     = self.fragaria.textView()
      let  textStorage   = textView.textStorage!
      let layoutManager = textView.layoutManager!
      
      layoutManager.ensureLayoutForTextContainer(textView.textContainer!)
      
      let lineHeight        = layoutManager.defaultLineHeightForFont(textView.font!)
      
      let newDocumentLineCount
      = textStorage.string.lineCountForCharacterRange(textStorage.string.startIndex..<textStorage.string.endIndex)
      
      let frameHeight       = CGFloat(newDocumentLineCount) * lineHeight
      var  visRect           = textView.visibleRect
      let maxScrollLocation = frameHeight - visRect.size.height
      
      //              NSLog("%f %f %f %f %f %ld", frameHeight, visRect.size.height,
      //                                      visRect.origin.y, maxScrollLocation,
      // relativeScrollLocation, textStorage.string.length);
      
      visRect.origin.y = round(relativeScrollLocation * maxScrollLocation)
      visRect.origin.x = 0;
      textView.scrollRectToVisible(visRect)
      
    }
  }
  var diffMatchPatch : DiffMatchPatch
  weak var overviewScroller : ALOverviewScroller?
  
  var language : ALLanguage {
    didSet {
      let fragariaName = language.fragariaID
      self.fragaria.setObject(fragariaName, forKey:MGSFOSyntaxDefinitionName)
      self.uncrustify(nil)
    }
  }
  
  var fileURL : NSURL? {
    didSet {
      if let url = self.fileURL {
        NSUserDefaults.standardUserDefaults().setURL(url, forKey: ALLastSourceURL)
        if let uti = NSWorkspace.sharedWorkspace().typeOfFile(url.path!, error:nil) {
          if let lang = ALLanguage.languageWithUTI(uti) {
            self.language = lang
          }
        }
      }
    }
  }
  
  private let ALLastSourceURL       = "LastSourceURL"
  private let SamplesFolderName     = "samples"
  private let SampleFileName        = "sample"
  private let ObjectiveCPPExtension = "mm"
  
  override var document: AnyObject? {
    didSet (oldDocument) {
      let containerView = self.splitView!.subviews[0] as NSView
      
      if oldDocument != nil {
        // lets see if die here. need a copy of the subview list
        for v in containerView.subviews {
          v.removeFromSuperviewWithoutNeedingDisplay()
        }
      }
      
      if var d = self.styleDocument {
        d.embedInView(containerView)
        d.model?.delegate = self
      }
      
      self.uncrustify(nil)
    }
  }
  
  override init(window:NSWindow?)
  {
    self.diffMatchPatch = DiffMatchPatch()
    self.fragaria       = MGSFragaria()
    self.language       = ALLanguage.languageFromUserDefaults()
    super.init(window:window)
  }
  
  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }
  
  convenience override init()
  {
    self.init(windowNibName:"ALMainWindowController")
    self._restoreSource()
    let x = self.window
  }
  
  @IBAction func uncrustify(sender : AnyObject?)
  {
    if var formatter = self.styleDocument {
      if let source = self.sourceDocument {
        if let m = formatter.model {
          m.format()
        }
      }
    }
  }
  
  func formatArgumentsForCoiffeurController(controller:ALCoiffeurController) -> (text:String, attributes: NSDictionary)
  {
    if let source = self.sourceDocument {
      return (text:source.string, attributes:[ALCoiffeurController.FormatLanguage:source.language,
        ALCoiffeurController.FormatFragment:NSNumber(bool:false)])
    } else {
      return (text:"", attributes: [:])
    }
  }
  
  func coiffeurController(coiffeurController:ALCoiffeurController, setText text:String)
  {
    if var source = self.sourceDocument {
      NSUserDefaults.standardUserDefaults().setInteger(coiffeurController.pageGuideColumn, forKey: MGSFragariaPrefsShowPageGuideAtColumn)
      NSUserDefaults.standardUserDefaults().setBool(coiffeurController.pageGuideColumn != 0, forKey: MGSFragariaPrefsShowPageGuide)
      source.string = text
    }
  }
  
  private func _restoreSource()
  {
    if let lastURL = NSUserDefaults.standardUserDefaults().URLForKey(ALLastSourceURL) {
      if self.loadSourceFormURL(lastURL, error:nil) {
        return
      }
    }
    
    let url
    = NSBundle.mainBundle().URLForResource(SampleFileName, withExtension:ObjectiveCPPExtension, subdirectory:SamplesFolderName)!
    var error : NSError?
    
    if !self.loadSourceFormURL(url, error:&error) {
      NSException(name: "No Source", reason: "Failed to load the sample source file", userInfo: nil).raise()
    }
  }
  
  func loadSourceFormURL(url:NSURL, error outError:NSErrorPointer) -> Bool
  {
    if let source = String(contentsOfURL:url, encoding:NSUTF8StringEncoding, error:outError) {
      self.newString = true
      self.codeString = source
      self.fileURL = url
      return true
    } else {
      return false
    }
  }
  
  override func windowDidLoad()
  {
    super.windowDidLoad()
    
    self.documentView = ALDocumentView()
    var types = NSMutableSet()
    
    for  l in ALLanguage.supportedLanguages {
      types.addObjectsFromArray(l.UTIs)
    }
    
    self.documentView!.allowedFileTypes  = types.allObjects as [String]
    self.documentView!.representedObject = self
    
    let resourcesURL = NSBundle.mainBundle().resourceURL!
    let baseURL      = resourcesURL.URLByAppendingPathComponent(SamplesFolderName)
    let fm           = NSFileManager.defaultManager()
    
    if let urls = fm.contentsOfDirectoryAtURL(baseURL, includingPropertiesForKeys:nil,
      options:NSDirectoryEnumerationOptions.SkipsHiddenFiles, error:nil) {
        self.documentView!.knownSampleURLs = urls as [NSURL]
    }
    
    self.splitView!.replaceSubview(self.splitView!.subviews[1] as NSView, with:self.documentView!.view)
    
    // we want to be the delegate
    self.fragaria.setObject(self, forKey:MGSFODelegate)
    self.fragaria.embedInView(self.documentView!.containerView)
    
    let textView : NSTextView = self.fragaria.textView()
    textView.editable = false
    textView.textContainer!.widthTracksTextView = false
    textView.textContainer!.containerSize       = NSMakeSize(CGFloat.max, CGFloat.max)
    
    let       scrollView       = textView.enclosingScrollView!
    let overviewScroller = ALOverviewScroller(frame:NSMakeRect(0,0,0,0))
    self.overviewScroller       = overviewScroller
    scrollView.verticalScroller = overviewScroller
    scrollView.verticalScroller!.scrollerStyle = NSScrollerStyle.Legacy
  }
  
  func windowWillClose(notification:NSNotification)
  {
    self.documentView?.representedObject = nil
  }
  
  var styleDocument : Document? {
    return self.document as? Document
  }
  
  var sourceDocument : ALMainWindowController? {
    return self
  }
  
  var string:String {
    get {
      return self.codeString
    }
    set (string){
      // TODO need a copy
      let oldString : String = self.fragaria.string()
      let scrollLocation = self.sourceTextViewScrollLocation
      
      self.fragaria.setString(string)
      
      if self.newString {
        self.sourceTextViewScrollLocation = 0
        self.overviewScroller?.regions     = []
      } else {
        self.sourceTextViewScrollLocation = scrollLocation
        
        let diffs = self.diffMatchPatch.diff_mainOfOldString(oldString, andNewString:string)
        self.overviewScroller?.regions = self._showDiffs(diffs, intensity:1)
      }
      
      self.newString = false
    }
  }
  
  private func _showDiffs(diffs:[AnyObject], intensity:CGFloat) -> [ALOverviewRegion]
  {
    let    textView    = self.fragaria.textView()
    let textStorage = textView.textStorage!
    
    if intensity == 0 {
      textStorage.removeAttribute(NSBackgroundColorAttributeName, range:NSMakeRange(0, textStorage.length))
      return []
    }
    
    var lineRanges = [ALOverviewRegion]();
    let saturation : CGFloat  = 0.5
    
    let insertColor = NSColor(calibratedHue:(1.0/3.0), saturation:saturation, brightness:1.0, alpha:intensity)
    let deleteColor = NSColor(calibratedHue:(0.0/3.0), saturation:saturation, brightness:1.0, alpha:intensity)
    let insertColor1 = NSColor(calibratedHue:(1.0/3.0), saturation:saturation, brightness:0.75, alpha:intensity)
    let deleteColor1 = NSColor(calibratedHue:(0.0/3.0), saturation:saturation, brightness:0.75, alpha:intensity)
    
    var index : String.Index = textStorage.string.startIndex
    var lineCount: Int = 0
    var offset  = 0
    
    for aDiff in diffs {
      if let diff = aDiff as? Diff {
        if diff.text.isEmpty {
          continue
        }
        
        //  let length = diff.text.length
        var lineSpan : Int = 0
        let length = distance(diff.text.startIndex,diff.text.endIndex)
        let nextIndex = advance(index, length)
        
        switch (diff.diffOperation) {
        case .Equal:
          lineSpan   = textStorage.string.lineCountForCharacterRange(index..<nextIndex)
          lineCount += lineSpan
          index = nextIndex
          offset += length
          
        case .Insert:
          lineSpan   = textStorage.string.lineCountForCharacterRange(index..<nextIndex)
          lineRanges.append(ALOverviewRegion(lineRange: NSMakeRange(lineCount, lineSpan), color: insertColor1))
          lineCount += lineSpan
          textStorage.addAttribute(NSBackgroundColorAttributeName, value:insertColor, range:NSMakeRange(offset, length))
          index = nextIndex
          offset += length
          break;
          
        case .Delete:
          lineRanges.append(ALOverviewRegion(lineRange: NSMakeRange(lineCount, 0), color: deleteColor1))
          if offset < textStorage.length {
            textStorage.addAttribute(NSBackgroundColorAttributeName, value:deleteColor, range:NSMakeRange(offset, 1))
          } else if offset > 0 {
            textStorage.addAttribute(NSBackgroundColorAttributeName, value:deleteColor, range:NSMakeRange(offset-1, 1))
          }
        }
      }
    }
    
    lineRanges.append(ALOverviewRegion(lineRange: NSMakeRange(lineCount, 0), color: nil))
    return lineRanges
  }
  
  @IBAction func changeLanguage(anItem:NSMenuItem)
  {
    if let language = anItem.representedObject as? ALLanguage {
      self.language = language
      language.saveToUserDefaults()
    }
  }
  
  override func validateMenuItem(anItem:NSMenuItem) -> Bool
  {
    if anItem.action == Selector("changeLanguage:") {
      if let language = anItem.representedObject as? ALLanguage {
        anItem.state = (self.language == language) ? NSOnState : NSOffState
      }
    }
    
    return true
  }
  
  func splitView(splitView: NSSplitView, constrainMaxCoordinate proposedMax: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat
  {
    return self.splitView!.frame.size.width - 370
  }
  
  func splitView(splitView: NSSplitView, constrainMinCoordinate proposedMin: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat
  {
    return 200
  }
  
}








































