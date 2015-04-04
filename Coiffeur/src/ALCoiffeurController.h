//
//  ALCoiffeurController.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/28/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ALRoot;
@class ALOption;
@class ALCoiffeurController;

@protocol ALCoiffeurControllerDelegate<NSObject>
@optional
- (NSString*)textToFormatByCoiffeurController:(ALCoiffeurController*)controller
																	 attributes:(NSDictionary**)attributes;
- (void)coiffeurController:(ALCoiffeurController*)controller setText:(NSString*)text;
@end

@interface ALCoiffeurController : NSObject
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) ALRoot* root;
@property (nonatomic, weak) id<ALCoiffeurControllerDelegate> delegate;
@property (nonatomic, strong) NSURL* executableURL;
@property (nonatomic, assign, readonly) NSUInteger pageGuideColumn;

- (instancetype)initWithExecutableURL:(NSURL*)executableURL error:(NSError**)outError;

- (BOOL) format:(NSString*)input attributes:(NSDictionary*)attributes
completionBlock:(void (^)(NSString*, NSError*)) block;
- (BOOL)format; // use the delegate

- (BOOL)AL_readOptionsFromLineArray:(NSArray*)lines;
- (BOOL)AL_readValuesFromLineArray:(NSArray*)lines;

- (BOOL)readOptionsFromString:(NSString*)text;
- (BOOL)readValuesFromString:(NSString*)text;
- (BOOL)readValuesFromURL:(NSURL *)absoluteURL error:(NSError **)error;
- (BOOL)writeValuesToURL:(NSURL *)absoluteURL error:(NSError **)error;

- (NSError*)runExecutableWithArguments:(NSArray*)args workingDirectory:(NSString*)workingDirectory input:(NSString*)input completionBlock:(void (^)(NSString*, NSError*))block;

- (NSString*)runExecutableWithArguments:(NSArray*)args workingDirectory:(NSString*)workingDirectory input:(NSString*)input error:(NSError**)outError;

- (ALOption*)optionWithKey:(NSString*)key;

+ (BOOL)contentsIsValidInString:(NSString*)string error:(NSError**)outError;

@end

extern NSString * const ALFormatLanguage;
extern NSString * const ALFormatFragment;
