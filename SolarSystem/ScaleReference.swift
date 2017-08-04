//
//  ScaleReference.swift
//  SolarSystem
//
//  Created by Roderic Campbell on 8/3/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation

class ScaleReference {
    static let pin:Float = 0.001
    static let mosquito:Float = 0.01
    static let finger:Float = 0.02
    static let film:Float = 0.033
    static let golfBall:Float = 0.038
    static let baseball:Float = 0.06
    static let creditCard:Float = 0.085
    static let compactDisc:Float = 0.11
    static let bicPen:Float = 0.13
    /**
     * Given a float in meters, return a string describint
     * an object whose radius is roughly that size
     */
    class func objectSizeDescription(for size: Float) -> String {
        print(size)
        switch size {
        case let x where x < pin: // millimeter
            return "It is the size of a pinhead or a flea"
        case mosquito...finger:
            return "It is the size of a large mosquito" // 1.5 cm

//        case let x where x >= mosquito && x < finger: // centimeter
            
        case finger...film: // 2 centimeters
            return "It is the average width of a human finger"
            
        case let x where x >= film && x < golfBall:
            return "It is the width of 35mm film"

        case let x where x >= golfBall && x < baseball:
            return "It is the size of a golf ball"  // 4.3 cm
            
        case let x where x >= baseball && x < compactDisc: // 7.3 to 7.5 cm
            return "It is the size of a baseball"
            
        case let x where x >= creditCard && x < compactDisc:
            return "It is the width of a credit card"
            
        case let x where x >= compactDisc && x < bicPen:
            return "It is the diameter of a compact disc" // 0.12
        
        case let x where x >= bicPen:
            return "It is the length of a bic pen with cap" // 15 cm
            
        case let x where x >= 10:
            return "It is is 10 meters"
        
        default:
            return "It is very large"
        }
    }
}
