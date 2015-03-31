//
//  ALDocumentController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/30/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALDocumentController.h"
#import "NSInvocation+shouldClose.h"
#import "AppDelegate.h"
#import "Document.h"

@implementation ALDocumentController

- (void)beginOpenPanel:(NSOpenPanel*)openPanel forTypes:(NSArray*)inTypes
		 completionHandler:(void (^)(NSInteger result))completionHandler
{
	openPanel.showsHiddenFiles = YES;
	[super beginOpenPanel:openPanel
							 forTypes:inTypes
			completionHandler:completionHandler];
}

- (void)canCloseOneOfDocuments:(NSArray*)documents atIndex:(NSUInteger)index
										invocation:(NSInvocation*)invocation
{
	if (index >= documents.count) {
		[invocation invokeWithShouldClose:YES];
		return;
	}
	
	__weak ALDocumentController* weakSelf = self;
	NSDocument* document = documents[index];
	
	[document canCloseWithBlock:^(BOOL success) {
		ALDocumentController* _self = weakSelf;
		if (!_self) {
			[invocation invokeWithShouldClose:YES];
		} else if (!success) {
			[invocation invokeWithShouldClose:NO];
		} else {
			[_self canCloseOneOfDocuments:documents
														atIndex:index + 1
												 invocation:invocation];
		}
	}];
	
}

- (void) controller:(NSDocumentController*)controller
doCloseAllDocuments:(BOOL)doClose contextInfo:(void*)contextInfo
{
	NSInvocation* invocation = (__bridge_transfer NSInvocation*)contextInfo;
	
	if (doClose) {
		for (NSDocument* doc in [self.documents copy]) {
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

- (void)closeAllDocumentsWithDelegate:(id)delegate
									didCloseAllSelector:(SEL)didCloseAllSelector
													contextInfo:(void*)contextInfo
{
	NSInvocation* target = [NSInvocation invocationWithTarget:delegate
																				shouldCloseSelector:didCloseAllSelector
																										 object:self
																								contextInfo:contextInfo];
	
	NSInvocation* invocation = [NSInvocation invocationWithTarget:self
																						shouldCloseSelector:@selector(controller:doCloseAllDocuments:contextInfo:)
																												 object:self
																										contextInfo:(__bridge_retained void*)target];
	
	if (self.documents.count == 0) {
		[invocation invokeWithShouldClose:YES];
	} else {
		[self canCloseOneOfDocuments:[self.documents copy]
												 atIndex:0
											invocation:invocation];
	}
}

- (NSString*)typeForContentsOfURL:(NSURL*)url error:(NSError**)outError
{
	NSString* type = [super typeForContentsOfURL:url error:outError];
	
	if ([type isEqualToString:ALDocumentClangFormatStyle] ||
			[type isEqualToString:ALDocumentUncrustifyStyle]) {
		NSString* data = [NSString stringWithContentsOfURL:url
																							encoding:NSUTF8StringEncoding
																								 error:outError];
		if (data) {
			if ([ALClangFormatDocument contentsIsValidInString:data error:outError])
				return ALDocumentClangFormatStyle;
			if ([ALUncrustifyDocument contentsIsValidInString:data error:outError])
				return ALDocumentUncrustifyStyle;
			
			return nil;
		}
	}
	
	return type;
}

- (void)AL_openExistingDocumentOrUntitledFile:(NSArray*)documents openedType:(NSArray*)openedTypes
{
	NSDocumentController* controller
	= [NSDocumentController sharedDocumentController];
	
	while (documents.count != 0) {
		NSURL* url = documents[0];
		documents = [documents subarrayWithRange:NSMakeRange(1, documents.count-1)];
		NSString* type = [controller typeForContentsOfURL:url error:nil];
		if (type == nil) continue;
		if ([openedTypes containsObject:type]) continue;
		
		[controller openDocumentWithContentsOfURL:url
																			display:YES
														completionHandler:^(NSDocument* document,
																								BOOL documentWasAlreadyOpen,
																								NSError* error) {
															NSArray* localOpenedTypes = openedTypes;
															if (document || documentWasAlreadyOpen) {
																if ([type isEqualToString:ALDocumentSource]) {
																	localOpenedTypes = [localOpenedTypes arrayByAddingObject:type];
																} else {
																	localOpenedTypes = [localOpenedTypes arrayByAddingObject:ALDocumentClangFormatStyle];
																	localOpenedTypes = [localOpenedTypes arrayByAddingObject:ALDocumentUncrustifyStyle];
																}
															}
															[self AL_openExistingDocumentOrUntitledFile:documents
																															 openedType:localOpenedTypes];
														}];
		
	}
	
	if (openedTypes.count == 0)
		[controller openUntitledDocumentAndDisplay:YES
																				 error:nil];
}

- (void)restoreState
{
	NSArray* documents  = [self recentDocumentURLs];
	
	documents = @[
								[NSURL fileURLWithPath:@"/Users/leuski/Documents/Projects/Coiffeur/CoiffeurTests/_clang-format"],
								[NSURL fileURLWithPath:@"/Users/leuski/Documents/Projects/Coiffeur/CoiffeurTests/Info.plist"],
								[NSURL fileURLWithPath:@"/Users/leuski/Documents/Projects/Coiffeur/CoiffeurTests/uncrustify.cfg"],
								[NSURL fileURLWithPath:@"/Users/leuski/Documents/Projects/Coiffeur/CoiffeurTests/CoiffeurTests.m"]
								
								];
	
	[self AL_openExistingDocumentOrUntitledFile:documents
																	 openedType:@[]];
}

//- (void)openDocumentWithContentsOfURL:(NSURL*)url display:(BOOL)displayDocument
//										completionHandler:(void (^)(NSDocument* document,
//														BOOL documentWasAlreadyOpen,
//														NSError* error))completionHandler
//{
//	void
//	(^b)(NSDocument* document, BOOL documentWasAlreadyOpen, NSError* error) = ^(
//					NSDocument* document, BOOL documentWasAlreadyOpen, NSError* error) {
//		completionHandler(document, documentWasAlreadyOpen, error);
//	};
//
//	[super openDocumentWithContentsOfURL:url
//															 display:displayDocument
//										 completionHandler:b];
//}
@end
