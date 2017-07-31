//
//  PinchController.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 7/31/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class PinchController {
    private var originalScale: Float?
    private var originalXPositions = [Planet:Float]()
    private var originalTorusRadius = [Planet:CGFloat]()
    private var originalPlanetSize = [Planet:SCNVector3]()
    private let solarSystemNodes: SolarSystemNodes
    
    init(with nodes: SolarSystemNodes) {
        solarSystemNodes = nodes
    }
    
    func pinch(with recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            originalScale = solarSystemNodes.planetoids[Planet.sun]?.scale.x
            for (planet,planetoid) in solarSystemNodes.planetoids {
                guard let planetNode = planetoid.planetNode else {
                    print("there was no node for this polanetoid \(planet.name)")
                    break
                }
                
                // retain the original position
                originalXPositions[planet] = planetNode.position.x
                
                // retain the original torus radius
                if let originalRadius = planetoid.torus?.ringRadius {
                    originalTorusRadius[planet] = originalRadius
                }
                
                // retain the original planet's scale
                originalPlanetSize[planet] = planetNode.scale
            }
        case .changed:
            let scale = Float(recognizer.scale)
            let newScale = scale * originalScale!

            for (planet, node) in solarSystemNodes.planetoids {
                // the path torus
                if let torus = node.torus, let originalRadius = originalTorusRadius[planet] {
                    torus.ringRadius = originalRadius * CGFloat(newScale)
                }
                
                // the planet itself
                if let currentScale = originalPlanetSize[planet] {
                    node.planetNode?.scale = SCNVector3Make(currentScale.x * scale, currentScale.y * scale, currentScale.z * scale)
                }
                
                // the orbit
                guard let planetXPosition = originalXPositions[planet] else {
                    print("\(planet.name) did not have an x position")
                    break
                }
                let newX = planetXPosition * scale
                node.planetNode?.position = SCNVector3Make(newX, 0, 0)
            }
            
        case .ended:
            // proper cleanup
            originalPlanetSize.removeAll()
            originalTorusRadius.removeAll()
            originalXPositions.removeAll()
            
        default:
            print("other pinch")
        }
    }
}
