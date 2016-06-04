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
    
    var currentUser: UserEntity? {
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
    
    func displayErrorAlert(message: String, actionHandler: ((UIAlertAction) -> Void), presentHandler: (() -> Void)) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: actionHandler))
        presentViewController(alert, animated: true, completion: presentHandler)
    }

}
