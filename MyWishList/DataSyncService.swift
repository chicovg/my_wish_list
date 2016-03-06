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

enum DataSyncError: ErrorType {
    case UserNotLoggedIn
    case UserLoginFailed
}

class DataSyncService {
    
    static let sharedInstance = DataSyncService()
    
    var facebookClient: FacebookClient {
        return FacebookClient.sharedInstance
    }
    
    var firebaseClient: FirebaseClient {
        return FirebaseClient.sharedInstance
    }
    
    func loginWithFacebook(viewController: UIViewController, handler: (error: DataSyncError?) -> Void) {
        facebookClient.login(viewController) { (facebookResult, facebookError) -> Void in
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
                handler(error: .UserLoginFailed)
            } else if facebookResult.isCancelled {
                print("Facebook login was cancelled.")
                handler(error: .UserLoginFailed)
            } else {
                print("Facebook login succeeded.")
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                self.userDidLoginWithFacebook(accessToken, handler: { (user, error) -> Void in
                    if let _ = user where error == nil {
                        handler(error: nil)
                    } else {
                        print("Firebase login failed! \(error)")
                        self.logoutFromFacebook()
                        handler(error: .UserLoginFailed)
                    }
                })
            }
        }
    }
    
    func logoutFromFacebook(){
        facebookClient.logout()
    }
    
    func userIsLoggedIn() -> Bool {
        if let _ = facebookClient.currentAccessToken(), _ = firebaseClient.currentUser() {
            return true
        } else {
            return false
        }
    }
    
    func userDidLoginWithFacebook(token: String, handler: (user: User?, error: NSError?) -> Void){
        firebaseClient.authenticateWithFacebook(token) { (user, error) -> Void in
            if let user = user {
                // TODO remove, this is test data!
                for i in 1...10 {
                    self.firebaseClient.save(wish: Wish(id: "wish\(i)", title: "test \(i)", link: "", detail: "test \(i) detail"))
                }
                handler(user: user, error: nil)
            } else {
                handler(user: nil, error: error)
            }
        }
    }
    
    // MARK: Wish list functions
    func queryWishes(handler: (wishes: [Wish], syncError: DataSyncError?) -> Void) {
        if userIsLoggedIn() {
            firebaseClient.queryWishes { (wishes) -> Void in
                handler(wishes: wishes, syncError: nil)
            }
        } else {
            handler(wishes: [], syncError: DataSyncError.UserNotLoggedIn)
        }
    }
    func queryWishes(forUser user: User, handler: (wishes: [Wish], syncError: DataSyncError?) -> Void) {
        if userIsLoggedIn() {
            firebaseClient.queryWishes(forUser: user) { (wishes) -> Void in
                handler(wishes: wishes, syncError: nil)
            }
        } else {
            handler(wishes: [], syncError: DataSyncError.UserNotLoggedIn)
        }
    }
    func deleteWish(wish: Wish, handler: (syncError: DataSyncError?, deleteError: NSError?) -> Void) {
        if userIsLoggedIn() {
            firebaseClient.deleteWish(wish: wish, completionHandler: { (deleteError) -> Void in
                handler(syncError: nil, deleteError: deleteError)
            })
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn, deleteError: nil)
        }
    }
    func save(wish wish: Wish, handler: (syncError: DataSyncError?, saveError: NSError?) -> Void) {
        if userIsLoggedIn() {
            firebaseClient.save(wish: wish, completionHandler: { (saveError) -> Void in
                handler(syncError: nil, saveError: saveError)
            })
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn, saveError: nil)
        }
    }
    
    
    // MARK: friends functions
    func fetchFriends(handler: (syncError: DataSyncError?) -> Void) {
        if userIsLoggedIn() {
            facebookClient.getFriends({ (friends) -> Void in
                self.firebaseClient.save(facebookFriendsList: friends)
                handler(syncError: nil)
            })
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn)
        }
    }
    
    func queryFriends(handler: (friends: [User], syncError: DataSyncError?) -> Void) {
        if userIsLoggedIn() {
            firebaseClient.queryFriends({ (friends) -> Void in
                handler(friends: friends, syncError: nil)
            })
        } else {
            handler(friends: [], syncError: DataSyncError.UserNotLoggedIn)
        }
    }
    
}