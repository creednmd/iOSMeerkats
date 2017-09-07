//
//  Float+Extension.swift
//  iOSMeerkats
//
//  Created by Joshua Woods on 9/7/17.
//  Copyright © 2017 Anthony Cohn-Richardby. All rights reserved.
//

import Foundation

extension Float {
    static func random(min: Float, max: Float) -> Float {
        let f = Float(arc4random()) / Float(UInt32.max)
        let d = max - min
        let off = f * d
        return min + off
    }
}
