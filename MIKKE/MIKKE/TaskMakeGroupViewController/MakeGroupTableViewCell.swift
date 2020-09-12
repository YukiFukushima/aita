//
//  MakeGroupTableViewCell.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/24.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit

class MakeGroupTableViewCell: UITableViewCell {

    @IBOutlet weak var memberCandidateName: UILabel!
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var memberCandidateImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
