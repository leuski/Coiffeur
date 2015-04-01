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

+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler
{
	[[NSDocumentController class] restoreWindowWithIdentifier:identifier state:state completionHandler:completionHandler];
}


- (void)reopenDocumentForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler
{
	[super reopenDocumentForURL:urlOrNil withContentsOfURL:contentsURL display:displayDocument completionHandler:completionHandler];
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
