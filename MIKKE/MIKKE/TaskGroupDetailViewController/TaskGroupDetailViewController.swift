//
//  TaskGroupDetailViewController.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/26.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseUI
import SwiftDate

class TaskGroupDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupInfoDelegate, UITextViewDelegate {
    
    @IBOutlet weak var taskGroupDetailTableView: UITableView!
    @IBOutlet weak var inputTextField: UITextView!
    @IBOutlet weak var commitBtnSymbol: UIButton!
    let db = Firestore.firestore()
    var listner:ListenerRegistration? = nil
    
    var tappedIndexPathRow:Int = 0                  // 選択したテーブルビューの番号
    let notification = NotificationCenter.default   // KeyboardAction取得用変数(後々の勉強の為)
    var isActiveKeyboard:Bool = false               // keyboard表示状態管理変数(後々の勉強の為)
    var keyboardHeight:CGFloat = 0                  // ketboardの高さ(後々の勉強の為)
    var cellSum:CGFloat = 0                         // cellの高さの合計(後々の勉強の為)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        taskGroupDetailTableView.delegate = self
        taskGroupDetailTableView.dataSource = self
        GroupInfoManager.sharedInstance.delegate = self
        inputTextField.delegate = self
        configureTableViewCell()
        setupNavigationBar()
        
        // Do any additional setup after loading the view.
        
        //タイトル設定
        if GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupName=="friend"{
            self.title = getFriendNameOfFriendGroup(groupNumber:getCurrentGroupNumberFromTappedGroup())
        }else{
            self.title = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupName
        }
        
        //背景画像設定
        cofigureBackgroundImage()
        
        //キーボード表示時アクション関数登録(後々の勉強の為)
        notification.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        
        //キーボード消灯時アクション関数登録(後々の勉強の為)
        notification.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        
        //フォアグラウンド遷移時アクション関数登録
        notification.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        //バックグラウンド遷移時アクション関数登録
        notification.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        //インプットのテキストビューを可変にする("Scrolling Enable"のチェックを外すこと!)
        inputTextField.autoresizingMask = .flexibleHeight
        
        //テーブルのリロード完了後に下から表示
        taskGroupDetailTableView.performBatchUpdates({
            self.taskGroupDetailTableView.reloadData()
        }) { (finished) in
            self.dispTableViewFromBottom()
            //self.observeRealTimeFirestore()      //Firestoreを監視
            //print("reload完了しました🙂")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = true
        self.deActivateCommitBtn()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
        self.activateCommitBtn()
        self.listner?.remove()
    }
    
