//
//  SyncService.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/24/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import CoreData

let SYNC_RESULT_NOTIFICATION = "SyncResultNotification"

class SyncResult {
    let action : SyncAction
    let status : SyncStatus
    let entity : String
    let additionalInfo : String
    init(action : SyncAction, status : SyncStatus, entity: String, additionalInfo : String){
        self.action = action
        self.status = status
        self.entity = entity
        self.additionalInfo = additionalInfo
    }
}

enum SyncAction {
    case Save
    case Fetch
}

enum SyncStatus {
    case Successful
    case RemoteFailed
    case LocalFailed
}

class SyncService {
        
    var parseClient: ParseClient {
        return ParseClient.sharedInstance
    }
    
    var facebookClient: FBClient {
        return FBClient.sharedInstance
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    var currentFacebookId: String? {
        return FBCredentials.sharedInstance.currentFacebookId()
    }
    
    func saveContext() -> Bool {
        return CoreDataManager.sharedInstance.saveContext()
    }
    
    func sendNotification(action: SyncAction, status: SyncStatus, entity: String, additionalInfo: String) {
        let notification = NSNotification(name: SYNC_RESULT_NOTIFICATION, object: SyncResult(action: action, status: status, entity: entity, additionalInfo: additionalInfo))
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    // TODO: need network activity indicator
    
}
