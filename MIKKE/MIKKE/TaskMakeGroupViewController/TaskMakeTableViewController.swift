//
//  TaskMakeTableViewController.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/24.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseUI

class TaskMakeTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, GroupInfoDelegate, UserInfoDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var groupNameLabel: UITextField!
    @IBOutlet weak var makeGroupTableView: UITableView!
    let db = Firestore.firestore()
    
    //グループ候補格納変数
    var groupCandidate = GroupInfo(taskId:"",
                                   groupName:"",
                                   GroupMemberNamesInfo:[],
                                   groupMemberTalksInfo:[],
                                   createdAt:Timestamp(date:Date()),
                                   updatedAt:Timestamp(date:Date()))
    
    //新規グループ作成時(requestGroupIdが空文字)/グループメンバー追加時(requestGroupIdが任意のGrId)
    var requestGroupId:String = ""
    
    //同期用変数
    let dispatchGroup = DispatchGroup()
    let dispatchQueue = DispatchQueue(label: "searchView", attributes: .concurrent)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        makeGroupTableView.delegate = self
        makeGroupTableView.dataSource = self
        GroupInfoManager.sharedInstance.delegate = self
        UserInfoManager.sharedInstance.delegate = self
        groupNameLabel.delegate = self
        configureTableViewCell()
        
        /* ForDebug *
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            let groupDebug:GroupInfo = GroupInfoManager.sharedInstance.getGroupInfo(num: i)
            let groupNameDebug:String = groupDebug.groupName
            let groupMemberDebug:[GroupMemberNamesInfo] = groupDebug.GroupMemberNamesInfo
            
            print("グループ名"+groupNameDebug)
            for j in 0 ..< groupMemberDebug.count {
                let groupMemberDetail = groupMemberDebug[j].groupMemberNames
                print(groupMemberDetail)
            }
            
            /*
            let groupDebug:GroupInfo = GroupInfoManager.sharedInstance.getGroupInfo(num: i)
            let groupNameDebug:String = groupDebug.groupName
            let groupMemberDebug:[String] = groupDebug.groupMemberNames
            
            print("グループ名"+groupNameDebug)
            for j in 0 ..< groupMemberDebug.count {
                let groupMemberDetail = groupMemberDebug[j]
                print(groupMemberDetail)
            }
            */
        }
        * EndForDebug */
        
        //タイトルを変更
        self.title = "グループの作成"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        
        //新規グループ作成時(requestGroupIdが空文字)/グループメンバー追加時(requestGroupIdが任意のGrId)
        if !(requestGroupId==""){
            groupNameLabel.text = GroupInfoManager.sharedInstance.getGroupNamgeAtRequestTaskId(reqTaskId: requestGroupId)
            groupNameLabel.isUserInteractionEnabled = false
            groupNameLabel.textColor = .darkGray
            groupNameLabel.textAlignment = .center
            groupNameLabel.borderStyle = .none
            self.title = "グループにメンバーを追加"
            
            self.setGroupCandidateOfRequestGroup()
        }
        
        self.readUserInfoFromFirestore()
        dispatchGroup.notify(queue: DispatchQueue.main){                        //全てのタスクが完了したらコールされる
            //テーブルビュー再表示
            self.makeGroupTableView.reloadData()
            
            //友達が一人も登録されていないかどうか判定
            self.checkNoFriendAlert()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    //グループメンバー追加時にコールされるグループメンバー格納関数
    func setGroupCandidateOfRequestGroup(){
        //groupCandidateにセット
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            if GroupInfoManager.sharedInstance.groupInfo[i].taskId==requestGroupId{
                groupCandidate = GroupInfoManager.sharedInstance.groupInfo[i]
                break
            }
        }
        
        //テーブルビュー再表示
        makeGroupTableView.reloadData()
    }
    
    /* TableViewCellを読み込む(登録する)関数 */
    func configureTableViewCell(){
        /* nibを作成*/
        let nib = UINib(nibName: "MakeGroupTableViewCell", bundle: nil)
        
        /* ID */
        let cellID = "MakeGroupTableView"
        
        /* 登録 */
        makeGroupTableView.register(nib, forCellReuseIdentifier: cellID)
    }
    
    /* cellの個数 */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserInfoManager.sharedInstance.getFriendCountAtCurrentUserID()
    }
    
    /* cellの高さ */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    /* cellに表示する内容 */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MakeGroupTableView", for: indexPath)as!MakeGroupTableViewCell
        
        /* タップした時にハイライトを消す */
        cell.selectionStyle = .none
        
        /* タップ検知のためisUserInteractionEnabledをtrueに */
        cell.checkImage.isUserInteractionEnabled = true
        
        /* タップ時処理で使用するためrowをtagに持たせておく */
        cell.checkImage.tag = indexPath.row
        
        /* タップ時イベント設定 */
        cell.checkImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(checkBoxIconViewTapped)))
        
        /* Viewの候補者の名前を表示 */
        let friendId = UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().friendIds[indexPath.row]
        let friendName = UserInfoManager.sharedInstance.getNameAtRequestUserID(reqUserId:friendId)
        if friendName==""{
            cell.memberCandidateName.text = "名前未登録"
        }else{
            cell.memberCandidateName.text = UserInfoManager.sharedInstance.getNameAtRequestUserID(reqUserId:friendId)
        }
        
        /* Viewの候補者の画像を表示*/
        cell.memberCandidateImage.layer.cornerRadius = 25.0
        let userRef = self.getRequestUserRef(userId:friendId)                           //候補者のユーザーIDのリファレンスを取得
        downloadFromCloudStorage(userRef:userRef, cellImage: cell.memberCandidateImage) //候補者の画像を表示
        
        /* グループメンバーの候補者だけ文字を青色にする */
        cell.memberCandidateName.textColor = .darkGray
        cell.checkImage.image = UIImage(named: "NoCheckBox")
        for i in 0 ..< groupCandidate.GroupMemberNamesInfo.count {
            if groupCandidate.GroupMemberNamesInfo[i].groupMemberNames==UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().friendIds[indexPath.row]{
                cell.memberCandidateName.textColor = .systemTeal
                cell.checkImage.image = UIImage(named: "CheckBox")
            }
        }
        
        return cell
    }
    
    /* チェックボックスアイコンがクリックされた時にCallされる関数 */
    @objc func checkBoxIconViewTapped(sender:UITapGestureRecognizer){
        guard let inputRow=sender.view?.tag else {return}
        
        let appendUserInfo:GroupMemberNamesInfo = GroupMemberNamesInfo.init(groupMemberNames: "", status: false, statusMessage: "", alwaysPushEnable: false)
        
        if groupCandidate.GroupMemberNamesInfo.count==0{
            appendUserInfo.groupMemberNames = UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().friendIds[inputRow]
            groupCandidate.GroupMemberNamesInfo.append(appendUserInfo)
        }else{
            for i in 0 ..< groupCandidate.GroupMemberNamesInfo.count {
                if UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().friendIds[inputRow]==groupCandidate.GroupMemberNamesInfo[i].groupMemberNames{      // 既にリストにある場合
                    groupCandidate.GroupMemberNamesInfo.remove(at: i)
                    break
                }else if i==groupCandidate.GroupMemberNamesInfo.count-1{                        // リストの最後までなかった場合
                    appendUserInfo.groupMemberNames = UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().friendIds[inputRow]
                    groupCandidate.GroupMemberNamesInfo.append(appendUserInfo)
                }
            }
        }
        
        //再描画
        makeGroupTableView.reloadData()
    }
    
    //CloudStorageからダウンロードしてくる関数
    func downloadFromCloudStorage(userRef:StorageReference, cellImage:UIImageView){
        //placeholderの役割を果たす画像をセット
        let placeholderImage = UIImage(systemName: "photo")
        
        //読み込み
        cellImage.sd_setImage(with: userRef, placeholderImage: placeholderImage)
    }
    
    //Firestoreからのデータ(ユーザ情報)の読み込み
    func readUserInfoFromFirestore(){
        //同期処理開始
        dispatchGroup.enter()
        
        //print("UserSyncStart")
        
        dispatchQueue.async(group: dispatchGroup){
            self.db.collection("Users").order(by: "createdAt", descending: true).getDocuments { (querySnapShot, err) in
                if let err = err{
                    print("エラー:\(err)")
                    self.showAlert(title: "読み込みに失敗しました", message: "アプリを立ち上げ直してください")
                }else{
                    /* ForDebug
                     var i:Int = 0
                     * ForDebugEnd */
                    
                    //取得したDocument群の1つ1つのDocumentについて処理をする
                    for document in querySnapShot!.documents{
                        //各DocumentからはDocumentIDとその中身のdataを取得できる
                        print("\(document.documentID) => \(document.data())")
                        //型をUserInfo型に変換
                        do {
                            let decodedTask = try Firestore.Decoder().decode(UserInfo.self, from: document.data())
                            //変換に成功
                            UserInfoManager.sharedInstance.appendUserLists(userInfo: decodedTask)
                            
                        } catch let error as NSError{
                            print("エラー:\(error)")
                            self.showAlert(title: "読み込みに失敗しました", message: "アプリを立ち上げ直してください")
                        }
                    }
                    
                    //print("UserSyncEnd")
                    
                    //同期処理終了
                    self.dispatchGroup.leave()
                }
            }
        }
    }
    
    //友達が一人も登録されていないかどうか判定関数
    func checkNoFriendAlert(){
        if UserInfoManager.sharedInstance.getGroupIdsCountAtCurrentUserID()==0{
            let title = "ともだちが未登録です"
            let message = "\nホーム画面から\n友達を追加してみましょう！"
            
            self.showAlert( title:title, message:message )
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
    
    /* textに答えを入力した時にキーボードを消す(textFieldのprotocolに用意されているメソッド) */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    /* タッチした時にキーボードを消す(UIViewControllerに用意されているメソッド) */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    //Firestoreに保存する関数
    func saveGroupToFirestore(groupName:String){
        
        //新規グループ作成時(requestGroupIdが空文字)/グループメンバー追加時(requestGroupIdが任意のGrId)
        if requestGroupId==""{
            //新しくタスクIDを取得
            let taskId = db.collection("Groups").document().documentID
            
            groupCandidate.taskId = taskId              //taskID格納
            groupCandidate.createdAt = Timestamp()      //作成日格納
            groupCandidate.groupName = groupName        //名前格納
            //自分を格納
            let appendUserInfo:GroupMemberNamesInfo = GroupMemberNamesInfo.init(groupMemberNames: "", status: false, statusMessage: "", alwaysPushEnable: false)
            appendUserInfo.groupMemberNames = UserInfoManager.sharedInstance.getCurrentUserID()
            groupCandidate.GroupMemberNamesInfo.append(appendUserInfo)
        }
        groupCandidate.updatedAt = Timestamp()            //更新日格納
        
        //Firestore(GroupInfo)に保存
        do{
            //Firestoreに保存出来るように変換する
            let encodeGroupInfo:[String:Any] = try Firestore.Encoder().encode(groupCandidate)
            
            //Firestore保存
            db.collection("Groups").document(groupCandidate.taskId).setData(encodeGroupInfo)
            
            //グループを追加
            GroupInfoManager.sharedInstance.appendGroupInfo(groupInfo: groupCandidate)
            
            //グループメンバーに招待メッセージをPush
            self.sendInviteMessageToOtherUser()
            
            //HOME画面に遷移
            navigationController?.popViewController(animated: true)
            
        }catch let error as NSError{
            print("エラー\(error)")
            self.showAlert(title:"エラー", message: "データの読み込みに失敗しました")
        }
    }
    
    //グループメンバーに招待メッセージをPushする関数
    func sendInviteMessageToOtherUser(){
        for i in 0 ..< groupCandidate.GroupMemberNamesInfo.count {
            if groupCandidate.GroupMemberNamesInfo[i].groupMemberNames == UserInfoManager.sharedInstance.getCurrentUserID(){
                /* NoAction(自分には通知しない) */
            }else{
                var userToken:String = ""
                userToken = UserInfoManager.sharedInstance.getTokenAtRequestUserID(reqUserId:groupCandidate.GroupMemberNamesInfo[i].groupMemberNames)
                
                /* ForDebug *
                print("userToken:")
                print(userToken)
                * EndForDebug */
                //sendMessage(userIdToken:userToken)
                SendMessage.sendMessageToUser(userIdToken: userToken,
                                              title: "招待されました",
                                              body: "グループ「"+groupCandidate.groupName+"」に参加しましょう")
            }
        }
    }
    
    //グループ作成ボタン
    @IBAction func makeGroupBtn(_ sender: Any) {
        guard let groupName=groupNameLabel.text else{ return }
        
        if groupName.isEmpty{
            self.showAlert(title:"エラー", message: "グループ名を入力してください")
        }else if groupCandidate.GroupMemberNamesInfo.count==0{
            self.showAlert(title:"エラー", message: "メンバーを選んでください")
        }else{
            //グループをFirebaseに保存
            self.saveGroupToFirestore(groupName:groupName)
        }
        
        /* ForDebug *
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            let groupDebug:GroupInfo = GroupInfoManager.sharedInstance.getGroupInfo(num: i)
            let groupNameDebug:String = groupDebug.groupName
            let groupMemberDebug:[String] = groupDebug.groupMemberNames
            
            print("グループ名"+groupNameDebug)
            for j in 0 ..< groupMemberDebug.count {
                let groupMemberDetail = groupMemberDebug[j]
                print(groupMemberDetail)
            }
        }
        * EndForDebug */
    }
}
