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
import Mixpanel

class ViewController: UIViewController {
    
    @IBOutlet var status: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    var done = false
    var scalingOrbitUp = false
    var scaleSizeUp = false
    
    var anchorWidth: Float?
    
    var sessionConfig = ARWorldTrackingSessionConfiguration()
    let solarSystemNodes = Planet.buildSolarSystem()
    var arrowNode = SCNNode.arrow()
    
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    
    // TODO make this lazy
    var blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.light))

    #if DEBUG
    // For debug purposes, count and color the discovered planes
    var planeCount = 0
    let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple]
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()

        Mixpanel.sharedInstance()?.track("view did load")
        
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
        
        print("view will appear. restart plane detection")
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
    var collectionViewController: PlanetCollectionViewController?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PlanetCollectionViewController {
          print("set the thing")
            dest.planetSelectionChanged = { (newlySelectedPlanet) in
                print("planet \(newlySelectedPlanet)")
                
                for (planet, node) in self.solarSystemNodes.planetoids {
                    if newlySelectedPlanet == planet {
                        print("set this label")
//                        node.textNode.isHidden = false
                        SCNTransaction.begin()
                        SCNTransaction.animationDuration = 0.5
                        let lookat = SCNLookAtConstraint(target: node.planetNode)
                        self.arrowNode.constraints = [lookat]
                        SCNTransaction.commit()

                    } else {
//                        node.textNode.isHidden = true
                    }
                }
            }
            collectionViewController = dest
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
   
    @IBAction func tappedScreen(_ sender: UITapGestureRecognizer) {
        
        // determine if we've tapped a planet
        if (sender.state == .ended) {
            let location = sender.location(in: view)
            let hittestResults = sceneView.hitTest(location, options: nil)
            for result in hittestResults {
                let node = result.node
                
                if self.solarSystemNodes.planetoids.contains(where: { (planets) -> Bool in
                    return node == planets.value.planetNode
                }) {
                    if let name = result.node.name {
                        print("tapped \(name))")
                        Mixpanel.sharedInstance()?.track("tracked a planet", properties: ["name" : name])

                        // now scroll to this node. We've got a name
                        self.collectionViewController?.changeToPlanet(name: name)
                        return
                    }
                }
                
            }
        }
        
        arrowNode.isHidden = !arrowNode.isHidden
    }
    
    @IBAction func scaleToARPlane() {
        Mixpanel.sharedInstance()?.track("tapped scale to plane")

        if let anchorWidth = anchorWidth {
            PlanetoidGroupNode.scale(nodes: solarSystemNodes.planetoids, plutoTableRadius: anchorWidth)
        }
    }
    
    @IBAction func toggleTrails() {
        Mixpanel.sharedInstance()?.track("toggled trails")

        for (_, planetoidNode) in solarSystemNodes.planetoids {
            // do something with button
            planetoidNode.path?.isHidden = !(planetoidNode.path?.isHidden)!
        }
    }
    
    @IBAction func changeOrbitScaleTapped(_ sender: Any) {
        print("changing orbit scale")
        Mixpanel.sharedInstance()?.track("change orbit scale")

        // toggle the state
        scalingOrbitUp = !scalingOrbitUp
        PlanetoidGroupNode.scaleOrbit(planetoids: solarSystemNodes.planetoids, scalingUp: scalingOrbitUp)
    }
    
    @IBAction func changeSizeScaleTapped(_ sender: Any) {
        print("changing scale")
        Mixpanel.sharedInstance()?.track("change size scale")

        // toggle the state
        scaleSizeUp = !scaleSizeUp
        
        PlanetoidGroupNode.scaleNodes(nodes: solarSystemNodes.planetoids, scaleUp: scaleSizeUp)
    }
    
    func blurBackground() {
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)
    }
    
    func unblurBackground() {
        blurView.removeFromSuperview()
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
        blurBackground()
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
        unblurBackground()
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

        var distances = [Planet:Float]()
        for (planet, node) in solarSystemNodes.planetoids {
            
            guard let planetPosition = node.planetNode?.position else {
                print("\(planet.name ) doesn't have a position, bail")
                return
            }
            
            let distance = cameraNode.position.distance(receiver: planetPosition)
            distances[planet] = distance
        }
        DispatchQueue.main.async {
            self.collectionViewController?.updateDistance(distances: distances)
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
           
            if let planeAnchor = anchor as? ARPlaneAnchor {
                #if DEBUG
                    // DEBUG: Display all of the ARPlaneAnchors that we see
                    let pos = SCNVector3.positionFromTransform(planeAnchor.transform)
                    print("NEW SURFACE DETECTED AT \(pos.friendlyString())")
                    print("The box of the plane is before scaling is \(planeAnchor.extent)")
                    
                    // We get a plane, this should roughly match a tabletop or a floor
//                    let plane = ViewController.planeFor(planeAnchor, materials: [self.nextMaterial()])
                    
                    let plane = BorderedPlane(width: planeAnchor.extent.x, height: planeAnchor.extent.z, color: .blue)
                    node.addChildNode(plane)
                    
                    let borderMaterial = SCNMaterial()
                    borderMaterial.diffuse.contents = UIColor.blue
                    plane.addBorder(materials: [borderMaterial])
                    // create a new node, for some reason this is easier than using the original. The
                    // original is oddly rotated on it's side.
//                    let planeNode = SCNNode(geometry: plane)
//                    planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
//                    planeNode.categoryBitMask = 2
//                    planeNode.addCorners()
        
//                    node.addChildNode(planeNode)

                #endif
                
                if self.done {
                    return
                }
                Mixpanel.sharedInstance()?.track("Discovered an Anchor")

                if let cameraNode = self.sceneView.pointOfView {
                    self.arrowNode.categoryBitMask = 4
                    cameraNode.addChildNode(self.arrowNode)
                    
                    // Make the bottom HUD show, hint that it is scrollable
                    UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {
                        self.view.layoutIfNeeded()
                    }, completion: { (completed) in
                        self.collectionViewController?.hintScrollable()
                    })
                    
                    var lightVector = node.position
                    lightVector.y = 10
                    let light = SCNNode.omniLight(lightVector)
                    node.addChildNode(light)
                }
                
                self.done = true
                for planetNode in self.solarSystemNodes.planetoids {
                    node.addChildNode(planetNode.value)
                }
                for light in self.solarSystemNodes.lightNodes {
                    node.addChildNode(light)
                }
                
                // determine scale based on the size of the plane
                let width = planeAnchor.extent.x
                let length = planeAnchor.extent.y
                let depth = planeAnchor.extent.z
                print("The plane w: \(width) l: \(length) d: \(depth)")
                
                var radius: Float
                if depth < width {
                    radius = depth
                } else {
                    radius = width
                }
                
                PlanetoidGroupNode.scale(nodes: self.solarSystemNodes.planetoids, plutoTableRadius: radius)
                self.anchorWidth = radius
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
        print("will update node \(node) for anchor \(anchor.identifier)")
        
        // Since we added our SCNPlane to the node as a child, we must find the first child
        // The anchor, of course, must be an ARPlaneAnchor
        // Update the SCNPlane geometry of this SCNNode to resemble our new understanding
        if let thePlaneNode = node.childNodes.first, let planeAnchor = anchor as? ARPlaneAnchor {
            for line in thePlaneNode.childNodes {
                print("the line is a \(line)")
                line.removeFromParentNode()
            }
//            let materials = (thePlaneNode.geometry?.materials)!
            
            let plane = BorderedPlane(width: planeAnchor.extent.x, height: planeAnchor.extent.y, color: .red)
            thePlaneNode.addChildNode(plane)
            let borderMaterial = SCNMaterial()
            borderMaterial.diffuse.contents = UIColor.red
            plane.addBorder(materials: [borderMaterial])

//            let plane = ViewController.planeFor(planeAnchor, materials: materials)
//            thePlaneNode.geometry = plane
//            thePlaneNode.addCorners()
        }
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
    
    // Helper methods for plane and anchor updates
    class func planeFor(_ planeAnchor: ARPlaneAnchor, materials: [SCNMaterial]) -> SCNPlane {
        let width = planeAnchor.extent.x
        let height = planeAnchor.extent.z
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        plane.materials = materials
        return plane
    }
    
    #if DEBUG
    func nextMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        let color = UIColor.blue// self.colors[self.planeCount % self.colors.count]
        print("The color is \(color)")
        material.diffuse.contents = color.withAlphaComponent(0.6)
        self.planeCount = self.planeCount + 1
        return material
    }
#endif
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
        return
        
//        print("These are updated")
//        for anchor in anchors {
//            print("updated anchors \(anchor)")
//        }
//        print("that is the end of the updates")
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
