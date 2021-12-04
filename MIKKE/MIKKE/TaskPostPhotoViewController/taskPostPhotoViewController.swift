//
//  taskPostPhotoViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2021/11/24.
//  Copyright © 2021 福島悠樹. All rights reserved.
//

import UIKit

class taskPostPhotoViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var groupId:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        //タブを隠す
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @IBAction func tappedShutterBtn(_ sender: Any) {
        print("シャッターボタンが押された")
        
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
        
        // iPad の場合のみ、ActionSheetを表示するための必要な設定
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertSheet.popoverPresentationController?.sourceView = self.view
            let screenSize = UIScreen.main.bounds
            alertSheet.popoverPresentationController?.sourceRect = CGRect(x: screenSize.size.width / 2,
                                                                           y: screenSize.size.height,
                                                                           width: 0,
                                                                           height: 0)
        }
        
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
        
        let vc = taskConfimrMyPhotoViewController()
        
        if let pickedImage = info[.originalImage] as? UIImage{
            //撮影or選択した画像をimageViewの中身に入れる
            if UIImagePickerController.InfoKey.mediaType == .originalImage{ //撮影した場合
                //resultImage.image = pickedImage.resize(toWidth: 1080)
                vc.isOriginalImage = true
            }else{  //アルバムから選択した場合
                //resultImage.image = pickedImage
                vc.isOriginalImage = false
            }
            
            vc.image = pickedImage
            vc.groupId = groupId
            navigationController?.pushViewController(vc, animated: true)
            
            //表示した画面を閉じる処理
            picker.dismiss(animated: true, completion: nil)
        }else{
            //表示した画面を閉じる処理
            picker.dismiss(animated: true, completion: nil)
        }
    }
}
