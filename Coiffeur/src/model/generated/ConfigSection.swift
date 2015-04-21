//
//  ConfigSection.swift
//  Coiffeur
//
//  Created by Anton Leuski on 4/5/15.
//  Copyright (c) 2015 Anton Leuski. All rights reserved.
//

import Foundation
import CoreData

class ConfigSection: ConfigNode {
	@NSManaged var storedFilteredChildren: AnyObject?
	@NSManaged var expanded: Bool
}
