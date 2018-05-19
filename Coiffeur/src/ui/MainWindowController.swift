//
//  MainWindowController.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
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

import Cocoa

class MainWindowController : NSWindowController {
  
  @IBOutlet weak var splitView : NSSplitView!
  var sourceView: SourceView!
  var styleView: CoiffeurView!
	
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
    self.init(windowNibName:NSNib.Name(rawValue: "MainWindowController"))
  }
	
  override func windowDidLoad()
  {
    super.windowDidLoad()
    
    self.sourceView = SourceView()
		self.splitView.addSubview(self.sourceView.view)

		let uncrustify : BlockObserver = { _, _ in self.uncrustify() }
		self.sourceView.addObserverForKeyPath("language", observer:uncrustify)
		self.sourceView.addObserverForKeyPath("sourceString",
			options: .initial, observer:uncrustify)
		
		self.addObserverForKeyPath("document", options: [.new, .initial, .old]) {
			(_, change:[AnyHashable: Any]) in

			if let _ = change[NSKeyValueChangeKey.oldKey] as? Document {
				if self.styleView != nil {
					self.styleView.view.removeFromSuperviewWithoutNeedingDisplay()
					self.styleView = nil
				}
			}
			
			if let newDocument = change[NSKeyValueChangeKey.newKey] as? Document  {
				self.styleView = CoiffeurView()
				self.splitView.subviews.insert(self.styleView.view, at: 0)
				self.window?.initialFirstResponder = self.styleView.optionsView
				self.styleView.representedObject = newDocument.model!
				newDocument.model!.delegate = self.sourceView
			}
			
			self.uncrustify()
		}
	}
	
	@IBAction func uncrustify(_ sender : AnyObject? = nil)
	{
		if let model = (self.document as? Document)?.model {
			model.format()
		}
	}
	
  @IBAction func changeLanguage(_ anItem:NSMenuItem)
  {
    if let language = anItem.representedObject as? Language {
      self.sourceView.language = language
    }
  }
  
  override func validateMenuItem(_ anItem:NSMenuItem) -> Bool
  {
    if anItem.action == #selector(MainWindowController.changeLanguage(_:)) {
      if let language = anItem.representedObject as? Language {
        anItem.state = (self.sourceView.language == language)
					? .on : .off
      }
    }
    
    return true
  }
}

extension MainWindowController : NSWindowDelegate
{
	func windowWillClose(_ notification:Notification)
	{
		self.removeAllObservers()
		self.sourceView.removeAllObservers()
		self.sourceView.representedObject = nil
		self.sourceView = nil
		self.styleView.representedObject = nil
		self.styleView = nil
	}
	
	func windowWillUseStandardFrame(_ window: NSWindow,
		defaultFrame newFrame: NSRect) -> NSRect
	{
		var frame = newFrame
		if (self.window!.collectionBehavior.intersection((NSWindow.CollectionBehavior.fullScreenPrimary.union(NSWindow.CollectionBehavior.fullScreenAuxiliary)))).rawValue == 0
		{
			frame.size.width = min(frame.size.width, 1200)
		}
		return frame
	}
}

extension MainWindowController : NSSplitViewDelegate
{
  func splitView(_ splitView: NSSplitView,
		constrainMaxCoordinate proposedMax: CGFloat,
		ofSubviewAt dividerIndex: Int) -> CGFloat
  {
    return self.splitView.frame.size.width - 370
  }
  
  func splitView(_ splitView: NSSplitView,
		constrainMinCoordinate proposedMin: CGFloat,
		ofSubviewAt dividerIndex: Int) -> CGFloat
  {
    return 200
  }
}








































