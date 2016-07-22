//
//  WishTableViewCell.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/23/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit

class PromisedWishTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var friendsImage: UIImageView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var promisedToLabel: UILabel!
    @IBOutlet weak var promisedOnLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setPromsedLabel(friend: String, promisedOn: NSDate) {
        let timeBetween = promisedOn.timeIntervalSinceNow
        let daysSince = Int(0 - round(timeBetween/(60 * 60 * 24)))
        promisedToLabel.text = "Promised to \(friend)"
        promisedOnLabel.text = "\(daysSince > 0 ? "\(daysSince) days ago" : "today")"
    }

}
