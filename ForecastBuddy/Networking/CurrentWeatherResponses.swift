//
//  WeatherResponses.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//
/*
 About WeatherResponses:
 Model obejct responseTypes for current weather data
 */
import Foundation

// top level
struct CurrentForecastResponse: Codable {
    let main:CurrentMainResponse
    let weather:[CurrentWeatherResponse]
}

// temperature model
struct CurrentMainResponse: Codable {
    let temp:Double
}

// icon (string representing image of weather..clouds, sun, etc)
struct CurrentWeatherResponse: Codable {
    let icon:String
}
