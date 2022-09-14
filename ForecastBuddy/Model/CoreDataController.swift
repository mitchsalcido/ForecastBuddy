//
//  CoreDataController.swift
//  VirtualTourist
//
//  Created by Mitchell Salcido on 6/26/22.
//
/*
 About CoreDataController:
 Handle setup and config of Core Data stack. Provide functions for saving, deleting, and background operations. Retrieve network data and store
 */
import Foundation
import CoreData
import UIKit

class CoreDataController {
    
    // container and context
    let container:NSPersistentContainer
    var viewContext:NSManagedObjectContext {
        return container.viewContext
    }
    
    // init with Data model name
    init(name: String) {
        self.container = NSPersistentContainer(name: name)
    }
    
    // load store
    func load() {
        container.loadPersistentStores { description, error in
            guard error == nil else {
                fatalError("Error loading Store: \(error!.localizedDescription)")
            }
            self.configureContext()
        }
    }
    
    // context config
    func configureContext() {
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    // Core Data errors
    enum CoreDataError: LocalizedError {
        case badSave        // bad save
        case badFetch       // bad fetch
        case badData        // bad data
        
        var errorDescription: String? {
            switch self {
            case.badSave:
                return "Bad core data save."
            case .badFetch:
                return "Bad data fetch."
            case .badData:
                return "Bad data received."
            }
        }
        var failureReason: String? {
            switch self {
            case .badSave:
                return "Unable to save data."
            case .badFetch:
                return "Unable to retrieve data."
            case .badData:
                return "Bad data received in call."
            }
        }
        var helpAnchor: String? {
            return "Contact developer for prompt and courteous service."
        }
        var recoverySuggestion: String? {
            return "Close app and re-open."
        }
    }
}

// MARK: Background Op, Saving/Deleting Managed Objects
extension CoreDataController {

    // perform an operation on private queue
    func performBackgroundOp(completion: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            context.automaticallyMergesChangesFromParent = true
            context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            completion(context)
        }
    }
    
    // save context. Return true if good save
    @discardableResult func saveContext(context:NSManagedObjectContext, completion: @escaping (LocalizedError?) -> Void) -> Bool {
        do {
            try context.save()
            DispatchQueue.main.async {
                completion(nil)
            }
            return true
        } catch {
            DispatchQueue.main.async {
                completion(CoreDataError.badSave)
            }
            return false
        }
    }
    
    // delete managed objects
    func deleteManagedObjects(objects:[NSManagedObject], completion: @escaping (LocalizedError?) -> Void) {
        
        /*
         Retrieve object IDs for objects, retrieve objects from private context and delete
         */

        let objectIDs = objects.map {$0.objectID}
        self.performBackgroundOp { context in
            /*
             Retrieve objects into private queue and delete
             */
            for objectID in objectIDs {
                let privateObject = context.object(with: objectID)
                context.delete(privateObject)
            }
            
            // save
            self.saveContext(context: context, completion: completion)
        }
    }
}

extension CoreDataController {
    /*
     Handle retrieval of current weather. Return URLSessionDataTask object for use in canceling network task in the event of bad network or time-out
     */
    func getCurrentForecast(longitude: Double, latitude: Double, completion: @escaping (NSManagedObjectID?, LocalizedError?) -> Void) -> URLSessionDataTask? {
        
        // current weather network call
        return OpenWeatherAPI.getCurrentWeather(longitude: longitude, latitude: latitude) { response, error in
            
            // test current weather returned data response
            guard let icon = response?.weather.first?.icon, let temperature = response?.main.temp else {
                // bad response
                completion(nil, OpenWeatherAPI.OpenWeatherAPIError.badDataError)
                return
            }
            
            /*
             good response. Create a new currentWeather forecast on a background private context
             */
            self.performBackgroundOp { privateContext in
                
                // create new Forecast core data model
                let forecast = Forecast(context: privateContext)
                forecast.latitude = latitude
                forecast.longitude = longitude
                forecast.date = Date()
              
                // create new CurrentCondition core data model
                let currentCondition = CurrentCondition(context: privateContext)
                currentCondition.icon = icon
                currentCondition.temperatureKelvin = temperature
                currentCondition.forecast = forecast
                
                // save
                self.saveContext(context: privateContext) { error in
                    let objectID = forecast.objectID
                    DispatchQueue.main.async {
                        if let _ = error {
                            // bad save
                            completion(nil, CoreDataError.badSave)
                        } else {
                            // good save. Return Forecast objectID for use on main
                            completion(objectID, nil)
                        }
                    }
                }
            }
        }
    }
    
    /*
     Handle retrieval of five-day forecast. Assign five days worth of hourly responses to Forecast data
     */
    func getFiveDayForecast(forecast:Forecast, completion: @escaping (LocalizedError?) -> Void) {
        
        // objectID for use on background private queue
        let objectID = forecast.objectID
        
        // five-day forecast network call
        OpenWeatherAPI.getFiveDayForecast(longitude: forecast.longitude, latitude: forecast.latitude) { response, error in
            
            // test response
            guard let response = response?.list else {
                // bad response
                completion(OpenWeatherAPI.OpenWeatherAPIError.badDataError)
                return
            }
            
            // Using response, create Forecast on background queue
            self.performBackgroundOp { privateContext in
                let privateForecast = privateContext.object(with: objectID) as! Forecast
                
                // HourlyForecast will be sorted by dayOfWeek, Date(time)
                var dayOfWeek:Int16 = 0
                
                // day string to assign to hourlyForecasts
                var lastDay = ""
                
                // iterate through response
                for hourly in response {
                    
                    // test response data
                    if let icon = hourly.weather.first?.icon, let description = hourly.weather.first?.description {
                        
                        // create new hourly forecast. Assign dayOfWeek (for sorting)
                        let hourlyForecast = HourlyForecast(context: privateContext)
                        let date = Date(timeIntervalSince1970: Double(hourly.dt))
                        if lastDay != date.dayString() {
                            dayOfWeek += 1
                            lastDay = date.dayString()
                        }
                        
                        // complete assignment of data to hourlyForecast
                        hourlyForecast.date = date
                        hourlyForecast.dayOfWeek = dayOfWeek
                        hourlyForecast.icon = icon
                        hourlyForecast.temperatureKelvin = hourly.main.temp
                        hourlyForecast.weatherDescription = description
                        hourlyForecast.forecast = privateForecast
                    }
                }
                
                // save when complete
                self.saveContext(context: privateContext) { error in
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            }
        }
    }
}

