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

class PlanetoidNode: SCNNode {
    let path: SCNTorus
    var planetNode: SCNNode?
    
    required init(scene: SCNScene, orbitalRadius: CGFloat, rotationDuration: CFTimeInterval) {
        
        path = SCNTorus(ringRadius: orbitalRadius, pipeRadius: 0.001)
        super.init()
        
        if let node = scene.rootNode.childNodes.first {
            let geometry = node.geometry
            
            // TODO look into if I can just use the node that we know we have for this
            let aPlanetNode = SCNNode(geometry: geometry)
            aPlanetNode.scale = SCNVector3Make(0.05, 0.05, 0.05)
            aPlanetNode.position = SCNVector3Make(Float(orbitalRadius), 0, 0)
            aPlanetNode.categoryBitMask = 1
            self.addChildNode(aPlanetNode)
            aPlanetNode.rotate(duration: rotationDuration)
            self.planetNode = aPlanetNode
        }
        
        self.addChildNode(SCNNode(geometry: path))
        self.rotate(duration: rotationDuration)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addRings() {
        guard let planet = planetNode else {
            print("there is no planet")
            return
        }
        let torus = SCNTorus(ringRadius: 0.1, pipeRadius: 0.01)
        //        torus.materials.first?.diffuse = UIColor.red
        let torusNode = SCNNode(geometry: torus)
        torusNode.scale = SCNVector3Make(1, 0.1, 1)
        planet.addChildNode(torusNode)
    }
}

extension SCNNode {
    
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
//            node.scale = SCNVector3Make(0.01, 0.01, 0.01)
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
    
    class func planet(_ planet: Planet) -> PlanetoidNode {
        let planetScene = SCNScene(named: planet.sceneString)!
        let planetoidNode = PlanetoidNode(scene: planetScene,
                                          orbitalRadius: planet.orbitalRadius,
                                          rotationDuration: planet.rotationDuration)
        return planetoidNode
    }
    
    class func earthGroup() -> SCNNode {
        // TODO this can be cleaned up a bit more
        let earth = Planet(sceneString: "art.scnassets/Earth.scn", orbitalRadius: 0.4, radius: 0.005, rotationDuration: 7)
        let rotationSphere = SCNGeometry.planetoid(radius: earth.orbitalRadius, color: .clear)
        let rotationNode = SCNNode(geometry: rotationSphere)
        guard let earthScene = SCNScene(named: earth.sceneString) else {
            print("no earth scene")
            return rotationNode
        }
        rotationNode.rotate(duration: earth.rotationDuration)
        
        if let node = earthScene.rootNode.childNodes.first {
            let geometry = node.geometry
            let planet = SCNNode(geometry: geometry)
            planet.scale = SCNVector3Make(0.05, 0.05, 0.05)
            planet.position = SCNVector3Make(Float(earth.orbitalRadius), 0, 0)
            planet.categoryBitMask = 1
            rotationNode.addChildNode(planet)
            let moon = self.planetGroup(orbitRadius: 0.1,
                                        planetRadius: 0.08,
                                        planetColor: .gray)
            planet.addChildNode(moon)
            moon.rotate(duration: 12, clockwise: false)
//            planet.rotate(duration: earth.rotationDuration)
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
