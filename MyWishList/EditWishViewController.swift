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
    
    var firebaseClient: FirebaseClient {
        return FirebaseClient.sharedInstance
    }
    
    var user: User!
    var wishToEdit: Wish?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let wish = wishToEdit {
            titleTextField.text = wish.title
            detailTextView.text = wish.detail
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func doneEditing(sender: UIButton) {
        if let title = titleTextField.text {
            var id : String? = nil
            if let wish = wishToEdit {
                id = wish.id
            }
            var detail: String? = nil
            if let desc = detailTextView.text {
                detail = desc
            }
            
            let wish = Wish(id: id, title: title, detail: detail)
            firebaseClient.save(wish: wish) { (error) -> Void in
                if let err = error {
                    // TODO display an error message
                    print("Save failed: \(err)")
                } else {
                    self.dismissViewControllerAnimated(true) { () -> Void in }
                }
            }
        } else {
            // TODO display an error message
            print("Title field not populated!")
        }
        
    }

}

