//
//  FiveDayForecastResponse.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 8/1/22.
//

import Foundation

struct FiveDayForecastResponse: Codable {
    let list:[HourlyResponse]
}

struct HourlyResponse: Codable {
    let dt:Int
    let main:HourlyMainResponse
    let weather:[HourlyWeatherResponse]
}

struct HourlyMainResponse: Codable {
    let temp:Double
}

struct HourlyWeatherResponse: Codable {
    let description:String
    let icon:String
}

