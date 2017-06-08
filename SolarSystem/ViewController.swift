//
//  ViewController.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 6/7/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var done = false
    let earthScene = SCNScene(named: "art.scnassets/Earth.scn")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = SCNScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        print("error \(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        print("interruppted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        print("interuption ended")
    }
}

extension ViewController: ARSessionDelegate {
    func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("These are updated")
        for anchor in anchors {
            print("updated anchors \(anchor)")
        }
        print("that is the end of the updates")
    }
    
    func omniLightNode(_ vector: SCNVector3) -> SCNNode {
        let omniLight = SCNLight()
        omniLight.type = .omni
        omniLight.color = UIColor.white
        omniLight.categoryBitMask = 2
        let omniNode = SCNNode()
        omniNode.position = vector
        omniNode.light = omniLight
        return omniNode
    }
    
    func sunLightNode(geometry: SCNGeometry) -> SCNNode {
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
        //                let lightGeo = self.planetoidGeometry(radius: 0.02, color: .red)
        //                lightNode.geometry = lightGeo
        lightNode.light = sunLight
        return lightNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            print("did add node, pushed to main queue")
            if self.done {
                return
            }
            
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.done = true
                let pos = self.positionFromTransform(anchor.transform)
                print("NEW SURFACE DETECTED AT \(pos.friendlyString())")
                print("The box of the plane is before scaling is \(planeAnchor.extent)")
                
                let fadedYellow = UIColor.yellow//.withAlphaComponent(0.5)
                let sunGeometry = self.planetoidGeometry(radius: 0.04, color: fadedYellow)
                let sunNode = SCNNode(geometry: sunGeometry)
                node.addChildNode(sunNode)
                sunNode.categoryBitMask = 2
                
                // Add some omni lights to light up the sun
                node.addChildNode(self.omniLightNode(SCNVector3Make(1, 1, 1)))
                node.addChildNode(self.omniLightNode(SCNVector3Make(-1, -1, -1)))
                
                node.addChildNode(self.sunLightNode(geometry: sunGeometry))
                
                let mercury = self.planetGroup(orbitRadius: 0.1,
                                            planetRadius: 0.005,
                                            planetColor: .red)
                
                let venus = self.planetGroup(orbitRadius: 0.3,
                                                        planetRadius: 0.01,
                                                        planetColor: .yellow)
                
                let earth = self.earthGroup(orbitRadius: 0.6)
                
                let mars = self.planetGroup(orbitRadius: 1,
                                             planetRadius: 0.01,
                                             planetColor: .red)
                
                let jupiter = self.planetGroup(orbitRadius: 3,
                                            planetRadius: 0.1,
                                            planetColor: .red)
                
                let saturn = self.planetGroup(orbitRadius: 6,
                                               planetRadius: 0.12,
                                               planetColor: .orange)
                
                let uranus = self.planetGroup(orbitRadius: 11,
                                              planetRadius: 0.12,
                                              planetColor: .blue)
                
                let neptune = self.planetGroup(orbitRadius: 18,
                                              planetRadius: 0.12,
                                              planetColor: .purple)
                node.addChildNode(earth)
                node.addChildNode(venus)
                node.addChildNode(mercury)
                node.addChildNode(mars)
                node.addChildNode(jupiter)
                node.addChildNode(saturn)
                node.addChildNode(uranus)
                node.addChildNode(neptune)
                
                self.rotate(node: mercury, duration: 5)
                self.rotate(node: venus, duration: 10)
                self.rotate(node: earth, duration: 15)
                self.rotate(node: mars, duration: 30)
                self.rotate(node: jupiter, duration: 45)
                self.rotate(node: saturn, duration: 60)
                self.rotate(node: uranus, duration: 100)
                self.rotate(node: neptune, duration: 140)
            }
        }
    }
    
    func earthGroup(orbitRadius: CGFloat) -> SCNNode {
        let rotationSphere = self.planetoidGeometry(radius: orbitRadius, color: .clear)
        let rotationNode = SCNNode(geometry: rotationSphere)
        
        if let node = earthScene.rootNode.childNodes.first {
            let geometry = node.geometry
            let planet = SCNNode(geometry: geometry)
            planet.position = SCNVector3Make(Float(orbitRadius), 0, 0)
            planet.scale = SCNVector3Make(0.05, 0.05, 0.05)
            planet.categoryBitMask = 1
            rotationNode.addChildNode(planet)
//            let moon = self.planetGroup(orbitRadius: orbitRadius * 1.1,
//                                        planetRadius: 0.01,
//                                        planetColor: .gray)
//            planet.addChildNode(moon)
//            rotate(node: moon, duration: 1)
            
            rotate(node: planet, duration: 1)
        }
        return rotationNode
    }
    
    // Creates a planet that has the ability to orbit around a central point
    func planetGroup(orbitRadius: CGFloat, planetRadius: CGFloat, planetColor: UIColor) -> SCNNode {
        let rotationSphere = self.planetoidGeometry(radius: orbitRadius, color: .clear)
        let rotationNode = SCNNode(geometry: rotationSphere)
        
        let geometry  = self.planetoidGeometry(radius: planetRadius, color: planetColor)
        let planet = SCNNode(geometry: geometry)
        planet.categoryBitMask = 1
        planet.position = SCNVector3Make(Float(orbitRadius), 0, 0)
        rotationNode.addChildNode(planet)
        return rotationNode
    }
    
    func rotate(node: SCNNode, duration: CFTimeInterval) {
        
        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi, z: 0, duration: duration)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        node.runAction(moveLoop)
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("did add anchor")
    }
}

extension ViewController {
    func planetoidGeometry(radius: CGFloat, color: UIColor) -> SCNGeometry {
        let theColor = SCNMaterial()
        theColor.diffuse.contents = color// UIImage.init(named: "icon.png")
        
        // Now create the geometry and set the colors
        let geometry = SCNSphere(radius: radius)
        geometry.materials = [theColor]
        return geometry
    }
}
