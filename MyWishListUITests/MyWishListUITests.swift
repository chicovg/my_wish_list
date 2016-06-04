//
//  MyWishListUITests.swift
//  MyWishListUITests
//
//  Created by Victor Guthrie on 1/23/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import XCTest
import Darwin

class MyWishListUITests: XCTestCase {
    
    let TIMEOUT: Double = 10
    
    let joeTester: (email: String, password: String) = ("joe_ylfwhbi_tester@tfbnw.net", "pass123")
    let joeTestersWishList: [(title: String, description: String?, link: String?)] = [
        ("", nil, nil)
    ]
    
    let charlieFallerman: (email: String, password: String) = ("charlie_fmvuwoq_fallerman@tfbnw.net", "pass123")
    let charlieFallermansWishList: [(title: String, description: String?, link: String?)] = [
        ("", nil, nil)
    ]
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}
