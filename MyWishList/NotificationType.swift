//
//  Notification.swift
//  MyWishList
//
//  Created by Victor Guthrie on 7/16/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import Firebase

let GIFT_PROMISED_MESSAGE = "A friend just promised to grant one of your wishes!"

enum NotificationType: String {
    case GiftPromised = "GiftPromised"
    
    var notification: Notification {
        switch self {
        case .GiftPromised :
            return Notification(message: GIFT_PROMISED_MESSAGE)
        }
    }
}

struct Notification {
    static let MESSAGE = "message"
    
    var id: String?
    let message: String
    
    init(message: String) {
        self.message = message
    }
    
    init(fromFDataSnapshot snapshot: FDataSnapshot!) {
        self.id = snapshot.key
        self.message = snapshot.childSnapshotForPath(Notification.MESSAGE).value as! String
    }
}


