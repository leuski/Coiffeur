//
//  ALDocument.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/31/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALDocument.h"
#import "ALMainWindowController.h"

@implementation ALDocument


+ (BOOL)autosavesInPlace {
    return YES;
}

- (void)makeWindowControllers
{
	[[ALMainWindowController sharedInstance] addDocument:self];
}

- (void)restoreDocumentWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler
{
	[super restoreDocumentWindowWithIdentifier:identifier state:state completionHandler:completionHandler];
}

- (void)updateChangeCount:(NSDocumentChangeType)change
{
	[self willChangeValueForKey:@"isDocumentEdited"];
	[super updateChangeCount:change];
	[self didChangeValueForKey:@"isDocumentEdited"];
}

- (void)updateChangeCountWithToken:(id)changeCountToken forSaveOperation:(NSSaveOperationType)saveOperation
{
	[self willChangeValueForKey:@"isDocumentEdited"];
	[super updateChangeCountWithToken:changeCountToken forSaveOperation:saveOperation];
	[self didChangeValueForKey:@"isDocumentEdited"];
}

- (void)close
{
	for (NSWindowController* windowCtrl in [self.windowControllers copy]) {
		if ([windowCtrl respondsToSelector:@selector(removeDocument:)]) {
			[(id)windowCtrl removeDocument:self];
		}
	}
	[super close];
}

@end

@implementation NSDocument (shouldClose)

- (void)AL_document:(NSDocument*)doc shouldClose:(BOOL)shouldClose
		completionBlock:(void*)contextInfo
{
	void (^completeBlock)(BOOL) = (__bridge_transfer void (^)(BOOL))contextInfo;
	completeBlock(shouldClose);
}

- (void)canCloseWithBlock:(void (^)(BOOL))block
{
	[self canCloseDocumentWithDelegate:self
								 shouldCloseSelector:@selector(AL_document:shouldClose:completionBlock:)
												 contextInfo:(__bridge_retained void*)[block copy]];
}

@end