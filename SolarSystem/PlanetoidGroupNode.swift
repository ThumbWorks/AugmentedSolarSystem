//
//  PlanetoidGroupNode.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 7/12/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import SceneKit
import SwiftAA

struct SolarSystemNodes {
    let lightNodes: [SCNNode]
    let planetoids: [Planet:PlanetoidGroupNode]
    
    func addAllNodesAsChild(to node: SCNNode) {
        for planetNode in planetoids {
            node.addChildNode(planetNode.value)
        }
        for light in lightNodes {
            node.addChildNode(light)
        }
    }
    
    func updatePostions(to date: Date) {
        _ = planetoids.map { (planet, groupNode) in
            if let type = planet.type {
                let day = JulianDay(date)
                let planetAA = type.init(julianDay: day)
                groupNode.updatePlanetLocation(planetAA.position())
            }
        }
    }
    
    func showingPaths() -> Bool {
        if let anyNode = planetoids.first?.value.path {
            return anyNode.isHidden
        }
        return false
    }
    
    func toggleOrbitPaths(to isHidden: Bool) {
        for (_, planetoidNode) in planetoids {
            // do something with the orbit path
            planetoidNode.path?.isHidden = isHidden
        }
    }
    
    func scaleOrbit(scalingUp: Bool) {
        // Figure out the current orbit of mercury. Scale the rest based on that.
        // So mercury doesn't really move from where it is, everything else does.
        guard let merc = planetoids[Planet.mercury]?.planetNode else {return}
        
        // retain the current mercury position
        let mercuryARRadius = CGFloat(merc.position.x)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = scalingUp ? 5 : 1
        
        var counter: CGFloat = 0
        for planet in Planet.allPlanets {
            // don't scale mercury or sun
            if counter < 2 {
                counter = counter + 1
                continue
            }
            let node = planetoids[planet]
            guard let planetNode = node?.planetNode else {
                print("we have no planet node")
                return
            }
            
            // We really only want to change the radius of the planet's orbit, so the torus and
            // the x position of the planet are the only 2 things that need to change. They will
            // both be the same value
            var radius: CGFloat = 0
            if scalingUp {
                radius = mercuryARRadius * planet.orbitalRadius / Planet.mercury.orbitalRadius
            } else {
                radius = mercuryARRadius * counter
            }
            var position = planetNode.position
            position.x = Float(radius)
            node?.torus?.ringRadius = radius
            planetNode.position = position
            counter = counter + 1
        }
        SCNTransaction.commit()
    }
    
    func scaleNodes(scaleUp: Bool) {
        // determine size of sun
        // if scaling down, make everything the size of the sun
        // if scaling up, do the math to figure out what size everything should be
        guard let currentScale = planetoids[Planet.sun]?.planetNode?.scale.x else {return}
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = scaleUp ? 5 : 1
        for (planet,node) in planetoids {
            // update the scale here
            guard let planetNode = node.planetNode else {
                print("we have no planet node")
                return
            }
            var scale: Float = 0
            if scaleUp {
                scale = planet.radius / Planet.sun.radius * currentScale
            } else {
                scale = currentScale
            }
            planetNode.scale = SCNVector3Make(scale, scale, scale)
        }
        SCNTransaction.commit()
    }
    
    /*!
     @method scale:nodes:plutoTableRadius:
     @abstract Scales the set of Planet:PlanetoidGroupNode objects based on the desired radius of pluto
     @param nodes the set of nodes to scale
     @param plutoTableRadius the desired radius of the node set
     */
    func scalePlanets(to plutoRadius: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        let orbitalDelta = plutoRadius / 8
        var currentRadius: Float = 0
        let planetSize = orbitalDelta / 4 /*A fraction of the delta gives us some space (har)*/
        for planet in Planet.allPlanets {
            
            guard let groupNode = planetoids[planet] else {
                continue
            }
            groupNode.planetNode?.scale = SCNVector3Make(planetSize, planetSize, planetSize)
            groupNode.torus?.ringRadius = CGFloat(currentRadius)
            groupNode.planetNode?.position = SCNVector3Make(currentRadius, 0, 0)
            currentRadius = currentRadius + orbitalDelta
        }
        SCNTransaction.commit()
    }
    
//    func updateSpeed(_ value: Double) {
//        _ = planetoids.map { (planet, node) in
//            print("change speed \(planet.name)")
//            if let planetNode = node.planetNode {
//                node.beginRotation(planet: planet, node: planetNode, multiplier: value)
//            }
//            node.beginOrbit(planet: planet, multiplier: value)
//        }
//    }
    
    func updateLookat(selected planet: Planet, arrowNode: SCNNode) {
        for (solarSystemPlanet, planetoidGroup) in planetoids {
            if planet == solarSystemPlanet {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                let lookat = SCNLookAtConstraint(target: planetoidGroup.planetNode)
                arrowNode.constraints = [lookat]
                SCNTransaction.commit()
            }
        }        
    }
    
    func removeAllNodesFromParent() {
        for planetNode in planetoids {
            planetNode.value.removeFromParentNode()
        }
        
        for light in lightNodes {
            light.removeFromParentNode()
        }
    }
}

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
        
//        let label = SCNText(string: planet.name, extrusionDepth: 1)
//        textNode = SCNNode(geometry: label)

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
            beginRotation(planet: planet, node: aPlanetNode, multiplier: 1)
            self.planetNode = aPlanetNode
        }
        if let path = path {
            self.addChildNode(path)
//            beginOrbit(planet: planet, multiplier: 1)
        }
    }
    
    func updatePlanetLocation(_ celestialLongitude: Float) {
        print("longitude \(celestialLongitude)")
        self.rotation = SCNVector4Make(0, 1, 0, celestialLongitude * Float.pi / 180)
    }
    
//    func beginOrbit(planet: Planet, multiplier: Double) {
//        // cleanup just in case
//        removeAction(forKey: "orbit")
//
//        // Normalize to Earth's rotation. Once earth year is 365 seconds
//        let action = SCNAction.createRotateAction(duration: planet.orbitPeriod * 365 / multiplier)
//        runAction(action, forKey: "orbit")
//    }
    
    func beginRotation(planet: Planet, node: SCNNode, multiplier: Double) {
        // cleanup just in case
        node.removeAction(forKey: "rotation")
        
        // Normalize to Earth's rotation (earth is now 1 second)
        let normalizedRotationDuration = planet.rotationDuration / Planet.earth.rotationDuration / multiplier
        let action = SCNAction.createRotateAction(duration: normalizedRotationDuration)
        node.runAction(action, forKey: "rotation")
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
        let action = SCNAction.createRotateAction(duration: 5, clockwise: false)
        moon.runAction(action)
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
