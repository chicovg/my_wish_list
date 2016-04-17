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
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let kWishUrlKey = "documentUrl"
    let TOKEN_KEY = "firebaseToken"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextFields()
        
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
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
    }

    @IBAction func save(sender: UIBarButtonItem) {
        if let accessToken = KeychainClient.sharedInstance.currentAccessToken() {
            FirebaseClient.sharedInstance.authenticateWithFacebook(accessToken, handler: { (user, error) -> Void in
                if error != nil {
                    self.displayExtensionReturningAlert("Not Logged In!", message: "Please log in via the MyWishList app first!", actionLabel: "Ok")
                } else {
                    self.saveWish({ (success) -> Void in
                        if success {
                            self.displayExtensionReturningAlert("Success!", message: "The item was added to your wish list!", actionLabel: "Great!")
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
        }
    }
    
    private func setupTextFields(){
        titleTextField.delegate = self
        
        let borderColor = UIColor(red: 0.48, green: 0.72, blue: 0.67, alpha: 1.0).CGColor
        titleTextField.layer.borderColor = borderColor
        titleTextField.layer.borderWidth = 1.0
        linkTextField.layer.borderColor = borderColor
        linkTextField.layer.borderWidth = 1.0
        detailsTextView.layer.borderColor = borderColor
        detailsTextView.layer.borderWidth = 1.0
    }
    
    private func displayExtensionReturningAlert(title: String, message: String, actionLabel: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: actionLabel, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.extensionContext!.completeRequestReturningItems(self.extensionContext!.inputItems, completionHandler: nil)
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
}

extension ActionViewController : UITextFieldDelegate {
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == titleTextField {
            if let titleText = textField.text where NSString(string: titleText).length > 0 {
                saveButton.enabled = true
            } else {
                saveButton.enabled = false
            }
        }
        
    }
}
