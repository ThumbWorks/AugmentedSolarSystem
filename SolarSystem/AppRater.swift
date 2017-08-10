//
//  AppRater.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 8/10/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import UIKit
import StoreKit

class AppRater {
    class func requestEventIsAppropriate() {
        // check if last loaded timestamp is greater than 24 hours
        let key = "firstRunTimestamp"
        let now = Date().timeIntervalSince1970
        
        // check when the first install was. Per docs, this will default to 0.
        let firstInstall = UserDefaults.standard.double(forKey: key)
        print("first install is \(firstInstall)")
        
        if firstInstall == 0 {
            // haven't run the app yet, set the key
            print("let's come back in a day to ask them, set a timestamp for now and check the delta")
            UserDefaults.standard.set(now, forKey: key)
            return
        }
        
        // Check if it is more than 1 day old, if so, request
        let oneDayAgo = now - 24 * 60 * 60
        if firstInstall < oneDayAgo {
            SKStoreReviewController.requestReview()
        } else {
            print("install was \(firstInstall) one day ago was \(oneDayAgo)")
        }
    }
}
