//
//  CoreDataManager.swift
//  CoreDataProgressiveMigration
//
//  Created by Nazmul Islam on 18/2/22.
//

import Foundation
import CoreData

class CoreDataManager {
    private let config: CoreDataConfig
    private let saveQueue: OperationQueue
    
    let managedObjectModel: NSManagedObjectModel
    let mainContext: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext
    
    init(config: CoreDataConfig) {
        self.config = config
        let migrator = CoreDataMigrator(config: config)
        
        if migrator.requiresMigration() {
            migrator.migrateStore()
        }
        
        let modelURL = config.modelURL
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to create model from file: \(modelURL)")
        }

        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        do {
            try psc.addPersistentStore(
                ofType: config.storeType.value,
                configurationName: nil,
                at: config.storeURL,
                options: nil
            )
        } catch let error {
            print(error)
            fatalError("Error configuring persistent store: \(error.localizedDescription)")
        }

        let mainMoc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainMoc.persistentStoreCoordinator = psc
        // main moc shoud never have any unsaved changes, should only be used for read
        mainMoc.mergePolicy = NSMergePolicy(merge: .rollbackMergePolicyType)
        
        print(mainMoc.automaticallyMergesChangesFromParent)
        
        let backgroundMoc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundMoc.persistentStoreCoordinator = psc
        // in case of any conflict write entire in memory object graph to persistent store,
        // should not have any conflict because this is the only context that should perform the writing job
        backgroundMoc.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
        
        let saveQueue = OperationQueue()
        saveQueue.maxConcurrentOperationCount = 1
        
        self.managedObjectModel = mom
        self.mainContext = mainMoc
        self.backgroundContext = backgroundMoc
        self.saveQueue = saveQueue
        
        // merge changes from backgroundContext to main context on backgrounnd context save
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(mergeChangesOnMain(_:)),
            name: .NSManagedObjectContextDidSave,
            object: backgroundContext
        )
    }
    
    func readInMain(readBlock: (NSManagedObjectContext) -> Void) {
        mainContext.performAndWait {
            readBlock(mainContext)
        }
    }
    
    func saveInBackground(
        saveBlock: @escaping (NSManagedObjectContext) -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let saveOperation = BlockOperation { [weak self] in
            guard let self = self else { return }

            self.backgroundContext.performAndWait {
                saveBlock(self.backgroundContext)
                
                do {
                    try self.backgroundContext.save()
                    completion(.success(()))
                } catch {
                    print("DATAMANAGER: save failed \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        
        saveQueue.addOperation(saveOperation)
    }
    
    func reset() {
        // TODO: - IMPLEMMENT
        // Ensure the followings:
        // 1. During reset no other operation should run
        // 4. Cancel all pending operations
        // 2. Destroy current store/sqlite file
        // 3. Create new store/sqlite file
        fatalError("NOT IMPLEMENTED")
    }
    
    // MARK: - Helpers
    
    @objc
    private func mergeChangesOnMain(_ notification: Notification) {
        performSyncOnMain {
            mainContext.mergeChanges(fromContextDidSave: notification)
        }
    }
}
