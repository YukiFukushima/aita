//
//  taskConfimrMyPhotoViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2021/11/26.
//  Copyright © 2021 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseUI

class taskConfimrMyPhotoViewController: UIViewController, UINavigationControllerDelegate, UserInfoDelegate, GroupInfoDelegate {
    @IBOutlet weak var confirmImageView: UIImageView!
    var image: UIImage?
    var isOriginalImage:Bool = false
    var groupId:String = ""
    let dispatchGroup = DispatchGroup()
    let dispatchQueue = DispatchQueue(label: "completeCloudStorageMyPhoto", attributes: .concurrent)
    var ActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        UserInfoManager.sharedInstance.delegate = self
        GroupInfoManager.sharedInstance.delegate = self
        confirmImageView.contentMode = .scaleAspectFit
        confirmImageView.image = image!.resize(toWidth: 1080)
        
        self.setupNavigationBar()
        
        //インジケーター設定
        self.setupActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        //タブを隠す
        self.tabBarController?.tabBar.isHidden = true
    }
    
    //activity indicatorの設定
    private func setupActivityIndicator() {
        // ActivityIndicatorを作成＆中央に配置
        ActivityIndicator = UIActivityIndicatorView()
        ActivityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        ActivityIndicator.center = self.view.center
        
        // クルクルをストップした時に非表示する
        ActivityIndicator.hidesWhenStopped = true
        
        // 色を設定
        ActivityIndicator.style = UIActivityIndicatorView.Style.medium
        
        //Viewに追加
        self.view.addSubview(ActivityIndicator)
    }
    
    // navigation barの設定
    private func setupNavigationBar() {
        //画面上部のナビゲーションバーの右側に写真投稿ボタンを設置し、押されたら画面遷移されるようにする
        let rightButtonItem = UIBarButtonItem(title: "投稿", style: .done, target: self, action: #selector(uploadPhoto))
        navigationItem.rightBarButtonItem = rightButtonItem
    }
    
    // 投稿ボタンをタップしたときの動作
    @objc func uploadPhoto() {
        //くるくる開始
        self.ActivityIndicator.startAnimating()
        
        //右ボタン無効化
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        //CloudStoreに画像を保存
        self.uploadCloudStorage()
        
        //クラウドへのアップロードが完了したらコールされる
        dispatchGroup.notify(queue: DispatchQueue.main){
            print("SyncEndCloudStorage")
            
            //くるくる停止
            self.ActivityIndicator.stopAnimating()
            
            //右ボタン有効化
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            
            
            //プッシュ通知
            self.pushPhotoPostToOtherUser()
            
            //前画面に遷移
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // 指定されたGroupIdからグループ番号を取得する関数
    func getCurrentGroupNumberFromGroupId(groupId:String)->Int{
        var resultGroupNo:Int = 0
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            if groupId==GroupInfoManager.sharedInstance.getGroupInfo(num: i).taskId{
                resultGroupNo = i
                break
            }
        }
        
        return resultGroupNo
    }
    
    //自分以外のユーザーで、ステータスがFreeの人に写真投稿を通知する
    func pushPhotoPostToOtherUser(){
        var userStatus:Bool = false
        var userAlwaysPushEnable:Bool = false
        var enableBlockSetting:Bool = false
        
        /* 送信相手のステータスがFreeだったら、Push通知 */
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromGroupId(groupId:groupId)).GroupMemberNamesInfo.count {
            userStatus = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromGroupId(groupId:groupId)).GroupMemberNamesInfo[i].status
            userAlwaysPushEnable = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromGroupId(groupId:groupId)).GroupMemberNamesInfo[i].alwaysPushEnable
            enableBlockSetting = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromGroupId(groupId:groupId)).GroupMemberNamesInfo[i].enableBlock
            
            if GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromGroupId(groupId:groupId)).GroupMemberNamesInfo[i].groupMemberNames == UserInfoManager.sharedInstance.getCurrentUserID(){
                /* NoAction(自分には通知しない) */
            }else if userStatus == false
            &&       userAlwaysPushEnable == false{
                /* NoAction(ステータスがBusy && 必ず通知する設定ではない人には通知しない) */
            }else if enableBlockSetting == true{
                /* NoAction(ブロック設定している人には通知しない) */
            }else{
                var userToken:String = ""
                userToken = UserInfoManager.sharedInstance.getTokenAtRequestUserID(reqUserId:GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromGroupId(groupId:groupId)).GroupMemberNamesInfo[i].groupMemberNames)
                
                /* ForDebug *
                print("userToken:")
                print(userToken)
                * EndForDebug */
                
                let sendTile:String = GroupInfoManager.sharedInstance.getGroupInfo(num: getCurrentGroupNumberFromGroupId(groupId:groupId)).groupName
                
                SendMessage.sendMessageToUser(userIdToken: userToken,
                                              title: sendTile,
                                              body: UserInfoManager.sharedInstance.getNameAtCurrentUserID()+"さんが写真を投稿しました！")
            }
        }
    }
    
    //写真をcloudにupdateする関数
    func uploadCloudStorage(){
        /*
        //let storage = Storage.storage()
         
        //ルートのリファレンスを作成
        let storageRef = storage.reference()
        
        //ユーザーIDの取得
        let userId = UserInfoManager.sharedInstance.getCurrentUserID()
        
        //userImagesディレクトリに、"ユーザーID.png"の名前でファイルを保存する
        let userRef = storageRef.child("userImages/\(userId).png")
        */
        
        if confirmImageView.image==nil{
            //HOME画面に遷移
            self.navigationController?.popViewController(animated: true)
        }else{
            //let userRef = getUserRef()
            let reqUserId:String = UserInfoManager.sharedInstance.getCurrentUserID()
            let userPostImageRef = self.getRequestUserPostImageRef(userId:reqUserId, directory:groupId)
            
            guard let data = self.confirmImageView.image?.pngData() else { return }
            
            //同期処理開始
            dispatchGroup.enter()
            
            dispatchQueue.async(group: dispatchGroup){
                let meta = StorageMetadata()
                meta.contentType = "image/png"
                
                //データをアップロード
                userPostImageRef.putData(data, metadata: meta) { (metadata, err) in
                    guard let metadata = metadata else {
                        print("upload error")
                        return
                    }
                    let size = metadata.size
                    
                    //アップロード時の画像のサイズ
                    print("\(size):size")
                    
                    //キャッシュ削除
                    userPostImageRef.downloadURL { (url, error) in
                        guard let url = url else { return }
                        self.confirmImageView.sd_setImage(with: url, placeholderImage: nil, options: SDWebImageOptions.refreshCached, context: nil)
                        
                        //同期処理終了
                        self.dispatchGroup.leave()
                    }
                    
                    /*
                    //画像アップ時に端末のキャッシュ削除することで、画像変更時の反映が素早くなる（SDWebImageはFirebaseUIが採用しているライブラリ）
                    SDImageCache.shared.clearMemory()
                    SDImageCache.shared.clearDisk()
                    
                    //同期処理終了
                    self.dispatchGroup.leave()
                    */
                }
            }
        }
    }
}
