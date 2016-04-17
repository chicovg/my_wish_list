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
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let kEditNavigationItemTitle = "Edit Wish"
    let kAddNavigationItemTille = "Add to Wish List!"
    
    var user: User!
    var wishToEdit: Wish?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextFields()
        
        if let wish = wishToEdit {
            navItem.title = kEditNavigationItemTitle
            titleTextField.text = wish.title
            linkTextField.text = wish.link
            detailTextView.text = wish.detail
        } else {
            navItem.title = kAddNavigationItemTille
            saveButton.enabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func doneButtonPressed(sender: UIBarButtonItem) {
        if let title = titleTextField.text {
            var id: String? = nil
            var granted: Bool = false
            if let wish = wishToEdit {
                id = wish.id
                granted = wish.granted
            }
            var link: String? = nil
            if let linkTxt = linkTextField.text {
                link = linkTxt
            }
            var detail: String? = nil
            if let desc = detailTextView.text {
                detail = desc
            }
            
            let wish = Wish(id: id, title: title, link: link, detail: detail, granted: granted)
            syncService.save(wish: wish, handler: { (syncError, saveError) -> Void in
                if let _ = syncError where syncError == .UserNotLoggedIn {
                    self.returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
                } else if let err = saveError {
                    // TODO display an error message
                    print("save failed \(err)")
                } else {
                    self.dismissViewControllerAnimated(true, completion: { () -> Void in})
                }
            })
        }
    }

    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in})
    }
    
    private func setupTextFields(){
        titleTextField.delegate = self
        
        let borderColor = UIColor(red: 0.48, green: 0.72, blue: 0.67, alpha: 1.0).CGColor
        titleTextField.layer.borderColor = borderColor
        titleTextField.layer.borderWidth = 1.0
        linkTextField.layer.borderColor = borderColor
        linkTextField.layer.borderWidth = 1.0
        detailTextView.layer.borderColor = borderColor
        detailTextView.layer.borderWidth = 1.0
    }
    
}

extension EditWishViewController : UITextFieldDelegate {
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

