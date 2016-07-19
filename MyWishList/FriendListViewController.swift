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
    
    var friends: [User] = []
    var user: User!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: FriendshipEntity.ENTITY_NAME)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "friend.\(User.Keys.name)", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        fetchFriends()
        setupTableView()
        setupSearchController()
        fetch()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier where identifier == kSegueToFriendWishList, let fWishListVC = segue.destinationViewController as? FriendWishListViewController, indexPath = tableView.indexPathForSelectedRow {
            fWishListVC.friend = friendAtIndexPath(indexPath)
        }
    }
    
    @IBAction func logout(sender: AnyObject) {
        returnToLoginView(shouldLogout: true, showLoggedOutAlert: false)
    }

}

extension FriendListViewController : NSFetchedResultsControllerDelegate {
    
    private func setupFetchResultsController(){
        fetchedResultsController.delegate = self
    }
    
    private func updateFetchRequest(user: User) {
        if let searchText = searchController.searchBar.text where
            searchController.active && searchController.searchBar.text != "" {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(user.id == %@) AND (title CONTAINS[cd] %@)", user.id, searchText)
        } else {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "user.id == %@", user.id)
        }
    }
    
    private func fetchFriends() {
        guard let user = currentUser else {
            returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
            return
        }
        
        syncService.fetchFriends(user)
    }
    
    private func fetch() {
        guard let userEntity = currentUser else {
            returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
            return
        }
        updateFetchRequest(userEntity)
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error in fetch(): \(error)")
        }
        tableView.reloadData()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        fetch()
    }
}

extension FriendListViewController : UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController.sections else {
            return 0
        }
        return sections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kReuseIdentifier, forIndexPath: indexPath) as! FriendTableViewCell
        let friend = friendAtIndexPath(indexPath)
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
    
    private func friendAtIndexPath(indexPath: NSIndexPath) -> User {
        return (fetchedResultsController.objectAtIndexPath(indexPath) as! FriendshipEntity).friend.userValue
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
        fetch()
    }
}
