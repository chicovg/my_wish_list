//
//  Notification.swift
//  MyWishList
//
//  Created by Victor Guthrie on 7/16/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import Firebase

let GIFT_PROMISED_TITLE = "Great News!"
let GIFT_PROMISED_MESSAGE = "A friend just promised to grant your wish: %@!"
let GIFT_UNPROMISED_TITLE = "Oh No!"
let GIFT_UNPROMISED_MESSAGE = "A friend is no longer able to grant your wish: %@."
let GIFT_RECEIVED_TITLE = "Great News!"
let GIFT_RECEIVED_MESSAGE = "Your friend %@ has received your gift: %@!"

enum NotificationType: String {
    case GiftPromised = "GiftPromised"
    case GiftUnpromised = "GiftUnpromised"
    case GiftReceived = "GiftReceived"
    
    func notification(messageArgs: [CVarArgType]) -> Notification {
        switch self {
        case .GiftPromised :
            return Notification(type: self, title: GIFT_PROMISED_TITLE, message: GIFT_PROMISED_MESSAGE, messageArgs: messageArgs)
        case .GiftUnpromised :
            return Notification(type: self, title: GIFT_UNPROMISED_TITLE, message: GIFT_UNPROMISED_MESSAGE, messageArgs: messageArgs)
        case .GiftReceived :
            return Notification(type: self, title: GIFT_RECEIVED_TITLE, message: GIFT_RECEIVED_MESSAGE, messageArgs: messageArgs)
        }
    }
}

struct Notification {
    static let TITLE = "title"
    static let MESSAGE = "message"
    static let TYPE = "type"
    
    var id: String?
    let title: String
    let message: String
    let type: NotificationType
    
    init(type: NotificationType, title: String, message: String) {
        self.title = title
        self.message = message
        self.type = type
    }
    
    init(type: NotificationType, title: String, message: String, messageArgs: [CVarArgType]) {
        self.init(type: type, title: title, message: String(format: message, arguments: messageArgs))
    }
    
    init(fromFDataSnapshot snapshot: FDataSnapshot!) {
        self.id = snapshot.key
        self.title = snapshot.childSnapshotForPath(Notification.TITLE).value as! String
        self.message = snapshot.childSnapshotForPath(Notification.MESSAGE).value as! String
        self.type = NotificationType(rawValue: snapshot.childSnapshotForPath(Notification.TYPE).value as! String)!
    }
}


