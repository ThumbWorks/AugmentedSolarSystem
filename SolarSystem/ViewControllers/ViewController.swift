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
import SwiftMessages

class ViewController: UIViewController {
    var startTime: TimeInterval = 0
    var startDate = Date()
    var displayedDate = Date()

    lazy var dateFormatter = { () -> DateFormatter in
        // TODO This should happen once. 
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    var datePicker: DatePickerViewController?
    var hudViewController: HUDViewController?

    @IBOutlet var status: UILabel!
    @IBOutlet var sceneView: VirtualObjectARView!
    var done = false
    var scalingOrbitUp = false
    var scaleSizeUp = false
    @IBOutlet var toggleViews: [UIView]!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var planetScaleButton: UIButton!
    @IBOutlet weak var orbitScaleButton: UIButton!
    @IBOutlet weak var orbitShowButton: UIButton!

    var anchorWidth: Float?
    let cameraState: ARCamera.TrackingState = .normal
    var focusSquare = FocusSquare()

    // the optional planet that the camera is within the bounding volume of
    var insidePlanet: Planet?
    
    let solarSystemNodes = Planet.buildSolarSystem()
    
    var pincher: PinchController?
    
    var arrowNode = SCNNode.arrow()
    
    @IBOutlet weak var datePickerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var datePickerHeightConstraint: NSLayoutConstraint!
    
    #if DEBUG
    // For debug purposes, count and color the discovered planes
    var planeCount = 0
    let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple]
    var debugPlaneAnchorNode: SCNNode?
    #endif

//    func updateDateString(_ date: Date) {
//        let dateString = dateFormatter().string(from: date)
//        dateButton.setTitle(dateString, for: .normal)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        #if targetEnvironment(simulator)
        view.backgroundColor = .gray
        #endif
        pincher = PinchController(with: solarSystemNodes)
        status.text = ""
        Mixpanel.sharedInstance()?.track("view did load")
        
        // hide the toggleviews
        toggleViews.forEach { $0.isHidden = true }

        // Set the view's delegate
        sceneView.delegate = self
        
        // Set the scene to the view
        sceneView.scene = SCNScene()
        sceneView.scene.rootNode.addChildNode(focusSquare)

//        updateDateString(displayedDate)

        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func willEnterForeground() {
        restartEverything()
    }
    
    @objc func didEnterBackground() {
        // dismiss any view controller that is presented
        if let presented = self.presentedViewController {
            print("presented view controller is \(presented)")
            self.dismiss(animated: false)
        }
    }
    
    func restartPlaneDetection() {
        // configure session
        let sessionConfig = ARWorldTrackingConfiguration()
        sessionConfig.planeDetection = .horizontal
        sceneView.session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
        focusSquare.unhide()
    }
    
    func restartSessionNoPlaneDetection() {
        // configure session
        let sessionConfig = ARWorldTrackingConfiguration()
        sceneView.session.run(sessionConfig, options:[])
    }
    
    
    func updateFocusSquare() {
        
        // We should always have a valid world position unless the sceen is just being initialized.
        guard let (worldPosition, planeAnchor, _) = sceneView.worldPosition(fromScreenPosition: screenCenter, objectPosition: focusSquare.lastPosition) else {
            self.focusSquare.state = .initializing
            self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            return
        }
        
        if let _ = self.presentedViewController as? TutorialViewController {
            self.dismiss(animated: false)
        }
        
        self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
        let camera = self.sceneView.session.currentFrame?.camera
        if let planeAnchor = planeAnchor {
            self.focusSquare.state = .planeDetected(anchorPosition: worldPosition, planeAnchor: planeAnchor, camera: camera)
        } else {
            self.focusSquare.state = .featuresDetected(anchorPosition: worldPosition, camera: camera)
        }
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
        toggleHUD(toShowingState: false, animated: false)

        toggleDatePicker(toShowingState: false, animated: false)
        
        done = false

        // hide the toggleViews
        toggleViews.forEach { $0.isHidden = true }

        solarSystemNodes.removeAllNodesFromParent()
        
        // Create a session configuration
        //        sessionConfig.planeDetection = .horizontal
        
        // Run the view's session
        //        sceneView.session.run(sessionConfig)
        
        updateLabel()
        resetToDetectedPlane()
        
        collectionViewController?.changeToPlanet(name: Planet.sun.name)
        #if !targetEnvironment(simulator)
        let tutorial = TutorialViewController()
        tutorial.definesPresentationContext = true
        tutorial.modalPresentationStyle = .overCurrentContext
        present(tutorial, animated: true)
        #else
        toggleHUD(toShowingState: true)
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toggleDatePicker(toShowingState: false)
        toggleHUD(toShowingState: false, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        restartEverything()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
//        sceneView.session.pause()
        restartEverything()
    }
    
    var collectionViewController: PlanetCollectionViewController?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PlanetCollectionViewController {
            dest.planetSelectionChanged = { (newlySelectedPlanet) in
                self.solarSystemNodes.updateLookat(selected: newlySelectedPlanet, arrowNode: self.arrowNode)
            }
            collectionViewController = dest
        }
        
        if let dest = segue.destination as? DatePickerViewController {
            datePicker = dest
            
            dest.dateSelection = { (date, done) in
                self.displayedDate = date
                self.startTime = 0
                self.startDate = date
//                self.updateDateString(date)
                self.solarSystemNodes.updatePostions(to: date)
                
                if done {
                    self.toggleDatePicker(toShowingState: false)
                }
            }
        }
    }
    
