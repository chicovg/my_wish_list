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

class FirebaseClient {
    
    static let sharedInstance = FirebaseClient()
    
    let USERS_PATH = "users"
    let FRIENDS_PATH = "friends"
    let WISHES_PATH = "wishes"
            
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
    
    func removeAllObservers() {
        rootRef.removeAllObservers()
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
    
    func save(user user: User) {
        if let ref = currentUserRef() {
            ref.updateChildValues(user.attributes)
        } else {
            // handle
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
        } else {
            // handle
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
    func save(wish wish: Wish) {
        save(wish: wish) { (error, key) -> Void in
            if let error = error {
                print("Save failed: \(error)")
            }
        }
    }
    
    func save(wish wish: Wish, completionHandler: (error: NSError?, key: String) -> Void) {
        if let ref = currentUserWishesRef() {
            if let id = wish.id {
                ref.childByAppendingPath(id).updateChildValues(wish.attributes, withCompletionBlock: { (error, ref) -> Void in
                    completionHandler(error: error, key: ref.key)
                })
            } else {
                ref.childByAutoId().updateChildValues(wish.attributes, withCompletionBlock: { (error, ref) -> Void in
                    completionHandler(error: error, key: ref.key)
                })
            }
        } else {
            // handle
        }
    }
    
    func deleteWish(wish wish: Wish, completionHandler: (NSError?) -> Void) {
        if let ref = currentUserWishesRef() {
            if let wishId = wish.id {
                ref.childByAppendingPath(wishId).removeValueWithCompletionBlock({ (error, ref) -> Void in
                    completionHandler(error)
                })
            }
        } else {
            // handle
        }
    }
    
    func queryWishes(completionHandler: (wishes: [Wish]) -> Void) {
        if let ref = currentUserWishesRef() {
            queryWishes(ref, completionHandler: completionHandler)
        } else {
            completionHandler(wishes: [])
        }
    }
    
    func queryWishes(forUser user: User, completionHandler: (wishes: [Wish]) -> Void) {
        if let ref = userWishesRef(user.id) {
            queryWishes(ref, completionHandler: completionHandler)
        } else {
            completionHandler(wishes: [])
        }
    }
    
    func queryUngrantedWishes(forUser user: User, completionHandler: (wishes: [Wish]) -> Void) {
        if let ref = userWishesRef(user.id) {
            queryWishes(ref) { (wishes: [Wish]) -> Void in
                completionHandler(wishes: wishes.filter({ (wish: Wish) -> Bool in
                    return wish.granted == false
                }))
            }
        } else {
            completionHandler(wishes: [])
        }
    }
    
    private func queryWishes(ref: FQuery, filter: (Wish) -> Bool = {(Wish) -> Bool in return true }, completionHandler: (wishes: [Wish]) -> Void) {
        ref.queryOrderedByChild(Wish.Keys.title).observeEventType(FEventType.Value) { (snapshot: FDataSnapshot!) -> Void in
            var wishes: [Wish] = []
            for item in snapshot.children {
                wishes.append(Wish(fromFDataSnapshot: item as! FDataSnapshot))
            }
            wishes = wishes.filter(filter)
            completionHandler(wishes: wishes)
        }
    }
    
    func grantWish(userId: String, wishId: String, completionHandler: (NSError?) -> Void) {
        if let ref = userWishesRef(userId) {
            ref.childByAppendingPath(wishId).updateChildValues([Wish.Keys.granted : true])
        }
    }
    
}
