//
//  CoreDataClient.swift
//  MyWishList
//
//  Created by Victor Guthrie on 4/18/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData

class CoreDataClient {
    
    static let sharedInstance = CoreDataClient()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    // MARK: WishEntity functions
    func upsert(wish wish: Wish, forUser user: UserEntity) -> WishEntity? {
        return upsert(WishEntity.ENTITY_NAME, idAttributeName: Wish.Keys.id, idValue: wish.id!,
               attributes: attributesWithUser(wish.attributes, user: user)) as? WishEntity
    }
    
    func delete(wish wish: Wish) {
        if let entity = findOne(WishEntity.ENTITY_NAME, idAttributeName: Wish.Keys.id, idValue: wish.id!) {
            delete(entity)
        }
    }
    
    func grant(wish wish: Wish, grantedBy user: UserEntity, forFriend friend: FriendEntity) -> GrantedWishEntity? {
        let obj = upsert(GrantedWishEntity.ENTITY_NAME, idAttributeName: Wish.Keys.id, idValue: wish.id!,
               attributes: attributesWithFriend(
                attributesWithGrantedByUser(wish.attributes, user: user),
                friend: friend))
        return obj as? GrantedWishEntity
    }
    
    // MARK: UserEntity functions
    func upsert(user user: User) -> UserEntity? {
        return upsert(UserEntity.ENTITY_NAME, idAttributeName: User.Keys.id, idValue: user.id,
                      attributes: user.attributes) as? UserEntity
    }
    
    func upsert(friends friends: [User], ofUser user: UserEntity) {
        friends.forEach { (friend) in
            upsert(FriendEntity.ENTITY_NAME, idAttributeName: User.Keys.id, idValue: friend.id,
                attributes: attributesWithUser(friend.attributes, user: user))
        }
    }
        
    func find(userById userId: String) -> UserEntity? {
        return findOne(UserEntity.ENTITY_NAME, idAttributeName: User.Keys.id, idValue: userId) as? UserEntity
    }
    
    private func attributesWithUser(attributes: [String:  AnyObject], user: UserEntity) -> [String : AnyObject] {
        var attributesWithUser: [String : AnyObject] = [User.Keys.user: user]
        attributes.forEach({ (key, value) in
            attributesWithUser[key] = value
        })
        return attributesWithUser
    }
    
    private func attributesWithGrantedByUser(attributes: [String:  AnyObject], user: UserEntity) -> [String : AnyObject] {
        var attributesWithUser: [String : AnyObject] = [Wish.Keys.grantedBy: user]
        attributes.forEach({ (key, value) in
            attributesWithUser[key] = value
        })
        return attributesWithUser
    }
    
    private func attributesWithFriend(attributes: [String:  AnyObject], friend: FriendEntity) -> [String : AnyObject] {
        var attributesWithFriend: [String : AnyObject] = [Wish.Keys.friend: friend]
        attributes.forEach({ (key, value) in
            attributesWithFriend[key] = value
        })
        return attributesWithFriend
    }
    
    // MARK: General Core Data functions
    func delete(object: NSManagedObject) {
        sharedContext.deleteObject(object)
    }
    
    func saveContext() {
        CoreDataManager.sharedInstance.saveContext()
    }
    
    private func upsert(entityName: String, idAttributeName: String, idValue: String, attributes: [String: AnyObject]) -> NSManagedObject {
        if let existing = findOne(entityName, idAttributeName: idAttributeName, idValue: idValue) {
            for (name, value) in attributes {
                existing.setValue(value, forKey: name)
            }
            return existing
        } else {
            let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: sharedContext)!
            let newEntity = NSManagedObject(entity: entity, insertIntoManagedObjectContext: sharedContext)
            for (name, value) in attributes {
                newEntity.setValue(value, forKey: name)
            }
            return newEntity
        }
    }
    
    private func findOne(entityName: String, idAttributeName: String, idValue: String) -> NSManagedObject? {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: sharedContext)
        fetchRequest.predicate = NSPredicate(format: "%K = %@", idAttributeName, idValue)
        
        do {
            let result = try sharedContext.executeFetchRequest(fetchRequest)
            return result.count > 0 ? result[0] as? NSManagedObject : nil
        } catch {
            let fetchError = error as NSError
            print("Error fetching \(entityName) \(idAttributeName)=\(idValue): \(fetchError)")
            return nil
        }
    }
    
}
