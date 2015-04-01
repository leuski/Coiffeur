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

@property (nonatomic, weak) IBOutlet NSSplitView* splitView;
@property (nonatomic, strong) NSMutableArray* documentsToDisplay;
@end

@implementation ALMainWindowController

static ALMainWindowController* sharedALMainWindowController = nil;

+ (ALMainWindowController*)sharedInstance
{
	static dispatch_once_t pred;

	dispatch_once(&pred, ^{
		sharedALMainWindowController = [[ALMainWindowController alloc] init];
		[sharedALMainWindowController window]; // load it
	});
	return sharedALMainWindowController;
}

- (instancetype)init
{
	if (self = [super initWithWindowNibName:@"ALMainWindowController"]) {
		self.documentsToDisplay = [NSMutableArray new];
		self.documentViews = [NSMutableArray new];
	}
	return self;
}

- (void)canCloseOneOfDocuments:(NSArray*)documentViews
											 atIndex:(NSUInteger)index
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
	[documentView.document canCloseWithBlock:^(BOOL success) {
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
	}];
}

- (void)windowController:(ALMainWindowController*)wc
						 shouldClose:(BOOL)shouldClose
						 contextInfo:(void*)contextInfo
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

- (BOOL)AL_getDocument:(NSDocument**)outDocument targetView:(ALDocumentView**)outDocumentView
{
	while (self.documentsToDisplay.count > 0) {
		NSDocument* document = self.documentsToDisplay[0];
		[self.documentsToDisplay removeObjectAtIndex:0];
		
		NSString*		type = document.fileType;
		
		for(ALDocumentView* dv in self.documentViews) {
			if (document == dv.document) break;
			if ([dv.allowedFileTypes containsObject:type]) {
				*outDocument = document;
				*outDocumentView = dv;
				return YES;
			}
		}
	}
	return NO;
}

- (void)AL_showDocument
{
	NSDocument* document;
	ALDocumentView* documentView;
	if (![self AL_getDocument:&document targetView:&documentView]) {
		
		NSDocumentController* controller = [NSDocumentController sharedDocumentController];
		for(ALDocumentView* dv in self.documentViews) {
			if (dv.document) continue;
			NSError* error;
			NSDocument* doc = [controller makeUntitledDocumentOfType:dv.allowedFileTypes[0] error:&error];
			if (doc) {
				[controller addDocument:doc];
				[self addDocument:doc toDocumentView:dv];
			} else {
				[NSApp presentError:error];
			}
		}
		
		[self.window makeKeyAndOrderFront:nil];

		return;
	}
	
	__weak ALMainWindowController* weakSelf     = self;
	void (^completeBlock)(BOOL) = ^(BOOL success) {
		ALMainWindowController* _self = weakSelf;
		if (!_self) return;

		[_self AL_do:success swapDocumentInView:documentView forDocument:document];
		[_self AL_showDocument];
	};
	
	[documentView canCloseDocumentWithBlock:completeBlock];
}

- (void)AL_do:(BOOL)success swapDocumentInView:(ALDocumentView*)documentView forDocument:(NSDocument*)document
{
	if (!success) {
		[document close];
	} else {
		[documentView.document close];
		[self addDocument:document toDocumentView:documentView];
	}
}

- (void)displayDocument:(NSDocument*)document inView:(ALDocumentView*)documentView
{
	__weak ALMainWindowController* weakSelf     = self;
	void (^completeBlock)(BOOL) = ^(BOOL success) {
		ALMainWindowController* _self = weakSelf;
		if (!_self) return;
		
		[_self AL_do:success swapDocumentInView:documentView forDocument:document];
	};
	
	[documentView canCloseDocumentWithBlock:completeBlock];
}

- (void)addDocument:(NSDocument*)document
{
	[self.documentsToDisplay addObject:document];
	dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@"%@", self.documentsToDisplay);
		[self AL_showDocument];
	});
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
	return nil;
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

	for (NSView* v in [self.splitView.subviews copy])
		[v removeFromSuperviewWithoutNeedingDisplay];

	NSArray* types = @[ @[ ALDocumentUncrustifyStyle, ALDocumentClangFormatStyle ]
					, @[ ALDocumentSource ]];

	for (NSUInteger i = 0; i < types.count; ++i) {
		ALDocumentView* documentView = [ALDocumentView new];
		documentView.allowedFileTypes = types[i];
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

	// detach the view controllers from the documents
	for (ALDocumentView* ctrl in me.documentViews) {
		[ctrl.document close];
	}
	
	[NSApp terminate:nil];
}

- (NSUndoManager*)windowWillReturnUndoManager:(NSWindow*)window
{
	if (window != self.window) return nil;
	return self.styleDocument.undoManager;
}

- (Document*)styleDocument
{
	ALDocumentView* documentView = self.documentViews[0];
	return (Document*)documentView.document;
}

- (ALCodeDocument*)sourceDocument
{
	ALDocumentView* documentView = self.documentViews[1];
	return (ALCodeDocument*)documentView.document;
}

- (IBAction)uncrustify:(id)sender
{
	Document      * formatter = self.styleDocument;
	ALCodeDocument* source    = self.sourceDocument;

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
	ALCodeDocument* source = self.sourceDocument;
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
	ALCodeDocument* source = self.sourceDocument;
	source.string = text;
}

@end

