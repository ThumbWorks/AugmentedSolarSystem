//
//  StatusLabelViewController.swift
//  SolAR
//
//  Created by Roderic Campbell on 4/3/19.
//  Copyright © 2019 Roderic Campbell. All rights reserved.
//

import UIKit

struct StatusLabelViewModel {
    let text: String?
    static var searchForSurface = StatusLabelViewModel(text: "Searching for a surface")
    static var tapToSetSolarSystem = StatusLabelViewModel(text: "Tap to set the Solar System")
    static func inside(celestialObject: String) -> StatusLabelViewModel {
        return StatusLabelViewModel(text: "You are inside \(celestialObject)")
    }
    static func limitedTracking(reason: String) -> StatusLabelViewModel {
        return StatusLabelViewModel(text: "Tracking Limited: \(reason)")
    }
    static var trackingUnavailable = StatusLabelViewModel(text: "Tracking unavailable")
    static var selectPlanet = StatusLabelViewModel(text: "Select a date to see the planet alignment at that point in time")
}



class StatusLabelViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    let statusLabelView = StatusLabelView.instantiate()

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = statusLabelView
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    func update(with viewModel: StatusLabelViewModel) {
        statusLabelView.label.text = viewModel.text
    }
}
