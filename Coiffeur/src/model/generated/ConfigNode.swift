//
//  ConfigNode.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation
import CoreData

class ConfigNode: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var children: NSSet
    @NSManaged var parent: ConfigNode?

}
