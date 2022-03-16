//
//  Weak.swift
//  SecureChat
//
//  Created by Nazmul Islam on 18/8/20.
//  Copyright © 2020 TigerIT Foundation. All rights reserved.
//

import Foundation

struct Weak<T> {
    private weak var _reference: AnyObject?

    init(_ object: T) {
        _reference = object as AnyObject
    }
    var reference: T? { _reference as? T }
}
