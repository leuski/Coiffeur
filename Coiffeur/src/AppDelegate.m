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
#import "ALCoiffeurController.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
static NSString* const AL_AboutFileName = @"about";
static NSString* const AL_AboutFileNameExtension = @"html";
static NSString* const AL_UserDefaultsFileNameExtension = @"plist";
static NSString* const AL_UserDefaultsFileName   = @"UserDefaults";
#pragma clang diagnostic pop

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu* languagesMenu;
@property (weak) IBOutlet NSMenu* makeNewDocumentMenu;
@end

@implementation AppDelegate

- (instancetype)init
{
  if (self = [super init]) {
    [ALDocumentController new];

    [MGSFragaria initializeFramework];

    NSBundle*     bundle = [NSBundle bundleForClass:[self class]];
    NSURL*        UDURL  = [bundle URLForResource:AL_UserDefaultsFileName
                                    withExtension:AL_UserDefaultsFileNameExtension];
    NSDictionary* ud     = [NSDictionary dictionaryWithContentsOfURL:UDURL];

    if (ud) {
      [[NSUserDefaults standardUserDefaults] registerDefaults:ud];
    }
  }

  return self;
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
  for (ALLanguage* l in[ALLanguage supportedLanguages]) {
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:l.displayName
                                                  action:@selector(changeLanguage:)
                                           keyEquivalent:@""];
    item.representedObject = l;
    [self.languagesMenu addItem:item];
  }

  NSUInteger count = 0;

  for (Class aClass in[ALCoiffeurController availableTypes]) {
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:[aClass documentType]
                                                  action:@selector(AL_openUntitledDocumentOfType:)
                                           keyEquivalent:@""];
    item.representedObject = [aClass documentType];

    if (count < 2) {
      item.keyEquivalent = @"n";
      NSUInteger mask = NSCommandKeyMask;

      if (count > 0) {
        mask |= NSAlternateKeyMask;
      }

      item.keyEquivalentModifierMask = mask;
    }

    [self.makeNewDocumentMenu addItem:item];
    ++count;
  }
}

- (void)applicationWillTerminate:(NSNotification*)aNotification
{
  // Insert code here to tear down your application
}

- (void)AL_openUntitledDocumentOfType:(id)sender
{
  NSString* type = [sender representedObject];
  NSError*  error;

  ALDocumentController* controller = [NSDocumentController sharedDocumentController];

  if (![controller openUntitledDocumentOfType:type display:YES error:&error]) {
    [NSApp presentError:error];
  }
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

- (void)awakeFromNib
{
  [self setTextContainerInset:NSMakeSize(0, 0)];
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

