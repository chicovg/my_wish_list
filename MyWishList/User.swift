//
//  User.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/22/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import Firebase

struct User {
    struct Keys {
        static let id = "id"
        static let name = "name"
        static let pictureUrl = "picture_url"
        static let picture = "picture"
        static let data = "data"
        static let url = "url"
        static let provider = "provider"
        static let fb_name = "displayName"
    }
    
    let id: String
    let name: String
    let pictureUrl: String
    
    init(id: String, name: String, pictureUrl: String) {
        self.id = id
        self.name = name
        self.pictureUrl = pictureUrl
    }
    
    init?(fromJson json: [String: AnyObject]) {
        if let id = json[Keys.id] as? String, name = json[Keys.name] as? String, picture = json[Keys.picture] as? [String : AnyObject], data = picture[Keys.data] as? [String : AnyObject], url = data[Keys.url] as? String  {
            self.init(id: id, name: name, pictureUrl: url)
        } else {
            return nil
        }
    }
    
    init(fromFacebookAuthData authData: FAuthData){
        self.init(id: authData.uid,
            name: authData.providerData["displayName"] as! String,
            pictureUrl: authData.providerData["profileImageURL"] as! String)
    }
    
    init(fromFDataSnapshot snapshot: FDataSnapshot){
        self.id = snapshot.key
        self.name = snapshot.childSnapshotForPath(Keys.name).value as! String
        self.pictureUrl = snapshot.childSnapshotForPath(Keys.pictureUrl).value as! String
    }
    
    func toValuesDictionary() -> [String : AnyObject] {
        return [Keys.name : self.name, Keys.pictureUrl : self.pictureUrl]
    }
    
}