//
//  TaskMikkeDetailStatusViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/08/22.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class TaskMikkeDetailStatusViewController: UIViewController, UIGestureRecognizerDelegate, GroupInfoDelegate {

    @IBOutlet weak var inputDetailStatus: UITextView!
    @IBOutlet weak var alwaysPushSettingUiSwitch: UISwitch!
    @IBOutlet weak var deleteDetailStatusBtnState: UIButton!
    @IBOutlet weak var addFriendImage: UIImageView!
    @IBOutlet weak var addFriendLabel: UILabel!
    @IBOutlet weak var enableBlockSwitch: UISwitch!
    
    var currentGroupNo:Int = 0
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        GroupInfoManager.sharedInstance.delegate = self
    }

    //本画面表示時にコールされる関数
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //必ず通知する否かの状態に従って設定
        if getCurrentUserAlwaysPushSettignInCurrentGroup(){
            self.alwaysPushSettingUiSwitch.isOn = true
        }else{
            self.alwaysPushSettingUiSwitch.isOn = false
        }
        
        //ブロック設定の状態に従って設定
        if GroupInfoManager.sharedInstance.getCurrentUserEnableBlockSettignInCurrentGroup(groupNo:currentGroupNo){
            self.enableBlockSwitch.isOn = true
        }else{
            self.enableBlockSwitch.isOn = false
        }
        
        //詳細ステータスをinputDetailStatusに書き込む
        self.inputDetailStatus.text = self.getCurrentUserDetailStatusInCurrentGroup()
        
        //ゴミ箱ボタンの表示更新
        self.dispDeleteBtnStatus()
        
        //タブを隠す
        self.tabBarController?.tabBar.isHidden = true
        
        //アイコン画像タップ時コール関数登録
        addFriendImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addGroupMemberImageViewTapped)))
        
        //単独の友達としてのグループ登録時による切り替え
        if GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).groupName=="friend"{
            addFriendImage.image = nil
            addFriendImage.isUserInteractionEnabled = false
            addFriendLabel.textColor = .clear
        }else{
            addFriendImage.image = UIImage(systemName: "person.crop.circle.fill.badge.plus")
            addFriendImage.isUserInteractionEnabled = true
            addFriendLabel.textColor = .darkGray
        }
        
        //タイトル設定
        self.title = "このグループでの設定"
    }
    
    //本画面消去時にコールされる関数
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //タブを隠す
        self.tabBarController?.tabBar.isHidden = false
    }
    
    /* タッチした時にキーボードを消す(UIViewControllerに用意されているメソッド) */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    /* textに答えを入力した時にキーボードを消す(textFieldのprotocolに用意されているメソッド) */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    /* グループメンバー追加画像がクリックされた時にCallされる関数 */
    @objc func addGroupMemberImageViewTapped(sender:UITapGestureRecognizer){
        let vc = TaskMakeTableViewController()
        
        //グループID作成
        vc.requestGroupId = GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).taskId
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // このグループ内の現在のユーザーIDの詳細ステータス(一言メッセージ)を変更する関数
    func setCurrentUserDetailStatusInCurrentGroup(statusMessage:String){
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo.count{
            if GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].groupMemberNames==UserInfoManager.sharedInstance.getCurrentUserID(){
                GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].statusMessage = statusMessage
                break
            }
        }
    }
    
    // このグループ内の現在のユーザーIDの詳細ステータス(一言メッセージ)を変更する関数
    func getCurrentUserDetailStatusInCurrentGroup() -> String{
        var result:String = ""
        
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo.count{
            if GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].groupMemberNames==UserInfoManager.sharedInstance.getCurrentUserID(){
                result = GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].statusMessage
                break
            }
        }
        
        return result
    }
    
    // このグループ内の現在のユーザーIDの常時通知設定を変更する関数
    func setCurrentUserAlwaysPushSettignInCurrentGroup(alwaysPushSetting:Bool){
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo.count{
            if GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].groupMemberNames==UserInfoManager.sharedInstance.getCurrentUserID(){
                GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].alwaysPushEnable = alwaysPushSetting
                break
            }
        }
    }
    
    // このグループ内の現在のユーザーIDの常時通知設定を取得する関数
    func getCurrentUserAlwaysPushSettignInCurrentGroup() -> Bool{
        var result:Bool = false
        
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo.count{
            if GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].groupMemberNames==UserInfoManager.sharedInstance.getCurrentUserID(){
                result = GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).GroupMemberNamesInfo[i].alwaysPushEnable
                break
            }
        }
        
        return result
    }
    
    //Firestoreに保存する関数
    func saveGroupOfDetailStatusToFirestore(){
        //GroupのタスクIDを取得
        let taskId = GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).taskId
        
        //Firestoreに保存
        do{
            //Firestoreに保存出来るように変換する
            let encodeGroupInfo:[String:Any] = try Firestore.Encoder().encode(GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo))
            
            //保存
            db.collection("Groups").document(taskId).setData(encodeGroupInfo)
            
        }catch let error as NSError{
            print("エラー\(error)")
        }
    }
    
    //ゴミ箱ボタンの表示更新
    func dispDeleteBtnStatus(){
        if self.inputDetailStatus.text==""{
            self.deleteDetailStatusBtnState.isHidden = true
        }else{
            self.deleteDetailStatusBtnState.isHidden = false
        }
    }
    
    //常時通知切り替えSw関数
    @IBAction func tappedAlwaysPushSettingUiSwitch(_ sender: Any) {
        if (sender as AnyObject).isOn{
            self.setCurrentUserAlwaysPushSettignInCurrentGroup(alwaysPushSetting:true)  //SwOnの処理
        }else{
            self.setCurrentUserAlwaysPushSettignInCurrentGroup(alwaysPushSetting:false)  //SwOffの処理
        }
        
        //Firestoreに保存
        self.saveGroupOfDetailStatusToFirestore()
    }
    
    //ブロック通知切り替えSw関数
    @IBAction func tappedEnableBlockSettingUiSwitch(_ sender: Any) {
        if (sender as AnyObject).isOn{
            GroupInfoManager.sharedInstance.setCurrentUserEnableBlockSettignInCurrentGroup(groupNo: currentGroupNo, enableBlockSetting: true)
            //self.setCurrentUserAlwaysPushSettignInCurrentGroup(alwaysPushSetting:true)  //SwOnの処理
        }else{
            GroupInfoManager.sharedInstance.setCurrentUserEnableBlockSettignInCurrentGroup(groupNo: currentGroupNo, enableBlockSetting: false)
            //self.setCurrentUserAlwaysPushSettignInCurrentGroup(alwaysPushSetting:false)  //SwOffの処理
        }
        
        //Firestoreに保存
        self.saveGroupOfDetailStatusToFirestore()
    }
    
    
    //詳細ステータス消去ボタン押下時関数
    @IBAction func deleteResultDetailStatus(_ sender: Any) {
        //詳細ステータスを空にしてinputDetailStatusに書き込む
        self.inputDetailStatus.text = ""
        
        //ゴミ箱ボタンの表示更新
        self.dispDeleteBtnStatus()
        
        //配列に保存
        self.setCurrentUserDetailStatusInCurrentGroup(statusMessage:inputDetailStatus.text)
        
        //Firestoreに保存
        self.saveGroupOfDetailStatusToFirestore()
    }
    //詳細ステータス入力ボタン押下時関数
    @IBAction func commitDetailStatus(_ sender: Any) {
        //入力された文字列が大きすぎたらエラーメッセージ(だしたい)
        /*
        let width:Int = inputDetailStatus.text.count
        print("文字数：")
        print(width)
        */
        
        //配列に保存
        self.setCurrentUserDetailStatusInCurrentGroup(statusMessage:inputDetailStatus.text)
        
        //Firestoreに保存
        self.saveGroupOfDetailStatusToFirestore()
        
        self.navigationController?.popViewController(animated: true)
    }
    
    //通報ボタン
    @IBAction func tappedEmergencyBtn(_ sender: Any) {
        let vc = taskEmergencyViewController()
        vc.groupId = GroupInfoManager.sharedInstance.getGroupInfo(num: currentGroupNo).taskId
        navigationController?.pushViewController(vc, animated: true)
    }
}
