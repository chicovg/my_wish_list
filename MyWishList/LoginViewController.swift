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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupLoginButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension LoginViewController : FBSDKLoginButtonDelegate {
    
    private func setupLoginButton(){
        let loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        loginButton.center = self.view.center
        loginButton.delegate = self
        self.view.addSubview(loginButton)
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if let token = result.token {
            SyncService.sharedInstance.facebookUserId = token.userID
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                let tabVC = self.storyboard!.instantiateViewControllerWithIdentifier("TabViewController")
                self.presentViewController(tabVC, animated: true, completion: { () -> Void in
                    print("Logged In..")
                })
            })
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
    }
    
    func loginButtonWillLogin(loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }
}
