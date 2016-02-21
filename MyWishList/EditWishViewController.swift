//
//  EditWishViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/23/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class EditWishViewController: UIViewController {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var detailTextView: UITextView!
    
    var wishToEdit: Wish?
    
    var userId: String? {
        return FBCredentials.sharedInstance.currentFacebookId()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let wish = wishToEdit {
            titleTextField.text = wish.title
            detailTextView.text = wish.detail
        }
        
        if userId == nil {
            // Error?
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func doneEditing(sender: UIButton) {
        if let title = titleTextField.text {
            var detail: String? = nil
            if let desc = detailTextView.text {
                detail = desc
            }
            
            if let wish = wishToEdit {
                wish.title = title
                wish.detail = detail
                wishService.updateWish(wish)
            } else {
                let dictionary : [String : AnyObject?] = [
                    Wish.Keys.userId : userId!,
                    Wish.Keys.title : title,
                    Wish.Keys.detail : detail,
                ]
                print("title: \(title) detail: \(detail)")
                wishService.createWish(dictionary)
            }
        } else {
            // display and error message
        }
        dismissViewControllerAnimated(true) { () -> Void in } 
    }
    
    var wishService: WishService {
        return WishService.sharedInstance
    }

}

