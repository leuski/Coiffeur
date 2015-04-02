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
#import "ALClangFormatController.h"
#import "ALUncrustifyController.h"
#import "ALCoiffeurView.h"


@interface Document ()
@property (nonatomic, strong) ALCoiffeurView*	coiffeur;
@end

@implementation Document

- (instancetype)initWithModelController:(ALCoiffeurController* )controller {
    self = [super init];
    if (self) {
			self.model = controller;
			self.undoManager = controller.managedObjectContext.undoManager;
    }
    return self;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	return [self.model readValuesFromURL:url error:outError];
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	return [self.model writeValuesToURL:url error:outError];
}

+ (BOOL)autosavesInPlace
{
	return YES;
}

- (void)makeWindowControllers
{
	ALMainWindowController* controller = [ALMainWindowController new];
	[self addWindowController:controller];
}

- (void)embedInView:(NSView*)container
{
	self.coiffeur = [[ALCoiffeurView alloc] initWithModel:self.model bundle:nil];
	[self.coiffeur embedInView:container];
}

+ (BOOL)contentsIsValidInString:(NSString*)string error:(NSError**)outError
{
	return NO;
}

- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
	[self.model.managedObjectContext commitEditing];
	[super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

@end

@implementation ALUncrustifyDocument
- (instancetype)init
{
	return self = [super initWithModelController:[[ALUncrustifyController alloc]
					initWithExecutableURL:[[NSBundle mainBundle]
									URLForAuxiliaryExecutable:@"uncrustify"]
													error:nil]];
}

+ (BOOL)contentsIsValidInString:(NSString*)string error:(NSError**)outError;
{
	return [ALUncrustifyController contentsIsValidInString:string
																									 error:outError];
}

@end

@implementation ALClangFormatDocument
- (instancetype)init
{
	return self = [super initWithModelController:[[ALClangFormatController alloc]
					initWithExecutableURL:[[NSBundle mainBundle]
									URLForAuxiliaryExecutable:@"clang-format"]
													error:nil]];
}

+ (BOOL)contentsIsValidInString:(NSString*)string error:(NSError**)outError;
{
	return [ALClangFormatController contentsIsValidInString:string
																									 error:outError];
}
@end

