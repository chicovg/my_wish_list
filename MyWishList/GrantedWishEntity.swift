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
    
    convenience init(wish: WishEntity, grantedBy: UserEntity, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entityForName(GrantedWishEntity.ENTITY_NAME, inManagedObjectContext: context!)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.grantedBy = grantedBy
        self.wish = wish
    }
}

extension GrantedWishEntity {
    
    @NSManaged var grantedBy: UserEntity
    @NSManaged var wish: WishEntity
    
}
