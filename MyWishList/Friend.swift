//
//  Friend.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/7/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData

class Friend: NSManagedObject {

    static let ENTITY_NAME: String = "Friend"
    
    struct Keys {
        static let id = "id"
        static let name = "name"
        static let picture = "picture"
    }

    @NSManaged var id: String?
    @NSManaged var name: String?
    @NSManaged var picture: String?
    
    convenience init(dictionary: [String : AnyObject?], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(Friend.ENTITY_NAME, inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        if let id = dictionary[Keys.id] as? String {
            self.id = id
        }
        
        if let name = dictionary[Keys.name] as? String {
            self.name = name
        }
        
        if let pictureJson = dictionary[Keys.picture] as? [String : AnyObject], url = extractPictureUrl(pictureJson) {
            self.picture = url
        }
    }
    
    func updateFromJson(json: [String : AnyObject]) {
        if let name = json[Keys.name] as? String {
            self.name = name
        }
        
        if let pictureJson = json[Keys.picture] as? [String : AnyObject], url = extractPictureUrl(pictureJson) {
            self.picture = url
        }
    }
    
    private func extractPictureUrl(json: AnyObject) -> String? {
        if let data = json["data"] as? [String : AnyObject], url = data["url"] as? String {
            return url
        }
        return nil
    }
    
    var nameWithDefault : String {
        if let name = name {
            return name
        } else {
            return "Unknown Friend"
        }
    }
}
