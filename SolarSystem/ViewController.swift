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
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("These are updated")
        for anchor in anchors {
            print("updated anchors \(anchor)")
        }
        print("that is the end of the updates")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            print("did add node, pushed to main queue")
            if self.done {
                return
            }
            
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.done = true
                let pos = SCNVector3.positionFromTransform(anchor.transform)
                print("NEW SURFACE DETECTED AT \(pos.friendlyString())")
                print("The box of the plane is before scaling is \(planeAnchor.extent)")
                
                let fadedYellow = UIColor.yellow//.withAlphaComponent(0.5)
                let sunGeometry = SCNGeometry.planetoid(radius: 0.04, color: fadedYellow)
                let sunNode = SCNNode(geometry: sunGeometry)
                node.addChildNode(sunNode)
                sunNode.categoryBitMask = 2
                
                // Add some omni lights to light up the sun
                node.addChildNode(SCNNode.omniLight(SCNVector3Make(1, 1, 1)))
                node.addChildNode(SCNNode.omniLight(SCNVector3Make(-1, -1, -1)))
                
                node.addChildNode(SCNNode.sunLight(geometry: sunGeometry))
                
                let mercury = SCNNode.planetGroup(orbitRadius: 0.1,
                                                  planetRadius: 0.005,
                                                  planetColor: .red)
                
                let venus = SCNNode.planetGroup(orbitRadius: 0.3,
                                                planetRadius: 0.01,
                                                planetColor: .yellow)
                
                let earth = SCNNode.earthGroup(orbitRadius: 0.6)
                
                let mars = SCNNode.planetGroup(orbitRadius: 1,
                                               planetRadius: 0.01,
                                               planetColor: .red)
                
                let jupiter = SCNNode.planetGroup(orbitRadius: 3,
                                                  planetRadius: 0.1,
                                                  planetColor: .red)
                
                let saturn = SCNNode.planetGroup(orbitRadius: 6,
                                                 planetRadius: 0.12,
                                                 planetColor: .orange)
                
                let uranus = SCNNode.planetGroup(orbitRadius: 11,
                                                 planetRadius: 0.12,
                                                 planetColor: .blue)
                
                let neptune = SCNNode.planetGroup(orbitRadius: 18,
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
                
                mercury.rotate(duration: 5)
                venus.rotate(duration: 10)
                earth.rotate(duration: 15)
                mars.rotate(duration: 30)
                jupiter.rotate(duration: 45)
                saturn.rotate(duration: 60)
                uranus.rotate(duration: 100)
                neptune.rotate(duration: 140)
            }
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("did add anchor")
    }
}
