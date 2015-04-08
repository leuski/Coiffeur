//
//  DocumentView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/7/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

@objc(ALDocumentView)
class ALDocumentView : NSViewController, NSPathControlDelegate {
  
  var allowedFileTypes = [String]()
  var knownSampleURLs = [NSURL]()
  @IBOutlet weak var containerView: NSView?
  
  private var windowController : ALMainWindowController? {
    return self.view.window?.delegate as? ALMainWindowController
  }
  
  func pathControl(pathControl: NSPathControl, willPopUpMenu menu: NSMenu)
  {
    menu.removeItemAtIndex(0)
    
    var index = 0
    for url in self.knownSampleURLs {
      var item = NSMenuItem(title: url.path!.lastPathComponent, action: Selector("openDocumentInView:"), keyEquivalent: "")
      item.representedObject = url;
      menu.insertItem(item, atIndex:index++)
    }
    
    var item = NSMenuItem(title: NSLocalizedString("Choose…", comment:"Choose…"), action: Selector("openDocumentInView:"), keyEquivalent: "")
    menu.insertItem(item, atIndex:index++)
  }
  
  func pathControl(pathControl: NSPathControl, validateDrop info: NSDraggingInfo) -> NSDragOperation
  {
    var count = 0;
    
    info.enumerateDraggingItemsWithOptions(NSDraggingItemEnumerationOptions(), forView:pathControl,
      classes:[NSURL.self], searchOptions:[:], usingBlock: {
        (draggingItem: NSDraggingItem!, idx:Int, stop: UnsafeMutablePointer<ObjCBool>) in
        if let url = self._allowedURLForDraggingItem(draggingItem) {
          ++count
        }
    })
    return count == 1 ? NSDragOperation.Every : NSDragOperation.None
  }
  
  private func _openDocumentWithURL(url:NSURL)
  {
    self.windowController?.loadSourceFormURL(url, error:nil)
  }
  
  private func _allowedURLForDraggingItem(draggingItem: NSDraggingItem) -> NSURL?
  {
    if let url  = draggingItem.item as? NSURL {
      if let type = NSDocumentController.sharedDocumentController().typeForContentsOfURL(url, error: nil) {
        if contains(self.allowedFileTypes, type) {
          return url
        }
      }
    }
    return nil
  }
  
  func pathControl(pathControl: NSPathControl, acceptDrop info: NSDraggingInfo) -> Bool
  {
    var theURL : NSURL? = nil
    
    info.enumerateDraggingItemsWithOptions(NSDraggingItemEnumerationOptions(), forView:pathControl,
      classes:[NSURL.self], searchOptions:[:], usingBlock: {
        (draggingItem: NSDraggingItem!, idx:Int, stop: UnsafeMutablePointer<ObjCBool>) in
        if let url = self._allowedURLForDraggingItem(draggingItem) {
          theURL = url;
          stop.memory = true
        }
    })
    
    if let url = theURL {
      self._openDocumentWithURL(url)
      return true
    }
    return false
  }
  
  @IBAction func openDocumentInView(sender : AnyObject)
  {
    if let url = sender.representedObject as? NSURL {
      self._openDocumentWithURL(url)
      return
    }
    
    var op = NSOpenPanel()
    
    if self.allowedFileTypes.count > 0 {
      op.allowedFileTypes = self.allowedFileTypes
    }
    
    op.allowsOtherFileTypes = false
    
    op.beginSheetModalForWindow(self.view.window!, completionHandler:{
      (result:NSModalResponse) in
      if (result == NSFileHandlingPanelOKButton) {
        self._openDocumentWithURL(op.URL!)
      }
    })
  }
  
  override func validateMenuItem(menuItem:NSMenuItem) -> Bool
  {
    return true
  }
  
}
