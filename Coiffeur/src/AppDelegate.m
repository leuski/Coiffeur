//
//  AppDelegate.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "AppDelegate.h"
#import "ALMainWindowController.h"
#import "ALDocumentController.h"
#import "ALLanguage.h"
#import <MGSFragaria/MGSFragaria.h>

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
NSString* const ALDocumentUncrustifyStyle  = @"Uncrustify Style File";
NSString* const ALDocumentClangFormatStyle = @"Clang-Format Style File";
static NSString* const AL_AboutFileName = @"about";
static NSString* const AL_AboutFileNameExtension = @"html";
static NSString* const AL_UserDefaultsFileNameExtension = @"plist";
static NSString* const AL_UserDefaultsFileName = @"UserDefaults";
#pragma clang diagnostic pop

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu* languagesMenu;
@end

@implementation AppDelegate

- (instancetype)init
{
	if (self = [super init]) {

		[ALDocumentController new];

		[MGSFragaria initializeFramework];
		
		NSDictionary* ud = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:AL_UserDefaultsFileName withExtension:AL_UserDefaultsFileNameExtension]];
		if (ud) {
			[[NSUserDefaults standardUserDefaults] registerDefaults:ud];
		}
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
	for (ALLanguage* l in [ALLanguage supportedLanguages]) {
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:l.displayName
																									action:@selector(changeLanguage:)
																					 keyEquivalent:@""];
		item.representedObject = l;
		[self.languagesMenu addItem:item];
	}
}

- (void)applicationWillTerminate:(NSNotification*)aNotification
{
	// Insert code here to tear down your application
}

- (NSBundle*)bundle
{
	return [NSBundle mainBundle];
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"
- (NSURL*)aboutURL
{
	return [self.bundle URLForResource:AL_AboutFileName withExtension:AL_AboutFileNameExtension];
}
#pragma clang diagnostic pop

@end


#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedClassInspection"

@interface ALBorderlessTextView : NSTextView
@end

@implementation ALBorderlessTextView

- (void)awakeFromNib {
	[self setTextContainerInset:NSMakeSize(0,0)];
	[self.textContainer setLineFragmentPadding:0];
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
	return value ? @([value integerValue]) : nil;
}

- (id)reverseTransformedValue:(NSNumber*)value
{
	return value ? [value stringValue] : nil;
}

@end

#pragma clang diagnostic pop