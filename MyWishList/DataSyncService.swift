//
//  DataSyncService.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/21/16.
//  Copyright © 2016 chicovg. All rights reserved.
//
//  Orchestrates data synchronization between facebook and firebase,
//
//

import Foundation
import FBSDKCoreKit

class DataSyncService {
    
    static let sharedInstance = DataSyncService()
    
    var facebookClient: FacebookClient {
        return FacebookClient.sharedInstance
    }
    
    var firebaseClient: FirebaseClient {
        return FirebaseClient.sharedInstance
    }
    
    func userIsLoggedIn() -> Bool {
        if let _ = FBSDKAccessToken.currentAccessToken() {
            return true
        } else {
            return false
        }
    }
    
    func userDidLoginWithFacebook(token: String, handler: (user: User?, error: NSError?) -> Void){
        firebaseClient.authenticateWithFacebook(token) { (user, error) -> Void in
            if let user = user {
                self.facebookClient.getFriends({ (friends) -> Void in
                    self.firebaseClient.save(friendsList: friends)
                })
                for i in 1...10 {
                    self.firebaseClient.save(wish: Wish(id: "wish\(i)", title: "test \(i)", detail: "test \(i) detail"))
                }
                handler(user: user, error: nil)
            } else {
                handler(user: nil, error: error)
            }
        }
    }
    
    /*
        TODO every operation should check
        1) logged in: get current firebase auth info else send back to login page

    */
    
}