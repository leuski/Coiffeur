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

@interface ALCoiffeurModelController : NSObject

@property (nonatomic, strong) NSURL* uncrustifyURL;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) ALRoot* root;

- (instancetype)initWithUncrustifyURL:(NSURL*)url moc:(NSManagedObjectContext*)moc;

- (BOOL)readOptionsFromString:(NSString*)text;
- (BOOL)readValuesFromString:(NSString*)text;
- (BOOL)writeValuesToURL:(NSURL *)absoluteURL error:(NSError **)error;

- (BOOL)runUncrustify:(NSArray*)args text:(NSString*)input completionBlock:(void (^)(NSString*)) block;
- (NSString*)runUncrustify:(NSArray*)args text:(NSString*)input;
- (BOOL)uncrustify:(NSString*)input completionBlock:(void (^)(NSString*)) block;

@end
