//
//  GrantedWishListViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 6/7/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class GrantedWishListViewController: MyWishListParentViewController {
    
    let kReuseIdentifier = "grantedWishTableViewCell"
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet weak var tableView: UITableView!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: GrantedWishEntity.ENTITY_NAME)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "wish.\(Wish.Keys.grantedOn)", ascending: false),
            NSSortDescriptor(key: "wish.\(Wish.Keys.title)", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))),
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension GrantedWishListViewController : NSFetchedResultsControllerDelegate {
    
    private func setupFetchResultsController(){
        fetchedResultsController.delegate = self
    }
    
    private func updateFetchRequest(user: UserEntity) {
        if let searchText = searchController.searchBar.text where
            searchController.active && searchController.searchBar.text != "" {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "(grantedBy == %@) AND (title CONTAINS[cd] %@)", user, searchText)
        } else {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "grantedBy == %@", user)
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
extension GrantedWishListViewController : UITableViewDataSource, UITableViewDelegate {
    
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
        let entity = (fetchedResultsController.objectAtIndexPath(indexPath) as! GrantedWishEntity).wish
        return entity.wishValue()
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
}

// MARK  UISearchResultsUpdating
extension GrantedWishListViewController : UISearchResultsUpdating {
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
