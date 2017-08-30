//
//  GameViewController.swift
//  SolarSystemScene
//
//  Created by Roderic Campbell on 7/5/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {
    @IBOutlet var scnView: SCNView!
    
    let solarSystem = Planet.buildSolarSystem()
//    var planetNodes: [Planet:PlanetoidGroupNode]?
    var scaleSizeUp = false
    var scaleOrbitUp = false
    var pinchController: PinchController?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
       
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        scene.rootNode.addChildNode(solarSystem.lightNodes[0])
        for nodeMap in solarSystem.planetoids {
            scene.rootNode.addChildNode(nodeMap.value)
        }
        
        pinchController = PinchController(with: solarSystem)
        solarSystem.scalePlanets(to: 40)
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func pinch(_ sender: UIPinchGestureRecognizer) {
        pinchController?.pinch(with: sender)
    }
    
    @IBAction func changeScaleTapped(_ sender: UIButton) {
        print("changing scale")
        
        // toggle the state
        scaleSizeUp = !scaleSizeUp

        solarSystem.scaleNodes(scaleUp: scaleSizeUp)
    }
    
    @IBAction func togglePaths() {
        for (_, planetoidNode) in solarSystem.planetoids {
            // do something with button
            planetoidNode.path?.isHidden = !(planetoidNode.path?.isHidden)!
        }
    }
    
    @IBAction func changeOrbitScaleTapped(_ sender: UIButton) {
        // toggle the state
        scaleOrbitUp = !scaleOrbitUp
        solarSystem.scaleOrbit(scalingUp: scaleSizeUp)
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
