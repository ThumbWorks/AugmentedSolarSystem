//
//  DatePickerViewController.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 8/25/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import UIKit
class DatePickerViewController: UIViewController {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    var dateSelection: ((Date, Bool) -> ())?

    @IBAction func datePickerValueChange(_ sender: Any) {
        if let selection = dateSelection {
            selection(datePicker.date, false)
        }
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        // send it up
        if let selection = dateSelection {
            selection(datePicker.date, true)
        }
    }
}
