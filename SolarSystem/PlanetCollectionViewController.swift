//
//  PlanetCollectionViewController.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 7/17/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import UIKit

class PlanetCollectionViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var dataSource: PlanetDataSource!
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var axialTilt: UILabel!
    @IBOutlet weak var rotationDuration: UILabel!
    @IBOutlet weak var radius: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var sizeReference: UILabel!
    
    var currentPlanet: Planet?

    override func viewDidLoad() {
        distance.text = ""
    }
    func updateDistance(_ distanceString: String) {
        distance.text =  distanceString
    }
    
    func updateReferenceSize(_ sizes: [Planet:Float]) {
        if let planet = currentPlanet, let meters = sizes[planet] {
            sizeReference.text =  ScaleReference.objectSizeDescription(for: meters)
        }
    }
    
    func changeToPlanet(name: String) {
//        if let indexPath = dataSource.pathForPlanet(with: name) {
//            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//        }
    }
    
    func changePlanetSelection() {
        return
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
        
        name.text = currentPlanet.name.uppercased()
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
}

extension Float {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
