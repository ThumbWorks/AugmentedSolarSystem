//
//  ScaleReference.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 8/3/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation

class ScaleReference {
    /**
     * Given a float in meters, return a string describint
     * an object whose radius is roughly that size
     */
    class func objectSizeDescription(for size: Float) -> String {
        switch size {
        case let x where x < 0.001: // millimeter
            return "It is the size of a pinhead or a flea"
            
        case let x where x >= 0.01: // centimeter
            return "It is the size of a large mosquito" // 1.5 cm
            
        case let x where x >= 0.02: // 2 centimeters
            return "It is the average width of a human finger"
            
        case let x where x >= 0.033:
            return "It is the width of 35mm film"

        case let x where x >= 0.038:
            return "It is the size of a golf ball"  // 4.3 cm
            
        case let x where x >= 0.06: // 7.3 to 7.5 cm
            return "It is the size of a baseball"
            
        case let x where x >= 0.085:
            return "It is the width of a credit card"
            
        case let x where x >= 0.1:
            return "It is a decimeter"
            
        case let x where x >= 0.11:
            return "It is the diameter of a compact disc" // 0.12
        
        case let x where x >= 0.13:
            return "It is the length of a bic pen with cap" // 15 cm
            
        case let x where x >= 10:
            return "It is is 10 meters"
        
        default:
            return "It is very large"
        }
    }
}
