//
//  CoreDataModelVersionProvider.swift
//  CoreDataProgressiveMigration
//
//  Created by Nazmul Islam on 20/2/22.
//

import Foundation
import CoreData

class CoreDataModelVersionProvider {
    private let conifg: CoreDataConfig
    
    init(config: CoreDataConfig) {
        self.conifg = config
    }

    var firstVersion: CoreDataModelVersion {
        return getCoreDataModelVersion(firstVersionNumber)
    }
    
    var latestVersion: CoreDataModelVersion {
        return getCoreDataModelVersion(latestVersionNumber)
    }

    func nextVersion(for version: CoreDataModelVersion) -> CoreDataModelVersion? {
        guard let nextVersionNumber = nextVersionNumber(for: version.number) else {
            return nil
        }

        return getCoreDataModelVersion(nextVersionNumber)
    }
    
    func compatibleVersion(for storeMetadata: [String : Any]) -> CoreDataModelVersion? {
        var currentVersion: CoreDataModelVersion? = firstVersion
        while let version = currentVersion {
            if version.isCompatible(with: storeMetadata) {
                return version
            }
            currentVersion = nextVersion(for: version)
        }
        
        return nil
    }
    
    // MARK: - Helper
    
    private var firstVersionNumber: Int {
//        fatalError("NOT IMPLEMENTED")
        return 1
    }
    
    private var latestVersionNumber: Int {
//        fatalError("NOT IMPLEMENTED")
        return 1
    }

    private func nextVersionNumber(for versionNumber: Int) -> Int? {
//        fatalError("NOT IMPLEMENTED")
        return nil
    }

    private func versionName(for versionNumber: Int) -> String {
//        fatalError("NOT IMPLEMENTED")
        switch versionNumber {
        case 1:
            return conifg.modelName
        default:
            return "\(conifg.modelName)_\(versionNumber)"
        }
    }
    
    private func getCoreDataModelVersion(_ number: Int) -> CoreDataModelVersion {
        let url: URL
        let versionName = versionName(for: number)
        if let omoURL = resourceURL(for: versionName, withExtension: "omo") {
            print("MIGRATION: found omoURL")
            url = omoURL
        } else if let momURL = resourceURL(for: versionName, withExtension: "mom") {
            print("MIGRATION: found momURL")
            url = momURL
        } else {
            fatalError("MIGRATION: unable to find model url")
        }

        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("MIGRATION: unable to load model from: \(url.path)")
        }

        return CoreDataModelVersion(
            number: number,
            name: versionName,
            managedObjectModel: model
        )
    }
    
    private func resourceURL(for name: String, withExtension ext: String) -> URL? {
        Bundle.main.url(
            forResource: name,
            withExtension: ext,
            subdirectory: conifg.modelDirectory
        )
    }
}
