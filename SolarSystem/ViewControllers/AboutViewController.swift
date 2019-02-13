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

    let aboutView = AboutView()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = aboutView
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        Mixpanel.sharedInstance()?.track("About View Loaded")
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true)
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
           self.aboutView.updateHeightConstraints()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        aboutView.updateHeightConstraints()
    }
}
