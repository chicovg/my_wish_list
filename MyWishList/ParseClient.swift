//
//  ParseClient.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/24/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation

class ParseResponse {
    let httpResponse: HTTPResponse
    
    init(httpResponse: HTTPResponse){
        self.httpResponse = httpResponse
    }
    
    func success() -> Bool {
        return self.httpResponse.success
    }
    
    func jsonContent() -> [String : AnyObject]? {
        return httpResponse.parsedResult as? [String : AnyObject]
    }
}

class ParseClient : HTTPClient {
    
    static let sharedInstance = ParseClient()
    
    var dateFormatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"
        return formatter
    }()
    
    let baseUrl = "https://api.parse.com/1/classes/Wish"
    
    let parseAppIdHeader = "X-Parse-Application-Id"
    let parseRestApiKeyHeader = "X-Parse-REST-API-Key"
    
    let parseAppId = "IvqBmK9jEWl58zKzHBgnNE667OfXzy5xZNqMBiwm"
    let parseRestApiKey = "EdbBRRE0ud0S9VFMiTZyPrZ3nVpHxK27nJkHSihP"

    /**
        fetches all wishes saved by this user
    */
    func fetchAllWishes(userId: String, completionHandler: (response: ParseResponse) -> Void) {
        let httpHeaders = [parseAppIdHeader: parseAppId, parseRestApiKeyHeader : parseRestApiKey]
        get("\(baseUrl)?where={\"userId\":\"\(userId)\"}", httpHeaders: httpHeaders) {
            data, response, error in
            let httpResponse = self.buildJsonResponse(data, response: response, error: error)
            completionHandler(response: ParseResponse(httpResponse: httpResponse))
        }
    }
    
    /** 
        Persists a new wish via Parse API
    */
    func persistWish(wish: Wish, completionHandler: (response: ParseResponse) -> Void) {
        let httpHeaders = [parseAppIdHeader: parseAppId, parseRestApiKeyHeader : parseRestApiKey]
        let httpBody = wish.toJsonString()
        post(baseUrl, httpHeaders: httpHeaders, httpBody: httpBody) {
            data, response, error in
            let httpResponse = self.buildJsonResponse(data, response: response, error: error)
            completionHandler(response: ParseResponse(httpResponse: httpResponse))
        }
    }
    
    /**
        Updates an existing wish via Parse API
    */
    func updateWish(wish: Wish, completionHandler: (response: ParseResponse) -> Void) {
        let httpHeaders = [parseAppIdHeader: parseAppId, parseRestApiKeyHeader : parseRestApiKey]
        let updateUrl = "\(baseUrl)/\(wish.objectId!)"
        let httpBody = wish.toJsonString()
        put(updateUrl, httpHeaders: httpHeaders, httpBody: httpBody) {
            data, response, error in
            let httpResponse = self.buildJsonResponse(data, response: response, error: error)
            completionHandler(response: ParseResponse(httpResponse: httpResponse))
        }
    }
    
    /**
        Deletes an existing wish via Parse API
     */
    func deleteWish(wishId: String, completionHandler: (response: ParseResponse) -> Void) {
        let httpHeaders = [parseAppIdHeader: parseAppId, parseRestApiKeyHeader : parseRestApiKey]
        let deleteUrl = "\(baseUrl)/\(wishId)"
        delete(deleteUrl, httpHeaders: httpHeaders) {
            data, response, error in
            let httpResponse = self.buildResponse(data, response: response, error: error)
            completionHandler(response: ParseResponse(httpResponse: httpResponse))
        }
    }
    
}