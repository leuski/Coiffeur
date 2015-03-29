//
//  ALMainWindowController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALMainWindowController.h"
#import "ALCoiffeurView.h"
#import "ALDocumentView.h"
#import "NSInvocation+shouldClose.h"
#import "AppDelegate.h"

#import "Document.h"
#import "ALCodeDocument.h"
#import "ALUncrustifyController.h"

@interface ALMainWindowController ()<NSWindowDelegate, ALCoiffeurControllerDelegate>

@property (weak) IBOutlet NSSplitView* splitView;
@end

@implementation ALMainWindowController

+ (ALMainWindowController*)sharedInstance
{
	static ALMainWindowController* shared = nil;
	if (!shared) {
		shared = [ALMainWindowController new];
		[shared window]; // load it
	}
	return shared;
}

- (instancetype)init
{
	if (self = [super initWithWindowNibName:@"ALMainWindowController"]) {
		self.documentViews = [NSMutableArray new];
	}
	return self;
}

- (void)document:(NSDocument*)doc shouldClose:(BOOL)shouldClose
 completionBlock:(void*)contextInfo
{
	void (^completeBlock)(BOOL) = (__bridge_transfer void (^)(BOOL))contextInfo;
	completeBlock(shouldClose);
}

- (void)setDocument:(NSDocument*)document atIndex:(NSUInteger)index
{
	for (ALDocumentView* dv in self.documentViews) {
		if (document == dv.document)
			return;
	}

	ALDocumentView               * documentView = self.documentViews[index];
	__weak ALMainWindowController* weakSelf     = self;

	void (^completeBlock)(BOOL) = ^(BOOL success) {
		if (!success) {
			[document close];
			return;
		}

		ALMainWindowController* _self = weakSelf;
		if (!_self) return;

		[_self removeDocumentFromDocumentView:documentView];
		[documentView.document close];
		[_self addDocument:document toDocumentView:documentView];
	};

	if (documentView.document) {
		[documentView.document canCloseDocumentWithDelegate:self
																		shouldCloseSelector:@selector(document:shouldClose:completionBlock:)
																						contextInfo:(__bridge_retained void*)[completeBlock copy]];
	} else {
		completeBlock(YES);
	}
}

- (void)canCloseOneOfDocuments:(NSArray*)documentViews atIndex:(NSUInteger)index
										invocation:(NSInvocation*)invocation
{
	ALDocumentView* documentView = nil;
	while (index < documentViews.count) {
		documentView = documentViews[index];
		if (documentView.document) break;
		++index;
	}

	if (index >= documentViews.count) {
		[invocation invokeWithShouldClose:YES];
		return;
	}

	__weak ALMainWindowController* weakSelf = self;
	void (^completeBlock)(BOOL) = ^(BOOL success) {
		ALMainWindowController* _self = weakSelf;
		if (!_self) {
			[invocation invokeWithShouldClose:YES];
		} else if (!success) {
			[invocation invokeWithShouldClose:NO];
		} else {
			[_self canCloseOneOfDocuments:documentViews
														atIndex:index + 1
												 invocation:invocation];
		}
	};

	[documentView.document canCloseDocumentWithDelegate:self
																	shouldCloseSelector:@selector(document:shouldClose:completionBlock:)
																					contextInfo:(__bridge_retained void*)[completeBlock copy]];

}

- (void)windowController:(ALMainWindowController*)wc
						 shouldClose:(BOOL)shouldClose contextInfo:(void*)contextInfo
{
	if (shouldClose)
		[wc close];
}

- (BOOL)windowShouldClose:(id)sender
{
	BOOL canClose = YES;
	for (ALDocumentView* documentView in self.documentViews) {
		if (documentView.document) {
			canClose = NO;
			break;
		}
	}

	if (canClose) return YES;

	[self canCloseOneOfDocuments:[self.documentViews copy]
											 atIndex:0
										invocation:[NSInvocation invocationWithTarget:self
																							shouldCloseSelector:@selector(windowController:shouldClose:contextInfo:)
																													 object:self
																											contextInfo:nil]];

	return NO;
}

