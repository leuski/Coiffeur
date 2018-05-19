//
//  NSObject+al.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/19/15.
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

import Foundation

extension NSObject {

  typealias BlockObserver = (AnyObject, [AnyHashable: Any]) -> Void
  typealias ObserverToken = UUID

  class BlockObserverImplementation: NSObject {
    let observer: BlockObserver
    let keyPath: String
    let token: ObserverToken
    let removeWhenChangedOnce: Bool
    weak var target: NSObject?

    init(_ observer:@escaping BlockObserver, keyPath: String, removeWhenChangedOnce: Bool,
         token: ObserverToken, target: NSObject)
    {
      self.observer = observer
      self.keyPath = keyPath
      self.token = token
      self.target = target
      self.removeWhenChangedOnce = removeWhenChangedOnce
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?)
    {
      if context != &AssociatedKeys.Context { return }
      self.observer(object! as AnyObject, change!)
      if !self.removeWhenChangedOnce { return }
      if let target = self.target {
        target._observers.removeObject(forKey: self.token)
      }
    }

    deinit {
      if let target = self.target {
        target.removeObserver(self, forKeyPath: self.keyPath,
                              context: &AssociatedKeys.Context)
      }
    }
  }

  fileprivate struct AssociatedKeys {
    fileprivate static var AOName = 57
    fileprivate static var Context = 57
  }

  private var _observers: NSMutableDictionary {
    get {
      if let dict = objc_getAssociatedObject(self,
                                             &AssociatedKeys.AOName) as? NSMutableDictionary
      {
        return dict
      }
      let dict = NSMutableDictionary()
      objc_setAssociatedObject(self, &AssociatedKeys.AOName,
                               dict, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return dict
    }
  }

  @discardableResult
  func addObserverForKeyPath(_ keyPath: String,
                             options: NSKeyValueObservingOptions = NSKeyValueObservingOptions(),
                             removeWhenChangedOnce: Bool = false,
                             observer: @escaping (AnyObject, [AnyHashable: Any]) -> Void) -> ObserverToken
  {
    let token = ObserverToken()
    let observer = BlockObserverImplementation(observer, keyPath: keyPath,
                                               removeWhenChangedOnce: removeWhenChangedOnce, token: token, target: self)
    self.addObserver(observer, forKeyPath: keyPath, options: options,
                     context: &AssociatedKeys.Context)
    _observers.setObject(observer, forKey: token as NSCopying)
    return token
  }

  @discardableResult
  func addOneShotObserverForKeyPath(_ keyPath: String,
                                    options: NSKeyValueObservingOptions = NSKeyValueObservingOptions(),
                                    observer: @escaping (AnyObject, [AnyHashable: Any]) -> Void) -> ObserverToken
  {
    return addObserverForKeyPath(keyPath, options: options,
                                 removeWhenChangedOnce: true, observer: observer)
  }

  func removeObserverWithToken(_ token: ObserverToken)
  {
    if let dict = objc_getAssociatedObject(self,
                                           &AssociatedKeys.AOName) as? NSMutableDictionary
    {
      dict.removeObject(forKey: token)
    }
  }

  func removeAllObservers()
  {
    if let dict = objc_getAssociatedObject(self,
                                           &AssociatedKeys.AOName) as? NSMutableDictionary
    {
      dict.removeAllObjects()
    }
  }

}
