//
//  SourceView.swift
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

class SourceView: NSViewController {
  
	// model-related properties
	dynamic var sourceString = ""
	dynamic var language = Language.languageFromUserDefaults() {
		didSet {
			self.language.saveToUserDefaults()
			let fragariaName = self.language.fragariaID
			self.fragaria.setObject(fragariaName, forKey:MGSFOSyntaxDefinitionName)
		}
	}
	
	dynamic var fileURL : NSURL? {
		didSet {
			if let url = self.fileURL {
				NSUserDefaults.standardUserDefaults().setURL(url,
					forKey: Private.LastSourceURLUDKey)
				if let uti = try? NSWorkspace.sharedWorkspace().typeOfFile(url.path!),
					 let lang = Language.languageWithUTI(uti)
				{
					self.language = lang
				}
			}
		}
	}

	var allowedFileTypes = Language.supportedLanguageUTIs
	var knownSampleURLs = SourceView._knownSampleURLs()

	// view-related properties
	typealias ScrollLocation = CGFloat
	
	@IBOutlet weak var containerView: NSView!

	var fragaria : MGSFragaria
	var diffMatchPatch : DiffMatchPatch
	
	var overviewScroller : OverviewScroller? {
		return self.fragaria.textView().enclosingScrollView?.verticalScroller
			as? OverviewScroller
	}

	var string:String {
		get {
			return self.fragaria.string()
		}
		set (string) {
			let oldString : String = self.fragaria.string()
			let scrollLocation = self.sourceTextViewScrollLocation
			
			self.fragaria.setString(string)
			
			if string.isEmpty || oldString.isEmpty {
				self.sourceTextViewScrollLocation = 0
				self.overviewScroller?.regions = []
			} else {
				self.sourceTextViewScrollLocation = scrollLocation
				let diffs = self.diffMatchPatch.diff_mainOfOldString(oldString,
					andNewString:string)
				self.overviewScroller?.regions = self._showDiffs(diffs, intensity:1)
			}
		}
	}

	var sourceTextViewScrollLocation : ScrollLocation {
		get {
			// we will try and preserve visible frame position in the source document
			// across changes.
			let (_, visRect, maxScrollLocation) = _scrollLocation()
			let relativeScrollLocation = (maxScrollLocation > 0)
				? visRect.origin.y / maxScrollLocation
				: 0
			return relativeScrollLocation
		}
		set (relativeScrollLocation) {
			var (textView, visRect, maxScrollLocation) = _scrollLocation()
			visRect.origin.y = round(relativeScrollLocation * maxScrollLocation)
			visRect.origin.x = 0
			textView.scrollRectToVisible(visRect)
		}
	}

	private func _scrollLocation()
		-> (textView:NSTextView, visRect:NSRect, maxScrollLocaiton:CGFloat)
	{
		let textView: NSTextView     = self.fragaria.textView()
		let textStorage   = textView.textStorage!
		let layoutManager = textView.layoutManager!
		
		// first we need the document height.
		// textView lays text out lazily, so we cannot just use the textView frame
		// to get the height. It's not computed yet.

		layoutManager.ensureLayoutForTextContainer(textView.textContainer!)

		// Here we are taking advantage of two assumptions:
		// 1. the text is not wrapping, so we only count hard line breaks
		let oldDocumentLineCount = textStorage.string.lineCount()
		
		// 2. the text is laid out in one font size, so the line height is constant
		let lineHeight = layoutManager.defaultLineHeightForFont(textView.font!)
		
		let frameHeight = CGFloat(oldDocumentLineCount) * lineHeight
		let visRect = textView.visibleRect
		let maxScrollLocation = frameHeight - visRect.size.height
		
		//             NSLog("%f %f %f %f %f %ld", frameHeight, visRect.size.height,
		//                                      visRect.origin.y, maxScrollLocation,
		// relativeScrollLocation, textStorage.string.length)
		
		return (textView:textView, visRect:visRect,
			maxScrollLocaiton:maxScrollLocation)
	}
	
	override init?(nibName nibNameOrNil: String? = "SourceView",
		bundle nibBundleOrNil: NSBundle? = nil)
	{
		self.diffMatchPatch = DiffMatchPatch()
		self.fragaria       = MGSFragaria()
		super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
		_restoreSource()
	}
	
