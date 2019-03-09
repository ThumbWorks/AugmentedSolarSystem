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
    var moon = SCNNode()

    func placeSolarSystem(on node: SCNNode, at position: SCNVector3) {
        guard let sun = planetoids[Planet.sun] else {return}
        sun.position = position
        addAllNodesAsChild(to: node, position: position)
    }
    
    func addAllNodesAsChild(to node: SCNNode, position: SCNVector3? = nil) {
        for planetNode in planetoids {
            if let position = position {
                planetNode.value.position = position
            }
            node.addChildNode(planetNode.value)
        }
        for light in lightNodes {
            if let position = position {
                light.position = position
            }
            node.addChildNode(light)
        }
    }
    
    func updatePostions(to date: Date) {
        
        // update the planet positions
        let day = JulianDay(date)
        _ = planetoids.map { (planet, groupNode) in
            if let type = planet.type {
                let planetAA = type.init(julianDay: day)
                groupNode.updatePlanetLocation(planetAA.position())
            }
        }
        // TODO add the moons back in (again)

//        let moonAA = Moon(julianDay: day)
//
//        let coords = moonAA.apparentEclipticCoordinates
//        let lat = Float(coords.celestialLatitude.magnitude)
//        let lon = Float(coords.celestialLongitude.magnitude)
//        print("lat \(lat) lon \(lon)")
//        moon.eulerAngles = SCNVector3Make(lat, lon, 0)
//        moon.rotation = SCNVector4Make(0, 1, 0, lon)
//        moon.rotation = SCNVector4Make(1, 0, 0, lat)
    }
    
    func showingPaths() -> Bool {
        if let anyNode = planetoids.first?.value.path {
            return anyNode.isHidden
        }
        return false
    }
    
    func toggleOrbitPaths(hidden: Bool) {
        for (_, planetoidNode) in planetoids {
            // do something with the orbit path
            planetoidNode.path?.isHidden = hidden
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
            torus?.name = "torus for \(planet.name)"
            path = SCNNode(geometry: torus)
            path?.name = "path for \(planet.name)"
        } else {
            path = nil
            torus = nil
        }
        
        super.init()
        
        if let aPlanetNode = scene.rootNode.childNodes.first {

            aPlanetNode.scale = SCNVector3Make(0.05, 0.05, 0.05)
            aPlanetNode.position = SCNVector3Make(Float(planet.displayOrbitalRadius), 0, 0)
            aPlanetNode.name = planet.name
            self.addChildNode(aPlanetNode)
            let radianTilt = planet.axialTilt / 360 * 2*Float.pi
            aPlanetNode.rotation = SCNVector4Make(0, 0, 1, radianTilt)
            beginRotation(planet: planet, node: aPlanetNode, multiplier: 1)
            self.planetNode = aPlanetNode
        }
        if let path = path {
            self.addChildNode(path)
        }
    }
    
    func updatePlanetLocation(_ coords: EclipticCoordinates) {
        let longitude = coords.celestialLongitude.magnitude.value
        let longitudeInRadians = longitude * Double.pi / 180
        self.rotation = SCNVector4Make(0, 1, 0, Float(longitudeInRadians))
    }
    
    func beginRotation(planet: Planet, node: SCNNode, multiplier: Double) {
        // cleanup just in case
        node.removeAction(forKey: "rotation")
        
        // Normalize to Earth's rotation (earth is now 1 second)
        let normalizedRotationDuration = planet.rotationDuration / Planet.earth.rotationDuration / multiplier
        let action = SCNAction.createSpinAction(duration: normalizedRotationDuration)
        node.runAction(action, forKey: "rotation")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
