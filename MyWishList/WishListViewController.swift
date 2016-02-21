//
//  WishListViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/23/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class WishListViewController: UIViewController {
    
    let kSegueToEditWish = "segueToEditWish"
    let kReuseIdentifier = "wishListTableViewCell"
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()
        registerForSyncNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier where identifier == kSegueToEditWish, let editVC = segue.destinationViewController as? EditWishViewController, wish = sender as? Wish {
            editVC.wishToEdit = wish
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
        let index = fetchedResultsController.fetchedObjects?.count
        performSegueWithIdentifier(kSegueToEditWish, sender: index)
    }
    
    // MARK: Facebook Id
    var facebookId : String? {
        return FBCredentials.sharedInstance.currentFacebookId()
    }
    
    // MARK: CoreData Context
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    // MARK: Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: Wish.ENTITY_NAME)
        fetchRequest.predicate = NSPredicate(format: "\(Wish.Keys.userId) == %@", self.facebookId!)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Wish.Keys.title, ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    var wishService: WishService {
        return WishService.sharedInstance
    }
    
}

extension WishListViewController: NSFetchedResultsControllerDelegate {
    private func saveContext(){
        CoreDataManager.sharedInstance.saveContext()
    }
    
    private func fetch(){
        if let facebookId = facebookId {
            do {
                try fetchedResultsController.performFetch()
            } catch {
                let saveError = error as NSError
                print("\(saveError)")
            }
        } else {
            // TODO should we throw an error here and go back?
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        fetch()
        tableView.reloadData()
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension WishListViewController : UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        fetch()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections[section].numberOfObjects
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kReuseIdentifier, forIndexPath: indexPath)
        let wish = fetchedResultsController.objectAtIndexPath(indexPath) as! Wish
        cell.textLabel?.text = wish.title
        cell.detailTextLabel?.text = wish.detail
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let wish = fetchedResultsController.objectAtIndexPath(indexPath) as! Wish
            wishService.deleteWish(wish)
            tableView.reloadData()
        }
    }

    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let wish = fetchedResultsController.objectAtIndexPath(indexPath) as! Wish
        performSegueWithIdentifier(kSegueToEditWish, sender: wish)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}

extension WishListViewController {
    func syncNotificationRecieved(notification: NSNotification){
        print(notification.name)
        if let syncResult = notification.object as? SyncResult where syncResult.action == .Fetch && syncResult.entity == Wish.ENTITY_NAME
            && syncResult.status == .Successful {
            fetch()
            tableView.reloadData()
        }
    }
    
    private func registerForSyncNotifications(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "syncNotificationRecieved:", name: SYNC_RESULT_NOTIFICATION, object: nil)
    }
    
    private func deregisterFromSyncNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}


