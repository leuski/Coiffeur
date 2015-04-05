//
//  ALCoiffeurController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/28/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALCoiffeurController.h"
#import "ALCoreData.h"
#import "ALRoot.h"
#import "ALOption.h"

#import "ALClangFormatController.h"
#import "ALUncrustifyController.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
NSString* const ALFormatLanguage     = @"ALFormatLanguage";
NSString* const ALFormatFragment     = @"ALFormatFragment";

NSString* const ALSignedOptionType   = @"signed";
NSString* const ALUnsignedOptionType = @"unsigned";
NSString* const ALStringOptionType   = @"string";

NSString* const ALNewLine = @"\n";
NSString* const ALSpace   = @" ";

#pragma clang diagnostic pop

NSComparator ALKeyComparator = ^NSComparisonResult (ALOption* obj1, ALOption* obj2) {
  return [obj1.indexKey compare:obj2.indexKey];
};

@interface ALCoiffeurController ()
@property (nonatomic, strong) NSManagedObjectModel* managedObjectModel;
@end

@implementation ALCoiffeurController

+ (NSArray*)availableTypes
{
  static dispatch_once_t onceToken;
  static NSArray* types;

  dispatch_once(&onceToken, ^{
    types = @[[ALClangFormatController class], [ALUncrustifyController class]];
  });
  return types;
}

+ (BOOL)contentsIsValidInString:(NSString*)string error:(NSError**)outError
{
  return NO;
}

+ (NSString*)documentType
{
  return nil;
}

- (NSString*)documentType
{
  return [[self class] documentType];
}

- (instancetype)initWithExecutableURL:(NSURL*)executableURL error:(NSError**)outError
{
  if (self = [super init]) {
    self.executableURL = executableURL;

    NSManagedObjectModel*   mom = [NSManagedObjectModel mergedModelFromBundles:nil];
    NSManagedObjectContext* moc
      = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    moc.persistentStoreCoordinator
      = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];

    if (nil == [moc.persistentStoreCoordinator
                addPersistentStoreWithType:NSInMemoryStoreType
                             configuration:nil
                                       URL:nil
                                   options:nil
                                     error:outError])
    {
      return self = nil;
    }

    moc.undoManager = [[NSUndoManager alloc] init];

    self.managedObjectModel   = mom;
    self.managedObjectContext = moc;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(modelDidChange:)
                                                 name:
     NSManagedObjectContextObjectsDidChangeNotification
                                               object:self.managedObjectContext];
  }

  return self;
}

- (instancetype)initWithError:(NSError**)outError
{
  return [self initWithExecutableURL:nil error:outError];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)modelDidChange:(NSNotification*)note
{
  [self format];
}

- (BOOL)format
{
  BOOL result = NO;

  id<ALCoiffeurControllerDelegate> del = self.delegate;

  if (!del
      || ![del respondsToSelector:@selector(textToFormatByCoiffeurController:attributes:)]
      || ![del respondsToSelector:@selector(coiffeurController:setText:)])
  {
    return result;
  }

  NSDictionary* attributes;
  NSString*     input = [del textToFormatByCoiffeurController:self
                                                   attributes:&attributes];

  if (input) {
    result = [self format:input
               attributes:attributes
          completionBlock:^(NSString* output, NSError* error) {
            if (output) {
              [del     coiffeurController:self
                                  setText:output];
            }
          }];
  }

  return result;
}

- (BOOL)   format:(NSString*)input
       attributes:(NSDictionary*)attributes
  completionBlock:(void (^)(NSString*, NSError*))block
{
  return NO;
}

- (BOOL)readOptionsFromLineArray:(NSArray*)lines
{
  return NO;
}

- (BOOL)readValuesFromLineArray:(NSArray*)lines
{
  return NO;
}

- (BOOL)readOptionsFromString:(NSString*)text
{
  NSArray* lines = [text componentsSeparatedByString:ALNewLine];

  if (!lines) {
    return NO;
  }

  [self.managedObjectContext disableUndoRegistration];

  self.root = [ALRoot objectInContext:self.managedObjectContext];

  BOOL result = [self readOptionsFromLineArray:lines];

  [self.managedObjectContext enableUndoRegistration];

  return result;
}

- (BOOL)readValuesFromString:(NSString*)text
{
  NSArray* lines = [text componentsSeparatedByString:ALNewLine];

  if (!lines) {
    return NO;
  }

  [self.managedObjectContext disableUndoRegistration];

  BOOL result = [self readValuesFromLineArray:lines];

  [self.managedObjectContext enableUndoRegistration];

  return result;
}

