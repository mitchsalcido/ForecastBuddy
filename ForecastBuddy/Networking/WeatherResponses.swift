//
//  WeatherResponses.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//

import Foundation

struct CurrentWeatherResponse: Codable {
    let base:String
    let clouds:CloudsResponse
    let cod:Int
    let coord:CoordResponse
    let dt:Date
    let id:Int
    let main:MainResponse
    let name:String
    let sys:SysResponse
    let timezone:Double
    let visibility:Int
    let weather:[WeatherResponse]
    //let wind:WindResponse
}

struct CloudsResponse: Codable {
    let all:Double
}

struct CoordResponse: Codable {
    let lat:Double
    let lon:Double
}

struct MainResponse: Codable {
    let feels_like:Double
    let humidity:Double
    let pressure:Double
    let temp:Double
    let temp_max:Double
    let temp_min:Double
}

struct SysResponse: Codable {
    let country:String
    let id:Int
    let sunrise:Date
    let sunset:Date
    let type:Int
}

struct WeatherResponse: Codable {
    let description:String
    let icon:String
    let id:Int
    let main:String
}

struct WindResponse: Codable {
    let deg:Double
    let gust:Double
    let speed:Double
}
