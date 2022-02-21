//
//  CoreDataMigrationVersion.swift
//  CoreDataProgressiveMigration
//
//  Created by Nazmul Islam on 18/2/22.
//

import Foundation
import CoreData

struct CoreDataModelVersion {
    let number: Int
    let name: String
    let managedObjectModel: NSManagedObjectModel

    func isCompatible(with storeMetadata: [String : Any]) -> Bool {
        return managedObjectModel.isConfiguration(
            withName: nil,
            compatibleWithStoreMetadata: storeMetadata
        )
    }
}

extension CoreDataModelVersion: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.number < rhs.number
    }
}

extension CoreDataModelVersion: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.number == rhs.number
    }
}
