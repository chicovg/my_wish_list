//
//  FirebaseClient.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/21/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import Firebase

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
    
    var currentUserRef: Firebase?
    var currentUser: User? // TODO: do I need this?
    
    var currentUserFriendsRef: Firebase? {
        return currentUserRef?.childByAppendingPath(FRIENDS_PATH)
    }
    
    var currentUserWishesRef: Firebase? {
        return currentUserRef?.childByAppendingPath(WISHES_PATH)
    }
    
    // MARK: users functions
    func authenticateWithFacebook(accessToken: String, handler: (user: User?, error: NSError?) -> Void) {
        rootRef.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: { error, authData in
            if let authData = authData {
                print("Logged in! \(authData)")
                let user = User(fromFacebookAuthData: authData)
                self.setCurrentUser(user)
                handler(user: user, error: nil)
            } else {
                print("Login failed. \(error)")
                handler(user: nil, error: error)
            }
        })
    }
    
    private func setCurrentUser(user: User) {
        currentUserRef = rootRef.childByAppendingPath(USERS_PATH).childByAppendingPath(user.id)
        currentUser = user
        save(user: user)
    }
    
    func save(user user: User) {
        if let ref = currentUserRef {
            ref.updateChildValues(user.toValuesDictionary())
        } else {
            // handle
        }
    }
    
    // MARK: friends functions
    func save(friendsList friends: [User]) {
        if let ref = currentUserFriendsRef {
            let friendsValues = friends.reduce([:]) { (var dict, friend) -> [String : [String: AnyObject]] in
                dict[friend.id] = friend.toValuesDictionary()
                return dict
            }
            ref.updateChildValues(friendsValues)
        } else {
            // handle
        }
    }
    
    func queryFriends(completionHandler: (friends: [User]) -> Void) {
        if let ref = currentUserFriendsRef {
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
        save(wish: wish) { (error) -> Void in
            if let error = error {
                print("Save failed: \(error)")
            }
        }
    }
    
    func save(wish wish: Wish, completionHandler: (NSError?) -> Void) {
        if let ref = currentUserWishesRef {
            if let id = wish.id {
                ref.childByAppendingPath(id).updateChildValues(wish.toValuesDictionary(), withCompletionBlock: { (error, ref) -> Void in
                    completionHandler(error)
                })
            } else {
                ref.childByAutoId().updateChildValues(wish.toValuesDictionary(), withCompletionBlock: { (error, ref) -> Void in
                    completionHandler(error)
                })
            }
        } else {
            // handle
        }
    }
    
    func deleteWish(wish wish: Wish, completionHandler: (NSError?) -> Void) {
        if let ref = currentUserWishesRef {
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
        if let ref = currentUserWishesRef {
            ref.queryOrderedByChild(Wish.Keys.title).observeEventType(FEventType.Value) { (snapshot: FDataSnapshot!) -> Void in
                var wishes: [Wish] = []
                for item in snapshot.children {
                    wishes.append(Wish(fromFDataSnapshot: item as! FDataSnapshot))
                }
                completionHandler(wishes: wishes)
            }
        } else {
            completionHandler(wishes: [])
        }
    }
    
    func queryWishes(forUser user: User, completionHandler: (wishes: [Wish]) -> Void) {
        let ref = rootRef.childByAppendingPath(USERS_PATH).childByAppendingPath(user.id).childByAppendingPath(WISHES_PATH)
        ref.queryOrderedByChild(Wish.Keys.title).observeEventType(FEventType.Value) { (snapshot: FDataSnapshot!) -> Void in
            var wishes: [Wish] = []
            for item in snapshot.children {
                wishes.append(Wish(fromFDataSnapshot: item as! FDataSnapshot))
            }
            completionHandler(wishes: wishes)
        }
    }
    
}