	required init?(coder: NSCoder)
	{
		self.diffMatchPatch = DiffMatchPatch()
		self.fragaria       = MGSFragaria()
		super.init(coder:coder)
		_restoreSource()
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		// we want to be the delegate
		self.fragaria.embedInView(self.containerView)
		
		let textView : NSTextView = self.fragaria.textView()
		textView.editable = false
		textView.textContainer!.widthTracksTextView = false
		textView.textContainer!.containerSize = NSMakeSize(CGFloat.max, CGFloat.max)
		
		let       scrollView       = textView.enclosingScrollView!
		scrollView.verticalScroller = OverviewScroller(frame:NSMakeRect(0,0,0,0))
		scrollView.verticalScroller!.scrollerStyle = NSScrollerStyle.Legacy
	}
	
	private func _showDiffs(diffs:NSMutableArray, intensity:CGFloat)
		-> [OverviewRegion]
	{
		let textStorage = self.fragaria.textView().textStorage!
		
		textStorage.removeAttribute(NSBackgroundColorAttributeName,
			range:NSMakeRange(0, textStorage.length))
		
		if intensity == 0 {
			return []
		}
		
		var lineRanges = [OverviewRegion]()
		let saturation : CGFloat  = 0.5
		let insertHue : CGFloat = 1.0 / 3.0
		let deleteHue : CGFloat = 0.0 / 3.0
		let textViewBrightness : CGFloat = 1.0
		let scrollerBrightness : CGFloat = 0.75
		
		let insertColor = NSColor(calibratedHue:insertHue, saturation:saturation,
			brightness:textViewBrightness, alpha:intensity)
		let deleteColor = NSColor(calibratedHue:deleteHue, saturation:saturation,
			brightness:textViewBrightness, alpha:intensity)
		let insertColor1 = NSColor(calibratedHue:insertHue, saturation:saturation,
			brightness:scrollerBrightness, alpha:intensity)
		let deleteColor1 = NSColor(calibratedHue:deleteHue, saturation:saturation,
			brightness:scrollerBrightness, alpha:intensity)
		
		var index : String.Index = textStorage.string.startIndex
		var lineCount: Int = 0
		var offset  = 0
		
		for aDiff in diffs {
			if let diff = aDiff as? Diff {
				if diff.text.isEmpty {
					continue
				}
				
				if diff.diffOperation == .Delete {
					lineRanges.append(OverviewRegion(firstLineIndex: lineCount,
						lineCount: 0, color: deleteColor1))
					if offset < textStorage.length {
						textStorage.addAttribute(NSBackgroundColorAttributeName,
							value:deleteColor, range:NSMakeRange(offset, 1))
					} else if offset > 0 {
						textStorage.addAttribute(NSBackgroundColorAttributeName,
							value:deleteColor, range:NSMakeRange(offset-1, 1))
					}
				} else {
					let length = diff.text.startIndex.distanceTo(diff.text.endIndex)
					let nextIndex = index.advancedBy(length)
					let range = index..<nextIndex
					index = nextIndex
					let lineSpan   = textStorage.string.lineCountForCharacterRange(range)
					
					if diff.diffOperation == .Insert {
						lineRanges.append(OverviewRegion(firstLineIndex: lineCount,
							lineCount: lineSpan, color: insertColor1))
						textStorage.addAttribute(NSBackgroundColorAttributeName,
							value:insertColor, range:NSMakeRange(offset, length))
					}
					
					lineCount += lineSpan
					offset += length
				}
			}
		}
		
		lineRanges.append(OverviewRegion(firstLineIndex: lineCount,
			lineCount: 0, color: nil))
		return lineRanges
	}

}

extension SourceView : NSPathControlDelegate {
	
	func pathControl(pathControl: NSPathControl, willPopUpMenu menu: NSMenu)
	{
		menu.removeItemAtIndex(0)
		
		var index = 0
		for url in self.knownSampleURLs {
			let item = NSMenuItem(title: url.lastPathComponent!,
				action: "openDocumentInView:", keyEquivalent: "")
			item.representedObject = url
			menu.insertItem(item, atIndex:index++)
		}
		
		let item = NSMenuItem(title: NSLocalizedString("Choose…", comment:""),
			action: "openDocumentInView:", keyEquivalent: "")
		menu.insertItem(item, atIndex:index++)
	}
	
	func pathControl(pathControl: NSPathControl,
		validateDrop info: NSDraggingInfo) -> NSDragOperation
	{
		var count = 0
		
		info.enumerateDraggingItemsWithOptions(NSDraggingItemEnumerationOptions(),
			forView:pathControl,
			classes:[NSURL.self],
			searchOptions:[:],
			usingBlock: {
				(draggingItem: NSDraggingItem!, idx:Int,
					stop: UnsafeMutablePointer<ObjCBool>) in
				if let _ = self._allowedURLForItem(draggingItem) {
					++count
				}
		})
		return count == 1 ? NSDragOperation.Every : NSDragOperation.None
	}
	
