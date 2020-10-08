//
//  taskPrivacyViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/10/06.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import WebKit

class taskPrivacyViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var wkWebView: WKWebView!
    @IBOutlet weak var backBtnLabel: UIButton!
    @IBOutlet weak var loadingMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        backBtnLabel.isUserInteractionEnabled = false
        backBtnLabel.layer.borderColor = UIColor.darkGray.cgColor
        backBtnLabel.backgroundColor = .lightGray
        
        //メッセージを消す
        loadingMessageLabel.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finish")
        
        //ボタンを押せるようにする
        backBtnLabel.isUserInteractionEnabled = true
        backBtnLabel.layer.borderColor = UIColor.systemTeal.cgColor
        backBtnLabel.backgroundColor = .clear
        
        //メッセージを出す
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
    
    @IBAction func tappedBackBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
