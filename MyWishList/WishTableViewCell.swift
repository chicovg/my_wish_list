//
//  WishTableViewCell.swift
//  MyWishList
//
//  Created by Victor Guthrie on 1/23/16.
//  Copyright © 2016 chicovg. All rights reserved.
//

import UIKit

class WishTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
