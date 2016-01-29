//
//  SyncService.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/24/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData

let SYNC_RESULT_NOTIFICATION = "SyncResultNotification"

class SyncResult {
    let action : SyncAction
    let status : SyncStatus
    let additionalInfo : String
    init(action : SyncAction, status : SyncStatus, additionalInfo : String){
        self.action = action
        self.status = status
        self.additionalInfo = additionalInfo
    }
}

enum SyncAction {
    case Save
    case Fetch
}

enum SyncStatus {
    case Successful
    case RemoteFailed
    case LocalFailed
}

class SyncService {
    
    static let sharedInstance = SyncService()
    
    var facebookUserId: String? // TODO, this all seems awkward, need to fix!
    
    var parseClient: ParseClient {
        return ParseClient.sharedInstance
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    func setFacebookUserId(userId: String) {
        facebookUserId = userId
    }
    
    func createWish(properties: [String : AnyObject?]) {
        let wish = Wish(dictionary: properties, context: sharedContext)
        
        if let userId = facebookUserId {
            wish.userId = userId
            persistWish(wish)
        } else {
            sendNotification(.Save, status: .RemoteFailed, additionalInfo: "User not logged in!")
        }
        
        if (!saveContext()) {
            sendNotification(.Save, status: .LocalFailed, additionalInfo: "Failed to save to local DB")
        }
    }
    
    func updateWish(wish: Wish) {
        if let _ = wish.objectId {
            parseClient.updateWish(wish) { response in
                if let wishJson = response.jsonContent() where response.success() {
                    wish.updateFromJson(wishJson)
                    self.saveContext()
                    self.sendNotification(.Save, status: .Successful, additionalInfo: "Save successful!")
                } else {
                    self.sendNotification(.Save, status: .RemoteFailed, additionalInfo: "Could not persist wish remotely!")
                }
            }
        } else {
            persistWish(wish)
        }
        
        if (!saveContext()) {
            sendNotification(.Save, status: .LocalFailed, additionalInfo: "Failed to save to local DB")
        }
    }
    
    private func persistWish(wish: Wish) {
        parseClient.persistWish(wish) { response in
            if let wishJson = response.jsonContent() where response.success() {
                wish.updateFromJson(wishJson)
                self.saveContext()
                self.sendNotification(.Save, status: .Successful, additionalInfo: "Save successful!")
            } else {
                self.sendNotification(.Save, status: .RemoteFailed, additionalInfo: "Could not persist wish remotely!")
            }
        }
    }
    
    func deleteWish(wish: Wish){
        sharedContext.deleteObject(wish)
        if let objectId = wish.objectId {
            parseClient.deleteWish(objectId) { response in
                if !response.success() {
                    self.sendNotification(.Save, status: .RemoteFailed, additionalInfo: "Could not delete wish remotely!")
                }
            }
        }
        
        if (!saveContext()) {
            sendNotification(.Save, status: .LocalFailed, additionalInfo: "Failed to save to local DB")
        }
    }
    
    func fetchRemoteData() {
        // fetch wishes
        if let userId = facebookUserId {
            parseClient.fetchAllWishes(userId) { response in
                if response.success() {
                    if let content = response.jsonContent(), results = content["results"] as? [[String : AnyObject]] {
                        results.forEach({ result in
                            if let objectId = result[Wish.Keys.objectId] as? String, wish = self.fetchWish(byObjectId: objectId) {
                                wish.updateFromJson(result)
                            }
                        })
                    }
                } else {
                    self.sendNotification(.Fetch, status: .RemoteFailed, additionalInfo: "Failed fetching wishes from remote")
                }
            }
        } else {
            sendNotification(.Fetch, status: .RemoteFailed, additionalInfo: "User not logged in!")
        }
        // todo fetch wish promises
    }
    
    private func fetchWish(byObjectId objectId : String) -> Wish? {
        let fetchRequest = NSFetchRequest(entityName: Wish.ENTITY_NAME)
        fetchRequest.predicate = NSPredicate(format: "objectId == %@", objectId)
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest)
            return results[0] as? Wish
        } catch {
            let nserror = error as NSError
            print("Error fetching wish: \(nserror)")
        }
        return nil
    }
    
    private func saveContext() -> Bool {
        return CoreDataManager.sharedInstance.saveContext()
    }
    
    private func sendNotification(action: SyncAction, status: SyncStatus, additionalInfo: String) {
        let notification = NSNotification(name: SYNC_RESULT_NOTIFICATION, object: SyncResult(action: action, status: status, additionalInfo: additionalInfo))
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    // TODO: need network activity indicator
    
}
