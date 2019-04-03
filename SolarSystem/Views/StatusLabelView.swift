//
//  StatusLabelView.swift
//  SolAR
//
//  Created by Roderic Campbell on 4/3/19.
//  Copyright © 2019 Roderic Campbell. All rights reserved.
//

import UIKit

class StatusLabelView: UIView {
    @IBOutlet weak var label: UILabel!
    static func instantiate() -> StatusLabelView {
        let view: StatusLabelView = initFromNib()
        return view
    }
}
