//
//  ForecastTableViewController.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 8/1/22.
//

import UIKit
import CoreLocation

class ForecastTableViewController: UITableViewController {

    var coordinate:CLLocationCoordinate2D!
    var forecast:FiveDayForecastResponse?
    var dailyForcast:[[String:[HourlyResponse]]] = []
    var degreesF:Bool!
    var weatherIcons:[String:UIImage] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Five Day Forecast"
        OpenWeatherAPI.getFiveDayForecast(longitude: coordinate.longitude, latitude: coordinate.latitude) { response, error in
            if let response = response {
                self.dailyForcast = OpenWeatherAPI.createFiveDayForecastArray(weatherForecast: response)
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dailyForcast.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dailyForcast[section].values.first?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dailyForcast[section].keys.first
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ForecastCellID", for: indexPath) as! ForecastTableViewCell

        // Configure the cell...
        let daily = dailyForcast[indexPath.section]
        if let hourly = daily.values.first?[indexPath.row], let weather = hourly.weather.first {
            
            let date = Date(timeIntervalSince1970: Double(hourly.dt))
            cell.timeLabel.text = date.timeOfDayString()
            
            var temperature:Double!
            if degreesF {
                temperature = 1.8 * (hourly.main.temp - 273.0) + 32.0
            } else {
                temperature = hourly.main.temp - 273.15
            }
            cell.temperatureLabel.text = "\(Int(temperature))°"
            
            cell.weatherDescriptionLabel.text = weather.description
            
            if let iconImage = weatherIcons[weather.icon] {
                cell.iconImageView.image = iconImage
            } else {
                OpenWeatherAPI.getWeatherIcon(icon: weather.icon) { image in
                    if let image = image {
                        cell.iconImageView.image = image
                    }
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
