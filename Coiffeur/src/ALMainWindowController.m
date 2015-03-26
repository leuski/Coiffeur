//
//  ALMainWindowController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALMainWindowController.h"
#import <MGSFragaria/MGSFragaria.h>
#import "Document.h"
#import "ALCoreData.h"
#import "ALOption.h"
#import "ALCoiffeurViewController.h"

@interface ALMainWindowController () <NSWindowDelegate>
@property (weak) IBOutlet NSView *textEditorContainer;
@property (weak) IBOutlet NSView *coiffeurContainer;
@property (nonatomic, strong) MGSFragaria *fragaria;
@property (nonatomic, strong) ALCoiffeurViewController *coiffeur;
@end

@implementation ALMainWindowController

- (void)windowDidLoad {
	
	[super windowDidLoad];

	self.coiffeur = [[ALCoiffeurViewController alloc] initWithModel:[self.document model] bundle:nil];
	[self.coiffeur embedInView:self.coiffeurContainer];
	
	
	self.window.initialFirstResponder = self.coiffeur.optionsView;

	self.fragaria = [[MGSFragaria alloc] init];

	// we want to be the delegate
	[self.fragaria setObject:self forKey:MGSFODelegate];

	// Objective-C is the place to be
	[self.fragaria setObject:@"Objective-C" forKey:MGSFOSyntaxDefinitionName];

	// embed in our container - exception thrown if containerView is nil
	[self.fragaria embedInView:self.textEditorContainer];

	// set initial text
	[self.fragaria setString:@"// We don't need the future."];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(modelDidChange:)
																							 name:NSManagedObjectContextObjectsDidChangeNotification
																						 object:self.managedObjectContext];

	
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
																									name:NSManagedObjectContextObjectsDidChangeNotification
																								object:self.managedObjectContext];
}

- (void)modelDidChange:(NSNotification*)note
{
	[(Document*)self.document uncrustify:self];
}

- (NSManagedObjectContext*)managedObjectContext
{
	return [self.document managedObjectContext];
}


- (NSString*)exampleText
{
	return self.fragaria.string;
}

- (void)setExampleText:(NSString *)exampleText
{
	[self.fragaria setString:exampleText];
}

@end

