//
//  Document.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "Document.h"

#import "ALMainWindowController.h"
#import "ALClangFormatController.h"
#import "ALUncrustifyController.h"
#import "ALCoiffeurView.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
static NSString* const AL_ClangFormatExecutableName = @"clang-format";
static NSString* const AL_UncrustifyExecutableName = @"uncrustify";
#pragma clang diagnostic pop

@interface Document ()
@property (nonatomic, strong) ALCoiffeurView*	coiffeur;
@end

@implementation Document

- (instancetype)initWithModelController:(ALCoiffeurController* )controller {
  self = [super init];
  if (self) {
    if (!controller)
      return self = nil;

    self.model = controller;
    self.undoManager = controller.managedObjectContext.undoManager;
  }
  return self;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	return [self.model readValuesFromURL:url error:outError];
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
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
  NSError* error; //TODO
  self = [super initWithModelController:[[ALUncrustifyController alloc]
					initWithExecutableURL:[[NSBundle mainBundle] URLForAuxiliaryExecutable:AL_UncrustifyExecutableName]
													error:&error]];
  return self;
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
  NSError* error; //TODO
	self = [super initWithModelController:[[ALClangFormatController alloc]
					initWithExecutableURL:[[NSBundle mainBundle] URLForAuxiliaryExecutable:AL_ClangFormatExecutableName]
													error:&error]];

  return self;
}

+ (BOOL)contentsIsValidInString:(NSString*)string error:(NSError**)outError;
{
	return [ALClangFormatController contentsIsValidInString:string
																									 error:outError];
}
@end