- (void)addDocument:(NSDocument*)document
{
	NSUInteger index = [[document fileType] isEqualToString:ALDocumentStyle]
										 ? 0
										 : 1;
	[self setDocument:document atIndex:index];

	ALDocumentView* documentView = self.documentViews[1 - index];
	if (documentView.document) return;

	[documentView newDocument:nil];
	[[NSDocumentController sharedDocumentController]
					addDocument:documentView.document];
}

- (void)removeDocument:(NSDocument*)document
{
	for(ALDocumentView* dv in self.documentViews) {
		if (dv.document == document) {
			[self removeDocumentFromDocumentView:dv];
		}
	}
}

- (void)setDocument:(NSDocument*)document
{
//	NSLog(@"Will not set document to: %@",document);
}

- (NSDocument*)document
{
	if (self.window != [NSApp keyWindow]) return nil;

	NSResponder* responder = self.window.firstResponder;
	while (responder && ![responder isKindOfClass:[ALDocumentView class]])
		responder = responder.nextResponder;

	return [(id)responder document];
}

- (void)addDocument:(NSDocument*)document
		 toDocumentView:(ALDocumentView*)documentView
{
	documentView.document = document;
	if ([document respondsToSelector:@selector(embedInView:)]) {
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCDFAInspection"
		[(id)document embedInView:documentView.containerView];
#pragma clang diagnostic pop
	}
	[document addWindowController:self];
	if ([document isKindOfClass:[Document class]]) {
		Document* d = (Document*)document;
		d.model.delegate = self;
	}
}

- (void)removeDocumentFromDocumentView:(ALDocumentView*)documentView
{
	NSDocument* existingDocument = documentView.document;
	if (!existingDocument) return;

	documentView.document = nil;
	for (NSView* v in [documentView.containerView.subviews copy]) {
		[v removeFromSuperviewWithoutNeedingDisplay];
	}

	[existingDocument removeWindowController:self];
}

- (void)addDocumentView:(ALDocumentView*)documentView
{
	[self.documentViews addObject:documentView];
	[self.splitView addSubview:documentView.view];
}

- (void)windowDidLoad
{
	[super windowDidLoad];

	self.shouldCloseDocument = YES;

	for (NSView* v in [self.splitView.subviews copy])
		[v removeFromSuperviewWithoutNeedingDisplay];

	NSArray* types = @[
					ALDocumentStyle
					, ALDocumentSource];

	for (NSUInteger i = 0; i < types.count; ++i) {
		ALDocumentView* documentView = [ALDocumentView new];
		documentView.fileType = types[i];
		[self addDocumentView:documentView];
	}
}

- (void)windowWillClose:(NSNotification*)notification
{
	NSWindow* window = self.window;
	if (notification.object != window) {
		return;
	}

	// let's keep a reference to ourselves and not have us thrown away while we clear out references.
	ALMainWindowController* me = self;

	// detach the view controllers from the document first
	//	me.currentContentViewController = nil;
	for (ALDocumentView* ctrl in me.documentViews) {
		[me removeDocumentFromDocumentView:ctrl];
		[ctrl.document close];
	}
	// then any content view
	[window setContentView:nil];
	[me.documentViews removeAllObjects];
}

- (NSUndoManager*)windowWillReturnUndoManager:(NSWindow*)window
{
	if (window != self.window) return nil;
	ALDocumentView* documentView = self.documentViews[0];
	return documentView.document.undoManager;
}

- (IBAction)uncrustify:(id)sender
{
	Document      * formatter = self.documentViews[0];
	ALCodeDocument* source    = self.documentViews[1];

	[formatter.model format:source.string
							 attributes:@{
											 ALFormatLanguage   : source.language
											 , ALFormatFragment : @(NO)}
					completionBlock:^(NSString* text, NSError* error) {
						if (text)
							source.string = text;
						if (error)
							NSLog(@"%@", error);
					}];
}

- (NSString*)textToFormatByCoiffeurController:(ALCoiffeurController*)controller
																	 attributes:(NSDictionary**)attributes
{
	ALCodeDocument* source = self.documentViews[1];
	if (attributes)
		*attributes = @{
						ALFormatLanguage   : source.language
						, ALFormatFragment : @(NO)};
	return source.string;
}

- (void)coiffeurController:(ALCoiffeurController*)controller
									 setText:(NSString*)text
{
	if (!text) return;
	ALCodeDocument* source = self.documentViews[1];
	source.string = text;
}

@end

