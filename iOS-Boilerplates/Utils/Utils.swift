//
//  Utils.swift
//  CoreDataProgressiveMigration
//
//  Created by Nazmul Islam on 21/2/22.
//

import Foundation

func performSyncOnMain(_ block: () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync {
            block()
        }
    }
}
