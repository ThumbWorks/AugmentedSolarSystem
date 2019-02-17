//
//  PlanetDataSource.swift
//  SolAR
//
//  Created by Roderic Campbell on 2/14/19.
//  Copyright © 2019 Roderic Campbell. All rights reserved.
//

import UIKit
import SceneKit

class PlanetDataSource: NSObject, UICollectionViewDataSource {
    let planets = Planet.allPlanets

    func pathForPlanet(with name: String) -> IndexPath? {
        print("path for planet")
        if let index = planets.index(where: { (planet) -> Bool in
            return planet.name == name
        }) {
            return IndexPath(row: index, section: 0)
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return planets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let planet = planets[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlanetCell.reuseIdentifier, for: indexPath) as! PlanetCell
        let sceneString = "art.scnassets/\(planet.name).scn"
        let scene = SCNScene(named: sceneString)!
        cell.sceneView.scene = scene

        let aPlanetNode = scene.rootNode
        let radianTilt = planet.axialTilt / 360 * 2*Float.pi
        aPlanetNode.rotation = SCNVector4Make(0, 0, 1, radianTilt)

        let rotationDuration = 16.0 // seems like a good rotation
        let action = SCNAction.createRotateAction(duration: rotationDuration)
        aPlanetNode.runAction(action)
        return cell
    }
}
