//
//  AboutView.swift
//  SolAR
//
//  Created by Roderic Campbell on 2/12/19.
//  Copyright © 2019 Roderic Campbell. All rights reserved.
//

import SwiftMessages

class AboutView: MessageView {
    @IBOutlet weak var bottomText: UITextView!
    @IBOutlet weak var topText: UITextView!
    @IBOutlet weak var topTextHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomTextHeightConstraint: NSLayoutConstraint!

    func updateHeightConstraints() {
        bottomTextHeightConstraint.constant = bottomText.contentSize.height
        bottomText.layoutIfNeeded()

        topTextHeightConstraint.constant = topText.contentSize.height
        topText.layoutIfNeeded()
    }
}