	func pathControl(pathControl: NSPathControl,
		acceptDrop info: NSDraggingInfo) -> Bool
	{
		var theURL : NSURL? = nil
		
		info.enumerateDraggingItemsWithOptions(NSDraggingItemEnumerationOptions(),
			forView:pathControl,
			classes:[NSURL.self],
			searchOptions:[:],
			usingBlock: {
				(draggingItem: NSDraggingItem!, idx:Int,
					stop: UnsafeMutablePointer<ObjCBool>) in
				if let url = self._allowedURLForItem(draggingItem) {
					theURL = url
					stop.memory = true
				}
		})
		
		if let url = theURL {
			self.tryLoadSourceFromURL(url)
			return true
		}
		return false
	}
	
	private func _allowedURLForItem(draggingItem: NSDraggingItem) -> NSURL?
	{
		let DC = NSDocumentController.sharedDocumentController()
		if let url  = draggingItem.item as? NSURL,
			 let type = try? DC.typeForContentsOfURL(url)
		{
			if self.allowedFileTypes.contains(type) {
				return url
			}
		}
		return nil
	}
	
}

extension SourceView {
	
	private struct Private {
		static let LastSourceURLUDKey    = "LastSourceURL"
		static let SamplesFolderName     = "samples"
		static let SampleFileName        = "sample"
		static let ObjectiveCPPExtension = "mm"
	}
	
	func loadSourceFromURL(url:NSURL) throws
	{
		let source = try String(contentsOfURL:url, encoding:NSUTF8StringEncoding)
		self.sourceString = source
		self.fileURL = url
	}

	func tryLoadSourceFromURL(url:NSURL) -> Bool
	{
		do {
			try loadSourceFromURL(url)
			return true
		} catch _ {
			return false
		}
	}
	
	@IBAction func openDocumentInView(sender : AnyObject)
	{
		if let url = sender.representedObject as? NSURL {
			tryLoadSourceFromURL(url)
			return
		}
		
		let op = NSOpenPanel()
		
		if self.allowedFileTypes.count > 0 {
			op.allowedFileTypes = self.allowedFileTypes
		}
		
		op.allowsOtherFileTypes = false
		
		op.beginSheetModalForWindow(self.view.window!, completionHandler:
		{ (result:NSModalResponse) in
			if (result == NSFileHandlingPanelOKButton) {
				self.tryLoadSourceFromURL(op.URL!)
			}
		})
	}
	
	override func validateMenuItem(menuItem:NSMenuItem) -> Bool
	{
		return true
	}
	
	private func _restoreSource()
	{
		let UD = NSUserDefaults.standardUserDefaults()
		if let lastURL = UD.URLForKey(Private.LastSourceURLUDKey) {
			if self.tryLoadSourceFromURL(lastURL) {
				return
			}
		}
		
		let url = NSBundle.mainBundle().URLForResource(Private.SampleFileName,
			withExtension:Private.ObjectiveCPPExtension,
			subdirectory:Private.SamplesFolderName)!
		
		if !self.tryLoadSourceFromURL(url) {
			NSException(name: "No Source",
				reason: "Failed to load the sample source file",
				userInfo: nil).raise()
		}
	}
	
	private class func _knownSampleURLs() -> [NSURL]
	{
		let resourcesURL = NSBundle.mainBundle().resourceURL!
		let baseURL = resourcesURL.URLByAppendingPathComponent(
			Private.SamplesFolderName)
		let fm = NSFileManager.defaultManager()
		// TODO
		if let urls = try? fm.contentsOfDirectoryAtURL(baseURL,
			includingPropertiesForKeys:nil,
			options:NSDirectoryEnumerationOptions.SkipsHiddenFiles) {
				return urls 
		}
		return []
	}
}

extension SourceView : CoiffeurControllerDelegate {

	func coiffeurControllerArguments(controller: CoiffeurController)
		-> CoiffeurController.Arguments
	{
		return CoiffeurController.Arguments(self.sourceString,
			language:self.language)
	}
	
	func coiffeurController(coiffeurController:CoiffeurController,
		setText text:String)
	{
		let UD = NSUserDefaults.standardUserDefaults()
		var pageGuideColumn = coiffeurController.pageGuideColumn
		if UD.boolForKey("CoiffeurOverwritePageGuide") {
			pageGuideColumn = UD.integerForKey("CoiffeurOverwritePageGuideValue")
		}
		UD.setInteger(pageGuideColumn,
			forKey: MGSFragariaPrefsShowPageGuideAtColumn)
		UD.setBool(pageGuideColumn != 0, forKey: MGSFragariaPrefsShowPageGuide)
		self.string = text
	}

}
