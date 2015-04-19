//
//  ConfigNode.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/18/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation
import CoreData

class ConfigNode: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var storedIndex: Int32
    @NSManaged var children: NSOrderedSet
    @NSManaged var parent: ConfigNode?

}
