//
//  WishListViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/23/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class WishListViewController: MyWishListParentViewController {
    
    let kSegueToEditWish = "segueToEditWish"
    let kReuseIdentifier = "wishListTableViewCell"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var allWishes: [Wish] = []
    var wishes: [Wish] = []
    var grantedWishes: [Wish] = []
    
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
        if let identifier = segue.identifier where identifier == kSegueToEditWish,
            let editVC = segue.destinationViewController as? EditWishViewController {
                if let indexPath = sender as? NSIndexPath {
                    editVC.wishToEdit = wishAtIndexPath(indexPath)
                } else {
                    editVC.wishToEdit = nil
                }
        }
    }
    
    // MARK: Actions
    @IBAction func editWishList(sender: UIBarButtonItem) {
        if tableView.editing {
            tableView.setEditing(false, animated: true)
            editButton.title = "Edit"
            addButton.enabled = true
        } else {
            tableView.setEditing(true, animated: true)
            editButton.title = "Done"
            addButton.enabled = false
        }
    }
    
    @IBAction func addNewWish(sender: UIBarButtonItem) {
        performSegueWithIdentifier(kSegueToEditWish, sender: nil)
    }
    
    @IBAction func logout(sender: AnyObject) {
        returnToLoginView(shouldLogout: true, showLoggedOutAlert: false)
    }
    
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension WishListViewController : UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        syncService.queryWishes { (wishes, syncError) -> Void in
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
            let filteredWishes = allWishes.filter({ (wish) -> Bool in
                return wish.title.lowercaseString.containsString(searchText.lowercaseString)
            })
            wishes = filteredWishes.filter({ (wish) -> Bool in return !wish.granted})
            grantedWishes = filteredWishes.filter({ (wish) -> Bool in return wish.granted})
        } else {
            wishes = allWishes.filter({ (wish) -> Bool in return !wish.granted})
            grantedWishes = allWishes.filter({ (wish) -> Bool in return wish.granted})
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return grantedWishes.count > 0
            ? (wishes.count > 0 ? 2 : 1)
            : (wishes.count > 0 ? 1 : 0)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 && wishes.count > 0
            ? wishes.count
            : grantedWishes.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 && wishes.count > 0
            ? "Wished"
            : "Granted"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kReuseIdentifier, forIndexPath: indexPath)
        let wish = wishAtIndexPath(indexPath)
        if wish.granted {
            cell.imageView?.image = UIImage(named: "Checkmark")
        } else {
            cell.imageView?.image = UIImage(named: "Checkmark-unchecked")
        }
        cell.textLabel?.text = wish.title
        cell.detailTextLabel?.text = wish.detail
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let wish = wishAtIndexPath(indexPath)
            syncService.deleteWish(wish, handler: { (syncError, deleteError) -> Void in
                if let _ = syncError where syncError == .UserNotLoggedIn {
                    self.returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
                } else if let err = deleteError {
                    print("delete failed \(err)")
                }
            })
        }
    }
    
    private func wishAtIndexPath(indexPath: NSIndexPath) -> Wish {
        return indexPath.section == 0 && wishes.count > 0
            ? wishes[indexPath.row]
            : grantedWishes[indexPath.row]
    }

    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(kSegueToEditWish, sender: indexPath)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}

// MARK  UISearchResultsUpdating
extension WishListViewController : UISearchResultsUpdating {
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



