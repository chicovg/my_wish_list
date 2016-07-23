//
//  PromiseWishViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 7/9/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit

class PromiseWishViewController: ViewWishViewController {
    
    var friend: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true) {}
    }
    
    @IBAction func grantWish(sender: UIBarButtonItem) {
        self.displayConfirmDialogue("Grant Wish?", message: "Do you want to grant this wish for your friend?", confirmLabel: "Yes", denyLabel: "Not now" ) { (alert) in
            self.syncService.promise(wish: self.wish, forFriend: self.friend) { (syncError, saveError) in
                if let _ = syncError where syncError == .NoNetworkConnection {
                    self.displayNoNetworkConnectionAlert()
                } else if let _ = syncError where syncError == .UserNotLoggedIn {
                    self.returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
                } else if let err = saveError {
                    self.displayErrorAlert("There was an issue updating your friend's wish list", actionHandler: { (action) in }, presentHandler: {})
                    print("save failed \(err)")
                } else {
                    self.dismissViewControllerAnimated(true, completion: {})
                }
            }
        }
    }
}
