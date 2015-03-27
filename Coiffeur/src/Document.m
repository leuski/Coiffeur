//
//  Document.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "Document.h"

#import "AppDelegate.h"
#import "ALCoreData.h"
#import "ALMainWindowController.h"
#import "ALCoiffeurModelController.h"


@interface Document () <ALCoiffeurModelControllerDelegate>
@property (nonatomic, weak) ALMainWindowController* mainWindowController;
@property (nonatomic, strong) NSString* language;
@property (nonatomic, strong) NSURL* codeURL;
@end

static NSString * const ALUncrustifyFileType = @"Uncrustify";

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
			
			self.language = [[NSUserDefaults standardUserDefaults] stringForKey:ALFormatLanguage];
			
			self.model = [[ALCoiffeurModelController alloc] initWithUncrustifyURL:[[NSBundle mainBundle] URLForAuxiliaryExecutable:@"uncrustify"]
																																				moc:self.managedObjectContext
																																			error:nil];
			self.model.delegate = self;
			
    }
    return self;
}

- (void)makeWindowControllers
{
	ALMainWindowController* wc = [[ALMainWindowController alloc] initWithWindowNibName:@"ALMainWindowController"];
	[self addWindowController:wc];
	self.mainWindowController = wc;

}

- (BOOL)readValuesFromURL:(NSURL *)absoluteURL error:(NSError *__autoreleasing *)error
{
	NSString* data = [NSString stringWithContentsOfURL:absoluteURL encoding:NSUTF8StringEncoding error:error];
	if (!data) return NO;
	
	return [self.model readValuesFromString:data];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError *__autoreleasing *)error
{
	if (![typeName isEqualToString:ALUncrustifyFileType])
		return [super readFromURL:absoluteURL ofType:typeName error:error];

	[self.managedObjectContext disableUndoRegistration];
	BOOL result	= [self readValuesFromURL:absoluteURL error:error];
	[self.managedObjectContext enableUndoRegistration];

	return result;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)error
{
	if (![typeName isEqualToString:ALUncrustifyFileType])
		return [super writeToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation originalContentsURL:absoluteOriginalContentsURL error:error];

	return [self.model writeValuesToURL:absoluteURL error:error];
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
	savePanel.showsHiddenFiles = YES;
	return YES;
}

- (NSString*)languageForURL:(NSURL*)url
{
	NSError* error;
	NSString* uti = [[NSWorkspace sharedWorkspace] typeOfFile:[url path] error:&error];
	if (!uti) return self.language;
	NSString* l = [AppDelegate languageForUTI:uti];
	return l ? l : self.language;
}

- (void)setCodeURL:(NSURL *)codeURL
{
	self->_codeURL = codeURL;
	self.language = [self languageForURL:self.codeURL];

	if (codeURL) {
		[[NSUserDefaults standardUserDefaults] setObject:[codeURL absoluteString] forKey:@"ALCodeURL"];
	}
}

- (BOOL)readCodeFromURL:(NSURL*)url error:(NSError *__autoreleasing *)error
{
	NSString* code = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:error];
	if (!code) {
		return NO;
	}
	
	self.mainWindowController.exampleText = code;
	self.codeURL = url;
	return YES;
}

- (BOOL)writeCodeToURL:(NSURL*)url error:(NSError *__autoreleasing *)error
{
	BOOL result = [self.mainWindowController.exampleText writeToURL:url
																											 atomically:YES
																												 encoding:NSUTF8StringEncoding
																														error:error];
	if (result) {
		self.codeURL = url;
	}

	return result;
}

- (IBAction)openCode:(id)sender
{
	NSOpenPanel* op = [NSOpenPanel openPanel];
	
	[op beginSheetModalForWindow:self.mainWindowController.window completionHandler:^(NSInteger result) {
		if (result != NSFileHandlingPanelOKButton) return;

		[op orderOut:nil];
		
		NSError* error;
		if (![self readCodeFromURL:[op URL] error:&error]) {
			[self presentError:error];
		}
	}];
}

- (IBAction)saveCode:(id)sender
{
	if (self.codeURL) {
		NSError* error;
		if (![self writeCodeToURL:self.codeURL error:&error]) {
			[self presentError:error];
		}
	} else {
		[self saveCodeAs:sender];
	}
}

- (IBAction)saveCodeAs:(id)sender
{
	NSSavePanel* sp = [NSSavePanel savePanel];
	[sp beginSheetModalForWindow:self.mainWindowController.window completionHandler:^(NSInteger result) {
		if (result != NSFileHandlingPanelOKButton) return;
		
		[sp orderOut:nil];
		
		NSError* error;
		if (![self writeCodeToURL:[sp URL] error:&error]) {
			[self presentError:error];
		}

	}];
}

- (IBAction)uncrustify:(id)sender
{
	ALMainWindowController* wc = self.mainWindowController;
	if (!wc) return;
	
	NSString* text = wc.exampleText;
	[self.model uncrustify:text
							attributes:@{ALFormatLanguage:self.language, ALFormatFragment : @(NO)}
				 completionBlock:^(NSString* text, NSError* error) {
		if (text)
			wc.exampleText = text;
		if (error)
			NSLog(@"%@", error);
	}];
}

- (NSString*)textToUncrustifyByCoiffeurModelController:(ALCoiffeurModelController *)controller attributes:(NSDictionary *__autoreleasing *)attributes
{
	ALMainWindowController* wc = self.mainWindowController;
	if (!wc) return nil;
	*attributes = @{ALFormatLanguage:self.language, ALFormatFragment : @(NO)};
	return wc.exampleText;
}

- (void)coiffeurModelController:(ALCoiffeurModelController *)controller setUncrustifiedText:(NSString *)text
{
	if (!text) return;
	ALMainWindowController* wc = self.mainWindowController;
	if (!wc) return ;
	wc.exampleText = text;
}

- (IBAction)changeLanguage:(NSMenuItem *)anItem
{
	NSDictionary* props = [anItem representedObject];
	self.language = props[@"uncrustify"];
	[[NSUserDefaults standardUserDefaults] setObject:self.language forKey:ALFormatLanguage];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	if (anItem.action == @selector(changeLanguage:)) {
		NSDictionary* props = [anItem representedObject];
		anItem.state = [self.language isEqualToString:props[@"uncrustify"]]
			? NSOnState : NSOffState;
	}
	return YES;
}

@end
