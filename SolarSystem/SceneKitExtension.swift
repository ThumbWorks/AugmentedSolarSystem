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
    class func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
    
    class func planetoid(radius: CGFloat, color: UIColor) -> SCNGeometry {
        let theColor = SCNMaterial()
        theColor.diffuse.contents = color
        
        // Now create the geometry and set the colors
        let geometry = SCNSphere(radius: radius)
        geometry.materials = [theColor]
        return geometry
    }
}


class BorderedPlane: SCNNode {
    init(width: Float, height: Float, color: UIColor) {
        super.init()
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        categoryBitMask = 2
        let material = SCNMaterial()
        material.diffuse.contents = color.withAlphaComponent(0.4)
        plane.materials = [material]
        geometry = plane
        transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)

        
//        addBorder(materials: [borderMaterial])
    }
    
    func addBorder(materials: [SCNMaterial]) {
        let box = self.boundingBox
        let corner1 = box.min
        let corner2 = SCNVector3Make(box.max.x, box.min.y, box.min.z)
        let corner3 = box.max
        let corner4 = SCNVector3Make(box.min.x, box.max.y, box.max.z)
        print("The corners are \(corner1) \(corner2) \(corner3) \(corner4) ")
        for geometry in [SCNGeometry.lineFrom(vector: corner1, toVector: corner2),
                         SCNGeometry.lineFrom(vector: corner2, toVector: corner3),
                         SCNGeometry.lineFrom(vector: corner3, toVector: corner4),
                         SCNGeometry.lineFrom(vector: corner4, toVector: corner1)] {
                            geometry.materials = materials
                            self.addChildNode(SCNNode(geometry: geometry))
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension SCNNode {
    
    class func arrow() -> SCNNode {
        let arrowScene = SCNScene(named: "art.scnassets/arrow.dae")!
        let arrow = arrowScene.rootNode.childNodes.first!
        arrow.position = SCNVector3Make(0, 0, -0.1)
        arrow.scale = SCNVector3Make(0.0001, 0.0001, 0.0001)
        arrow.categoryBitMask = 4
        for light in arrow.childNodes {
            light.light?.categoryBitMask = 4
        }
        arrow.name = "Arrow"
        return arrow
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
    
    func rotate(duration: CFTimeInterval, clockwise: Bool = true) {
        let rotationValue = clockwise ? CGFloat.pi : -CGFloat.pi
        let rotate = SCNAction.rotateBy(x: 0, y: rotationValue, z: 0, duration: duration)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
            self.runAction(moveLoop)
        
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
}

extension Planet {
    
    static func buildSolarSystem() -> SolarSystemNodes {
        var nodes = [Planet:PlanetoidGroupNode]()

        // Data on sizes of planets http://www.freemars.org/jeff/planets/planets5.htm
        
        let sunNode = PlanetoidGroupNode(planet: Planet.sun)
        sunNode.planetNode?.categoryBitMask = 2
        nodes[Planet.sun] = sunNode
        let light = SCNNode.sunLight(geometry: sunNode.planetNode!.geometry!)

        // Add the light from the sun
        nodes[Planet.mercury] = PlanetoidGroupNode(planet: Planet.mercury)
        nodes[Planet.venus] = PlanetoidGroupNode(planet: Planet.venus)
//        return SolarSystemNodes(lightNodes: [light], planetoids: nodes)

        let earthNode = PlanetoidGroupNode(planet: Planet.earth)
        let moon = SCNNode.planetGroup(orbitRadius: 2,
                                       planetRadius: 0.09,
                                       planetColor: .gray)
        earthNode.addMoon(moon)
        nodes[Planet.earth] = earthNode
        
        nodes[Planet.mars] = PlanetoidGroupNode(planet: Planet.mars)
        
        // Jupiter has a moon
        let jupiterNode = PlanetoidGroupNode(planet: Planet.jupiter)
        let jupiterMoon = SCNNode.planetGroup(orbitRadius: 3,
                                       planetRadius: 0.2,
                                       planetColor: .gray)
        jupiterNode.addMoon(jupiterMoon)
        nodes[Planet.jupiter] = jupiterNode
        
        // Saturn has rings
        let saturnNode = PlanetoidGroupNode(planet: Planet.saturn)
        saturnNode.addRings()
        nodes[Planet.saturn] = saturnNode
        
        nodes[Planet.uranus] = PlanetoidGroupNode(planet: Planet.uranus)
        nodes[Planet.neptune] = PlanetoidGroupNode(planet: Planet.neptune)
        nodes[Planet.pluto] = PlanetoidGroupNode(planet: Planet.pluto)
        

        return SolarSystemNodes(lightNodes: [light], planetoids: nodes)
    }
}
