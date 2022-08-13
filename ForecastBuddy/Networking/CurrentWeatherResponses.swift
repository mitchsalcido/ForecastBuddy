//
//  WeatherResponses.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//

import Foundation

struct CurrentForecastResponse: Codable {
    let main:CurrentMainResponse
    let weather:[CurrentWeatherResponse]
}

struct CurrentMainResponse: Codable {
    let temp:Double
}

struct CurrentWeatherResponse: Codable {
    let icon:String
}

struct HourlyWeather {
    let icon:String
    let date: Date
    let temperature:Double
    let description:String
}
