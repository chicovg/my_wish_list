//
//  GrantedWishEntity.swift
//  MyWishList
//
//  Created by Victor Guthrie on 6/10/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData

class GrantedWishEntity: NSManagedObject {
    
    static let ENTITY_NAME = "GrantedWishEntity"
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(user: UserEntity, friend: FriendEntity, wish: Wish, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entityForName(GrantedWishEntity.ENTITY_NAME, inManagedObjectContext: context!)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.id = wish.id
        self.title = wish.title
        self.detail = wish.detail
        self.link = wish.link
        self.granted = wish.granted
        self.grantedOn = wish.grantedOn
        self.grantedBy = user
        self.friend = friend
    }
    
    func wishValue() -> Wish {
        var gtd = false
        if let granted = self.granted {
            gtd = granted.boolValue
        }
        return Wish(id: id, title: title, link: link, detail: detail, granted: gtd, grantedOn: grantedOn)
    }
    
}

extension GrantedWishEntity {
    
    @NSManaged var id: String?
    @NSManaged var title: String
    @NSManaged var detail: String?
    @NSManaged var link: String?
    @NSManaged var granted: NSNumber?
    @NSManaged var grantedOn: NSDate?
    @NSManaged var grantedBy: UserEntity
    @NSManaged var friend: FriendEntity
    
}
