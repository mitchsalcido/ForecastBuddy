//
//  UIView+Ext.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/31/22.
//

import UIKit


extension UIView {
    func imageFromView() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