    /* テーブルview表示後にコールされる関数 */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.observeRealTimeFirestore()      //Firestoreを監視
    }
    
    // navigation barの設定
    private func setupNavigationBar() {
        //画面上部のナビゲーションバーの左側にTalkボタンを設置し、押されたらログアウト関数がcallされるようにする
        //let leftButtonItem = UIBarButtonItem(title: "Talk", style: .done, target: self, action: #selector(talkView))
        //navigationItem.leftBarButtonItem = leftButtonItem
    }
    
    // Talkボタンをタップしたときの動作
    @objc func talkView() {
        let vc = TaskGroupViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // キーボードが登場する通知を受けた時に実行されるメソッド
    @objc func keyboardWillShow(_ notification: Notification) {
        /* 後々の勉強のために残しておく
        print("keyboardWillShow")
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame: NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeightValue = keyboardRectangle.height
        let cellSumHeight = taskGroupDetailTableView.contentSize.height
        let viewHeight = self.view.frame.size.height
        
        keyboardHeight = keyboardHeightValue
        isActiveKeyboard = true
        
        if cellSumHeight+keyboardHeight<viewHeight{
            self.taskGroupDetailTableView.contentOffset.y = -keyboardHeight
        }
        //dispTableViewFromBottom()
        */
    }
    
    // キーボードが退場した通知を受けた時に実行されるメソッド
    @objc func keyboardDidHide(_ notification: Notification) {
        /* 後々の勉強のために残しておく
        print("keyboardDidHide")
        
        keyboardHeight = 0
        isActiveKeyboard = false
        
        self.taskGroupDetailTableView.contentOffset.y = 0
        //dispTableViewFromBottom()
        */
    }
    
    // フォアグラウンド遷移時に実行されるメソッド
    @objc func appMovedToForeground() {
        //print("フォアグランド")
    }
    
    // バックグラウンド遷移時に実行されるメソッド
    @objc func appMovedToBackground() {
        //print("バックグランド")
        self.view.endEditing(true)
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
    
    // 送信ボタン有効化関数
    func activateCommitBtn(){
        commitBtnSymbol.isUserInteractionEnabled = true
        commitBtnSymbol.tintColor = .systemBlue
    }
    
    // 送信ボタン無効化関数
    func deActivateCommitBtn(){
        commitBtnSymbol.isUserInteractionEnabled = false
        commitBtnSymbol.tintColor = .gray
    }
    
    //textViewに文字が入力されるたびにコールされる関数
    func textViewDidChange(_ textView: UITextView) {
        guard let text=textView.text else {return}
        
        if text==""{
            self.deActivateCommitBtn()
        }else{
            self.activateCommitBtn()
        }
    }
    
    // タップされたindexPathから現在のユーザーIDのグループ番号を取得する関数
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
    
    /* 背景画像設定 */
    func cofigureBackgroundImage(){
        //スクリーンサイズ
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        
        let image = UIImage(named: "SunnySky")
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.taskGroupDetailTableView.frame.width, height: self.taskGroupDetailTableView.frame.height))
        
        //ぼかし設定
        let blurEffect = UIBlurEffect(style: .light)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        
        //倍率設定
        let scale = height / self.taskGroupDetailTableView.frame.height
        let scaleWidth = width / self.taskGroupDetailTableView.frame.width
        
        visualEffectView.frame = CGRect(x: 0, y: 0, width: self.taskGroupDetailTableView.frame.width * scaleWidth, height: self.taskGroupDetailTableView.frame.height * scale)
        visualEffectView.center = CGPoint(x: (width / 2), y: (height / 2))
        
        //visualEffectView.frame = self.taskGroupDetailTableView.frame
        //visualEffectView.frame = CGRect(x: 0, y: 0, width: self.taskGroupDetailTableView.frame.width, height: self.taskGroupDetailTableView.frame.height)
        //visualEffectView.frame = self.view.frame
        //visualEffectView.frame = imageView.bounds
        //visualEffectView.frame = self.taskGroupDetailTableView.frame
        //visualEffectView.frame = self.taskGroupDetailTableView.bounds
        //visualEffectView.frame = CGRect(x: 0, y: 0, width: self.taskGroupDetailTableView.bounds.width, height: self.taskGroupDetailTableView.bounds.height)
        
        //背景画像をセット
        imageView.image = image
        imageView.addSubview(visualEffectView)
        taskGroupDetailTableView.backgroundView = imageView
    }
    
    /* TableViewCellを読み込む(登録する)関数 */
    func configureTableViewCell(){
        /* nibを作成*/
        let nib = UINib(nibName: "TaskGroupDetailTableViewCell", bundle: nil)
        
        
        /* ID */
        let cellID = "GroupDetailTableViewCell"
        
        /* 登録 */
        taskGroupDetailTableView.register(nib, forCellReuseIdentifier: cellID)
    }
    
    /* cellの個数 */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo.count
    }
    
    /* cellの高さ */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        taskGroupDetailTableView.estimatedRowHeight = 20    //最低限のセルの高さ設定
        return UITableView.automaticDimension               //セルの高さを可変にする
    }
    
    /* cellに表示する内容 */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupDetailTableViewCell", for: indexPath)as!TaskGroupDetailTableViewCell
        
        /* 最初が空配列の場合、keyboard調整なので何も表示しないようにする */
        if GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo[indexPath.row].groupMemberTalks==""{
            cell.groupDetailTextView.text = ""
            cell.groupDetailTextView.backgroundColor = .clear
            cell.GroupDetailImageView.image = nil
            cell.dateLabel.text = ""
            cell.postName.text = ""
        }else{
            cell.groupDetailTextView.textColor = .black
            cell.groupDetailTextView.backgroundColor = .white
            cell.groupDetailTextView.text = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo[indexPath.row].groupMemberTalks
            cell.groupDetailTextView.font = .monospacedSystemFont(ofSize: 16, weight: .thin)
            //cell.GroupDetailImageView.image = UIImage(named: "SpongeBob")
            let userId = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo[indexPath.row].groupMemberNames
            let userRef = self.getRequestUserRef(userId:userId)                             //会話メンバーIDのリファレンスを取得
            downloadFromCloudStorage(userRef:userRef, cellImage: cell.GroupDetailImageView) //会話メンバーの画像を表示
            
            let date:Date = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo[indexPath.row].groupMemberTalksCreatedAt.dateValue()
            cell.dateLabel.text = date.convertTo(region: Region.local).toFormat("yyyy-MM-dd HH:mm:ss")
            cell.dateLabel.textColor = .white
            
            let postNameId = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo[indexPath.row].groupMemberNames
            let postName = UserInfoManager.sharedInstance.getNameAtRequestUserID(reqUserId: postNameId)
            cell.postName.text = postName
            cell.postName.textColor = .white
        }
        
        return cell
    }
    
    //CloudStorageからダウンロードしてくる関数
    func downloadFromCloudStorage(userRef:StorageReference, cellImage:UIImageView){
        //placeholderの役割を果たす画像をセット
        //let placeholderImage = UIImage(systemName: "photo")
        
        //読み込み
        cellImage.sd_setImage(with: userRef, placeholderImage: nil)
    }
    
    /* テーブルビューを一番後ろから表示させる関数 */
    func dispTableViewFromBottom(){
        let count:Int = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo.count
        
        if count==0{    //何も入っていなければ(最初の会話の時)
            return
        }else{          //何か入っていたら(会話が開始していれば)
            taskGroupDetailTableView.scrollToRow(at: IndexPath(row: count-1, section: 0), at: .bottom, animated: false)
        }
        
        /* 後々の勉強のために残しておく
        let count:Int = GroupInfoManager.sharedInstance.getGroupInfo(num: groupNumber).groupMemberTalksInfo.count
        let cellSumHeight = taskGroupDetailTableView.contentSize.height
        let viewHeight = self.view.frame.size.height
        
        print("セルの高さ：")
        print(cellSumHeight)
        print("viewの高さ：")
        print(viewHeight)
        print("Keyboardの高さ：")
        print(keyboardHeight)
        
        if count==0{
            return
        }else{
            if isActiveKeyboard==true{
                if cellSumHeight+keyboardHeight>viewHeight{
                    self.taskGroupDetailTableView.contentOffset.y = 0
                    taskGroupDetailTableView.scrollToRow(at: IndexPath(row: count-1, section: 0), at: .bottom, animated: true)
                }/*else if cellSumHeight<=keyboardHeight
                    &&       count==1{
                    self.taskGroupDetailTableView.contentOffset.y = -keyboardHeight
                }*/
                else{
                    self.taskGroupDetailTableView.contentOffset.y = -keyboardHeight
                }
            }else{
                taskGroupDetailTableView.scrollToRow(at: IndexPath(row: count-1, section: 0), at: .bottom, animated: true)
            }
        }
        */
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
                        let decodedTask = try Firestore.Decoder().decode(GroupMemberTalksInfo.self, from: document.data())
                        
                        /* ForDebug *
                        print("Talk!!:")
                        print(decodedTask.groupId)
                        print(decodedTask.groupMemberTalks)
                        * ForDebugEnd */
                        
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
                
                /* ForDebug *
                print("Grの数:")
                print(GroupInfoManager.sharedInstance.getGroupInfoCount())
                
                for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
                    print("Grの会話の数:")
                    print(GroupInfoManager.sharedInstance.groupInfo[i].groupMemberTalksInfo.count)
                    
                    for k in 0 ..< GroupInfoManager.sharedInstance.groupInfo[i].groupMemberTalksInfo.count {
                        print("TalkGr:")
                        print(GroupInfoManager.sharedInstance.groupInfo[i].groupMemberTalksInfo[k].groupMemberTalks)
                    }
                }
                * ForDebugEnd */
                
                self.taskGroupDetailTableView.reloadData()                    //再描画
                self.dispTableViewFromBottom()                                // tableViewを後ろから表示
            }
        }
    }
    
    //Firestoreでリアルタイム監視
    func observeRealTimeFirestore(){
        //監視(会話に変更があったのかを監視する)
        self.listner = db.collection("Groups").document(GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).taskId).addSnapshotListener{ DocumentSnapshot, error in
        //db.collection("Groups").where("state", "==", "CA").document(GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).taskId).addSnapshotListener{ DocumentSnapshot, error in
            /* ForDebug *
            guard let document = DocumentSnapshot else{ return }
            guard let data = document.data() else{ return }
            print("Current data: \(data)")
            * EndForDebug */
            
            /* ForDebug *
            let source = (DocumentSnapshot?.metadata.hasPendingWrites)! ? "Local" : "Server"
            print("addSnapData:")
            print(source)
            * EndForDebug */
            
            self.db.collection("Groups").order(by: "createdAt", descending: true).getDocuments { (querySnapShot, err) in
                let source = (DocumentSnapshot?.metadata.hasPendingWrites)! ? "Local" : "Server"
                
                if source=="Local"{
                    self.taskGroupDetailTableView.reloadData()                    //再描画
                    self.dispTableViewFromBottom()                                // tableViewを後ろから表示
                }else{
                    //配列を全削除
                    GroupInfoManager.sharedInstance.groupInfo.removeAll()
                    
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
                                let decodedTask = try Firestore.Decoder().decode(GroupInfo.self, from: document.data())
                                //変換に成功
                                GroupInfoManager.sharedInstance.appendGroupInfo(groupInfo: decodedTask)
                                //GroupInfoManager.sharedInstance.groupInfo.insert(decodedTask, at: self.groupNumber)
                                
                            } catch let error as NSError{
                                print("エラー:\(error)")
                            }
                        }
                        
                        //トーク情報の読み込み
                        self.readTalksInfoFromFireStore()
                    }
                }
            }
        }
    }
    
    //Firestoreに保存する関数
    func saveGroupOfTalksToFirestore(){
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
        
        //Firestoreに保存2
        do{
            let lastNum = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo.count-1
            
            //GroupのトークIDを取得
            let talkId = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo[lastNum].talkId
            
            //Firestoreに保存出来るように変換する
            let encodeGroupInfoTalks:[String:Any] = try Firestore.Encoder().encode(GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo[lastNum])
            
            //保存
            //db.collection("Groups").document(taskId).collection("Talks").document(talkId).setData(encodeGroupInfoTalks)
            db.collection("Talks").document(talkId).setData(encodeGroupInfoTalks)
            
        }catch let error as NSError{
            print("エラー\(error)")
        }
    }
    
    /* メッセージ送信ボタン */
    @IBAction func commitBtn(_ sender: Any) {
        guard let message=inputTextField.text else{ return }
        
        //GroupのタスクIDを取得
        let taskId = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).taskId
        
        //TalkのタスクIDを取得
        let talkId = db.collection("Talks").document().documentID
        
        let newMessageInfo:GroupMemberTalksInfo = GroupMemberTalksInfo.init(groupMemberNames: UserInfoManager.sharedInstance.getCurrentUserID(), groupMemberTalks: message, groupMemberTalksCreatedAt: Timestamp(), groupId: taskId, talkId: talkId)
        
        var userStatus:Bool = false
        var userAlwaysPushEnable:Bool = false
        
        /* 最初に空配列を入れてKeyboardが押し上げた時に隠れないようにする */
        if GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).groupMemberTalksInfo.count==0{
            let initMessageInfo:GroupMemberTalksInfo = GroupMemberTalksInfo.init(groupMemberNames: UserInfoManager.sharedInstance.getCurrentUserID(), groupMemberTalks: "", groupMemberTalksCreatedAt: Timestamp(), groupId: taskId, talkId:talkId)
            for _ in 0 ..< 6 {
                GroupInfoManager.sharedInstance.appendGroupInfoTalksInfo(num: getCurrentGroupNumberFromTappedGroup(), messageInfo: initMessageInfo)
            }
        }
        
        GroupInfoManager.sharedInstance.appendGroupInfoTalksInfo(num: getCurrentGroupNumberFromTappedGroup(), messageInfo: newMessageInfo)     //配列に追加
        
        saveGroupOfTalksToFirestore()                           //Firebaseに追加
        //observeRealTimeFirestore()                            //Firestoreを監視(View表示の最初に一回)
        inputTextField.text = ""                                //空文字
        deActivateCommitBtn()                                   //アイコンを隠す(空文字にしたから)
        
        /* 送信相手のステータスがFreeだったら、Push通知 */
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo.count {
            
            userStatus = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[i].status
            userAlwaysPushEnable = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[i].alwaysPushEnable
            
            if GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).GroupMemberNamesInfo[i].groupMemberNames == UserInfoManager.sharedInstance.getCurrentUserID(){
                /* NoAction(自分には通知しない) */
            }else if userStatus == false
            &&       userAlwaysPushEnable == false{
                /* NoAction(ステータスがBusy && 必ず通知する設定ではない人には通知しない) */
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
                                              body: message)
            }
        }
        
        //削除してしまったユーザーの為にpush通知する処理を後で追加:2020.7.18
    }
    
    /*
    /* textに答えを入力した時にキーボードを消す(textViewのprotocolに用意されているメソッド) */
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return textView.resignFirstResponder()
    }
    
    /* タッチした時にキーボードを消す(UIViewControllerに用意されているメソッド) */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    /* タッチした時にキーボードを消す */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
    }
    */
}
