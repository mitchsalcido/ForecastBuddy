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
    
    var locationManager:CLLocationManager!
    
    var weatherIcons:[String:UIImage] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    @IBAction func homeBbiPressed(_ sender: Any) {
        locationManager.requestLocation()
    }
    
    @IBAction func longPressDetected(_ sender: Any) {
        
        // retreive location of touch
        let longPressGr = sender as! UILongPressGestureRecognizer
        let pressLocation = longPressGr.location(in: mapView)
        let coordinate = mapView.convert(pressLocation, toCoordinateFrom: mapView)
        
        if longPressGr.state == .began {
            let annotation = WeatherAnnotation()
            annotation.coordinate = coordinate
            //annotation.title = "Annotation"
            OpenWeatherAPI.getCurrentWeather(longitude: coordinate.longitude, latitude: coordinate.latitude) { response, error in
                
                guard let currentWeather = response else {
                    print("no weather info found")
                    return
                }
                
                annotation.currentWeather = currentWeather
                self.mapView.addAnnotation(annotation)
                /*
                if let icon = currentWeather.weather.first?.icon {
                    annotation.icon = icon
                    self.mapView.addAnnotation(annotation)
                }
                 */
                print(currentWeather)
            }
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
        guard let icon = weatherAnnotation.currentWeather.weather.first?.icon else {
            return nil
        }
        
        let tempKelvin:Double = weatherAnnotation.currentWeather.main.temp
        let temperature = Int(1.8 * (tempKelvin - 273.0)) + 32
        
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
            getDetailCalloutAccessory(icon: icon, temperature: temperature, annotationView: pinView)
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
        print("regionDidChange")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let weatherAnnotation = view.annotation as! WeatherAnnotation
        if let currentWeather = weatherAnnotation.currentWeather {
            print(currentWeather)
        }
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
    
    func getDetailCalloutAccessory(icon: String, temperature: Int, annotationView: MKMarkerAnnotationView) {
        
        if let weatherImageIcon = weatherIcons[icon] {
            configureDetailCalloutAccessory(weatherImage: weatherImageIcon, temperature: temperature, annotationView: annotationView)
        } else {
            
            OpenWeatherAPI.getWeatherIcon(icon: icon) { image in
                guard let image = image else {
                    self.configureDetailCalloutAccessory(weatherImage: nil, temperature: temperature, annotationView: annotationView)
                    return
                }
                
                self.weatherIcons[icon] = image
                self.configureDetailCalloutAccessory(weatherImage: image, temperature: temperature, annotationView: annotationView)
            }
        }
    }
    
    func configureDetailCalloutAccessory(weatherImage: UIImage?, temperature: Int, annotationView:MKMarkerAnnotationView) {
        
        let detailView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0))
        let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 35.0))
        imageView.image = weatherImage
        imageView.contentMode = .scaleAspectFit
        
        detailView.addSubview(imageView)
        
        let label = UILabel(frame: CGRect(x: 0.0, y: 35.0, width: 50.0, height: 15.0))
        label.text = "\(temperature)°F"
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
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError")
    }
}

