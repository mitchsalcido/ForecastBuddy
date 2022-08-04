//
//  WeatherAnnotation.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//

import UIKit
import MapKit
import CoreData

class WeatherAnnotation: MKPointAnnotation {    
    var currentWeather:CurrentForecastResponse!
    
    var pin:Pin!
    
    var icon: String {
        if let icon = currentWeather.weather.first?.icon {
            return icon
        }
        return ""
    }
    
    var temperature: Double {
        return currentWeather.main.temp
    }
}
