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
        static let status = "status"
        static let promisedBy = "promisedBy"
        static let promisedOn = "promisedOn"
        static let grantedOn = "grantedOn"
        static let friend = "friend"
        static let statusOrder = "statusOrder"
    }
    
    /**
        Wished: The user creates the wish on thier list
            - can edit/delete the wish
            - visible to other users
        Promised: A friend agrees to grant the wish
            - can no longer edit or delete the wish
            - no longer visible to all friends (only visible to the friend who promised it)
            - moved to promises tab of user who will grant the wish
        Granted: the user has received the wish
            - can delete the wish
     */
    struct Status {
        static let Wished = "Wished"
        static let Promised = "Promised"
        static let Granted = "Granted"
    }
    
    var id: String?
    let title: String
    var link: String?
    var detail: String?
    var status: String
    var promisedBy: User?
    var promisedOn: NSDate?
    var grantedOn: NSDate?
    
    static let dateFormatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
        return formatter
    }()
    
    var attributes: [String : AnyObject] {
        var dict: [String : AnyObject] = [Keys.title : self.title, Keys.status : self.status]
        if let id = self.id {
            dict[Keys.id] = id
        }
        if let detail = self.detail {
            dict[Keys.detail] = detail
        }
        if let link = self.link {
            dict[Keys.link] = link
        }
        
        return dict
    }
    
    var attributesForFirebase: [String: AnyObject] {
        var attr = self.attributes
        if let promisedBy = self.promisedBy {
            attr[Keys.promisedBy] = promisedBy.attributes
        }
        if let promisedOn = self.promisedOn {
            attr[Keys.promisedOn] = Wish.dateFormatter.stringFromDate(promisedOn)
        }
        if let grantedOn = self.grantedOn {
            attr[Keys.grantedOn] = Wish.dateFormatter.stringFromDate(grantedOn)
        }
        return attr
    }
    
    init(id: String?, title: String, link: String?, detail: String?, status: String, promisedBy: User?, promisedOn: NSDate?, grantedOn: NSDate?) {
        self.id = id
        self.title = title
        self.link = link
        self.detail = detail
        self.status = status
        self.promisedBy = promisedBy
        self.promisedOn = promisedOn
        self.grantedOn = grantedOn
    }
    
    init(id: String?, title: String, link: String?, detail: String?){
        self.init(id: id, title: title, link: link, detail: detail, status: Status.Wished, promisedBy: nil, promisedOn: nil, grantedOn: nil)
    }
    
    init(title: String, link: String?, detail: String?){
        self.init(id: nil, title: title, link: link, detail: detail, status: Status.Wished, promisedBy: nil, promisedOn: nil, grantedOn: nil)
    }
    
    init(title: String){
        self.init(id: nil, title: title, link: nil, detail: nil, status: Status.Wished, promisedBy: nil, promisedOn: nil, grantedOn: nil)
    }
    
    init(fromPrevious wish: Wish?, withUpdates updates: (title: String, link: String?, detail: String?)) {
        if let wish = wish {
            self.init(id: wish.id, title: updates.title, link: updates.link, detail: updates.detail, status: wish.status, promisedBy: wish.promisedBy, promisedOn: wish.promisedOn, grantedOn: wish.grantedOn)
        } else {
            self.init(title: updates.title, link: updates.link, detail: updates.detail)
        }
    }
    
    init(fromPrevious wish: Wish, withUpdates updates: [String: Any?]) {
        self.init(id: wish.id,
                  title: (updates[Keys.title] ?? wish.title) as! String,
                  link: (updates[Keys.link] ?? wish.link) as? String,
                  detail: (updates[Keys.detail] ?? wish.detail) as? String,
                  status: (updates[Keys.status] ?? wish.status) as! String,
                  promisedBy: (updates[Keys.promisedBy] ?? wish.promisedBy) as? User,
                  promisedOn: (updates[Keys.promisedOn] ?? wish.promisedOn) as? NSDate,
                  grantedOn: (updates[Keys.grantedOn] ?? wish.grantedOn) as? NSDate)
    }
    
    private func chooseAttribute(key: String, attributes: [String : AnyObject], defaultValue: AnyObject?) -> AnyObject? {
        guard let value = attributes[key] else {
            return defaultValue
        }
        return value
    }
    
    init(fromFDataSnapshot snapshot: FDataSnapshot) {
        self.id = snapshot.key
        self.title = snapshot.childSnapshotForPath(Keys.title).value as! String
        self.status = snapshot.childSnapshotForPath(Keys.status).value as! String
        if snapshot.hasChild(Keys.detail) {
            self.detail = snapshot.childSnapshotForPath(Keys.detail).value as? String
        }
        if snapshot.hasChild(Keys.link) {
            self.link = snapshot.childSnapshotForPath(Keys.link).value as? String
        }
        if let promisedBySnapshot = snapshot.childSnapshotForPath(Keys.promisedBy) where promisedBySnapshot.hasChildren() {
            self.promisedBy = User(fromFDataSnapshot: promisedBySnapshot)
        }
        if let promisedOnString = snapshot.childSnapshotForPath(Keys.promisedOn).value as? String {
            self.promisedOn = Wish.dateFormatter.dateFromString(promisedOnString)
        }
        if let grantedOnString = snapshot.childSnapshotForPath(Keys.grantedOn).value as? String {
            self.grantedOn = Wish.dateFormatter.dateFromString(grantedOnString)
        }
    }
    
    func wished() -> Bool {
        return self.status == Status.Wished
    }
}
