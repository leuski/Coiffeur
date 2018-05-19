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

class MainWindowController: NSWindowController {

  @IBOutlet weak var splitView: NSSplitView!
  var sourceView: SourceView!
  var styleView: CoiffeurView!

  private var observers = [NSKeyValueObservation]()

  override init(window: NSWindow?)
  {
    super.init(window: window)
  }

  required init?(coder: NSCoder)
  {
    fatalError("init(coder:) has not been implemented")
  }

  convenience init()
  {
    self.init(windowNibName: NSNib.Name(rawValue: "MainWindowController"))
  }

  override func windowDidLoad()
  {
    super.windowDidLoad()

    self.sourceView = SourceView()
    self.splitView.addSubview(self.sourceView.view)

    observers.append(sourceView.observe(\.language, options: []) {
      [weak self] _, _ in self?.uncrustify()
    })
    observers.append(sourceView.observe(\.sourceString, options: [.initial]) {
      [weak self] _, _ in self?.uncrustify()
    })
    observers.append(observe(
      \MainWindowController.document, options: [.new, .initial, .old])
    {
      [weak self] _, change in self?.handleDocumentChange(change)
    })
  }

  private func handleDocumentChange<T>(_ change: NSKeyValueObservedChange<T>) {
    if let oldValue = change.oldValue, nil != oldValue as? Document {
      if styleView != nil {
        styleView.view.removeFromSuperviewWithoutNeedingDisplay()
        styleView = nil
      }
    }

    if
      let newValue = change.newValue,
      let newDocument = newValue as? Document
    {
      styleView = CoiffeurView()
      splitView.subviews.insert(styleView.view, at: 0)
      window?.initialFirstResponder = styleView.optionsView
      styleView.representedObject = newDocument.model!
      newDocument.model!.delegate = sourceView
    }

    self.uncrustify()
  }

  @IBAction func uncrustify(_ sender: AnyObject? = nil)
  {
    if let model = (self.document as? Document)?.model {
      model.format()
    }
  }

  @IBAction func changeLanguage(_ anItem: NSMenuItem)
  {
    if let language = anItem.representedObject as? Language {
      self.sourceView.language = language
    }
  }

  override func validateMenuItem(_ anItem: NSMenuItem) -> Bool
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

extension MainWindowController: NSWindowDelegate
{
  func windowWillClose(_ notification: Notification)
  {
    self.sourceView.representedObject = nil
    self.sourceView = nil
    self.styleView.representedObject = nil
    self.styleView = nil
  }

  func windowWillUseStandardFrame(
    _ window: NSWindow,
    defaultFrame newFrame: NSRect) -> NSRect
  {
    var frame = newFrame
    let target: NSWindow.CollectionBehavior =
      [.fullScreenPrimary, .fullScreenAuxiliary]
    if self.window!.collectionBehavior.isDisjoint(with: target) {
      frame.size.width = min(frame.size.width, 1200)
    }
    return frame
  }
}

extension MainWindowController: NSSplitViewDelegate
{
  func splitView(
    _ splitView: NSSplitView,
    constrainMaxCoordinate proposedMax: CGFloat,
    ofSubviewAt dividerIndex: Int) -> CGFloat
  {
    return self.splitView.frame.size.width - 370
  }

  func splitView(
    _ splitView: NSSplitView,
    constrainMinCoordinate proposedMin: CGFloat,
    ofSubviewAt dividerIndex: Int) -> CGFloat
  {
    return 200
  }
}
