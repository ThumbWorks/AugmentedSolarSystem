//
//  NodeExtension.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 6/8/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import SceneKit
import SwiftAA

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
     */
    var translation: float3 {
        let translation = columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

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

extension SCNVector3 {
    func distance(receiver: SCNVector3) -> Float {
        let xd = receiver.x - self.x
        let yd = receiver.y - self.y
        let zd = receiver.y - self.z
        let distance = abs(sqrt(xd*xd + yd*yd + zd * zd))
        return distance
    }
}

extension SCNAction {
    class func createARKitCalibrationAction(rotationValue: CGFloat) -> SCNAction {
        let duration = 0.5
        let rotateX = SCNAction.rotateBy(x: rotationValue, y: 0, z: 0, duration: duration)
        let rotateY = SCNAction.rotateBy(x: 0, y: rotationValue, z: 0, duration: duration)
        let rotateZ = SCNAction.rotateBy(x: 0, y: 0, z: rotationValue, duration: duration)

        let rotateNegativeX = SCNAction.rotateBy(x: -rotationValue, y: 0, z: 0, duration: duration)
        let rotateNegativeY = SCNAction.rotateBy(x: 0, y: -rotationValue, z: 0, duration: duration)
        let rotateNegativeZ = SCNAction.rotateBy(x: 0, y: 0, z: -rotationValue, duration: duration)
        
        let moveLeft = SCNAction.move(by: SCNVector3Make(-1, 0, 0), duration: duration * 2)
        let moveRight = SCNAction.move(by: SCNVector3Make(1, 0, 0), duration: duration * 2)

        let moveSequence = SCNAction.sequence([rotateNegativeX, moveLeft, rotateY, rotateZ, rotateNegativeY, moveRight, rotateNegativeZ, moveRight, rotateX, rotateNegativeZ, rotateNegativeX, moveLeft, rotateNegativeY, rotateZ, rotateY, rotateX])

        let loop = SCNAction.repeatForever(moveSequence)
        return loop
    }
    
    class func createRotateAction(duration: CFTimeInterval, clockwise: Bool = true) -> SCNAction {
        let rotationValue = clockwise ? CGFloat.pi : -CGFloat.pi
        let rotate = SCNAction.rotate(by: rotationValue, around: SCNVector3Make(0, 1, 0), duration: duration)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        return moveLoop
    }
    
    class func createSpinAction(duration: CFTimeInterval) -> SCNAction {
        let rotationValue = CGFloat.pi
        let rotate = SCNAction.rotateBy(x: 0, y: rotationValue, z: 0, duration: duration)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        return moveLoop
    }
}

extension SCNNode {
    
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
    
    // Creates a planet that has the ability to orbit around a central point
    class func moonGroup(orbitRadius: CGFloat, planetRadius: CGFloat, planetColor: UIColor, lat: Double, lon: Double) -> SCNNode {
        let rotationSphere = SCNGeometry.planetoid(radius: orbitRadius, color: .clear)
        let rotationNode = SCNNode(geometry: rotationSphere)
        let geometry  = SCNGeometry.planetoid(radius: planetRadius, color: planetColor)
        let moon = SCNNode(geometry: geometry)
        moon.categoryBitMask = 1
        moon.position = SCNVector3Make(Float(orbitRadius), 0, 0)
        rotationNode.addChildNode(moon)
        
//        let q = SCNQuaternion.init(0, lat, lon, 1)
//        rotationNode.rotate(by: q, aroundTarget: SCNVector3Zero)
        return rotationNode
    }
}
extension SwiftAA.Object {
    func position() -> EclipticCoordinates {
        if let planet = self as? SwiftAA.Planet {
            return planet.heliocentricEclipticCoordinates
        } else if let earth = self as? SwiftAA.Earth {
            return earth.heliocentricEclipticCoordinates
        }
        return SwiftAA.EclipticCoordinates(celestialLongitude: 0, celestialLatitude: 0)
    }
}

extension Planet {
    
    static func buildSolarSystem() -> SolarSystemNodes {
        var nodes = [Planet:PlanetoidGroupNode]()

        
        // Data on sizes of planets http://www.freemars.org/jeff/planets/planets5.htm
        
        let sunNode = PlanetoidGroupNode(planet: Planet.sun)
        sunNode.planetNode?.categoryBitMask = 2
        nodes[Planet.sun] = sunNode
        
        // Add the light from the sun
        let light = SCNNode.sunLight(geometry: sunNode.planetNode!.geometry!)


        // Mercury
        let mercury = PlanetoidGroupNode(planet: Planet.mercury)
        mercury.updatePlanetLocation(mercuryAA.position())
        
        let venus = PlanetoidGroupNode(planet: Planet.venus)
        venus.updatePlanetLocation(venusAA.position())
        
//        return SolarSystemNodes(lightNodes: [light], planetoids: nodes)

        let earthNode = PlanetoidGroupNode(planet: Planet.earth)
        earthNode.updatePlanetLocation(earthAA.position())
        
//        let moonLat = moonAA.eclipticCoordinates.celestialLatitude.magnitude
//        let moonLong = moonAA.eclipticCoordinates.celestialLongitude.magnitude
        let moon = SCNNode.moonGroup(orbitRadius: 2,
                                     planetRadius: 0.09, //CGFloat(moonAA.radiusVector.km.magnitude),
                                     planetColor: .gray,
                                     lat: 0.0,
                                     lon: 0.0)
        
        let marsGroup = PlanetoidGroupNode(planet: Planet.mars)
        marsGroup.updatePlanetLocation(marsAA.position())
        
        let jupiterNode = PlanetoidGroupNode(planet: Planet.jupiter)
        // Jupiter has a moon
//        let europaLat = jupiterAA.Europa.EquatorialLatitude.magnitude
//        let europaLon = jupiterAA.Europa.TrueLongitude.magnitude
//        let jupiterMoon = SCNNode.moonGroup(orbitRadius: 3,
//                                            planetRadius: 0.2,
//                                            planetColor: .gray,
//                                            lat: europaLat,
//                                            lon: europaLon)
        jupiterNode.updatePlanetLocation(jupiterAA.position())

        // Saturn has rings
        let saturnNode = PlanetoidGroupNode(planet: Planet.saturn)
        saturnNode.updatePlanetLocation(saturnAA.position())
        
        let uranus = PlanetoidGroupNode(planet: Planet.uranus)
        uranus.updatePlanetLocation(uranusAA.position())
        
        let neptune = PlanetoidGroupNode(planet: Planet.neptune)
        neptune.updatePlanetLocation(neptuneAA.position())

        // Pluto lives matter
//        let pluto = PlanetoidGroupNode(planet: Planet.pluto)
//        pluto.updatePlanetLocation(plutoAA.position())

        nodes[Planet.mercury] = mercury
        nodes[Planet.venus] = venus
        nodes[Planet.earth] = earthNode
        nodes[Planet.mars] = marsGroup
        nodes[Planet.jupiter] = jupiterNode
        nodes[Planet.saturn] = saturnNode
        nodes[Planet.uranus] = uranus
        nodes[Planet.neptune] = neptune
//        nodes[Planet.pluto] = pluto

        return SolarSystemNodes(lightNodes: [light], planetoids: nodes, moon: moon)
    }
}
