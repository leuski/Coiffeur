//
//  ALCoiffeurView.m
//  Coiffeur
//
//  Created by Anton Leuski on 3/26/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALCoiffeurView.h"
#import "ALCoreData.h"
#import "ALNode+model.h"
#import "ALSubsection.h"
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


@interface ALCoiffeurView () <NSOutlineViewDelegate>
@property (weak) IBOutlet NSPopUpButton *jumpMenu;

@end

@implementation ALCoiffeurView

- (instancetype)initWithModel:(ALCoiffeurModelController*)model bundle:(NSBundle*)bundle;
{
	if (self = [super initWithNibName:@"ALCoiffeurView" bundle:bundle]) {
		self.model = model;
		self.optionsSortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES comparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
			return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
		}] ];
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
	[self AL_fillMenu];
}

- (NSArray*)allNodes
{
	NSMutableArray* array = [NSMutableArray new];
	[self fillNodeArray:array atNode:self.optionsController.arrangedObjects];
	return array;
}

- (void)fillNodeArray:(NSMutableArray*)array atNode:(id)node
{
	for(id n in [node childNodes]) {
		[array addObject:n];
		[self fillNodeArray:array atNode:n];
	}
}

- (void)AL_fillMenu
{
	NSArray*	allNodes = [self allNodes];

	NSMutableArray* sections = [NSMutableArray new];
	for(id n in allNodes) {
		if ([[n representedObject] isKindOfClass:[ALSubsection class]])
			[sections addObject:n];
	}
	
	[sections sortUsingComparator:^NSComparisonResult(id n1, id n2) {
		ALNode* obj1 = [n1 representedObject];
		ALNode* obj2 = [n2 representedObject];
		NSUInteger d1 = obj1.depth;
		NSUInteger d2 = obj2.depth;
		while (d1 > d2) {
			if (obj1.parent == obj2)
				return NSOrderedDescending;
			obj1 = obj1.parent; --d1;
		}
		while (d2 > d1) {
			if (obj2.parent == obj1)
				return NSOrderedAscending;
			obj2 = obj2.parent; --d2;
		}
		while (obj1.parent != obj2.parent) {
			obj1 = obj1.parent; --d1;
			obj2 = obj2.parent; --d2;
		}
		return [obj1.title compare:obj2.title options:NSCaseInsensitiveSearch];
	}];
	
	for(NSInteger i = self.jumpMenu.numberOfItems-1; i >= 1; --i) {
		[self.jumpMenu removeItemAtIndex:i];
	}
	
	for(id node in sections) {
		NSMenuItem* item = [NSMenuItem new];
		ALSubsection* section = [node representedObject];
		item.title = section.title;
		item.indentationLevel = section.depth-1;
		item.representedObject = node;
		[self.jumpMenu.menu addItem:item];
	}
	
	self.jumpMenu.preferredEdge = NSMaxYEdge;
}

- (IBAction)jumpToSection:(id)sender {
	NSPopUpButton* popup = sender;
	[self.optionsView scrollRowToVisible:[self.optionsView rowForItem:popup.selectedItem.representedObject]];
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
	
	NSView* view;
	
	if (tokens.count == 0)
		view = [outlineView makeViewWithIdentifier:@"view.section" owner:self];
	else if (tokens.count == 1 && [tokens[0] isEqualToString:@"number"])
		view = [outlineView makeViewWithIdentifier:@"view.number" owner:self];
	else if (tokens.count == 1)
		view = [outlineView makeViewWithIdentifier:@"view.string" owner:self];
	else {
		view = [outlineView makeViewWithIdentifier:@"view.choice" owner:self];
		NSSegmentedControl* segmented;
		
		for(id v in view.subviews) {
			if ([v isKindOfClass:[NSSegmentedControl class]]) {
				segmented = v;
				break;
			}
		}
		
		[segmented setLabels:tokens];
	}
	

	
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

//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
//{
//	return NO;
//}
@end

@interface ALOutlineView : NSOutlineView
@end

// to enable NSStepper in th eoutline view cells
@implementation ALOutlineView
- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event {
	return YES;
}
@end

@interface ALTableCellView : NSTableCellView

@end

@implementation ALTableCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)style
{
	[super setBackgroundStyle:style];
	
	// If the cell's text color is black, this sets it to white
	[((NSCell *)self.textField.cell) setBackgroundStyle:style];
	
	// Otherwise you need to change the color manually
	switch (style) {
		case NSBackgroundStyleLight:
			[self.textField setTextColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
			break;
			
		case NSBackgroundStyleDark:
		default:
			[self.textField setTextColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
			break;
	}
}

@end

@interface ALTreeController : NSTreeController
//- (NSArray*)allNodes;
@end

@implementation ALTreeController


@end
