//
//  WeatherAnnotation.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//

import UIKit
import MapKit

class WeatherAnnotation: MKPointAnnotation {
    var icon:String?
    
    var currentWeather:CurrentWeatherResponse!
}
