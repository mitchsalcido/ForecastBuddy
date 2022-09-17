//
//  ViewController+Ext.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 9/9/22.
//
/*
 About ViewController+Ext:
 Extent functionality of UIViewController
 */

import UIKit

extension UIViewController {
    
    // show an alert with an "OK" dismiss button
    func showAlert(_ error: LocalizedError) {
        
        let alert = UIAlertController(title: error.localizedDescription, message: error.recoverySuggestion, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
