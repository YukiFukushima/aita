//
//  taskPrivacyViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/10/06.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import WebKit

class taskPrivacyViewController: UIViewController {

    @IBOutlet weak var wkWebView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    
    
    @IBAction func tappedBackBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
