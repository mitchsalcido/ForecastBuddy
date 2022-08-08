//
//  MapViewController.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

// 37.77° N lat, -122.41° W lon San Fran
// 39.73° N lat, -121.84° W lon Chico
class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var homeBbi: UIBarButtonItem!
    @IBOutlet weak var degreesUnitsToggleBbi: UIBarButtonItem!
    
    var dataController:CoreDataController!
    
    var locationManager:CLLocationManager!
    
    var targetRegion:MKCoordinateRegion?
    var degreesF:Bool!
        
    let DISTANCE_RESOLUTION = 500.0 // 500 meters
    let MILE_IN_METERS = 1600.0
    let WEATHER_UPDATE_INTERVAL:TimeInterval = 30.0//10800.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Forecast Buddy"
        
        // retrieve dataController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        fetchCurrentForecasts()

        degreesF = UserDefaults.standard.bool(forKey: OpenWeatherAPI.UserInfo.degreesUnitsPreferenceKey)
        degreesUnitsToggleBbi.title = degreesF ? "°F" : "°C"

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ForecastSegueID" {
            let controller = segue.destination as! ForecastTableViewController
            controller.coordinate = sender as? CLLocationCoordinate2D
            controller.degreesF = degreesF
        }
    }
    
    @IBAction func homeBbiPressed(_ sender: Any) {
        locationManager.requestLocation()
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
            addNewPin(coordinate: coordinate)
        }
    }
    
}

// MARK: MapView Delegate
extension MapViewController {
    
    // handle creation of annotationView
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reUseID = "pinReuseID"
        let pinView: MKMarkerAnnotationView!
        
        let weatherAnnotation = annotation as! WeatherAnnotation
        
        // dequeue or create new if nil
        if let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reUseID) as? MKMarkerAnnotationView {
            pinView.annotation = weatherAnnotation
            return pinView
        } else {
            pinView = MKMarkerAnnotationView(annotation: weatherAnnotation, reuseIdentifier: reUseID)
            pinView.canShowCallout = true
            pinView.animatesWhenAdded = true

            // left accessory...delete weatherAnnotation
            pinView.leftCalloutAccessoryView = getLeftCalloutAccessory()
            
            // right accessory...navigate to WeatherDetailController
            pinView.rightCalloutAccessoryView = getRightCalloutAccessory()
            
            // detail accessory...view with current conditions
            pinView.detailCalloutAccessoryView = getDetailCalloutAccessory(annotation: weatherAnnotation)
        }
        return pinView
    }
    
    // handle callout accessory tap
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        guard let weatherAnnotation = view.annotation as? WeatherAnnotation, let pin = weatherAnnotation.forecast else {
            return
        }
        
        if control == view.rightCalloutAccessoryView {
            performSegue(withIdentifier: "ForecastSegueID", sender: weatherAnnotation.coordinate)
        }
        
        if control == view.leftCalloutAccessoryView {
            dataController.deleteManagedObjects(objects: [pin]) { error in
                if let _ = error {
                    print("pin delete error")
                }
            }
            mapView.removeAnnotation(weatherAnnotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        if let targetRegion = targetRegion {
            if regionsEqual(regionA: targetRegion, regionB: mapView.region, metersResolution: DISTANCE_RESOLUTION) {
                self.targetRegion = nil
                
                addNewPin(coordinate: mapView.region.center)

                let annotations = mapView.annotations(in: mapView.visibleMapRect) as! Set<WeatherAnnotation>
                
                var nearbyPins:[Forecast] = []
                for annotation in annotations {
                    if coordinatesEqual(coordA: mapView.region.center, coordB: annotation.coordinate, metersResolution: MILE_IN_METERS) {
                        
                        print("removing rearby annot's")
                        mapView.removeAnnotation(annotation)
                        if let pin = annotation.forecast {
                            nearbyPins.append(pin)
                        }
                    }
                }
                dataController.deleteManagedObjects(objects: nearbyPins) { error in
                    if let _ = error {
                        print("bad remove annot/pin")
                    }
                }
            }
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        homeBbi.isEnabled = false
        degreesUnitsToggleBbi.isEnabled = false
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        homeBbi.isEnabled = true
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
        
        guard let forecasts = annotation.forecast.hourlyForecast?.allObjects as? [HourlyForecast], let icon = forecasts.first?.name, var temperature = forecasts.first?.temperatureKelvin else {
            return nil
        }
    
        let detailView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0))
        
        let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 35.0))
        imageView.contentMode = .scaleAspectFit

        if let image = UIImage(named: icon) {
            imageView.image = image
        } else {
            // TODO: default icon
        }
        detailView.addSubview(imageView)
        
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

        let widthConstraint = detailView.widthAnchor.constraint(equalToConstant: 50.0)
        let heightConstraint = detailView.heightAnchor.constraint(equalToConstant: 50.0)
        widthConstraint.isActive = true
        heightConstraint.isActive = true
        
        return detailView
    }
}

