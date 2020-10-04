//
//  TaskAddFriendMethodViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/08/25.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import Accounts

class TaskAddFriendMethodViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var taskAddFriendMethodTableView: UITableView!
    
    let imageLists:[UIImage] = [UIImage(named: "iconGroup")!, UIImage(named: "smaphoIcon")!, UIImage(named: "QRCodeIcon")!]
    let methodLists:[String] = ["IDで検索", "アプリで友達を招待する", "QRコードを読み取る"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        taskAddFriendMethodTableView.delegate = self
        taskAddFriendMethodTableView.dataSource = self
        configureTableViewCell()
        self.title = "友達を追加する"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //タブを隠す
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //タブを戻す
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func configureTableViewCell(){
        /* nibを作成*/
        let nib = UINib(nibName: "TaskAddFriendMethodTableViewCell", bundle: nil)
        
        /* ID */
        let cellID = "FriendMethodTableViewCell"
        
        /* 登録 */
        taskAddFriendMethodTableView.register(nib, forCellReuseIdentifier: cellID)
    }
    
    /* cellの高さ */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    /* cellの数 */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return methodLists.count
    }
    
    /* cellの内容 */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = taskAddFriendMethodTableView.dequeueReusableCell(withIdentifier: "FriendMethodTableViewCell", for: indexPath) as! TaskAddFriendMethodTableViewCell
        
        cell.methodImageView.image = imageLists[indexPath.row]
        if methodLists[indexPath.row]=="IDで検索"{
            cell.methodImageView.layer.cornerRadius = 25.0
        }
        cell.methodLabel.text = methodLists[indexPath.row]
        
        taskAddFriendMethodTableView.deselectRow(at: indexPath, animated: true)
        
        return cell
    }
    
    /* タップ時処理 */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //タップ後cellの色をすーっと変える
        taskAddFriendMethodTableView.deselectRow(at: indexPath, animated: true)
        
        if methodLists[indexPath.row]=="アプリで友達を招待する"{
            //ShareSheet表示
            self.dispShareSheet()
        }else if methodLists[indexPath.row]=="IDで検索"{
            //検索画面表示
            let vc = TaskAddFriendSearchViewController()
            navigationController?.pushViewController(vc, animated: true)
        }else if methodLists[indexPath.row]=="QRコードを読み取る"{
            //QRCode読み取り画面表示
            let vc = ReadQRCodeViewController()
            navigationController?.pushViewController(vc, animated: true)
        }else{
            /* NoAction */
        }
    }
    
    /* ShareSheet表示関数 */
    func dispShareSheet(){
        // 共有する項目
        /* 練習 */
        //let shareText = ShareItem("Apple - Apple Watch")
        //let shareWebsite = ShareItem(NSURL(string: "https://www.apple.com/jp/watch/")!)
        //let shareImage = ShareItem(UIImage(named: "Mikke")!)
        
        //let shareText = "Apple - Apple Watch"
        //let shareWebsite = NSURL(string: "https://www.apple.com/jp/watch/")!
        //let shareImage = UIImage(named: "Mikke")!
        /* 練習終わり */
        
        //パターン1:ShareSheet上にもSNSで通知した先にもアドレスが表示(shareTextの文言が出ている)
        /*
        let shareText = "aitaでメッセージのやり取りをしてみませんか?\nhttps://apps.apple.com/us/app/id1531293068"
        //let shareWebsite = ShareItem(NSURL(string: "https://apps.apple.com/us/app/id1531293068")!)
        let shareImage = ShareItem(UIImage(named: "aitaSNS")!)
        let activityItems = [shareText, shareImage] as [Any]
        */
        
        //パターン2:ShareSheet上はshareWebsiteに従ってアイコンも文言も表示。SNSで通知した先では下のアイテムが全て表示(リリース後はこっちが良さそう)
        let shareText = ShareItem("aitaでメッセージのやり取りをしてみませんか?")
        let shareWebsite = ShareItem(NSURL(string: "https://apps.apple.com/us/app/id1533569159")!)
        let shareImage = ShareItem(UIImage(named: "aitaSNS")!)
        let activityItems = [shareText, shareWebsite, shareImage] as [Any]
        
        
        // 初期化処理
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // 使用しないアクティビティタイプ
        let excludedActivityTypes = [
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.addToReadingList
        ]
        activityVC.excludedActivityTypes = excludedActivityTypes
        
        //iPadでActivityViewControllerを出すため
        activityVC.popoverPresentationController?.sourceView = self.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0,
                                                                      y: self.view.bounds.size.height / 2.0,
                                                                      width: 1.0,
                                                                      height: 1.0)
        // UIActivityViewControllerを表示
        self.present(activityVC, animated: true, completion: nil)
    }
}
