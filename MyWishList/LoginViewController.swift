//
//  LoginViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/24/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController {
    
    let kSegueToMainView = "segueToMainView"
    
    @IBOutlet weak var loginWithFacebookButton: UIButton!
    
    var syncService: DataSyncService {
        return DataSyncService.sharedInstance
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didTouchLoginWithFacebook(sender: UIButton) {
        if syncService.userIsLoggedIn() {
            logout()
        } else {
            loginWithFacebook()
        }
    }

    func logout() {
        syncService.logoutFromFacebook()
    }
    
    private func loginWithFacebook(){
        syncService.loginWithFacebook(self) { (error) -> Void in
            if let err = error where err == .UserLoginFailed {
                // todo display error
                print("Login failed")
            } else {
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    let tabVC = self.storyboard?.instantiateViewControllerWithIdentifier(tabBarControllerId)
                    self.presentViewController(tabVC!, animated: true, completion: { () -> Void in
                        print("Logged In as \(user.name)")
                    })
                })
            }
        }
    }
    
    func showLoggedOutAlert() {
        
    }
}
