//
//  CoreDataClientTest.swift
//  MyWishList
//
//  Created by Victor Guthrie on 5/29/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import XCTest
import Foundation
import CoreData
@testable import MyWishList


class CoreDataClientTests: XCTestCase {
    
    var coreDataClient = CoreDataClient.sharedInstance
    
    let testUser = User(id: "test", name: "Test User", pictureUrl: "http://pictures.com")
    
    lazy var wishListFRC: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: WishEntity.ENTITY_NAME)
        fetchRequest.predicate = NSPredicate(format: "user.id == %@", self.testUser.id)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: Wish.Keys.status, ascending: false),
            NSSortDescriptor(key: Wish.Keys.title, ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))),
        ]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.coreDataClient.sharedContext,
                                                                  sectionNameKeyPath: Wish.Keys.status,
                                                                  cacheName: nil)
        return fetchedResultsController
    }()
    
    lazy var friendsListFRC: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: FriendshipEntity.ENTITY_NAME)
        fetchRequest.predicate = NSPredicate(format: "user.id == %@", self.testUser.id)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "friend.\(User.Keys.name)", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.coreDataClient.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        return fetchedResultsController
    }()
    
    lazy var promisedWishListFRC: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: WishPromiseEntity.ENTITY_NAME)
        fetchRequest.predicate = NSPredicate(format: "promisedBy.id == %@", self.testUser.id)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "\(Wish.Keys.promisedOn)", ascending: false)
        ]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.coreDataClient.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        return fetchedResultsController
    }()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        coreDataClient.delete(testUser)
    }
    
    // MARK: WishEntity functions
    func testCreateWish() {
        let wish = Wish(id: "testCreateWish", title: "test wish", link: "http://wish/url", detail: "A test wish for a test user")
        guard let wishEntity = coreDataClient.upsert(wish: wish, forUser: testUser) else {
            XCTFail("wish not created")
            return
        }
        coreDataClient.saveContext()
        
        XCTAssert(wishEntity.title == wish.title)
        XCTAssert(wishEntity.link == wish.link)
        XCTAssert(wishEntity.detail == wish.detail)
        XCTAssert(wishEntity.user.id == testUser.id)
        
        XCTAssert(fetch(wishListFRC).fetchedObjects!.count == 1)
    }
    
    func testUpdateWish() {
        let wish = Wish(id: "testUpdateWish", title: "test wish", link: "http://wish/url", detail: "A test wish for a test user")
        guard let wishEntity = coreDataClient.upsert(wish: wish, forUser: testUser) else {
            XCTFail("wish not created")
            return
        }
        coreDataClient.saveContext()
        
        let updtWish = Wish(id: wish.id!, title: "test wish updt", link: wish.link!, detail: wish.detail!)
        guard let wishEntityUpdt = coreDataClient.upsert(wish: updtWish, forUser: testUser) else {
            XCTFail("wish not updated")
            return
        }
        coreDataClient.saveContext()
        
        XCTAssert(wishEntity.objectID == wishEntityUpdt.objectID)
        XCTAssert(wishEntity.id == wishEntity.id)
        XCTAssert(wishEntityUpdt.title == updtWish.title)
        XCTAssert(wishEntityUpdt.link == updtWish.link)
        XCTAssert(wishEntityUpdt.detail == updtWish.detail)
        XCTAssert(wishEntityUpdt.link == wish.link)
        XCTAssert(wishEntityUpdt.detail == wish.detail)
        XCTAssert(wishEntityUpdt.user.userValue == testUser)
        
        XCTAssert(fetch(wishListFRC).fetchedObjects!.count == 1)
    }
    
    func testPromiseWish() {
        let otherUser = User(id: "other", name: "Other User", pictureUrl: "http://pics.net/123")
        let promisedOn = NSDate()
        let wish = Wish(id: "testPromiseWish", title: "test wish", link: nil, detail: nil, status: Wish.Status.Promised, promisedBy: testUser, promisedOn: promisedOn, grantedOn: nil)
        
        guard let wishEntity = coreDataClient.upsert(wish: wish, forUser: otherUser) else {
            XCTFail("wish not created")
            return
        }
        coreDataClient.saveContext()
        
        XCTAssert(wishEntity.wishPromise!.promisedBy.userValue == testUser)
        XCTAssert(wishEntity.wishPromise!.promisedOn == promisedOn)
        XCTAssert(wishEntity.wishPromise!.wish.id == wish.id)
        
        XCTAssert(fetch(promisedWishListFRC).fetchedObjects!.count == 1)

        coreDataClient.delete(otherUser)
        coreDataClient.saveContext()
        
        XCTAssert(fetch(promisedWishListFRC).fetchedObjects!.count == 0)
    }
    
    func testCreateUser() {
        let user = User(id: "testCreateUser", name: "Test User", pictureUrl: "http://picture.com")
        guard let userEntity = coreDataClient.upsert(user: user) else {
            XCTFail("User not created")
            return
        }
        coreDataClient.saveContext()
        
        XCTAssert(userEntity.id == user.id)
        XCTAssert(userEntity.name == user.name)
        XCTAssert(userEntity.pictureUrl == user.pictureUrl)
        
        guard let _ = coreDataClient.find(userById: user.id) else {
            XCTFail("Unable to find created user")
            return
        }
        
        coreDataClient.delete(userEntity)
    }
    
    func testUpdateUser() {
        let user = User(id: "testUpdateUser", name: "Test User", pictureUrl: "http://picture.com")
        guard let userEntity = coreDataClient.upsert(user: user) else {
            XCTFail("User not created")
            return
        }
        coreDataClient.saveContext()
        
        XCTAssert(userEntity.id == user.id)
        XCTAssert(userEntity.name == user.name)
        XCTAssert(userEntity.pictureUrl == user.pictureUrl)
        
        let updatedUser = User(id: "testUpdateUser", name: "Test User Updated", pictureUrl: "http://picture.com")
        guard let updatedUserEntity = coreDataClient.upsert(user: updatedUser) else {
            XCTFail("User not updated")
            return
        }
        coreDataClient.saveContext()
        
        XCTAssert(updatedUserEntity.id == updatedUser.id)
        XCTAssert(updatedUserEntity.id == userEntity.id)
        
        XCTAssert(updatedUserEntity.name == updatedUser.name)
        XCTAssert(updatedUserEntity.name == userEntity.name)
        
        XCTAssert(updatedUserEntity.pictureUrl == updatedUser.pictureUrl)
        XCTAssert(updatedUserEntity.pictureUrl == userEntity.pictureUrl)
        
        coreDataClient.delete(updatedUserEntity)
    }
    
    func testSaveFriend() {
        let friend = User(id: "testFriend", name: "Bob Slidell", pictureUrl: "http://gifrific.com/wp-content/uploads/2013/04/Bob-Office-Space-Licking-Upper-Lip-320x320.gif")
        coreDataClient.upsert(friend: friend, ofUser: testUser)
        coreDataClient.saveContext()
        
        XCTAssert(fetch(friendsListFRC).fetchedObjects?.count == 1)
        
        coreDataClient.upsert(friend: friend, ofUser: testUser)
        coreDataClient.saveContext()
        
        fetch(friendsListFRC)
        XCTAssert(friendsListFRC.fetchedObjects!.count == 1)
        
        let friendshipEntity = friendsListFRC.fetchedObjects![0] as! FriendshipEntity
        XCTAssert(friendshipEntity.user.id == testUser.id)
        XCTAssert(friendshipEntity.user.name == testUser.name)
        XCTAssert(friendshipEntity.user.pictureUrl == testUser.pictureUrl)
        XCTAssert(friendshipEntity.friend.id == friend.id)
        XCTAssert(friendshipEntity.friend.name == friend.name)
        XCTAssert(friendshipEntity.friend.pictureUrl == friend.pictureUrl)
        
        XCTAssert(fetch(friendsListFRC).fetchedObjects!.count == 1)
    }
    
    private func fetch(fetchedResultsController: NSFetchedResultsController) -> NSFetchedResultsController {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            XCTFail("Error in fetch(): \(error)")
        }
        return fetchedResultsController
    }
    
}
