//
//  ViewController.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/23.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseUI
import Accounts

class ViewController: UIViewController, UserInfoDelegate{
    @IBOutlet weak var nameTextField: UITextView!
    @IBOutlet weak var nameImageView: UIImageView!
    var localNameImageView:UIImageView!
    @IBOutlet weak var makeGroupLabel: UIButton!
    @IBOutlet weak var qrCodeLabel: UIButton!
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        UserInfoManager.sharedInstance.delegate = self      //己をセット
        setupNavigationBar()                                //ナビゲーションバーの設定
        
        //フォアグラウンド遷移時に呼ばれる関数登録
        NotificationCenter.default.addObserver(
        self,
        selector: #selector(ViewController.viewWillEnterForeground(_:)),
        name: UIApplication.willEnterForegroundNotification,
        object: nil)
        
        //画像の角丸具合の設定
        nameImageView.layer.cornerRadius = 50.0
        
        //名前を編集できないようにする
        nameTextField.isUserInteractionEnabled = false
        
        //初期のデータのロードはまだ未完了(初期画面はまだ未表示)
        InitViewCompleteRepository.saveInitViewCompleteDefaults(initComplete: false)
        
        //初期画面遷移判定
        /* ForDebug *
        TutorialViewCompleteRepository.saveTutorialViewCompleteDefaults(tutorialComplete: false)
        * ForDebugEnd */
        if TutorialViewCompleteRepository.loadTutorialViewCompleteDefaults()==false{
            //チュートリアル画面を表示
            self.presentTutorialViewController()
            return
        }else{
            //ログインチェック
            if self.isLogin() == false{
                // ログインビューコントローラを表示
                self.presentLoginViewController()
                return
            }else{
                // Initビューコントローラを表示
                self.presentInitViewController()
                return
            }
        }
    }
    
    //再描画時処理
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //print("名前と画像の表示")
        
        if InitViewCompleteRepository.loadInitViewCompleteDefaults()==true{
            //名前の表示
            self.nameTextField.isHidden = false
            self.viewName()
            
            //名前画像の表示
            self.nameImageView.isHidden = false
            self.viewNameImage()
            
            self.view.isHidden = false
        }else{
            self.nameTextField.isHidden = true
            self.nameImageView.isHidden = true
            self.view.isHidden = true
        }
    }
    
    //フォアグラウンド遷移時に呼ばれる関数
    @objc func viewWillEnterForeground(_ notification: Notification?) {
        UIApplication.shared.applicationIconBadgeNumber = 0     //バッジを消す
        if (self.isViewLoaded && (self.view.window != nil)) {
            //print("フォアグラウンド")
        }
    }
    
    // 名前の表示関数
    func viewName(){
        let currentUserName = UserInfoManager.sharedInstance.getNameAtCurrentUserID()
        if currentUserName==""{
            self.nameTextField.text = "名前未登録"
        }else{
            self.nameTextField.text = currentUserName
        }
    }
    
    // //名前画像の表示関数
    func viewNameImage(){
        let userRef = self.getUserRef()
        downloadFromCloudStorage(userRef:userRef)
    }
    
    //CloudStorageからダウンロードしてくる関数
    func downloadFromCloudStorage(userRef:StorageReference){
        //placeholderの役割を果たす画像をセット
        let placeholderImage = UIImage(systemName: "photo")
        
        //読み込み
        nameImageView.sd_setImage(with: userRef, placeholderImage: placeholderImage)
        
        //読み込み(プロフィールの編集に渡す時の為にLocalに保存)
        localNameImageView = nameImageView
    }
    
    //チュートリアル画面の表示関数
    func presentTutorialViewController(){
        let TutorialVC = TaskTutorialViewController()
        
        //モーダルスタイルを指定
        TutorialVC.modalPresentationStyle = .fullScreen
        
        //表示
        self.present(TutorialVC, animated: true, completion: nil)
    }
    
    //Init画面の表示関数
    func presentInitViewController(){
        let InitVC = TaskInitViewController()
        
        //モーダルスタイルを指定
        InitVC.modalPresentationStyle = .fullScreen
        
        //表示
        self.present(InitVC, animated: true, completion: nil)
    }
    
    //ログイン画面の表示関数
    func presentLoginViewController(){
        let loginVC = TaskLoginViewController()
        
        //モーダルスタイルを指定
        loginVC.modalPresentationStyle = .fullScreen
        
        //表示
        self.present(loginVC, animated: true, completion: nil)
    }
    
    //ログイン認証されているかどうかの判定関数
    func isLogin() -> Bool{
        //ログインしているユーザーがいるかどうかを判別
        if Auth.auth().currentUser != nil{
            return true
        }else{
            return false
        }
    }
    
    // navigation barの設定
    private func setupNavigationBar() {
        /*
        //画面上部のナビゲーションバーの右側に+ボタンを配置
        let rightButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showMakeGroupView))
        navigationItem.rightBarButtonItem = rightButtonItem
        
        //画面上部のナビゲーションバーの左側にログアウトボタンを設置し、押されたらログアウト関数がcallされるようにする
        let leftButtonItem = UIBarButtonItem(title: "ログアウト", style: .plain, target: self, action: #selector(logout))
        
        //let leftButtonItem = UIBarButtonItem(image: UIImage(named: "logout")!, style: .plain, target: self, action: #selector(logout))
        navigationItem.leftBarButtonItem = leftButtonItem
        */
        
        //タイトルを変更
        self.title = "ホーム"
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
    
    //グループの作成ボタンを押下時の処理を記載
    @IBAction func tappedMakeGroupBtn(_ sender: Any) {
        if UserInfoManager.sharedInstance.getNameAtCurrentUserID().isEmpty{
            self.showAlert(title:"名前未登録", message: "プロフィールを編集して名前を\n登録してください")
        }else{
            let vc = TaskMakeTableViewController()
            
            //新規グループの作成なのでリクエストするグループIDは空文字
            vc.requestGroupId = ""
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    //プロフィールの編集ボタンを押下時の処理を記載
    @IBAction func tappedRenameBtn(_ sender: Any) {
        let vc = TaskEditUserInfoViewController()
        vc.imageViewFromHomeView = localNameImageView
        navigationController?.pushViewController(vc, animated: true)
        //self.present(vc, animated: true, completion: nil)
    }
    
    //QRCodeボタン押下時関数
    @IBAction func tappedQRCodeBtn(_ sender: Any) {
        if UserInfoManager.sharedInstance.getNameAtCurrentUserID().isEmpty{
            self.showAlert(title:"名前未登録", message: "プロフィールを編集して名前を\n登録してください")
        }else{
            let vc = TaskQRCodeViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
        
        /* ForDebug*
        // UserDefaultsのオールクリア
        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)
        GroupInfoManager.sharedInstance.saveGroupInfo()
        * EndForDebug */
        
        /* ForDebug *
        // Firestoreのオールクリア
        print("deleteCount : ")
        print(UserInfoManager.sharedInstance.getUserListsCount())
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            let taskId = UserInfoManager.sharedInstance.userLists[i].taskId
            let userId = UserInfoManager.sharedInstance.userLists[i].userID
            
            print("delete : ")
            print(taskId)
            print("delete2 : ")
            print(userId)
            
            db.collection("Users").document(taskId).delete()
        }
        * EndForDebug */
    }
    
    //友達の招待ボタン押下時関数
    @IBAction func tappedInviteFriendsBtn(_ sender: Any) {
        let vc = TaskAddFriendMethodViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //ログアウトボタンを押下時の処理を記載
    @IBAction func tappedLogoutBtn(_ sender: Any) {
        // アクションシートを表示する
        let alertSheet = UIAlertController(title: nil, message: "本当にログアウトしますか？", preferredStyle: .actionSheet)
        
        //ログアウトを選んだとき
        let logoutAction = UIAlertAction(title: "ログアウト", style: .default) { action in
            print("ログアウトが選択されました")
            self.actLogout()
        }
        
        //キャンセルを選んだとき
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { action in
            print("キャンセルが選択されました")
        }
        
        alertSheet.addAction(logoutAction)
        alertSheet.addAction(cancelAction)
        
        present(alertSheet, animated: true)
        
    }
    
    //ログアウトの実行関数
    func actLogout(){
        do{
            try Auth.auth().signOut()
            
            //ログアウトに成功したら、ログイン画面を表示
            self.presentLoginViewController()
            
        }catch let signOutError as NSError{
            print("サインアウトエラー:\(signOutError)")
        }
    }
    
    /* 以下現在、未使用 *********************************************************/
    // +ボタンをタップしたときの動作
    @objc func showMakeGroupView() {
        let vc = TaskMakeTableViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // ログアウトボタンをタップしたときの動作
    @objc func logout() {
        do{
            try Auth.auth().signOut()
            
            //ログアウトに成功したら、ログイン画面を表示
            self.presentLoginViewController()
            
        }catch let signOutError as NSError{
            print("サインアウトエラー:\(signOutError)")
        }
    }
    /* 未使用関数終了 *************************************************************/
}

