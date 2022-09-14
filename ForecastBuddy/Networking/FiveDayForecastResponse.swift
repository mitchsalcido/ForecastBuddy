//
//  FiveDayForecastResponse.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 8/1/22.
//
/*
 About FiveDayForecastResponse:
 Model obejct responseTypes for five-day forecast data
 */
import Foundation

// top level
struct FiveDayForecastResponse: Codable {
    let list:[HourlyResponse]
}

// hourly model
struct HourlyResponse: Codable {
    let dt:Int
    let main:HourlyMainResponse
    let weather:[HourlyWeatherResponse]
}

// temperature model
struct HourlyMainResponse: Codable {
    let temp:Double
}

// desc and weather icon
struct HourlyWeatherResponse: Codable {
    let description:String
    let icon:String
}