    func toggleDatePicker(toShowingState: Bool, animated: Bool = true) {
        datePickerBottomConstraint.constant = toShowingState ? 0 : -datePickerHeightConstraint.constant
        
        let duration = animated ? 0.3 : 0.0
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        })
        
        if toShowingState == true {
            datePicker?.datePicker.setDate(displayedDate, animated: false)
        }
    }
    func toggleHUD(toShowingState: Bool, animated: Bool = true) {
        if toShowingState {
            let hudViewController = HUDViewController()
            hudViewController.modalPresentationStyle = .custom
            hudViewController.transitioningDelegate = self
            self.hudViewController = hudViewController
            present(hudViewController, animated: true)
        } else if presentedViewController as? HUDViewController == nil {
            dismiss(animated: true)
        }
    }
}

class HUDPresentationController: UIPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView,
            let presentedView = presentedView else { return .zero }

        let inset: CGFloat = 16

        // Make sure to account for the safe area insets
        let safeAreaFrame = containerView.bounds
            .inset(by: containerView.safeAreaInsets)

        let targetWidth = safeAreaFrame.width - 2 * inset
        let fittingSize = CGSize(
            width: targetWidth,
            height: UIView.layoutFittingCompressedSize.height
        )
        let targetHeight = presentedView.systemLayoutSizeFitting(
            fittingSize, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow).height

        var frame = safeAreaFrame
        frame.origin.x += inset
        frame.origin.y += frame.size.height - targetHeight - inset
        frame.size.width = targetWidth
        frame.size.height = targetHeight
        return frame
    }
}

extension ViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        return HUDPresentationController.init(presentedViewController: presented, presenting: presenting)
    }
}

// IBActions
extension ViewController {
    @IBAction func tappedInfo(_ button: UIButton) {
        let aboutView: AboutView
        do {
            aboutView = try SwiftMessages.viewFromNib(named: "AboutView")
        } catch {
            print("error \(error)")
            return
        }
        //view.delegate = delegate
        //view.update()

        var config = SwiftMessages.Config()

        config.presentationContext = .window(windowLevel: .alert)
        config.duration = .forever
        config.presentationStyle = .center
        config.dimMode = .blur(style: .dark,
                               alpha: 1,
                               interactive: true)
        SwiftMessages.show(config: config, view: aboutView)
    }

    @IBAction func toggleDateSelector(_ button: UIButton) {
        let isUp = datePickerBottomConstraint.constant == 0
        toggleDatePicker(toShowingState: !isUp)
    }
    
    @IBAction func pinchedScreen(_ sender: UIPinchGestureRecognizer) {
        pincher?.pinch(with: sender)
    }
    
    func addSolarSystemToFocusSquareLocation() {
        switch focusSquare.state {
        case .initializing:
            break
            
        case .featuresDetected(_, _):
            break
            
        case .planeDetected(let anchorPosition, let planeAnchor, _):
            updateLabel()
            print("set the sun here \(anchorPosition)")
            Mixpanel.sharedInstance()?.track("Tapped to set solar system")

            let root = sceneView.scene.rootNode
            let position = SCNVector3Make(anchorPosition.x, anchorPosition.y, anchorPosition.z)
            solarSystemNodes.placeSolarSystem(on: root, at: position)

            let width = planeAnchor.extent.x
            let depth = planeAnchor.extent.z

            // determine scale based on the size of the plane
            var radius: Float
            if depth < width {
                radius = depth
            } else {
                radius = width
            }
            DispatchQueue.main.async {
                self.updateUIAfterPlacingObjects(root, radius: radius)
            }
            focusSquare.hide()
//
//            // Testing to see if this helps with performance at all. After 6 seconds, just change the session configuration to something less aggressive
//            let deadlineTime = DispatchTime.now() + .seconds(6)
//            DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
//                self.restartSessionNoPlaneDetection()
//            })
        }
    }
    
