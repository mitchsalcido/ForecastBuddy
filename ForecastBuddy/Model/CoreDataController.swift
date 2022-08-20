//
//  CoreDataController.swift
//  VirtualTourist
//
//  Created by Mitchell Salcido on 6/26/22.
//
/*
 About CoreDataController:
 Handle setup and config of Core Data stack. Provide functions for saving, deleting, and background operations.
 */
import Foundation
import CoreData

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
        case badSave
        case badFetch
        case badData
        
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
    
    func createFiveDayForecast(forecast:Forecast, completion: @escaping (LocalizedError?) -> Void) {
        
        let objectID = forecast.objectID
        OpenWeatherAPI.getFiveDayForecast(longitude: forecast.longitude, latitude: forecast.latitude) { response, error in
            
            guard let response = response?.list else {
                completion(OpenWeatherAPI.OpenWeatherAPIError.badData)
                return
            }
            
            self.performBackgroundOp { privateContext in
                let privateForecast = privateContext.object(with: objectID) as! Forecast
                
                var dayOfWeek:Int16 = 0
                var lastDay = ""
                for hourly in response {
                    if let name = hourly.weather.first?.icon, let description = hourly.weather.first?.description {
                        let hourlyForecast = HourlyForecast(context: privateContext)
                        let date = Date(timeIntervalSince1970: Double(hourly.dt))
                        if lastDay != date.dayString() {
                            dayOfWeek += 1
                            lastDay = date.dayString()
                        }
                        hourlyForecast.date = date
                        hourlyForecast.dayOfWeek = dayOfWeek
                        hourlyForecast.name = name
                        hourlyForecast.temperatureKelvin = hourly.main.temp
                        hourlyForecast.weatherDescription = description
                        hourlyForecast.forecast = privateForecast
                    }
                }
                self.saveContext(context: privateContext) { error in
                    completion(error)
                }
            }
        }
    }
}

