//
//  FBClient.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/13/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import FBSDKCoreKit

class FBCredentials {
    static let sharedInstance = FBCredentials()
    
    var token: FBSDKAccessToken?
    
    func currentFacebookId() -> String? {
        if let token = token {
            return token.userID
        }
        return nil
    }
}

class FBClient : HTTPClient {
    
    static let sharedInstance = FBClient()

    func getFriends(completionHandler: (result: [String: AnyObject]) -> Void) {
        let params = ["fields": "id,name,picture"]
        let request = FBSDKGraphRequest(graphPath: "/me/friends", parameters: params)
        request.startWithCompletionHandler {
            connection, result, error in
            if let result = result as? [String : AnyObject] {
                completionHandler(result: result)
            }
            print(result)
        }
    }
    
    func getImage(urlString: String, completionHandler: (response: HTTPResponse) -> Void) {
        let httpHeaders: [String : String] = [:]
        self.get(urlString, httpHeaders: httpHeaders) {
            data, response, error in
            let httpResponse = self.buildResponse(data, response: response, error: error)
            completionHandler(response: httpResponse)
        }
    }
    
}
