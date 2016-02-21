//
//  FriendService.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/14/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation

class FriendService : SyncService {
    
    static let sharedInstance = FriendService()
    
    func fetchFriends() {
        facebookClient.getFriends() {
            result in
            if let data = result["data"] as? [[String : AnyObject]] {
                for friendJson in data {
                    if let userId = friendJson["id"] as? String, friend = self.fetchFriend(byUserId: userId) {
                        friend.updateFromJson(friendJson)
                    } else if let _ = friendJson["id"] as? String {
                        let _ = Friend(dictionary: friendJson, context: self.sharedContext)
                    }
                }
                self.sendNotification(.Fetch, status: .Successful, entity: Friend.ENTITY_NAME, additionalInfo: "Fetched remote data successfully!")
            }
        }
    }
    
    private func fetchFriend(byUserId userId : String) -> Friend? {
        if let results = CoreDataManager.sharedInstance.queryEntity(withEntityName: Friend.ENTITY_NAME, withPredicatFormat: "id == %@", andArguments: [userId]) {
            if results.count > 0 {
                return results[0] as? Friend
            }
        }
        return nil
    }
    
}