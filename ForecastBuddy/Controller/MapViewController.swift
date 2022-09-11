//
//  MapViewController.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//

import UIKit
import MapKit
import CoreData

// 37.77° N lat, -122.41° W lon San Fran
// 39.73° N lat, -121.84° W lon Chico
class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var degreesUnitsToggleBbi: UIBarButtonItem!
    
    var dataController:CoreDataController!
        
    var degreesF:Bool!
        
    let WEATHER_UPDATE_INTERVAL:TimeInterval = 30.0//10800.0
    let NETWORK_TIMEOUT:TimeInterval = 10.0
    
    var newAnnotations:[WeatherAnnotation]? = nil
    //var networkTimer: Timer? = nil
    
    var newlyDroppedAnnotations:[WeatherAnnotation:Timer] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //title = "Forecast Buddy"
        
        // retrieve dataController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        
        // info button to navigate to AppInfo
        let button = UIButton(type: .infoLight)
        button.addTarget(self, action: #selector(appInfoButtonPressed(_:)), for: .touchUpInside)
        let bbi = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = bbi
        
        fetchCurrentForecasts()

        degreesF = UserDefaults.standard.bool(forKey: OpenWeatherAPI.UserInfo.degreesUnitsPreferenceKey)
        degreesUnitsToggleBbi.title = degreesF ? "°F" : "°C"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ForecastSegueID" {
            let controller = segue.destination as! FiveDayForecastViewController
            let forecast = sender as? Forecast
            controller.degreesF = degreesF
            controller.dataController = dataController
            controller.forecast = forecast
        }
    }
    
    @IBAction func degreesUnitsToggleBbiPressed(_ sender: Any) {
        
        degreesF = !degreesF
        degreesUnitsToggleBbi.title = degreesF ? "°F" : "°C"
        
        UserDefaults.standard.set(degreesF, forKey: OpenWeatherAPI.UserInfo.degreesUnitsPreferenceKey)
        
        let annotations = mapView.annotations as! [WeatherAnnotation]
        for weatherAnnotation in annotations {
            if let view = mapView.view(for: weatherAnnotation) as? MKMarkerAnnotationView {
                view.detailCalloutAccessoryView = getDetailCalloutAccessory(annotation: weatherAnnotation)
            }
        }
    }
    
    @IBAction func longPressDetected(_ sender: Any) {
        
        // retreive location of touch
        let longPressGr = sender as! UILongPressGestureRecognizer
        let pressLocation = longPressGr.location(in: mapView)
        let coordinate = mapView.convert(pressLocation, toCoordinateFrom: mapView)
        
        if longPressGr.state == .began {
            addNewForecast(coordinate: coordinate)
        }
    }
}

// MARK: MapView Delegate
extension MapViewController {
    
    // handle creation of annotationView
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let weatherAnnotation = annotation as! WeatherAnnotation
        let pinView = MKMarkerAnnotationView(annotation: weatherAnnotation, reuseIdentifier: nil)
        
        pinView.canShowCallout = true
        pinView.animatesWhenAdded = true

        // left accessory...delete weatherAnnotation
        pinView.leftCalloutAccessoryView = getLeftCalloutAccessory()
        
        // right accessory...navigate to WeatherDetailController
        if let _ = weatherAnnotation.forecast?.hourlyForecast {
            pinView.rightCalloutAccessoryView = getRightCalloutAccessory()
        }
        
        // detail accessory...view with current conditions
        pinView.detailCalloutAccessoryView = getDetailCalloutAccessory(annotation: weatherAnnotation)
        
        return pinView
    }
    
    // handle callout accessory tap
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        guard let weatherAnnotation = view.annotation as? WeatherAnnotation, let forecast = weatherAnnotation.forecast else {
            return
        }
        
        if control == view.rightCalloutAccessoryView {
            performSegue(withIdentifier: "ForecastSegueID", sender: forecast)
        }
        
        if control == view.leftCalloutAccessoryView {
            dataController.deleteManagedObjects(objects: [forecast]) { error in
                if let _ = error {
                    print("pin delete error")
                }
            }
            
            mapView.removeAnnotation(weatherAnnotation)
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        degreesUnitsToggleBbi.isEnabled = false
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        degreesUnitsToggleBbi.isEnabled = true
    }
}

extension MapViewController {
    
