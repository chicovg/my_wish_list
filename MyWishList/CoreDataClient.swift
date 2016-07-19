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
    func upsert(wish wish: Wish, forUser user: User) -> WishEntity? {
        if let userEntity = upsert(user: user) {
            if let wishEntity = upsert(WishEntity.ENTITY_NAME, idAttributeName: Wish.Keys.id, idValue: wish.id!,
                                       attributes: attributes(wish.attributes, withUser: userEntity)) as? WishEntity {
                if let promisedBy = wish.promisedBy, promisedByEntity = upsert(user: promisedBy), promisedOn = wish.promisedOn {
                    upsertWishPromise(wishEntity, promisedBy: promisedByEntity, promisedOn: promisedOn)
                } else if let wishPromiseEntity = wishEntity.wishPromise {
                    delete(wishPromiseEntity)
                }
                return wishEntity
            }
        }
        return nil
    }
    
    func delete(wish wish: Wish, forUser user: User) {
        if let _ = upsert(user: user), entity = findOne(WishEntity.ENTITY_NAME, idAttributeName: Wish.Keys.id, idValue: wish.id!) {
            delete(entity)
        }
    }
    
    func promise(wish wish: Wish, promisedBy user: User, forFriend friend: User) -> WishPromiseEntity? {
        if let _ = upsert(user: user), wishEntity = upsert(wish: wish, forUser: friend), promisedBy = wish.promisedBy, promisedByEntity = upsert(user: promisedBy), promisedOn = wish.promisedOn {
            return upsertWishPromise(wishEntity, promisedBy: promisedByEntity, promisedOn: promisedOn)
        }
        return nil
    }
    
    // MARK: UserEntity functions
    func upsert(user user: User) -> UserEntity? {
        return upsert(UserEntity.ENTITY_NAME, idAttributeName: User.Keys.id, idValue: user.id,
                      attributes: user.attributes) as? UserEntity
    }
    
    func upsert(friend friend: User, ofUser user: User) -> FriendshipEntity? {
        if let userEntity = upsert(user: user), friendEntity = upsert(UserEntity.ENTITY_NAME, idAttributeName: User.Keys.id, idValue: friend.id, attributes: friend.attributes) as? UserEntity {
            return upsertFriendship(userEntity, friend: friendEntity)
        }
        return nil
    }
    
    func find(userById userId: String) -> UserEntity? {
        return findOne(UserEntity.ENTITY_NAME, idAttributeName: User.Keys.id, idValue: userId) as? UserEntity
    }
    
    func delete(user: User) {
        if let userEntity = find(userById: user.id) {
            delete(userEntity)
        }
    }
    
    private func attributes(attributes: [String:  AnyObject], withUser user: UserEntity) -> [String : AnyObject] {
        return appendedAttributes(attributes, additionalAttributes: [User.Keys.user: user])
    }
    
    private func attributes(attributes: [String:  AnyObject], withFriend friend: UserEntity) -> [String : AnyObject] {
        return appendedAttributes(attributes, additionalAttributes: [Wish.Keys.friend: friend])
    }
    
    private func appendedAttributes(attributes: [String : AnyObject], additionalAttributes: [String : AnyObject]) -> [String : AnyObject] {
        var appendedAttributes: [String: AnyObject] = [:]
        attributes.forEach({ (key, value) in
            appendedAttributes[key] = value
        })
        additionalAttributes.forEach({ (key, value) in
            appendedAttributes[key] = value
        })
        return appendedAttributes
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
    
    private func upsertWishPromise(wish: WishEntity, promisedBy: UserEntity, promisedOn: NSDate) -> WishPromiseEntity? {
        guard let existing = findOne(WishPromiseEntity.ENTITY_NAME, predicateFormat: "%K = %@ AND %K = %@", arguments: ["wish", wish, "promisedBy", promisedBy]) else {
            return WishPromiseEntity(wish: wish, promisedBy: promisedBy, promisedOn: promisedOn, grantedOn: nil, insertIntoManagedObjectContext: sharedContext)
        }
        
        return existing as? WishPromiseEntity
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
