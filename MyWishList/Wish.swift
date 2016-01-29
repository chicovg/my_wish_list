//
//  Wish.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/23/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData


class Wish: NSManagedObject {
    static let ENTITY_NAME: String = "Wish"
}

extension Wish {
    
    struct Keys {
        static let userId = "userId"
        static let objectId = "objectId"
        static let title = "title"
        static let detail = "detail"
        static let lastUpdatedDate = "lastUpdatedDate"
    }
    
    @NSManaged var title: String!
    @NSManaged var userId: String?
    @NSManaged var objectId: String?
    @NSManaged var detail: String?
    @NSManaged var lastUpdatedDate: NSDate
    
    convenience init(dictionary: [String : AnyObject?], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(Wish.ENTITY_NAME, inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.title = dictionary[Keys.title] as! String
        if let userId = dictionary[Keys.userId] as? String {
            self.userId = userId
        }
        if let objectId = dictionary[Keys.objectId] as? String {
            self.objectId = objectId
        }
        if let detail = dictionary[Keys.detail] as? String {
            self.detail = detail
        }
        self.lastUpdatedDate = NSDate()
    }
    
    func updateFromJson(json: [String : AnyObject]) {
        if let title = json[Keys.title] as? String {
            self.title = title
        }
        if let userId = json[Keys.userId] as? String {
            self.userId = userId
        }
        if let objectId = json[Keys.objectId] as? String {
            self.objectId = objectId
        }
        if let detail = json[Keys.detail] as? String {
            self.detail = detail
        }
        if let updtDate = json[Keys.lastUpdatedDate] as? NSDate{
            self.lastUpdatedDate = updtDate
        }
    }
    
    func toJsonString() -> String {
        var fields: Array = Array<String>()
        fields.append("\"title\":\"\(title)\"")
        if let userId = userId {
            fields.append("\"userId\":\"\(userId)\"")
        }
        if let detail = detail {
            fields.append("\"detail\":\"\(detail)\"")
        }
        if let objectId = objectId {
            fields.append("\"objectId\":\"\(objectId)\"")
        }
        return "{\(fields.joinWithSeparator(","))}"
    }
    
}
