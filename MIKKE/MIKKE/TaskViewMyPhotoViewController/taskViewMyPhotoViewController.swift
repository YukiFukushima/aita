//
//  taskViewMyPhotoViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2021/12/24.
//  Copyright © 2021 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseUI

class taskViewMyPhotoViewController: UIViewController,UserInfoDelegate {
    var groupId:String = ""
    var ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var myPhotoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        UserInfoManager.sharedInstance.delegate = self
        
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
    
    // ユーザー画像の表示関数
    func postUserImage(){
        let userPostImageRef = self.getRequestUserPostImageRef(userId:UserInfoManager.sharedInstance.getCurrentUserID(), directory:groupId)
        
        self.downloadFromCloudStorage(userRef:userPostImageRef, currentUserImageView:myPhotoImageView)
    }
    
    //CloudStorageからダウンロードしてくる関数
    func downloadFromCloudStorage(userRef:StorageReference, currentUserImageView:UIImageView){
        //画像の表示
        userRef.downloadURL { (url, error) in
            guard let url = url else {
                self.myPhotoImageView.image = UIImage(named: "noimage")
                //くるくる停止
                self.ActivityIndicator.stopAnimating()
                return
            }
            self.myPhotoImageView.sd_setImage(with: url, placeholderImage: nil, options: SDWebImageOptions.refreshCached, context: nil)
            
            //くるくる停止
            self.ActivityIndicator.stopAnimating()
        }
    }
}
