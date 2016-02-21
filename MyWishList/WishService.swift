//
//  WishListService.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/14/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation

class WishService: SyncService {
    
    static let sharedInstance = WishService()
    
    func createWish(properties: [String : AnyObject?]) {
        let wish = Wish(dictionary: properties, context: sharedContext)
        persistWish(wish)
        
        if (!saveContext()) {
            sendNotification(.Save, status: .LocalFailed, entity: Wish.ENTITY_NAME, additionalInfo: "Failed to save to local DB")
        }
    }
    
    func updateWish(wish: Wish) {
        if let _ = wish.objectId {
            parseClient.updateWish(wish) { response in
                if let wishJson = response.jsonContent() where response.success() {
                    wish.updateFromJson(wishJson)
                    self.saveContext()
                    self.sendNotification(.Save, status: .Successful, entity: Wish.ENTITY_NAME, additionalInfo: "Save successful!")
                } else {
                    self.sendNotification(.Save, status: .RemoteFailed, entity: Wish.ENTITY_NAME, additionalInfo: "Could not persist wish remotely!")
                }
            }
        } else {
            persistWish(wish)
        }
        
        if (!saveContext()) {
            sendNotification(.Save, status: .LocalFailed, entity: Wish.ENTITY_NAME, additionalInfo: "Failed to save to local DB")
        }
    }
    
    private func persistWish(wish: Wish) {
        parseClient.persistWish(wish) { response in
            if let wishJson = response.jsonContent() where response.success() {
                wish.updateFromJson(wishJson)
                self.saveContext()
                self.sendNotification(.Save, status: .Successful, entity: Wish.ENTITY_NAME, additionalInfo: "Save successful!")
            } else {
                self.sendNotification(.Save, status: .RemoteFailed, entity: Wish.ENTITY_NAME, additionalInfo: "Could not persist wish remotely!")
            }
        }
    }
    
    func deleteWish(wish: Wish){
        sharedContext.deleteObject(wish)
        if let objectId = wish.objectId {
            parseClient.deleteWish(objectId) { response in
                if !response.success() {
                    self.sendNotification(.Save, status: .RemoteFailed, entity: Wish.ENTITY_NAME, additionalInfo: "Could not delete wish remotely!")
                }
            }
        }
        
        if (!saveContext()) {
            sendNotification(.Save, status: .LocalFailed, entity: Wish.ENTITY_NAME, additionalInfo: "Failed to save to local DB")
        }
    }
    
    func fetchWishes() {
        if let userId = currentFacebookId {
            fetchWishes(byUserId: userId)
        } else {
            sendNotification(.Fetch, status: .RemoteFailed, entity: Wish.ENTITY_NAME, additionalInfo: "User not logged in!")
        }
    }
    
    func fetchWishes(byUserId userId: String) {
        parseClient.fetchAllWishes(userId) { response in
            if response.success() {
                if let content = response.jsonContent(), results = content["results"] as? [[String : AnyObject]] {
                    for result in results {
                        if let objectId = result[Wish.Keys.objectId] as? String, wish = self.fetchWish(byObjectId: objectId) {
                            wish.updateFromJson(result)
                        } else if let _ = result[Wish.Keys.objectId] as? String {
                            self.createWish(result)
                        }
                    }
                    self.sendNotification(.Fetch, status: .Successful, entity: Wish.ENTITY_NAME, additionalInfo: "Fetched remote data successfully!")
                }
            } else {
                self.sendNotification(.Fetch, status: .RemoteFailed, entity: Wish.ENTITY_NAME, additionalInfo: "Failed fetching wishes from remote")
            }
        }
    }
    
    private func fetchWish(byObjectId objectId : String) -> Wish? {
        if let results = CoreDataManager.sharedInstance.queryEntity(withEntityName: Wish.ENTITY_NAME, withPredicatFormat: "objectId == %@", andArguments: [objectId]) {
            if results.count > 0 {
                return results[0] as? Wish
            }
        }
        return nil
    }
    
}
