//
//  NodeExtension.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 6/8/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import SceneKit

extension SCNGeometry {
    class func planetoid(radius: CGFloat, color: UIColor) -> SCNGeometry {
        let theColor = SCNMaterial()
        theColor.diffuse.contents = color
        
        // Now create the geometry and set the colors
        let geometry = SCNSphere(radius: radius)
        geometry.materials = [theColor]
        return geometry
    }
}

extension Planet: Hashable {
    var hashValue: Int {
        return name.hash
    }
}

struct Planet: Equatable {
    static func ==(lhs: Planet, rhs: Planet) -> Bool {
        return lhs.name == rhs.name &&
            lhs.orbitalRadius == rhs.orbitalRadius &&
            lhs.displayOrbitalRadius == rhs.displayOrbitalRadius &&
            lhs.radius == rhs.radius &&
            lhs.rotationDuration == rhs.rotationDuration &&
            lhs.axialTilt == rhs.axialTilt &&
            lhs.orbitPeriod == rhs.orbitPeriod
    }
    
    let name: String
    
    // Distance from the sun in millions of km
    // Source: http://www.enchantedlearning.com/subjects/astronomy/planets/
    let orbitalRadius: CGFloat
    let displayOrbitalRadius: CGFloat
    
    // In KM: eg. Earth 6371.0
    // Source: https://en.wikipedia.org/wiki/List_of_Solar_System_objects_by_size
    let radius: Float
    
    // In hours: eg. Earth 23.93, Mercury 1407.6
    // Source: https://en.m.wikipedia.org/wiki/Axial_tilt#Solar_System_bodies
    let rotationDuration: Double
    
    // Tilt on the poles in degrees: eg. Earth 23.44
    // Source: https://en.m.wikipedia.org/wiki/Axial_tilt#Solar_System_bodies
    let axialTilt: Float
    
    // Duration to circle the sun in earth years
    // Source: https://en.wikipedia.org/wiki/Orbital_period#Examples_of_sidereal_and_synodic_periods
    let orbitPeriod: Double
}

