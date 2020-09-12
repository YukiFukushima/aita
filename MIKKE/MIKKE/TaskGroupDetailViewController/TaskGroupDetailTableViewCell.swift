//
//  TaskGroupDetailTableViewCell.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/26.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit

class TaskGroupDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var groupDetailTextView: UITextView!
    @IBOutlet weak var GroupDetailImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var postName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = .clear   //セルの色を透明にする
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
