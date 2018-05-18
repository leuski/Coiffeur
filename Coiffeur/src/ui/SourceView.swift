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
	@objc dynamic var sourceString = ""
	@objc dynamic var language = Language.languageFromUserDefaults() {
		didSet {
			self.language.saveToUserDefaults()
			let fragariaName = self.language.fragariaID
			self.fragaria.setObject(fragariaName, forKey:MGSFOSyntaxDefinitionName)
		}
	}
	
	@objc dynamic var fileURL : URL? {
		didSet {
			if let url = self.fileURL {
				UserDefaults.standard.set(url,
					forKey: Private.LastSourceURLUDKey)
				if let uti = try? NSWorkspace.shared.type(ofFile: url.path),
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
				let diffs = self.diffMatchPatch.diff_main(ofOldString: oldString,
					andNewString:string)
				self.overviewScroller?.regions = self._showDiffs(diffs!, intensity:1)
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
			textView.scrollToVisible(visRect)
		}
	}

	fileprivate func _scrollLocation()
		-> (textView:NSTextView, visRect:NSRect, maxScrollLocaiton:CGFloat)
	{
		let textView: NSTextView     = self.fragaria.textView()
		let textStorage   = textView.textStorage!
		let layoutManager = textView.layoutManager!
		
		// first we need the document height.
		// textView lays text out lazily, so we cannot just use the textView frame
		// to get the height. It's not computed yet.

		layoutManager.ensureLayout(for: textView.textContainer!)

		// Here we are taking advantage of two assumptions:
		// 1. the text is not wrapping, so we only count hard line breaks
		let oldDocumentLineCount = textStorage.string.lineCount()
		
		// 2. the text is laid out in one font size, so the line height is constant
		let lineHeight = layoutManager.defaultLineHeight(for: textView.font!)
		
		let frameHeight = CGFloat(oldDocumentLineCount) * lineHeight
		let visRect = textView.visibleRect
		let maxScrollLocation = frameHeight - visRect.size.height
		
		//             NSLog("%f %f %f %f %f %ld", frameHeight, visRect.size.height,
		//                                      visRect.origin.y, maxScrollLocation,
		// relativeScrollLocation, textStorage.string.length)
		
		return (textView:textView, visRect:visRect,
			maxScrollLocaiton:maxScrollLocation)
	}
	
  override init(nibName nibNameOrNil: NSNib.Name? = NSNib.Name(rawValue: "SourceView"),
		bundle nibBundleOrNil: Bundle? = nil)
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
		self.fragaria.embed(in: self.containerView)
		
		let textView : NSTextView = self.fragaria.textView()
		textView.isEditable = false
		textView.textContainer!.widthTracksTextView = false
		textView.textContainer!.containerSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
		
		let       scrollView       = textView.enclosingScrollView!
		scrollView.verticalScroller = OverviewScroller(frame:NSMakeRect(0,0,0,0))
		scrollView.verticalScroller!.scrollerStyle = NSScroller.Style.legacy
	}
	
	fileprivate func _showDiffs(_ diffs:NSMutableArray, intensity:CGFloat)
		-> [OverviewRegion]
	{
		let textStorage = self.fragaria.textView().textStorage!
		
		textStorage.removeAttribute(NSAttributedStringKey.backgroundColor,
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
				
				if diff.diffOperation == .delete {
					lineRanges.append(OverviewRegion(firstLineIndex: lineCount,
						lineCount: 0, color: deleteColor1))
					if offset < textStorage.length {
						textStorage.addAttribute(NSAttributedStringKey.backgroundColor,
							value:deleteColor, range:NSMakeRange(offset, 1))
					} else if offset > 0 {
						textStorage.addAttribute(NSAttributedStringKey.backgroundColor,
							value:deleteColor, range:NSMakeRange(offset-1, 1))
					}
				} else {
					let length = diff.text.distance(from: diff.text.startIndex, to: diff.text.endIndex)
					let nextIndex = textStorage.string.index(index, offsetBy: length)
					let range = index..<nextIndex
					index = nextIndex
					let lineSpan   = textStorage.string.lineCountForCharacterRange(range)
					
					if diff.diffOperation == .insert {
						lineRanges.append(OverviewRegion(firstLineIndex: lineCount,
							lineCount: lineSpan, color: insertColor1))
						textStorage.addAttribute(NSAttributedStringKey.backgroundColor,
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
	
	func pathControl(_ pathControl: NSPathControl, willPopUp menu: NSMenu)
	{
		menu.removeItem(at: 0)
		
		var index = 0
		for url in self.knownSampleURLs {
			let item = NSMenuItem(title: url.lastPathComponent,
				action: #selector(SourceView.openDocumentInView(_:)), keyEquivalent: "")
			item.representedObject = url
			menu.insertItem(item, at:index)
      index += 1
		}
		
		let item = NSMenuItem(title: NSLocalizedString("Choose…", comment:""),
			action: #selector(SourceView.openDocumentInView(_:)), keyEquivalent: "")
		menu.insertItem(item, at:index)
    index += 1
	}
	
	func pathControl(_ pathControl: NSPathControl,
		validateDrop info: NSDraggingInfo) -> NSDragOperation
	{
		var count = 0
		
		info.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions(),
			for:pathControl,
			classes:[NSURL.self],
			searchOptions:[:],
			using: {
				(draggingItem: NSDraggingItem!, idx:Int,
					stop: UnsafeMutablePointer<ObjCBool>) in
				if let _ = self._allowedURLForItem(draggingItem) {
					count += 1
				}
		})
		return count == 1 ? NSDragOperation.every : NSDragOperation()
	}
	
	func pathControl(_ pathControl: NSPathControl,
		acceptDrop info: NSDraggingInfo) -> Bool
	{
		var theURL : URL? = nil
		
		info.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions(),
			for:pathControl,
			classes:[NSURL.self],
			searchOptions:[:],
			using: {
				(draggingItem: NSDraggingItem!, idx:Int,
					stop: UnsafeMutablePointer<ObjCBool>) in
				if let url = self._allowedURLForItem(draggingItem) {
					theURL = url
					stop.pointee = true
				}
		})
		
		if let url = theURL {
			self.tryLoadSourceFromURL(url)
			return true
		}
		return false
	}
	
	fileprivate func _allowedURLForItem(_ draggingItem: NSDraggingItem) -> URL?
	{
		let DC = NSDocumentController.shared
		if let url  = draggingItem.item as? URL,
			 let type = try? DC.typeForContents(of: url)
		{
			if self.allowedFileTypes.contains(type) {
				return url
			}
		}
		return nil
	}
	
}

extension SourceView {
	
	fileprivate struct Private {
		static let LastSourceURLUDKey    = "LastSourceURL"
		static let SamplesFolderName     = "samples"
		static let SampleFileName        = "sample"
		static let ObjectiveCPPExtension = "mm"
	}
	
	func loadSourceFromURL(_ url:URL) throws
	{
		let source = try String(contentsOf:url, encoding:String.Encoding.utf8)
		self.sourceString = source
		self.fileURL = url
	}

  @discardableResult
	func tryLoadSourceFromURL(_ url:URL) -> Bool
	{
		do {
			try loadSourceFromURL(url)
			return true
		} catch _ {
			return false
		}
	}
	
	@IBAction func openDocumentInView(_ sender : AnyObject)
	{
		if let url = sender.representedObject as? URL {
			tryLoadSourceFromURL(url)
			return
		}
		
		let op = NSOpenPanel()
		
		if self.allowedFileTypes.count > 0 {
			op.allowedFileTypes = self.allowedFileTypes
		}
		
		op.allowsOtherFileTypes = false
		
		op.beginSheetModal(for: self.view.window!, completionHandler:
		{ (result:NSApplication.ModalResponse) in
			if (result.rawValue == NSFileHandlingPanelOKButton) {
				self.tryLoadSourceFromURL(op.url!)
			}
		})
	}
	
	override func validateMenuItem(_ menuItem:NSMenuItem) -> Bool
	{
		return true
	}
	
	fileprivate func _restoreSource()
	{
		let UD = UserDefaults.standard
		if let lastURL = UD.url(forKey: Private.LastSourceURLUDKey) {
			if self.tryLoadSourceFromURL(lastURL) {
				return
			}
		}
		
		let url = Bundle.main.url(forResource: Private.SampleFileName,
			withExtension:Private.ObjectiveCPPExtension,
			subdirectory:Private.SamplesFolderName)!
		
		if !self.tryLoadSourceFromURL(url) {
			NSException(name: NSExceptionName(rawValue: "No Source"),
				reason: "Failed to load the sample source file",
				userInfo: nil).raise()
		}
	}
	
	fileprivate class func _knownSampleURLs() -> [URL]
	{
		let resourcesURL = Bundle.main.resourceURL!
		let baseURL = resourcesURL.appendingPathComponent(
			Private.SamplesFolderName)
		let fm = FileManager.default
		// TODO
		if let urls = try? fm.contentsOfDirectory(at: baseURL,
			includingPropertiesForKeys:nil,
			options:FileManager.DirectoryEnumerationOptions.skipsHiddenFiles) {
				return urls 
		}
		return []
	}
}

extension SourceView : CoiffeurControllerDelegate {

	func coiffeurControllerArguments(_ controller: CoiffeurController)
		-> CoiffeurController.Arguments
	{
		return CoiffeurController.Arguments(self.sourceString,
			language:self.language)
	}
	
	func coiffeurController(_ coiffeurController:CoiffeurController,
		setText text:String)
	{
		let UD = UserDefaults.standard
		var pageGuideColumn = coiffeurController.pageGuideColumn
		if UD.bool(forKey: "CoiffeurOverwritePageGuide") {
			pageGuideColumn = UD.integer(forKey: "CoiffeurOverwritePageGuideValue")
		}
		UD.set(pageGuideColumn,
			forKey: MGSFragariaPrefsShowPageGuideAtColumn)
		UD.set(pageGuideColumn != 0, forKey: MGSFragariaPrefsShowPageGuide)
		self.string = text
	}

}
