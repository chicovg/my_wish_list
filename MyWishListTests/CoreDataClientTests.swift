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
    
    var createdObjects: [NSManagedObject] = []
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
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
    
    func testCreateWish() {
        let user = User(id: "testCreateWish", name: "Test User", pictureUrl: "http://picture.com")
        guard let userEntity = coreDataClient.upsert(user: user) else {
            XCTFail("User not created")
            return
        }
        coreDataClient.saveContext()
        
        let wish = Wish(id: "testWish1", title: "test wish 1", link: "http://wish/url", detail: "A test wish for a test user")
        guard let wishEntity = coreDataClient.upsert(wish: wish, forUser: userEntity) else {
            XCTFail("wish not created")
            return
        }
        coreDataClient.saveContext()
        
        XCTAssert(wishEntity.title == wish.title)
        XCTAssert(wishEntity.link == wish.link)
        XCTAssert(wishEntity.detail == wish.detail)
        XCTAssert(wishEntity.user == userEntity)
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
