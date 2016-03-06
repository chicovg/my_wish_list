//
//  ActionViewController.swift
//  Add To My Wish List
//
//  Created by Victor Guthrie on 3/5/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var detailsTextView: UITextView!
    
    let kWishUrlKey = "documentUrl"
    
    var syncService: DataSyncService {
        return DataSyncService.sharedInstance
    }
    
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
    }

    @IBAction func save(sender: UIBarButtonItem) {
        if syncService.userIsLoggedIn() {
            handleSaveWish()
        } else {
            syncService.loginWithFacebook(self, handler: { (error) -> Void in
                if let err = error where err == .UserLoginFailed {
                    // TODO display error msg
                    print("Login failed")
                } else {
                    self.handleSaveWish()
                }
            })
        }
    }

    private func handleSaveWish() {
        saveWish { (success) -> Void in
            if(success) {
                self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
            } else {
                // TODO display error msg
            }
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
            syncService.save(wish: wish, handler: { (syncError, saveError) -> Void in
                if let _ = syncError where syncError == .UserNotLoggedIn {
                    
                } else if let err = saveError {
                    print("save failed \(err)")
                    handler(success: false)
                } else {
                    handler(success: true)
                }
            })
        } else {
            print("Title field not populated!")
            handler(success: false)
        }
    }
    
}
