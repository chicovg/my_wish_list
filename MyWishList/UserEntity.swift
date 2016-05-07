//
//  UserEntity.swift
//  MyWishList
//
//  Created by Victor Guthrie on 5/7/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData


class UserEntity: NSManagedObject {
        
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var pictureUrl: String
    @NSManaged var wishes: [WishEntity]
    @NSManaged var friends: [FriendEntity]
    
    init(entity: NSEntityDescription, user: User, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.id = user.id
        self.name = user.name
        self.pictureUrl = user.pictureUrl
    }
    
    convenience init(user: User, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entityForName("UserEntity", inManagedObjectContext: context!)!
        self.init(entity: entity, user: user, insertIntoManagedObjectContext: context)
    }
}
