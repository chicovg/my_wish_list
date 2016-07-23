//
//  MyWishListViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/28/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class MyWishListParentViewController: UIViewController {
    
    var syncService: DataSyncService {
        return DataSyncService.sharedInstance
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    var currentUser: User? {
        return syncService.currentUser()
    }
    
    func returnToLoginView(shouldLogout logout: Bool, showLoggedOutAlert: Bool){
        let loginVC = self.storyboard?.instantiateViewControllerWithIdentifier(loginViewControllerId) as! LoginViewController
        self.presentViewController(loginVC, animated: true, completion: { () -> Void in
            if logout {
                loginVC.logout()
            }
            if showLoggedOutAlert {
                loginVC.showLoggedOutAlert()
            }
        })
    }
    
    func displayNoNetworkConnectionAlert() {
        displayErrorAlert("Unable to connect to the internet. Check your network settings.", actionHandler: { (action) in }) {}
    }
    
    func displayErrorAlert(message: String, actionHandler: ((UIAlertAction) -> Void), presentHandler: (() -> Void)) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: actionHandler))
        presentViewController(alert, animated: true, completion: presentHandler)
    }
    
    func displayConfirmDialogue(title: String, message: String, confirmLabel: String, denyLabel: String, confirmAction: ((UIAlertAction) -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: confirmLabel, style: UIAlertActionStyle.Default, handler: confirmAction))
        alert.addAction(UIAlertAction(title: denyLabel, style: UIAlertActionStyle.Cancel, handler: nil))
        
        presentViewController(alert, animated: true, completion: nil)
    }

}
