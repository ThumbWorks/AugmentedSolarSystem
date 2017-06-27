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
    
    @IBOutlet var status: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    var done = false
    var sessionConfig = ARWorldTrackingSessionConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Set the scene to the view
        sceneView.scene = SCNScene()
    }
    
    func restartPlaneDetection() {
        // configure session
        sessionConfig.planeDetection = .horizontal
        sceneView.session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        restartPlaneDetection()
        
        // Create a session configuration
        sessionConfig.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(sessionConfig)
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
        
        switch camera.trackingState {
        case .normal:
            status.text = "Tracking Normal"
        case .notAvailable:
            status.text = "Tracking unavailable"
        case .limited(let reason):
            status.text = "Tracking Limited: \(reason)"
        }
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
        session.pause()
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
        session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
        restartPlaneDetection()
        status.text = "Resetting Session"
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func setUpAsteroidBelt(centerNode: SCNNode, orbitalRadius: CGFloat) {
        // TODO set up the belt. Let's try the hard way
        let count = 360
        for i in 0...count {
            let position = SCNVector3Make(Float(orbitalRadius), Float(360 / count * i), 0)
            let asteroid = SCNNode.planetGroup(orbitRadius: orbitalRadius, planetRadius: 0.1, planetColor: .brown, position: position)
            asteroid.rotate(duration:30)
            centerNode.addChildNode(asteroid)
        }
    }
    
    fileprivate func buildSolarSystem(_ planeAnchor: ARPlaneAnchor, node: SCNNode) {
        self.done = true
        let pos = SCNVector3.positionFromTransform(planeAnchor.transform)
        print("NEW SURFACE DETECTED AT \(pos.friendlyString())")
        print("The box of the plane is before scaling is \(planeAnchor.extent)")
        
        // Data on sizes of planets http://www.freemars.org/jeff/planets/planets5.htm
        let actualMercuryRadius: CGFloat = 14878.0 / 2.0 // .005 / 14878*12104
        let mercuryARRadius: CGFloat = 0.005
        let venusRadius: CGFloat = mercuryARRadius / actualMercuryRadius * (12104 / 2)
        let marsRadius: CGFloat = mercuryARRadius / actualMercuryRadius * (6787 / 2)
//        let jupiterRadius: CGFloat = mercuryARRadius / actualMercuryRadius * (142800 / 2)
//        let saturnRadius: CGFloat = mercuryARRadius / actualMercuryRadius * (120000 / 2)
//        let uranusRadius: CGFloat = mercuryARRadius / actualMercuryRadius * (51200 / 2)
//        let neptuneRadius: CGFloat = mercuryARRadius / actualMercuryRadius * (48600 / 2)
        
        let mercuryOrbitalRadius: CGFloat = 0.2
        let venusOrbitalRadius: CGFloat = 0.3
        let earthOrbialRadius: CGFloat = 0.4
        let marsOrbitalRadius: CGFloat = 0.5
        let jupiterOribialRadius: CGFloat = 0.8
        let saturnOrbitalRadius: CGFloat = 1.0
        let uranusOrbitalRadius: CGFloat = 1.5
        let neptuneOrbitalRadius: CGFloat = 1.7
        let plutoOrbitalRadius: CGFloat = 2.0
        
        let sunNode = SCNNode.sun()
        node.addChildNode(sunNode)
        sunNode.categoryBitMask = 2
        
        // Add the light from the sun
        node.addChildNode(SCNNode.sunLight(geometry: sunNode.geometry!))
        let mercury = SCNNode.genericPlanetGroup(orbitRadius: mercuryOrbitalRadius, sceneName: "art.scnassets/Mercury.scn", rotationDuration: 2)
        let venus = SCNNode.planetGroup(orbitRadius: venusOrbitalRadius, planetRadius: venusRadius, planetColor: .yellow)
        let jupiter = SCNNode.genericPlanetGroup(orbitRadius: jupiterOribialRadius, sceneName: "art.scnassets/Jupiter.scn", rotationDuration: 9)
        let earth = SCNNode.earthGroup(orbitRadius: earthOrbialRadius)
        let mars = SCNNode.planetGroup(orbitRadius: marsOrbitalRadius, planetRadius: marsRadius, planetColor: .red)
        
        let saturn = SCNNode.genericPlanetGroup(orbitRadius: saturnOrbitalRadius, sceneName: "art.scnassets/Neptune.scn", rotationDuration: 13)
        let uranus = SCNNode.genericPlanetGroup(orbitRadius: uranusOrbitalRadius, sceneName: "art.scnassets/Uranus.scn", rotationDuration: 13)
        let neptune = SCNNode.genericPlanetGroup(orbitRadius: neptuneOrbitalRadius, sceneName: "art.scnassets/Neptune.scn", rotationDuration: 8)
        let pluto = SCNNode.genericPlanetGroup(orbitRadius: plutoOrbitalRadius, sceneName: "art.scnassets/Pluto.scn", rotationDuration: 4)
        
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
