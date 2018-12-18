//
//  float2Extension.swift
//  ColorBlending
//
//  Created by Brenna Olson on 12/12/18.
//  Copyright © 2018 Brenna Olson. All rights reserved.
//

import simd
import UIKit

extension float2 {
    init(from cgPoint: CGPoint) {
        self.init(Float(cgPoint.x), Float(cgPoint.y))
    }
}
