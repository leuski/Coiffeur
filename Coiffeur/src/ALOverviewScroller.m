//
//  ALOverviewScroller.m
//  Coiffeur
//
//  Created by Anton Leuski on 4/2/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

#import "ALOverviewScroller.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
static NSString* const AL_OverviewRegionFormat = @"[%@ %@]";
#pragma clang diagnostic pop

@implementation ALOverviewRegion

+ (instancetype)overviewRegionWithLineRange:(NSRange)range color:(NSColor*)color
{
  ALOverviewRegion* region = [ALOverviewRegion new];

  region.lineRange = range;
  region.color     = color;
  return region;
}

- (NSString*)description
{
  return [NSString stringWithFormat:AL_OverviewRegionFormat, NSStringFromRange(self.lineRange),
          self.color];
}

@end

@implementation ALOverviewScroller

- (void)drawRect:(NSRect)dirtyRect
{
  [super drawRect:dirtyRect];

  // Drawing code here.
}

- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag
{
  [super drawKnobSlotInRect:slotRect highlight:flag];

  if (self.regions.count == 0) {
    return;
  }

  ALOverviewRegion* lastRegion = self.regions.lastObject;
  NSUInteger lineCount = lastRegion.lineRange.location;

  if (lineCount == 0) {
    return;
  }

  CGFloat height = self.frame.size.height;
  CGFloat width  = self.frame.size.width;
  CGFloat scale  = height / lineCount;

  for (ALOverviewRegion* region in self.regions) {
    if (!region.color) {
      continue;
    }

    NSRect regionRect = NSMakeRect(0, scale * region.lineRange.location,
      width, MAX(scale * region.lineRange.length, 2));

    if (NSIntersectsRect(slotRect, regionRect)) {
      [region.color setFill];
      NSRectFill(regionRect);
    }
  }
}

- (void)setRegions:(NSArray*)regions
{
  self->_regions = regions;
  [self setNeedsDisplay:YES];
}

- (void)setKnobProportion:(CGFloat)proportion
{
  [super setKnobProportion:proportion];
  [self setNeedsDisplay:YES];
}

@end

