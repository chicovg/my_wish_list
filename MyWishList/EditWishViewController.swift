//
//  EditWishViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/23/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class EditWishViewController: MyWishListParentViewController {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var detailTextView: UITextView!
    
    let kEditNavigationItemTitle = "Edit Wish"
    let kAddNavigationItemTille = "Add to Wish List!"
    
    var user: User!
    var wishToEdit: Wish?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let wish = wishToEdit {
            navigationItem.title = kEditNavigationItemTitle
            titleTextField.text = wish.title
            detailTextView.text = wish.detail
        } else {
            navigationItem.title = kAddNavigationItemTille
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func doneButtonPressed(sender: UIBarButtonItem) {
        if let title = titleTextField.text {
            var id : String? = nil
            if let wish = wishToEdit {
                id = wish.id
            }
            var link: String? = nil
            if let linkTxt = linkTextField.text {
                link = linkTxt
            }
            var detail: String? = nil
            if let desc = detailTextView.text {
                detail = desc
            }
            
            let wish = Wish(id: id, title: title, link: link, detail: detail)
            syncService.save(wish: wish, handler: { (syncError, saveError) -> Void in
                if let _ = syncError where syncError == .UserNotLoggedIn {
                    self.returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
                } else if let err = saveError {
                    // TODO display an error message
                    print("save failed \(err)")
                } else {
                    self.dismissViewControllerAnimated(true) { () -> Void in }
                }
            })
        } else {
            // TODO display an error message
            print("Title field not populated!")
        }
    }

}

