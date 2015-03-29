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
	return [NSSet setWithObject:@"fileType"];
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
	if (!self.document) return nil;
	return [self.allowedFileTypes containsObject:ALDocumentSource]
		? @"Source"
		: @"Style";
}

#pragma clang diagnostic pop

- (void)viewDidLoad {
	[super viewDidLoad];
	
	
    // Do view setup here.
}

- (ALMainWindowController*)windowController
{
	id wc = self.view.window.delegate;
	return wc && [wc isKindOfClass:[ALMainWindowController class]] ?
	(ALMainWindowController*)wc : nil;
}

- (void)pathControl:(NSPathControl *)pathControl willPopUpMenu:(NSMenu *)menu
{
	NSMenuItem* item;
	
	[menu removeItemAtIndex:0];
	
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

- (NSUInteger)indexInController
{
	ALMainWindowController* controller = self.windowController;
	NSUInteger index = 0;
	for(ALDocumentView* dv in controller.documentViews) {
		if (dv == self) return index;
		++index;
	}
	return NSNotFound;
}

- (IBAction)newDocument:(id)sender
{
	NSUInteger index = [self indexInController];
	if (index == NSNotFound) return;
	
	NSString* type = [sender representedObject];
	if (!type) type = self.allowedFileTypes[0];
	
	NSDocument* doc = [[NSDocumentController sharedDocumentController]
					makeUntitledDocumentOfType:type error:nil];
	[[self windowController] setDocument:doc atIndex:index];
}

- (IBAction)openDocumentInView:(id)sender
{
	NSUInteger index = [self indexInController];
	if (index == NSNotFound) return;

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
		
		[[NSDocumentController sharedDocumentController]
			openDocumentWithContentsOfURL:[op URL]
														display:NO
									completionHandler:^(NSDocument *document,
																			BOOL documentWasAlreadyOpen,
																			NSError *error) {
										if (document) {
											[[self windowController] setDocument:document
																									 atIndex:index];
										}
									}];
	}];
}

- (IBAction)saveDocument:(id)sender
{
	[self.document saveDocument:sender];
}

- (IBAction)saveDocumentAs:(id)sender
{
	[self.document saveDocumentAs:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	return YES;
}

@end

