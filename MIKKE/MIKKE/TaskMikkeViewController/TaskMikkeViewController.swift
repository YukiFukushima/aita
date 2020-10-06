//
//  TaskMikkeViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/08/07.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import RAMPaperSwitch

class TaskMikkeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupInfoDelegate, UserInfoDelegate {
    
    @IBOutlet weak var taskMikkeTableView: UITableView!
    @IBOutlet weak var currentUserStatus: UILabel!
    @IBOutlet weak var currentUserName: UILabel!
    @IBOutlet weak var currentUserImageView: UIImageView!
    @IBOutlet weak var currentUserDetailStatus: UILabel!
    @IBOutlet weak var mikkeBtnLabel: UIButton!
    
    let db = Firestore.firestore()
    var listner:ListenerRegistration? = nil
    
    var tappedIndexPathRow:Int = 0                  // 選択したテーブルビューの番号
    @IBOutlet weak var paperSwitch: RAMPaperSwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        taskMikkeTableView.delegate = self
        taskMikkeTableView.dataSource = self
        GroupInfoManager.sharedInstance.delegate = self
        UserInfoManager.sharedInstance.delegate = self
        configureTableViewCell()
        
        //ユーザー画像の角丸設定
        currentUserImageView.layer.cornerRadius = 25.0
        
        //Barのセットアップ
        self.setupNavigationBar()
        
        //タイトルを表示
        if GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupName=="friend"{
            self.title = getFriendNameOfFriendGroup(groupNumber:getCurrentGroupNumberFromTappedGroup())+"のステータス"
        }else{
            self.title = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupName+"のステータス"
        }
        
