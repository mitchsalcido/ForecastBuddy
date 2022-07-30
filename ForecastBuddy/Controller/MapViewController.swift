//
//  MapViewController.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//

import UIKit
import MapKit

// San Fran: 37.7749° N, -122.4194° W
// Chico CA: 39.73° N, -121.84° W
class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var weatherIcons:[String:UIImage] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //OpenWeatherAPI.getCurrentWeather(longitude: -122.4194, latitude: 37.7749)
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let weatherAnnotation = view.annotation as! WeatherAnnotation
        if let icon = weatherAnnotation.currentWeather.weather.first?.icon {
            print(icon)
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

extension UIView {
    func imageFromView() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
