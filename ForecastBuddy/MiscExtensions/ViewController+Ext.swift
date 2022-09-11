//
//  ViewController+Ext.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 9/9/22.
//

import UIKit

extension UIViewController {
    
    func showAlert(_ error: LocalizedError) {
        
        let alert = UIAlertController(title: error.localizedDescription, message: error.recoverySuggestion, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