        //Swich操作した時のアクション関数
        self.paperSwitch.animationDidStartClosure = {(onAnimation: Bool) in
            UIView.transition(with: self.currentUserStatus, duration: self.paperSwitch.duration, options: UIView.AnimationOptions.transitionCrossDissolve, animations: {
                self.currentUserStatus.textColor = onAnimation ? UIColor.white : UIColor.black
            },
                                      completion:nil)
        }
    }
    
    //本画面表示時にコールされる関数
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //カレントユーザーの表示更新
        self.viewNameImage(reqUSerId:UserInfoManager.sharedInstance.getCurrentUserID(), currentUserImageView: currentUserImageView)
        self.viewName(userName:UserInfoManager.sharedInstance.getNameAtCurrentUserID(), userNameLabel:currentUserName, isCurrentUser:true)
        self.dispUserStatus(status: self.getCurrentUserStatusInCurrentGroup(), currentUserStatusLabel:currentUserStatus, isCurrentUser:true)
        
        self.dispUserDetailStatus(message: getCurrentUserDetailStatusInCurrentGroup(), currentUserDetailStatusLabel: currentUserDetailStatus, isCurrentUser: true)
        
        self.currentUserDetailStatus.textAlignment = .center
        
        //UISwitchの表示更新
        if self.getCurrentUserStatusInCurrentGroup()==true{
            paperSwitch.isOn = true
        }
        
        //ブロック状態の判定関数
        if GroupInfoManager.sharedInstance.getCurrentUserEnableBlockSettignInCurrentGroup(groupNo: getCurrentGroupNumberFromTappedGroup())==true{
            mikkeBtnLabel.setTitle("ブロック中", for: .normal)
            mikkeBtnLabel.isUserInteractionEnabled = false
            mikkeBtnLabel.layer.borderColor = UIColor.darkGray.cgColor
            mikkeBtnLabel.backgroundColor = .lightGray
        }else{
            mikkeBtnLabel.setTitle("aita!", for: .normal)
            mikkeBtnLabel.isUserInteractionEnabled = true
            mikkeBtnLabel.layer.borderColor = UIColor.systemTeal.cgColor
            mikkeBtnLabel.backgroundColor = .clear
        }
        
        //タブを隠す
        self.tabBarController?.tabBar.isHidden = true
    }
    
    /* テーブルview表示後にコールされる関数 */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        readUserInfoFromFirestore()                         //User情報読み込み
        observeRealTimeFirestore()                          //Firestoreを監視
    }
    
    //本画面消去時にコールされる関数
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
        self.listner?.remove()
    }
    
    // navigation barの設定
    private func setupNavigationBar() {
        //画面上部のナビゲーションバーの右側に+ボタンを配置
        //let rightButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showDetailStatusView))
        let rightButtonItem = UIBarButtonItem(title: "設定", style: .plain, target: self, action: #selector(showDetailStatusView))
        navigationItem.rightBarButtonItem = rightButtonItem
    }
    
    // +ボタンをタップしたときの動作
    @objc func showDetailStatusView() {
        let vc = TaskMikkeDetailStatusViewController()
        vc.currentGroupNo = getCurrentGroupNumberFromTappedGroup()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //友達登録したときに出来る2人グループの時の相手の名前を取得する関数
    func getFriendNameOfFriendGroup(groupNumber:Int)->String{
        var resultFriendName:String = ""
        
        //2人だけなので自分以外の名前を出す
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo.count {
            if UserInfoManager.sharedInstance.getCurrentUserID()==GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[i].groupMemberNames{
                //自分なのでNoAction
            }else{
                let friendNameId = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[i].groupMemberNames
                resultFriendName = UserInfoManager.sharedInstance.getNameAtRequestUserID(reqUserId: friendNameId)
            }
        }
        
        return resultFriendName
    }
    
    /* TableViewCellを読み込む(登録する)関数 */
    func configureTableViewCell(){
        /* nibを作成*/
        let nib = UINib(nibName: "TaskMikkeTableViewCell", bundle: nil)
        
        
        /* ID */
        let cellID = "TaskMikkeTableViewCell"
        
        /* 登録 */
        taskMikkeTableView.register(nib, forCellReuseIdentifier: cellID)
    }
    
    /* cellの高さ */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let userId = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[indexPath.row].groupMemberNames
        
        if userId==UserInfoManager.sharedInstance.getCurrentUserID(){
            return 0
        }else{
            return 200
        }
    }
    
    /* cellの個数 */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if GroupInfoManager.sharedInstance.getCurrentUserEnableBlockSettignInCurrentGroup(groupNo: getCurrentGroupNumberFromTappedGroup())==true{
            return 0
        }else{
            return GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo.count
        }
    }
    
    /* cellに表示する内容 */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskMikkeTableViewCell", for: indexPath)as!TaskMikkeTableViewCell
        let userId = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[indexPath.row].groupMemberNames
        let userName = UserInfoManager.sharedInstance.getNameAtRequestUserID(reqUserId: userId)
        let userStatus = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[indexPath.row].status
        let userDetailStatus = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[indexPath.row].statusMessage
        
        //ハイライト効果を削除(タッチした時にグレーにするのをやめる)
        cell.selectionStyle = .none
        
        //名前の表示
        viewName(userName:userName, userNameLabel:cell.userNameLabel, isCurrentUser:false)
        
        //画像の表示
        viewNameImage(reqUSerId:userId, currentUserImageView: cell.userImageView)
        cell.userImageView.layer.cornerRadius = 50.0
        
        //ステータスの表示
        dispUserStatus(status:userStatus, currentUserStatusLabel:cell.userStatusLabel, isCurrentUser:false)
        if userStatus==true{
            cell.backgroundColor = UIColor.systemTeal
        }else{
            cell.backgroundColor = UIColor.clear
        }
        
        //一言メッセージの表示
        cell.userDetailStatusLabel.text = userDetailStatus
        
        return cell
    }
    
    // タップされたindexPathから現在のグループ番号を取得する関数
    func getCurrentGroupNumberFromTappedGroup()->Int{
        let detailedGroupId:String = UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds[tappedIndexPathRow]
        var resultGroupNo:Int = 0
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            if detailedGroupId==GroupInfoManager.sharedInstance.getGroupInfo(num: i).taskId{
                resultGroupNo = i
                break
            }
        }
        
        return resultGroupNo
    }
    
    // このグループ内の現在のユーザーIDのステータスを取得する関数
    func getCurrentUserStatusInCurrentGroup()->Bool{
        var currentGroupNo:Int = 0
        var currentUserStatus:Bool = false
        
        //グループ番号取得
        currentGroupNo = getCurrentGroupNumberFromTappedGroup()
        
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo.count{
            if GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].groupMemberNames==UserInfoManager.sharedInstance.getCurrentUserID(){
                currentUserStatus = GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].status
                break
            }
        }
        
        return currentUserStatus
    }
    
    // このグループ内の現在のユーザーIDのステータスを変更する関数
    func setCurrentUserStatusInCurrentGroup(status:Bool){
        var currentGroupNo:Int = 0
        
        //グループ番号取得
        currentGroupNo = getCurrentGroupNumberFromTappedGroup()
        
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo.count{
            if GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].groupMemberNames==UserInfoManager.sharedInstance.getCurrentUserID(){
                GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].status = status
                break
            }
        }
    }
    
    // このグループ内の現在のユーザーIDの詳細ステータス(一言メッセージ)を取得する関数
    func getCurrentUserDetailStatusInCurrentGroup()->String{
        var currentGroupNo:Int = 0
        var currentUserDetailStatus:String = ""
        
        //グループ番号取得
        currentGroupNo = getCurrentGroupNumberFromTappedGroup()
        
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo.count{
            if GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].groupMemberNames==UserInfoManager.sharedInstance.getCurrentUserID(){
                currentUserDetailStatus = GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].statusMessage
                break
            }
        }
        
        return currentUserDetailStatus
    }
    
    //CloudStorageからダウンロードしてくる関数
    func downloadFromCloudStorage(userRef:StorageReference, currentUserImageView:UIImageView){
        //placeholderの役割を果たす画像をセット
        let placeholderImage = UIImage(systemName: "photo")
        
        //読み込み
        currentUserImageView.sd_setImage(with: userRef, placeholderImage: placeholderImage)
    }
    
    // ユーザーの名前の表示関数
    func viewName(userName:String, userNameLabel:UILabel, isCurrentUser:Bool){
        if userName==""{
            userNameLabel.text = "名前がまだありません"
        }else{
            if isCurrentUser==true{
                userNameLabel.text = userName+"のステータス"
            }else{
                userNameLabel.text = userName
            }
        }
    }
    
    // ユーザー画像の表示関数
    func viewNameImage(reqUSerId:String, currentUserImageView: UIImageView){
        let userRef = self.getRequestUserRef(userId:reqUSerId)
        downloadFromCloudStorage(userRef:userRef, currentUserImageView:currentUserImageView)
    }
    
    // ユーザーステータス表示関数
    func dispUserStatus(status:Bool, currentUserStatusLabel:UILabel, isCurrentUser:Bool){
        if status==true{
            if isCurrentUser==true{
                //currentUserStatusLabel.text = "会話できる"
                currentUserStatusLabel.text = "Free"
            }else{
                //currentUserStatusLabel.text = "大丈夫です"
                currentUserStatusLabel.text = "Free"
            }
            currentUserStatusLabel.textColor = UIColor.white
        }else{
            if isCurrentUser==true{
                //currentUserStatusLabel.text = "会話できない"
                currentUserStatusLabel.text = "Busy"
            }else{
                //currentUserStatusLabel.text = "少々お待ちください"
                currentUserStatusLabel.text = "Busy"
            }
            currentUserStatusLabel.textColor = UIColor.darkGray
        }
    }
    
    // ユーザー詳細ステータス(一言メッセージ)表示関数
    func dispUserDetailStatus(message:String, currentUserDetailStatusLabel:UILabel, isCurrentUser:Bool){
        currentUserDetailStatusLabel.text = message
    }
    
    //Firestoreに保存する関数
    func saveGroupOfStatusToFirestore(){
        //GroupのタスクIDを取得
        let taskId = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).taskId
        
        //更新日を更新
        GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).updatedAt = Timestamp()
        
        //Firestoreに保存1
        do{
            //Firestoreに保存出来るように変換する
            let encodeGroupInfo:[String:Any] = try Firestore.Encoder().encode(GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()))
            
            //保存
            db.collection("Groups").document(taskId).setData(encodeGroupInfo)
            
        }catch let error as NSError{
            print("エラー\(error)")
        }
        
        /* ここで保存したいのはステータスなので会話内容は保存しない
        //Firestoreに保存2
        do{
            let lastNum = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo.count-1
            
            //GroupのトークIDを取得
            let talkId = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo[lastNum].talkId
            
            //Firestoreに保存出来るように変換する
            let encodeGroupInfoTalks:[String:Any] = try Firestore.Encoder().encode(GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo[lastNum])
            
            //保存
            db.collection("Groups").document(taskId).collection("Talks").document(talkId).setData(encodeGroupInfoTalks)
            
        }catch let error as NSError{
            print("エラー\(error)")
        }
        */
    }
    
    //Firestoreからのデータ(ユーザー情報)の読み込み
    func readUserInfoFromFirestore(){
        //Firebaseから読み込み
        self.db.collection("Users").order(by: "taskId", descending: true).getDocuments { (querySnapShot, err) in
            if let err = err{
                print("エラー:\(err)")
            }else{
                //取得したDocument群の1つ1つのDocumentについて処理をする
                for document in querySnapShot!.documents{
                    //各DocumentからはDocumentIDとその中身のdataを取得できる
                    /*print("\(document.documentID) => \(document.data())")*/
                    //型をUserInfo型に変換
                    do {
                        let decodedTask = try Firestore.Decoder().decode(UserInfo.self, from: document.data())
                        //変換に成功
                        UserInfoManager.sharedInstance.appendUserLists(userInfo: decodedTask)
                        
                        //print("SyncUserInfo")
                        
                    } catch let error as NSError{
                        print("エラー:\(error)")
                    }
                }
            
                //再描画
                self.taskMikkeTableView.reloadData()
            }
        }
    }
    
    //Firestoreからのトーク情報の読み込み
    func readTalksInfoFromFireStore(){
        self.db.collection("Talks").order(by: "groupMemberTalksCreatedAt", descending: true).getDocuments { (querySnapShot, err) in
            //トーク情報を初期化
            GroupInfoManager.sharedInstance.initGroupTalkInfo()
            
            //再度読み直して配列に保存
            if let err = err{
                print("エラー:\(err)")
            }else{
                //取得したDocument群の1つ1つのDocumentについて処理をする
                for document in querySnapShot!.documents{
                    //各DocumentからはDocumentIDとその中身のdataを取得できる
                    /*print("\(document.documentID) => \(document.data())")*/
                    //型をUserInfo型に変換([String:Any]型で記録する為、変換が必要)
                    do {
                        //groupNum += 1
                        
                        let decodedTask = try Firestore.Decoder().decode(GroupMemberTalksInfo.self, from: document.data())
                        //変換に成功
                        GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId:decodedTask.groupId).groupMemberTalksInfo.insert(decodedTask, at: 6)
                        
                        //GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId:decodedTask.groupId).groupMemberTalksInfo.insert(decodedTask, at: 6)
                        //GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId:decodedTask.groupId).groupMemberTalksInfo.append(decodedTask)
                        
                        //GroupInfoManager.sharedInstance.getGroupInfo(num: groupNum).groupMemberTalksInfo.append(decodedTask)
                        //GroupInfoManager.sharedInstance.appendGroupInfo(groupInfo: decodedTask)
                        //GroupInfoManager.sharedInstance.groupInfo.insert(decodedTask, at: self.groupNumber)
                    } catch let error as NSError{
                        print("エラー:\(error)")
                    }
                }
                //再描画
                self.taskMikkeTableView.reloadData()
            }
        }
    }
    
    //Firestoreでリアルタイム監視
    func observeRealTimeFirestore(){
        //監視(ステータスに変更があったのかを監視する)
        self.listner = db.collection("Groups").document(GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).taskId).addSnapshotListener{ DocumentSnapshot, error in
            /* ForDebug *
            guard let document = DocumentSnapshot else{ return }
            guard let data = document.data() else{ return }
            print("Current data: \(data)")
            * EndForDebug */
            
            self.db.collection("Groups").order(by: "createdAt", descending: true).getDocuments { (querySnapShot, err) in
                //配列を全削除
                GroupInfoManager.sharedInstance.groupInfo.removeAll()
                
                //再度読み直して配列に保存
                if let err = err{
                    print("エラー:\(err)")
                }else{
                    //取得したDocument群の1つ1つのDocumentについて処理をする
                    for document in querySnapShot!.documents{
                        //各DocumentからはDocumentIDとその中身のdataを取得できる
                        /* print("\(document.documentID) => \(document.data())") */
                        //型をUserInfo型に変換([String:Any]型で記録する為、変換が必要)
                        do {
                            let decodedTask = try Firestore.Decoder().decode(GroupInfo.self, from: document.data())
                            //変換に成功
                            GroupInfoManager.sharedInstance.appendGroupInfo(groupInfo: decodedTask)
                            //GroupInfoManager.sharedInstance.groupInfo.insert(decodedTask, at: self.groupNumber)
                        } catch let error as NSError{
                            print("エラー:\(error)")
                        }
                    }
                    
                    self.readTalksInfoFromFireStore()
                }
            }
        }
    }
    
    //自分以外のユーザーで、ステータスがFreeの人にステータス変更を通知する
    func pushStatusChangeToOtherUser(){
        var userStatus:Bool = false
        var userAlwaysPushEnable:Bool = false
        var enableBlockSetting:Bool = false
        
        /* 送信相手のステータスがFreeだったら、Push通知 */
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo.count {
            userStatus = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[i].status
            userAlwaysPushEnable = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[i].alwaysPushEnable
            enableBlockSetting = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[i].enableBlock
            
            if GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[i].groupMemberNames == UserInfoManager.sharedInstance.getCurrentUserID(){
                /* NoAction(自分には通知しない) */
            }else if userStatus == false
            &&       userAlwaysPushEnable == false{
                /* NoAction(ステータスがBusy && 必ず通知する設定ではない人には通知しない) */
            }else if enableBlockSetting == true{
                /* NoAction(ブロック設定している人には通知しない) */
            }else{
                var userToken:String = ""
                userToken = UserInfoManager.sharedInstance.getTokenAtRequestUserID(reqUserId:GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[i].groupMemberNames)
                
                /* ForDebug *
                print("userToken:")
                print(userToken)
                * EndForDebug */
                
                let sendTile:String = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupName
                
                SendMessage.sendMessageToUser(userIdToken: userToken,
                                              title: sendTile,
                                              body: UserInfoManager.sharedInstance.getNameAtCurrentUserID()+"さんのステータスが変更されました！")
            }
        }
    }
    
    //話せる相手を見つけた時のボタン
    @IBAction func mikkeBtn(_ sender: Any) {
        let vc = TaskGroupDetailViewController()
        vc.tappedIndexPathRow = tappedIndexPathRow
        
        /* やらないほうが良かった処理
        //ステータスをFreeに変更(会話に行くのだからステータスはFreeにするという意図)
        setCurrentUserStatusInCurrentGroup(status: true)
        dispUserStatus(status: self.getCurrentUserStatusInCurrentGroup(), currentUserStatusLabel:currentUserStatus, isCurrentUser:true)
        
        //Firebaseに保存
        saveGroupOfStatusToFirestore()
        */
        
        //画面遷移
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //現在のユーザーのステータスを変えるスイッチ
    @IBAction func currentUserStatusSwitch(_ sender: Any) {
        if (sender as AnyObject).isOn{
            setCurrentUserStatusInCurrentGroup(status: true)
            paperSwitch.backgroundColor = .systemTeal
        }else{
            setCurrentUserStatusInCurrentGroup(status: false)
            paperSwitch.backgroundColor = .systemGray6
        }
        dispUserStatus(status: self.getCurrentUserStatusInCurrentGroup(), currentUserStatusLabel:currentUserStatus, isCurrentUser:true)
        
        //Firebaseに保存
        saveGroupOfStatusToFirestore()
        
        //ステータスの変更をPush通知
        //if getCurrentUserStatusInCurrentGroup()==true{  //Freeになったら通知
            pushStatusChangeToOtherUser()
        //}
    }
}
