//
//  GrantedWishListViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 6/7/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class PromisedWishListViewController: MyWishListParentViewController {
    
    let kReuseIdentifier = "promisedWishTableViewCell"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet weak var tableView: UITableView!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: WishPromiseEntity.ENTITY_NAME)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "\(Wish.Keys.promisedOn)", ascending: false)
        ]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)        
        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()
        setupFetchResultsController()
        setupSearchController()
        fetch()
    }

}

extension PromisedWishListViewController : NSFetchedResultsControllerDelegate {
    
    private func setupFetchResultsController(){
        fetchedResultsController.delegate = self
    }
    
    private func updateFetchRequest(user: User) {
        if let searchText = searchController.searchBar.text where
            searchController.active && searchController.searchBar.text != "" {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(promisedBy.id == %@) AND (title CONTAINS[cd] %@)", user.id, searchText)
        } else {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "promisedBy.id == %@", user.id)
        }
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
    
    func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return sectionName == "0" ? "Wished" : "Granted"
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        fetch()
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension PromisedWishListViewController : UITableViewDataSource, UITableViewDelegate {
    
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
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].indexTitle
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kReuseIdentifier, forIndexPath: indexPath) as! PromisedWishTableViewCell
        let wishPromiseEntity = wishPromiseAtIndexPath(indexPath)
        let wishEntity = wishPromiseEntity.wish
        let userEntity = wishEntity.user
        
        cell.titleLabel.text = wishEntity.title
        cell.detailLabel.text = wishEntity.detail
        cell.friendsImage.image = UIImage(named: "PhotoPlaceholder")
        cell.setPromsedLabel(userEntity.name, promisedOn: wishPromiseEntity.promisedOn)
        
        ImageService.sharedInstance.getImage(byUrlString: userEntity.pictureUrl) { (image) -> Void in
            if let image = image {
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    cell.friendsImage.image = image
                })
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let wishEntity = wishPromiseAtIndexPath(indexPath).wish
        let unpromiseAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Unpromise" ) { (action, indexPath) in
            self.displayConfirmDialogue("Unpromise?", message: "Are you sure that you no longer want to grant your friend's wish?", confirmLabel: "Yes", denyLabel: "Cancel" ) { (action) in
                self.syncService.unpromise(wish: wishEntity.wishValue, forFriend: wishEntity.user.userValue) { (syncError, saveError) in
                    if let _ = syncError where syncError == .NoNetworkConnection {
                        self.displayNoNetworkConnectionAlert()
                    } else if let _ = syncError where syncError == .UserNotLoggedIn {
                        self.returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
                    } else if let err = saveError {
                        print("unpromise failed \(err)")
                        self.displayErrorAlert("There was an problem unpromising the wish!", actionHandler: { (action) in }, presentHandler: {})
                    } else {
                        self.fetch()
                    }
                }
            }
        }
        
        return [unpromiseAction]
    }
    
    private func wishPromiseAtIndexPath(indexPath: NSIndexPath) -> WishPromiseEntity {
        return (fetchedResultsController.objectAtIndexPath(indexPath) as! WishPromiseEntity)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
}

// MARK  UISearchResultsUpdating
extension PromisedWishListViewController : UISearchResultsUpdating {
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
