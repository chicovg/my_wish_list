//
//  FriendEntity.swift
//  MyWishList
//
//  Created by Victor Guthrie on 5/7/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData


class FriendEntity: UserEntity {
    
    @NSManaged var user: UserEntity
    
    init(user: UserEntity, friend: User, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entityForName("FriendEntity", inManagedObjectContext: context!)!
        super.init(entity: entity, user: friend, insertIntoManagedObjectContext: context!)
        
        self.user = user
    }

}
