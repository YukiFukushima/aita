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

class TaskQRCodeResultViewController: UIViewController, UserInfoDelegate, GroupInfoDelegate {

    @IBOutlet weak var resultQRCodelabel: UILabel!
    var passResultQRCode:String = ""
    var addFriendUserId:String = ""
    let db = Firestore.firestore()
    
    //グループ候補格納変数
    var groupCandidate = GroupInfo(taskId:"",
                                   groupName:"",
                                   GroupMemberNamesInfo:[],
                                   groupMemberTalksInfo:[],
                                   createdAt:Timestamp(date:Date()),
                                   updatedAt:Timestamp(date:Date()))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        UserInfoManager.sharedInstance.delegate = self      //己をセット
        GroupInfoManager.sharedInstance.delegate = self     //己をセット
        
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
    
    //Firestoreからのデータ(会話グループ情報)の読み込み
    func readGroupInfoFromFirestore(){
        //Firebaseから読み込み
        self.db.collection("Groups").order(by: "createdAt", descending: true).getDocuments { (querySnapShot, err) in
            //配列を全削除
            GroupInfoManager.sharedInstance.groupInfo.removeAll()
            
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
                        
                        //print("SyncGroupInfo")
                        
                    } catch let error as NSError{
                        print("エラー:\(error)")
                    }
                }
                //友達登録処理
                //友達と自分がまだグループ管理になっていないならグループ管理に追加
                if self.isExistFriendGroup(friendUserId:self.addFriendUserId)==false{
                    self.saveFriendGroupToFirestore(friendUserId:self.addFriendUserId)
                }
                
                //①友達と自分がグループ管理になっているが、自分の所属グループにそのグループが存在しない場合(削除した場合)再度追加(配列のみ)
                self.addMyIdToExistFriendGroup(friendUserId:self.addFriendUserId)
                
                //②友達を保存(ここで、①の追加分と合わせてFirestoreに保存)
                self.saveFriendToFirestore(friendUserId:self.addFriendUserId)
                
                //画面遷移
                self.dispHomeView()
            }
        }
    }
    
    //既に2人組のグループとして存在しているか否か判定し、存在している場合、自分の所属グループにそのグループを加える関数
    func addMyIdToExistFriendGroup(friendUserId:String){
        var result:Bool = false
        var isExistMyIdInFriendGroup:Bool = false
        var groupId:String = ""
        
        //自分のカレントID取得
        let currentUserId = UserInfoManager.sharedInstance.getCurrentUserID()
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            //もしグループ名がfriendなら
            if GroupInfoManager.sharedInstance.getGroupInfo(num: i).groupName=="friend"{
                let groupMemberOne = GroupInfoManager.sharedInstance.getGroupInfo(num: i).GroupMemberNamesInfo[0].groupMemberNames
                let groupMemberTwo = GroupInfoManager.sharedInstance.getGroupInfo(num: i).GroupMemberNamesInfo[1].groupMemberNames
                
                if groupMemberOne==currentUserId
                && groupMemberTwo==friendUserId{
                    result = true
                }else if groupMemberOne==friendUserId
                &&       groupMemberTwo==currentUserId{
                    result = true
                }
                
                //自分と友達のGrが存在しているなら
                if result==true{
                    groupId = GroupInfoManager.sharedInstance.getGroupInfo(num: i).taskId
                    //自分の所属GrにそのGrがないなら追加
                    for j in 0 ..< UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds.count{
                        if UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds[j]==groupId{
                            isExistMyIdInFriendGroup = true
                            break
                        }
                    }
                    break
                }
            }
        }
        
        //引数で指定した友達とのグループが存在して且つ、自分がそのグループに所属していない場合
        if result
        && isExistMyIdInFriendGroup==false{
            UserInfoManager.sharedInstance.appendGroupIdsAtCurrentUserID(groupId: groupId)  //所属Grに追加
        }
    }
    
    //既に2人組のグループとして存在しているか否か判定する関数
    func isExistFriendGroup(friendUserId:String)->Bool{
        var result:Bool = false
        
        //自分のカレントID取得
        let currentUserId = UserInfoManager.sharedInstance.getCurrentUserID()
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            //もしグループ名がfriendなら
            if GroupInfoManager.sharedInstance.getGroupInfo(num: i).groupName=="friend"{
                let groupMemberOne = GroupInfoManager.sharedInstance.getGroupInfo(num: i).GroupMemberNamesInfo[0].groupMemberNames
                let groupMemberTwo = GroupInfoManager.sharedInstance.getGroupInfo(num: i).GroupMemberNamesInfo[1].groupMemberNames
                
                if groupMemberOne==currentUserId
                && groupMemberTwo==friendUserId{
                    result = true
                }else if groupMemberOne==friendUserId
                &&       groupMemberTwo==currentUserId{
                    result = true
                }
                
                if result==true{
                    break
                }
            }
        }
        
        return result
    }
    
    //グループ作成(自分と友人の2人で構成されるグループ)関数
    func saveFriendGroupToFirestore(friendUserId:String){
        //新しくタスクIDを取得
        let taskId = db.collection("Groups").document().documentID
        
        groupCandidate.taskId = taskId              //taskID格納
        groupCandidate.createdAt = Timestamp()      //作成日格納
        groupCandidate.groupName = "friend"         //名前格納
        
        ////自分を格納
        let appendUserInfo:GroupMemberNamesInfo = GroupMemberNamesInfo.init(groupMemberNames: "", status: false, statusMessage: "", alwaysPushEnable: false)
        appendUserInfo.groupMemberNames = UserInfoManager.sharedInstance.getCurrentUserID()
        groupCandidate.GroupMemberNamesInfo.append(appendUserInfo)
        
        //友達を格納
        let appendUserFriendInfo:GroupMemberNamesInfo = GroupMemberNamesInfo.init(groupMemberNames: "", status: false, statusMessage: "", alwaysPushEnable: false)
        appendUserFriendInfo.groupMemberNames = friendUserId
        groupCandidate.GroupMemberNamesInfo.append(appendUserFriendInfo)

        groupCandidate.updatedAt = Timestamp()            //更新日格納
        
        //Firestore(GroupInfo)に保存
        do{
            //Firestoreに保存出来るように変換する
            let encodeGroupInfo:[String:Any] = try Firestore.Encoder().encode(groupCandidate)
            
            //Firestore保存
            db.collection("Groups").document(groupCandidate.taskId).setData(encodeGroupInfo)
        }catch let error as NSError{
            print("エラー\(error)")
            self.showAlert(title:"エラー", message: "データの読み込みに失敗しました")
        }
    }
    
    //自分の友人を自分の情報に保存する関数
    func saveFriendToFirestore(friendUserId:String){
        //現在のユーザーの友達リストに追加
        UserInfoManager.sharedInstance.appendFriendAtCurrentUserID(friendUserId: friendUserId)
        
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
                    
                    //QRCodeを保存
                    addFriendUserId = QRCodeResult
                    
                    //グループを読み込み最新状態にした上で、友達と自分がまだグループ管理になっていないか判断し、友達追加
                    readGroupInfoFromFirestore()
                    
                    /*
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
                    */
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
            
            //画面遷移
            dispHomeView()
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
    
    //HOME画面遷移関数
    func dispHomeView(){
        //画面遷移
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
            self.tabBarController?.tabBar.isHidden = false
            self.navigationController?.popToRootViewController(animated: true)
        }
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
