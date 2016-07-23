//
//  FirebaseClient.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/21/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import Firebase

let FACEBOOK_AUTH_PREFIX = "facebook"

let MyWishListFirebaseClientDomain = "MyWishListFirebaseClientDomain"

enum FirebaseClientErrorCode: Int {
    case RefNotCreated = 1
}

class FirebaseClient {
    
    static let sharedInstance = FirebaseClient()
    
    let USERS_PATH = "users"
    let FRIENDS_PATH = "friends"
    let WISHES_PATH = "wishes"
    let NOTIFICATIONS_PATH = "notifications"
    
    var connected: Bool = false
            
    lazy var rootRef: Firebase = {
        Firebase.defaultConfig().persistenceEnabled = true
        let ref = Firebase(url: "my-wishlist.firebaseio.com")
        ref.keepSynced(true)
        return ref
    }()
    
    func currentUser() -> User? {
        if let authData = rootRef.authData {
            return User(fromFacebookAuthData: authData)
        }
        return nil
    }
    
    private func currentUserRef() -> Firebase? {
        if let user = currentUser() {
            return rootRef.childByAppendingPath(USERS_PATH).childByAppendingPath(user.id)
        }
        return nil
    }
    
    private func currentUserFriendsRef() -> Firebase? {
        if let user = currentUser() {
            return rootRef.childByAppendingPath(FRIENDS_PATH).childByAppendingPath(user.id)
        }
        return nil
    }

    private func currentUserWishesRef() -> Firebase? {
        if let user = currentUser() {
            return rootRef.childByAppendingPath(WISHES_PATH).childByAppendingPath(user.id)
        }
        return nil
    }
    
    private func userWishesRef(userId: String) -> Firebase? {
        return rootRef.childByAppendingPath(WISHES_PATH).childByAppendingPath(userId)
    }
    
    private func userNotificationsRef(userId: String) -> Firebase? {
        return rootRef.childByAppendingPath(NOTIFICATIONS_PATH).childByAppendingPath(userId)
    }
    
    private func connectedRef() -> Firebase {
        return rootRef.childByAppendingPath(".info").childByAppendingPath("connected")
    }
    
    // MARK: misc functions
    func removeAllObservers() {
        rootRef.removeAllObservers()
    }

    func observeConnectionStatus() -> Bool {
        connectedRef().queryOrderedByKey().observeEventType(.Value) { (snapshot: FDataSnapshot!) in
            self.connected = snapshot.value as! Bool
            print("\(self.connected ? "Connected to" : "Disconnected from") Firebase")
        }
        return true
    }
    
    // MARK: user functions
    func authenticateWithFacebook(accessToken: String, handler: (user: User?, error: NSError?) -> Void) {
        rootRef.authWithOAuthProvider(FACEBOOK_AUTH_PREFIX, token: accessToken, withCompletionBlock: { error, authData in
            if let authData = authData {
                print("Logged in! \(authData)")
                let user = User(fromFacebookAuthData: authData)
                self.save(user: user)
                handler(user: user,error: nil)
            } else {
                print("Login failed. \(error)")
                handler(user: nil, error: error)
            }
        })
    }
    
    func unauthenticate() {
        rootRef.unauth()
    }
    
    func save(user user: User) {
        if let ref = currentUserRef() {
            ref.updateChildValues(user.attributes)
        }
    }
    
    // MARK: friends functions
    func save(facebookFriendsList friends: [User]) {
        if let ref = currentUserFriendsRef() {
            let friendsValues = friends.reduce([:]) { (dictionary, friend) -> [String : [String: AnyObject]] in
                var dict = dictionary
                dict["\(FACEBOOK_AUTH_PREFIX):\(friend.id)"] = friend.attributes
                return dict
            }
            ref.updateChildValues(friendsValues)
        }
    }
    
    func queryFriends(completionHandler: (friends: [User]) -> Void) {
        if let ref = currentUserFriendsRef() {
            ref.queryOrderedByChild("name").observeEventType(FEventType.Value) { (snapshot: FDataSnapshot!) -> Void in
                var friends: [User] = []
                for item in snapshot.children {
                    friends.append(User(fromFDataSnapshot: item as! FDataSnapshot))
                }
                completionHandler(friends: friends)
            }
        } else {
            completionHandler(friends: [])
        }
    }
    
    // MARK: wishes functions
    
