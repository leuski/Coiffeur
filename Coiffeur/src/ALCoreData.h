//
//  NSManagedObjectContext+Fetch.h
//  WebAnnotator
//
//  Created by Anton Leuski on 4/18/11.
//  Copyright 2011 Anton Leuski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (ALCoreData)

- (NSArray*)fetch:(NSString*)entityName withPredicate:(NSPredicate*)predicate error:(NSError**)outError;
- (NSManagedObject*)fetchSingle:(NSString*)entityName withPredicate:(NSPredicate*)predicate error:(NSError**)outError;

- (void)disableUndoRegistration;
- (void)enableUndoRegistration;

- (void)beginActionWithName:(NSString*)name;
- (void)endAction;

+ (NSManagedObjectContext*)managedObjectContextWithModelWithName:(NSString*)fileName concurrencyType:(NSManagedObjectContextConcurrencyType)ct;
+ (NSManagedObjectContext*)managedObjectContextWithModelWithName:(NSString*)fileName inBundle:(NSBundle*)bundle concurrencyType:(NSManagedObjectContextConcurrencyType)ct;
@end

@interface NSAttributeDescription (ALCoreData)

- (id)valueWithXMLAttributeValue:(NSString*)attrValue;
- (NSString*)xmlAttributeValueWithValue:(id)value;

@end

@interface NSManagedObject (ALCoreData)

+ (NSString*)entityNameInContext:(NSManagedObjectContext* )managedObjectContext;

+ (instancetype)objectInContext:(NSManagedObjectContext* )managedObjectContext;

+ (NSArray*)allObjectsInContext:(NSManagedObjectContext* )managedObjectContext;
+ (NSArray*)allObjectsInContext:(NSManagedObjectContext* )managedObjectContext error:(NSError**)outError;
+ (NSArray*)allObjectsInContext:(NSManagedObjectContext* )managedObjectContext withPredicate:(NSPredicate*)predicate error:(NSError**)outError;

+ (instancetype)firstObjectInContext:(NSManagedObjectContext* )managedObjectContext;
+ (instancetype)firstObjectInContext:(NSManagedObjectContext* )managedObjectContext error:(NSError**)outError;
+ (instancetype)firstObjectInContext:(NSManagedObjectContext* )managedObjectContext withPredicate:(NSPredicate*)predicate error:(NSError**)outError;

+ (void)deleteAllObjectsFromContext:(NSManagedObjectContext* )managedObjectContext;

@end

NS_INLINE id ALManagedObjectAccessor(NSManagedObject* obj)
{
	NSManagedObjectContext* moc = obj.managedObjectContext;
	return moc && [moc existingObjectWithID:obj.objectID error:nil] ? obj : nil;
}
