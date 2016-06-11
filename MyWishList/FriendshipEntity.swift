//
//  Friendship.swift
//  MyWishList
//
//  Created by Victor Guthrie on 6/11/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData

class FriendshipEntity: NSManagedObject {

    static let ENTITY_NAME = "FriendshipEntity"
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(user: UserEntity, friend: UserEntity, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entityForName(FriendshipEntity.ENTITY_NAME, inManagedObjectContext: context!)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.user = user
        self.friend = friend
    }
}

extension FriendshipEntity {
    
    @NSManaged var user: UserEntity
    @NSManaged var friend: UserEntity
    
}