class PlanetoidGroupNode: SCNNode {
    let path: SCNNode?
    var planetNode: SCNNode?
    required init(planet: Planet) {
        
        let sceneString = "art.scnassets/\(planet.name).scn"
        let scene = SCNScene(named: sceneString)!
        
        if planet.orbitalRadius > 0 {
            let torus = SCNTorus(ringRadius: planet.displayOrbitalRadius, pipeRadius: 0.001)
            path = SCNNode(geometry: torus)
        } else {
            path = nil
            
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
            let normalizedRotationDuration = planet.rotationDuration / 23.93
            aPlanetNode.rotate(duration: normalizedRotationDuration)
            self.planetNode = aPlanetNode
        }
        if let path = path {
            self.addChildNode(path)
            // Normalize to Earth's rotation. Once year is 10 seconds
            self.rotate(duration: planet.orbitPeriod * 10)
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

extension SCNNode {
    
    func buildSolarSystem() -> ([Planet:PlanetoidGroupNode], SCNNode) {
        var nodes = [Planet:PlanetoidGroupNode]()
        // TODO the sun is now Jupiter sized, need to look this up
        let sun = Planet(name: "Sun", orbitalRadius: 0, displayOrbitalRadius: 0, radius: 69911, rotationDuration: 1, axialTilt: 1, orbitPeriod: 1)
        let mercury = Planet(name: "Mercury", orbitalRadius: 57.9, displayOrbitalRadius: 0.2, radius: 2439.7, rotationDuration: 1407.6, axialTilt: 0.03, orbitPeriod: 0.240846)
        let venus = Planet(name: "Venus", orbitalRadius: 108.2, displayOrbitalRadius: 0.3, radius: 6051.8, rotationDuration: 5832.6, axialTilt: 2.64, orbitPeriod: 0.615)
        let earth = Planet(name: "Earth", orbitalRadius: 149.6, displayOrbitalRadius: 0.4, radius: 6371, rotationDuration: 23.93, axialTilt: 23.44, orbitPeriod: 1)
        let mars = Planet(name: "Mars", orbitalRadius: 227.9, displayOrbitalRadius: 0.5, radius: 3389.5, rotationDuration: 24.62, axialTilt: 25.19, orbitPeriod: 1.881)
        let jupiter = Planet(name: "Jupiter", orbitalRadius: 778.3, displayOrbitalRadius: 0.8, radius: 69911, rotationDuration: 9.93, axialTilt: 3.13, orbitPeriod: 11.86)
        let saturn = Planet(name: "Saturn", orbitalRadius: 1427, displayOrbitalRadius: 1.0, radius: 58232, rotationDuration: 10.66, axialTilt: 26.73, orbitPeriod: 29.46)
        let uranus = Planet(name: "Uranus", orbitalRadius: 2871, displayOrbitalRadius: 1.5, radius: 25362, rotationDuration: 17.24, axialTilt: 82.23, orbitPeriod: 84.01)
        let neptune = Planet(name: "Neptune", orbitalRadius: 4497, displayOrbitalRadius: 1.7, radius: 24622, rotationDuration: 16.11, axialTilt: 28.32, orbitPeriod: 164.8)
        let pluto = Planet(name: "Pluto", orbitalRadius: 5913, displayOrbitalRadius: 2.0, radius: 1186, rotationDuration: 153.29, axialTilt: 57.47, orbitPeriod: 248.1)
        
        // Data on sizes of planets http://www.freemars.org/jeff/planets/planets5.htm
        
        let sunNode = PlanetoidGroupNode(planet:sun)
        sunNode.planetNode?.categoryBitMask = 2
        nodes[sun] = sunNode
        
        // Add the light from the sun
        nodes[mercury] = PlanetoidGroupNode(planet: mercury)
        nodes[venus] = PlanetoidGroupNode(planet: venus)
        
        let earthNode = PlanetoidGroupNode(planet: earth)
        let moon = SCNNode.planetGroup(orbitRadius: 2,
                                       planetRadius: 0.09,
                                       planetColor: .gray)
        earthNode.addMoon(moon)
        nodes[earth] = earthNode
        
        nodes[mars] = PlanetoidGroupNode(planet: mars)
        
        // Jupiter has a moon
        let jupiterNode = PlanetoidGroupNode(planet: jupiter)
        let jupiterMoon = SCNNode.planetGroup(orbitRadius: 3,
                                       planetRadius: 0.2,
                                       planetColor: .gray)
        jupiterNode.addMoon(jupiterMoon)
        nodes[jupiter] = jupiterNode
        
        // Saturn has rings
        let saturnNode = PlanetoidGroupNode(planet: saturn)
        saturnNode.addRings()
        nodes[saturn] = saturnNode
        
        nodes[uranus] = PlanetoidGroupNode(planet: uranus)
        nodes[neptune] = PlanetoidGroupNode(planet: neptune)
        nodes[pluto] = PlanetoidGroupNode(planet: pluto)
        
        let light = SCNNode.sunLight(geometry: sunNode.planetNode!.geometry!)

        return (nodes, light)
    }
    
    // Creates a planet that has the ability to orbit around a central point
    class func planetGroup(orbitRadius: CGFloat, planetRadius: CGFloat, planetColor: UIColor, position: SCNVector3? = nil) -> SCNNode {
        let rotationSphere = SCNGeometry.planetoid(radius: orbitRadius, color: .clear)
        let rotationNode = SCNNode(geometry: rotationSphere)
        let geometry  = SCNGeometry.planetoid(radius: planetRadius, color: planetColor)
        
        let planet = SCNNode(geometry: geometry)
        planet.categoryBitMask = 1
        if let position = position {
            planet.position = position
        } else {
            planet.position = SCNVector3Make(Float(orbitRadius), 0, 0)
        }
        rotationNode.addChildNode(planet)
        return rotationNode
    }
    
    func rotate(duration: CFTimeInterval, clockwise: Bool = true) {
        let rotationValue = clockwise ? CGFloat.pi : -CGFloat.pi
        let rotate = SCNAction.rotateBy(x: 0, y: rotationValue, z: 0, duration: duration)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        self.runAction(moveLoop)
    }
    
    class func sun() -> SCNNode {
                
        let sunScene = SCNScene(named: "art.scnassets/Sun.scn")!
        
        if let node = sunScene.rootNode.childNodes.first {
            let geometry = node.geometry
            node.scale = SCNVector3Make(0.01, 0.01, 0.01)
            let planet = SCNNode(geometry: geometry)
            // TODO think about the bit mask for the sun
            planet.categoryBitMask = 1
            planet.rotate(duration: 20)
            planet.scale = SCNVector3Make(0.05, 0.05, 0.05)
            return planet
        }
        let sunGeometry = SCNGeometry.planetoid(radius: 5, color: .yellow)
        let alternateSunNode = SCNNode(geometry: sunGeometry)
        return alternateSunNode
    }
    
    class func omniLight(_ vector: SCNVector3) -> SCNNode {
        let omniLight = SCNLight()
        omniLight.type = .omni
        omniLight.color = UIColor.white
        omniLight.categoryBitMask = 2
        let omniNode = SCNNode()
        omniNode.position = vector
        omniNode.light = omniLight
        return omniNode
    }
    
    class func sunLight(geometry: SCNGeometry) -> SCNNode {
        let sunLight = SCNLight()
        sunLight.type = .omni
        sunLight.color = UIColor.white
        sunLight.shadowColor = UIColor.black
        sunLight.categoryBitMask = 1
        
        let lightNode = SCNNode()
        let max = geometry.boundingBox.max
        let min = geometry.boundingBox.min
        let averageX = (max.x + min.x) / 2
        let averageY = (max.y + min.y) / 2
        let averageZ = (max.z + min.z) / 2
        lightNode.position = SCNVector3Make(averageX, averageY, averageZ)
        lightNode.light = sunLight
        return lightNode
    }
}
