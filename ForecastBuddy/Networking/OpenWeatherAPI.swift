//
//  OpenWeatherAPI.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//
/*
 About OpenWeatherAPI:
 Handle OpenWeather API interface, networking, and Errors
*/

import Foundation
import UIKit

class OpenWeatherAPI {
    
    // User info
    struct UserInfo {
        
        // api key
        static let apiKey = "a9bb26a5929aaba76a9ddc291858d0ea"
        
        // degrees F/C preference key for UserDefaults
        static let degreesUnitsPreferenceKey = "degreesUnitsPreferenceKey"
    }
    
    // network API parameters
    struct APIInfo {
        static let scheme = "https"
        static let host = "api.openweathermap.org"
        static let currentWeatherPath = "/data/2.5/weather"
        static let fiveDayForcastPath = "/data/2.5/forecast"
        static let iconUrlBase = "https://openweathermap.org/img/wn/"
    }
    
    /*
     OpenWeather endpoints
     Handle building and creation of endpoint URL using URLComponents
     */
    enum Endpoints {
        
        // endpoint for retrieving current weather
        case currentWeather(longitude: Double, latitude: Double)
        
        // endpoint for retrieving 5-day forecast
        case fiveDayForecast(longitude: Double, latitude: Double)
        
        // build URL
        var url:URL? {
            
            // build URLComponents
            var components = URLComponents()
            components.scheme = APIInfo.scheme
            components.host = APIInfo.host
            var queryItems:[URLQueryItem] = []
            
            // test geocoded cases for queryItems
            switch self {
            case .currentWeather(longitude: let lon, latitude: let lat), .fiveDayForecast(longitude: let lon, latitude: let lat):
                queryItems.append(URLQueryItem(name: "lat", value: "\(lat)"))
                queryItems.append(URLQueryItem(name: "lon", value: "\(lon)"))
            }
            
            // test cases for path
            switch self {
            case .currentWeather:
                components.path = APIInfo.currentWeatherPath
            case .fiveDayForecast:
                components.path = APIInfo.fiveDayForcastPath
            }
            
            // api key
            queryItems.append(URLQueryItem(name: "appid", value: UserInfo.apiKey))
            
            components.queryItems = queryItems
            return components.url
        }
    }
    
    /*
     OpenWeatherAPIError
     Error handling for OpenWeather networking
     */
    enum OpenWeatherAPIError: LocalizedError {
        case urlError           // bad url creation
        case badDataError       // bad data returned
        case dataDecodeError    // unable to decode retrieved data
        case slowNetwork        // slow/nonresponsive network
        
        var errorDescription: String? {
            switch self {
            case .urlError:
                return "Bad URL"
            case .badDataError:
                return "Bad OpenWeather data download."
            case .dataDecodeError:
                return "Unable to decode retrieved data."
            case .slowNetwork:
                return "Slow or bad network connection."
            }
        }
        var failureReason: String? {
            switch self {
            case .urlError:
                return "Possbile bad text formatting."
            case .badDataError:
                return "Bad data/response from OpenWeather."
            case .dataDecodeError:
                return "Possible bad/corrupted data returned."
            case .slowNetwork:
                return "Excessive download time."
            }
        }
        var helpAnchor: String? {
            return "Contact developer for prompt and courteous service."
        }
        var recoverySuggestion: String? {
            return "Close App and re-open."
        }
    }
}

// MARK: -OpenWeather API functions
extension OpenWeatherAPI {
    
    /*
     handle current weather retrieval
     Retrieve current weather data into a CurrentForecastResponse model. Also return a URLSessionDataTask for use in canceling task in the event of bad network performance or a time-out
     */
    class func getCurrentWeather(longitude: Double, latitude: Double, completion: @escaping (CurrentForecastResponse?, LocalizedError?) -> Void) -> URLSessionDataTask? {
        
        return taskGET(url: Endpoints.currentWeather(longitude: longitude, latitude: latitude).url, responseType: CurrentForecastResponse.self, completion: completion)
    }
    
    
    /*
     handle five-day forecast retrieval
     Retrieve five-day forecast data into a FiveDayForecastResponse model.
     */
    class func getFiveDayForecast(longitude: Double, latitude: Double, completion: @escaping (FiveDayForecastResponse?, LocalizedError?) -> Void) {
        
        taskGET(url: Endpoints.fiveDayForecast(longitude: longitude, latitude: latitude).url, responseType: FiveDayForecastResponse.self, completion: completion)
    }
}

// MARK: -Network functions
extension OpenWeatherAPI {
    
    /*
     Network GET. Retrieve network data formatted to ResponseType.
     Function tests for proper URL, then creates a URL task where the data is decoded into the appropriate ResponseType
     */
    @discardableResult class func taskGET<ResponseType: Decodable>(url: URL?, responseType: ResponseType.Type, completion: @escaping (ResponseType?, LocalizedError?) -> Void) -> URLSessionDataTask? {
        
        // URL test
        guard let url = url else {
            // bad url
            DispatchQueue.main.async {
                completion(nil, OpenWeatherAPIError.urlError)
            }
            return nil
        }
        
        // create task
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            // test data
            guard let data = data else {
                // bad data
                DispatchQueue.main.async {
                    completion(nil, OpenWeatherAPIError.badDataError)
                }
                return
            }
            
            // decode data to ResponseType
            do {
                let json = try JSONDecoder().decode(responseType.self, from: data)
                // good decode
                DispatchQueue.main.async {
                    completion(json, nil)
                }
            } catch {
                // bad decode
                DispatchQueue.main.async {
                    completion(nil, OpenWeatherAPIError.dataDecodeError)
                }
            }
        }
        
        // run/return task
        task.resume()
        return task
    }
}
