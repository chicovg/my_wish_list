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
    }
    
    var id: String?
    let title: String
    var link: String?
    var detail: String?
    var granted: Bool
    
    init(id: String?, title: String, link: String?, detail: String?, granted: Bool){
        self.id = id
        self.title = title
        self.link = link
        self.detail = detail
        self.granted = granted
    }
    
    init(id: String?, title: String, link: String?, detail: String?){
        self.init(id: id, title: title, link: link, detail: detail, granted: false)
    }
    
    init(title: String, link: String?, detail: String?){
        self.init(id: nil, title: title, link: link, detail: detail, granted: false)
    }
    
    init(title: String){
        self.init(id: nil, title: title, link: nil, detail: nil, granted: false)
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
    }
    
    func toValuesDictionary() -> [String : AnyObject] {
        var dict: [String : AnyObject] = [Keys.title : self.title,
                                        Keys.granted : self.granted]
        if let detail = self.detail {
            dict[Keys.detail] = detail
        }
        if let link = self.link {
            dict[Keys.link] = link
        }
        return dict
    }
}
