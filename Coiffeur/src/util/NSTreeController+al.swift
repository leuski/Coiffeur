//
//  NSTreeController+al.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/25/15.
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

extension NSTreeController {
	
	struct DepthFirstView : Sequence {

		struct NodeGenerator: IteratorProtocol {
			
			var stack = [IndexingIterator<[NSTreeNode]>]()
			
			init(_ root: NSTreeNode)
			{
				if let array = root.children {
					stack.append(array.makeIterator())
				}
			}
			
			mutating func next() -> NSTreeNode?
			{
				while !stack.isEmpty {
					var last = stack.last!
					if let node = last.next() {
						stack[stack.count-1] = last
						if let array = node.children {
							stack.append(array.makeIterator())
						}
						return node
					} else {
						stack.removeLast()
					}
				}
				return nil
			}
			
		}

		typealias Iterator = NodeGenerator
		
		let owner: NSTreeController
		
		init(_ owner:NSTreeController)
		{
			self.owner = owner
		}
		
		func makeIterator() -> Iterator
		{
			return NodeGenerator(self.owner.arrangedObjects )
		}
		
		func filter(_ includeElement: (NSTreeNode) -> Bool) -> [NSTreeNode]
		{
			return self.filter(includeElement)
		}
		
	}
	
	var nodes: DepthFirstView {
		return DepthFirstView(self)
	}
	
	var firstLeaf: NSTreeNode? {
		for node in self.nodes {
			if node.isLeaf {
				return node
			}
		}
		return nil
	}
	
}
