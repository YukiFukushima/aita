//
//  TaskAddFriendSearchViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/08/25.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

class TaskAddFriendSearchViewController: UIViewController, UISearchBarDelegate, UserInfoDelegate, GroupInfoDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchResultLabel: UILabel!
    @IBOutlet weak var searchResultImageView: UIImageView!
    @IBOutlet weak var addFriendBtn: UIButton!
    var addFriendUserId:String = ""
    let db = Firestore.firestore()
    let dispatchGroup = DispatchGroup()
    let dispatchQueue1 = DispatchQueue(label: "searchView1", attributes: .concurrent)
    
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
        searchBar.delegate = self
        UserInfoManager.sharedInstance.delegate = self
        GroupInfoManager.sharedInstance.delegate = self
        
        //画像の角丸具合の設定
        searchResultImageView.layer.cornerRadius = 50.0
        
        self.title = "aita IDで友達を追加する"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.searchBar.isHidden = true
        self.readUserInfoFromFirestore()
        self.searchResultLabel.text = "IDを入力して友達を探してみてください"
        self.addFriendBtn.isHidden = true
        
        //タブを隠す
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //タブを戻す
        self.tabBarController?.tabBar.isHidden = false
    }
    
    /* タッチした時にキーボードを消す(UIViewControllerに用意されているメソッド) */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    //Keyboard上のSearchボタン押下時関数
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        var filterUserUniqueId:[String] = []
        var allUniqueUserIdList:[String] = []
        var finalUserUniqueId:String = ""
        
        //全ユーザーの設定IDをローカルにロード
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            allUniqueUserIdList.append(UserInfoManager.sharedInstance.userLists[i].uniqueUserId)
        }
        
        //検索バーに入力された文字列と設定IDとを照合し候補を格納
        guard let text=searchBar.text else{ return }
        filterUserUniqueId = allUniqueUserIdList.filter({ (String) -> Bool in
            return String.contains(text)
        })
        
        //候補から完全一致するユーザーIDを特定
        for i in 0 ..< filterUserUniqueId.count {
            if text==filterUserUniqueId[i]{
                finalUserUniqueId = text
                break
            }
        }
        
        //検索結果表示
        dispResultSearch(finalUserUniqueId:finalUserUniqueId)
    }
    
    //検索結果表示関数
    func dispResultSearch(finalUserUniqueId:String){
        if finalUserUniqueId==""{   //ユーザーIDが見つからなかった(入力したIDの友達がいなかった)
            searchResultLabel.text = "お探しのユーザーが見当たりません"
            searchResultImageView.image = nil
            addFriendUserId = ""
            self.addFriendBtn.isHidden = true
        }else{                          //入力したIDの友達がいた
            for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
                if finalUserUniqueId==UserInfoManager.sharedInstance.userLists[i].uniqueUserId{
                    
                    //名前の入力
                    searchResultLabel.text = UserInfoManager.sharedInstance.userLists[i].name
                    
                    //画像の入力
                    viewNameImage(reqUSerId:UserInfoManager.sharedInstance.userLists[i].userID, currentUserImageView: searchResultImageView)
                    
                    //候補をローカルに記憶
                    addFriendUserId = UserInfoManager.sharedInstance.userLists[i].userID
                    
                    //ボタンを有効にする
                    self.addFriendBtn.isHidden = false
                }
            }
        }
    }
    
    //CloudStorageからダウンロードしてくる関数
    func downloadFromCloudStorage(userRef:StorageReference, currentUserImageView:UIImageView){
        //placeholderの役割を果たす画像をセット
        let placeholderImage = UIImage(systemName: "photo")
        
        //読み込み
        currentUserImageView.sd_setImage(with: userRef, placeholderImage: placeholderImage)
    }
    
    // ユーザー画像の表示関数
    func viewNameImage(reqUSerId:String, currentUserImageView: UIImageView){
        let userRef = self.getRequestUserRef(userId:reqUSerId)
        downloadFromCloudStorage(userRef:userRef, currentUserImageView:currentUserImageView)
    }
    
    //Firestoreからのデータ(ユーザ情報)の読み込み
    func readUserInfoFromFirestore(){
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
                
                //ユーザー情報を読み込んだらサーチバーを有効にする
                self.searchBar.isHidden = false
            }
        }
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
    
    //アラート表示関数
    func showAlert( title:String, message:String? ){
        //UIAlertControllerを関数の引数であるとtitleとmessageを使ってインスタンス化
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        //UIAlertActionを追加
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        //表示
        self.present(alertVC, animated: true, completion: nil)
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
        //配列に保存
        UserInfoManager.sharedInstance.appendFriendAtCurrentUserID(friendUserId:addFriendUserId)
        
        //Firebaseに保存
        do{
            //Firestoreに保存出来るように変換する
            let encodeUserInfo:[String:Any] = try Firestore.Encoder().encode(UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID())
            
            //Firestoreに書き込み
            db.collection("Users").document(UserInfoManager.sharedInstance.getTaskIdAtCurrentUserID()).setData(encodeUserInfo)
            
        }catch let error as NSError{
            print("エラー\(error)")
        }
        
        //追加完了メッセージ
        searchResultLabel.text = UserInfoManager.sharedInstance.getNameAtRequestUserID(reqUserId: addFriendUserId)+"を友達に追加しました"
        
        //ボタンを隠す
        self.addFriendBtn.isHidden = true
        
        //サーチバーを隠す
        self.searchBar.isHidden = true
        
        //HOME画面に遷移
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
            self.tabBarController?.tabBar.isHidden = false                      //タブを戻す
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    //友達リスト追加ボタン押下時関数
    @IBAction func tappedAddFriendListBtn(_ sender: Any) {
        var isCompletedAddFriend:Bool = false
        
        //既に登録済みか否かチェック
        for i in 0 ..< UserInfoManager.sharedInstance.getFriendCountAtCurrentUserID() {
            if addFriendUserId==UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().friendIds[i]{
                isCompletedAddFriend = true
                break
            }
        }
        
        //友達が未登録なら
        if isCompletedAddFriend==false{
            //グループを読み込み最新状態にした上で、友達と自分がまだグループ管理になっていないか判断し、友達追加
            readGroupInfoFromFirestore()
        }else{
            searchResultLabel.text = UserInfoManager.sharedInstance.getNameAtRequestUserID(reqUserId: addFriendUserId)+"は登録済みです"
            
            //サーチバーを隠す
            self.searchBar.isHidden = true
            
            //検索バーの文字列を消去
            self.searchBar.text = ""
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0){
                //検索バーを再表示
                self.searchBar.isHidden = false
                
                //初期状態(初期文言)
                self.searchResultLabel.text = "IDを入力して友達を探してみてください"
                
                //初期状態(画像非表示)
                self.searchResultImageView.image = nil
                
                //初期状態(ボタンを隠す)
                self.addFriendBtn.isHidden = true
            }
        }
    }
}