- (BOOL)readValuesFromURL:(NSURL*)absoluteURL error:(NSError**)error
{
  NSString* data = [NSString stringWithContentsOfURL:absoluteURL
                                            encoding:NSUTF8StringEncoding
                                               error:error];

  return data != nil && [self readValuesFromString:data];
}

- (BOOL)writeValuesToURL:(NSURL*)absoluteURL error:(NSError**)error
{
  return NO;
}

- (NSUInteger)pageGuideColumn
{
  return 0;
}

- (ALOption*)optionWithKey:(NSString*)key
{
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
  return [ALOption firstObjectInContext:self.managedObjectContext
                          withPredicate:[NSPredicate predicateWithFormat:@"indexKey = %@", key]
                                  error:nil];

#pragma clang diagnostic pop
}

- (NSTask*)startExecutableWithArguments:(NSArray*)args
                       workingDirectory:(NSString*)workingDirectory
                                  input:(NSString*)input
                                  error:(NSError**)outError
{
  NSURL* executableURL = self.executableURL;

  @try {
    NSTask* theTask = [[NSTask alloc] init];

    NSPipe* outPipe = [NSPipe pipe];
    [theTask setStandardOutput:outPipe];

    NSPipe*       inpPipe     = [NSPipe pipe];
    NSFileHandle* writeHandle = input ? [inpPipe fileHandleForWriting] : nil;
    [theTask setStandardInput:inpPipe];

    NSPipe* errPipe = [NSPipe pipe];
    [theTask setStandardError:errPipe];

    [theTask setLaunchPath:executableURL.path];

    if (args) {
      [theTask setArguments:args];
    }

    if (workingDirectory) {
      [theTask setCurrentDirectoryPath:workingDirectory];
    }

    [theTask launch];

    if (writeHandle) {
      [writeHandle writeData:[input dataUsingEncoding:NSUTF8StringEncoding]];
      [writeHandle closeFile];
    }

    if (outError) {
      *outError = nil;
    }

    return theTask;
  } @catch (NSException* ex) {
    if (outError) {
      *outError = [NSError errorWithDomain:NSPOSIXErrorDomain
                                      code:0
                                  userInfo:@{NSLocalizedDescriptionKey: ex.reason ? ex.reason : @""}
                  ];
    }

    return nil;
  }
}

- (NSString*)runTask:(NSTask*)task error:(NSError**)outError
{
  NSFileHandle* outHandle = [task.standardOutput fileHandleForReading];
  NSData*       outData   = [outHandle readDataToEndOfFile];

  NSFileHandle* errHandle = [task.standardError fileHandleForReading];
  NSData*       errData   = [errHandle readDataToEndOfFile];

  [task waitUntilExit];

  int status = [task terminationStatus];

  if (status == 0) {
    if (outError) {
      *outError = nil;
    }

    return [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
  }

  if (outError) {
    NSString* errText = [[NSString alloc] initWithData:errData encoding:NSUTF8StringEncoding];

    if (!errText) {
      NSString* format = NSLocalizedString(@"Format executable error code %d", NULL);
      errText = [NSString stringWithFormat:format, status];
    }

    *outError = [NSError errorWithDomain:NSPOSIXErrorDomain
                                    code:status
                                userInfo:@{NSLocalizedDescriptionKey: errText}];
  }

  return nil;
}

- (NSError*)runExecutableWithArguments:(NSArray*)args
                      workingDirectory:(NSString*)workingDirectory
                                 input:(NSString*)input
                       completionBlock:(void (^)(NSString*, NSError*))block
{
  NSError* error;
  NSTask*  theTask = [self startExecutableWithArguments:args
                                       workingDirectory:workingDirectory
                                                  input:input
                                                  error:&error];

  if (!theTask) {
    return error;
  }

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    @autoreleasepool {
      NSError* localError;
      NSString* text = [self runTask:theTask error:&localError];
      dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
          block(text, localError);
        }
      });
    }
  });

  return nil;
}

- (NSString*)runExecutableWithArguments:(NSArray*)args
                       workingDirectory:(NSString*)workingDirectory
                                  input:(NSString*)input
                                  error:(NSError**)outError
{
  NSTask* theTask = [self startExecutableWithArguments:args
                                      workingDirectory:workingDirectory
                                                 input:input
                                                 error:outError];

  if (!theTask) {
    return nil;
  }

  return [self runTask:theTask error:outError];
}

@end

