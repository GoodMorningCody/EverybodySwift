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
        task.creation = NSDate()
        
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
    
    func countOfTaskInWeekend(weekend:Int) -> Int {
        if let fetched = getWeekend(weekend) {
            return fetched.tasks.count
        }
        
        return 0
    }
    
    func needUpdate() {
        // Core Data 갱신해야됨
        // 1. 시간 계산 후 어제 Task 가져오기
        if let fetched = getWeekend(-1) {
            var tasks = fetched.mutableSetValueForKey("tasks")
            var tasksArray = tasks.allObjects
            
            for( var i=tasksArray.count-1; i>=0; --i ) {
                var task = tasksArray[i] as Task
                
                // 2-1. repeat true면서 done으로 되어 있는 녀석 풀기
                if task.repeat.boolValue {
                    task.done = NSNumber(bool: false)
                }
                //2-2. repeat false면 녀석 지우기
                else {
                    tasksArray.removeAtIndex(i)
                }
            }
            
            fetched.tasks = NSSet(array: tasksArray)
        }
        sync()
    }
}