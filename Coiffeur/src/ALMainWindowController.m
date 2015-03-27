//
//  ALMainWindowController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALMainWindowController.h"
#import <MGSFragaria/MGSFragaria.h>
#import "ALCoiffeurViewController.h"
#import "Document.h"

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
	[self.fragaria setString:@"// some code here. File > Open Code... (hold down alt)."];
	
	NSString* lastCodeURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"ALCodeURL"];
	if (lastCodeURL) {
		[[self document] readCodeFromURL:[NSURL URLWithString:lastCodeURL] error:nil];
	}
	
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

