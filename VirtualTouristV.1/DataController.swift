//
//  DataController.swift
//  VirtualTouristV.1
//
//  Created by salma on 25/12/1441 AH.
//  Copyright © 1441 salma. All rights reserved.
//

import Foundation
import UIKit
import CoreData


 class DataController {
       
    

     let persistentContainer:NSPersistentContainer
        
        var viewContext:NSManagedObjectContext {
            return persistentContainer.viewContext
        }
        
        let backgroundContext:NSManagedObjectContext!
        
        init(modelName:String) {
            persistentContainer = NSPersistentContainer(name: modelName)
            
            backgroundContext = persistentContainer.newBackgroundContext()
        }
        
      func configureContexts() {
            viewContext.automaticallyMergesChangesFromParent = true
            backgroundContext.automaticallyMergesChangesFromParent = true
            
            backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        }
        
     func load(completion: (() -> Void)? = nil) {
            persistentContainer.loadPersistentStores { storeDescription, error in
                guard error == nil else {
                    fatalError(error!.localizedDescription)
                }
                self.autoSaveViewContext()
                self.configureContexts()
                completion?()
            }
        }
        
    func fetchPins(viewContext: NSManagedObjectContext)->[Pin]{
            let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
            if let fetchedPins = try? viewContext.fetch(fetchRequest){
                return fetchedPins
            }
            
            return []
        }
    }

    // MARK: - Autosaving

    extension DataController {
        func autoSaveViewContext(interval:TimeInterval = 30) {
            print("autosaving")
            
            guard interval > 0 else {
                print("cannot set negative autosave interval")
                return
            }
            
            if viewContext.hasChanges {
                try? viewContext.save()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                self.autoSaveViewContext(interval: interval)
            }
        }

}


