//
//  WishPromiseEntity.swift
//  MyWishList
//
//  Created by Victor Guthrie on 6/10/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData

class WishPromiseEntity: NSManagedObject {
    
    static let ENTITY_NAME = "WishPromiseEntity"
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(wish: WishEntity, promisedBy: UserEntity, promisedOn: NSDate, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entityForName(WishPromiseEntity.ENTITY_NAME, inManagedObjectContext: context!)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.promisedBy = promisedBy
        self.wish = wish
        self.promisedOn = promisedOn
    }
}

extension WishPromiseEntity {
    
    @NSManaged var promisedBy: UserEntity
    @NSManaged var wish: WishEntity
    @NSManaged var promisedOn: NSDate
    
}
