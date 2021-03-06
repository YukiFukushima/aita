//
//  TaskGroupViewController.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/23.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseUI

class TaskGroupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupInfoDelegate, UserInfoDelegate {

    @IBOutlet weak var taskGroupTableView: UITableView!
    let db = Firestore.firestore()
    var listner:ListenerRegistration? = nil
    var imageDownloadCounter:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        taskGroupTableView.delegate = self
        taskGroupTableView.dataSource = self
        GroupInfoManager.sharedInstance.delegate = self
        UserInfoManager.sharedInstance.delegate = self
        configureTableViewCell()
        
        // Do any additional setup after loading the view.
        
        //タイトルを表示
        self.title = "ともだち"
    }
    
    /* 再描画 */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.taskGroupTableView.reloadData()    //監視後のロードとダブるけどViewの更新はとにかく早くする
        self.observeRealTimeFirestore()         //Firestoreを監視
        
        if UserGroupUpdateRepository.loadUserGroupUpdateDefaults()==true{           //新しいグループに招待されているなら
            UserGroupUpdateRepository.saveUserGroupUpdateDefaults(goUpdate: false)  //updateフラグを落とす
        }
        
    }
    
    /* テーブルview表示後にコールされる関数 */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //self.observeRealTimeFirestore()    //Firestoreを監視
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.listner?.remove()
    }
    
    //友達が一人も登録されていないかどうか判定関数
    func checkNoFriendAlert(){
        if UserInfoManager.sharedInstance.getGroupIdsCountAtCurrentUserID()==0{
            //UIAlertControllerを関数の引数であるとtitleとmessageを使ってインスタンス化
            let alertVC = UIAlertController(title: "ともだちが未登録です", message: "\nホーム画面から\n友達を追加してみましょう！", preferredStyle: .alert)
            
            //UIAlertActionを追加
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            //表示
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    /* TableViewCellを読み込む(登録する)関数 */
    func configureTableViewCell(){
        
        /* nibを作成*/
        let nib = UINib(nibName: "TaskGroupTableViewCell", bundle: nil)
        
        /* ID */
        let cellID = "GroupTableViewCell"
        
        /* 登録 */
        taskGroupTableView.register(nib, forCellReuseIdentifier: cellID)
    }
    
    /* cellの個数 */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return GroupInfoManager.sharedInstance.getGroupInfoCount()
        return UserInfoManager.sharedInstance.getGroupIdsCountAtCurrentUserID()
    }
    
    /* cellの高さ */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    /* cellに表示する内容 */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupTableViewCell", for: indexPath)as!TaskGroupTableViewCell
        
        /* グループイメージ(角丸調整) */
        cell.groupImageView.layer.cornerRadius = 25.0
        
        /* グループメンバー追加画像タップ時イベント設定 */
        cell.currentUserImage.layer.cornerRadius = 18
        //cell.currentUserImage.isUserInteractionEnabled = true
        //cell.currentUserImage.tag = indexPath.row
        //cell.currentUserImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addGroupMemberImageViewTapped)))
        viewNameImage(reqUSerId:UserInfoManager.sharedInstance.getCurrentUserID(), currentUserImageView: cell.currentUserImage)
        
        /* グループ名を表示+グループイメージを表示 */
        var groupId:String = ""
        let currentUserInfo:UserInfo = UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID()
        groupId = currentUserInfo.groupIds[indexPath.row]
        
        if GroupInfoManager.sharedInstance.getGroupNamgeAtRequestTaskId(reqTaskId: groupId)=="friend"{
            //2人だけなので自分以外の名前を出す
            cell.groupLabel.text = getFriendNameOfFriendGroup(groupId:groupId)
            viewNameImage(reqUSerId:getFriendIdOfFriendGroup(groupId:groupId), currentUserImageView: cell.groupImageView)
        }else{
            cell.groupLabel.text = GroupInfoManager.sharedInstance.getGroupNamgeAtRequestTaskId(reqTaskId: groupId)
            cell.groupImageView.image = UIImage(named: "aita")
        }
        
        //カレントユーザーがブロックしているグループはグレー表示
        if GroupInfoManager.sharedInstance.getCurrentUserEnableBlockSettignInCurrentGroup(groupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: indexPath.row))==true{
            cell.groupLabel.textColor = .darkGray
        }else{
            //Freeのメンバーがいるか判定
            if isExistFreeMember(groupId:groupId)==true{
                cell.groupLabel.textColor = .systemTeal
            }else{
                cell.groupLabel.textColor = .darkGray
            }
        }
        
        //cell上の今のユーザーのステータス表示
        if GroupInfoManager.sharedInstance.getCurrentUserStatusInReqGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: indexPath.row))==true{
            cell.userStatusLabel.text = "free"
            cell.userStatusLabel.textColor = .systemTeal
        }else{
            cell.userStatusLabel.text = "busy"
            cell.userStatusLabel.textColor = .darkGray
        }
        
        /*
        //cellに埋め込んだUISwitch
        let switchView = UISwitch()
        switchView.tag = indexPath.row
        if GroupInfoManager.sharedInstance.getCurrentUserStatusInReqGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: indexPath.row))==true{
            switchView.setOn(true, animated: false)
        }else{
            switchView.setOn(false, animated: false)
        }
        switchView.addTarget(self, action: #selector(hundleSwitch), for: UIControl.Event.valueChanged)
        cell.accessoryView = switchView
        */
        
        return cell
    }
    
    //現在freeの人がいるかいないか判定する関数
    func isExistFreeMember(groupId:String)->Bool{
        var result:Bool = false
        var checkMemberStatus:Bool = false
        let currentUserId:String = UserInfoManager.sharedInstance.getCurrentUserID()
        
        //自分自身のステータスは比較対象から外す
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId: groupId).GroupMemberNamesInfo.count {
            checkMemberStatus = GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId: groupId).GroupMemberNamesInfo[i].status
            if checkMemberStatus == true
            && currentUserId != GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId: groupId).GroupMemberNamesInfo[i].groupMemberNames{
                result = true
                break
            }
        }
        
        return result
    }
    
    //友達登録したときに出来る2人グループの時の相手の名前を取得する関数
    func getFriendIdOfFriendGroup(groupId:String)->String{
        var resultFriendId:String = ""
        
        //2人だけなので自分以外の名前を出す
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId: groupId).GroupMemberNamesInfo.count {
            if UserInfoManager.sharedInstance.getCurrentUserID()==GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId: groupId).GroupMemberNamesInfo[i].groupMemberNames{
                //自分なのでNoAction
            }else{
                resultFriendId = GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId: groupId).GroupMemberNamesInfo[i].groupMemberNames
            }
        }
        
        return resultFriendId
    }
    
    //友達登録したときに出来る2人グループの時の相手の名前を取得する関数
    func getFriendNameOfFriendGroup(groupId:String)->String{
        var resultFriendName:String = ""
        
        //2人だけなので自分以外の名前を出す
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId: groupId).GroupMemberNamesInfo.count {
            if UserInfoManager.sharedInstance.getCurrentUserID()==GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId: groupId).GroupMemberNamesInfo[i].groupMemberNames{
                //自分なのでNoAction
            }else{
                let friendNameId = GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId: groupId).GroupMemberNamesInfo[i].groupMemberNames
                resultFriendName = UserInfoManager.sharedInstance.getNameAtRequestUserID(reqUserId: friendNameId)
            }
        }
        
        return resultFriendName
    }
    
    //自分以外のユーザーで、ステータスがFreeの人にステータス変更を通知する
    func pushStatusChangeToOtherUser(groupNo:Int){
        var userStatus:Bool = false
        var userAlwaysPushEnable:Bool = false
        var enableBlockSetting:Bool = false
        
        /* 送信相手のステータスがFreeだったら、Push通知 */
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: groupNo).GroupMemberNamesInfo.count {
            userStatus = GroupInfoManager.sharedInstance.getGroupInfo(num: groupNo).GroupMemberNamesInfo[i].status
            userAlwaysPushEnable = GroupInfoManager.sharedInstance.getGroupInfo(num: groupNo).GroupMemberNamesInfo[i].alwaysPushEnable
            enableBlockSetting = GroupInfoManager.sharedInstance.getGroupInfo(num: groupNo).GroupMemberNamesInfo[i].enableBlock
            
            if GroupInfoManager.sharedInstance.getGroupInfo(num: groupNo).GroupMemberNamesInfo[i].groupMemberNames == UserInfoManager.sharedInstance.getCurrentUserID(){
                /* NoAction(自分には通知しない) */
            }else if userStatus == false
            &&       userAlwaysPushEnable == false{
                /* NoAction(ステータスがBusy && 必ず通知する設定ではない人には通知しない) */
            }else if enableBlockSetting == true{
                /* NoAction(ブロック設定している人には通知しない) */
            }else{
                var userToken:String = ""
                userToken = UserInfoManager.sharedInstance.getTokenAtRequestUserID(reqUserId:GroupInfoManager.sharedInstance.getGroupInfo(num: groupNo).GroupMemberNamesInfo[i].groupMemberNames)
                
                /* ForDebug *
                print("userToken:")
                print(userToken)
                * EndForDebug */
                
                let sendTile:String = GroupInfoManager.sharedInstance.getGroupInfo(num: groupNo).groupName
                
                SendMessage.sendMessageToUser(userIdToken: userToken,
                                              title: sendTile,
                                              body: UserInfoManager.sharedInstance.getNameAtCurrentUserID()+"さんのステータスが変更されました！")
            }
        }
    }
    
    //GroupInfo内のグループメンバーとUserInfo内の確認済みグループメンバーを照合し、無ければ、新しいGrとして自分が入っているグループ群に加える
    func addMyGroupIdsFromSearchingGrouoInfo(){
        let myUserId = UserInfoManager.sharedInstance.getCurrentUserID()
        var necessarySaveFirestore:Bool = false
        var newGroupIds:[String] = [""]
        
        newGroupIds.removeAll()
        
        //グループ内検索(自分(Id)の入っているグループ(taskId)を見つける)
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            for j in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: i).GroupMemberNamesInfo.count{
                //自分がこのグループに含まれていたら
                if GroupInfoManager.sharedInstance.getGroupInfo(num: i).GroupMemberNamesInfo[j].groupMemberNames==myUserId{
                    //このグループが確認済みか確認
                    var isRegisterd:Bool = false    //未確認
                    if UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().verifyGroupIds.count==0{
                        /* NoAction */
                    }else{
                        for k in 0 ..< UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().verifyGroupIds.count{
                            if UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().verifyGroupIds[k]==GroupInfoManager.sharedInstance.getGroupInfo(num: i).taskId{
                                isRegisterd = true
                                break
                            }
                        }
                    }
                    
                    //未確認なら
                    if isRegisterd==false{
                        let groupId = GroupInfoManager.sharedInstance.getGroupInfo(num: i).taskId
                        
                        //参加Gr(バッファ)に加える
                        //UserInfoManager.sharedInstance.appendGroupIdsAtCurrentUserID(groupId: groupId)
                        newGroupIds.insert(groupId, at: 0)
                        
                        //確認済みGrに加える
                        //UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().verifyGroupIds.append(groupId)
                        necessarySaveFirestore = true
                    }
                    break
                }
            }
        }
        
        //加えるべきGrを加える
        if newGroupIds.count != 0{
            for i in 0 ..< newGroupIds.count {
                UserInfoManager.sharedInstance.appendGroupIdsAtCurrentUserID(groupId: newGroupIds[i])
                UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().verifyGroupIds.append(newGroupIds[i])
            }
        }
        
        //Firestoreに保存するなら
        if necessarySaveFirestore==true{
            saveUserInfoToFirestore()
        }
    }
    
    // ユーザー画像の表示関数
    func viewNameImage(reqUSerId:String, currentUserImageView: UIImageView){
        let userRef = self.getRequestUserRef(userId:reqUSerId)

        downloadFromCloudStorage(userRef:userRef, currentUserImageView:currentUserImageView)
    }
    
    //CloudStorageからダウンロードしてくる関数
    func downloadFromCloudStorage(userRef:StorageReference, currentUserImageView:UIImageView){
        //placeholderの役割を果たす画像をセット
        //let placeholderImage = UIImage(systemName: "photo")
        
        //読み込み
        currentUserImageView.sd_setImage(with: userRef, placeholderImage: nil)
    }
    
    //Firestoreへの保存
    func saveUserInfoToFirestore(){
        do{
            //Firestoreに保存出来るように変換する
            let encodeUserInfo:[String:Any] = try Firestore.Encoder().encode(UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID())
            
            //Firestoreに書き込み
            db.collection("Users").document(UserInfoManager.sharedInstance.getTaskIdAtCurrentUserID()).setData(encodeUserInfo)
            
        }catch let error as NSError{
            print("エラー\(error)")
        }
    }
    
    //Firestoreでリアルタイム監視
    func observeRealTimeFirestore(){
        //監視(ステータスに変更があったのかを監視する)
        //db.collection("Groups").whereField("status", isEqualTo: "true").addSnapshotListener{ querySnapshot, error in
        //db.collection("Groups").document(GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromTappedGroup()).taskId).addSnapshotListener{ DocumentSnapshot, error in
        self.listner = db.collection("Groups").addSnapshotListener{ DocumentSnapshot, error in
            self.db.collection("Groups").order(by: "createdAt", descending: true).getDocuments { (querySnapShot, err) in
                
                let source = (DocumentSnapshot?.metadata.hasPendingWrites)! ? "Local" : "Server"
                
                /* ForDebug *
                print("addSnapData:")
                print(source)
                * EndForDebug */
                
                if source=="Local"{
                    //再描画
                    self.taskGroupTableView.reloadData()
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
                        
                        //Talk情報の読み込み
                        self.readTalksInfoFromFireStore()
                    }
                }
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
                        
                        let decodedTask = try Firestore.Decoder().decode(GroupMemberTalksInfo.self, from: document.data())
                        //変換に成功
                        GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId:decodedTask.groupId).groupMemberTalksInfo.insert(decodedTask, at: 6)
                        //GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId:decodedTask.groupId).groupMemberTalksInfo.append(decodedTask)
                        
                        //GroupInfoManager.sharedInstance.getGroupInfo(num: groupNum).groupMemberTalksInfo.append(decodedTask)
                        //GroupInfoManager.sharedInstance.appendGroupInfo(groupInfo: decodedTask)
                        //GroupInfoManager.sharedInstance.groupInfo.insert(decodedTask, at: self.groupNumber)
                    } catch let error as NSError{
                        print("エラー:\(error)")
                    }
                }
                //自分の入っているグループを検索して、自分の情報(自分が入っているグループ群)に加える
                self.addMyGroupIdsFromSearchingGrouoInfo()
                
                //再描画
                self.taskGroupTableView.reloadData()
                
                //友達が一人も登録されていないかチェック
                self.checkNoFriendAlert()
            }
        }
    }
    
    //Firestoreに保存する関数
    func saveGroupInfoToFirestore(groupNo:Int){
        //GroupのタスクIDを取得
        let taskId = GroupInfoManager.sharedInstance.getGroupInfo(num: groupNo).taskId
        
        //更新日を更新
        GroupInfoManager.sharedInstance.getGroupInfo(num: groupNo).updatedAt = Timestamp()
        
        //Firestoreに保存1
        do{
            //Firestoreに保存出来るように変換する
            let encodeGroupInfo:[String:Any] = try Firestore.Encoder().encode(GroupInfoManager.sharedInstance.getGroupInfo(num: groupNo))
            
            //保存
            db.collection("Groups").document(taskId).setData(encodeGroupInfo)
            
        }catch let error as NSError{
            print("エラー\(error)")
        }
    }
    
    /* Firestoreからの削除関数 */
    func deleteTaskFromFirestore(deleteGropuNum:Int){
        db.collection("Groups").document(GroupInfoManager.sharedInstance.getGroupInfo(num: deleteGropuNum).taskId).delete()
    }
    
    /* スワイプ処理(削除) */
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        var deleteExecute:Bool = false
        var deleteVerifyExecute:Bool = false
        var deleteFriendExecute:Bool = false
        var deleteMyIdNumExecute:Bool = false
        var deleteGroupInfoNum:Int = 0
        var deleteGroupMyIdNum:Int = 0
        var deleteFriendIdNum:Int = 0
        var deleteMyIdNumAtGroup:Int = 0
        var deleteGroupIdNum:Int = 0
        var deleteVerifyExecuteNum:Int = 0
        
        //1.削除するグループ(taskId)を取得
        let deleteTaskId = UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds[indexPath.row]
        
        //1.削除するグループIDが入っている自分のGrIdの配列番号を取得
        for i in 0 ..< UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds.count{
            if UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds[i]==deleteTaskId{
                deleteGroupMyIdNum = i
                deleteExecute = true
            }
        }
        
        //1.配列から削除する必要があるなら
        if deleteExecute==true{
            UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds.remove(at: deleteGroupMyIdNum)
        }
        
        //3.削除するグループの番号を取得
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount(){
            if GroupInfoManager.sharedInstance.getGroupInfo(num: i).taskId==deleteTaskId{
                deleteGroupInfoNum = i
                break
            }
        }
        
        //3.削除するGrIdが友達のGrか否か判定
        if GroupInfoManager.sharedInstance.getGroupInfo(num: deleteGroupInfoNum).groupName=="friend"{
            //自分の友達リストから削除
            var friendNameId:String = ""
            
            //友達のIdを取得
            for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: deleteGroupInfoNum).GroupMemberNamesInfo.count {
                if GroupInfoManager.sharedInstance.getGroupInfo(num: deleteGroupInfoNum).GroupMemberNamesInfo[i].groupMemberNames != UserInfoManager.sharedInstance.getCurrentUserID(){
                    friendNameId = GroupInfoManager.sharedInstance.getGroupInfo(num: deleteGroupInfoNum).GroupMemberNamesInfo[i].groupMemberNames
                    break;
                }
            }
            
            //友達のIdが入っている配列要素を見つける、配列から削除(自分の友達リストから削除)
            for i in 0 ..< UserInfoManager.sharedInstance.getFriendCountAtCurrentUserID(){
                if friendNameId==UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().friendIds[i]{
                    deleteFriendIdNum = i
                    deleteFriendExecute = true
                }
            }
            
            //配列から削除する必要があるなら
            if deleteFriendExecute==true{
                UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().friendIds.remove(at: deleteFriendIdNum)
            }
        }
        //4.削除するGrIdがGrの場合
        else{
            for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount(){
                if GroupInfoManager.sharedInstance.getGroupInfo(num: i).taskId==deleteTaskId{
                    deleteGroupIdNum = i
                    for j in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: i).GroupMemberNamesInfo.count{
                        if UserInfoManager.sharedInstance.getCurrentUserID()==GroupInfoManager.sharedInstance.getGroupInfo(num: i).GroupMemberNamesInfo[j].groupMemberNames{
                            deleteMyIdNumAtGroup = j
                            deleteMyIdNumExecute = true
                            break
                        }
                    }
                    
                    //配列から削除する必要があるなら
                    if deleteMyIdNumExecute==true{
                        GroupInfoManager.sharedInstance.getGroupInfo(num: i).GroupMemberNamesInfo.remove(at: deleteMyIdNumAtGroup)
                    }
                    break
                }
            }
            
            //2.削除するグループIDが入っている自分のVerify(確認済み)Idの配列番号を取得
            for j in 0 ..< UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().verifyGroupIds.count{
                if UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().verifyGroupIds[j]==deleteTaskId{
                    deleteVerifyExecuteNum = j
                    deleteVerifyExecute = true
                }
            }
            
            //2.配列から削除する必要があるなら
            if deleteVerifyExecute==true{
                UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().verifyGroupIds.remove(at: deleteVerifyExecuteNum)
            }
        }
        
        //5.User情報をFirebaseに保存する必要があるなら
        if deleteExecute==true
        || deleteFriendExecute==true
        || deleteVerifyExecute==true{
            saveUserInfoToFirestore()
        }
        
        //6.Group情報をFirebaseに保存する必要があるなら
        if deleteMyIdNumExecute==true{
            saveGroupInfoToFirestore(groupNo:deleteGroupIdNum)
        }
        
        /*
        //グループに所属するメンバーが一人もいなくなったら、グループから削除する。
        //ただ、このままではダメで、groupクラスのメンバーに、グループからいなくなったメンバーの情報(ID)を増やし、所属メンバーといなくなったーメンバーの整合がとれたら、
        //そのグループを削除するようにする(後で処理を追加:2020.7.18)
        self.deleteTaskFromFirestore(deleteGropuNum:deleteGroupInfoNum)             //Firestoreから削除
        GroupInfoManager.sharedInstance.removeGroupInfo(num: deleteGroupInfoNum)    //配列から削除
        */
        
        //再描画
        //restoreDataFromFirestore()
        self.taskGroupTableView.reloadData()
    }
    
    //自分のステータス変更関数
    func actChangeStatus(inputRow:Int){
        if GroupInfoManager.sharedInstance.getCurrentUserStatusInReqGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow))==true{
            GroupInfoManager.sharedInstance.setCurrentUserStatusInCurrentGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow), status: false)
        }else{
            GroupInfoManager.sharedInstance.setCurrentUserStatusInCurrentGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow), status: true)
        }
        
        //FireStoreに保存
        saveGroupInfoToFirestore(groupNo:GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow))
        
        //ステータスの変更をPush通知
        //if GroupInfoManager.sharedInstance.getCurrentUserStatusInReqGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow))==true{  //Freeになったら通知
            pushStatusChangeToOtherUser(groupNo:GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow))
        //}
        
        //再描画(監視している先で再描画)
        //taskGroupTableView.reloadData()
    }
    
    /* 左から右へスワイプしてステータスを変更 */
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let statusChangeAction = UIContextualAction(style: .normal,
                                                    title: "ステータス変更",
                                                    handler: { (action: UIContextualAction, view: UIView, completion: (Bool) -> Void) in
                                                        //print("statusChange")
                                                        
                                                        self.actChangeStatus(inputRow:indexPath.row)
                                                        
                                                        // 処理を実行完了した場合はtrue
                                                        completion(true)
                                                    })
        statusChangeAction.backgroundColor = .systemTeal
        return UISwipeActionsConfiguration(actions: [statusChangeAction])
    }
    
    /* タップ時処理 */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //タップ後cellの色をすーっと変える
        taskGroupTableView.deselectRow(at: indexPath, animated: true)
        
        let vc = TaskMikkeViewController()
        
        vc.tappedIndexPathRow = indexPath.row
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /******************************************************************/
    /* 以下、未使用関数群 */
    /******************************************************************/
    /*
    //Firestoreからのデータ(User情報)の読み込み
    func readUserInfoFromFirestore(){
        db.collection("Users").order(by: "taskId", descending: true).getDocuments { (querySnapShot, err) in
            if let err = err{
                print("エラー:\(err)")
            }else{
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
                    }
                }
                
                //自分の入っているグループを検索して、自分の情報(自分が入っているグループ群)に加える(ForDebug)
                //self.addMyGroupIdsFromSearchingGrouoInfo()
                
                //自分の入っているグループを検索して、どこにもなかったら削除する
                //self.deleteMyGroupIdsFromSearchingGrouoInfo()
                
                //再描画
                self.taskGroupTableView.reloadData()
            }
        }
    }
    
    /* Firestoreからデータを配列に読み込んで再更新(グループを作って戻ってきた時とグループを削除した時のため) */
    func restoreDataFromFirestore(){
        GroupInfoManager.sharedInstance.groupInfo.removeAll()   //配列を全削除
        UserInfoManager.sharedInstance.userLists.removeAll()    //配列を全削除
        readGroupInfoFromFirestore()                            //会話グループ情報の読み込み(この読み込みの後にユーザー情報を読み込む!)
    }
    
    //自分の入っているグループを検索して、見つかったら自分の情報(自分が入っているグループ群)に加える(push通知を受けた時にこの関数をcallするようにする処理を後で追加:2020.7.18)
    func addMyGroupIdsFromSearchingGrouoInfo(){
        let myUserId = UserInfoManager.sharedInstance.getCurrentUserID()
        var searchResultGroupIds:String = ""
        var judegeSaveToFirebase:Bool = false
        
        //グループ内検索(自分(Id)の入っているグループ(taskId)を見つける)
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            //for j in 0 ..< GroupInfoManager.sharedInstance.groupInfo[i].groupMemberNames.count{
            for j in 0 ..< GroupInfoManager.sharedInstance.groupInfo[i].GroupMemberNamesInfo.count{
                //if GroupInfoManager.sharedInstance.groupInfo[i].groupMemberNames[j]==myUserId{
                if GroupInfoManager.sharedInstance.groupInfo[i].GroupMemberNamesInfo[j].groupMemberNames==myUserId{
                    searchResultGroupIds = GroupInfoManager.sharedInstance.groupInfo[i].taskId
                    break;
                }
            }
            
            if searchResultGroupIds == ""{                          //自分の入っているGrが何もなかったら
                /* NoAction */
            }else{
                //自分の情報内のグループ群に、上で見つけたグループが存在するかしないか検索
                if UserInfoManager.sharedInstance.getGroupIdsCountAtCurrentUserID()==0{                         //自分の所属Grがゼロなら
                    UserInfoManager.sharedInstance.appendGroupIdsAtCurrentUserID(groupId: searchResultGroupIds)
                    judegeSaveToFirebase = true     //Firebaseに保存する
                }else{
                    var checkExistMyId:Bool = false
                    for j in 0 ..< UserInfoManager.sharedInstance.getGroupIdsCountAtCurrentUserID(){
                        //存在するなら既存のグループ
                        if searchResultGroupIds==UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds[j]{
                            checkExistMyId = false
                            break;
                        }
                        //存在しないなら保存する
                        else{
                            checkExistMyId = true
                        }
                    }
                    
                    //自分のIdを加える必要があるなら
                    if checkExistMyId==true{
                        UserInfoManager.sharedInstance.appendGroupIdsAtCurrentUserID(groupId: searchResultGroupIds)
                        judegeSaveToFirebase = true     //Firebaseに保存する
                    }
                }
            }
            
            //再サーチの為に初期化
            searchResultGroupIds = ""
        }
        
        //Firestore(UserInfo(自分))に保存
        if judegeSaveToFirebase==true{
            saveUserInfoToFirestore()
        }
    }
    
    //自分の入っているグループを検索して、どこにもなかった(グループが削除されていた)ら削除する(❇︎実際にはあり得ない(現在未使用)が、残しておく)
    func deleteMyGroupIdsFromSearchingGrouoInfo(){
        var judegeSaveToFirebase:Bool = false
        let length = UserInfoManager.sharedInstance.getGroupIdsCountAtCurrentUserID()
        
        if length==0{
            UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds.removeAll()
            judegeSaveToFirebase = true
        }else{
            for i in 0 ..< length{
                var notDelete:Bool = false
                
                for j in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount(){
                    if UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds[i]==GroupInfoManager.sharedInstance.groupInfo[j].taskId{
                        notDelete=true     //見つかったら
                        break
                    }
                }
                
                if notDelete==false{
                    UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds.remove(at: i)
                    judegeSaveToFirebase = true
                }
            }
        }
        
        //Firestore(UserInfo(自分))に保存
        if judegeSaveToFirebase==true{
            saveUserInfoToFirestore()
        }
    }
    */
    
    /*
    //cellに埋め込んだUISwitch変化時のアクション関数
    @objc func hundleSwitch(sender:UISwitch){
        print("table row switch Changed \(sender.tag)")
        if (sender as AnyObject).isOn{
            print("isON")
            GroupInfoManager.sharedInstance.setCurrentUserStatusInCurrentGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: sender.tag), status: true)
        }else{
            print("isOFF")
            GroupInfoManager.sharedInstance.setCurrentUserStatusInCurrentGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: sender.tag), status: false)
        }
        
        taskGroupTableView.reloadData()
    }
    */
    
    //友達登録画面遷移関数
    /*
    func registerFriend(){
        let vc = TaskAddFriendMethodViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    */
    
    /*
    /* グループメンバー追加画像がクリックされた時にCallされる関数 */
    @objc func addGroupMemberImageViewTapped(sender:UITapGestureRecognizer){
        guard let inputRow=sender.view?.tag else {return}
        
        if GroupInfoManager.sharedInstance.getCurrentUserStatusInReqGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow))==true{
            GroupInfoManager.sharedInstance.setCurrentUserStatusInCurrentGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow), status: false)
        }else{
            GroupInfoManager.sharedInstance.setCurrentUserStatusInCurrentGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow), status: true)
        }
        
        //FireStoreに保存
        saveGroupInfoToFirestore(groupNo:GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow))
        
        //ステータスの変更をPush通知
        //if GroupInfoManager.sharedInstance.getCurrentUserStatusInReqGroup(reqGroupNo: GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow))==true{  //Freeになったら通知
            pushStatusChangeToOtherUser(groupNo:GroupInfoManager.sharedInstance.getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow: inputRow))
        //}
        
        //再描画(監視している先で再描画)
        //taskGroupTableView.reloadData()
    }
    */
    /* 以下、未使用関数群終わり */
}
