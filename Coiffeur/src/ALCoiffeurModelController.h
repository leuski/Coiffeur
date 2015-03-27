//
//  ALCoiffeurModelController.h
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ALRoot;
@class ALCoiffeurModelController;

@protocol ALCoiffeurModelControllerDelegate <NSObject>
@optional
- (NSString*)textToUncrustifyByCoiffeurModelController:(ALCoiffeurModelController*)controller attributes:(NSDictionary**)attributes;
- (void)coiffeurModelController:(ALCoiffeurModelController*)controller setUncrustifiedText:(NSString*)text;
@end

@interface ALCoiffeurModelController : NSObject

@property (nonatomic, strong) NSURL* uncrustifyURL;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) ALRoot* root;
@property (nonatomic, weak) id<ALCoiffeurModelControllerDelegate> delegate;

- (instancetype)initWithUncrustifyURL:(NSURL*)url moc:(NSManagedObjectContext*)moc error:(NSError**)outError;

- (BOOL)readOptionsFromString:(NSString*)text;
- (BOOL)readValuesFromString:(NSString*)text;
- (BOOL)writeValuesToURL:(NSURL *)absoluteURL error:(NSError **)error;

- (NSError*)runUncrustify:(NSArray*)args text:(NSString*)input completionBlock:(void (^)(NSString*, NSError*)) block;
- (NSString*)runUncrustify:(NSArray*)args text:(NSString*)input error:(NSError**)outError;

- (BOOL)uncrustify:(NSString*)input
				attributes:(NSDictionary*)attributes
	 completionBlock:(void (^)(NSString*, NSError*)) block;

@end

extern NSString * const ALFormatLanguage;
extern NSString * const ALFormatFragment;
