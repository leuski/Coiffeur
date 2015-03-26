//
//  ALCoiffeurViewController.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALCoiffeurViewController.h"
#import "ALNode+model.h"
#import "ALCoiffeurModelController.h"

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


@interface ALCoiffeurViewController () <NSOutlineViewDelegate>

@end

@implementation ALCoiffeurViewController

- (instancetype)initWithModel:(ALCoiffeurModelController*)model bundle:(NSBundle*)bundle;
{
	if (self = [super initWithNibName:@"ALCoiffeurViewController" bundle:bundle]) {
		self.model = model;
		self.optionsSortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES] ];
	}
	return self;
}

- (void)embedInView:(NSView*)container
{
	NSView* childView = self.view;
	[container addSubview:childView];
	
	childView.translatesAutoresizingMaskIntoConstraints = NO;
	[container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[childView]|"
																																		 options:0
																																		 metrics:nil
																																			 views:NSDictionaryOfVariableBindings(childView)]];
	[container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[childView]|"
																																		 options:0
																																		 metrics:nil
																																			 views:NSDictionaryOfVariableBindings(childView)]];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self.optionsController addObserver:self
													 forKeyPath:@"content"
															options:NSKeyValueObservingOptionNew
															context:(__bridge void*)self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
												change:(NSDictionary *)change context:(void *)context
{
	if (context != (__bridge void*)self)
		return;
	
	[self.optionsController removeObserver:self forKeyPath:@"content"];
	[self.optionsView expandItem:nil expandChildren:YES];
	
	id node;
	for(node = [self.optionsController arrangedObjects];
			[[node childNodes] count];
			node = [[node childNodes] objectAtIndex:0]);
	[self.optionsController setSelectionIndexPath:[node indexPath]];
}

- (NSManagedObjectContext*)managedObjectContext
{
	return [self.model managedObjectContext];
}

- (ALRoot*)root
{
	return [self.model root];
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
	
	if ([node isKindOfClass:[ALRoot class]])
		return [outlineView makeViewWithIdentifier:@"view.root" owner:self];
	
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

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return ![self outlineView:outlineView isGroupItem:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
	return NO;
}
@end

@interface ALOutlineView : NSOutlineView

@end

// to enable NSStepper in th eoutline view cells
@implementation ALOutlineView
- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event {
	return YES;
}
@end
