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
    let kSegueToViewWish = "segueToViewWish"

    let kReuseIdentifier = "wishListTableViewCell"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: WishEntity.ENTITY_NAME)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: Wish.Keys.status, ascending: false),
            NSSortDescriptor(key: Wish.Keys.title, ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))),
        ]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: CoreDataClient.sharedInstance.sharedContext,
                                                                  sectionNameKeyPath: Wish.Keys.status,
                                                                  cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()
        setupSearchController()
        fetch()
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
        
        if let identifier = segue.identifier where identifier == kSegueToViewWish,
            let viewVC = segue.destinationViewController as? ViewWishViewController {
            if let indexPath = sender as? NSIndexPath {
                viewVC.wish = wishAtIndexPath(indexPath)
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

extension WishListViewController : NSFetchedResultsControllerDelegate {
    
    private func updateFetchRequest(user: User) {
        if let searchText = searchController.searchBar.text where
            searchController.active && searchController.searchBar.text != "" {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(user.id == %@) AND (title CONTAINS[cd] %@)", user.id, searchText)
        } else {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "user.id == %@", user.id)
        }
    }
    
    private func fetch() {
        guard let user = currentUser else {
            returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
            return
        }
        updateFetchRequest(user)
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error in fetch(): \(error)")
        }
        
        tableView.reloadData()
    }
    
    func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return sectionName
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        fetch()
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension WishListViewController : UITableViewDataSource, UITableViewDelegate {
    
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
        let cell = tableView.dequeueReusableCellWithIdentifier(kReuseIdentifier, forIndexPath: indexPath)
        let wish = wishAtIndexPath(indexPath)
        cell.textLabel?.text = wish.title
        cell.detailTextLabel?.text = wish.detail
        return cell
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let wish = wishAtIndexPath(indexPath)
        let deleteWishAction = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "Delete" ) { (action, indexPath) in
            self.syncService.deleteWish(wish, handler: { (syncError, deleteError) in
                if let _ = syncError where syncError == .UserNotLoggedIn {
                    self.returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
                } else if let err = deleteError {
                    print("delete failed \(err)")
                    self.displayErrorAlert("There was an problem deleting the wish!", actionHandler: { (action) in }, presentHandler: {})
                }
            })
        }
        let markGrantedAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Mark Granted" ) { (action, indexPath) in
            self.syncService.granted(wish: wish, handler: { (syncError, saveError) in
                if let _ = syncError where syncError == .UserNotLoggedIn {
                    self.returnToLoginView(shouldLogout: false, showLoggedOutAlert: true)
                } else if let err = saveError {
                    print("save failed \(err)")
                    self.displayErrorAlert("There was an problem updating the wish!", actionHandler: { (action) in },presentHandler: {})
                }
            })
        }
        markGrantedAction.backgroundColor = UIColor.init(red: 0.16, green: 0.64, blue: 0.39, alpha: 1.00)
        
        if wish.status == Wish.Status.Promised {
            return [markGrantedAction]
        }
        
        return [deleteWishAction]
    }
    
    private func wishAtIndexPath(indexPath: NSIndexPath) -> Wish {
        return (fetchedResultsController.objectAtIndexPath(indexPath) as! WishEntity).wishValue
    }

    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if wishAtIndexPath(indexPath).wished() {
            performSegueWithIdentifier(kSegueToEditWish, sender: indexPath)
        } else {
            performSegueWithIdentifier(kSegueToViewWish, sender: indexPath)
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
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
        fetch()
    }
}



