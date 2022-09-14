//
//  ForecastTableViewCell.swift
//  ForecastBuddy
//
//  Created by Mitchell Salcido on 8/1/22.
//
/*
 About ForecastTableViewCell:
 Custom tableView cell for displaying time, temperature, description, and image of weather icon
 */

import UIKit

class ForecastTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherDescriptionLabel: UILabel!
}
