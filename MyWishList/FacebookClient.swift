//
//  FBClient.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/13/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import FBSDKLoginKit

class FacebookClient : HTTPClient {
    
    static let sharedInstance = FacebookClient()
    
    let MAX_PAGE_SIZE = 25
    
    func currentAccessToken() -> FBSDKAccessToken? {
        return FBSDKAccessToken.currentAccessToken()
    }
    
    func login(viewController: UIViewController, handler: (result: FBSDKLoginManagerLoginResult!, error: NSError!) -> Void) {
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logInWithReadPermissions(["email","public_profile","user_friends"], fromViewController: viewController) { (facebookResult, facebookError) -> Void in
            handler(result: facebookResult, error: facebookError)
        }
    }
    
    func logout() {
        FBSDKLoginManager().logOut()
    }
    
    func getMe(completionHandler: (result: User?) -> Void) {
        let params = ["fields": "id,name,picture"]
        let request = FBSDKGraphRequest(graphPath: "/me", parameters: params)
        request.startWithCompletionHandler {
            connection, result, error in
            if let result = result as? [String : AnyObject] {
                completionHandler(result: User(fromJson: result))
            }
        }
    }
    
    func getFriends(completionHandler: (result: [User]) -> Void) {
        let params = ["fields": "id,name,picture", "limit": "\(MAX_PAGE_SIZE)"]
        let request = FBSDKGraphRequest(graphPath: "/me/friends", parameters: params)
        request.startWithCompletionHandler {
            connection, result, error in
            if let result = result as? [String : AnyObject], data = result["data"] as? [[String: AnyObject]] where data.count > 0 {
                completionHandler(result: self.mapFriends(fromJsonArray: data))
                
                if let paging = result["paging"] as? [String : AnyObject],
                    next = paging["next"] as? String {
                    self.getAdditonalFriends(next, completionHandler: completionHandler)
                }
            }
        }
    }
    
    private func getAdditonalFriends(url: String, completionHandler: (result: [User]) -> Void) {
        let httpHeaders: [String : String] = [:]
        get(url, httpHeaders: httpHeaders) {
            data, response, error in
            let httpResponse = self.buildJsonResponse(data, response: response, error: error)
            if let result = httpResponse.parsedResult as? [String : AnyObject], data = result["data"] as? [[String: AnyObject]] where data.count > 0 {
                completionHandler(result: self.mapFriends(fromJsonArray: data))
                
                if let paging = result["paging"] as? [String : AnyObject],
                    next = paging["next"] as? String {
                        self.getAdditonalFriends(next, completionHandler: completionHandler)
                }
            }
        }
    }
    
    private func mapFriends(fromJsonArray array: [[String: AnyObject]]) -> [User] {
        return array.map({ (json: [String: AnyObject]) -> User? in
            return User(fromJson: json)
        }).flatMap({ $0 })
    }
    
    func getImage(urlString: String, completionHandler: (response: HTTPResponse) -> Void) {
        let httpHeaders: [String : String] = [:]
        get(urlString, httpHeaders: httpHeaders) {
            data, response, error in
            let httpResponse = self.buildResponse(data, response: response, error: error)
            completionHandler(response: httpResponse)
        }
    }
    
}
