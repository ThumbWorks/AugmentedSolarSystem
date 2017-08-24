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
    var date = Date()

    @IBOutlet var status: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    var done = false
    var scalingOrbitUp = false
    var scaleSizeUp = false
    var lastUpdateTime: TimeInterval = 0
    
    @IBOutlet var toggleViews: [UIView]!
    @IBOutlet var resetViews: [UIView]!
    @IBOutlet weak var timeScaleSlider: UISlider!
    @IBOutlet weak var timeScaleButton: UIButton!
    @IBOutlet weak var planetScaleButton: UIButton!
    @IBOutlet weak var orbitScaleButton: UIButton!
    @IBOutlet weak var orbitShowButton: UIButton!

    var anchorWidth: Float?
    let cameraState: ARCamera.TrackingState = .normal

    // the optional planet that the camera is within the bounding volume of
    var insidePlanet: Planet?
    
    var sessionConfig = ARWorldTrackingConfiguration()
    let solarSystemNodes = Planet.buildSolarSystem()
    
    var pincher: PinchController?
    
    var arrowNode = SCNNode.arrow()
    
    @IBOutlet weak var hudHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var hudBottomConstraint: NSLayoutConstraint!
    
    // TODO make this lazy
    var blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.light))
    
    #if DEBUG
    // For debug purposes, count and color the discovered planes
    var planeCount = 0
    let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple]
    var debugPlaneAnchorNode: SCNNode?
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        pincher = PinchController(with: solarSystemNodes)
       
        Mixpanel.sharedInstance()?.track("view did load")
        
        // hide the toggleviews
        _ = toggleViews.map { (view) in
            view.isHidden = true
        }
        
        _ = resetViews.map { (view) in
            view.isHidden = true
        }
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Set the scene to the view
        sceneView.scene = SCNScene()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc func willEnterForeground() {
        restartEverything()
    }
    
    func restartPlaneDetection() {
        // configure session
        sessionConfig.planeDetection = .horizontal
        sceneView.session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
    }
    
    fileprivate func restartEverything() {
        restartPlaneDetection()
        
        arrowNode.isHidden = true
        
        #if DEBUG
        // clear the debug plane
        debugPlaneAnchorNode?.removeFromParentNode()
        debugPlaneAnchorNode = nil
        #endif

        // reset hudBottomConstraint
        // start the hud out of view
        hudBottomConstraint.constant = -hudHeightConstraint.constant
        
        done = false
        timeScaleButton.isHidden = true
        timeScaleSlider.isHidden = true

        // unhide the toggleViews
        _ = toggleViews.map({ (view) in
            view.isHidden = true
        })
        
        _ = resetViews.map({ (view) in
            view.isHidden = true
        })
        
        
        solarSystemNodes.removeAllNodesFromParent()
        
        // Create a session configuration
        //        sessionConfig.planeDetection = .horizontal
        
        // Run the view's session
        //        sceneView.session.run(sessionConfig)
        
        updateLabel()
        unblurBackground()
        
        resetToDetectedPlane()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restartEverything()
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
                self.solarSystemNodes.updateLookat(selected: newlySelectedPlanet, arrowNode: self.arrowNode)
            }
            collectionViewController = dest
        }
    }
}

// IBActions
extension ViewController {
    @IBAction func timeScaleButtonPressed(_ button: UIButton) {
        timeScaleSlider.isHidden = !timeScaleSlider.isHidden
    }
    
    @IBAction func sliderValueChanged(_ slider: UISlider) {
        print("value is \(slider.value)")
        let value = Double(slider.value)
        // iterate over all of the planets stop rotation and orbit, set with new float
//        solarSystemNodes.updateSpeed(value)
        print("currently this is a no-op until we re-do time")
    }
    
    @IBAction func backDate(_ sender: UIButton) {
        date = Date(timeInterval: -60*60*24, since: date)
        solarSystemNodes.updatePostions(to: date)
    }
    @IBAction func forwardDate(_ sender: UIButton) {
        date = Date(timeInterval: 60*60*24, since: date)
        solarSystemNodes.updatePostions(to: date)
    }
    
    @IBAction func pinchedScreen(_ sender: UIPinchGestureRecognizer) {
        pincher?.pinch(with: sender)
        _ = resetViews.map({ (view) in
            view.isHidden = false
        })
    }
    
    @IBAction func tappedScreen(_ sender: UITapGestureRecognizer) {
        // determine if we've tapped a planet
        if (sender.state == .ended) {
            let location = sender.location(in: view)
            let options: [SCNHitTestOption: Any] = [.searchMode: SCNHitTestSearchMode.all.rawValue]
            let hittestResults = sceneView.hitTest(location, options: options)
            let nodes = hittestResults.map({ (hitTest) -> SCNNode in
                return hitTest.node
            })
            
            for node in nodes {
                // see if it has a planetNode
                if self.solarSystemNodes.planetoids.contains(where: { (planets) -> Bool in
                    return node == planets.value.planetNode
                }) {
                    if let name = node.name {
                        print("tapped \(name))")
                        Mixpanel.sharedInstance()?.track("tracked a planet", properties: ["name" : name])

                        // now scroll to this node. We've got a name
                        self.collectionViewController?.changeToPlanet(name: name)
                        
                        // We only want the first one, so return out of the method
                        return
                    }
                }
            }
        }
    }
    
