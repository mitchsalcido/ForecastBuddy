//
//  Date+Ext.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 8/1/22.
//
/*
 About Date+Ext:
 Extent functionality of Date
 */

import Foundation

extension Date {

    func dayString() -> String {
        // day of week..."Monday", "Tuesday"...."Sunday"
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    func timeOfDayString() -> String {
        // time of day ..."2:00PM"
        
        let formatter = DateFormatter()

        // hour of day, AM/PM
        formatter.dateFormat = "HH"
        var hour:String = "00"
        var amPm:String = "AM"
        if var hourInt = Int(formatter.string(from: self)) {
            if hourInt > 12 {
                hourInt -= 12
                amPm = "PM"
            }
            hour = "\(hourInt)"
        }
        
        // minute of hour
        formatter.dateFormat = "mm"
        let minute = formatter.string(from: self)
        
        // combined format
        return "\(hour):\(minute) \(amPm)"
    }
}
