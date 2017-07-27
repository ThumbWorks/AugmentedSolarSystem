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
    @IBOutlet weak var distance: UILabel!
    
    var planetSelectionChanged: ((Planet) -> ())?
    var currentPlanet: Planet?
    func updateDistance(distances: [Planet:Float]) {
        if let planet = currentPlanet, let meters = distances[planet] {
            distance.text =  "\(meters.format(f: ".1")) real meters away"
        }
    }
    
    func changeToPlanet(name: String) {
        if let indexPath = dataSource.pathForPlanet(with: name) {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func changePlanetSelection() {
        
        // find the center of the frame wrt the content offset. 10 is
        let collectionViewSize = collectionView.frame.size
        let centerXFrame = collectionView.contentOffset.x + collectionViewSize.width/2
        let point = CGPoint(x: centerXFrame, y: collectionViewSize.height / 2)
        
        guard let indexPath = collectionView.indexPathForItem(at: point) else {
            print("no index path at center")
            return
        }
        currentPlanet = dataSource.planets[indexPath.row]
        
        guard let currentPlanet = currentPlanet else {
            print("unknown state here, what is our current planet derived from the index path?")
            return
        }
        if let closure = planetSelectionChanged {
            closure(currentPlanet)
        }
        
        name.text = currentPlanet.name
        axialTilt.text = "\(currentPlanet.axialTilt) degree tilt"
        rotationDuration.text = "\(currentPlanet.rotationDuration) hour days"
        radius.text = "\(currentPlanet.radius) km radius"
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("\n\nend scrolling, change labels \(collectionView.contentOffset)")
        changePlanetSelection()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("\n\nend scrolling, change labels \(collectionView.contentOffset)")
        changePlanetSelection()
    }
    override func viewDidAppear(_ animated: Bool) {
        changePlanetSelection()
    }
    
    func hintScrollable() {
        UIView.animate(withDuration: 2, delay: 3, options: [], animations: {
            self.collectionView.contentOffset = CGPoint(x: self.collectionView.frame.size.width / 2, y: 0)
        }) { (completed) in
            UIView.animate(withDuration: 2, animations: {
                self.collectionView.contentOffset = CGPoint(x: 0, y: 0)
            })
        }
    }
}

extension Float {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

class PlanetDataSource: NSObject, UICollectionViewDataSource {
    let planets = Planet.allPlanets
    
    func pathForPlanet(with name: String) -> IndexPath? {
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
