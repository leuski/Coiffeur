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

@interface ALDocumentView () <NSPathControlDelegate>
@end

@implementation ALDocumentView

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

#pragma mark - NSPathControlDelegate

- (void)pathControl:(NSPathControl *)pathControl willPopUpMenu:(NSMenu *)menu
{
	NSMenuItem* item;
	
	[menu removeItemAtIndex:0];

	NSInteger index = 0;
	for(NSURL* url in self.knownSampleURLs) {
		item = [[NSMenuItem alloc] initWithTitle:url.path.lastPathComponent action:@selector(openDocumentInView:) keyEquivalent:@""];
		[menu insertItem:item atIndex:index++];
		item.representedObject = url;
	}
	item = [[NSMenuItem alloc] initWithTitle:@"Choose…" action:@selector(openDocumentInView:) keyEquivalent:@""];
	[menu insertItem:item atIndex:index++];
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

																 NSURL* url = [self AL_allowedURLForDraggingItem:draggingItem];
																 if (url) {
																	 ++count;
																 }
															 }];
	return count == 1 ? NSDragOperationEvery : NSDragOperationNone;
}

- (void)AL_openDocumentWithURL:(NSURL*)url
{
	[self.windowController loadSourceFormURL:url error:nil];
}

- (NSURL*)AL_allowedURLForDraggingItem:(NSDraggingItem*)draggingItem
{
	NSURL* url = (NSURL*)draggingItem.item;
	NSError* error;
	NSString* type = [[NSDocumentController sharedDocumentController]
										typeForContentsOfURL:url
										error:&error];
	if (type && [self.allowedFileTypes containsObject:type]) return url;

	return nil;
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
																 
																 NSURL* url = [self AL_allowedURLForDraggingItem:draggingItem];
																 if (url) {
																	 theURL = url;
																	 *stop = YES;
																 }
															 }];
	if (!theURL) return NO;

	[self AL_openDocumentWithURL:theURL];

	return YES;
}

#pragma mark - actions

- (IBAction)openDocumentInView:(id)sender
{
	NSURL* url = [sender representedObject];
	
	if (url) {
		[self AL_openDocumentWithURL:url];
		return;
	}
	
	NSOpenPanel* op = [NSOpenPanel openPanel];
	
	if (self.allowedFileTypes.count)
		op.allowedFileTypes = self.allowedFileTypes;
	op.allowsOtherFileTypes = NO;
	
	[op beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		if (result != NSFileHandlingPanelOKButton) return;
		[self AL_openDocumentWithURL:[op URL]];
	}];
}

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
// button label results in the focus not transferring to the control. Fixing.
- (void)mouseDown:(NSEvent *)theEvent
{
	[self.window makeFirstResponder:self];
	[super mouseDown:theEvent];
}
@end


