//
//  AppDelegate.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "AppDelegate.h"

@interface ALDocumentController : NSDocumentController
@end


@interface AppDelegate ()
@property (weak) IBOutlet NSMenu *languagesMenu;

@end


@implementation AppDelegate

// silence the warning
- (void)changeLanguage:(id)sender {}

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

			[controller openDocumentWithContentsOfURL:[documents objectAtIndex:0]
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

@end

@interface ALString2NumberTransformer : NSValueTransformer

@end

@implementation ALString2NumberTransformer

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(NSString*)value
{
	return value ? @([value integerValue]) : 0;
}

- (id)reverseTransformedValue:(NSNumber*)value
{
	return value ? [value stringValue] : nil;
}

@end