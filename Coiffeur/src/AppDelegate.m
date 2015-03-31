//
//  AppDelegate.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "AppDelegate.h"
#import "ALCodeDocument.h"
#import "ALMainWindowController.h"
#import "ALDocumentController.h"

NSString* const ALDocumentUncrustifyStyle  = @"Uncrustify Style File";
NSString* const ALDocumentClangFormatStyle = @"Clang-Format Style File";
NSString* const ALDocumentSource           = @"Source File";

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu* languagesMenu;
@end

@implementation AppDelegate

+ (NSArray*)supportedLanguages
{
	static NSArray* ALLanguages = nil;
	if (!ALLanguages) {
		ALLanguages
						= [NSArray arrayWithContentsOfURL:[[NSBundle bundleForClass:[self class]]
						URLForResource:@"languages" withExtension:@"plist"]];
	}
	return ALLanguages;
}

+ (NSString*)languageForUTI:(NSString*)uti
{
	for (NSDictionary* d in [self supportedLanguages]) {
		for (NSString* u in d[@"uti"]) {
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

		NSDictionary* ud
												= [NSDictionary dictionaryWithContentsOfURL:[[NSBundle bundleForClass:[self class]]
										URLForResource:@"UserDefaults" withExtension:@"plist"]];
		if (ud) {
			[[NSUserDefaults standardUserDefaults] registerDefaults:ud];
		}
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
	for (NSDictionary* d in [AppDelegate supportedLanguages]) {
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:d[@"name"]
																									action:@selector(changeLanguage:)
																					 keyEquivalent:@""];
		item.representedObject = d;
		[self.languagesMenu addItem:item];
	}
}

- (void)applicationWillTerminate:(NSNotification*)aNotification
{
	// Insert code here to tear down your application
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication*)sender
{
	static BOOL applicationHasStarted = NO;
	// On startup, when asked to open an untitled file, open the last opened
	// file instead
	if (applicationHasStarted) return YES;

	applicationHasStarted            = YES;
	// Get the recent documents
	ALDocumentController* controller = [NSDocumentController sharedDocumentController];
	[controller restoreState];
	return NO;
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