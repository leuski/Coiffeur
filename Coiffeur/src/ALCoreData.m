//
//  NSManagedObjectContext+Fetch.m
//  WebAnnotator
//
//  Created by Anton Leuski on 4/18/11.
//  Copyright 2011 Anton Leuski. All rights reserved.
//

#import "ALCoreData.h"
#import "NSData+ALBase64.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
static NSString* const kALTrue = @"true";
static NSString* const kALFalse = @"false";
#pragma clang diagnostic pop


@implementation NSManagedObjectContext (ALCoreData)

// ---------------------------------------------------------------------------------

- (NSArray*)fetch:(NSString*)entityName withPredicate:(NSPredicate*)predicate error:(NSError**)outError {
	NSEntityDescription*	entity	= [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
	
	NSFetchRequest*			fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
	if (predicate)
		[fetchRequest setPredicate: predicate];
	
	NSError*	fetchError	= nil;
	NSArray*	results		= [self executeFetchRequest:fetchRequest error:&fetchError];
	
	if (fetchError != nil) {
		if (outError) 
			*outError = fetchError;
		return [NSArray array];
	}
	
	if (results == nil) {
		return [NSArray array];
	}
	
	return results;
}

// ---------------------------------------------------------------------------------

- (NSManagedObject*)fetchSingle:(NSString*)entityName withPredicate:(NSPredicate*)predicate error:(NSError**)outError {
	NSArray * results	= [self fetch:entityName withPredicate:predicate error:outError];
	return [results count] > 0 ? [results objectAtIndex:0] : nil;
}

- (void)disableUndoRegistration {
	[self processPendingChanges];
	[[self undoManager] disableUndoRegistration];
}

- (void)enableUndoRegistration {
	[self processPendingChanges];
	[[self undoManager] enableUndoRegistration];
}

- (void)beginActionWithName:(NSString*)name
{
	[self.undoManager beginUndoGrouping];
	[self.undoManager setActionName:name];
}

- (void)endAction
{
	[self.undoManager endUndoGrouping];
}

+ (NSManagedObjectContext*)managedObjectContextWithModelWithName:(NSString*)fileName concurrencyType:(NSManagedObjectContextConcurrencyType)ct
{
	return [self managedObjectContextWithModelWithName:fileName inBundle:[NSBundle mainBundle] concurrencyType:ct];
}

+ (NSManagedObjectContext*)managedObjectContextWithModelWithName:(NSString*)fileName inBundle:(NSBundle*)bundle concurrencyType:(NSManagedObjectContextConcurrencyType)ct;
{
	NSURL* modelURL = [bundle URLForResource:fileName withExtension:@"momd"];
	NSManagedObjectModel* managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

	if (!managedObjectModel) {
		ALLogError(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
		return nil;
	}

	NSError* error = nil;
	NSPersistentStoreCoordinator* coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];

	if (!coordinator) {
		ALLogError(@"Failed to initialize the store");
		return nil;
	}

	if (![coordinator addPersistentStoreWithType:NSInMemoryStoreType
								   configuration:nil
											 URL:nil
										 options:nil
										   error:&error]) {
        ALLogError(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
		return nil;
	}

	NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:ct];
	[managedObjectContext setPersistentStoreCoordinator:coordinator];

	return managedObjectContext;
}


@end

@implementation NSAttributeDescription (ALCoreData)

+ (NSDateFormatter*)AL_dateFormatter
{
	static NSDateFormatter*	sharedFormatter = nil;
	if (!sharedFormatter) {
		sharedFormatter = [NSDateFormatter new];
		[sharedFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
	}
	return sharedFormatter;
}

- (id)valueWithXMLAttributeValue:(NSString*)attrValue
{
	switch (self.attributeType) {
		case NSInteger16AttributeType:
		case NSInteger32AttributeType:
			return [NSNumber numberWithInteger:[attrValue integerValue]];
		case NSInteger64AttributeType:
			return [NSNumber numberWithLongLong:[attrValue longLongValue]];
		case NSDecimalAttributeType:
			return [NSDecimalNumber decimalNumberWithString:attrValue];
		case NSDoubleAttributeType:
			return [NSNumber numberWithDouble:[attrValue doubleValue]];
		case NSFloatAttributeType:
			return [NSNumber numberWithFloat:[attrValue floatValue]];
		case NSStringAttributeType:
			return attrValue;
		case NSBooleanAttributeType:
			return [NSNumber numberWithBool:[attrValue boolValue]];
		case NSDateAttributeType:
			return [[NSAttributeDescription AL_dateFormatter] dateFromString:attrValue];
		case NSBinaryDataAttributeType:
			return [[NSData alloc] initWithBase64EncodedString:attrValue options:0];
		case NSTransformableAttributeType:
		{
			NSString* transformerName = self.valueTransformerName;
			if (!transformerName) transformerName = NSKeyedUnarchiveFromDataTransformerName;
			NSValueTransformer*	transformer	= [NSValueTransformer valueTransformerForName:transformerName];
			return [transformer reverseTransformedValue:[[NSData alloc] initWithBase64EncodedString:attrValue options:0]];
		}
		default: break;
	}
	return nil;
}

- (NSString*)xmlAttributeValueWithValue:(id)value
{
	switch (self.attributeType) {
		case NSInteger16AttributeType:
		case NSInteger32AttributeType:
		case NSInteger64AttributeType:
		case NSDecimalAttributeType:
		case NSDoubleAttributeType:
		case NSFloatAttributeType:
			return [((NSNumber*)value) stringValue];
		case NSStringAttributeType:
			return value;
		case NSBooleanAttributeType:
			return [value boolValue] ? kALTrue : kALFalse;
		case NSDateAttributeType:
			return [[NSAttributeDescription AL_dateFormatter] stringFromDate:value];
		case NSBinaryDataAttributeType:
			return [((NSData*)value) base64EncodedStringWithOptions:0];
		case NSTransformableAttributeType:
		{
			NSString* transformerName = self.valueTransformerName;
			if (!transformerName) transformerName = NSKeyedUnarchiveFromDataTransformerName;
			NSValueTransformer*	transformer	= [NSValueTransformer valueTransformerForName:transformerName];
			return [((NSData*)[transformer transformedValue:value]) base64EncodedStringWithOptions:0];
		}
		default: break;
	}
	return nil;
}

@end


@implementation NSManagedObject (ALCoreData)

+ (NSString*)entityNameInContext:(NSManagedObjectContext* )managedObjectContext
{
	NSManagedObjectModel*			mom = managedObjectContext.persistentStoreCoordinator.managedObjectModel;
	if (!mom) return nil;
	NSString* className = NSStringFromClass(self);
	for(NSEntityDescription* entity in mom.entities) {
		if ([className isEqualToString:entity.managedObjectClassName])
			return [entity.name copy];
	}
	return nil;
}

+ (instancetype)objectInContext:(NSManagedObjectContext* )managedObjectContext
{
	NSString* entityName = [self entityNameInContext:managedObjectContext];
	return entityName ? [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:managedObjectContext] : nil;
}

+ (void)deleteAllObjectsFromContext:(NSManagedObjectContext* )managedObjectContext
{
	for(NSManagedObject* object in [self allObjectsInContext:managedObjectContext]) {
		[managedObjectContext deleteObject:object];
	}
}

+ (NSArray*)allObjectsInContext:(NSManagedObjectContext* )managedObjectContext
{
	NSString* entityName = [self entityNameInContext:managedObjectContext];
	return entityName ? [managedObjectContext fetch:entityName withPredicate:nil error:nil] : [NSArray array];
}

+ (instancetype)firstObjectInContext:(NSManagedObjectContext* )managedObjectContext
{
	return [self firstObjectInContext:managedObjectContext error:nil];
}

+ (instancetype)firstObjectInContext:(NSManagedObjectContext* )managedObjectContext error:(NSError**)outError
{
	return [self firstObjectInContext:managedObjectContext withPredicate:nil error:outError];
}

+ (instancetype)firstObjectInContext:(NSManagedObjectContext* )managedObjectContext withPredicate:(NSPredicate*)predicate error:(NSError**)outError
{
	NSString* entityName = [self entityNameInContext:managedObjectContext];
	return entityName ? [managedObjectContext fetchSingle:entityName withPredicate:predicate error:outError] : nil;
}

@end