    /** creates or updates a wish */
    func save(wish wish: Wish, forUser user: User, completionHandler: (error: NSError?, key: String) -> Void) {
        if let ref = userWishesRef(user.id) {
            if let id = wish.id {
                ref.childByAppendingPath(id).updateChildValues(wish.attributesForFirebase, withCompletionBlock: { (error, ref) -> Void in
                    completionHandler(error: error, key: ref.key)
                })
            } else {
                ref.childByAutoId().updateChildValues(wish.attributesForFirebase, withCompletionBlock: { (error, ref) -> Void in
                    completionHandler(error: error, key: ref.key)
                })
            }
        } else {
            completionHandler(error: NSError(domain: MyWishListFirebaseClientDomain,
                code: FirebaseClientErrorCode.RefNotCreated.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Unable to save wish: Firebase location reference not created",
                    NSLocalizedFailureReasonErrorKey : "current user wishes ref not present, wishId: \(wish.id)"
                ]), key: "")
        }
    }
    
    /** updates wish attributes without over-writing the entire wish */
    func updateWishAttributes(userId: String, wishId: String, attributes: [String : AnyObject], completionHandler: (NSError?) -> Void) {
        if let ref = userWishesRef(userId) {
            ref.childByAppendingPath(wishId).updateChildValues(attributes)
            completionHandler(nil)
        } else {
            completionHandler(NSError(domain: MyWishListFirebaseClientDomain,
                code: FirebaseClientErrorCode.RefNotCreated.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Unable to update wish attributes: Firebase location reference not created",
                    NSLocalizedFailureReasonErrorKey : "userWishes ref not present, userId \(userId) wishId: \(wishId)"
                ]))
        }
    }
    
    /** deleted the wish if it exists */
    func deleteWish(wish wish: Wish, completionHandler: (NSError?) -> Void) {
        if let ref = currentUserWishesRef() {
            if let wishId = wish.id {
                ref.childByAppendingPath(wishId).removeValueWithCompletionBlock({ (error, ref) -> Void in
                    completionHandler(error)
                })
            }
        } else {
            completionHandler(NSError(domain: MyWishListFirebaseClientDomain,
                code: FirebaseClientErrorCode.RefNotCreated.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Unable to delete wish: Firebase location reference not created",
                    NSLocalizedFailureReasonErrorKey : "current user wishes ref not present, wishId: \(wish.id)"
                ]))
        }
    }
    
    /** Queries wishes passes results to handler */
    func queryWishes(forUser user: User, filter: (Wish) -> Bool = {(Wish) -> Bool in return true }, listenForUpdates: Bool = true, completionHandler: (wishes: [Wish]) -> Void) {
        if let ref = userWishesRef(user.id) {
            if listenForUpdates {
                ref.queryOrderedByChild(Wish.Keys.title).observeEventType(FEventType.Value) { (snapshot: FDataSnapshot!) -> Void in
                    var wishes: [Wish] = []
                    for item in snapshot.children {
                        wishes.append(Wish(fromFDataSnapshot: item as! FDataSnapshot))
                    }
                    wishes = wishes.filter(filter)
                    completionHandler(wishes: wishes)
                }
            } else {
                ref.queryOrderedByChild(Wish.Keys.title).observeSingleEventOfType(FEventType.Value) { (snapshot: FDataSnapshot!) -> Void in
                    var wishes: [Wish] = []
                    for item in snapshot.children {
                        wishes.append(Wish(fromFDataSnapshot: item as! FDataSnapshot))
                    }
                    wishes = wishes.filter(filter)
                    completionHandler(wishes: wishes)
                }
            }
        } else {
            completionHandler(wishes: [])
        }
    }
    
    /** listens for any wishes removed from firebase and returns them to the handler */
    func listenForWishDeletes(forUser user: User, completionHandler: (wish: Wish) -> Void) {
        if let ref = userWishesRef(user.id) {
            ref.observeEventType(FEventType.ChildRemoved, withBlock: { (dataSnapshot) in
                completionHandler(wish: Wish(fromFDataSnapshot: dataSnapshot))
            })
        }
    }
    
    func queryNotifications(forUser user: User, listenForUpdates: Bool = true, completionHandler: (notifications: [Notification]) -> Void) {
        if let ref = userNotificationsRef(user.id) {
            if listenForUpdates {
                ref.queryOrderedByKey().observeEventType(FEventType.Value) { (snapshot: FDataSnapshot!) -> Void in
                    var notifications: [Notification] = []
                    for item in snapshot.children {
                        notifications.append(Notification(fromFDataSnapshot: item as! FDataSnapshot))
                    }
                    completionHandler(notifications: notifications)
                }
            } else {
                ref.queryOrderedByKey().observeSingleEventOfType(FEventType.Value) { (snapshot: FDataSnapshot!) -> Void in
                    var notifications: [Notification] = []
                    for item in snapshot.children {
                        notifications.append(Notification(fromFDataSnapshot: item as! FDataSnapshot))
                    }
                    completionHandler(notifications: notifications)
                }
            }
        }
    }
    
    func sendNotification(notification: Notification, toUser user: User) {
        if let ref = userNotificationsRef(user.id) {
            ref.childByAutoId().updateChildValues([
                Notification.TYPE: notification.type.rawValue,
                Notification.TITLE: notification.title,
                Notification.MESSAGE: notification.message
            ], withCompletionBlock: { (error, ref) in
                print("\(error) \(ref)")
            })
        }
    }
    
    func deleteNotification(notification: Notification, forUser user: User) {
        if let ref = userNotificationsRef(user.id) {
            ref.childByAppendingPath(notification.id!).removeValue()
        }
    }
}
