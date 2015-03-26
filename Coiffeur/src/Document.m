//
//  Document.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "Document.h"

#import "ALCoreData.h"
#import "ALMainWindowController.h"

#import "ALRoot.h"
#import "ALOption.h"
#import "ALSection.h"
#import "ALNode+model.h"

#import "ALCoiffeurModelController.h"

@interface Document ()
@end

static NSString * const ALUncrustifyFileType = @"Uncrustify";

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
			self.model = [[ALCoiffeurModelController alloc] initWithUncrustifyURL:[[NSBundle mainBundle] URLForAuxiliaryExecutable:@"uncrustify"]
																																				moc:self.managedObjectContext];
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	// Add any code here that needs to be executed once the windowController has loaded the document's window.
}

//+ (BOOL)autosavesInPlace {
//	return YES;
//}

- (void)makeWindowControllers
{
	[self addWindowController:[[ALMainWindowController alloc] initWithWindowNibName:@"ALMainWindowController"]];
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

- (IBAction)uncrustify:(id)sender
{
	ALMainWindowController* wc = nil;
	for(id w in self.windowControllers) {
		if ([w isKindOfClass:[ALMainWindowController class]]) {
			wc = w;
			break;
		}
	}
	
	if (!wc) return;
	
	NSString* text = wc.exampleText;
	[self.model uncrustify:text completionBlock:^(NSString* text) {
		if (text)
			wc.exampleText = text;
	}];
}


@end
