//
//  CollisionTypes.swift
//  iOSMeerkats
//
//  Created by Joshua Woods on 9/7/17.
//  Copyright © 2017 Anthony Cohn-Richardby. All rights reserved.
//

import Foundation

struct CollisionTypes : OptionSet {
    let rawValue: Int
    
    static let bottom  = CollisionTypes(rawValue: 1 << 0)
    static let shape = CollisionTypes(rawValue: 1 << 1)
}
