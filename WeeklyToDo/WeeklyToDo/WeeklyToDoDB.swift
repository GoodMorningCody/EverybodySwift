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
        
        sync()
    }
    
    func getWeekend( weekend:Int ) -> Weekend? {
        var symbolAtIndex = Weekly.weekdayFromNow(weekend, useStandardFormat: true)
        if let fetchResults = self.managedObjectContext!.executeFetchRequest(NSFetchRequest(entityName: "Weekend"), error: nil) as? [Weekend] {
            for weekend in fetchResults {
                if weekend.symbol==symbolAtIndex {
                    return weekend
                }
            }
        }
        return nil
    }
    
    func insertTaskInWeekend(todo:String, when:String, isRepeat:Bool) {
        
        var task = NSEntityDescription.insertNewObjectForEntityForName("Task", inManagedObjectContext: self.managedObjectContext!) as Task
        task.todo = todo
        task.done = NSNumber(bool: false)
        task.repeat = NSNumber(bool: isRepeat)
        task.creationDate = NSDate()
        
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
        
        sync()
    }
    
    func removeTaskInWeekend(weekend:Int, atIndex:Int) {
        if let fetched = getWeekend(weekend) {
            if fetched.tasks.count>atIndex {
                var tasks = fetched.mutableSetValueForKey("tasks")
                var tasksArray = tasks.allObjects
                tasksArray.removeAtIndex(atIndex)
                fetched.tasks = NSSet(array: tasksArray)
            }
        }
        sync()
    }
    
    func switchDoneTaskInWeekend(weekend:Int, atIndex:Int) {
        if let fetched = getWeekend(weekend) {
            if fetched.tasks.count>atIndex {
                var task = fetched.tasks.allObjects[atIndex] as Task
                task.done = !task.done.boolValue
                
                if task.done==true {
                   task.doneDate = NSDate()
                }
                else {
                   task.doneDate = nil
                }
            }
        }
        
        sync()
    }
    
    func taskInWeekend(weekend:Int, atIndex:Int) -> Task? {
        if let fetched = getWeekend(weekend) {
            if fetched.tasks.count>atIndex {
                return fetched.tasks.allObjects[atIndex] as? Task
            }
        }
        return nil
    }
    
    func countOfDoneTaskInWeekend(weekend:Int) -> Int {
        var countOfDone = 0
        if let fetched = getWeekend(weekend) {
            for task in fetched.tasks.allObjects {
                if task.done.boolValue==true {
                    ++countOfDone
                }
            }
        }
        
        return countOfDone
    }
    
    func countOfTaskInWeekend(weekend:Int) -> Int {
        if let fetched = getWeekend(weekend) {
            return fetched.tasks.count
        }
        
        return 0
    }
    
    func needUpdate() {
        for i in 0...6 {
            if let weekend = getWeekend(i) {
                var tasks = weekend.mutableSetValueForKey("tasks")
                var taskArray = tasks.allObjects
                
                // 1. repeat false이고, creationDate가 오늘보다 작으면 삭제해야합니다
                // 2. repeat가 true이고, done이 true이면서, doneDate가 오늘보다 작으면 done을 false변경 해야 합니다
                for( var i=taskArray.count-1; i>=0; --i ) {
                    var task = taskArray[i] as Task
                    if task.didCreataionWhenPresent()==true {
                        taskArray.removeAtIndex(i)
                    }
                    else if task.didDoneWhenPresent()==true {
                        task.done = NSNumber(bool: false)
                    }
                }
                
                weekend.tasks = NSSet(array: taskArray)

            }
        }
        
        sync()
    }
}