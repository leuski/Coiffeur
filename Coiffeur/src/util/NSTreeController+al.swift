//
//  NSTreeController+al.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/25/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Cocoa

extension NSTreeController {
	
	struct DepthFirstView : SequenceType {

		struct NodeGenerator: GeneratorType {
			
			var stack = [IndexingGenerator<[AnyObject]>]()
			
			init(_ root:AnyObject)
			{
				if let array = root.childNodes as [AnyObject]? {
					stack.append(array.generate())
				}
			}
			
			mutating func next() -> AnyObject?
			{
				while !stack.isEmpty {
					var last = stack.last!
					if let x: AnyObject = last.next() {
						stack[stack.count-1] = last
						if let array = x.childNodes as [AnyObject]? {
							stack.append(array.generate())
						}
						return x
					} else {
						stack.removeLast()
					}
				}
				return nil
			}
			
		}

		typealias Generator = NodeGenerator
		
		let owner: NSTreeController
		
		init(_ owner:NSTreeController)
		{
			self.owner = owner
		}
		
		func generate() -> Generator
		{
			return NodeGenerator(self.owner.arrangedObjects)
		}
		
		func filter(includeElement: (AnyObject) -> Bool) -> [AnyObject]
		{
			return Swift.filter(self, includeElement)
		}
		
	}
	
	var nodes: DepthFirstView {
		return DepthFirstView(self)
	}
	
	var firstLeaf: AnyObject? {
		for node in self.nodes {
			if isLeaf(node) {
				return node
			}
		}
		return nil
	}
	
	func isLeaf(node:AnyObject) -> Bool
	{
		if let treeNode = node as? NSTreeNode,
			 let keyPath = self.leafKeyPathForNode(treeNode),
			 let flag = node.valueForKeyPath(keyPath) as? NSNumber
		{
			return flag.boolValue
		}

		if let keyPath = self.leafKeyPath,
			 let flag = node.valueForKeyPath(keyPath) as? NSNumber
		{
			return flag.boolValue
		}
			
		return node.childNodes??.count == nil || node.childNodes!!.count == 0
	}
}