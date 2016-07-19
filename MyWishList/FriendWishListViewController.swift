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
    let kSegueToPromiseWish = "segueToPromiseWish"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet weak var tableView: UITableView!

    var allWishes : [Wish] = []
    var wishes : [Wish] = []
    var friend : User!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()
        setupSearchController()
        
        navigationItem.title = friend.name
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let promiseVC = segue.destinationViewController as? PromiseWishViewController, indexPath = sender as? NSIndexPath where segue.identifier == kSegueToPromiseWish {
            promiseVC.friend = friend
            promiseVC.wish = wishes[indexPath.row]
        }
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
        syncService.queryWishedWishes(forUser: friend) { (wishes, syncError) in
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
        performSegueWithIdentifier(kSegueToPromiseWish, sender: indexPath)
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