    func getLeftCalloutAccessory() -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0.0, y: 0.0, width: 35.0, height: 35.0)
        button.setImage(UIImage(named: "LeftAccessory"), for: .normal)
        return button
    }
    
    func getRightCalloutAccessory() -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0.0, y: 0.0, width: 35.0, height: 35.0)
        button.setImage(UIImage(named: "RightAccessory"), for: .normal)
        return button
    }
    
    func getDetailCalloutAccessory(annotation: WeatherAnnotation) -> UIView? {

        let detailView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0))
        
        if let forecast = annotation.forecast, let currentCondition = forecast.currentCondition, let icon = currentCondition.icon {
            
            let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 35.0))
            imageView.contentMode = .scaleAspectFit

            if let image = UIImage(named: icon) {
                imageView.image = image
            } else {
                // TODO: default icon
            }
            detailView.addSubview(imageView)
            
            var temperature = currentCondition.temperatureKelvin
            if degreesF {
                temperature = 1.8 * (temperature - 273.0) + 32.0
            } else {
                temperature = temperature - 273.15
            }
            
            let label = UILabel(frame: CGRect(x: 0.0, y: 35.0, width: 50.0, height: 15.0))
            label.text = " \(Int(temperature))°"
            label.textAlignment = .center
            label.allowsDefaultTighteningForTruncation = true
            detailView.addSubview(label)
        } else {
            let activityIndicator = UIActivityIndicatorView(frame: detailView.bounds)
            activityIndicator.startAnimating()
            detailView.addSubview(activityIndicator)
        }

        let widthConstraint = detailView.widthAnchor.constraint(equalToConstant: 50.0)
        let heightConstraint = detailView.heightAnchor.constraint(equalToConstant: 50.0)
        widthConstraint.isActive = true
        heightConstraint.isActive = true
        
        return detailView
    }
}

extension MapViewController {
    
    func addNewForecast(coordinate: CLLocationCoordinate2D) {
        
        let annotation = WeatherAnnotation()
        annotation.coordinate = coordinate
        updateAnnotationStatus(annotation: annotation)

        annotation.task = dataController.getCurrentForecast(longitude: coordinate.longitude, latitude: coordinate.latitude) { forecastID, error in
            
            guard let forecastID = forecastID else {
                if let _ = error {
                    // TODO: error alert
                } else {
                    // TODO: error alert
                }
                return
            }
            
            if let view = self.mapView.view(for: annotation) as? MKMarkerAnnotationView {
             
                if let timer = self.newlyDroppedAnnotations.removeValue(forKey: annotation) {
                    print("good forecast. Invalidating timer")
                    timer.invalidate()
                }
                
                let forecast = self.dataController.viewContext.object(with: forecastID) as! Forecast
                                
                annotation.forecast = forecast
                annotation.task = nil

                view.detailCalloutAccessoryView = self.getDetailCalloutAccessory(annotation: annotation)
                view.rightCalloutAccessoryView = self.getRightCalloutAccessory()
            }
        }
    }
    
    func updateAnnotationStatus(annotation:WeatherAnnotation) {
        
        mapView.addAnnotation(annotation)
        newlyDroppedAnnotations[annotation] = Timer.scheduledTimer(withTimeInterval: NETWORK_TIMEOUT, repeats: false, block: { timer in
            
            for (weatherAnnotation, timer) in self.newlyDroppedAnnotations {
                
                weatherAnnotation.task?.cancel()
                timer.invalidate()
                self.mapView.removeAnnotation(weatherAnnotation)
            }
            
            self.newlyDroppedAnnotations.removeAll()
            self.showAlert(OpenWeatherAPI.OpenWeatherAPIError.slowNetwork)
        })
    }
}

extension MapViewController {
    
    func fetchCurrentForecasts() {
        
        let fetchRequest:NSFetchRequest<Forecast> = NSFetchRequest(entityName: "Forecast")
        do {
            let forecasts = try dataController.viewContext.fetch(fetchRequest)
            var oldForecasts:[Forecast] = []
            var oldCoordinates:[CLLocationCoordinate2D] = []
            var currentForecasts:[Forecast] = []
            for forecast in forecasts {
                let now = Date()
                if let date = forecast.date, date.distance(to: now) > WEATHER_UPDATE_INTERVAL {
                    oldForecasts.append(forecast)
                    oldCoordinates.append(CLLocationCoordinate2D(latitude: forecast.latitude, longitude: forecast.longitude))
                } else {
                    currentForecasts.append(forecast)
                }
            }
            
            var annotations:[WeatherAnnotation] = []
            for forecast in currentForecasts {
                let annotation = WeatherAnnotation()
                let coordinate = CLLocationCoordinate2D(latitude: forecast.latitude, longitude: forecast.longitude)
                annotation.coordinate = coordinate
                annotation.forecast = forecast
                annotations.append(annotation)
            }
            mapView.addAnnotations(annotations)
            
            dataController.deleteManagedObjects(objects: oldForecasts) { error in
                if let _ = error {
                    // TODO: delete pins error alert
                }
            }
            
            for coordinate in oldCoordinates {
                addNewForecast(coordinate: coordinate)
            }
        } catch {
            // TODO: bad pins fetch error alert
        }
    }
    
    // navigate to AppInfoViewController
    @objc func appInfoButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "AppInfoSegueID", sender: nil)
    }
}
