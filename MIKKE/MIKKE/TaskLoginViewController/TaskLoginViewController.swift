//
//  TaskLoginViewController.swift
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

class TaskLoginViewController: UIViewController, UserInfoDelegate, UITextFieldDelegate {

    @IBOutlet weak var emailTextView: UITextField!
    @IBOutlet weak var passwordTextView: UITextField!
    
    let db = Firestore.firestore()
    let dispatchGroup = DispatchGroup()
    let dispatchQueue1 = DispatchQueue(label: "initView1", attributes: .concurrent)
    let dispatchQueue2 = DispatchQueue(label: "initView2", attributes: .concurrent)
    let dispatchQueue3 = DispatchQueue(label: "initView3", attributes: .concurrent)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        UserInfoManager.sharedInstance.delegate = self  //己にセット
        emailTextView.delegate = self
        passwordTextView.delegate = self
        passwordTextView.isSecureTextEntry = true       //pw非表示
        
        /* ForDebug *
        print("deleteCount2 : ")
        print(UserInfoManager.sharedInstance.getUserListsCount())
        * ForDebugEnd */
    }
    
    //成功時の画面遷移処理
    func presentTaskHomeViewController(){
        //初期画面終了
        InitViewCompleteRepository.saveInitViewCompleteDefaults(initComplete: true)
        
        //チュートリアル画面からの遷移なら
        if TutorialViewCompleteRepository.loadTutorialViewCompleteDefaults()==false{
            TutorialViewCompleteRepository.saveTutorialViewCompleteDefaults(tutorialComplete: true) //チュートリアル画面表示済み
            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil) //前の前の画面表示
        }else{
            self.dismiss(animated: true, completion: nil)   //前の画面表示
        }
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
    
    //新規登録の際のエラー表示
    func newRegisterErrAlert(error:NSError){
        //引数errorのもつコードを使って、EnumであるAuthErrorCodeを読み出し
        if let errCode = AuthErrorCode(rawValue: error.code){
            var message = ""
            
            switch errCode {
            case .invalidEmail:
                message = "有効なメッセージを入力して下さい"
            case .emailAlreadyInUse:
                message = "既に登録されているEmailアドレスです"
            case .weakPassword:
                message = "パスワードは6文字以上で入力してください"
                
            default:
                message = "エラー：\(error.localizedDescription)"
            }
            
            //アラート表示
            self.showAlert(title: "登録できませんでした", message: message)
        }
    }
    
    //ログインの際のエラー表示
    func logInErrAlert(error:NSError){
        //引数errorのもつコードを使って、EnumであるAuthErrorCodeを読み出し
        if let errCode = AuthErrorCode(rawValue: error.code){
            var message = ""
            
            switch errCode {
            case .userNotFound:
                message = "アカウントが見つかりませんでした"
            case .wrongPassword:
                message = "パスワードを確認してください"
            case .userDisabled:
                message = "アカウントが無効になっています"
            case .invalidEmail:
                message = "Emailが無効な形式です"
            default:
                message = "エラー：\(error.localizedDescription)"
            }
            
            //アラート表示
            self.showAlert(title: "ログインできませんでした", message: message)
        }
    }
    
    //新規登録処理
    func emailNewRegister(email:String, password:String){
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error as NSError?{
                //エラー時の処理
                self.newRegisterErrAlert(error:error)
            }
            else{
                //新規登録時は、NoImageの画像をアプロード
                self.uploadNoImageCloudStorage()
                
                //新規登録時は、NoImageの画像をアプロード後に、成功時の処理
                //self.actSuccessLogin()
            }
        }
    }
    
    //NoImage画像をcloudにupdateする関数
    func uploadNoImageCloudStorage(){
        let userRef = getUserRef()
        
        //guard let data = self.resultImageView.image?.pngData() else { return }
        guard let data = UIImage(named: "はてな")?.pngData() else { return }
        let meta = StorageMetadata()
        meta.contentType = "image/png"
        
        //データをアップロード
        userRef.putData(data, metadata: meta) { (metadata, err) in
            guard let metadata = metadata else {
                print("upload error")
                return
            }
            let size = metadata.size
            
            //アップロード時の画像のサイズ
            print("\(size):size")
            
            //画像アップ時に端末のキャッシュ削除することで、画像変更時の反映が素早くなる（SDWebImageはFirebaseUIが採用しているライブラリ）
            SDImageCache.shared.clearMemory()
            SDImageCache.shared.clearDisk()
            
            //成功時の処理
            self.actSuccessLogin()
        }
    }
    
    //ログイン処理
    func emailLogin(email:String, password:String){
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error as NSError?{
                //エラー時の処理
                self.logInErrAlert(error:error)
            }
            else{
                //成功時の処理
                self.actSuccessLogin()
            }
        }
    }
    
    //ログイン時の警告表示共通関数
    func commonAlert(email:String, password:String)->Bool{
        var result:Bool = false
        
        if email.isEmpty && password.isEmpty{
            self.showAlert(title:"エラー", message: "メールアドレスとパスワードを入力してください")
        }
        else if email.isEmpty{
            self.showAlert(title:"エラー", message: "メールアドレスを入力してください")
        }
        else if password.isEmpty{
            self.showAlert(title:"エラー", message: "パスワードを入力してください")
        }
        else{
            result = true
        }
        
        return result
    }
    
    //リストへの追加処理関数
    func addUserInfo(){
        //新しくタスクIDを取得
        let taskId = db.collection("Users").document().documentID
        
        //新しい情報(taskId, userID, ..)で、クラスを実体化
        let userInfo = UserInfo(taskId:taskId,userID:String(describing:Auth.auth().currentUser?.uid), name:"", userToken:"", uniqueUserId:"", friendIds:[""], groupIds:[""], verifyGroupIds:[""], createdAt:Timestamp(), updatedAt:Timestamp())
        
        //最初は配列を空にして生成する
        userInfo.friendIds.removeAll()
        userInfo.groupIds.removeAll()
        userInfo.verifyGroupIds.removeAll()
        
        //Firestoreに保存
        do{
            //Firestoreに保存出来るように変換する
            let encodeUserInfo:[String:Any] = try Firestore.Encoder().encode(userInfo)
            
            //保存
            db.collection("Users").document(taskId).setData(encodeUserInfo)
            
            //リスト(配列)に追加
            UserInfoManager.sharedInstance.appendUserLists(userInfo:userInfo)
            
        }catch let error as NSError{
            print("エラー\(error)")
            self.showAlert(title:"エラー", message: "データの読み込みに失敗しました")
        }
    }
    
    //ユーザーTokenのセット
    func setUserToken(userToken:String){
        //ユーザーTokenを配列に保存
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() { //ユーザーリストをチェック
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                UserInfoManager.sharedInstance.userLists[i].userToken = userToken
                break
            }
        }
        
        //firestoreに保存
        do{
            //Firestoreに保存出来るように変換する
            let encodeUserInfo:[String:Any] = try Firestore.Encoder().encode(UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID())
            
            //Firestoreに書き込み
            db.collection("Users").document(UserInfoManager.sharedInstance.getTaskIdAtCurrentUserID()).setData(encodeUserInfo)
            
        }catch let error as NSError{
            print("エラー\(error)")
            self.showAlert(title:"エラー", message: "データの読み込みに失敗しました")
        }
    }
    
    //既存ユーザーチェック関数
    func checkExistingUser(){
        if UserInfoManager.sharedInstance.getUserListsCount()==0{               //ユーザーリストが空なら追加
            //リストに追加
            addUserInfo()
        }else{                                                                  //ユーザーリストに何かあるなら
            var isExistUser:Bool = false                                        //ユーザー判定フラグ(最初、ユーザーは未登録から開始)
            for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() { //ユーザーリストをチェック
                /* ForDebug *
                print("UserInfoUserID:")
                print(UserInfoManager.sharedInstance.userLists[i].userID)
                print("FirebaseUserID:")
                print(String(describing:Auth.auth().currentUser?.uid))
                * ForDebugEnd */
                
                if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                    isExistUser = true  //ユーザーは登録済み
                    break
                }
            }
            
            if isExistUser==false{      //ユーザーが未登録なら
                //リストに追加
                addUserInfo()
            }
        }
        
        //ユーザー固有Tokenをセット
        self.setUserToken(userToken: UserTokenRepository.loadUserTokenUserDefaults())
        
        //Home画面表示
        self.presentTaskHomeViewController()
    }
    
    //成功時の処理
    func actSuccessLogin(){
        //print("SyncStartLogin")
        
        GroupInfoManager.sharedInstance.groupInfo.removeAll()                   //配列(Group情報)をクリア
        readGroupInfoFromFirestore()                                            //Firebaseから読み込み(同期処理含む)
        
        UserInfoManager.sharedInstance.userLists.removeAll()                    //配列(User情報)をクリア
        readUserInfoFromFirestore()                                             //Firebaseから読み込み(同期処理含む)
        
        dispatchGroup.notify(queue: DispatchQueue.main){                        //全てのタスクが完了したらコールされる
            //print("SyncEndLogin")
            //Firestoreから読み出し後、新規ユーザーか既存ユーザーかをチェック
            self.checkExistingUser()
        }
    }
    
    //Firestoreからのデータ(ユーザ情報)の読み込み
    func readUserInfoFromFirestore(){
        //同期処理開始
        dispatchGroup.enter()
        
        //print("UserSyncStart")
        
        self.db.collection("Users").order(by: "createdAt", descending: true).getDocuments { (querySnapShot, err) in
            if let err = err{
                print("エラー:\(err)")
                self.showAlert(title: "読み込みに失敗しました", message: "アプリを立ち上げ直してください")
            }else{
                /* ForDebug
                 var i:Int = 0
                 * ForDebugEnd */
                
                self.dispatchQueue1.async(group: self.dispatchGroup){
                    //取得したDocument群の1つ1つのDocumentについて処理をする
                    for document in querySnapShot!.documents{
                        //各DocumentからはDocumentIDとその中身のdataを取得できる
                        //print("\(document.documentID) => \(document.data())")
                        //型をUserInfo型に変換
                        do {
                            let decodedTask = try Firestore.Decoder().decode(UserInfo.self, from: document.data())
                            //変換に成功
                            UserInfoManager.sharedInstance.appendUserLists(userInfo: decodedTask)
                            
                            /* ForDebug
                             print("taskId:")
                             print(UserInfoManager.sharedInstance.userLists[i].taskId)
                             print("userID:")
                             print(UserInfoManager.sharedInstance.userLists[i].userID)
                             print("name:")
                             print(UserInfoManager.sharedInstance.userLists[i].name)
                             print("createdAt:")
                             print(UserInfoManager.sharedInstance.userLists[i].createdAt)
                             print("updatedAt:")
                             print(UserInfoManager.sharedInstance.userLists[i].updatedAt)
                             i += 1
                             * ForDebugEnd */
                            
                        } catch let error as NSError{
                            print("エラー:\(error)")
                            self.showAlert(title: "読み込みに失敗しました", message: "アプリを立ち上げ直してください")
                        }
                    }
                }
                
                //print("UserSyncEnd")
                
                //同期処理終了
                self.dispatchGroup.leave()
            }
        }
    }
    
    //Firestoreからのトーク情報の読み込み
    func readTalksInfoFromFireStore(){
        //同期処理開始
        dispatchGroup.enter()
        
        //print("GroupTalkSyncStart")
        
        self.db.collection("Talks").order(by: "groupMemberTalksCreatedAt", descending: true).getDocuments { (querySnapShot, err) in
            
            //トーク情報を初期化
            GroupInfoManager.sharedInstance.initGroupTalkInfo()
            
            //再度読み直して配列に保存
            if let err = err{
                print("エラー:\(err)")
            }else{
                self.dispatchQueue3.async(group: self.dispatchGroup){
                    //取得したDocument群の1つ1つのDocumentについて処理をする
                    for document in querySnapShot!.documents{
                        //各DocumentからはDocumentIDとその中身のdataを取得できる
                        //print("\(document.documentID) => \(document.data())")
                        //型をUserInfo型に変換([String:Any]型で記録する為、変換が必要)
                        do {
                            
                            let decodedTask = try Firestore.Decoder().decode(GroupMemberTalksInfo.self, from: document.data())
                            //変換に成功
                            GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId:decodedTask.groupId).groupMemberTalksInfo.insert(decodedTask, at: 5)
                            //GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId:decodedTask.groupId).groupMemberTalksInfo.append(decodedTask)
                            
                            //GroupInfoManager.sharedInstance.getGroupInfo(num: groupNum).groupMemberTalksInfo.append(decodedTask)
                            //GroupInfoManager.sharedInstance.appendGroupInfo(groupInfo: decodedTask)
                            //GroupInfoManager.sharedInstance.groupInfo.insert(decodedTask, at: self.groupNumber)
                        } catch let error as NSError{
                            print("エラー:\(error)")
                        }
                    }
                    
                    //print("GroupTalkSyncEnd")
                    
                    //同期処理終了
                    self.dispatchGroup.leave()
                }
            }
        }
    }
    
    //Firestoreからのデータ(会話グループ情報)の読み込み
    func readGroupInfoFromFirestore(){
        //同期処理開始
        dispatchGroup.enter()
        
        print("GroupSyncStart")
        
        self.db.collection("Groups").order(by: "createdAt", descending: true).getDocuments { (querySnapShot, err) in
            if let err = err{
                print("エラー:\(err)")
            }else{
                self.dispatchQueue2.async(group: self.dispatchGroup){
                    //取得したDocument群の1つ1つのDocumentについて処理をする
                    for document in querySnapShot!.documents{
                        //各DocumentからはDocumentIDとその中身のdataを取得できる
                        //print("\(document.documentID) => \(document.data())")
                        //型をUserInfo型に変換([String:Any]型で記録する為、変換が必要)
                        do {
                            let decodedTask = try Firestore.Decoder().decode(GroupInfo.self, from: document.data())
                            //変換に成功
                            GroupInfoManager.sharedInstance.appendGroupInfo(groupInfo: decodedTask)
                        } catch let error as NSError{
                            print("エラー:\(error)")
                        }
                    }
                    
                    print("GroupSyncEnd")
                    
                    self.readTalksInfoFromFireStore()
                    
                    //同期処理終了
                    self.dispatchGroup.leave()
                }
            }
        }
        
    }
    
    /* textに答えを入力した時にキーボードを消す(textFieldのprotocolに用意されているメソッド) */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    /* タッチした時にキーボードを消す(UIViewControllerに用意されているメソッド) */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    //ログインボタン押下時関数
    @IBAction func tappedLoginBtn(_ sender: Any) {
        guard let email = emailTextView.text, let password = passwordTextView.text else{return}
        
        if commonAlert(email:email, password:password)==true {
            //ログイン処理
            self.emailLogin(email: email, password: password)
        }
    }
    
    //新規登録ボタン押下時関数
    @IBAction func tappedNewRegisterBtn(_ sender: Any) {
        guard let email = emailTextView.text, let password = passwordTextView.text else{return}
        
        if commonAlert(email:email, password:password)==true {
            //新規登録処理
            self.emailNewRegister(email: email, password: password)
        }
    }
}
