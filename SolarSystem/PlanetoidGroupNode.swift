//
//  PlanetoidGroupNode.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 7/12/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import SceneKit

struct SolarSystemNodes {
    let lightNodes: [SCNNode]
    let planetoids: [Planet:PlanetoidGroupNode]
}

class PlanetoidGroupNode: SCNNode {
    // The node that shows the orbital path which is used for hiding
    let path: SCNNode?
    
    // The geometry representing the orbital path which is used for scaling
    let torus: SCNTorus?
    let label: SCNText
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
        
        label = SCNText(string: planet.name, extrusionDepth: 1)
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
            let textNode = SCNNode(geometry: label)
            textNode.constraints = [SCNBillboardConstraint()]
            aPlanetNode.addChildNode(textNode)
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
    
    class func scaleOrbit(planetoids: [Planet:PlanetoidGroupNode], scalingUp: Bool) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5
        for (planet,node) in planetoids {
            
            guard let planetNode = node.planetNode else {
                print("we have no planet node")
                return
            }
            
            // We really only want to change the radius of the planet's orbit, so the torus and
            // the x position of the planet are the only 2 things that need to change. They will
            // both be the same value
            var radius: CGFloat = 0
            if scalingUp {
                radius = planet.orbitalRadius
            } else {
                radius = planet.displayOrbitalRadius
            }
            var position = planetNode.position
            position.x = Float(radius)
            node.torus?.ringRadius = radius
            planetNode.position = position
        }
        SCNTransaction.commit()
    }
    
    class func scaleNodes(nodes: [Planet:PlanetoidGroupNode], scaleUp: Bool) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5
        for (planet,node) in nodes {
            // update the scale here
            guard let planetNode = node.planetNode else {
                print("we have no planet node")
                return
            }
            var scale: Float = 0
            if scaleUp {
                scale = planet.radius / Planet.earth.radius / 20
            } else {
                scale = 0.05
            }
            planetNode.scale = SCNVector3Make(scale, scale, scale)
        }
        SCNTransaction.commit()
    }
    
}
