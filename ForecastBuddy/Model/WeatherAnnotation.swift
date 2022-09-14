//
//  WeatherAnnotation.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//
/*
 About WeatherAnnotation:
 Subclass of MKPointAnnotation. Included Forecast core data model. Also, reference to task for use in deleting annotation in the even of network issues
 */

import UIKit
import MapKit
import CoreData

class WeatherAnnotation: MKPointAnnotation {
    var forecast:Forecast? = nil
    var task:URLSessionDataTask? = nil
}
