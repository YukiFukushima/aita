//
//  TaskGroupTableViewCell.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/25.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit

class TaskGroupTableViewCell: UITableViewCell {

    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var userStatusLabel: UILabel!
    @IBOutlet weak var currentUserImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
