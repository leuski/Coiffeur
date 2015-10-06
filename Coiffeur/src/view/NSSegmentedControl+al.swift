//
//  NSSegmentedControl+al.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//

import Cocoa

extension NSSegmentedControl {
	
	var labels : [String] {
		get {
			var value = [String]()
			for var i = 0; i < self.segmentCount; ++i {
				value.append(labelForSegment(i)!)
			}
			return value
		}
		
		set (value) {
			self.segmentCount = value.count
			
			let font       = self.font!
			let fontName = font.familyName!
			let fontSize : NSNumber = font.xHeight
			
			let attributes : [String : AnyObject] = [
				NSFontFamilyAttribute: fontName,
				NSFontSizeAttribute: fontSize
			]
			
			var width = CGFloat(40.0)
			var i     = 0
			
			for token in value {
				let attributedString = NSAttributedString(string:token, attributes:attributes)
				let size = attributedString.size()
				
				if (width < size.width) {
					width = size.width
				}
				
				setLabel(token, forSegment: i++)
			}
			
			for var j = 0; j < self.segmentCount; ++j {
				setWidth(width+12, forSegment: j)
			}
		}
	}
	
}