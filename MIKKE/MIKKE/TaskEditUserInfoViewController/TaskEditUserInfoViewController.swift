//
//  TaskEditUserInfoViewController.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/24.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseUI

class TaskEditUserInfoViewController: UIViewController, UserInfoDelegate, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var renameTextView: UITextField!
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var uniqueIdTextView: UITextField!
    @IBOutlet weak var uniqueIdLabel: UILabel!
    @IBOutlet weak var uniqueIdWarningLabel: UILabel!
    
    var imageViewFromHomeView:UIImageView!
    let db = Firestore.firestore()
    let dispatchGroup = DispatchGroup()
    let dispatchQueue = DispatchQueue(label: "completeCloudStorage", attributes: .concurrent)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        UserInfoManager.sharedInstance.delegate = self
        renameTextView.delegate = self
        
        self.title = "プロフィールの編集"
        self.resultImageView.image = imageViewFromHomeView.image
        self.renameTextView.text = UserInfoManager.sharedInstance.getNameAtCurrentUserID()
        self.uniqueIdTextView.text = UserInfoManager.sharedInstance.getUniqueUserIdAtCurrentUserID()
        if self.uniqueIdTextView.text?.isEmpty == false{
            uniqueIdTextView.isUserInteractionEnabled = false
            uniqueIdTextView.borderStyle = .none
            uniqueIdTextView.textAlignment = .center
            uniqueIdLabel.text = "あなたのID"
            uniqueIdWarningLabel.textColor = .clear
            uniqueIdTextView.font = .boldSystemFont(ofSize: 16)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
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
    
    // 引数で渡された文字が半角英数字のみか判定する関数
    // - Returns: true：半角英数字のみ、false：半角英数字以外が含まれる
    func isAlphanumeric(string:String) -> Bool {
        return !string.isEmpty && string.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
    
    //ユーザーが任意に設定するIDが保存可能か否か判定する関数
    func isEnableSaveUniqueId(uniqueId:String) -> ResultUniqueId{
        var result:ResultUniqueId = .availableId
        
        //入力IDチェック
        if uniqueId==""{    //入力文字が空だったら強制許可(ユーザー独自のユーザーIDの作成は任意だから)
            result = .availableId
        }else if !self.isAlphanumeric(string:uniqueId){  //半角英数時以外だったら
            result = .eregularId
        }else if uniqueId.count<6{
            result = .underCountId
        }else{
            //入力されたIDが既に他人に使用されていたら入力済みだった場合はNG
            for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
                if UserInfoManager.sharedInstance.getCurrentUserID()==UserInfoManager.sharedInstance.userLists[i].userID{
                    /* NoAction(自分は除く) */
                }else{
                    if uniqueId==UserInfoManager.sharedInstance.userLists[i].uniqueUserId{
                        result = .sameId
                        break
                    }
                }
            }
        }
        
        return result
    }
    
    @IBAction func backToSaveBtn(_ sender: Any) {
        //名前とユーザーが任意に設定するIDを保存
        guard let reName = renameTextView.text else{ return }
        guard let uniqueId = uniqueIdTextView.text else { return }
        
        if reName.isEmpty{
            showAlert( title:"エラー", message:"名前を入力して下さい" )
        }else{
            switch isEnableSaveUniqueId(uniqueId:uniqueId){
            case .sameId:
                showAlert( title:"エラー", message:"このIDは使用できません" )
            case .eregularId:
                showAlert( title:"エラー", message:"半角英数時のみ入力可能です" )
            case .underCountId:
                showAlert( title:"エラー", message:"6文字以上で入力して下さい" )
            case .availableId:
                //名前を保存
                UserInfoManager.sharedInstance.setNameAtCurrentUserID(name: reName)
                
                //ユーザーが設定したユーザーIDを保存
                UserInfoManager.sharedInstance.setUniqueUserIdAtCurrentUserID(uniqueUserId: uniqueId)
                
                //Firestoreに保存
                do{
                    //Firestoreに保存出来るように変換する
                    let encodeUserInfo:[String:Any] = try Firestore.Encoder().encode(UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID())
                    
                    //Firestoreに書き込み
                    db.collection("Users").document(UserInfoManager.sharedInstance.getTaskIdAtCurrentUserID()).setData(encodeUserInfo)
                    
                }catch let error as NSError{
                    print("エラー\(error)")
                }
                
                print("SyncStartCloudStorage")
                
                //CloudStoreに画像を保存
                self.uploadCloudStorage()
                
                //クラウドへのアップロードが完了したらコールされる
                dispatchGroup.notify(queue: DispatchQueue.main){
                    print("SyncEndCloudStorage")
                    
                    //HOME画面に遷移
                    self.navigationController?.popViewController(animated: true)
                }
                //HOME画面に遷移(HOME画面への遷移は、CloudStorageにUpし終わった後に行うこと!!)
                //navigationController?.popViewController(animated: true)
                //self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
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
    
    /* 写真編集アイコンタップボタン */
    @IBAction func tappedPhotoImage(_ sender: Any) {
        print("押された！")
        // アクションシートを表示する
        let alertSheet = UIAlertController(title: nil, message: "選択してください", preferredStyle: .actionSheet)
        
        //カメラを選んだとき
        let cameraAction = UIAlertAction(title: "カメラで撮影", style: .default) { action in
            print("カメラが選択されました")
            self.presentPicker(sourceType:.camera)
        }
        //アルバムを選んだとき
        let albumAction = UIAlertAction(title: "アルバムから選択", style: .default) { action in
            print("アルバムが選択されました")
            self.presentPicker(sourceType:.photoLibrary)
        }
        //キャンセルを選んだとき
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { action in
            print("キャンセルが選択されました")
        }
        
        alertSheet.addAction(cameraAction)
        alertSheet.addAction(albumAction)
        alertSheet.addAction(cancelAction)
        
        present(alertSheet, animated: true)
    }
    
    //アルバムとカメラの画面を生成する関数
    func presentPicker(sourceType:UIImagePickerController.SourceType){
        if UIImagePickerController.isSourceTypeAvailable(sourceType){
            //ソースタイプが利用できるとき
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            
            //デリゲート先に自らのクラスを指定
            picker.delegate = self
            
            //画面を表示する
            present(picker, animated: true, completion: nil)
        } else {
            print("The SourceType is not found")
        }
    }
    
    //撮影もしくは画像を選択したら呼ばれる
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("撮影もしくは画像を選択したよ!")
        if let pickedImage = info[.originalImage] as? UIImage{
            //撮影or選択した画像をimageViewの中身に入れる
            //resultImageView.image = pickedImage
            resultImageView.image = pickedImage.resize(toWidth: 170)
            //resultImageView.contentMode = .scaleAspectFit
            resultImageView.contentMode = .scaleAspectFill
        }
        //表示した画面を閉じる処理
        picker.dismiss(animated: true, completion: nil)
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
        
        if resultImageView.image==nil{
            //HOME画面に遷移
            self.navigationController?.popViewController(animated: true)
        }else{
            let userRef = getUserRef()
            
            guard let data = self.resultImageView.image?.pngData() else { return }
            
            //同期処理開始
            dispatchGroup.enter()
            
            dispatchQueue.async(group: dispatchGroup){
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
                    
                    //同期処理終了
                    self.dispatchGroup.leave()
                }
            }
        }
    }
}


