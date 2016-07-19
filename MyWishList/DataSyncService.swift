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
    
    /** Returns the currently authenticated user or nil if the is no active session */
    func currentUser() -> User? {
        guard let _ = facebookClient.currentAccessToken(), user = firebaseClient.currentUser() else {
            return nil
        }
        
        return user
    }
        
    // MARK: Facebook Auth
    
    /** Logs in using facebook authentication */
    func loginWithFacebook(viewController: UIViewController, handler: (user: User?, error: DataSyncError?) -> Void) {
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
    
    /** Log out from facebook */
    func logoutFromFacebook() {
        toggleNetworkIndicator()
        facebookClient.logout()
        stopListeningForUpdates()
        toggleNetworkIndicator()
    }
    
    /** After logging in via facebook, establish a firebase session and listen for updates from firebase */
    private func userDidLoginWithFacebook(token: String, handler: (user: User?, error: NSError?) -> Void) {
        toggleNetworkIndicator()
        
        firebaseClient.authenticateWithFacebook(token) { (user, error) -> Void in
            self.toggleNetworkIndicator()
            
            guard let user = user else {
                handler(user: nil, error: error)
                return
            }
            
            self.keychainClient.saveAccessToken(token)
            self.coreDataClient.upsert(user: user)
            self.coreDataClient.saveContext()
            self.listenForUpdates(user)
            handler(user: user, error: nil)
        }
    }
    
    /** Listen for updates to wish data in firebase */
    func listenForUpdates(user: User) {        
        firebaseClient.queryWishes(forUser: user) { (wishes) in
            wishes.forEach({ (wish) in
                self.coreDataClient.upsert(wish: wish, forUser: user)
            })
            self.coreDataClient.saveContext()
        }
        
        firebaseClient.listenForWishDeletes(forUser: user) { (wish) in
            self.coreDataClient.delete(wish: wish, forUser: user)
            self.coreDataClient.saveContext()
        }
        
        firebaseClient.queryNotifications(forUser: user) { (notifications) in
            for notification in notifications {
                self.notifyUser(notification)
                self.deleteNotification(notification)
            }
        }
    }
    
    /** Remove all firebase listeners */
    private func stopListeningForUpdates() {
        firebaseClient.removeAllObservers()
    }
    
    // MARK: Wish list functions
    
    /** Queries for "Wished" wishes for a particular user */
    func queryWishedWishes(forUser user: User, handler: (wishes: [Wish], syncError: DataSyncError?) -> Void) {
        if let _ = currentUser() {
            toggleNetworkIndicator()

            firebaseClient.queryWishes(forUser: user, filter: { (wish) -> Bool in
                    return wish.status == Wish.Status.Wished
            }, completionHandler: { (wishes) in
                self.toggleNetworkIndicator()
                
                handler(wishes: wishes, syncError: nil)
            })
        } else {
            handler(wishes: [], syncError: DataSyncError.UserNotLoggedIn)
        }
    }
    func deleteWish(wish: Wish, handler: (syncError: DataSyncError?, deleteError: NSError?) -> Void) {
        if let _ = currentUser() {
            toggleNetworkIndicator()

            firebaseClient.deleteWish(wish: wish) { (deleteError) -> Void in
                self.toggleNetworkIndicator()

                handler(syncError: nil, deleteError: deleteError)
            }
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn, deleteError: nil)
        }
    }
    func save(wish wish: Wish, handler: (syncError: DataSyncError?, saveError: NSError?) -> Void) {
        if let user = currentUser() {
            toggleNetworkIndicator()
            
            firebaseClient.save(wish: wish, forUser: user) { (saveError, key) -> Void in
                self.toggleNetworkIndicator()
                
                handler(syncError: nil, saveError: saveError)
            }
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn, saveError: nil)
        }
    }
    func promise(wish wish: Wish, forFriend friend: User, handler: (syncError: DataSyncError?, saveError: NSError?) -> Void) {
        if let user = currentUser() {
            let promisedWish = Wish(fromPrevious: wish, withUpdates:
                [Wish.Keys.status : Wish.Status.Promised,
                    Wish.Keys.promisedOn : NSDate(),
                    Wish.Keys.promisedBy : user
                ]
            )
            firebaseClient.save(wish: promisedWish, forUser: friend) { (error, key) in
                if let error = error {
                    handler(syncError: nil, saveError: error)
                } else {
                    self.coreDataClient.upsert(wish: promisedWish, forUser: friend)
                    handler(syncError: nil, saveError: nil)
                }
            }
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn, saveError: nil)
        }
    }
    func unpromise(wish wish: Wish, forFriend friend: User, handler: (syncError: DataSyncError?, saveError: NSError?) -> Void) {
        if let _ = currentUser() {
            let promisedWish = Wish(fromPrevious: wish, withUpdates:
                [Wish.Keys.status : Wish.Status.Wished,
                    Wish.Keys.promisedBy : nil,
                    Wish.Keys.promisedOn : nil
                ]
            )
            firebaseClient.save(wish: promisedWish, forUser: friend) { (error, key) in
                if let error = error {
                    handler(syncError: nil, saveError: error)
                } else {
                    // get wish entity
                    self.coreDataClient.upsert(wish: promisedWish, forUser: friend)
                    handler(syncError: nil, saveError: nil)
                }
            }
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn, saveError: nil)
        }
    }
    func granted(wish wish: Wish, handler: (syncError: DataSyncError?, saveError: NSError?) -> Void) {
        if let user = currentUser() {
            let grantedWish = Wish(fromPrevious: wish, withUpdates:
                [Wish.Keys.status : Wish.Status.Granted,
                    Wish.Keys.grantedOn : NSDate()
                ]
            )
            firebaseClient.save(wish: grantedWish, forUser: user, completionHandler: { (error, key) in
                if let error = error {
                    handler(syncError: nil, saveError: error)
                } else {
                    self.coreDataClient.upsert(wish: grantedWish, forUser: user)
                    handler(syncError: nil, saveError: nil)
                }
            })
        } else {
            handler(syncError: DataSyncError.UserNotLoggedIn, saveError: nil)
        }
    }
    
    // MARK: Friend functions
    func fetchFriends(user: User) {
        toggleNetworkIndicator()
        
        facebookClient.getFriends({ (friends) -> Void in
            self.toggleNetworkIndicator()
            
            friends.map({ (friend) in
                return User(id: "\(FACEBOOK_AUTH_PREFIX):\(friend.id)", name: friend.name, pictureUrl: friend.pictureUrl)
            }).forEach({ (friend) in
                self.coreDataClient.upsert(friend: friend, ofUser: user)
            })
            
            self.coreDataClient.saveContext()
        })
    }
    
    func queryFriends(handler: (friends: [User], syncError: DataSyncError?) -> Void) {
        if let _ = currentUser() {
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
    
    // MARK: notification functions
    func sendNotification(withType type: NotificationType, toUser user: User) {
        firebaseClient.sendNotification(withType: type, toUser: user)
    }
    
    func fetchNotifications(handler: (notifications: [Notification], syncError: DataSyncError?) -> Void) {
        if let user = currentUser() {
            firebaseClient.queryNotifications(forUser: user, listenForUpdates: false) { (notifications) in
                handler(notifications: notifications, syncError: nil)
            }
        } else {
            handler(notifications: [], syncError: DataSyncError.UserNotLoggedIn)
        }
    }
    
    func deleteNotification(notification: Notification) {
        if let user = currentUser() {
            firebaseClient.deleteNotification(notification, forUser: user)
        }
    }
    
     func notifyUser(notification: Notification) {
        // create a corresponding local notification
        let uiNotification = UILocalNotification()
        uiNotification.alertBody = notification.message
        uiNotification.alertAction = "open"
        uiNotification.fireDate =  NSDate()
        uiNotification.soundName = UILocalNotificationDefaultSoundName
        
        UIApplication.sharedApplication().scheduleLocalNotification(uiNotification)
    }
    
}