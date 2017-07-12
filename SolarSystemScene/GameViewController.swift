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
    
    var planetNodes: [Planet:PlanetoidGroupNode]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        let scene = SCNScene()
        // create and add a camera to the scene
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
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
        
        let createdPlanetNodes = scene.rootNode.buildSolarSystem()
        planetNodes = createdPlanetNodes.0
        scene.rootNode.addChildNode(createdPlanetNodes.1)
        for nodeMap in createdPlanetNodes.0 {
            scene.rootNode.addChildNode(nodeMap.value)
        }
        
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
    
    @IBAction func changeScaleTapped(_ sender: Any) {
        print("changing scale")
        
        guard let nodes = planetNodes else {
            print("We don't have any planets")
            return
        }
        
        let earthArray = nodes.filter { (planet, _) -> Bool in
            return planet.name == "Earth"
        }
        guard let earthPlanet = earthArray.first else {
            print("did not find earth. bail")
            return
        }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5
        for (planet,node) in nodes {
            // update the scale here
            let radius = planet.radius / earthPlanet.0.radius
            print("path scale is \(node.path?.scale). \n planet scale \(node.planetNode?.scale) \n radius compared to earth should be \(radius)")
            node.planetNode?.scale = SCNVector3Make(radius, radius, radius)
            node.path?.scale = SCNVector3Make(5, 5, 5)
            print(planet.name)
        }
        // on completion - unhighlight
        SCNTransaction.completionBlock = {
            print("scale of planets done")
        }
        SCNTransaction.commit()
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
