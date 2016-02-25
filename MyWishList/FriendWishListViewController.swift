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
    
    var firebaseClient: FirebaseClient {
        return FirebaseClient.sharedInstance
    }
    
    var wishes : [Wish] = []
    var user : User!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTableView()
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

}

// MARK: UITableViewDataSource, UITableViewDelegate
extension FriendWishListViewController : UITableViewDataSource, UITableViewDelegate {
    
    private func setupTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        firebaseClient.queryWishes(forUser: user) { (wishes: [Wish]) -> Void in
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
}



