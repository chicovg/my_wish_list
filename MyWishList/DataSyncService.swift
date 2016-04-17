//
//  DataSyncService.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/21/16.
//  Copyright © 2016 chicovg. All rights reserved.
//
//  Orchestrates the interaction between the view layer and multiple 3rd party
//      clients (firebase, facebook, etc)

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
    
    var keychainClient: KeychainClient {
        return KeychainClient.sharedInstance
    }
    
    // MARK: Auth functions
    func userIsLoggedIn() -> Bool {
        guard let _ = facebookClient.currentAccessToken(), _ = firebaseClient.currentUser() else {
            return false
        }
        return true
    }
    
    // MARK: Facebook Auth
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
                    if let error = error {
                        print("Firebase login failed! \(error)")
                        self.logoutFromFacebook()
                        handler(error: .UserLoginFailed)
                    } else {
                        handler(error: nil)
                    }
                })
            }
        }
    }
    
    func logoutFromFacebook(){
        facebookClient.logout()
    }
    
    func userDidLoginWithFacebook(token: String, handler: (user: User?, error: NSError?) -> Void){
        firebaseClient.authenticateWithFacebook(token) { (user, error) -> Void in
            if let error = error {
                handler(user: nil, error: error)
            } else {
                self.keychainClient.saveAccessToken(token)
                handler(user: user, error: nil)
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
    func grantWish(userId: String, wishId: String, handler: (syncError: DataSyncError?, saveError: NSError?) -> Void) {
        if userIsLoggedIn() {
            firebaseClient.grantWish(userId, wishId: wishId, completionHandler: { (saveError) -> Void in
                handler(syncError: nil, saveError: saveError)
            })
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn, saveError: nil)
        }
    }
    
    
    
    // MARK: Friends functions
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