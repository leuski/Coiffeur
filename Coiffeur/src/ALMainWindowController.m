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
#import "ALNode+model.h"

@interface NSSegmentedControl (al)
- (void)setLabels:(NSArray*)labels;
@end

@implementation NSSegmentedControl (al)

- (void)setLabels:(NSArray*)labels
{
	self.segmentCount = labels.count;
	
	NSFont* font = self.font;
	NSDictionary* attributes = @{
		NSFontFamilyAttribute: font.familyName,
		NSFontSizeAttribute: @(font.xHeight)
	};
	
	NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:@"remove" attributes:attributes];
	NSSize size = attributedString.size;
	CGFloat	width = size.width;
	NSInteger i = 0;
	for(NSString* token in labels) {
		attributedString = [[NSAttributedString alloc] initWithString:token attributes:attributes];
		size = attributedString.size;
		if (width < size.width) width = size.width;
		[self setLabel:token forSegment:i++];
	}
	
	for(NSInteger i = 0; i < self.segmentCount; ++i) {
		[self setWidth:width+12 forSegment:i];
	}
}

@end


@interface ALMainWindowController () <NSWindowDelegate>
@property (weak) IBOutlet NSView *textEditorContainer;
@property (nonatomic, strong) MGSFragaria *fragaria;
@end

@implementation ALMainWindowController

- (void)windowDidLoad {
	self.optionsSortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES] ];
	
	[super windowDidLoad];
    
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.optionsView expandItem:nil expandChildren:YES];
	});
	
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

- (ALRoot*)root
{
	return [self.document root];
}

- (NSString*)exampleText
{
	return self.fragaria.string;
}

- (void)setExampleText:(NSString *)exampleText
{
	[self.fragaria setString:exampleText];
}

#pragma mark - NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	ALNode* node = [item representedObject];
	return !node.leaf;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	ALNode* node = [item representedObject];
	NSArray* tokens = node.tokens;

	if (tokens.count == 0)
		return [outlineView makeViewWithIdentifier:@"view.section" owner:self];
	
	if (tokens.count == 1 && [tokens[0] isEqualToString:@"number"])
		return [outlineView makeViewWithIdentifier:@"view.number" owner:self];
		
	if (tokens.count == 1)
		return [outlineView makeViewWithIdentifier:@"view.string" owner:self];

	NSView* view = [outlineView makeViewWithIdentifier:@"view.choice" owner:self];
	NSSegmentedControl* segmented;
	
	for(id v in view.subviews) {
		if ([v isKindOfClass:[NSSegmentedControl class]]) {
			segmented = v;
			break;
		}
	}
	
	[segmented setLabels:tokens];
	return view;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	return [self outlineView:outlineView viewForTableColumn:nil item:item].frame.size.height;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    return NO;
}

@end

@interface ALOutlineView : NSOutlineView

@end

@implementation ALOutlineView

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event {
	return YES;
}


@end
