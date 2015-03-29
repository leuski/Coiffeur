//
//  ALCodeDocument.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/27/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALCodeDocument.h"
#import "AppDelegate.h"
#import <MGSFragaria/MGSFragaria.h>
#import "ALUncrustifyController.h"
#import "ALMainWindowController.h"

@interface ALCodeDocument () <NSTextViewDelegate>
@property (nonatomic, strong) MGSFragaria* fragaria;
@end

@implementation ALCodeDocument

- (instancetype)init
{
	if (self = [super init]) {
		self.language = [[NSUserDefaults standardUserDefaults] stringForKey:ALFormatLanguage];

		self.fragaria = [[MGSFragaria alloc] init];
		
		// we want to be the delegate
		[self.fragaria setObject:self forKey:MGSFODelegate];
		
		// Objective-C is the place to be
		[self.fragaria setObject:@"Objective-C" forKey:MGSFOSyntaxDefinitionName];
	}
	return self;
}

- (void)makeWindowControllers
{
	[[ALMainWindowController sharedInstance] addDocument:self];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	return [self.fragaria.string dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	self.fragaria.string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	return YES;
}

//+ (BOOL)autosavesInPlace {
//    return YES;
//}

- (void)setFileURL:(NSURL *)fileURL
{
	[super setFileURL:fileURL];
	if (!fileURL) return;

	NSString* uti = [[NSWorkspace sharedWorkspace] typeOfFile:[self.fileURL path] error:nil];
	if (!uti) return ;
	
	NSString* lang = [AppDelegate languageForUTI:uti];
	if (!lang) return;
	
	self.language = lang;
}

- (void)embedInView:(NSView*)container
{
	[self.fragaria embedInView:container];
	NSTextView *textView = [self.fragaria objectForKey:ro_MGSFOTextView];
	textView.delegate = self;
}

- (void)textDidChange:(NSNotification *)notification
{
	[self updateChangeCount:NSChangeDone];
}

- (NSString*)string
{
	return self.fragaria.string;
}

- (void)setString:(NSString *)string
{
	self.fragaria.string = string;
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

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
	if (self.fileURL) return YES;
	
	NSArray* fileTypes = [[NSBundle mainBundle] infoDictionary][@"CFBundleDocumentTypes"];
	for(NSDictionary* ft in fileTypes) {
		if ([ft[@"CFBundleTypeName"] isEqualToString:ALDocumentSource]) {
			savePanel.allowedFileTypes = ft[@"CFBundleTypeExtensions"];
			break;
		}
	}

	for(NSDictionary* d in [[self class] supportedLanguages]) {
		if (![self.language isEqualToString:d[@"uncrustify"]]) continue;
		NSArray* utis = d[@"uti"];
		if (utis.count == 0) break;
		NSString* uti = utis[0];
		NSString* ext = [[NSWorkspace sharedWorkspace] preferredFilenameExtensionForType:uti];
		if (!ext) break;
		NSMutableArray* exts = [savePanel.allowedFileTypes mutableCopy];
		[exts removeObject:ext];
		[exts insertObject:ext atIndex:0];
		savePanel.allowedFileTypes = exts;
		break;
	}

	return YES;
}

@end
