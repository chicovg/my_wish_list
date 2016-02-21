//
//  ImageService.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/14/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import Foundation
import UIKit

class ImageService {
    
    // MARK: sharedInstance
    static let sharedInstance = ImageService()
    
    private var inMemoryCache = NSCache()
    
    private var facebookClient: FBClient {
        return FBClient.sharedInstance
    }
    
    /** Get image from local cache, if it is not cached, dowload from Flickr */
    func getImage(byUrlString urlString: String, callback: (image: UIImage?) -> Void) {
        if let objectURL = NSURL(string: urlString), let fileName = objectURL.lastPathComponent {
            let path = fullPathForFile(fileName)
            
            // if image is cached locally, get it, else fetch from flickr
            if let image = imageWithPath(path) {
                callback(image: image)
            } else {
                facebookClient.getImage(urlString, completionHandler: { (response) -> Void in
                    if response.success && response.data != nil {
                        let image = UIImage(data: response.data!)
                        callback(image: image)
                        self.storeImage(image, withPath: path)
                    } else {
                        callback(image: nil)
                        self.storeImage(nil, withPath: path)
                    }
                })
            }
        }
        
        callback(image: nil)
    }
    
    /** Removes image from cache and file system */
    func removeImage(byObjectURL objectURL: NSURL) {
        print("deleting: \(objectURL)")
        if let fileName = objectURL.lastPathComponent {
            let path = fullPathForFile(fileName)
            storeImage(nil, withPath: path)
        }
    }
    
    // MARK: Helpers
    private func imageWithPath(path: String) -> UIImage? {
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        } else if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    private func storeImage(image: UIImage?, withPath path: String) {
        if let image = image {
            inMemoryCache.setObject(image, forKey: path)
            let data = UIImagePNGRepresentation(image)!
            data.writeToFile(path, atomically: true)
        } else {
            inMemoryCache.removeObjectForKey(path)
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch _ {}
        }
    }
    
    private func fullPathForFile(filename: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(filename)
        
        return fullURL.path!
    }
}
