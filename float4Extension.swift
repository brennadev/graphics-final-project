//
//  float4Extension.swift
//  Patterns
//
//  Created by Brenna Olson on 8/19/18.
//  Copyright © 2018 Brenna Olson. All rights reserved.
//
//  Existing stuff of mine to make hooking between buffer color representation and UI easier (so essentially, this is library code, but it's my own)
//  DO NOT COPY THIS FILE other than for grading purposes for this assignment

import simd
import UIKit

// convenience interface when using float4 for color values
extension float4 {
    static let white = float4(1, 1, 1, 1)
    static let black = float4(0, 0, 0, 1)
    static let blue = float4(0, 0, 1, 1)
    static let green = float4(0, 1, 0, 1)
    static let pink = float4(1, 0, 1, 1)
    static let cyan = float4(0, 1, 1, 1)
    static let gray = float4(0.5, 0.5, 0.5, 1)
    
    /// Initializer that behaves the same as init(_:_:_:_:) but shows color component labels in the parameters to make intention clearer
    init(red: Float, green: Float, blue: Float, alpha: Float) {
        self.init(red, green, blue, alpha)
    }
    
    /// Convenience for use with Metal - get a simd float4 representation of a color. The parts of the color will be in RGBA order.
    init(from color: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: Float(red), green: Float(green), blue: Float(blue), alpha: Float(alpha))
    }
    
    
    /// Red component of a color
    var red: Float {
        get {
            return self[0]
        } set {
            self[0] = newValue
        }
    }
    
    /// Green component of a color
    var green: Float {
        get {
            return self[1]
        } set {
            self[1] = newValue
        }
    }
    
    /// Blue component of a color
    var blue: Float {
        get {
            return self[2]
        } set {
            self[2] = newValue
        }
    }
    
    /// Alpha component of a color
    var alpha: Float {
        get {
            return self[3]
        } set {
            self[3] = newValue
        }
    }
}

extension UIColor {
    /// Convenience for use with Metal - use a simd float4 to get a UIColor instance in display P3 space
    /// - parameter float4: simd float4 representation of a color. The format is assumed to be RGBA.
    convenience init(from float4: float4) {
        self.init(displayP3Red: CGFloat(float4.red), green: CGFloat(float4.green), blue: CGFloat(float4.blue), alpha: CGFloat(float4.alpha))
    }
}
