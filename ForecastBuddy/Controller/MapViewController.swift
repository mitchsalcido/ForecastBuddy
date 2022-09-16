//
//  MapViewController.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//
/*
 About MapViewController:
 Presents a mapView that allows the user to long-touch and place an annotation view. Placement of annotation invokes the downloading of an OpenWeather API current weather data response, and persists into a Forecast core data model.
 The annotations provide accessory views that allow user to delete the annotation, view the current weather conditions, or navigate to five-day forecast tableView
 */

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    // ref to mapView
    @IBOutlet weak var mapView: MKMapView!
    
    // ref to degreesUnits toggle, degrees F/C
    @IBOutlet weak var degreesUnitsToggleBbi: UIBarButtonItem!
    
    // ref to appInfoBbi..segue to AppInfoVC
    var appInfoBbi: UIBarButtonItem!
    
    // ref to CoreDataController
    var dataController:CoreDataController!
        
    // degrees units (°F/°C) shown in annotation view are determined by this property
    var degreesF:Bool!
        
    // update weather info after 3 hours. Persisted forecasts tested at app launch
    let WEATHER_UPDATE_INTERVAL:TimeInterval = 30.0//10800.0
    
    // timeout for network operations. Alert user of network issues
    let NETWORK_TIMEOUT:TimeInterval = 10.0
        
    // Array of newly placed forecast annotaions. Used to test network issues
    var newlyDroppedAnnotations:[WeatherAnnotation:Timer] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // retrieve dataController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        
        // info button to navigate to AppInfoVC
        let button = UIButton(type: .infoLight)
        button.addTarget(self, action: #selector(appInfoButtonPressed(_:)), for: .touchUpInside)
        appInfoBbi = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = appInfoBbi
        
        // retrieve persisted current weather forecasts
        fetchCurrentForecasts()

        // retrieve default °F/°C preference
        degreesF = UserDefaults.standard.bool(forKey: OpenWeatherAPI.UserInfo.degreesUnitsPreferenceKey)
        degreesUnitsToggleBbi.title = degreesF ? "°F" : "°C"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ForecastSegueID" {
            /*
             Handle segue to FiveDayForevastVC. Set properties
             */
            let controller = segue.destination as! FiveDayForecastViewController
            let forecast = sender as? Forecast
            controller.degreesF = degreesF
            controller.dataController = dataController
            controller.forecast = forecast
        }
    }
    
    @IBAction func degreesUnitsToggleBbiPressed(_ sender: Any) {
        /*
         Handle degreesF toggle. Toggles degreesF and updates UserDefault for future use.
         */
        
        // toggle, update bbi title
        degreesF = !degreesF
        degreesUnitsToggleBbi.title = degreesF ? "°F" : "°C"
        
        // update UserDefaults
        UserDefaults.standard.set(degreesF, forKey: OpenWeatherAPI.UserInfo.degreesUnitsPreferenceKey)
        
        // update text in annotationViews
        let annotations = mapView.annotations as! [WeatherAnnotation]
        for weatherAnnotation in annotations {
            if let view = mapView.view(for: weatherAnnotation) as? MKMarkerAnnotationView {
                view.detailCalloutAccessoryView = getDetailCalloutAccessory(annotation: weatherAnnotation)
            }
        }
    }
    
    @IBAction func longPressDetected(_ sender: Any) {
        /*
         Handle placement of new pin annotation
         */
        
        // retrieve map location/coordinates
        let longPressGr = sender as! UILongPressGestureRecognizer
        let pressLocation = longPressGr.location(in: mapView)
        let coordinate = mapView.convert(pressLocation, toCoordinateFrom: mapView)
        
        // test for long press
        if longPressGr.state == .began {
            // good long press. Add new forecast/annotation
            addNewForecast(coordinate: coordinate)
        }
    }
}

// MARK: -MapView Delegate
extension MapViewController {
    
    // handle creation of annotationView
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // cast annotation and create new annotationView
        let weatherAnnotation = annotation as! WeatherAnnotation
        let pinView = MKMarkerAnnotationView(annotation: weatherAnnotation, reuseIdentifier: nil)
        
