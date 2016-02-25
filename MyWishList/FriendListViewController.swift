//
//  FriendListViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/7/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class FriendListViewController: UIViewController {
    
    let kReuseIdentifier = "friendListTableViewCell"
    let kSegueToFriendWishList = "segueToFriendWishList"
    
    @IBOutlet weak var tableView: UITableView!
    
    var friends: [User] = []
    
    var firebaseClient: FirebaseClient {
        return FirebaseClient.sharedInstance
    }
    
    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier where identifier == kSegueToFriendWishList, let fWishListVC = segue.destinationViewController as? FriendWishListViewController, indexPath = tableView.indexPathForSelectedRow {
            fWishListVC.user = friends[indexPath.row]
        }
    }
    @IBAction func logout(sender: AnyObject) {
        let loginVC = self.storyboard?.instantiateViewControllerWithIdentifier(loginViewControllerId) as! LoginViewController
        self.presentViewController(loginVC, animated: true, completion: { () -> Void in
            loginVC.logout()
            print("Logged Out..")
        })
    }

}

extension FriendListViewController : UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        firebaseClient.queryFriends { (friends) -> Void in
            self.friends = friends
            self.tableView.reloadData()
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kReuseIdentifier, forIndexPath: indexPath) as! FriendTableViewCell
        let friend = friends[indexPath.row]
        cell.nameLabel.text = friend.name
        cell.photoImageView.image = UIImage(named: "PhotoPlaceholder")
        ImageService.sharedInstance.getImage(byUrlString: friend.pictureUrl) { (image) -> Void in
            if let image = image {
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    cell.photoImageView.image = image
                })
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let friend = friends[indexPath.row]
        performSegueWithIdentifier(kSegueToFriendWishList, sender: nil)
    }
    
}