    @IBAction func tappedScreen(_ sender: UITapGestureRecognizer) {

        if !done {
            addSolarSystemToFocusSquareLocation()
            return
        }
                
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
        
        orbitShowButton.setImage(#imageLiteral(resourceName: "Hide Orbit"), for: .normal)
        orbitScaleButton.setImage(#imageLiteral(resourceName: "Scale Orbit"), for: .normal)
        planetScaleButton.setImage(#imageLiteral(resourceName: "Scale Planets"), for: .normal)
        
        // show the orbits
        solarSystemNodes.toggleOrbitPaths(hidden: false)
        orbitShowButton.setImage(#imageLiteral(resourceName: "Hide Orbit"), for: .normal)
    }
    
    @IBAction func togglePaths(_ button: UIButton) {
        Mixpanel.sharedInstance()?.track("toggled paths")
        let currentlyShowing = solarSystemNodes.showingPaths()
        solarSystemNodes.toggleOrbitPaths(hidden: !currentlyShowing)
        button.setImage(!currentlyShowing ? #imageLiteral(resourceName: "Hide Orbit Selected") : #imageLiteral(resourceName: "Hide Orbit"), for: .normal)
    }
    
    @IBAction func changeOrbitScaleTapped(_ button: UIButton) {
        Mixpanel.sharedInstance()?.track("change orbit scale")
        
        // toggle the state
        scalingOrbitUp = !scalingOrbitUp
        
        button.setImage(scalingOrbitUp ? #imageLiteral(resourceName: "Scale Orbit Selected") : #imageLiteral(resourceName: "Scale Orbit"), for: .normal)
        
        solarSystemNodes.scaleOrbit(scalingUp: scalingOrbitUp)
    }
    
    @IBAction func changeSizeScaleTapped(_ button: UIButton) {
        Mixpanel.sharedInstance()?.track("change size scale")
        
        // toggle the state
        scaleSizeUp = !scaleSizeUp
        
        button.setImage(scaleSizeUp ? #imageLiteral(resourceName: "Scale Planets Selected") : #imageLiteral(resourceName: "Scale Planets"), for: .normal)
        
        // do the scale
        solarSystemNodes.scaleNodes(scaleUp: scaleSizeUp)
    }
    
    func updateLabel() {
        return

            //print("🐛 update label")
        switch cameraState {
        case .normal:
            if (!done) {
                switch focusSquare.state {
                case .initializing:
                    break
                    
                case .featuresDetected(_, _):
                    status.text = "Searching for a surface"
                    break
                    
                case .planeDetected(_, _, _):
                    status.text = "Tap to set the Solar System"
                }
            } else if let planet = insidePlanet {
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
        restartEverything()
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
        let sessionConfig = ARWorldTrackingConfiguration()
        session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
        restartPlaneDetection()
        status.text = "Resetting Session"
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let cameraNode = sceneView.pointOfView else {
            print("we got an update but we don't have a camera. No distance calculations can happen")
            return
        }
        
//        if !done {
//            return
//        }
        
        if startTime == 0 {
            startTime = time
        }

        // we calculate the distances so we can
        // a) display the distance for each planet in the hud
        // b) determine if we are inside of a node
        var distances = [Planet:Float]()
        var sizes = [Planet:Float]()
        insidePlanet = nil

        let delta = (time - startTime) * 60 * 60 * 24

        let newDate = startDate.addingTimeInterval(delta)
        displayedDate = newDate
        solarSystemNodes.updatePostions(to: newDate)
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

        DispatchQueue.main.async {
            self.updateFocusSquare()
            self.updateLabel()
            self.hudViewController?.update(with: distances)
            let arrowNode = self.arrowNode
            if let constraints = arrowNode.constraints {
                let lookats: [SCNLookAtConstraint] = constraints.filter({ (constraint) -> Bool in
                    if let _ = constraint as? SCNLookAtConstraint {
                        return true
                    }
                    return false
                }) as! [SCNLookAtConstraint]

                if let lookatTarget = lookats.first?.target {
                    self.arrowNode.isHidden = self.sceneView.isNode(lookatTarget, insideFrustumOf: cameraNode) || !self.done
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
        print("did add node. we go to async after this")
        DispatchQueue.main.async {
            print("did add node, pushed to main queue")
            
            if let planeAnchor = anchor as? ARPlaneAnchor {
                #if DEBUG || false
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
                
                if self.done {
                    return
                }
                Mixpanel.sharedInstance()?.track("Discovered an Anchor")
                self.dismiss(animated: false)
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
    
    func updateUIAfterPlacingObjects(_ node: SCNNode, radius: Float) {
        // move the HUD so it's visible
        self.toggleHUD(toShowingState: true)

//        self.collectionViewController?.hintScrollable()

        // Make the bottom HUD show, hint that it is scrollable
        //                UIView.animate(withDuration: 0.3, delay: 2, options: .curveEaseInOut, animations: {
        //                    self.view.layoutIfNeeded()
        //                }, completion: { (completed) in
        //                    self.collectionViewController?.hintScrollable()
        //                })
        
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
        toggleViews.forEach { $0.isHidden = false }

        self.done = true
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
