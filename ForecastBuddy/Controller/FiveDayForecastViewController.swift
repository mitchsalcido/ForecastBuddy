//
//  FiveDayForecastViewController.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 9/6/22.
//
/*
 About FiveDayForecastViewController:
 Presents a tableView that show hourly (3 hours increments) weather over a five day forecast.
 
 Persisted Hourly forcast are retrieved/managed with an NSFetchedResultsController, sorted by day and time of day.
 */

import UIKit
import CoreData

class FiveDayForecastViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // ref to tableView to present 5-day forecast
    @IBOutlet weak var tableView: UITableView!
    
    // shows network activity when downloading forecast
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // Forecast model set in MapViewController
    var forecast:Forecast!
    
    // degrees user preference set in MapViewController
    var degreesF:Bool!
    
    // CoreDataController set in MapViewController
    var dataController:CoreDataController!
    
    // FRC. Managed HourlyForecast model objects
    var fetchedResultsController:NSFetchedResultsController<HourlyForecast>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // fetch HourlyForecast managed objects
        configureHourlyForecastFrc()

        // test for valid 5-day forecast. Retrieve if no 5-day exists
        if let hourly = forecast.hourlyForecast?.count, hourly == 0 {
            dataController.getFiveDayForecast(forecast: forecast) { error in
                if let error = error {
                    self.showAlert(error)
                } else {
                    self.configureHourlyForecastFrc()
                }
            }
        }
    }
}

// MARK: - Table view data source
extension FiveDayForecastViewController {
    
    // section count
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    // row count
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    // header titles for HourlyForecast
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        // First section title is current day
        if section == 0 {
            return "Today"
        }
        
        // subsequent section titles are day of week
        if let hourly = fetchedResultsController.sections?[section].objects?.first as? HourlyForecast {
            return hourly.date?.dayString()
        }
        
        return nil
    }
    
    // cell for HourlyForecast
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // dequeue a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "ForecastCellID", for: indexPath) as! ForecastTableViewCell

        // retrieve an hourly forecast
        let hourly = fetchedResultsController.object(at: indexPath)
        
        // set time label
        cell.timeLabel.text = hourly.date?.timeOfDayString()
        
        // compute degrees based on user preference,°C or °F
        var temperature:Double!
        if degreesF {
            temperature = 1.8 * (hourly.temperatureKelvin - 273.0) + 32.0
        } else {
            temperature = hourly.temperatureKelvin - 273.15
        }
        
        // temperature label
        cell.temperatureLabel.text = "\(Int(temperature))°"
        
        // weather description label
        cell.weatherDescriptionLabel.text = hourly.weatherDescription
        
        // weather image icon
        cell.iconImageView.image = UIImage(named: hourly.icon ?? "DefaultWeather")

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: -Helpers
extension FiveDayForecastViewController {
    
    // fetch HourlyForecasts
    func configureHourlyForecastFrc() {
        /*
         Configure NSFetchedResultsController and perform fetch of HourlyForecast managed objects, sorted by day of week and date.
         */
        
        // request
        let request:NSFetchRequest<HourlyForecast> = NSFetchRequest(entityName: "HourlyForecast")
        
        // sort by day of week, then date
        let sortDescriptorDay = NSSortDescriptor(key: "dayOfWeek", ascending: true)
        let sortDescriptorDate = NSSortDescriptor(key: "date", ascending: true)
        
        // predicate to retrieve HourlyForcasts assigned to forecast attribute
        let predicate = NSPredicate(format: "forecast = %@", forecast)
        request.sortDescriptors = [sortDescriptorDay, sortDescriptorDate]
        request.predicate = predicate
        
        // config FRC
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataController.viewContext, sectionNameKeyPath: "dayOfWeek", cacheName: nil)

        do {
            // perform fetch and reload table
            try fetchedResultsController.performFetch()
            tableView.reloadData()
            
            // stop activityIndicator
            if let isEmpty = fetchedResultsController.fetchedObjects?.isEmpty, isEmpty == false {
                activityIndicator.stopAnimating()
            }
        } catch {
            // bad fetch
            showAlert(CoreDataController.CoreDataError.badFetch)
        }
    }
}

