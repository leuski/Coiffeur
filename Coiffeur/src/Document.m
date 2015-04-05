//
//  Document.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "Document.h"

#import "ALMainWindowController.h"
#import "ALCoiffeurController.h"
#import "ALCoiffeurView.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
static NSString* const ALCoiffeurErrorDomain = @"Coiffeur";
#pragma clang diagnostic pop

@interface Document ()
@property (nonatomic, strong) ALCoiffeurView* coiffeur;
@end

@implementation Document

- (instancetype)initWithType:(NSString*)typeName error:(NSError**)outError
{
  if (self = [super initWithType:typeName error:outError]) {
    self.model = [self AL_modelControllerOfType:typeName error:outError];

    if (!self.model) {
      self = nil;
    }
  }

  return self;
}

- (NSUndoManager*)undoManager
{
  return self.model ? self.model.managedObjectContext.undoManager : [super undoManager];
}

- (ALCoiffeurController*)AL_modelControllerOfType:(NSString*)type error:(NSError**)outError
{
  for (Class c in[ALCoiffeurController availableTypes]) {
    if ([type isEqualToString:[c documentType]]) {
      return [[c alloc] initWithError:outError];
    }
  }

  if (outError) {
    NSString* description
      = [NSString stringWithFormat:NSLocalizedString(@"Unknown document type “%@”", NULL), type];
    *outError = [NSError errorWithDomain:ALCoiffeurErrorDomain
                                    code:0
                                userInfo:@{NSLocalizedDescriptionKey: description}];
  }

  return nil;
}

- (BOOL)AL_ensureWeHaveModelOfType:(NSString*)typeName
                    errorFormatKey:(NSString*)errorFormatKey
                             error:(NSError**)outError
{
  if (self.model) {
    if (![typeName isEqualToString:self.model.documentType]) {
      if (outError) {
        NSString* description = [NSString stringWithFormat:NSLocalizedString(errorFormatKey, NULL)
                                 , typeName, self.model.documentType];
        *outError = [NSError errorWithDomain:ALCoiffeurErrorDomain
                                        code:0
                                    userInfo:@{NSLocalizedDescriptionKey: description}];
      }

      return NO;
    }
  } else {
    self.model = [self AL_modelControllerOfType:typeName error:outError];

    if (!self.model) {
      return NO;
    }
  }

  return YES;
}

- (BOOL)readFromURL:(NSURL*)url ofType:(NSString*)typeName error:(NSError**)outError
{
  if (![self AL_ensureWeHaveModelOfType:typeName
                         errorFormatKey:@"Cannot read content of document “%@” into document “%@”"
                                  error:outError])
  {
    return NO;
  }

  return [self.model readValuesFromURL:url error:outError];
}

- (BOOL)writeToURL:(NSURL*)url ofType:(NSString*)typeName error:(NSError**)outError
{
  if (![self AL_ensureWeHaveModelOfType:typeName
                         errorFormatKey:@"Cannot write content of document “%2$@” as “%1$@”"
                                  error:outError])
  {
    return NO;
  }

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

- (void)canCloseDocumentWithDelegate:(id)delegate
                 shouldCloseSelector:(SEL)shouldCloseSelector
                         contextInfo:(void*)contextInfo
{
  [self.model.managedObjectContext commitEditing];
  [super canCloseDocumentWithDelegate:delegate
                  shouldCloseSelector:shouldCloseSelector
                          contextInfo:contextInfo];
}

- (NSArray*)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation
{
  return @[self.model.documentType];
}

@end

