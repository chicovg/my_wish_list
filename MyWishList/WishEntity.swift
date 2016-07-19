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
        self.status = wish.status
        self.user = user
    }

}

extension WishEntity {
    
    @NSManaged var id: String?
    @NSManaged var title: String
    @NSManaged var detail: String?
    @NSManaged var link: String?
    @NSManaged var status: String
    @NSManaged var user: UserEntity
    @NSManaged var wishPromise: WishPromiseEntity?
    
    var wishValue: Wish {
        var promisedBy: User? = nil
        var promisedOn: NSDate? = nil
        var grantedOn: NSDate? = nil
        if let wishPromise = wishPromise {
            promisedBy = wishPromise.promisedBy.userValue
            promisedOn = wishPromise.promisedOn
            grantedOn = wishPromise.grantedOn
        }
        
        return Wish(id: id, title: title, link: link, detail: detail, status: status, promisedBy: promisedBy, promisedOn: promisedOn, grantedOn: grantedOn)
    }
    
    var statusOrder: Int {
        return status == Wish.Status.Wished ? 0 : status == Wish.Status.Promised ? 1 : 2
    }
    
}
