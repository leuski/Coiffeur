//
//  AppDelegate.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "AppDelegate.h"
#import "NSInvocation+shouldClose.h"
#import "ALCodeDocument.h"
#import "ALMainWindowController.h"

@interface ALDocumentController : NSDocumentController
@end

NSString * const ALDocumentUncrustifyStyle = @"Uncrustify Style File";
NSString * const ALDocumentClangFormatStyle = @"Clang-Format Style File";
NSString * const ALDocumentSource = @"Source File";


@interface AppDelegate ()
@property (weak) IBOutlet NSMenu *languagesMenu;

@end


@implementation AppDelegate

+ (NSArray*)supportedLanguages
{
	static NSArray * ALLanguages = nil;
	if (!ALLanguages) {
		ALLanguages = [NSArray arrayWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"languages" withExtension:@"plist"]];
	}
	return ALLanguages;
}

+ (NSString*)languageForUTI:(NSString*)uti
{
	for(NSDictionary* d in [self supportedLanguages]) {
		for(NSString* u in d[@"uti"]) {
			if ([u isEqualToString:uti])
				return d[@"uncrustify"];
		}
	}
	return nil;
}

- (instancetype)init
{
	if (self = [super init]) {
		
		[ALDocumentController new];
		
		NSDictionary* ud = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"UserDefaults" withExtension:@"plist"]];
		if (ud) {
			[[NSUserDefaults standardUserDefaults] registerDefaults:ud];
		}
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	for(NSDictionary* d in [AppDelegate supportedLanguages]) {
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:d[@"name"]
																									action:@selector(changeLanguage:)
																					 keyEquivalent:@""];
		item.representedObject = d;
		[self.languagesMenu addItem:item];
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	static BOOL applicationHasStarted = NO;
	// On startup, when asked to open an untitled file, open the last opened
	// file instead
	if (!applicationHasStarted)
	{
		applicationHasStarted = YES;
		// Get the recent documents
		NSDocumentController *controller = [NSDocumentController sharedDocumentController];
		NSArray *documents = [controller recentDocumentURLs];
		
		// If there is a recent document, try to open it.
		if ([documents count] > 0)
		{
			NSError *error = nil;
			
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

			[controller openDocumentWithContentsOfURL:documents[0]
																				display:YES
																					error:&error];
#pragma clang diagnostic pop
			
			// If there was no error, then prevent untitled from appearing.
			if (error == nil)
			{
				return NO;
			}
		}
	}
	
	return YES;
}

@end


@implementation ALDocumentController

- (void)beginOpenPanel:(NSOpenPanel *)openPanel
							forTypes:(NSArray *)inTypes
		 completionHandler:(void (^)(NSInteger result))completionHandler
{
	openPanel.showsHiddenFiles = YES;
	[super beginOpenPanel:openPanel forTypes:inTypes completionHandler:completionHandler];
}

- (void)document:(NSDocument *)doc shouldClose:(BOOL)shouldClose completionBlock:(void  *)contextInfo
{
	void (^completeBlock)(BOOL) = (__bridge_transfer void (^)(BOOL))contextInfo;
	completeBlock(shouldClose);
}

- (void)canCloseOneOfDocuments:(NSArray*)documents atIndex:(NSUInteger)index invocation:(NSInvocation*)invocation
{
	if (index >= documents.count) {
		[invocation invokeWithShouldClose:YES];
		return;
	}
	
	__weak ALDocumentController* weakSelf = self;
	void (^completeBlock)(BOOL) = ^(BOOL success) {
		ALDocumentController* _self = weakSelf;
		if (!_self) {
			[invocation invokeWithShouldClose:YES];
		} else if (!success) {
			[invocation invokeWithShouldClose:NO];
		} else {
			[_self canCloseOneOfDocuments:documents
														atIndex:index+1
												 invocation:invocation];
		}
	};
	
	NSDocument* document = documents[index];
	[document canCloseDocumentWithDelegate:self
										 shouldCloseSelector:@selector(document:shouldClose:completionBlock:)
														 contextInfo:(__bridge_retained void *)[completeBlock copy]];
	
}

- (void)controller:(NSDocumentController*)controller doCloseAllDocuments:(BOOL)doClose contextInfo:(void *)contextInfo
{
	NSInvocation* invocation = (__bridge_transfer NSInvocation*)contextInfo;

	if (doClose) {
		for(NSDocument* doc in [self.documents copy]) {
			for (NSWindowController* windowCtrl in [doc.windowControllers copy]) {
				if ([windowCtrl respondsToSelector:@selector(removeDocument:)]) {
					[(id)windowCtrl removeDocument:doc];
				}
			}
			[doc close];
		}
	}
	
	[invocation invokeWithShouldClose:doClose];
}

- (void)closeAllDocumentsWithDelegate:(id)delegate didCloseAllSelector:(SEL)didCloseAllSelector contextInfo:(void *)contextInfo
{
	NSInvocation* target = [NSInvocation invocationWithTarget:delegate
																				shouldCloseSelector:didCloseAllSelector
																										 object:self
																								contextInfo:contextInfo];

	NSInvocation* invocation = [NSInvocation invocationWithTarget:self
																						shouldCloseSelector:@selector(controller:doCloseAllDocuments:contextInfo:)
																												 object:self
																										contextInfo:(__bridge_retained void *)target];

	if (self.documents.count == 0) {
		[invocation invokeWithShouldClose:YES];
	} else {
		[self canCloseOneOfDocuments:[self.documents copy] atIndex:0 invocation:invocation];
	}
}

- (NSString*)typeForContentsOfURL:(NSURL*)url error:(NSError**)outError
{
	NSString* type = [super typeForContentsOfURL:url error:outError];
	
	if ([type isEqualToString:ALDocumentClangFormatStyle] || [type isEqualToString:ALDocumentUncrustifyStyle]) {
		NSString* data = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:outError];
		if (data) {
			if ([data hasPrefix:@"---"] || [data rangeOfString:@"\n---"].location != NSNotFound) {
				type = ALDocumentClangFormatStyle;
			} else {
				type = ALDocumentUncrustifyStyle;
			}
		}
	}
	NSLog(@"type: %@", type);
	return type;
}

@end

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedClassInspection"

@interface ALString2NumberTransformer : NSValueTransformer

@end

@implementation ALString2NumberTransformer

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(NSString*)value
{
	return value ? @([value integerValue]) : nil;
}

- (id)reverseTransformedValue:(NSNumber*)value
{
	return value ? [value stringValue] : nil;
}

@end

#pragma clang diagnostic pop