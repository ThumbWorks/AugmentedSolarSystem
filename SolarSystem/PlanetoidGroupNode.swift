//
//  PlanetoidGroupNode.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 7/12/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import SceneKit

class PlanetoidGroupNode: SCNNode {
    // The node that shows the orbital path which is used for hiding
    let path: SCNNode?
    
    // The geometry representing the orbital path which is used for scaling
    let torus: SCNTorus?
    
    var planetNode: SCNNode?
    required init(planet: Planet) {
        
        let sceneString = "art.scnassets/\(planet.name).scn"
        let scene = SCNScene(named: sceneString)!
        
        if planet.orbitalRadius > 0 {
            torus = SCNTorus(ringRadius: planet.displayOrbitalRadius, pipeRadius: 0.001)
            path = SCNNode(geometry: torus)
        } else {
            path = nil
            torus = nil
        }
        
        super.init()
        
        if let node = scene.rootNode.childNodes.first {
            let geometry = node.geometry
            
            // TODO look into if I can just use the node that we know we have for this
            let aPlanetNode = SCNNode(geometry: geometry)
            //            aPlanetNode.scale = SCNVector3Make(planet.radius, planet.radius, planet.radius)
            aPlanetNode.scale = SCNVector3Make(0.05, 0.05, 0.05)
            aPlanetNode.position = SCNVector3Make(Float(planet.displayOrbitalRadius), 0, 0)
            aPlanetNode.categoryBitMask = 1
            aPlanetNode.name = planet.name
            self.addChildNode(aPlanetNode)
            let radianTilt = planet.axialTilt / 360 * 2*Float.pi
            aPlanetNode.rotation = SCNVector4Make(0, 0, 1, radianTilt)
            
            // Normalize to Earth's rotation (earth is now 1 second)
            let normalizedRotationDuration = planet.rotationDuration / Planet.earth.rotationDuration
            aPlanetNode.rotate(duration: normalizedRotationDuration)
            self.planetNode = aPlanetNode
        }
        if let path = path {
            self.addChildNode(path)
            // Normalize to Earth's rotation. Once earth year is 365 seconds
            self.rotate(duration: planet.orbitPeriod * 365)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addMoon(_ moon: SCNNode) {
        guard let planet = planetNode else {
            print("there is no planet")
            return
        }
        planet.addChildNode(moon)
        moon.rotate(duration: 2, clockwise: false)
    }
    
    func addRings() {
        guard let planet = planetNode else {
            print("there is no planet")
            return
        }
        let torus = SCNTorus(ringRadius: 2.0, pipeRadius: 0.3)
        let torusNode = SCNNode(geometry: torus)
        torusNode.scale = SCNVector3Make(1, 0.1, 1)
        planet.addChildNode(torusNode)
    }
}
