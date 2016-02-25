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
        static let detail = "detail"
    }
    
    var id: String?
    let title: String
    var detail: String?
    
    init(id: String?, title: String, detail: String?){
        self.id = id
        self.title = title
        self.detail = detail
    }
    
    init(title: String){
        self.init(id: nil, title: title, detail: nil)
    }
    
    init(title: String, detail: String?){
        self.init(id: nil, title: title, detail: detail)
    }
    
    init(fromFDataSnapshot snapshot: FDataSnapshot){
        self.id = snapshot.key
        self.title = snapshot.childSnapshotForPath(Keys.title).value as! String
        if snapshot.hasChild(Keys.detail) {
            self.detail = snapshot.childSnapshotForPath(Keys.detail).value as? String
        }
    }
    
    func toValuesDictionary() -> [String : AnyObject] {
        var dict = [Keys.title : self.title]
        if let detail = self.detail {
            dict[Keys.detail] = detail
        }
        return dict
    }
}
