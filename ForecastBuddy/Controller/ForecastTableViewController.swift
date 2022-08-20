//
//  ForecastTableViewController.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 8/1/22.
//

import UIKit
import CoreData

class ForecastTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var forecast:Forecast!
    var degreesF:Bool!
    var dailyForecastArray:[[String:[HourlyWeather]]] = []
    var dataController:CoreDataController!
    var fetchedResultsController:NSFetchedResultsController<HourlyForecast>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Five Day Forecast"
        configureHourlyForecastFrc()
    }
}

// MARK: - Table view data source
extension ForecastTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        //return dailyForecastArray.count
        
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return dailyForecastArray[section].values.first?.count ?? 0
        
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //return dailyForecastArray[section].keys.first

        if let hourly = fetchedResultsController.sections?[section].objects?.first as? HourlyForecast {
            return hourly.date?.dayString()
        } else {
            print("nil header title")
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ForecastCellID", for: indexPath) as! ForecastTableViewCell

        let hourly = fetchedResultsController.object(at: indexPath)
        cell.timeLabel.text = hourly.date?.timeOfDayString()
        
        var temperature:Double!
        if degreesF {
            temperature = 1.8 * (hourly.temperatureKelvin - 273.0) + 32.0
        } else {
            temperature = hourly.temperatureKelvin - 273.15
        }
        
        cell.temperatureLabel.text = "\(Int(temperature))°"
        cell.weatherDescriptionLabel.text = hourly.weatherDescription
        cell.iconImageView.image = UIImage(named: hourly.name ?? "")
        /*
        // Configure the cell...
        let daily = dailyForecastArray[indexPath.section]
        if let hourly = daily.values.first?[indexPath.row] {
            
            cell.timeLabel.text = hourly.date.timeOfDayString()
            
            var temperature:Double!
            if degreesF {
                temperature = 1.8 * (hourly.temperature - 273.0) + 32.0
            } else {
                temperature = hourly.temperature - 273.15
            }
            
            cell.temperatureLabel.text = "\(Int(temperature))°"
            cell.weatherDescriptionLabel.text = hourly.description
            cell.iconImageView.image = UIImage(named: hourly.icon)
        }
         */
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ForecastTableViewController {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("didChangeContent")
    }
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("willChangeContent")
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("didChangeAtForNew")
    }
}
extension ForecastTableViewController {
    
    func configureHourlyForecastFrc() {
        
        let request:NSFetchRequest<HourlyForecast> = NSFetchRequest(entityName: "HourlyForecast")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        let predicate = NSPredicate(format: "forecast = %@", forecast)
        request.sortDescriptors = [sortDescriptor]
        request.predicate = predicate
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataController.viewContext, sectionNameKeyPath: "dayOfWeek", cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            //dailyForecastArray = configureDailyForecastArray()
            tableView.reloadData()
        } catch {
            // TODO: alert error
        }
    }
    
    func configureDailyForecastArray() -> [[String:[HourlyWeather]]] {
        
        var result:[[String:[HourlyWeather]]] = [] // [[Day:[HourlyWeather]]]
        
        guard let hourlyForecasts = fetchedResultsController.fetchedObjects, !hourlyForecasts.isEmpty else {
            return result
        }
        
        var days:[String] = []
        for hourlyForecast in hourlyForecasts {
            if let dayOfWeek = hourlyForecast.date?.dayString() {
                if !days.contains(dayOfWeek) {
                    days.append(dayOfWeek)
                }
            }
        }
        
        var hourlyResponses:[[HourlyWeather]] = []
        for day in days {
            var hourly:[HourlyWeather] = []
            for hourlyForecast in hourlyForecasts {
                
                if let date = hourlyForecast.date, let icon = hourlyForecast.name, let description = hourlyForecast.weatherDescription {
                    
                    let hourlyWeather = HourlyWeather(icon: icon, date: date, temperature: hourlyForecast.temperatureKelvin, description: description)
                    
                    if day == date.dayString() {
                        hourly.append(hourlyWeather)
                    }
                }
            }
            hourlyResponses.append(hourly)
        }
        
        days.remove(at: 0)
        days.insert("Today", at: 0)
        
        for (index, day) in days.enumerated() {
            result.append([day:hourlyResponses[index]])
        }
        
        return result
    }
}

