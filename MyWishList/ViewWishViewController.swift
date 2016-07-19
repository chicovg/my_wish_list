//
//  ViewWishViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 6/26/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit

class ViewWishViewController: MyWishListParentViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailTextView: UITextView!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var openLinkButton: UIButton!
    
    var wish: Wish!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        titleLabel.text = wish.title
        detailTextView.text = wish.detail
        if wish.link == nil || wish.link == "" {
            openLinkButton.hidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func close(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true) {}
    }
    
    @IBAction func openLink(sender: UIButton) {
        if let urlString = wish.link, url = NSURL(string: urlString) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}
