//
//  FriendEntity.swift
//  MyWishList
//
//  Created by Victor Guthrie on 5/14/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData


class FriendEntity: NSManagedObject {
    
    static let ENTITY_NAME = "FriendEntity"
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(entity: NSEntityDescription, friend user: User, of friendOf: UserEntity, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.id = user.id
        self.name = user.name
        self.pictureUrl = user.pictureUrl
        self.user = friendOf
        self.grantedWishes = []
    }

}

extension FriendEntity {
    
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var pictureUrl: String
    @NSManaged var user: UserEntity
    @NSManaged var grantedWishes: [GrantedWishEntity]
    
    var userValue: User {
        return User(id: id, name: name, pictureUrl: pictureUrl)
    }
    
}