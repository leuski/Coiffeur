//
//  Document.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "Document.h"

#import "ALCoreData.h"
#import "ALRoot.h"
#import "ALMainWindowController.h"
#import "ALClangFormatController.h"
#import "ALUncrustifyController.h"
#import "ALCoiffeurView.h"


@interface Document ()
@property (nonatomic, strong) ALCoiffeurView*	coiffeur;
@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
//			self.model = [self makeUncrustifyController];
			self.model = [self makeClangFormatController];
    }
    return self;
}

- (void)makeWindowControllers
{
	[[ALMainWindowController sharedInstance] addDocument:self];
}

- (Class)modelClass
{
	return self.model.class;
}

- (void)setModelClass:(Class)clazz
{
	if (self.model && clazz == self.modelClass)
		return;
	
	NSManagedObject* tmp = self.model.root;
	self.model.root = nil;
	[self.managedObjectContext deleteObject:tmp];

	if (clazz == [ALUncrustifyController class]) {
		self.model = [self makeUncrustifyController];
	} else {
		self.model = [self makeClangFormatController];
	}
}

- (ALUncrustifyController*)makeUncrustifyController
{
	return [[ALUncrustifyController alloc] initWithUncrustifyURL:[[NSBundle mainBundle] URLForAuxiliaryExecutable:@"uncrustify"]
																													 moc:self.managedObjectContext
																												 error:nil];
}

- (ALClangFormatController*)makeClangFormatController
{
	return [[ALClangFormatController alloc] initWithExecutableURL:[[NSBundle mainBundle] URLForAuxiliaryExecutable:@"clang-format"]
																														moc:self.managedObjectContext
																													error:nil];
}

- (BOOL)readValuesFromURL:(NSURL *)absoluteURL error:(NSError *__autoreleasing *)error
{
	NSString* data = [NSString stringWithContentsOfURL:absoluteURL encoding:NSUTF8StringEncoding error:error];
	if (!data) return NO;
	
	BOOL newClang = [data hasPrefix:@"---"] || [data rangeOfString:@"\n---"].location != NSNotFound;
	[self setModelClass:newClang ? [ALClangFormatController class] : [ALUncrustifyController class]];
	
	return [self.model readValuesFromString:data];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError**)error
{
	[self.managedObjectContext disableUndoRegistration];
	BOOL result	= [self readValuesFromURL:absoluteURL error:error];
	[self.managedObjectContext enableUndoRegistration];

	return result;
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)error
{
	return [self.model writeValuesToURL:absoluteURL error:error];
}

- (void)embedInView:(NSView*)container
{
	self.coiffeur = [[ALCoiffeurView alloc] initWithModel:self.model bundle:nil];
	[self.coiffeur embedInView:container];
	container.window.initialFirstResponder = self.coiffeur.optionsView;
}


@end
