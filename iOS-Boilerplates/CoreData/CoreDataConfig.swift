//
//  CoreDataConfig.swift
//  CoreDataProgressiveMigration
//
//  Created by Nazmul Islam on 18/2/22.
//

import Foundation
import CoreData

enum CoreDataStoreType {
    case sqlite
    case inMemory
    
    var value: String {
        switch self {
        case .sqlite: return NSSQLiteStoreType
        case .inMemory: return NSInMemoryStoreType
        }
    }
}

struct CoreDataConfig {
    /// Top level xcdatamodeld (aka the schema) file name
    let modelName: String
    /// Top level directory of the xcdatamodeld  (aka the schema) file
    let modelDirectory: String
    let modelURL: URL
    let storeURL: URL
    let storeType: CoreDataStoreType
    
    init(
        modelName: String,
        modelDirectory: String,
        modelURL: URL,
        storeURL: URL,
        storeType: CoreDataStoreType
    ) {
        self.modelName = modelName
        self.modelDirectory = modelDirectory
        self.modelURL = modelURL
        self.storeURL = storeURL
        self.storeType = storeType
    }
    
    /// Convenience initializer
    init(modelName: String) {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            fatalError("Failed to find data model url")
        }
        
        let appSupportDir = FileManager.default.documentsDirectory
        let storeName = "\(modelName).sqlite"
        let storeURL = appSupportDir
            .appendingPathComponent(storeName)
        
        self.modelName = modelName
        self.modelDirectory = "\(modelName).momd"
        self.modelURL = modelURL
        self.storeURL = storeURL
        self.storeType = .sqlite
    }
}
