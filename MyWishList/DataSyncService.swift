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
    
    var coreDataClient: CoreDataClient {
        return CoreDataClient.sharedInstance
    }
    
    // MARK: Auth functions
    func userIsLoggedIn() -> Bool {
        guard let _ = facebookClient.currentAccessToken(), _ = firebaseClient.currentUser() else {
            return false
            // TODO check for saved token
        }
        return true
    }
    
    func currentUser() -> UserEntity? {        
        guard let user = firebaseClient.currentUser() else {
            return nil
        }
        
        guard let userEntity = coreDataClient.find(userById: user.id) else {
            return nil
        }
        
        return userEntity
    }
        
    // MARK: Facebook Auth
    func loginWithFacebook(viewController: UIViewController, handler: (user: UserEntity?, error: DataSyncError?) -> Void) {
        toggleNetworkIndicator()
        
        facebookClient.login(viewController) { (facebookResult, facebookError) -> Void in
            self.toggleNetworkIndicator()
            
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
                handler(user: nil, error: .UserLoginFailed)
            } else if facebookResult.isCancelled {
                print("Facebook login was cancelled.")
                handler(user: nil, error: .UserLoginFailed)
            } else {
                print("Facebook login succeeded.")
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                self.userDidLoginWithFacebook(accessToken, handler: { (user, error) -> Void in
                    if let error = error {
                        print("Firebase login failed! \(error)")
                        self.logoutFromFacebook()
                        handler(user: nil, error: .UserLoginFailed)
                    } else {
                        handler(user: user, error: nil)
                    }
                })
            }
        }
    }
    
    func logoutFromFacebook() {
        toggleNetworkIndicator()
        facebookClient.logout()
        toggleNetworkIndicator()
    }
    
    func userDidLoginWithFacebook(token: String, handler: (user: UserEntity?, error: NSError?) -> Void) {
        toggleNetworkIndicator()
        
        firebaseClient.authenticateWithFacebook(token) { (user, error) -> Void in
            self.toggleNetworkIndicator()
            
            guard let user = user else {
                handler(user: nil, error: error)
                return
            }
            
            self.keychainClient.saveAccessToken(token)
            let userEntity = self.coreDataClient.upsert(user: user)
            self.coreDataClient.saveContext()
            handler(user: userEntity, error: nil)
        }
    }

    func listenForUpdates(user: UserEntity) {
        toggleNetworkIndicator()
        
        firebaseClient.queryWishes { (wishes) in
            self.toggleNetworkIndicator()

            wishes.forEach({ (wish) in
                self.coreDataClient.upsert(wish: wish, forUser: user)
            })
            self.coreDataClient.saveContext()
        }
    }
    
    func stopListeningForUpdates() {
        firebaseClient.removeAllObservers()
    }
    
    // MARK: Wish list functions
    func queryWishes(forUser user: User, handler: (wishes: [Wish], syncError: DataSyncError?) -> Void) {
        if userIsLoggedIn() {
            toggleNetworkIndicator()

            firebaseClient.queryWishes(forUser: user) { (wishes) -> Void in
                self.toggleNetworkIndicator()

                handler(wishes: wishes, syncError: nil)
            }
        } else {
            handler(wishes: [], syncError: DataSyncError.UserNotLoggedIn)
        }
    }
    func queryUngrantedWishes(forUser user: User, handler: (wishes: [Wish], syncError: DataSyncError?) -> Void) {
        if userIsLoggedIn() {
            toggleNetworkIndicator()

            firebaseClient.queryUngrantedWishes(forUser: user) { (wishes) -> Void in
                self.toggleNetworkIndicator()

                handler(wishes: wishes, syncError: nil)
            }
        } else {
            handler(wishes: [], syncError: DataSyncError.UserNotLoggedIn)
        }
    }
    func deleteWish(wish: Wish, handler: (syncError: DataSyncError?, deleteError: NSError?) -> Void) {
        if userIsLoggedIn() {
            toggleNetworkIndicator()

            firebaseClient.deleteWish(wish: wish, completionHandler: { (deleteError) -> Void in
                self.toggleNetworkIndicator()

                if deleteError == nil {
                    self.coreDataClient.delete(wish: wish)
                    self.coreDataClient.saveContext()
                }
                handler(syncError: nil, deleteError: deleteError)
            })
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn, deleteError: nil)
        }
    }
    func save(wish wish: Wish, handler: (syncError: DataSyncError?, saveError: NSError?) -> Void) {
        if let user = currentUser() {
            toggleNetworkIndicator()
            
            firebaseClient.save(wish: wish, completionHandler: { (saveError, key) -> Void in
                self.toggleNetworkIndicator()
                
                if saveError == nil {
                    self.coreDataClient.upsert(wish: Wish(id: key, title: wish.title, link: wish.link, detail: wish.detail, granted: wish.granted), forUser: user)
                    self.coreDataClient.saveContext()
                }
                handler(syncError: nil, saveError: saveError)
            })
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn, saveError: nil)
        }
    }
    func grantWish(userId: String, wishId: String, handler: (syncError: DataSyncError?, saveError: NSError?) -> Void) {
        if userIsLoggedIn() {
            toggleNetworkIndicator()
            
            firebaseClient.grantWish(userId, wishId: wishId, completionHandler: { (saveError) -> Void in
                self.toggleNetworkIndicator()
                
                handler(syncError: nil, saveError: saveError)
            })
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn, saveError: nil)
        }
    }
    
    // MARK: Friend functions
    func fetchFriends(user: UserEntity) {
        toggleNetworkIndicator()
        
        facebookClient.getFriends({ (friends) -> Void in
            self.toggleNetworkIndicator()
            
            self.coreDataClient.upsert(friends: friends.map({ (friend) in
                return User(id: "\(FACEBOOK_AUTH_PREFIX):\(friend.id)", name: friend.name, pictureUrl: friend.pictureUrl)
            }), ofUser: user)
            self.coreDataClient.saveContext()
        })
    }
    
    func queryFriends(handler: (friends: [User], syncError: DataSyncError?) -> Void) {
        if userIsLoggedIn() {
            toggleNetworkIndicator()
            
            firebaseClient.queryFriends({ (friends) -> Void in
                self.toggleNetworkIndicator()
                
                handler(friends: friends, syncError: nil)
            })
        } else {
            handler(friends: [], syncError: DataSyncError.UserNotLoggedIn)
        }
    }
    
    private func toggleNetworkIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible
            = !UIApplication.sharedApplication().networkActivityIndicatorVisible
    }
    
}