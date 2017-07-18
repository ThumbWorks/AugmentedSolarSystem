//
//  PlanetCollectionViewController.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 7/17/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class PlanetCollectionViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var dataSource: PlanetDataSource!
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var axialTilt: UILabel!
    @IBOutlet weak var rotationDuration: UILabel!
    @IBOutlet weak var radius: UILabel!
    
    var planetSelectionChanged: ((Planet) -> ())?
    func changePlanetSelection() {
        let centerPoint = CGPoint(x: collectionView.center.x + collectionView.contentOffset.x, y: 0)
        print("center point \(centerPoint)")
        guard let indexPath = collectionView.indexPathForItem(at: collectionView.contentOffset) else {
            print("no index path at center")
            return
        }
        let currentPlanet = dataSource.planets[indexPath.row]
        
        if let closure = planetSelectionChanged {
            closure(currentPlanet)
        }
        
        name.text = currentPlanet.name
        axialTilt.text = "\(currentPlanet.axialTilt) degree tilt"
        rotationDuration.text = "\(currentPlanet.rotationDuration) hour days"
        radius.text = "\(currentPlanet.radius) km radius"
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("\n\nend scrolling, change labels \(collectionView.contentOffset)")
        changePlanetSelection()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        changePlanetSelection()
    }
}

class PlanetDataSource: NSObject, UICollectionViewDataSource {
    let planets = Planet.allPlanets
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return planets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let planet = planets[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "planetCell", for: indexPath) as! PlanetCell
        
        let sceneString = "art.scnassets/\(planet.name).scn"
        let scene = SCNScene(named: sceneString)!
        cell.sceneView.scene = scene
        
        let aPlanetNode = scene.rootNode
        let radianTilt = planet.axialTilt / 360 * 2*Float.pi
        aPlanetNode.rotation = SCNVector4Make(0, 0, 1, radianTilt)
        
        let rotationDuration = 16.0 // seems like a good rotation
        aPlanetNode.rotate(duration: rotationDuration)
        return cell
    }
}

class PlanetCell: UICollectionViewCell {
    @IBOutlet var sceneView: SCNView!
}
