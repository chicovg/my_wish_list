//
//  WishEntity.swift
//  MyWishList
//
//  Created by Victor Guthrie on 5/7/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData

class WishEntity: NSManagedObject {
    
    static let ENTITY_NAME = "WishEntity"
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(user: UserEntity, wish: Wish, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entityForName(WishEntity.ENTITY_NAME, inManagedObjectContext: context!)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.id = wish.id
        self.title = wish.title
        self.detail = wish.detail
        self.link = wish.link
        self.granted = wish.granted
        self.user = user
    }
    
    func wishValue() -> Wish {
        var gtd = false
        if let granted = self.granted {
            gtd = granted.boolValue
        }
        return Wish(id: id, title: title, link: link, detail: detail, granted: gtd)
    }

}

extension WishEntity {
    
    @NSManaged var id: String?
    @NSManaged var title: String
    @NSManaged var detail: String?
    @NSManaged var link: String?
    @NSManaged var granted: NSNumber?
    @NSManaged var user: UserEntity
    
}
