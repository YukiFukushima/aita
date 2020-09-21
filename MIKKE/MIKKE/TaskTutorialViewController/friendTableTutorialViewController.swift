//
//  friendTableTutorialViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/09/18.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit

class friendTableTutorialViewController: UIViewController {

    @IBOutlet weak var currentPageStatus: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        currentPageStatus.backgroundColor = .darkGray
    }


    @IBAction func tappedNextPageBtn(_ sender: Any) {
        let TutorialVC = settingTutorialViewController()
        
        //モーダルスタイルを指定
        TutorialVC.modalPresentationStyle = .fullScreen
        
        //表示
        self.present(TutorialVC, animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
