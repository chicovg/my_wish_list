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
    
    var firebaseClient: FirebaseClient {
        return FirebaseClient.sharedInstance
    }
    
    var user: User!
    var wishes: [Wish] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier where identifier == kSegueToEditWish,
            let editVC = segue.destinationViewController as? EditWishViewController,
            indexPath = tableView.indexPathForSelectedRow {
            editVC.user = user
            editVC.wishToEdit = wishes[indexPath.row]
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
        let loginVC = self.storyboard?.instantiateViewControllerWithIdentifier(loginViewControllerId) as! LoginViewController
        self.presentViewController(loginVC, animated: true, completion: { () -> Void in
            loginVC.logout()
            print("Logged Out..")
        })
    }
    
}

// MARK: UITableViewDataSource, UITableViewDelegate
extension WishListViewController : UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        firebaseClient.queryWishes() { (wishes: [Wish]) -> Void in
            self.wishes = wishes
            self.tableView.reloadData()
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
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let wish = wishes[indexPath.row]
            firebaseClient.deleteWish(wish: wish) { (error) -> Void in
                if let err = error{
                    print("delete failed \(err)")
                } else {
                    self.wishes.removeAtIndex(indexPath.row)
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(kSegueToEditWish, sender: nil)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}



