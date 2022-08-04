//
//  OpenWeatherAPI.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//

import Foundation
import UIKit

class OpenWeatherAPI {
    
    struct UserInfo {
        static let apiKey = "a9bb26a5929aaba76a9ddc291858d0ea"
        static let degreesUnitsPreferenceKey = "degreesUnitsPreferenceKey"
    }
    
    struct APIInfo {
        static let scheme = "https"
        static let host = "api.openweathermap.org"
        static let currentWeatherPath = "/data/2.5/weather"
        static let fiveDayForcastPath = "/data/2.5/forecast"
        static let iconUrlBase = "https://openweathermap.org/img/wn/"
    }
    
    enum Endpoints {
        case currentWeather(longitude: Double, latitude: Double)
        case fiveDayForecast(longitude: Double, latitude: Double)
        
        var url:URL? {
            var components = URLComponents()
            components.scheme = APIInfo.scheme
            components.host = APIInfo.host
            var queryItems:[URLQueryItem] = []
            
            switch self {
            case .currentWeather(longitude: let lon, latitude: let lat):
                queryItems.append(URLQueryItem(name: "lat", value: "\(lat)"))
                queryItems.append(URLQueryItem(name: "lon", value: "\(lon)"))
                components.path = APIInfo.currentWeatherPath
            case .fiveDayForecast(longitude: let lon, latitude: let lat):
                queryItems.append(URLQueryItem(name: "lat", value: "\(lat)"))
                queryItems.append(URLQueryItem(name: "lon", value: "\(lon)"))
                components.path = APIInfo.fiveDayForcastPath
            }
            
            queryItems.append(URLQueryItem(name: "appid", value: UserInfo.apiKey))
            components.queryItems = queryItems
            return components.url
        }
    }
    
    enum OpenWeatherAPIError: LocalizedError {
        case url
        case badData
    }
}

extension OpenWeatherAPI {
    
    class func getFiveDayForecast(longitude: Double, latitude: Double, completion: @escaping (FiveDayForecastResponse?, LocalizedError?) -> Void) {
        
        taskGET(url: Endpoints.fiveDayForecast(longitude: longitude, latitude: latitude).url, responseType: FiveDayForecastResponse.self, completion: completion)
    }
    
    class func getCurrentWeather(longitude: Double, latitude: Double, completion: @escaping (CurrentForecastResponse?, LocalizedError?) -> Void) {
        
        taskGET(url: Endpoints.currentWeather(longitude: longitude, latitude: latitude).url, responseType: CurrentForecastResponse.self, completion: completion)
    }
    
    class func getWeatherIconData(icon:String, completion: @escaping (Data?) -> Void) {
        
        let urlString = APIInfo.iconUrlBase + icon + ".png"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
                
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(data)
            }
        }
        task.resume()
    }
}

extension OpenWeatherAPI {
    
    class func taskGET<ResponseType: Decodable>(url: URL?, responseType: ResponseType.Type, completion: @escaping (ResponseType?, LocalizedError?) -> Void) {
        
        guard let url = url else {
            print("bad url")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, OpenWeatherAPIError.badData)
                }
                return
            }
            
            do {
                let json = try JSONDecoder().decode(responseType.self, from: data)
                DispatchQueue.main.async {
                    completion(json, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, OpenWeatherAPIError.badData)
                }
            }
        }
        task.resume()
    }
}

extension OpenWeatherAPI {
    
    class func createFiveDayForecastArray(weatherForecast:FiveDayForecastResponse) -> [[String:[HourlyResponse]]] {
        
        var results:[[String:[HourlyResponse]]] = []
        
        var days:[String] = []
        for forecast in weatherForecast.list {
            let dayOfWeek = Date(timeIntervalSince1970: Double(forecast.dt)).dayString()
            if !days.contains(dayOfWeek) {
                days.append(dayOfWeek)
            }
        }
        
        var hourlyResponses:[[HourlyResponse]] = []
        for day in days {
            var hourly:[HourlyResponse] = []
            for forecast in weatherForecast.list {
                let dayOfForecast = Date(timeIntervalSince1970: Double(forecast.dt)).dayString()
                if day == dayOfForecast {
                    hourly.append(forecast)
                }
            }
            hourlyResponses.append(hourly)
        }
        
        days.remove(at: 0)
        days.insert("Today", at: 0)
        
        for (index, day) in days.enumerated() {
            results.append([day:hourlyResponses[index]])
        }
        
        return results
    }
}