        pinView.canShowCallout = true
        pinView.animatesWhenAdded = true

        // add left accessory...delete weatherAnnotation
        pinView.leftCalloutAccessoryView = getLeftCalloutAccessory()
        
        // add right accessory...navigate to WeatherDetailController
        if let _ = weatherAnnotation.forecast?.hourlyForecast {
            pinView.rightCalloutAccessoryView = getRightCalloutAccessory()
        }
        
        // add detail accessory...view with current conditions
        pinView.detailCalloutAccessoryView = getDetailCalloutAccessory(annotation: weatherAnnotation)
        
        return pinView
    }
    
    // handle callout accessory tap
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        // verify good WeatherAnnotation
        guard let weatherAnnotation = view.annotation as? WeatherAnnotation else {
            return
        }
        
        // test for right callout. Segue to FiveDayForecastVC
        if control == view.rightCalloutAccessoryView {
            performSegue(withIdentifier: "ForecastSegueID", sender: weatherAnnotation.forecast)
        }
        
        // test for left callout accessory for forecase/annotation deletion
        if control == view.leftCalloutAccessoryView {
            
            if let forecast = weatherAnnotation.forecast {
                // valid forecast. Delete Forecast
                dataController.deleteManagedObjects(objects: [forecast]) { error in
                    if let error = error {
                        // bad deletion. Show error
                        self.showAlert(error)
                    }
                }
            } else {
                /*
                 nil forecast means that network is still trying to download
                 Cancel network task and invalidate timer associated with annotation
                 */
                weatherAnnotation.task?.cancel()
                if let timer = newlyDroppedAnnotations.removeValue(forKey: weatherAnnotation) {
                    timer.invalidate()
                }
            }
            
            // remove annotation from mapView
            mapView.removeAnnotation(weatherAnnotation)
        }
    }

    // disable UI when annotationViews are selected
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        updateUI(enable: false)
    }
    
    // enable UI when annotationViews are deselected
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        updateUI(enable: true)
    }
}

// MARK: -AnnotationView accessory view creation functions
extension MapViewController {
    
    // left callout accessory: Delete annotation/forecast
    func getLeftCalloutAccessory() -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0.0, y: 0.0, width: 35.0, height: 35.0)
        button.setImage(UIImage(named: "LeftAccessory"), for: .normal)
        return button
    }
    
    // right callout accessory: Navigate to FiveDayForecastVC
    func getRightCalloutAccessory() -> UIButton {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0.0, y: 0.0, width: 35.0, height: 35.0)
        button.setImage(UIImage(named: "RightAccessory"), for: .normal)
        return button
    }
    
    // detail callout accessory
    func getDetailCalloutAccessory(annotation: WeatherAnnotation) -> UIView? {
        /*
         Create detailView that includes weather icon image (sun, clouds, rain, etc) and current temperature. If forecast is being downloaded show an activityIndicator.
         */
        
        // detailView
        let detailView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0))
        
        // test for good forecast
        if let forecast = annotation.forecast, let currentCondition = forecast.currentCondition, let icon = currentCondition.icon {
            
            // good forecast. Add weather icon image
            let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 35.0))
            imageView.contentMode = .scaleAspectFit

            // image for imageView
            if let image = UIImage(named: icon) {
                imageView.image = image
            } else {
                imageView.image = UIImage(named: "DefaultWeather")
            }
            
            // add imageView to detailView
            detailView.addSubview(imageView)
            
            // calculate temperate in proper units,°F/°C
            var temperature = currentCondition.temperatureKelvin
            if degreesF {
                temperature = 1.8 * (temperature - 273.0) + 32.0
            } else {
                temperature = temperature - 273.15
            }
            
            // create/add a label with temperature
            let label = UILabel(frame: CGRect(x: 0.0, y: 35.0, width: 50.0, height: 15.0))
            label.text = " \(Int(temperature))°"
            label.textAlignment = .center
            label.allowsDefaultTighteningForTruncation = true
            detailView.addSubview(label)
        } else {
            /*
             nil forecast. Network is still downloading. Use an activityIndicator
             */
            let activityIndicator = UIActivityIndicatorView(frame: detailView.bounds)
            activityIndicator.startAnimating()
            detailView.addSubview(activityIndicator)
        }

        // constraints
        let widthConstraint = detailView.widthAnchor.constraint(equalToConstant: 50.0)
        let heightConstraint = detailView.heightAnchor.constraint(equalToConstant: 50.0)
        widthConstraint.isActive = true
        heightConstraint.isActive = true
        
        return detailView
    }
}

