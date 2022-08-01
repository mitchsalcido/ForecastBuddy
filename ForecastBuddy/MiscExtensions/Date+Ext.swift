//
//  Date+Ext.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 8/1/22.
//

import Foundation

extension Date {
    
    func toLocalTime() -> Date {
        let timezoneOffset = TimeZone.current.secondsFromGMT()
        let epochDate = self.timeIntervalSince1970
        let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
        return Date(timeIntervalSince1970: timezoneEpochOffset)
    }
    
    func dayTimeString() -> String {
        
        // day of week..."Monday", "Tuesday"...."Sunday"
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let day = formatter.string(from: self)
        
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
        return day + " \(hour):\(minute) \(amPm)"
    }
}
