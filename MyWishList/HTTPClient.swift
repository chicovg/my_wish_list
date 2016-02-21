//
//  HTTPClient.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/24/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation

let unknownHttpErrorMsg = "Unknown Error"
let successHttpErrorMsg = "Successful Response"

struct HTTPResponse {
    let success: Bool
    var errorMsg: String = unknownHttpErrorMsg
    var data: NSData?
    var parsedResult: AnyObject?
    
    init(success: Bool, errorMsg: String, parsedResult: AnyObject?, data: NSData?) {
        self.success = success
        self.errorMsg = errorMsg
        self.parsedResult = parsedResult
        self.data = data
    }
    
    init(success: Bool, errorMsg: String, parsedResult: AnyObject?) {
        self.init(success: success, errorMsg: errorMsg, parsedResult: parsedResult, data: nil)
    }
    
    init(success: Bool, errorMsg: String, data: NSData?) {
        self.init(success: success, errorMsg: errorMsg, parsedResult: nil, data: data)
    }
    
    init(success: Bool, errorMsg: String) {
        self.init(success: success, errorMsg: errorMsg, parsedResult: nil, data: nil)
    }
}

class HTTPClient {
    
    /**
     Executes a GET request with the specified url and headers
     The completion handler is executed after the request returns
     */
    func get(url: String, httpHeaders: [String: String]?, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        sendRequest(buildRequest(url, method: "GET", httpHeaders: httpHeaders, httpBody: nil), completionHandler: completionHandler)
    }
    
    /**
     Executes a POST request with the specified url, headers, and request body
     The completion handler is executed after the request returns
     */
    func post(url: String, httpHeaders: [String: String]?, httpBody: String, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        sendRequest(buildRequest(url, method: "POST", httpHeaders: httpHeaders, httpBody: httpBody), completionHandler: completionHandler)
    }
    
    /**
     Executes a PUT request with the specified url, headers, and request body
     The completion handler is executed after the request returns
     */
    func put(url: String, httpHeaders: [String: String]?, httpBody: String, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        sendRequest(buildRequest(url, method: "PUT", httpHeaders: httpHeaders, httpBody: httpBody), completionHandler: completionHandler)
    }
    
    /**
     Executes a DELETE request with the specified url, and headers
     The completion handler is executed after the request returns
     */
    func delete(url: String, httpHeaders: [String: String]?, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        sendRequest(buildRequest(url, method: "DELETE", httpHeaders: httpHeaders, httpBody: nil), completionHandler: completionHandler)
    }
    
    /**
      Converts data, nsurl response, and error into HTTPResponse struct
    */
    func buildResponse(data: NSData?, response: NSURLResponse?, error: NSError?) -> HTTPResponse {
        guard (error == nil) else {
            print("There was an error with your request: \(error)")
            return HTTPResponse(success: false, errorMsg: "\(error)")
        }
        
        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
            if let response = response as? NSHTTPURLResponse {
                print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                return HTTPResponse(success: true, errorMsg: "Invalid Response : \(response.statusCode)")
            } else if let response = response {
                print("Your request returned an invalid response! Response: \(response)!")
                return HTTPResponse(success: true, errorMsg: "Invalid Response : \(response)")
            } else {
                print("Your request returned an invalid response!")
                return HTTPResponse(success: true, errorMsg: "Invalid Response")
            }
        }
        
        return HTTPResponse(success: true, errorMsg: successHttpErrorMsg, data: data)
    }
    
    func buildJsonResponse(data: NSData?, response: NSURLResponse?, error: NSError?) -> HTTPResponse {
        let httpResponse = buildResponse(data, response: response, error: error)
        if (httpResponse.success){
            // check if body can be parsed to Json
            if let data = httpResponse.data {
                let parsedResult: AnyObject!
                do {
                    parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    return HTTPResponse(success: true, errorMsg: successHttpErrorMsg, parsedResult: parsedResult)
                } catch {
                    print("Could not parse the data as JSON: '\(data)'")
                }
            }
            return HTTPResponse(success: true, errorMsg: "Could Not Parse JSON from response")
        }
        return httpResponse
    }
    
    /**
     Parses NSData and returns a JSON object
     */
    func dataToJson(data: NSData) -> AnyObject? {
        var parsedResult: AnyObject? = nil
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            print("Could not parse session response: '\(data)'")
        }
        return parsedResult
    }
    
    private func sendRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: completionHandler)
        task.resume()
    }
    
    private func buildRequest(url: String, method: String, httpHeaders: [String: String]?, httpBody: String?) -> NSURLRequest {
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = method
        
        if let headers = httpHeaders {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = httpBody {
            request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        }
        return request
    }
    
}

