//
//  taskConfirmUserPhotoViewController.swift
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

class taskConfirmUserPhotoViewController: UIViewController {
    var groupId:String = ""
    var userId:String = ""
    var ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var postUserImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupNavigationBar()
        
        //インジケーター設定
        self.setupActivityIndicator()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        //タブを隠す
        self.tabBarController?.tabBar.isHidden = true
        
        //くるくる開始して画像表示
        self.ActivityIndicator.startAnimating()
        self.postUserImage()
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
        let rightButtonItem = UIBarButtonItem(title: "保存", style: .done, target: self, action: #selector(savePhotoToCameraRoll))
        navigationItem.rightBarButtonItem = rightButtonItem
    }
    
    // カメラロールに画像を保存するボタンをタップしたときの動作
    @objc func savePhotoToCameraRoll() {
        // その中の UIImage を取得
        let targetImage = postUserImageView.image!
        
        //保存するか否かのアラート
        let alertController = UIAlertController(title: "保存", message: "この画像を保存しますか？", preferredStyle: .alert)
        //OK
        let okAction = UIAlertAction(title: "OK", style: .default) { (ok) in
            //右ボタン無効化
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            
            //くるくる開始
            self.ActivityIndicator.startAnimating()
            
            //ここでフォトライブラリに画像を保存
            UIImageWriteToSavedPhotosAlbum(targetImage, self, #selector(self.showResultOfSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        //CANCEL
        let cancelAction = UIAlertAction(title: "キャンセル", style: .default) { (cancel) in
            alertController.dismiss(animated: true, completion: nil)
        }
        //OKとCANCELを表示追加し、アラートを表示
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // 保存結果をアラートで表示
    @objc func showResultOfSaveImage(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        var title = "保存完了"
        var message = "カメラロールに保存しました"
        
        //右ボタン有効化
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        
        //くるくる停止
        self.ActivityIndicator.stopAnimating()
        
        if error != nil {
            title = "エラー"
            message = "保存に失敗しました"
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // OKボタンを追加
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // UIAlertController を表示
        self.present(alert, animated: true, completion: nil)
    }
    
    // ユーザー画像の表示関数
    func postUserImage(){
        let userPostImageRef = self.getRequestUserPostImageRef(userId:userId, directory:groupId)
        self.downloadFromCloudStorage(userRef:userPostImageRef, currentUserImageView:postUserImageView)
    }
    
    //CloudStorageからダウンロードしてくる関数
    func downloadFromCloudStorage(userRef:StorageReference, currentUserImageView:UIImageView){
        //画像の表示
        userRef.downloadURL { (url, error) in
            guard let url = url else {
                self.postUserImageView.image = UIImage(named: "noimage")
                //くるくる停止
                self.ActivityIndicator.stopAnimating()
                
                //右ボタン無効化
                self.navigationItem.rightBarButtonItem?.isEnabled = false
                return
            }
            self.postUserImageView.sd_setImage(with: url, placeholderImage: nil, options: SDWebImageOptions.refreshCached, context: nil)
            
            //くるくる停止
            self.ActivityIndicator.stopAnimating()
        }
        
        /*
        //placeholderの役割を果たす画像をセット
        let placeholderImage = UIImage(systemName: "photo")
        
        //読み込み
        currentUserImageView.sd_setImage(with: userRef, placeholderImage: placeholderImage)
        */
    }
}
