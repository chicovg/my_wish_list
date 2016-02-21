//
//  FriendWishListViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/14/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class FriendWishListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let kReuseIdentifier = "friendWishListTableViewCell"
    
    var userId : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let userId = userId {
            setupTableView()
            registerForSyncNotifications()
            WishService.sharedInstance.fetchWishes(byUserId: userId)
        } else {
            // Error?
        }
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
    
    // MARK: CoreData Context
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    // MARK: Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: Wish.ENTITY_NAME)
        fetchRequest.predicate = NSPredicate(format: "\(Wish.Keys.userId) == %@", self.userId!)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Wish.Keys.title, ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

}

extension FriendWishListViewController: NSFetchedResultsControllerDelegate {
    private func saveContext(){
        CoreDataManager.sharedInstance.saveContext()
    }
    
    private func fetch(){
        if let _ = userId {
            do {
                try fetchedResultsController.performFetch()
            } catch {
                let saveError = error as NSError
                print("\(saveError)")
            }
        } else {
            // TODO throw error
        }
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        fetch()
        tableView.reloadData()
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension FriendWishListViewController : UITableViewDataSource, UITableViewDelegate {
    
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
    
//    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        
//    }
//    
//    // MARK: UITableViewDelegate
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        let wish = fetchedResultsController.objectAtIndexPath(indexPath) as! Wish
////        performSegueWithIdentifier(kSegueToEditWish, sender: wish)
//    }
//    
//    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        return true
//    }
}

extension FriendWishListViewController {
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



