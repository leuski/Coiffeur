//
//  MainWindowController.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

class MainWindowController : NSWindowController, NSOutlineViewDelegate,
  NSWindowDelegate, CoiffeurControllerDelegate, NSSplitViewDelegate {
  
  typealias ScrollLocation = CGFloat
  
  @IBOutlet weak var splitView : NSSplitView!
  var sourceView: SourceView!
  var styleView: CoiffeurView!
  var fragaria : MGSFragaria
  var codeString : String = ""
  var newString : Bool = false
  
  var sourceTextViewScrollLocation : ScrollLocation {
    get {
      // we will try and preserve visible frame position in the document
      // across changes.
      
      let textView : NSTextView     = self.fragaria.textView()
      let textStorage   = textView.textStorage!
      let layoutManager = textView.layoutManager!
      
      // first we need the document height.
      // textView lays text out lazily, so we cannot just use the textView frame
      // to get the height. It's not computed yet.
      
      // Here we are taking advantage of two assumptions:
      // 1. the text is not wrapping, so we only count hard line breaks
      let oldDocumentLineCount = textStorage.string.lineCount()
      
      // 2. the text is laid out in one font size, so the line height is constant
      let lineHeight        = layoutManager.defaultLineHeightForFont(textView.font!)
      
      let frameHeight       = CGFloat(oldDocumentLineCount) * lineHeight
      let  visRect           = textView.visibleRect
      let maxScrollLocation = frameHeight - visRect.size.height
      let relativeScrollLocation = (maxScrollLocation > 0) ? visRect.origin.y / maxScrollLocation : 0
      
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
      
      let newDocumentLineCount = textStorage.string.lineCount()
      
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
  weak var overviewScroller : OverviewScroller!
  
  var language : Language {
    didSet {
      let fragariaName = language.fragariaID
      self.fragaria.setObject(fragariaName, forKey:MGSFOSyntaxDefinitionName)
      self.uncrustify(nil)
    }
  }
  
  var fileURL : NSURL? {
    didSet {
      if let url = self.fileURL {
        NSUserDefaults.standardUserDefaults().setURL(url, forKey: LastSourceURLUDKey)
        if let uti = NSWorkspace.sharedWorkspace().typeOfFile(url.path!, error:nil), let lang = Language.languageWithUTI(uti) {
          self.language = lang
        }
      }
    }
  }
  
  override var document: AnyObject? {
    didSet (oldDocument) {
      let containerView = self.splitView.subviews[0] as! NSView
      
      if oldDocument != nil {
        // lets see if die here. need a copy of the subview list
        for v in containerView.subviews {
          v.removeFromSuperviewWithoutNeedingDisplay()
        }
      }
      
      if var d = self.styleDocument, let v = CoiffeurView(model:d.model!, bundle:nil) {
          self.styleView = v
          v.embedInView(containerView)
          d.model!.delegate = self
      }
      
      self.uncrustify(nil)
    }
  }
  
  var styleDocument : Document? {
    return self.document as? Document
  }
  
  var sourceDocument : MainWindowController? {
    return self
  }
  
  var string:String {
    get {
      return self.codeString
    }
    set (string){
      let oldString : String = self.fragaria.string()
      let scrollLocation = self.sourceTextViewScrollLocation
      
      self.fragaria.setString(string)
      
      if self.newString {
        self.sourceTextViewScrollLocation = 0
        self.overviewScroller.regions     = []
      } else {
        self.sourceTextViewScrollLocation = scrollLocation
        
        let diffs = self.diffMatchPatch.diff_mainOfOldString(oldString, andNewString:string)
        self.overviewScroller.regions = self._showDiffs(diffs, intensity:1)
      }
      
      self.newString = false
    }
  }

  private let LastSourceURLUDKey    = "LastSourceURL"
  private let SamplesFolderName     = "samples"
  private let SampleFileName        = "sample"
  private let ObjectiveCPPExtension = "mm"
  
  override init(window:NSWindow?)
  {
    self.diffMatchPatch = DiffMatchPatch()
    self.fragaria       = MGSFragaria()
    self.language       = Language.languageFromUserDefaults()
    super.init(window:window)
  }
  
  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }
  
  convenience init()
  {
    self.init(windowNibName:"MainWindowController")
    self._restoreSource()
    let x = self.window
  }
  
  @IBAction func uncrustify(sender : AnyObject?)
  {
    if let m = self.styleDocument?.model {
      m.format()
    }
  }
  
  func formatArgumentsForCoiffeurController(controller:CoiffeurController) -> (text:String, attributes: NSDictionary)
  {
    if let source = self.sourceDocument {
      return (text:source.string, attributes:[CoiffeurController.FormatLanguage:source.language,
        CoiffeurController.FormatFragment:NSNumber(bool:false)])
    } else {
      return (text:"", attributes: [:])
    }
  }
  
  func coiffeurController(coiffeurController:CoiffeurController, setText text:String)
  {
    if var source = self.sourceDocument {
      NSUserDefaults.standardUserDefaults().setInteger(coiffeurController.pageGuideColumn, forKey: MGSFragariaPrefsShowPageGuideAtColumn)
      NSUserDefaults.standardUserDefaults().setBool(coiffeurController.pageGuideColumn != 0, forKey: MGSFragariaPrefsShowPageGuide)
      source.string = text
    }
  }
  
  private func _restoreSource()
  {
    if let lastURL = NSUserDefaults.standardUserDefaults().URLForKey(LastSourceURLUDKey) {
      if self.loadSourceFormURL(lastURL, error:nil) {
        return
      }
    }
    
    let url = NSBundle.mainBundle().URLForResource(SampleFileName,
      withExtension:ObjectiveCPPExtension, subdirectory:SamplesFolderName)!
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
    
    self.sourceView = SourceView(nibName:"SourceView", bundle:nil)

    var types = Set<String>()
    for  l in Language.supportedLanguages {
      types.unionInPlace(l.UTIs)
    }
    self.sourceView.allowedFileTypes  = [String](types)
    self.sourceView.representedObject = self
    
    let resourcesURL = NSBundle.mainBundle().resourceURL!
    let baseURL      = resourcesURL.URLByAppendingPathComponent(SamplesFolderName)
    let fm           = NSFileManager.defaultManager()
    
    if let urls = fm.contentsOfDirectoryAtURL(baseURL, includingPropertiesForKeys:nil,
      options:NSDirectoryEnumerationOptions.SkipsHiddenFiles, error:nil) {
        self.sourceView.knownSampleURLs = urls as! [NSURL]
    }
    
    self.splitView.replaceSubview(self.splitView.subviews[1] as! NSView, with:self.sourceView.view)
    
    // we want to be the delegate
    self.fragaria.setObject(self, forKey:MGSFODelegate)
    self.fragaria.embedInView(self.sourceView.containerView)
    
    let textView : NSTextView = self.fragaria.textView()
    textView.editable = false
    textView.textContainer!.widthTracksTextView = false
    textView.textContainer!.containerSize       = NSMakeSize(CGFloat.max, CGFloat.max)
    
    let       scrollView       = textView.enclosingScrollView!
    let overviewScroller = OverviewScroller(frame:NSMakeRect(0,0,0,0))
    self.overviewScroller       = overviewScroller
    scrollView.verticalScroller = overviewScroller
    scrollView.verticalScroller!.scrollerStyle = NSScrollerStyle.Legacy
  }
  
  func windowWillClose(notification:NSNotification)
  {
    self.sourceView.representedObject = nil
  }
  
  private func _showDiffs(diffs:NSMutableArray, intensity:CGFloat) -> [OverviewRegion]
  {
    let    textView    = self.fragaria.textView()
    let textStorage = textView.textStorage!
    
    if intensity == 0 {
      textStorage.removeAttribute(NSBackgroundColorAttributeName, range:NSMakeRange(0, textStorage.length))
      return []
    }
    
    var lineRanges = [OverviewRegion]();
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
          lineRanges.append(OverviewRegion(lineRange: NSMakeRange(lineCount, lineSpan), color: insertColor1))
          lineCount += lineSpan
          textStorage.addAttribute(NSBackgroundColorAttributeName, value:insertColor, range:NSMakeRange(offset, length))
          index = nextIndex
          offset += length
          break;
          
        case .Delete:
          lineRanges.append(OverviewRegion(lineRange: NSMakeRange(lineCount, 0), color: deleteColor1))
          if offset < textStorage.length {
            textStorage.addAttribute(NSBackgroundColorAttributeName, value:deleteColor, range:NSMakeRange(offset, 1))
          } else if offset > 0 {
            textStorage.addAttribute(NSBackgroundColorAttributeName, value:deleteColor, range:NSMakeRange(offset-1, 1))
          }
        }
      }
    }
    
    lineRanges.append(OverviewRegion(lineRange: NSMakeRange(lineCount, 0), color: nil))
    return lineRanges
  }
  
  @IBAction func changeLanguage(anItem:NSMenuItem)
  {
    if let language = anItem.representedObject as? Language {
      self.language = language
      language.saveToUserDefaults()
    }
  }
  
  override func validateMenuItem(anItem:NSMenuItem) -> Bool
  {
    if anItem.action == Selector("changeLanguage:") {
      if let language = anItem.representedObject as? Language {
        anItem.state = (self.language == language) ? NSOnState : NSOffState
      }
    }
    
    return true
  }
  
  func splitView(splitView: NSSplitView, constrainMaxCoordinate proposedMax: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat
  {
    return self.splitView.frame.size.width - 370
  }
  
  func splitView(splitView: NSSplitView, constrainMinCoordinate proposedMin: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat
  {
    return 200
  }
  
}








