// MARK: -Creating new Forecast functions
extension MapViewController {
    
    // add a new current weather forecast to mapView
    func addNewForecast(coordinate: CLLocationCoordinate2D) {
        /*
         Using coordinates, add an annotaion to the mapView and also begin downloading of current weather from OpenWeather API
         */
        
        // create new annotation
        let annotation = WeatherAnnotation()
        annotation.coordinate = coordinate
        
        // update annotation status (add to map, config download timeout timer
        configureAnnotation(annotation: annotation)

        /*
         retrieve forecast. Returned URLSessionDataTask is used for task cancelation if bad/slow networking
         */
        annotation.task = dataController.getCurrentForecast(longitude: coordinate.longitude, latitude: coordinate.latitude) { forecastID, error in
            
            // test for good objectID (ManagedObject is created on a private queue)
            guard let forecastID = forecastID else {
                if let error = error {
                    // bad forecast objectID
                    self.showAlert(error)
                } else {
                    self.showAlert(CoreDataController.CoreDataError.badData)
                }
                return
            }
            
            // retrieve annatationView
            if let view = self.mapView.view(for: annotation) as? MKMarkerAnnotationView {
                /*
                 Good forecast was created. Invalidate network "timeout" timer and nil task
                 */
                if let timer = self.newlyDroppedAnnotations.removeValue(forKey: annotation) {
                    timer.invalidate()
                }
                annotation.task = nil

                //assign forecast to annotation
                let forecast = self.dataController.viewContext.object(with: forecastID) as! Forecast
                annotation.forecast = forecast

                // update detail accessories with current weather conditions and control to allow navigation to FiveDayForecastVC
                view.detailCalloutAccessoryView = self.getDetailCalloutAccessory(annotation: annotation)
                view.rightCalloutAccessoryView = self.getRightCalloutAccessory()
            }
        }
    }
    
    // update status of annotaions
    func configureAnnotation(annotation:WeatherAnnotation) {
        
        // add to mapView
        mapView.addAnnotation(annotation)
        
        // configure. Add a timer to runloop that functions as a network "timeout" timer
        newlyDroppedAnnotations[annotation] = Timer.scheduledTimer(withTimeInterval: NETWORK_TIMEOUT, repeats: false, block: { timer in
            /*
             network timeout. Completion cancels the network task and removes uncompleted annotations from mapView
             */
            
            // cancel network task and invalidate timer
            for (weatherAnnotation, timer) in self.newlyDroppedAnnotations {
                weatherAnnotation.task?.cancel()
                timer.invalidate()
                self.mapView.removeAnnotation(weatherAnnotation)
            }
            
            // remove all new/incompletely downloaded annotation from dictionary
            self.newlyDroppedAnnotations.removeAll()
            
            // alert to indicate network timeout
            self.showAlert(OpenWeatherAPI.OpenWeatherAPIError.slowNetwork)
        })
    }
}

// MARK: -Misc helper functions
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
                if let error = error {
                    self.showAlert(error)
                }
            }
            
            for coordinate in oldCoordinates {
                addNewForecast(coordinate: coordinate)
            }
        } catch {
            showAlert(CoreDataController.CoreDataError.badFetch)
        }
    }
    
    // navigate to AppInfoViewController
    @objc func appInfoButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "AppInfoSegueID", sender: nil)
    }
    
    // set UI enable state
    func updateUI(enable: Bool) {
        appInfoBbi.isEnabled = enable
        degreesUnitsToggleBbi.isEnabled = enable
    }
}
