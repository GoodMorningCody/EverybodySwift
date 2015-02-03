//
//  WeeklyToDoDB.swift
//  WeeklyToDo
//
//  Created by Cody on 2015. 1. 26..
//  Copyright (c) 2015년 TIEKLE. All rights reserved.
//

import CoreData
import UiKit

var todoCoreModelFileName = "Weekly_To_Do_DB"

class WeeklyToDoDB : CoreDataController {
    class var sharedInstance : WeeklyToDoDB {
        struct Static {
            static var onceToken : dispatch_once_t = 0
            static var instance : WeeklyToDoDB? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = WeeklyToDoDB()
        }
        return Static.instance!
    }
    
    override init() {
        super.init()
        
        var storedSymbols : [String] = [String]()
        if let fetchResults = self.managedObjectContext!.executeFetchRequest(NSFetchRequest(entityName: "Weekend"), error: nil) as? [Weekend] {
            for weekend in fetchResults {
                storedSymbols.append(weekend.symbol)
            }
        }
        
        var symbol : String
        for index in 0...6 {
            symbol = Weekly.weekday(index, useStandardFormat: false)
            let filtered = storedSymbols.filter { $0 == symbol }
            if filtered.count==0 {
                let weekend = NSEntityDescription.insertNewObjectForEntityForName("Weekend", inManagedObjectContext: self.managedObjectContext!) as Weekend
                weekend.symbol = symbol
            }
        }
        
        if self.managedObjectContext?.hasChanges==true {
            self.managedObjectContext?.save(nil)
        }
    }
    
    func insertTaskInWeekend(todo:String, when:String, isRepeat:Bool) {
        
        var task = NSEntityDescription.insertNewObjectForEntityForName("Task", inManagedObjectContext: self.managedObjectContext!) as Task
        task.todo = todo
        task.done = NSNumber(bool: false)
        task.repeat = NSNumber(bool: isRepeat)
        
        if let fetchResults = self.managedObjectContext!.executeFetchRequest(NSFetchRequest(entityName: "Weekend"), error: nil) as? [Weekend] {
            for weekend in fetchResults {
                if weekend.symbol==when {
                    var tasks = weekend.mutableSetValueForKey("tasks")
                    task.weekend = weekend
                    tasks.addObject(task)
                    break
                }
            }
        }
        
        if self.managedObjectContext?.hasChanges==true {
            self.managedObjectContext?.save(nil)
        }
    }
    
    func removeTaskInWeekend(weekend:Int, atIndex:Int) {
        var symbolAtIndex = Weekly.weekdayFromNow(weekend, useStandardFormat: true)
        if let fetchResults = self.managedObjectContext!.executeFetchRequest(NSFetchRequest(entityName: "Weekend"), error: nil) as? [Weekend] {
            for weekend in fetchResults {
                if weekend.symbol==symbolAtIndex {
                    if weekend.tasks.count>atIndex {
                        var tasks = weekend.mutableSetValueForKey("tasks")
                        var tasksArray = tasks.allObjects
                        tasksArray.removeAtIndex(atIndex)
                        weekend.tasks = NSSet(array: tasksArray)
                    }
                }
            }
        }
        
        if self.managedObjectContext?.hasChanges==true {
            self.managedObjectContext?.save(nil)
        }
    }
    
    func switchDoneTaskInWeekend(weekend:Int, atIndex:Int) {
        var symbolAtIndex = Weekly.weekdayFromNow(weekend, useStandardFormat: true)
        if let fetchResults = self.managedObjectContext!.executeFetchRequest(NSFetchRequest(entityName: "Weekend"), error: nil) as? [Weekend] {
            for weekend in fetchResults {
                if weekend.symbol==symbolAtIndex {
                    if weekend.tasks.count>atIndex {
                        var task = weekend.tasks.allObjects[atIndex] as Task
                        task.done = !task.done.boolValue
                    }
                }
            }
        }
        
        if self.managedObjectContext?.hasChanges==true {
            self.managedObjectContext?.save(nil)
        }
    }
    
    func taskInWeekend(weekend:Int, atIndex:Int) -> Task? {
        var symbolAtIndex = Weekly.weekdayFromNow(weekend, useStandardFormat: true)
        
        if let fetchResults = self.managedObjectContext!.executeFetchRequest(NSFetchRequest(entityName: "Weekend"), error: nil) as? [Weekend] {
            for weekend in fetchResults {
                if weekend.symbol==symbolAtIndex {
                    if weekend.tasks.count<=atIndex {
                        return nil
                    }
                    else {
                        return weekend.tasks.allObjects[atIndex] as? Task
                    }
                }
            }
        }
        return nil
    }
    
    func taskInWeekend(symbol:String, atIndex:Int) -> Task? {
        if let fetchResults = self.managedObjectContext!.executeFetchRequest(NSFetchRequest(entityName: "Weekend"), error: nil) as? [Weekend] {
            for weekend in fetchResults {
                if weekend.symbol==symbol {
                    if weekend.tasks.count<=atIndex {
                        return nil
                    }
                    else {
                        return weekend.tasks.allObjects[atIndex] as? Task
                    }
                }
            }
        }
        return nil
    }
    
    func countOfTaskInWeekend(index:Int) -> Int {
        var symbolAtIndex = Weekly.weekdayFromNow(index, useStandardFormat: true)
        
        if let fetchResults = self.managedObjectContext!.executeFetchRequest(NSFetchRequest(entityName: "Weekend"), error: nil) as? [Weekend] {
            for weekend in fetchResults {
                if weekend.symbol==symbolAtIndex {
                    return weekend.tasks.count
                }
            }
        }
        return 0
    }
    
    func countOfTaskInWeekend(symbol:String) -> Int {
        if let fetchResults = self.managedObjectContext!.executeFetchRequest(NSFetchRequest(entityName: "Weekend"), error: nil) as? [Weekend] {
            for weekend in fetchResults {
                if weekend.symbol==symbol {
                    return weekend.tasks.count
                }
            }
        }
        return 0
    }
}