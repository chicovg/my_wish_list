//
//  FriendListViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/7/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class FriendListViewController: MyWishListParentViewController {
    
    let kReuseIdentifier = "friendListTableViewCell"
    let kSegueToFriendWishList = "segueToFriendWishList"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet weak var tableView: UITableView!
    
    var allFriends: [User] = []
    var friends: [User] = []
    
    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()
        setupSearchController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier where identifier == kSegueToFriendWishList, let fWishListVC = segue.destinationViewController as? FriendWishListViewController, indexPath = tableView.indexPathForSelectedRow {
            fWishListVC.friend = friends[indexPath.row]
        }
    }
    
    @IBAction func logout(sender: AnyObject) {
        returnToLoginView(shouldLogout: true, showLoggedOutAlert: false)
    }

}

extension FriendListViewController : UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        syncService.fetchFriends { (syncError) -> Void in
            if let _ = syncError where syncError == .UserNotLoggedIn {
                self.returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
            } else {
                self.syncService.queryFriends({ (friends, syncError) -> Void in
                    if let _ = syncError where syncError == .UserNotLoggedIn {
                        self.returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
                    } else {
                        self.allFriends = friends
                        self.updateFriends()
                        self.tableView.reloadData()
                    }
                })
            }
        }
    }
    
    private func updateFriends() {
        if let searchText = searchController.searchBar.text where
            searchController.active && searchController.searchBar.text != "" {
            friends = allFriends.filter({ (friend) -> Bool in
                return friend.name.lowercaseString.containsString(searchText.lowercaseString)
            })
        } else {
            friends = allFriends
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
        performSegueWithIdentifier(kSegueToFriendWishList, sender: nil)
    }
    
}

// MARK  UISearchResultsUpdating
extension FriendListViewController : UISearchResultsUpdating {
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        updateFriends()
        tableView.reloadData()
    }
}
