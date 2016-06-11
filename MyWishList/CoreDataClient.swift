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
    
    func grant(wish wish: Wish, grantedBy user: UserEntity, forFriend friend: UserEntity) -> GrantedWishEntity? {
        if let wishEntity = upsert(wish: wish, forUser: friend) {
            return upsertGrantedWish(wishEntity, grantedBy: user)
        }
        return nil
    }
    
    // MARK: UserEntity functions
    func upsert(user user: User) -> UserEntity? {
        return upsert(UserEntity.ENTITY_NAME, idAttributeName: User.Keys.id, idValue: user.id,
                      attributes: user.attributes) as? UserEntity
    }
    
    func upsert(friend friend: User, ofUser user: UserEntity) -> FriendshipEntity? {
        if let friendEntity = upsert(UserEntity.ENTITY_NAME, idAttributeName: User.Keys.id, idValue: friend.id,
                                     attributes: friend.attributes) as? UserEntity {
            return upsertFriendship(user, friend: friendEntity)
        }
        return nil
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
    
    private func attributesWithFriend(attributes: [String:  AnyObject], friend: UserEntity) -> [String : AnyObject] {
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
    
    private func upsertFriendship(user: UserEntity, friend: UserEntity) -> FriendshipEntity? {
        guard let existing = findOne(FriendshipEntity.ENTITY_NAME, predicateFormat: "%K = %@ AND %K = %@", arguments: ["user", user, "friend", friend]) else {
            return FriendshipEntity(user: user, friend: friend, insertIntoManagedObjectContext: sharedContext)
        }
        
        return existing as? FriendshipEntity
    }
    
    private func upsertGrantedWish(wish: WishEntity, grantedBy: UserEntity) -> GrantedWishEntity? {
        guard let existing = findOne(GrantedWishEntity.ENTITY_NAME, predicateFormat: "%K = %@ AND %K = %@", arguments: ["wish", wish, "grantedBy", grantedBy]) else {
            return GrantedWishEntity(wish: wish, grantedBy: grantedBy, insertIntoManagedObjectContext: sharedContext)
        }
        
        return existing as? GrantedWishEntity
    }
    
    private func findOne(entityName: String, idAttributeName: String, idValue: String) -> NSManagedObject? {
        return findOne(entityName, predicateFormat: "%K = %@", arguments: [idAttributeName, idValue])
    }

    private func findOne(entityName: String, predicateFormat: String, arguments: [AnyObject]) -> NSManagedObject? {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: sharedContext)
        fetchRequest.predicate = NSPredicate(format: predicateFormat, argumentArray: arguments)
        
        do {
            let result = try sharedContext.executeFetchRequest(fetchRequest)
            return result.count > 0 ? result[0] as? NSManagedObject : nil
        } catch {
            let fetchError = error as NSError
            print("Error fetching \(entityName) args: \(arguments) error: \(fetchError)")
            return nil
        }
        
    }
    
    
    
    
    
}
