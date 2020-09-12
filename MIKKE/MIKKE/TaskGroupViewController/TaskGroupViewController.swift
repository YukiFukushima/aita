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

class TaskGroupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GroupInfoDelegate, UIGestureRecognizerDelegate, UserInfoDelegate {

    @IBOutlet weak var taskGroupTableView: UITableView!
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        taskGroupTableView.delegate = self
        taskGroupTableView.dataSource = self
        GroupInfoManager.sharedInstance.delegate = self
        UserInfoManager.sharedInstance.delegate = self
        configureTableViewCell()
        
        // Do any additional setup after loading the view.
        
        //タイトルを表示
        self.title = "グループ"
    }
    
    /* 再描画 */
    override func viewWillAppear(_ animated: Bool) {
        readGroupInfoFromFirestore()                                                //グループを読み込んで再評価
        if UserGroupUpdateRepository.loadUserGroupUpdateDefaults()==true{           //新しいグループに招待されているなら
            UserGroupUpdateRepository.saveUserGroupUpdateDefaults(goUpdate: false)  //updateフラグを落とす
        }
        
        /*
        if UserGroupUpdateRepository.loadUserGroupUpdateDefaults()==true{   //新しいグループに招待されているなら
            self.addMyGroupIdsFromSearchingGrouoInfo()  //自分の入っているグループを検索して、自分の情報(自分が入っているグループ群)に加える
            UserGroupUpdateRepository.saveUserGroupUpdateDefaults(goUpdate: false)  //updateフラグを落とす
        }
        
        //restoreDataFromFirestore()            //自デバイスでグループを作って戻ってきた時のため
        self.taskGroupTableView.reloadData()    //自デバイスでグループを作って戻ってきた時のため
        */
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
        
        /* グループイメージを表示 */
        cell.groupImageView.image = UIImage(named: "aita")
        cell.groupImageView.layer.cornerRadius = 25.0
        
        /* グループメンバー追加画像タップ時イベント設定 */
        cell.addGroupMemberImageView.isUserInteractionEnabled = true
        cell.addGroupMemberImageView.tag = indexPath.row
        cell.addGroupMemberImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addGroupMemberImageViewTapped)))
        
        /* グループ名を表示 */
        var groupId:String = ""
        let currentUserInfo:UserInfo = UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID()
        groupId = currentUserInfo.groupIds[indexPath.row]
        cell.groupLabel.text = GroupInfoManager.sharedInstance.getGroupNamgeAtRequestTaskId(reqTaskId: groupId)
        return cell
    }
    
    /* グループメンバー追加画像がクリックされた時にCallされる関数 */
    @objc func addGroupMemberImageViewTapped(sender:UITapGestureRecognizer){
        guard let inputRow=sender.view?.tag else {return}
        
        let vc = TaskMakeTableViewController()
        
        //グループID作成
        var groupId:String = ""
        let currentUserInfo:UserInfo = UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID()
        groupId = currentUserInfo.groupIds[inputRow]
        vc.requestGroupId = groupId
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //GroupInfo内のグループメンバーとUserInfo内の確認済みグループメンバーを照合し、無ければ、新しいGrとして自分が入っているグループ群に加える
    func addMyGroupIdsFromSearchingGrouoInfo(){
        let myUserId = UserInfoManager.sharedInstance.getCurrentUserID()
        var necessarySaveFirestore:Bool = false
        
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
                        
                        //参加Grに加える
                        UserInfoManager.sharedInstance.appendGroupIdsAtCurrentUserID(groupId: groupId)
                        
                        //確認済みGrに加える
                        UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().verifyGroupIds.append(groupId)
                        necessarySaveFirestore = true
                    }
                    break
                }
            }
        }
        
        //Firestoreに保存するなら
        if necessarySaveFirestore==true{
            saveUserInfoToFirestore()
        }
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
                        GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId:decodedTask.groupId).groupMemberTalksInfo.insert(decodedTask, at: 5)
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
            }
        }
    }
    
    //Firestoreからのデータ(Group情報)の読み込み
    func readGroupInfoFromFirestore(){
        db.collection("Groups").order(by: "createdAt", descending: true).getDocuments { (querySnapShot, err) in
            //配列を全削除
            GroupInfoManager.sharedInstance.groupInfo.removeAll()
            
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
                    } catch let error as NSError{
                        print("エラー:\(error)")
                    }
                }
                
                //トーク情報の読み込み
                self.readTalksInfoFromFireStore()
            }
        }
    }
    
    /* Firestoreからの削除関数 */
    func deleteTaskFromFirestore(deleteGropuNum:Int){
        db.collection("Groups").document(GroupInfoManager.sharedInstance.getGroupInfo(num: deleteGropuNum).taskId).delete()
    }
    
    /* スワイプ処理(削除) */
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        var deleteGroupInfoNum:Int = 0
        var deleteGroupIdNum:Int = 0
        var deleteExecute:Bool = false
        
        //削除するグループ(taskId)を取得
        let deleteTaskId = UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds[indexPath.row]
        
        //削除するグループの番号を取得
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount(){
            if GroupInfoManager.sharedInstance.getGroupInfo(num: i).taskId==deleteTaskId{
                deleteGroupInfoNum = i
                break
            }
        }
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds.count{
            if UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds[i]==deleteTaskId{
                deleteGroupIdNum = i
                deleteExecute = true
            }
        }
        
        //Firebaseに保存する必要があるなら
        if deleteExecute==true{
            UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds.remove(at: deleteGroupIdNum)
            saveUserInfoToFirestore()
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
    
    /* タップ時処理 */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //タップ後cellの色をすーっと変える
        taskGroupTableView.deselectRow(at: indexPath, animated: true)
        
        //let vc = TaskGroupDetailViewController()
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
    /* 以下、未使用関数群終わり */
}
