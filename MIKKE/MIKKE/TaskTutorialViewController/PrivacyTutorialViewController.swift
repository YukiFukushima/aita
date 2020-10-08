//
//  PrivacyTutorialViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/10/06.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import WebKit

class PrivacyTutorialViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var wkWebView: WKWebView!
    @IBOutlet weak var tappedStartBtnLabel: UIButton!
    @IBOutlet weak var loadingMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //delegateセット
        wkWebView.navigationDelegate = self
        
        
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

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("status")
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Start")
        
        //ボタンをまだ押せないようにする
        tappedStartBtnLabel.isUserInteractionEnabled = false
        tappedStartBtnLabel.layer.borderColor = UIColor.darkGray.cgColor
        tappedStartBtnLabel.backgroundColor = .lightGray
        
        //メッセージを出す
        loadingMessageLabel.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finish")
        
        //ボタンを押せるようにする
        tappedStartBtnLabel.isUserInteractionEnabled = true
        tappedStartBtnLabel.layer.borderColor = UIColor.systemTeal.cgColor
        tappedStartBtnLabel.backgroundColor = .clear
        
        //メッセージを消す
        loadingMessageLabel.isHidden = true
        
        /* ForDebug *
        self.showAlert(title: "読み込みに失敗しました", message: "アプリを立ち上げ直してください")
        * EndForDebug */
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Err!")
        
        self.showAlert(title: "読み込みに失敗しました", message: "アプリを立ち上げ直してください")
    }
    
    //アラート表示関数
    func showAlert( title:String, message:String? ){
        //UIAlertControllerを関数の引数であるとtitleとmessageを使ってインスタンス化
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        //UIAlertActionを追加
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        //表示
        self.present(alertVC, animated: true, completion: nil)
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
