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
    
    var wishes: [Wish] = []
    var grantedWishes: [Wish] = []
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: WishEntity.ENTITY_NAME)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: Wish.Keys.granted, ascending: true),
            NSSortDescriptor(key: Wish.Keys.title, ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))),
        ]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: "granted",
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

extension WishListViewController : NSFetchedResultsControllerDelegate {
    
    private func setupFetchResultsController(){
        fetchedResultsController.delegate = self
    }
    
    private func updateFetchRequest(user: UserEntity) {
        if let searchText = searchController.searchBar.text where
            searchController.active && searchController.searchBar.text != "" {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(user == %@) AND (title CONTAINS[cd] %@)", user, searchText)
        } else {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "user == %@", user)
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
        let entity = (fetchedResultsController.objectAtIndexPath(indexPath) as! WishEntity)
        print("user.id = \(entity.user.id)")
        return entity.wishValue()
    }

    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(kSegueToEditWish, sender: indexPath)
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



