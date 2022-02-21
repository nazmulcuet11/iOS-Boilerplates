//
//  CoreDataMigrator.swift
//  CoreDataProgressiveMigration
//
//  Created by Nazmul Islam on 18/2/22.
//

import Foundation
import CoreData

class CoreDataMigrator {
    private let config: CoreDataConfig
    private var storeURL: URL { config.storeURL }
    private let fileManager = FileManager.default
    private let versionProvider: CoreDataModelVersionProvider

    init(config: CoreDataConfig) {
        self.config = config
        self.versionProvider = CoreDataModelVersionProvider(config: config)
    }
    
    /// Check if the NSPersistentStore at storeURL needs migration to attain specified version
    /// - Returns: true if store requires migration, false otherwise
    func requiresMigration() -> Bool {
        print("MIGRATION: \(#function)")
        
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL) else {
            print("MIGRATION: could not find metadata")
            return false
        }
        
        guard let currentVersion = versionProvider.compatibleVersion(for: metadata) else {
            fatalError("MIGRATION: could not find compatible version for metadata: \(metadata)")
        }
        
        print("MIGRATION: currentVersion: \(currentVersion.number)")
        print("MIGRATION: latestVersion: \(versionProvider.latestVersion.number)")
        
        return currentVersion < versionProvider.latestVersion
    }
    
    func migrateStore() {
        print("MIGRATION: \(#function)")
        print("MIGRATION: starting")
        
        do {
            backupCurrentStore()
            try migrateStore(at: storeURL, to: versionProvider.latestVersion)
            deleteBackupStore()
        } catch {
            restoreCurrentStore()
            fatalError("MIGRATION: failed, error: \(error.localizedDescription)")
        }
        
        print("MIGRATION: end")
    }
    
    private func migrateStore(at storeURL: URL, to version: CoreDataModelVersion) throws {
        print("MIGRATION: \(#function)")
        
        forceWALCheckpointingForStore(at: storeURL)
        
        var currentURL = storeURL
        let migrationSteps = self.migrationStepsForStore(at: storeURL, toVersion: version)
        
        for step in migrationSteps {
            print("MIGRATION: running migration step: \(step.sourceVersion.number) to \(step.destinationVersion.number)")
            
            let manager = NSMigrationManager(
                sourceModel: step.sourceModel,
                destinationModel: step.destinationModel
            )
            
            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent(UUID().uuidString)
            
            try manager.migrateStore(
                from: currentURL,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: step.mappingModel,
                toDestinationURL: destinationURL,
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil
            )
            
            if currentURL != storeURL {
                //Destroy intermediate step's store
                NSPersistentStoreCoordinator.destroyStore(at: currentURL)
            }
            
            currentURL = destinationURL
        }
        
        NSPersistentStoreCoordinator.replaceStore(at: storeURL, withStoreAt: currentURL)
        
        if (currentURL != storeURL) {
            NSPersistentStoreCoordinator.destroyStore(at: currentURL)
        }
    }
    
    private func migrationStepsForStore(
        at storeURL: URL,
        toVersion destinationVersion: CoreDataModelVersion
    ) -> [CoreDataMigrationStep] {
        
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL),
              let sourceVersion = versionProvider.compatibleVersion(for: metadata)
        else {
            fatalError("MIGRATION: unknown store version at URL \(storeURL)")
        }
        
        return migrationSteps(from: sourceVersion, to: destinationVersion)
    }
    
    private func migrationSteps(
        from sourceVersion: CoreDataModelVersion,
        to destinationVersion: CoreDataModelVersion
    ) -> [CoreDataMigrationStep] {
        
        var currentVersion = sourceVersion
        var migrationSteps = [CoreDataMigrationStep]()
        
        while currentVersion < destinationVersion,
                let nextVersion = versionProvider.nextVersion(for: currentVersion)
        {
            print("MIGRATION: creating step: \(currentVersion.number) -> \(nextVersion.number)")
            
            let migrationStep = CoreDataMigrationStep(
                sourceVersion: currentVersion,
                destinationVersion: nextVersion
            )
            migrationSteps.append(migrationStep)
            currentVersion = nextVersion
        }
        
        return migrationSteps
    }

    /// Since iOS 7, Core Data has used the Write-Ahead Logging (WAL) option on SQLite stores to provide the ability to recover from crashes by allowing changes to be rolled back until the database is stable. In WAL mode the changes are first written to the sqlite-wal file and at some future date those changes are transferred to the sqlite file. We need to force any data in the sqlite-wal file into the sqlite file before we perform a migration - a process known as checkpointing.
    /// - Parameter storeURL: store url
    private func forceWALCheckpointingForStore(at storeURL: URL) {
        print("MIGRATION: \(#function)")
        
        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL),
              let currentModel = compatibleModel(for: metadata)
        else {
            print("MIGRATION: can't forceWALCheckpointingForStore, required info not found")
            return
        }
        
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)
            
            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store = persistentStoreCoordinator.addPersistentStore(at: storeURL, options: options)
            try persistentStoreCoordinator.remove(store)
            print("MIGRATION: forceWALCheckpointingForStore success")
            
        } catch {
            fatalError("MIGRATION: failed to force WAL checkpointing, error: \(error.localizedDescription)")
        }
    }
    
    private var backupStoreURL: URL {
        let backupPath = storeURL.path.appending(".backup")
        return URL(fileURLWithPath: backupPath)
    }
    
    private func backupCurrentStore() {
        do {
            try fileManager.copyAndOverwriteItem(at: storeURL, to: backupStoreURL)
            print("MIGRATION: backedup current store at: \(backupStoreURL.path)")
        } catch {
            fatalError("MIGRATION: failed to backup: \(error.localizedDescription)")
        }
    }
    
    private func restoreCurrentStore() {
        guard fileManager.fileExists(atPath: backupStoreURL.path) else {
            fatalError("MIGRATION: No backup file to restore")
        }
        
        do {
            try fileManager.moveItem(at: backupStoreURL, to: storeURL)
            print("MIGRATION: restore success at \(storeURL.path)")
        } catch {
            fatalError("MIGRATION: failed to restore: \(error.localizedDescription)")
        }
    }
    
    private func deleteBackupStore() {
        do {
            try fileManager.removeFileIfExists(at: backupStoreURL)
            print("MIGRATION: deleted store from \(backupStoreURL.path)")
        } catch {
            print("MIGRATION: failed to delete: \(error.localizedDescription)")
        }
    }
    
    private func compatibleModel(for metadata: [String : Any]) -> NSManagedObjectModel? {
        let mainBundle = Bundle.main
        return NSManagedObjectModel.mergedModel(
            from: [mainBundle],
            forStoreMetadata: metadata
        )
    }
}
