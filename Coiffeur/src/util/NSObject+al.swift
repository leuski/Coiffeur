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
		let token:ObserverToken
		weak var target: NSObject?

		init(_ observer:BlockObserver, keyPath:String, token:ObserverToken, target:NSObject) {
			self.observer = observer
			self.keyPath = keyPath
			self.token = token
			self.target = target
		}

		override func observeValueForKeyPath(keyPath: String,
			ofObject object: AnyObject,
			change: [NSObject : AnyObject],
			context: UnsafeMutablePointer<Void>)
		{
			if context == AssociatedKeys.BlockObserverContext {
				self.observer(object, change)
			}
		}
		
		func stopObserving()
		{
			if let t: NSObject = self.target {
				self.target = nil
				t.removeObserver(self, forKeyPath: self.keyPath, context: AssociatedKeys.BlockObserverContext)
				t.al_observers.removeObjectForKey(self.token)
			}
		}
		
		deinit {
			stopObserving()
		}
	}

	class OneShotBlockObserverImplementation : BlockObserverImplementation {
		override func observeValueForKeyPath(keyPath: String,
			ofObject object: AnyObject,
			change: [NSObject : AnyObject],
			context: UnsafeMutablePointer<Void>)
		{
			if context == AssociatedKeys.BlockObserverContext {
				self.observer(object, change)
				if let t: AnyObject = self.target {
					t.removeObserverWithToken(self.token)
				}
			}
		}
	}

	private struct AssociatedKeys {
		private static let BlockObserverAOName = UnsafePointer<Void>(bitPattern: 57)
		private static let BlockObserverContext = UnsafeMutablePointer<Void>(bitPattern: 57)
	}
	
	var al_observers: NSMutableDictionary {
		get {
			if let dict = objc_getAssociatedObject(self, AssociatedKeys.BlockObserverAOName) as? NSMutableDictionary {
				return dict
			}
			let dict = NSMutableDictionary()
			objc_setAssociatedObject(
				self,
				AssociatedKeys.BlockObserverAOName,
				dict,
				UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			)
			return dict
		}
	}
	
	func addObserverForKeyPath(keyPath:String,
		options: NSKeyValueObservingOptions = NSKeyValueObservingOptions(),
		observer: (AnyObject, [NSObject : AnyObject]) -> Void) -> ObserverToken
	{
		let token = ObserverToken()
		let observer = BlockObserverImplementation(observer, keyPath:keyPath, token:token, target:self)
		self.addObserver(observer, forKeyPath: keyPath, options: options, context: AssociatedKeys.BlockObserverContext)
		al_observers.setObject(observer, forKey: token)
		return token
	}

	func addOneShotObserverForKeyPath(keyPath:String,
		options: NSKeyValueObservingOptions = NSKeyValueObservingOptions(),
		observer: (AnyObject, [NSObject : AnyObject]) -> Void) -> ObserverToken
	{
		let token = ObserverToken()
		let observer = OneShotBlockObserverImplementation(observer, keyPath:keyPath, token:token, target:self)
		self.addObserver(observer, forKeyPath: keyPath, options: options, context: AssociatedKeys.BlockObserverContext)
		al_observers.setObject(observer, forKey: token)
		return token
	}

	func removeObserverWithToken(token:ObserverToken)
	{
		al_observers.removeObjectForKey(token)
	}

	func removeAllObservers()
	{
		al_observers.removeAllObjects()
	}

}












