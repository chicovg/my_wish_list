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
    }
    
    var id: String?
    let title: String
    var link: String?
    var detail: String?
    
    init(id: String?, title: String, link: String?, detail: String?){
        self.id = id
        self.title = title
        self.link = link
        self.detail = detail
    }
    
    init(title: String){
        self.init(id: nil, title: title, link: nil, detail: nil)
    }
    
    init(title: String, link: String?, detail: String?){
        self.init(id: nil, title: title, link: link, detail: detail)
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
    }
    
    func toValuesDictionary() -> [String : AnyObject] {
        var dict = [Keys.title : self.title]
        if let detail = self.detail {
            dict[Keys.detail] = detail
        }
        if let link = self.link {
            dict[Keys.link] = link
        }
        return dict
    }
}
