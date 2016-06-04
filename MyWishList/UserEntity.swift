//
//  UserEntity.swift
//  MyWishList
//
//  Created by Victor Guthrie on 5/14/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData


class UserEntity: NSManagedObject {
    
    static let ENTITY_NAME = "UserEntity"

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(entity: NSEntityDescription, user: User, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.id = user.id
        self.name = user.name
        self.pictureUrl = user.pictureUrl
        self.friends = []
        self.wishes = []
    }
    
    convenience init(user: User, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entityForName(UserEntity.ENTITY_NAME, inManagedObjectContext: context!)!
        self.init(entity: entity, user: user, insertIntoManagedObjectContext: context)
    }

}

extension UserEntity {
    
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var pictureUrl: String
    @NSManaged var friends: [FriendEntity]
    @NSManaged var wishes: [WishEntity]
    
    var userValue: User {
        return User(id: id, name: name, pictureUrl: pictureUrl)
    }
    
    var wishValues: [Wish] {
        return wishes.map({ (entity) -> Wish in
            return entity.wishValue()
        })
    }
    
    var friendValues: [User] {
        return friends.map({ (entity) -> User in
            return entity.userValue
        })
    }
    
}