extension MapViewController {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        homeBbi.isEnabled = manager.authorizationStatus == .authorizedWhenInUse
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        let currentLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let region = MKCoordinateRegion(center: currentLocation, span: span)
        targetRegion = region
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // TODO: location fail alert
    }
}

extension MapViewController {
    
    func regionsEqual(regionA:MKCoordinateRegion, regionB:MKCoordinateRegion, metersResolution:Double) -> Bool {
        
        return coordinatesEqual(coordA: regionA.center, coordB: regionB.center, metersResolution: metersResolution)
    }
    
    func coordinatesEqual(coordA:CLLocationCoordinate2D, coordB: CLLocationCoordinate2D, metersResolution:Double) -> Bool {
        let locationA = CLLocation(latitude: coordA.latitude, longitude: coordA.longitude)
        let locationB = CLLocation(latitude: coordB.latitude, longitude: coordB.longitude)
        return locationB.distance(from: locationA) < metersResolution
    }
}

extension MapViewController {
    
    func addNewPin(coordinate: CLLocationCoordinate2D) {
        
        OpenWeatherAPI.getCurrentWeather(longitude: coordinate.longitude, latitude: coordinate.latitude) { response, error in
            
            guard let icon = response?.weather.first?.icon, let temperature = response?.main.temp else {
                return
            }
            
            let forecast = Forecast(context: self.dataController.viewContext)
            forecast.latitude = coordinate.latitude
            forecast.longitude = coordinate.longitude
            forecast.date = Date()
            
            let hourlyForecast = HourlyForecast(context: self.dataController.viewContext)
            hourlyForecast.name = icon
            hourlyForecast.temperatureKelvin = temperature
            hourlyForecast.date = Date()
            
            hourlyForecast.forecast = forecast
            
            self.dataController.saveContext(context: self.dataController.viewContext) { error in
                
                if let _ = error {
                } else {
                    let annotation = WeatherAnnotation()
                    annotation.coordinate = coordinate
                    annotation.forecast = forecast
                    self.mapView.addAnnotation(annotation)
                }
            }
        }
    }
}

extension MapViewController {
    
    func fetchCurrentForecasts() {
        
        let fetchRequest:NSFetchRequest<Forecast> = NSFetchRequest(entityName: "Forecast")
        let predicate = NSPredicate(format: "hourlyForecast.@count == 1")
        fetchRequest.predicate = predicate
        
        do {
            let results = try dataController.viewContext.fetch(fetchRequest)
            var oldPins:[Forecast] = []
            var oldCoordinates:[CLLocationCoordinate2D] = []
            var currentPins:[Forecast] = []
            for pin in results {
                let now = Date()
                if let date = pin.date, date.distance(to: now) > WEATHER_UPDATE_INTERVAL {
                    oldPins.append(pin)
                    oldCoordinates.append(CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
                } else {
                    currentPins.append(pin)
                }
            }
            
            var annotations:[WeatherAnnotation] = []
            for pin in currentPins {
                let annotation = WeatherAnnotation()
                let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                annotation.coordinate = coordinate
                annotation.forecast = pin
                annotations.append(annotation)
            }
            mapView.addAnnotations(annotations)
            
            dataController.deleteManagedObjects(objects: oldPins) { error in
                if let _ = error {
                    // TODO: delete pins error alert
                }
            }
            
            for coordinate in oldCoordinates {
                addNewPin(coordinate: coordinate)
            }
        } catch {
            // TODO: bad pins fetch error alert
        }
    }
}
