//
//  MainWindowController.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

class MainWindowController : NSWindowController, NSWindowDelegate,
	NSSplitViewDelegate {
  
  @IBOutlet weak var splitView : NSSplitView!
  var sourceView: SourceView!
  var styleView: CoiffeurView!
	
  override var document: AnyObject? {
    didSet (oldDocument) {
			
			if oldDocument != nil && self.styleView != nil {
				self.styleView.view.removeFromSuperviewWithoutNeedingDisplay()
				self.styleView = nil
      }
      
      if var d = self.styleDocument {
				self.styleView = CoiffeurView()
				self.splitView.subviews.insert(self.styleView.view, atIndex: 0)
				self.window?.initialFirstResponder = self.styleView.optionsView
				self.styleView.representedObject = d.model!
				d.model!.delegate = self.sourceView
      }
      
      self.uncrustify()
    }
  }
  
  var styleDocument : Document? {
    return self.document as? Document
  }
  
  override init(window:NSWindow?)
  {
    super.init(window:window)
  }
  
  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }
  
  convenience init()
  {
    self.init(windowNibName:"MainWindowController")
    let x = self.window
  }
  
  @IBAction func uncrustify(_ sender : AnyObject? = nil)
  {
    if let m = self.styleDocument?.model {
      m.format()
    }
  }
  
  override func windowDidLoad()
  {
    super.windowDidLoad()
    
    self.sourceView = SourceView()
		self.splitView.addSubview(self.sourceView.view)

		let uncrustify : BlockObserver = { _, _ in self.uncrustify() }
		self.sourceView.addObserverForKeyPath("language", observer:uncrustify)
		self.sourceView.addObserverForKeyPath("sourceString", options: .Initial, observer:uncrustify)
	}
	
  func windowWillClose(notification:NSNotification)
  {
		self.sourceView.representedObject = nil
		self.sourceView = nil
		self.styleView.representedObject = nil
		self.styleView = nil
  }
	
  @IBAction func changeLanguage(anItem:NSMenuItem)
  {
    if let language = anItem.representedObject as? Language {
      self.sourceView.language = language
    }
  }
  
  override func validateMenuItem(anItem:NSMenuItem) -> Bool
  {
    if anItem.action == Selector("changeLanguage:") {
      if let language = anItem.representedObject as? Language {
        anItem.state = (self.sourceView.language == language) ? NSOnState : NSOffState
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








































