//
//  PlanetCell.swift
//  SolAR
//
//  Created by Roderic Campbell on 2/14/19.
//  Copyright © 2019 Roderic Campbell. All rights reserved.
//

import UIKit
import SceneKit

class PlanetCell: UICollectionViewCell {
    @IBOutlet var sceneView: SCNView!

    override func prepareForReuse() {
        sceneView.scene = nil
    }

}
