//
//  ALMainWindowController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALMainWindowController.h"

#import <MGSFragaria/MGSFragaria.h>

#import "NSString+commandLine.h"
#import "ALDocumentView.h"
#import "AppDelegate.h"

#import "Document.h"
#import "ALCodeDocument.h"
#import "ALUncrustifyController.h"

@interface ALMainWindowController () <NSWindowDelegate, ALCoiffeurControllerDelegate, ALCodeDocument, NSSplitViewDelegate>

@property (nonatomic, weak) IBOutlet NSSplitView* splitView;
@property (nonatomic, strong) ALDocumentView* documentView;
@property (nonatomic, strong) MGSFragaria* fragaria;
@property (nonatomic, strong) NSString* codeString;
@end

static NSString * const ALLastSourceURL = @"ALLastSourceURL";

@implementation ALMainWindowController
@synthesize string=_string, fileURL = _fileURL, language = _language;

- (instancetype)init
{
  if (self = [super initWithWindowNibName:@"ALMainWindowController"]) {
		self.fragaria = [MGSFragaria new];
		self.language = [[NSUserDefaults standardUserDefaults] stringForKey:ALFormatLanguage];
		[self AL_restoreSource];
		[self window];
  }
  return self;
}

- (void)AL_restoreSource
{
	NSString* lastURLString = [[NSUserDefaults standardUserDefaults] stringForKey:ALLastSourceURL];
	NSURL* url;
	if (lastURLString) {
		url = [NSURL URLWithString:lastURLString];
		if ([self loadSourceFormURL:url error:nil]) {
			return;
		}
	}
	url = [[NSBundle mainBundle] URLForResource:@"sample" withExtension:@"mm" subdirectory:@"samples"];
	NSError* error;
	if (![self loadSourceFormURL:url error:&error]) {
		NSException* exception = [NSException exceptionWithName:@"No Source" reason:@"Failed to load the sample source file" userInfo:nil];
		[exception raise];
	}
}

- (BOOL)loadSourceFormURL:(NSURL*)url error:(NSError**)outError
{
  NSString* source = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:outError];
  if (!source) return NO;

  self.codeString = source;
	self.fileURL = url;

	[self uncrustify:nil];

  return YES;
}

- (void)windowDidLoad
{
  [super windowDidLoad];

  self.documentView = [ALDocumentView new];
	
	NSMutableSet* types = [NSMutableSet new];
	for(NSDictionary* d in [AppDelegate supportedLanguages]) {
		[types addObjectsFromArray:d[@"uti"]];
	}
	
	self.documentView.allowedFileTypes = [types allObjects];
	self.documentView.representedObject = [self sourceDocument];
	
	NSURL* baseURL = [[NSBundle mainBundle].resourceURL URLByAppendingPathComponent:@"samples"];
	self.documentView.knownSampleURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:baseURL
																																		includingPropertiesForKeys:nil
																																											 options:NSDirectoryEnumerationSkipsHiddenFiles
																																												 error:nil];
	
  [self.splitView replaceSubview:self.splitView.subviews[1] with:self.documentView.view];


  // we want to be the delegate
  [self.fragaria setObject:self forKey:MGSFODelegate];
	[self.fragaria embedInView:self.documentView.containerView];

  NSTextView* textView = [self.fragaria objectForKey:ro_MGSFOTextView];
  textView.editable = NO;
	textView.textContainer.widthTracksTextView = NO;
	textView.textContainer.containerSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
}

- (void)windowWillClose:(NSNotification *)notification
{
	self.documentView.representedObject = nil;
}

#pragma mark - accessors

- (void)setDocument:(NSDocument*)document
{
  NSDocument* oldDocument = self.document;
  [super setDocument:document];
  NSDocument* newDocument = self.document;
  if (oldDocument == newDocument) return;

  NSView* containerView = self.splitView.subviews[0];
  if (oldDocument) {
    for (NSView* v in [containerView.subviews copy]) {
      [v removeFromSuperviewWithoutNeedingDisplay];
    }
  }

  Document* d = self.styleDocument;
  [d embedInView:containerView];
  d.model.delegate = self;
	
	[self uncrustify:nil];
}

- (Document*)styleDocument
{
  NSDocument* document = self.document;
  return [document isKindOfClass:[Document class]] ? (Document*) document : nil;
}

- (id <ALCodeDocument>)sourceDocument
{
  return self;
}

