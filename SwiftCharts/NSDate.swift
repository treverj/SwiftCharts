//
//  NSDate.swift
//  SwiftCharts
//
//  Created by ischuetz on 05/08/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

var systemCalendar: Calendar {
    return Calendar.current
}

extension Date {
    
    var day: Int {
        return (systemCalendar as NSCalendar).components([.day], from: self).day!
    }

    var month: Int {
        return (systemCalendar as NSCalendar).components([.month], from: self).month!
    }
    
    var year: Int {
        return (systemCalendar as NSCalendar).components([.year], from: self).year!
    }
    
    func components(_ unitFlags: NSCalendar.Unit) -> DateComponents {
        return (systemCalendar as NSCalendar).components(unitFlags, from: self)
    }
    
    func component(_ unit: Calendar.Component) -> Int {
        let components = systemCalendar.dateComponents([unit], from: self)
        return components.value(for: unit)!
    }
    
    func addComponent(_ value: Int, unit: Calendar.Component) -> Date {
        var dateComponents = DateComponents()
        dateComponents.setValue(value, for: unit)
        return (systemCalendar as NSCalendar).date(byAdding: dateComponents, to: self, options: NSCalendar.Options(rawValue: 0))!
    }
    
    static func toDateComponents(_ timeInterval: TimeInterval, unit: Calendar.Component) -> DateComponents {
        let date1 = Date()
        let date2 = Date(timeInterval: timeInterval, since: date1)
        return systemCalendar.dateComponents([unit], from: date1, to: date2)
    }
    
    func timeInterval(_ date: Date, unit: Calendar.Component) -> Int {
        let interval = timeIntervalSince(date)
        let components = Date.toDateComponents(interval, unit: unit)
        return components.value(for: unit)!
    }
}
