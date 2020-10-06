//
//  PrivacyTutorialViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/10/06.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import WebKit

class PrivacyTutorialViewController: UIViewController {

    @IBOutlet weak var wkWebView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //利用規約表示
        self.loadWebView(urlString:"https://yukifukushima.github.io/aitaPolicy/")
        //スワイプで進む、戻るを有効にする
        self.wkWebView.allowsBackForwardNavigationGestures = true
    }

    func loadWebView(urlString:String){
        let myURL = URL(string: urlString)
        
        let myReq = URLRequest(url:myURL!)
        
        self.wkWebView.load(myReq)
    }

    @IBAction func tappedStartBtn(_ sender: Any) {
        //UserDefaultsに保存(最初のログイン時にフラグを落とす。ココでは落とさない。)
        //TutorialViewCompleteRepository.saveTutorialViewCompleteDefaults(tutorialComplete: true)
        
        //初期画面(ログイン画面)に遷移
        let vc=TaskLoginViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
}
