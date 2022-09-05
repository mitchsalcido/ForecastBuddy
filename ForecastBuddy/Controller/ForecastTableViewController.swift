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
        
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        if section == 0 {
            return "Today"
        }
        
        if let hourly = fetchedResultsController.sections?[section].objects?.first as? HourlyForecast {
            return hourly.date?.dayString()
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
        cell.iconImageView.image = UIImage(named: hourly.icon ?? "")

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ForecastTableViewController {
    
    func configureHourlyForecastFrc() {
        
        let request:NSFetchRequest<HourlyForecast> = NSFetchRequest(entityName: "HourlyForecast")
        let sortDescriptorDay = NSSortDescriptor(key: "dayOfWeek", ascending: true)
        let sortDescriptorDate = NSSortDescriptor(key: "date", ascending: true)
        let predicate = NSPredicate(format: "forecast = %@", forecast)
        request.sortDescriptors = [sortDescriptorDay, sortDescriptorDate]
        request.predicate = predicate
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataController.viewContext, sectionNameKeyPath: "dayOfWeek", cacheName: nil)

        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            // TODO: alert error
        }
    }
}

