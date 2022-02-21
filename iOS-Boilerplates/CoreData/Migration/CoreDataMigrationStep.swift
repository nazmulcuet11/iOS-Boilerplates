//
//  CoreDataMigrationStep.swift
//  CoreDataProgressiveMigration
//
//  Created by Nazmul Islam on 18/2/22.
//

import Foundation
import CoreData

struct CoreDataMigrationStep {
    let sourceVersion: CoreDataModelVersion
    let destinationVersion: CoreDataModelVersion
    let sourceModel: NSManagedObjectModel
    let destinationModel: NSManagedObjectModel
    let mappingModel: NSMappingModel
    
    // MARK: Init
    
    init(
        sourceVersion: CoreDataModelVersion,
        destinationVersion: CoreDataModelVersion
    ) {
        let sourceModel = sourceVersion.managedObjectModel
        let destinationModel = destinationVersion.managedObjectModel
        
        guard let mappingModel = getMappingModel(from: sourceModel, to: destinationModel) else {
            fatalError("MIGRATION: Could not generate mapping model for: \(sourceVersion.number) to \(destinationVersion.number)")
        }
        
        self.sourceVersion = sourceVersion
        self.destinationVersion = destinationVersion
        self.sourceModel = sourceModel
        self.destinationModel = destinationModel
        self.mappingModel = mappingModel
    }
}

fileprivate func getMappingModel(
    from sourceModel: NSManagedObjectModel,
    to destinationModel: NSManagedObjectModel
) -> NSMappingModel? {
    
    if let customMapping = customMappingModel(from: sourceModel, to: destinationModel) {
        print("MIGRATION: found custom mapping model")
        pruneEntityMappings(customMapping)
        return customMapping
    }
    
    if let inferredMapping = inferredMappingModel(from: sourceModel, to: destinationModel) {
        print("MIGRATION: found inferred mapping model")
        return inferredMapping
    }
    
    return nil
}

/// Coredata requires that entityMigrationPolicyClassName to be sepcified with full class name, this could be a problem to define in .xcmappingmodel file in the following scenario. Let's assume we have multiple target. Now our entityMigrationPolicyClassName will different based on the target, e.g target1 would be target1.<clas name>, target2 would be target2.<class name>. As we can not define two different entityMigrationPolicyClassName in the same .xcmappingmodel we would need to duplicate .xcmappingmodel file for each target and specify appriate class name for each target. On the other hand we can just keep <clas name> in the .xcmappingmodel file and later in the code prepend module name/target name based on the active target using the following function.
///
/// - Parameter mappingModel: mapping model where entity mapping pruning is required
fileprivate func pruneEntityMappings(_ mappingModel: NSMappingModel) {
    
    guard let namespace = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String else {
        print("MIGRATION: namespace not found")
        return
    }
    
    // Coredata requieres any special characters in the namespace to be replaced with "_"
    let specialChars = [" ", "-", "."]
    var modifiedNameSpace = namespace
    for specialChar in specialChars {
        modifiedNameSpace = modifiedNameSpace.replacingOccurrences(of: specialChar, with: "_")
    }
    
    for mapping in mappingModel.entityMappings {
        if let className = mapping.entityMigrationPolicyClassName {
            let fullClassName = "\(modifiedNameSpace).\(className)"
            print("MIGRATION: className: \(className)")
            print("MIGRATION: fullClassName: \(fullClassName)")

            mapping.entityMigrationPolicyClassName = fullClassName
        }
    }
}

fileprivate func customMappingModel(
    from sourceModel: NSManagedObjectModel,
    to destinationModel: NSManagedObjectModel
) -> NSMappingModel? {
    
    return NSMappingModel(
        from: [Bundle.main],
        forSourceModel: sourceModel,
        destinationModel: destinationModel
    )
}

fileprivate func inferredMappingModel(
    from sourceModel: NSManagedObjectModel,
    to destinationModel: NSManagedObjectModel
) -> NSMappingModel? {
    
    return try? NSMappingModel.inferredMappingModel(
        forSourceModel: sourceModel,
        destinationModel: destinationModel
    )
}
