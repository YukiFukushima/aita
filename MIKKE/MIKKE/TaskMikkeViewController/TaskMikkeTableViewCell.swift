//
//  TaskMikkeTableViewCell.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/08/07.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit

class TaskMikkeTableViewCell: UITableViewCell {

    @IBOutlet weak var userStatusLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userDetailStatusLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
