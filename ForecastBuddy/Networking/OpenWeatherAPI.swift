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
}

extension OpenWeatherAPI {
    
    class func getCurrentWeather(longitude: Double, latitude: Double, completion: @escaping (CurrentWeatherResponse?, Error?) -> Void) {
        
        taskGET(url: Endpoints.currentWeather(longitude: longitude, latitude: latitude).url, completion: completion)
    }
    
    class func getWeatherIcon(icon:String, completion: @escaping (UIImage?) -> Void) {
        
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
                completion(UIImage(data: data))
            }
        }
        task.resume()
    }
}

extension OpenWeatherAPI {
    
    class func taskGET(url: URL?, completion: @escaping (CurrentWeatherResponse?, Error?) -> Void) {
        
        guard let url = url else {
            print("bad url")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            do {
                let json = try JSONDecoder().decode(CurrentWeatherResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(json, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
}
