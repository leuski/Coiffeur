//
//  ALDocumentView.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/27/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALDocumentView.h"
#import "ALMainWindowController.h"
#import "AppDelegate.h"
#import "ALDocument.h"

@interface ALDocumentView () <NSPathControlDelegate>
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedPropertyInspection"
@property (nonatomic, strong, readonly) NSURL* displayURL;
@property (nonatomic, strong, readonly) NSString* displayType;
#pragma clang diagnostic pop
@end

@implementation ALDocumentView

+ (NSSet*)keyPathsForValuesAffectingDisplayURL
{
	return [NSSet setWithArray:@[ @"document.fileURL", @"document.displayName" ] ];
}

+ (NSSet*)keyPathsForValuesAffectingDisplayType
{
	return [NSSet setWithObject:@"allowedFileTypes"];
}

- (instancetype)init
{
	if (self = [super initWithNibName:@"ALDocumentView"
														 bundle:[NSBundle bundleForClass:[self class]]]) {
		
	}
	return self;
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"

- (NSURL*)displayURL
{
	if (!self.document) return nil;
	return self.document.fileURL
		? self.document.fileURL
		: [NSURL fileURLWithPath:self.document.displayName];
}

- (NSString*)displayType
{
	if (!self.allowedFileTypes) return nil;
	return [self.allowedFileTypes containsObject:ALDocumentSource]
		? @"Source"
		: @"Style";
}

#pragma clang diagnostic pop

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (ALMainWindowController*)windowController
{
	id wc = self.view.window.delegate;
	return wc && [wc isKindOfClass:[ALMainWindowController class]] ?
	(ALMainWindowController*)wc : nil;
}

- (id)supplementalTargetForAction:(SEL)action sender:(id)sender
{
	if ([self.document respondsToSelector:action])
		return self.document;
	
	return [super supplementalTargetForAction:action sender:sender];
}

#pragma mark - NSPathControlDelegate

- (void)pathControl:(NSPathControl *)pathControl willPopUpMenu:(NSMenu *)menu
{
	NSMenuItem* item;
	
	[menu removeItemAtIndex:0];

	item = [[NSMenuItem alloc] initWithTitle:@"Browse Document Versions…" action:@selector(browseDocumentVersions:) keyEquivalent:@""];
	[menu insertItem:item atIndex:0];
	
	item = [[NSMenuItem alloc] initWithTitle:@"Save As…" action:@selector(saveDocumentAs:) keyEquivalent:@""];
	[menu insertItem:item atIndex:0];

	item = [[NSMenuItem alloc] initWithTitle:@"Save" action:@selector(saveDocument:) keyEquivalent:@""];
	[menu insertItem:item atIndex:0];
	
	item = [[NSMenuItem alloc] initWithTitle:@"Open…" action:@selector(openDocumentInView:) keyEquivalent:@""];
	[menu insertItem:item atIndex:0];
	
	int index = 0;
	for(NSString* type in self.allowedFileTypes) {
		item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"New %@", type] action:@selector(newDocument:) keyEquivalent:@""];
		item.representedObject = type;
		[menu insertItem:item atIndex:index++];
	}
}

- (NSDragOperation)pathControl:(NSPathControl *)pathControl validateDrop:(id<NSDraggingInfo>)info
{
	__block NSUInteger count = 0;
	[info enumerateDraggingItemsWithOptions:0
																	forView:pathControl
																	classes:@[ [NSURL class] ]
														searchOptions:nil
															 usingBlock:^(NSDraggingItem* draggingItem,
																			 NSInteger idx, BOOL* stop) {

																 NSURL* url = (NSURL*)draggingItem.item;
																 NSError* error;
																 NSString* type = [[NSDocumentController sharedDocumentController]
																				 typeForContentsOfURL:url
																												error:&error];
																 if (type && [self.allowedFileTypes containsObject:type]) {
																	 ++count;
																 }
															 }];
	return count == 1 ? NSDragOperationEvery : NSDragOperationNone;
}

- (void)AL_openDocumentWithURL:(NSURL*)url
{
	[[NSDocumentController sharedDocumentController]
	 openDocumentWithContentsOfURL:url
	 display:NO
	 completionHandler:^(NSDocument *document,
											 BOOL documentWasAlreadyOpen,
											 NSError *error) {
		 if (document && !documentWasAlreadyOpen) {
			 [[self windowController] displayDocument:document inView:self];
		 }
	 }];
}

- (BOOL)pathControl:(NSPathControl *)pathControl acceptDrop:(id<NSDraggingInfo>)info
{
	__block NSURL* theURL = nil;
	[info enumerateDraggingItemsWithOptions:0
																	forView:pathControl
																	classes:@[ [NSURL class] ]
														searchOptions:nil
															 usingBlock:^(NSDraggingItem* draggingItem,
																						NSInteger idx, BOOL* stop) {
																 
																 NSURL* url = (NSURL*)draggingItem.item;
																 NSError* error;
																 NSString* type = [[NSDocumentController sharedDocumentController]
																									 typeForContentsOfURL:url
																									 error:&error];
																 if (type && [self.allowedFileTypes containsObject:type]) {
																	 theURL = url;
																	 *stop = YES;
																 }
															 }];
	if (!theURL) return NO;

	[self AL_openDocumentWithURL:theURL];

	return YES;
}

- (void)canCloseDocumentWithBlock:(void(^)(BOOL))block
{
	if (self.document) {
		[self.document canCloseWithBlock:block];
	} else {
		block(YES);
	}
}

#pragma mark - actions

- (IBAction)newDocument:(id)sender
{
	NSString* type = [sender representedObject];
	if (!type) type = self.allowedFileTypes[0];
	
	NSDocumentController* controller = [NSDocumentController sharedDocumentController];
	NSDocument* document = [controller makeUntitledDocumentOfType:type error:nil];
	if (document) {
		[controller addDocument:document];
		[[self windowController] displayDocument:document inView:self];
	}
}

- (IBAction)openDocumentInView:(id)sender
{
	NSOpenPanel* op = [NSOpenPanel openPanel];
	
	NSMutableOrderedSet* allowedExtensions = [NSMutableOrderedSet new];
	
	NSArray* fileTypes = [[NSBundle mainBundle] infoDictionary][@"CFBundleDocumentTypes"];
	for(NSDictionary* ft in fileTypes) {
		if (![self.allowedFileTypes containsObject:ft[@"CFBundleTypeName"]]) continue;
		[allowedExtensions addObjectsFromArray:ft[@"CFBundleTypeExtensions"]];
	}
	
	op.allowedFileTypes = [allowedExtensions array];
	op.allowsOtherFileTypes = NO;
	
	[op beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		if (result != NSFileHandlingPanelOKButton) return;
		[self AL_openDocumentWithURL:[op URL]];
	}];
}

//- (IBAction)saveDocument:(id)sender
//{
//	[self.document saveDocument:sender];
//}
//
//- (IBAction)saveDocumentAs:(id)sender
//{
//	[self.document saveDocumentAs:sender];
//}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	return YES;
}

@end

#pragma mark - ALPathControl

@interface ALPathControl : NSPathControl

@end

@implementation ALPathControl

// there is a bug in NSPathControl where clicking outside of the
// button label results in the focus no transfering to the control. Fixing.
- (void)mouseDown:(NSEvent *)theEvent
{
	[self.window makeFirstResponder:self];
	[super mouseDown:theEvent];
}
@end


