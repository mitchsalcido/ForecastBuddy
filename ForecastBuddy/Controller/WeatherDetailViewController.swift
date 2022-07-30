//
//  WeatherDetailViewController.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 7/29/22.
//

import UIKit

class WeatherDetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    let pngStrings = ["01d.png", "02d.png", "03d.png", "04d.png", "09d.png", "10d.png", "11d.png", "13d.png", "50d.png"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        let index = Int.random(in: 0..<pngStrings.count)
        getIcon(png: pngStrings[index])
    }
    
    func getIcon(png:String) {
        
        let urlString = "https://openweathermap.org/img/wn/" + png
        guard let url = URL(string: urlString) else {
            print("bad urlString")
            return
        }
        
        if let data = try? Data(contentsOf: url) {
            print("good data")
            self.imageView.image = UIImage(data: data)
        } else {
            print("bad data: \(url)")
        }
    }
}
