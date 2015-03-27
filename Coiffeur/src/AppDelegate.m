//
//  AppDelegate.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu *languagesMenu;

@end

static NSArray * ALLanguages = nil;

@implementation AppDelegate

// silence the warning
- (void)changeLanguage:(id)sender {}

- (instancetype)init
{
	if (self = [super init]) {
		NSDictionary* ud = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"UserDefaults" withExtension:@"plist"]];
		if (ud) {
			[[NSUserDefaults standardUserDefaults] registerDefaults:ud];
		}
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	
	if (!ALLanguages) {
		ALLanguages = [NSArray arrayWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"languages" withExtension:@"plist"]];
		
		for(NSDictionary* d in ALLanguages) {
			NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:d[@"name"]
																										action:@selector(changeLanguage:)
																						 keyEquivalent:@""];
			item.representedObject = d;
			[self.languagesMenu addItem:item];
		}
	}
	
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
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