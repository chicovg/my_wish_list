//
//  Wish.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/22/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import Firebase

struct Wish {
    struct Keys {
        static let id = "id"
        static let title = "title"
        static let link = "link"
        static let detail = "detail"
        static let granted = "granted"
        static let grantedOn = "grantedOn"
        static let grantedBy = "grantedBy"
        static let friend = "friend"
    }
    
    var id: String?
    let title: String
    var link: String?
    var detail: String?
    var granted: Bool
    var grantedOn: NSDate?
    
    static let dateFormatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
        return formatter
    }()
    
    var attributes: [String : AnyObject] {
        var dict: [String : AnyObject] = [Keys.title : self.title,
                                          Keys.granted : self.granted]
        if let id = self.id {
            dict[Keys.id] = id
        }
        if let detail = self.detail {
            dict[Keys.detail] = detail
        }
        if let link = self.link {
            dict[Keys.link] = link
        }
        if let grantedOn = self.grantedOn {
            dict[Keys.grantedOn] = grantedOn
        }
        
        return dict
    }
    
    var attributesForFirebase: [String: AnyObject] {
        var attr = self.attributes
        if let grantedOn = grantedOn {
            attr[Keys.grantedOn] = Wish.dateFormatter.stringFromDate(grantedOn)
        }
        return attr
    }
    
    init(id: String?, title: String, link: String?, detail: String?, granted: Bool, grantedOn: NSDate?){
        self.id = id
        self.title = title
        self.link = link
        self.detail = detail
        self.granted = granted
        self.grantedOn = grantedOn
    }
    
    init(id: String?, title: String, link: String?, detail: String?){
        self.init(id: id, title: title, link: link, detail: detail, granted: false, grantedOn: nil)
    }
    
    init(title: String, link: String?, detail: String?){
        self.init(id: nil, title: title, link: link, detail: detail, granted: false, grantedOn: nil)
    }
    
    init(title: String){
        self.init(id: nil, title: title, link: nil, detail: nil, granted: false, grantedOn: nil)
    }
    
    init(fromFDataSnapshot snapshot: FDataSnapshot){
        self.id = snapshot.key
        self.title = snapshot.childSnapshotForPath(Keys.title).value as! String
        if snapshot.hasChild(Keys.detail) {
            self.detail = snapshot.childSnapshotForPath(Keys.detail).value as? String
        }
        if snapshot.hasChild(Keys.link) {
            self.link = snapshot.childSnapshotForPath(Keys.link).value as? String
        }
        if snapshot.hasChild(Keys.granted) {
            self.granted = snapshot.childSnapshotForPath(Keys.granted).value as! Bool
        } else {
            self.granted = false
        }
        if let grantedOnString = snapshot.childSnapshotForPath(Keys.grantedOn).value as? String where snapshot.hasChild(Keys.grantedOn) {
            self.grantedOn = Wish.dateFormatter.dateFromString(grantedOnString)
        }
    }
}
