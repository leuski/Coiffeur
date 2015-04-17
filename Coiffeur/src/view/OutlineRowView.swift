//
//  OutlineRowView.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/16/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

class OutlineRowView : NSTableRowView {
	
	var colors = [NSColor]()
	
	override func drawBackgroundInRect(dirtyRect: NSRect)
	{
		super.drawBackgroundInRect(dirtyRect)
		for var i = 0; i < colors.count; ++i {
			colors[i].setFill()
			NSRectFill(NSMakeRect(CGFloat(3 + i*5), CGFloat(0), CGFloat(3-2*i), self.frame.size.height))
		}
	}
	
	override func drawSelectionInRect(dirtyRect: NSRect)
	{
		NSColor.selectedMenuItemColor().setFill()
		NSRectFill(NSMakeRect(CGFloat(10), CGFloat(0), self.frame.size.width-10, self.frame.size.height))
	}
}
