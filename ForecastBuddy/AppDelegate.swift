//
//  AppDelegate.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // ref to core data stack/controller
    var dataController:CoreDataController!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // set up core data
        dataController = CoreDataController(name: "ForecastModel")
        dataController.load()
        
        // Configure Degrees Fah/Cel user preference stored in UserDefaults
        if UserDefaults.standard.value(forKey: OpenWeatherAPI.UserInfo.degreesUnitsPreferenceKey) == nil {
            
            // default to Far (true) on first app use
            UserDefaults.standard.set(true, forKey: OpenWeatherAPI.UserInfo.degreesUnitsPreferenceKey)
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

