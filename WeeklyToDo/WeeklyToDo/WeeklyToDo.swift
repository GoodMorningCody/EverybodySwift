//
//  WeeklyToDo.swift
//  WeeklyToDo
//
//  Created by Cody on 2015. 2. 2..
//  Copyright (c) 2015년 TIEKLE. All rights reserved.
//

import Foundation
import CoreData

class WeeklyToDo: NSManagedObject {

    @NSManaged var done: NSNumber
    @NSManaged var repeat: NSNumber
    @NSManaged var todo: String
    @NSManaged var weekend: WeeklyToDo.Weekend
}
