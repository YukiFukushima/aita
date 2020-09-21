//
//  TaskTutorialViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/09/15.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit

class TaskTutorialViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func tappedNextPageBtn(_ sender: Any) {
        let TutorialVC = statusTutorialViewController()
        
        //モーダルスタイルを指定
        TutorialVC.modalPresentationStyle = .fullScreen
        
        //表示
        self.present(TutorialVC, animated: true, completion: nil)
        
        /*
        //UserDefaultsに保存(最初のログイン時にフラグを落とす。ココでは落とさない。)
        //TutorialViewCompleteRepository.saveTutorialViewCompleteDefaults(tutorialComplete: true)
        
        //初期画面(ログイン画面)に遷移
        let vc=TaskLoginViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
        */
    }
    /*
    //"はじめよう"ボタン押下時関数
    @IBAction func tappedStartBtn(_ sender: Any) {
        let TutorialVC = statusTutorialViewController()
        
        //モーダルスタイルを指定
        TutorialVC.modalPresentationStyle = .fullScreen
        
        //表示
        self.present(TutorialVC, animated: true, completion: nil)
        
        /*
        //UserDefaultsに保存(最初のログイン時にフラグを落とす。ココでは落とさない。)
        //TutorialViewCompleteRepository.saveTutorialViewCompleteDefaults(tutorialComplete: true)
        
        //初期画面(ログイン画面)に遷移
        let vc=TaskLoginViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
        */
    }
    */
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
