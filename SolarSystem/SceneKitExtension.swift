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

class PlanetoidGroupNode: SCNNode {
    let orbitRadius: CGFloat
    let planetRadius: CGFloat
    let planetColor: UIColor
    var planetName: String?
    init(orbit: CGFloat, radius: CGFloat, color: UIColor) {
        orbitRadius = orbit
        planetRadius = radius
        planetColor = color
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SCNNode {
    
    // Creates a planet that has the ability to orbit around a central point
    class func planetGroup(orbitRadius: CGFloat, planetRadius: CGFloat, planetColor: UIColor, planetName: String? = nil) -> SCNNode {
        let rotationSphere = SCNGeometry.planetoid(radius: orbitRadius, color: .clear)
        let rotationNode = SCNNode(geometry: rotationSphere)
        let geometry  = SCNGeometry.planetoid(radius: planetRadius, color: planetColor)
        
        let planet = SCNNode(geometry: geometry)
        planet.categoryBitMask = 1
        planet.position = SCNVector3Make(Float(orbitRadius), 0, 0)
        rotationNode.addChildNode(planet)
        
        if let string = planetName {
            let text = SCNText(string: string, extrusionDepth: 0.1)
            let textNode = SCNNode(geometry: text)
            text.font = UIFont(name: "Helvetica", size: 1)
            
            let mat = SCNMaterial()
            mat.diffuse.contents = planetColor
            text.materials = [mat]
            
            textNode.scale = SCNVector3Make(0.05, 0.05, 0.05)
            textNode.position = SCNVector3Make(Float(orbitRadius), 0.01, 0)
            rotationNode.addChildNode(textNode)
        }
        return rotationNode
    }
    
    func rotate(duration: CFTimeInterval, clockwise: Bool = true) {
        let rotationValue = clockwise ? CGFloat.pi : -CGFloat.pi
        let rotate = SCNAction.rotateBy(x: 0, y: rotationValue, z: 0, duration: duration)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        self.runAction(moveLoop)
    }
    
    class func earthGroup(orbitRadius: CGFloat) -> SCNNode {
        let rotationSphere = SCNGeometry.planetoid(radius: orbitRadius, color: .clear)
        let rotationNode = SCNNode(geometry: rotationSphere)
        let earthScene = SCNScene(named: "art.scnassets/Earth.scn")!
        
        if let node = earthScene.rootNode.childNodes.first {
            let geometry = node.geometry
            let planet = SCNNode(geometry: geometry)
            planet.position = SCNVector3Make(Float(orbitRadius), 0, 0)
            planet.categoryBitMask = 1
            rotationNode.addChildNode(planet)
            let moon = self.planetGroup(orbitRadius: 0.1,
                                        planetRadius: 0.008,
                                        planetColor: .gray)
            planet.addChildNode(moon)
            moon.rotate(duration: 3, clockwise: false)
            planet.rotate(duration: 1)
        }
        return rotationNode
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
