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
    var scalingOrbitUp = false
    var scaleSizeUp = false
    
    var sessionConfig = ARWorldTrackingSessionConfiguration()
    let solarSystemNodes = Planet.buildSolarSystem()

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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PlanetCollectionViewController {
          print("set the thing")
            dest.planetSelectionChanged = { (newlySelectedPlanet) in
                print("planet \(newlySelectedPlanet)")
                
                for (planet, node) in self.solarSystemNodes.planetoids {
                    if newlySelectedPlanet == planet {
                        print("set this label")
                        node.textNode.isHidden = false
                    } else {
                        node.textNode.isHidden = true
                    }
                }
            }
        }
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

extension ViewController {
   
    @IBAction func toggleTrails() {
        for (_, planetoidNode) in solarSystemNodes.planetoids {
            // do something with button
            planetoidNode.path?.isHidden = !(planetoidNode.path?.isHidden)!
        }
    }
    
    @IBAction func changeOrbitScaleTapped(_ sender: Any) {
        print("changing orbit scale")
        // toggle the state
        scalingOrbitUp = !scalingOrbitUp
        PlanetoidGroupNode.scaleOrbit(planetoids: solarSystemNodes.planetoids, scalingUp: scalingOrbitUp)
    }
    
    @IBAction func changeSizeScaleTapped(_ sender: Any) {
        print("changing scale")

        // toggle the state
        scaleSizeUp = !scaleSizeUp
        
        PlanetoidGroupNode.scaleNodes(nodes: solarSystemNodes.planetoids, scaleUp: scaleSizeUp)
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
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if !done {
//            print("Wait until we find an anchor for the sun")
            return
        }
        guard let cameraNode = sceneView.pointOfView else {
            print("we got an update but we don't have a camera. No distance calculations can happen")
            return
        }

        for (planet, node) in solarSystemNodes.planetoids {
            guard let planetPosition = node.planetNode?.position else {
                print("\(planet.name ) doesn't have a position, bail")
                return
            }
            let distance = cameraNode.position.distance(receiver: planetPosition)
//            print("planet \(planet.name) is this far away: \(distance)")
        }
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
                self.done = true
                for planetNode in self.solarSystemNodes.planetoids {
                    node.addChildNode(planetNode.value)
                }
                let pos = SCNVector3.positionFromTransform(planeAnchor.transform)
                print("NEW SURFACE DETECTED AT \(pos.friendlyString())")
                print("The box of the plane is before scaling is \(planeAnchor.extent)")
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
