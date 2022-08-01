//
//  MapViewController.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//

import UIKit
import MapKit
import CoreLocation

// 37.77° N lat, -122.41° W lon San Fran
// 39.73° N lat, -121.84° W lon Chico
class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var homeBbi: UIBarButtonItem!
    @IBOutlet weak var degreesUnitsToggleBbi: UIBarButtonItem!
    
    var locationManager:CLLocationManager!
    
    var targetRegion:MKCoordinateRegion?
    var degreesF = true
    
    var weatherIcons:[String:UIImage] = [:]
    
    let DISTANCE_RESOLUTION = 500.0 // 500 meters
    let MILE_IN_METERS = 1600.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        degreesUnitsToggleBbi.title = "°F"
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    @IBAction func homeBbiPressed(_ sender: Any) {
        locationManager.requestLocation()
    }
    
    @IBAction func degreesUnitsToggleBbiPressed(_ sender: Any) {
        degreesF = !degreesF
        degreesUnitsToggleBbi.title = degreesF ? "°F" : "°C"
        
        let annotations = mapView.annotations as! [WeatherAnnotation]
        for annotation in annotations {
            if let view = mapView.view(for: annotation) as? MKMarkerAnnotationView {
                configureDetailCalloutAccessory(annotationView: view)
            }
        }
    }
    
    @IBAction func longPressDetected(_ sender: Any) {
        
        // retreive location of touch
        let longPressGr = sender as! UILongPressGestureRecognizer
        let pressLocation = longPressGr.location(in: mapView)
        let coordinate = mapView.convert(pressLocation, toCoordinateFrom: mapView)
        
        if longPressGr.state == .began {
            insertAnnotationAtCoordinate(coordinate: coordinate)
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
            getDetailCalloutAccessory(annotationView: pinView)
        }
        
        return pinView
    }
    
    // handle callout accessory tap
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        guard let weatherAnnotation = view.annotation as? WeatherAnnotation else {
            return
        }
        
        if control == view.rightCalloutAccessoryView {
            performSegue(withIdentifier: "WeatherDetailSegueID", sender: nil)
        }
        
        if control == view.leftCalloutAccessoryView {
            mapView.removeAnnotation(weatherAnnotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        if let targetRegion = targetRegion {
            if regionsEqual(regionA: targetRegion, regionB: mapView.region, metersResolution: DISTANCE_RESOLUTION) {
                self.targetRegion = nil
                
                let annotations = mapView.annotations(in: mapView.visibleMapRect) as! Set<WeatherAnnotation>
                for annotation in annotations {
                    if coordinatesEqual(coordA: mapView.region.center, coordB: annotation.coordinate, metersResolution: MILE_IN_METERS) {
                        mapView.removeAnnotation(annotation)
                    }
                }
                insertAnnotationAtCoordinate(coordinate: mapView.region.center) { annotation in
                    self.mapView.selectAnnotation(annotation, animated: true)
                }
            }
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        homeBbi.isEnabled = false
        degreesUnitsToggleBbi.isEnabled = false
                
        let weatherAnnotation = view.annotation as! WeatherAnnotation
        print(weatherAnnotation.currentWeather!)
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
    
    func getDetailCalloutAccessory(annotationView: MKMarkerAnnotationView) {
        let annotation = annotationView.annotation as! WeatherAnnotation
        let icon = annotation.icon
        if let _ = weatherIcons[icon] {
            configureDetailCalloutAccessory(annotationView: annotationView)
        } else {
            OpenWeatherAPI.getWeatherIcon(icon: icon) { image in
                
                if let image = image {
                    self.weatherIcons[icon] = image
                }
                self.configureDetailCalloutAccessory(annotationView: annotationView)
            }
        }
    }
    
    func configureDetailCalloutAccessory(annotationView:MKMarkerAnnotationView) {
        let annotation = annotationView.annotation as! WeatherAnnotation
        let icon = annotation.icon
        let detailView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0))
        let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 35.0))
        imageView.image = weatherIcons[icon]
        imageView.contentMode = .scaleAspectFit
        detailView.addSubview(imageView)
        
        var temperature:Double!
        if degreesF {
            temperature = 1.8 * (annotation.temperature - 273.0) + 32.0
        } else {
            temperature = annotation.temperature - 273.15
        }
        
        let label = UILabel(frame: CGRect(x: 0.0, y: 35.0, width: 50.0, height: 15.0))
        label.text = degreesF ? "\(Int(temperature))°F" : "\(Int(temperature))°C"
        label.textAlignment = .center
        label.allowsDefaultTighteningForTruncation = true
        detailView.addSubview(label)
        
        let detailImageView = UIImageView(frame: detailView.bounds)
        detailImageView.image = detailView.self.imageFromView()
        annotationView.detailCalloutAccessoryView = detailImageView
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
        print("didFailWithError")
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
    
    func insertAnnotationAtCoordinate(coordinate:CLLocationCoordinate2D, completion:((WeatherAnnotation) -> Void)? = nil) {
        
        let annotation = WeatherAnnotation()
        annotation.coordinate = coordinate
        OpenWeatherAPI.getCurrentWeather(longitude: coordinate.longitude, latitude: coordinate.latitude) { response, error in
            
            guard let currentWeather = response else {
                print("no weather info found")
                return
            }
            
            annotation.currentWeather = currentWeather
            self.mapView.addAnnotation(annotation)
            if let completion = completion {
                completion(annotation)
            }
        }
    }
}
