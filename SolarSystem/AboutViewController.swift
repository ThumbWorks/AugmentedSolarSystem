//
//  AboutViewController.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 8/7/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import UIKit
import Mixpanel

class AboutViewController: UIViewController {
    override func viewDidLoad() {
        Mixpanel.sharedInstance()?.track("About View Loaded")
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func visitThumbworks(_ sender: Any) {
        Mixpanel.sharedInstance()?.track("Tap Thumbworks")
        if let url = URL(string: "http://twitter.com/thumbworksinc") {
            UIApplication.shared.open(url, options:[:] )
        }
    }
}
