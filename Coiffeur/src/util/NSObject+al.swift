//
//  NSObject+al.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/19/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation

extension NSObject {
	
	typealias BlockObserver = (AnyObject, [NSObject : AnyObject]) -> Void
	typealias ObserverToken = NSUUID
	
	class BlockObserverImplementation : NSObject {
		let observer: BlockObserver
		let keyPath: String
		let token: ObserverToken
		let removeWhenChangedOnce: Bool
		weak var target: NSObject?
		
		init(_ observer:BlockObserver, keyPath:String, removeWhenChangedOnce:Bool,
			token:ObserverToken, target:NSObject)
		{
			self.observer = observer
			self.keyPath = keyPath
			self.token = token
			self.target = target
			self.removeWhenChangedOnce = removeWhenChangedOnce
		}

		override func observeValueForKeyPath(keyPath: String,
			ofObject object: AnyObject,
			change: [NSObject : AnyObject],
			context: UnsafeMutablePointer<Void>)
		{
			if context != AssociatedKeys.BlockObserverContext { return }
			self.observer(object, change)
			if !self.removeWhenChangedOnce { return }
			if let t = self.target {
				t.al_observers.removeObjectForKey(self.token)
			}
		}
		
		deinit {
			if let t = self.target {
				t.removeObserver(self, forKeyPath: self.keyPath,
					context: AssociatedKeys.BlockObserverContext)
			}
		}
	}

	private struct AssociatedKeys {
		private static let BlockObserverAOName = UnsafePointer<Void>(bitPattern: 57)
		private static let BlockObserverContext = UnsafeMutablePointer<Void>(bitPattern: 57)
	}
	
	var al_observers: NSMutableDictionary {
		get {
			if let dict = objc_getAssociatedObject(self,
				AssociatedKeys.BlockObserverAOName) as? NSMutableDictionary
			{
				return dict
			}
			let dict = NSMutableDictionary()
			objc_setAssociatedObject(self, AssociatedKeys.BlockObserverAOName,
				dict, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
			return dict
		}
	}
	
	func addObserverForKeyPath(keyPath:String,
		options: NSKeyValueObservingOptions = NSKeyValueObservingOptions(),
		removeWhenChangedOnce: Bool = false,
		observer: (AnyObject, [NSObject : AnyObject]) -> Void) -> ObserverToken
	{
		let token = ObserverToken()
		let observer = BlockObserverImplementation(observer, keyPath:keyPath,
			removeWhenChangedOnce:removeWhenChangedOnce, token:token, target:self)
		self.addObserver(observer, forKeyPath: keyPath, options: options,
			context: AssociatedKeys.BlockObserverContext)
		al_observers.setObject(observer, forKey: token)
		return token
	}

	func addOneShotObserverForKeyPath(keyPath:String,
		options: NSKeyValueObservingOptions = NSKeyValueObservingOptions(),
		observer: (AnyObject, [NSObject : AnyObject]) -> Void) -> ObserverToken
	{
		return addObserverForKeyPath(keyPath, options:options,
			removeWhenChangedOnce:true, observer:observer)
	}

	func removeObserverWithToken(token:ObserverToken)
	{
		if let dict = objc_getAssociatedObject(self,
			AssociatedKeys.BlockObserverAOName) as? NSMutableDictionary
		{
			dict.removeObjectForKey(token)
		}
	}

	func removeAllObservers()
	{
		if let dict = objc_getAssociatedObject(self,
			AssociatedKeys.BlockObserverAOName) as? NSMutableDictionary
		{
			dict.removeAllObjects()
		}
	}

}












