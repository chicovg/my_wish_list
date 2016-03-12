//
//  KeychainClient.swift
//  MyWishList
//
//  Created by Victor Guthrie on 3/12/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import SimpleKeychain

class KeychainClient {
    
    static let sharedInstance = KeychainClient()
    
    let AUTH_SERVICE = "Auth0"
    let ACCESS_GROUP = "com.chicovg.wishlist"
    let TOKEN_KEY = "MyWishListTokenKey"
    let PROMPT_MESSAGE = "Would you like this app to access your keychain?"
    
    func saveAccessToken(token: String) -> Bool {
        let keychain = A0SimpleKeychain(service: AUTH_SERVICE, accessGroup: ACCESS_GROUP)
        return keychain.setString(token, forKey: TOKEN_KEY, promptMessage: PROMPT_MESSAGE)
    }
    
    func currentAccessToken() -> String? {
        let keychain = A0SimpleKeychain(service: AUTH_SERVICE, accessGroup: ACCESS_GROUP)
        return keychain.stringForKey(TOKEN_KEY, promptMessage: PROMPT_MESSAGE)
    }
    
}
