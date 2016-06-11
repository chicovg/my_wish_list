//
//  FriendWishListViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/14/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class FriendWishListViewController: MyWishListParentViewController {
    
    let kReuseIdentifier = "friendWishListTableViewCell"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet weak var tableView: UITableView!

    var allWishes : [Wish] = []
    var wishes : [Wish] = []
    var friend : UserEntity!
    
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
    
    // MARK: Actions
    @IBAction func doneButtonPressed(sender: UIBarButtonItem) {
        // save edits
        dismissViewControllerAnimated(true) { () -> Void in }
    }

}

// MARK: UITableViewDataSource, UITableViewDelegate
extension FriendWishListViewController : UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        syncService.queryUngrantedWishes(forUser: friend.userValue) { (wishes, syncError) -> Void in
            if let _ = syncError where syncError == .UserNotLoggedIn {
                self.returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
            }
            self.allWishes = wishes
            self.updateWishes()
            self.tableView.reloadData()
        }
    }
    
    private func updateWishes() {
        if let searchText = searchController.searchBar.text where
            searchController.active && searchController.searchBar.text != "" {
            self.wishes = allWishes.filter({ (wish) -> Bool in
                return wish.title.lowercaseString.containsString(searchText.lowercaseString)
            })
        } else {
            self.wishes = allWishes
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wishes.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kReuseIdentifier, forIndexPath: indexPath)
        let wish = wishes[indexPath.row]
        cell.textLabel?.text = wish.title
        cell.detailTextLabel?.text = wish.detail
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let wish = wishes[indexPath.row]
        let alert = UIAlertController(title: "Grant Wish?", message: "Do you want to grant this wish for your friend?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Not now", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.syncService.grantWish(wish: wish, forFriend: self.friend, handler: { (syncError, saveError) -> Void in
                if let _ = syncError where syncError == .UserNotLoggedIn {
                    self.returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
                } else if let err = saveError {
                    self.displayErrorAlert("There was an issue updating your friend's wish list", actionHandler: { (action) in }, presentHandler: {})
                    print("save failed \(err)")
                }
            })
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
}

// MARK  UISearchResultsUpdating
extension FriendWishListViewController : UISearchResultsUpdating {
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        updateWishes()
        tableView.reloadData()
    }
}



