//
//  FriendListViewController.swift
//  MyWishList
//
//  Created by Victor Guthrie on 2/7/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit
import CoreData

class FriendListViewController: UIViewController {
    
    let kReuseIdentifier = "friendListTableViewCell"
    let kSegueToFriendWishList = "segueToFriendWishList"
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()
        
        fetch()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier where identifier == kSegueToFriendWishList, let fWishListVC = segue.destinationViewController as? FriendWishListViewController, friend = sender as? Friend, userId = friend.id {
            fWishListVC.userId = userId
        }
    }
    
    // MARK: CoreData Context
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance.managedObjectContext
    }
    
    // MARK: Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: Friend.ENTITY_NAME)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Friend.Keys.name, ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

}

extension FriendListViewController : NSFetchedResultsControllerDelegate {
    private func saveContext(){
        CoreDataManager.sharedInstance.saveContext()
    }
    
    private func fetch(){
        do {
            try fetchedResultsController.performFetch()
        } catch {
            let saveError = error as NSError
            print("\(saveError)")
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        fetch()
        tableView.reloadData()
    }
}

extension FriendListViewController : UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
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
        let cell = tableView.dequeueReusableCellWithIdentifier(kReuseIdentifier, forIndexPath: indexPath) as! FriendTableViewCell
        let friend = fetchedResultsController.objectAtIndexPath(indexPath) as! Friend
        cell.nameLabel.text = friend.nameWithDefault
        cell.photoImageView.image = UIImage(named: "PhotoPlaceholder")
        if let pictureUrl = friend.picture {
            ImageService.sharedInstance.getImage(byUrlString: pictureUrl) { (image) -> Void in
                if let image = image {
                    dispatch_async(dispatch_get_main_queue(), {() -> Void in
                        cell.photoImageView.image = image
                    })
                }
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let friend = fetchedResultsController.objectAtIndexPath(indexPath)
        performSegueWithIdentifier(kSegueToFriendWishList, sender: friend)
    }
    
}

extension FriendListViewController {
    func syncNotificationRecieved(notification: NSNotification){
        print(notification.name)
        if let syncResult = notification.object as? SyncResult where syncResult.action == .Fetch && syncResult.entity == Friend.ENTITY_NAME
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
