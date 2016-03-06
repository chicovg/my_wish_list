//
//  MyWishListViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/28/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit

class MyWishListParentViewController: UIViewController {
    
    var syncService: DataSyncService {
        return DataSyncService.sharedInstance
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

}
