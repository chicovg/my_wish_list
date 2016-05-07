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
    
    @NSManaged var id: String?
    @NSManaged var title: String
    @NSManaged var detail: String?
    @NSManaged var link: String?
    @NSManaged var granted: NSNumber?
    @NSManaged var user: UserEntity
    
    init(user: UserEntity, wish: Wish, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entityForName("WishEntity", inManagedObjectContext: context!)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.id = wish.id
        self.title = wish.title
        self.detail = wish.detail
        self.link = wish.link
        self.granted = wish.granted
        self.user = user
    }

}
