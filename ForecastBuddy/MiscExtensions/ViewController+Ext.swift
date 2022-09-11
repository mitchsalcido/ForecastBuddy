//
//  ViewController+Ext.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 9/9/22.
//

import UIKit

extension UIViewController {
    
    func showAlert() {
        
        let alert = UIAlertController(title: "No Data", message: "Bad network data. Try later", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
