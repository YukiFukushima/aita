//
//  TaskQRCodeResultViewController.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/28.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class TaskQRCodeResultViewController: UIViewController, UserInfoDelegate {

    @IBOutlet weak var resultQRCodelabel: UILabel!
    var passResultQRCode:String = ""
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        UserInfoManager.sharedInstance.delegate = self      //己をセット
        setupNavigationBar()                                //ナビゲーションバーの設定
        analizeQRCodeResult(QRCodeResult:passResultQRCode)  //QRコードの結果を表示
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    //引数で指定されたユーザーが既に登録済みか否かチェックする関数
    func checkRegisterdFriend(friendName:String)->Bool{
        var result:Bool = false
        
        for i in 0 ..< UserInfoManager.sharedInstance.getFriendCountAtCurrentUserID() {
            if friendName==UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().friendIds[i]{
                result = true
                break
            }
        }
        return result
    }
    
    //QRCodeからの結果を判定し表示する
    func analizeQRCodeResult(QRCodeResult:String){
        var resultAnalizeQRCode:Bool = false    //false(ユーザーがいなかった)/true(ユーザーがいた)
        
        //結果の表示
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            var idName:String = ""
            var idUserName:String = ""
            idName = UserInfoManager.sharedInstance.userLists[i].userID
            idUserName = UserInfoManager.sharedInstance.userLists[i].name
            if idName==passResultQRCode{
                resultAnalizeQRCode = true  //ユーザーがいた
                if checkRegisterdFriend(friendName:idName){
                    if idUserName==""{
                        resultQRCodelabel.text = "登録済みです\n(名前がまだ未登録です)"
                    }else{
                        resultQRCodelabel.text = idUserName+"\n\nは登録済みです"
                    }
                }else{
                    if idUserName==""{
                        resultQRCodelabel.text = "友達に追加しました!\n(名前がまだ未登録です)"
                    }else{
                        resultQRCodelabel.text = idUserName+"\n\nを友達に追加しました!"
                    }
                    
                    //現在のユーザーの友達リストに追加
                    UserInfoManager.sharedInstance.appendFriendAtCurrentUserID(friendUserId: QRCodeResult)
                    
                    //Firestoreに保存
                    do{
                        //Firestoreに保存出来るように変換する
                        let encodeUserInfo:[String:Any] = try Firestore.Encoder().encode(UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID())
                        
                        //Firestoreに書き込み
                        db.collection("Users").document(UserInfoManager.sharedInstance.getTaskIdAtCurrentUserID()).setData(encodeUserInfo)
                        
                    }catch let error as NSError{
                        print("エラー\(error)")
                    }
                }
                break
            }else{
                /* NoAction */
            }
        }
        
        //QRCode結果に応じたアクション
        if resultAnalizeQRCode==false{
            resultQRCodelabel.text = "不明なユーザーです"
            var message = ""
            message = "アプリを立ち上げ直してください"
            self.showAlert(title: "QRコードの読み取りに失敗しました", message: message)
        }
        
        //画面遷移
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
            self.tabBarController?.tabBar.isHidden = false
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        /* ForDebug *
        //resultQRCodelabel.text = passResultQRCode
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            var idName:String = ""
            var idUserName:String = ""
            idName = UserInfoManager.sharedInstance.userLists[i].userID
            idUserName = UserInfoManager.sharedInstance.userLists[i].name
            if idName==passResultQRCode{
                resultQRCodelabel.text = idUserName
                break
            }else{
                resultQRCodelabel.text = "不明なユーザーです"
            }
        }
        * EndForDebug */
    }
    
    // navigation barの設定
    private func setupNavigationBar() {
        /*
        //画面上部のナビゲーションバーの左側にログアウトボタンを設置し、押されたらログアウト関数がcallされるようにする
        let leftButtonItem = UIBarButtonItem(title: "HOME", style: .done, target: self, action: #selector(homeBtn))
        navigationItem.leftBarButtonItem = leftButtonItem
        */
        //Backボタンを隠す
        self.navigationItem.hidesBackButton = true
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
    
    // HOMEボタンをタップしたときの動作
    @objc func homeBtn() {
        /*
        self.navigationController?.popToRootViewController(animated: true)
        */
    }
}
