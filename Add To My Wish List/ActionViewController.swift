//
//  ActionViewController.swift
//  Add To My Wish List
//
//  Created by Victor Guthrie on 3/5/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import MobileCoreServices
import SimpleKeychain

class ActionViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var detailsTextView: UITextView!
    
    let kWishUrlKey = "documentUrl"
    let TOKEN_KEY = "firebaseToken"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem
        let itemProvider = extensionItem?.attachments?.first as? NSItemProvider
        
        let propertyList = String(kUTTypePropertyList)
        if let provider = itemProvider where provider.hasItemConformingToTypeIdentifier(propertyList) {
            provider.loadItemForTypeIdentifier(propertyList, options: nil, completionHandler: { (item, error) -> Void in
                let dictionary = item as! NSDictionary
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as! NSDictionary
                    if let urlString = results[self.kWishUrlKey] as? String {
                        self.linkTextField.text = urlString
                    }
                })
            })
        }
        
        let tokenSaved = A0SimpleKeychain(service: "Auth0", accessGroup: "com.chicovg.wishlist").stringForKey(TOKEN_KEY)
        print("\(tokenSaved)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
    }

    @IBAction func save(sender: UIBarButtonItem) {
        if let accessToken = KeychainClient.sharedInstance.currentAccessToken() {
            FirebaseClient.sharedInstance.authenticateWithFacebook(accessToken, handler: { (user, error) -> Void in
                if let error = error {
                    // display error message
                } else {
                    self.saveWish({ (success) -> Void in
                        if success {
                            // TODO show conformation
                            self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
                        }
                    })
                }
            })
        }
    }
    
    private func saveWish(handler: (success: Bool) -> Void) {
        if let title = titleTextField.text {
            var link: String? = nil
            if let linkTxt = linkTextField.text {
                link = linkTxt
            }
            var detail: String? = nil
            if let desc = detailsTextView.text {
                detail = desc
            }
            
            let wish = Wish(title: title, link: link, detail: detail)
            FirebaseClient.sharedInstance.save(wish: wish)
            handler(success: true)
        } else {
            print("Title field not populated!")
            handler(success: false)
        }
    }
    
}
