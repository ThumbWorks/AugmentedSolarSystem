//
//  WhiteView.swift
//  SolAR
//
//  Created by Roderic Campbell on 4/3/19.
//  Copyright © 2019 Roderic Campbell. All rights reserved.
//

import UIKit

class WhiteView: UIView {
    override func awakeFromNib() {
        layer.cornerRadius = 20
        layer.masksToBounds = true
        backgroundColor = .white
    }
}
