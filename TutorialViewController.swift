//
//  TutorialViewController.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 9/1/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class TutorialViewController: UIViewController {
    
    @IBOutlet weak var sceneView: SCNView!
    
    func createTutorial() {
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        let sphere = SCNSphere(radius: 2)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue
        sphere.materials = [material]
//        let sphereNode = SCNNode(geometry: sphere)
//        scene.rootNode.addChildNode(sphereNode)
        
        // load the table asset
        let tableNode = SCNScene(named: "art.scnassets/table.dae")!.rootNode
        tableNode.position = SCNVector3Make(0, 0, -12)
        tableNode.rotation = SCNVector4Make(1, 0, 0, Float.pi/20)
        tableNode.scale = SCNVector3Make(0.06, 0.06, 0.06)
        scene.rootNode.addChildNode(tableNode)
        
        // Load the device asset
        let iOSDeviceNode = SCNScene(named: "art.scnassets/iPhone6.dae")!.rootNode
        iOSDeviceNode.scale = SCNVector3Make(0.05, 0.05, 0.05)
//        iOSDeviceNode.pivot = SCNMatrix4MakeTranslation(-15.5, -25.5, -15.5)
        iOSDeviceNode.rotation = SCNVector4Make(1, 0, 0, Float.pi/2)
        iOSDeviceNode.position = SCNVector3Make(0, 0, 3)

        let min = iOSDeviceNode.boundingBox.min
        let max = iOSDeviceNode.boundingBox.max
        let diff = max - min
//        let algorithmicDiff = SCNVector3Make(-(max.x - min.x) / 2, -(max.x - min.x) / 2, -(max.x - min.x) / 2)
//        print("diff is \(diff)")
//        iOSDeviceNode.position = diff

//        let phoneLookatTable = SCNLookAtConstraint(target: tableNode)
//        iOSDeviceNode.constraints = [phoneLookatTable]
//        scene.rootNode.addChildNode(iOSDeviceNode)

        // at this point, tutorialNode is just an empty node with no parent
        let deviceRotatingNode = SCNNode()
        deviceRotatingNode.addChildNode(iOSDeviceNode)
        deviceRotatingNode.position = tableNode.position // SCNVector3Make(0, 0, -7)
        scene.rootNode.addChildNode(deviceRotatingNode)
        
        let camera = SCNCamera()
        let pov = SCNNode()
        pov.camera = camera
        scene.rootNode.addChildNode(pov)
        let cameraLookatTable = SCNLookAtConstraint(target: tableNode)
        pov.constraints = [cameraLookatTable]
        
        sceneView.pointOfView = pov
        
        // create and add the repeating animation
        let rotationValue = CGFloat.pi / 7
        let action = SCNAction.createARKitCalibrationAction(rotationValue: rotationValue)
        deviceRotatingNode.runAction(action)

        let tableAction = SCNAction.createARKitCalibrationAction(rotationValue: -rotationValue/8)
        tableNode.runAction(tableAction)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        createTutorial()
    }
}
