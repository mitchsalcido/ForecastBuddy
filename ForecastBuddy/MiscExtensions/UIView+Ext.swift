//
//  UIView+Ext.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/31/22.
//

import UIKit


extension UIView {
    func imageFromView() -> UIImage? {
        
        //return UIImage(named: "01d")
        /*
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        let image = renderer.image { context in
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
        
        return image
         */
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
