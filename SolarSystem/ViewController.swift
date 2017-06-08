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

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var done = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
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
}
extension ViewController: ARSessionObserver {
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("error \(error.localizedDescription)")
    }
    
    /**
     This is called when the camera's tracking state has changed.
     
     @param session The session being run.
     @param camera The camera that changed tracking states.
     */
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("camera did change tracking state \(camera.trackingState)")
    }
    
    /**
     This is called when a session is interrupted.
     
     @discussion A session will be interrupted and no longer able to track when
     it fails to receive required sensor data. This happens when video capture is interrupted,
     for example when the application is sent to the background or when there are
     multiple foreground applications (see AVCaptureSessionInterruptionReason).
     No additional frame updates will be delivered until the interruption has ended.
     @param session The session that was interrupted.
     */
    func sessionWasInterrupted(_ session: ARSession) {
        print("session interupted")
    }
    
    /**
     This is called when a session interruption has ended.
     
     @discussion A session will continue running from the last known state once
     the interruption has ended. If the device has moved, anchors will be misaligned.
     To avoid this, some applications may want to reset tracking (see ARSessionRunOptions).
     @param session The session that was interrupted.
     */
    func sessionInterruptionEnded(_ session: ARSession) {
        print("Session interruption ended")
    }
    
}

extension ViewController: ARSCNViewDelegate {
    /**
     Implement this to provide a custom node for the given anchor.
     
     @discussion This node will automatically be added to the scene graph.
     If this method is not implemented, a node will be automatically created.
     If nil is returned the anchor will be ignored.
     @param renderer The renderer that will render the scene.
     @param anchor The added anchor.
     @return Node that will be mapped to the anchor or nil.
     */
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//
//    }
    
    fileprivate func buildSolarSystem(_ planeAnchor: ARPlaneAnchor, node: SCNNode) {
        self.done = true
        let pos = SCNVector3.positionFromTransform(planeAnchor.transform)
        print("NEW SURFACE DETECTED AT \(pos.friendlyString())")
        print("The box of the plane is before scaling is \(planeAnchor.extent)")
        
        let sunGeometry = SCNGeometry.planetoid(radius: 0.04, color: .yellow)
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
    
    /**
     Called when a new node has been mapped to the given anchor.
     
     @param renderer The renderer that will render the scene.
     @param node The node that maps to the anchor.
     @param anchor The added anchor.
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            print("did add node, pushed to main queue")
            if self.done {
                return
            }
            
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.buildSolarSystem(planeAnchor, node: node)
            }
        }
    }
    
    /**
     Called when a node will be updated with data from the given anchor.
     
     @param renderer The renderer that will render the scene.
     @param node The node that will be updated.
     @param anchor The anchor that was updated.
     */
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        print("will update node \(node) for anchor \(anchor)")
    }
    
    /**
     Called when a node has been updated with data from the given anchor.
     
     @param renderer The renderer that will render the scene.
     @param node The node that was updated.
     @param anchor The anchor that was updated.
     */
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        print("did update node \(node) for anchor \(anchor)")
    }
    
    /**
     Called when a mapped node has been removed from the scene graph for the given anchor.
     
     @param renderer The renderer that will render the scene.
     @param node The node that was removed.
     @param anchor The anchor that was removed.
     */
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("didRemove. node \(node) for anchor \(anchor)")
    }
}
extension ViewController: ARSessionDelegate {
    
    /**
     This is called when new anchors are added to the session.
     
     @param session The session being run.
     @param anchors An array of added anchors.
     */
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("did add anchor")
    }
    
    /**
     This is called when anchors are updated.
     
     @param session The session being run.
     @param anchors An array of updated anchors.
     */
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("These are updated")
        for anchor in anchors {
            print("updated anchors \(anchor)")
        }
        print("that is the end of the updates")
    }
    
    // This is much to noisy to actually do anything with it every time for now
    /**
     This is called when a new frame has been updated.
     
     @param session The session being run.
     @param frame The frame that has been updated.
     */
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        print("The frame has been updated")
//    }
    
    /**
     This is called when anchors are removed from the session.
     
     @param session The session being run.
     @param anchors An array of removed anchors.
     */
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("An anchor has been removed")
    }
    
}
