//
//  HudView.swift
//  SolAR
//
//  Created by Roderic Campbell on 2/14/19.
//  Copyright © 2019 Roderic Campbell. All rights reserved.
//

import UIKit

extension UICollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

class HUDView: UIView {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var axial: UILabel!
    @IBOutlet weak var radius: UILabel!
    @IBOutlet weak var distance: UILabel!

    static func instantiate() -> HUDView {
        let view: HUDView = initFromNib()
        return view
    }
}