    // This is essentially reset
    @IBAction func resetToDetectedPlane() {
        Mixpanel.sharedInstance()?.track("tapped reset to detected plane")
        guard let anchorWidth = anchorWidth else {
            print("Tapped reset without an anchorWidth")
            return
        }
        let radius = anchorWidth / 2
        scaleSizeUp = !scaleSizeUp
        
        solarSystemNodes.scalePlanets(to: radius)
        
        _ = resetViews.map({ (view) in
            view.isHidden = true
        })
        
        orbitShowButton.setImage(#imageLiteral(resourceName: "Hide Orbit"), for: .normal)
        orbitScaleButton.setImage(#imageLiteral(resourceName: "Scale Orbit"), for: .normal)
        planetScaleButton.setImage(#imageLiteral(resourceName: "Scale Planets"), for: .normal)
    }
    
    @IBAction func togglePaths(_ button: UIButton) {
        Mixpanel.sharedInstance()?.track("toggled paths")
        let currentlyShowing = solarSystemNodes.showingPaths()
        solarSystemNodes.toggleOrbitPaths(to: !currentlyShowing)
        button.setImage(!currentlyShowing ? #imageLiteral(resourceName: "Hide Orbit Selected") : #imageLiteral(resourceName: "Hide Orbit"), for: .normal)
    }
    
    @IBAction func changeOrbitScaleTapped(_ button: UIButton) {
        Mixpanel.sharedInstance()?.track("change orbit scale")
        
        // toggle the state
        scalingOrbitUp = !scalingOrbitUp
        
        button.setImage(scalingOrbitUp ? #imageLiteral(resourceName: "Scale Orbit Selected") : #imageLiteral(resourceName: "Scale Orbit"), for: .normal)
        
        solarSystemNodes.scaleOrbit(scalingUp: scaleSizeUp)
        
        _ = resetViews.map { (view) in
            view.isHidden = false
        }
    }
    
    @IBAction func changeSizeScaleTapped(_ button: UIButton) {
        Mixpanel.sharedInstance()?.track("change size scale")
        
        // toggle the state
        scaleSizeUp = !scaleSizeUp
        
        button.setImage(scaleSizeUp ? #imageLiteral(resourceName: "Scale Planets Selected") : #imageLiteral(resourceName: "Scale Planets"), for: .normal)
        
        // do the scale
        solarSystemNodes.scaleNodes(scaleUp: scaleSizeUp)
        
        // ensure that the reset button is not hidden
        _ = resetViews.map({ (view)  in
            view.isHidden = false
        })
    }
    
    func blurBackground() {
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)
    }
    
    func unblurBackground() {
        blurView.removeFromSuperview()
    }
    
    func updateLabel() {
        
        switch cameraState {
        case .normal:
            if (!done) {
                status.text = "Searching for a surface"
            }
            if let planet = insidePlanet {
                if planet == Planet.sun {
                    status.text = "You are inside the \(planet.name)"
                } else {
                    status.text = "You are inside \(planet.name)"
                }
            } else {
                status.text = ""
            }
        case .notAvailable:
            status.text = "Tracking unavailable"
        case .limited(let reason):
            status.text = "Tracking Limited: \(reason)"
        }
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
        DispatchQueue.main.async {
            self.updateLabel()
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
            return
        }
        guard let cameraNode = sceneView.pointOfView else {
            print("we got an update but we don't have a camera. No distance calculations can happen")
            return
        }

        // we calculate the distances so we can
        // a) display the distance for each planet in the hud
        // b) determine if we are inside of a node
        var distances = [Planet:Float]()
        var sizes = [Planet:Float]()
        insidePlanet = nil

        for (planet, node) in solarSystemNodes.planetoids {
            
            guard let planetNode = node.planetNode else {
                print("\(planet.name ) doesn't have a node, bail")
                return
            }
            let distance = cameraNode.position.distance(receiver: planetNode.position)
            distances[planet] = distance
            
            sizes[planet] = planetNode.boundingSphere.radius * planetNode.scale.x
            if let sphere = planetNode.geometry as? SCNSphere {
                let radius = sphere.radius * CGFloat(planetNode.scale.x)
                if CGFloat(distance) < radius {
                    insidePlanet = planet
                }
            }
        }
        // rate limit
        if (self.lastUpdateTime + 1.0) > time {
            return
        }
        DispatchQueue.main.async {
            self.updateLabel()
            self.lastUpdateTime = time
            if let planet = self.collectionViewController?.currentPlanet, let meters = distances[planet] {
                var distanceString = ""
                print("calculating distance")
                distanceString =  "\(meters.format(f: ".1")) real meters away"
                self.collectionViewController?.updateDistance(distanceString)
            }
            //TODO come back to this
//            self.collectionViewController?.updateReferenceSize(sizes)
            let arrowNode = self.arrowNode
            if let constraints = arrowNode.constraints {
                let lookats: [SCNLookAtConstraint] = constraints.filter({ (constraint) -> Bool in
                    if let _ = constraint as? SCNLookAtConstraint {
                        return true
                    }
                    return false
                }) as! [SCNLookAtConstraint]
                
                if let lookatTarget = lookats.first?.target {
                    self.arrowNode.isHidden = self.sceneView.isNode(lookatTarget, insideFrustumOf: cameraNode)
                }
            }
        }
    }
    
    #if DEBUG
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        guard let anchor = self.debugPlaneAnchorNode else {return}
        anchor.isHidden = !anchor.isHidden
    }
    #endif
    
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
                    let plane = BorderedPlane(width: planeAnchor.extent.x, height: planeAnchor.extent.z, color: .blue)
                    self.debugPlaneAnchorNode = plane
                    node.addChildNode(plane)
                    
                    let borderMaterial = SCNMaterial()
                    borderMaterial.diffuse.contents = UIColor.blue
                    plane.addBorder(materials: [borderMaterial])
                    
                    // once we are restarting a session, this needs to be checked
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTap(_:)))
                    tap.numberOfTapsRequired = 3
                    self.view.addGestureRecognizer(tap)
                #endif

                let width = planeAnchor.extent.x
                let length = planeAnchor.extent.y
                let depth = planeAnchor.extent.z
                print("The plane w: \(width) l: \(length) d: \(depth)")
                
                if width < 0.1 && length < 0.1 {
                    print("We need a minimum sized anchor plane")
                    return
                }
                
                if self.done {
                    return
                }
                Mixpanel.sharedInstance()?.track("Discovered an Anchor")

                // move the HUD so it's visible
                self.hudBottomConstraint.constant = 0
                
                // Make the bottom HUD show, hint that it is scrollable
                UIView.animate(withDuration: 0.3, delay: 2, options: .curveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: { (completed) in
                    self.collectionViewController?.hintScrollable()
                })
                
                if let cameraNode = self.sceneView.pointOfView {
                    self.arrowNode.categoryBitMask = 4
                    cameraNode.addChildNode(self.arrowNode)
                    self.solarSystemNodes.updateLookat(selected: Planet.sun, arrowNode: self.arrowNode)
                    var lightVector = node.position
                    lightVector.y = 10
                    let light = SCNNode.omniLight(lightVector)
                    node.addChildNode(light)
                }
                
                // unhide the toggleViews
                _ = self.toggleViews.map({ (view) in
                    view.isHidden = false
                })
                self.timeScaleButton.isHidden = false
                self.done = true
                
                self.solarSystemNodes.addAllNodesAsChild(to: node)
               
                // determine scale based on the size of the plane
                var radius: Float
                if depth < width {
                    radius = depth
                } else {
                    radius = width
                }
                self.solarSystemNodes.scalePlanets(to: radius / 2)
                self.anchorWidth = radius
                
                // At this point the planets are visible. Set a timer for the rating mechanism.
                // The thinking here is that they've seen the planets and are playing with them for a minute.
                // A this point people seem to really like it, now would be the time to ask
                let deadlineTime = DispatchTime.now() + .seconds(60)
                DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                    AppRater.requestEventIsAppropriate()
                }
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
//        print("will update node \(node) for anchor \(anchor.identifier)")
        
        // Since we added our SCNPlane to the node as a child, we must find the first child
        // The anchor, of course, must be an ARPlaneAnchor
        // Update the SCNPlane geometry of this SCNNode to resemble our new understanding
        if let thePlaneNode = node.childNodes.first, let planeAnchor = anchor as? ARPlaneAnchor {
            for line in thePlaneNode.childNodes {
                line.removeFromParentNode()
            }
            
            let plane = BorderedPlane(width: planeAnchor.extent.x, height: planeAnchor.extent.y, color: .red)
            thePlaneNode.addChildNode(plane)
            let borderMaterial = SCNMaterial()
            borderMaterial.diffuse.contents = UIColor.red
            plane.addBorder(materials: [borderMaterial])
        }
    }
    
    #if DEBUG
    func nextMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        let color = self.colors[self.planeCount % self.colors.count]
        print("The color is \(color)")
        material.diffuse.contents = color.withAlphaComponent(0.6)
        self.planeCount = self.planeCount + 1
        return material
    }
    #endif
}
