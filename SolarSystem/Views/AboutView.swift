//
//  AboutView.swift
//  SolAR
//
//  Created by Roderic Campbell on 2/12/19.
//  Copyright © 2019 Roderic Campbell. All rights reserved.
//

import SwiftMessages
import Mixpanel

class AboutView: MessageView {
    @IBOutlet weak var bottomText: UITextView!
    @IBOutlet weak var topText: UITextView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @IBAction func visitThumbworks(_ sender: Any) {
        Mixpanel.sharedInstance()?.track("Tap Thumbworks")
        if let url = URL(string: "http://thumbworks.io") {
            UIApplication.shared.open(url, options:[:] )
        }
    }

    @IBAction func rateTheApp(_ sender: Any) {
        Mixpanel.sharedInstance()?.track("Rate the app")
        let appID = "1262856697"
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review") {
            UIApplication.shared.open(url, options:[:] )
        }
    }

    @IBAction func seeOtherApps(_ sender: Any) {
        Mixpanel.sharedInstance()?.track("See other apps")
        if let url = URL(string: "http://appstore.com/thumbworks") {
            UIApplication.shared.open(url, options:[:] )
        }
    }

    @IBAction func visitTwitter(_ sender: Any) {
        if let url = URL(string: "twitter://user?screen_name=thumbworksinc") {
            if UIApplication.shared.canOpenURL(url) {
                Mixpanel.sharedInstance()?.track("Tap Twitter Native")
                UIApplication.shared.open(url, options:[:] )
                return
            }
        }
        if let url = URL(string: "http://twitter.com/thumbworksinc") {
            Mixpanel.sharedInstance()?.track("Tap Twitter Safari")
            UIApplication.shared.open(url, options:[:] )
        }
    }
}