- (void)setFileURL:(NSURL *)fileURL
{
  self->_fileURL = fileURL;
  if (!fileURL) return;
	
	[[NSUserDefaults standardUserDefaults] setObject:[[fileURL filePathURL] absoluteString] forKey:ALLastSourceURL];

  NSString* uti = [[NSWorkspace sharedWorkspace] typeOfFile:[self.fileURL path] error:nil];
  if (!uti) return ;

  NSString* lang = [AppDelegate languageForUTI:uti];
  if (!lang) return;

  self.language = lang;
	
}

- (void)setLanguage:(NSString *)language
{
	self->_language = language;

	NSString* fragariaName = [AppDelegate fragariaNameForLanguage:self.language];
	if (fragariaName && self.fragaria)
		[self.fragaria setObject:fragariaName forKey:MGSFOSyntaxDefinitionName];

	[self uncrustify:nil];
}

- (NSString*)string
{
	return self.codeString;
}


- (void)setString:(NSString *)string
{
	if (!self.fragaria) return;
	
	// we will try and preserve visible frame position in the document
	// across changes.

	NSTextView* textView = [self.fragaria objectForKey:ro_MGSFOTextView];
	NSTextStorage* textStorage = textView.textStorage;
	NSLayoutManager* layoutManager = textView.layoutManager;

	// first we need the document height.
	// textview lays text out lazyliy, so we cannot just use the textview frame
	// to get the height. It's not computed yet.

	// Here we are taking advantage of two assumptions:
	// 1. the text is not wrapping, so we only count hard line breaks
	NSRange oldDocumentLineRange = [textStorage.string lineRangeForCharacterRange:NSMakeRange(0, textStorage.string.length)];
	
	// 2. the text is layed out in one font size, so the line height is constant
	CGFloat lineHeight = [layoutManager defaultLineHeightForFont:textView.font];
	
	CGFloat frameHeight = oldDocumentLineRange.length * lineHeight;
	NSRect visRect = textView.visibleRect;
	CGFloat maxScrollLocation = frameHeight - visRect.size.height;
	CGFloat relativeScrollLocation = (maxScrollLocation > 0) ? visRect.origin.y / maxScrollLocation : 0;
	
//	NSLog(@"%f %f %f %f %f %ld", frameHeight, visRect.size.height,
//				visRect.origin.y, maxScrollLocation, relativeScrollLocation, string.length);
	
	self.fragaria.string = string;

	NSRange newDocumentLineRange = [textStorage.string lineRangeForCharacterRange:NSMakeRange(0, textStorage.string.length)];

	frameHeight = newDocumentLineRange.length * lineHeight;
	visRect = textView.visibleRect;
	maxScrollLocation = frameHeight - visRect.size.height;
	
	//	NSLog(@"%f %f %f %f %f %ld", frameHeight, visRect.size.height,
	//				visRect.origin.y, maxScrollLocation, relativeScrollLocation, string.length);

	visRect.origin.y = relativeScrollLocation * maxScrollLocation;
	visRect.origin.x = 0;
	[textView scrollRectToVisible:visRect];
}

- (IBAction)changeLanguage:(NSMenuItem *)anItem
{
  NSDictionary* props = [anItem representedObject];
  self.language = props[@"uncrustify"];
  [[NSUserDefaults standardUserDefaults] setObject:self.language forKey:ALFormatLanguage];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
  if (anItem.action == @selector(changeLanguage:)) {
    NSDictionary* props = [anItem representedObject];
    anItem.state = [self.language isEqualToString:props[@"uncrustify"]]
        ? NSOnState : NSOffState;
  }
  return YES;
}

#pragma mark - NSSplitViewDelegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return self.splitView.frame.size.width - 370;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return 200;
}

#pragma mark - coiffeur

- (IBAction)uncrustify:(id)sender
{
  Document* formatter = self.styleDocument;
  id <ALCodeDocument> source = self.sourceDocument;
	
	if (!formatter || !source) return;

  [formatter.model format:source.string attributes:@{ALFormatLanguage : source.language, ALFormatFragment : @(NO)} completionBlock:^(NSString* text, NSError* error) {
      if (text)
        source.string = text;
      if (error)
        NSLog(@"%@", error);
  }];
}

- (NSString*)textToFormatByCoiffeurController:(ALCoiffeurController*)controller attributes:(NSDictionary**)attributes
{
  id<ALCodeDocument> source = self.sourceDocument;
  if (attributes)
    *attributes = @{ALFormatLanguage : source.language, ALFormatFragment : @(NO)};
  return source.string;
}

- (void)coiffeurController:(ALCoiffeurController*)controller setText:(NSString*)text
{
  if (!text) return;
  id<ALCodeDocument> source = self.sourceDocument;
  source.string = text;
}

@end

