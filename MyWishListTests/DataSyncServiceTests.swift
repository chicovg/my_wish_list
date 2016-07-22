//
//  DataSyncServiceTests.swift
//  MyWishList
//
//  Created by Victor Guthrie on 6/25/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import XCTest
@testable import MyWishList

class DataSyncServiceTests: XCTestCase {
    
    var dataSyncService = DataSyncService.sharedInstance
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCompleteWishFlow() {
        // create 2 users
        dataSyncService.facebookClient
        
        
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
