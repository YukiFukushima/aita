//
//  ReadQRCodeViewController.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/28.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class ReadQRCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    // カメラやマイクの入出力を管理するオブジェクトを生成
    let session = AVCaptureSession()
    let dispatchGroup = DispatchGroup()
    let dispatchQueue = DispatchQueue(label: "searchView", attributes: .concurrent)
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        self.readUserInfoFromFirestore()
        dispatchGroup.notify(queue: DispatchQueue.main){    //全てのタスクが完了したらコールされる
            self.readQRCode()                               //カメラを起動してQRCodeを読み取る
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    //Firestoreからのデータ(ユーザ情報)の読み込み
    func readUserInfoFromFirestore(){
        //同期処理開始
        dispatchGroup.enter()
        
        //print("UserSyncStart")
        
        dispatchQueue.async(group: dispatchGroup){
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
                    
                    //print("UserSyncEnd")
                    
                    //同期処理終了
                    self.dispatchGroup.leave()
                }
            }
        }
    }
    
    //カメラを起動してQRCodeを読み取る
    func readQRCode(){
        // カメラやマイクのデバイスオブジェクトを生成
        let devices:[AVCaptureDevice] = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices
        
        //　該当するデバイスのうち最初に取得したもの(背面カメラ)を利用する
        if let backCamera = devices.first {
            do {
                // QRコードの読み取りに背面カメラの映像を利用するための設定
                let deviceInput = try AVCaptureDeviceInput(device: backCamera)
                
                let myBoundSize: CGSize = UIScreen.self.main.bounds.size
                let width = myBoundSize.width
                let height = myBoundSize.height
                
                if self.session.canAddInput(deviceInput) {
                    self.session.addInput(deviceInput)

                    // 背面カメラの映像からQRコードを検出するための設定
                    let metadataOutput = AVCaptureMetadataOutput()

                    if self.session.canAddOutput(metadataOutput) {
                        self.session.addOutput(metadataOutput)

                        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                        metadataOutput.metadataObjectTypes = [.qr]

                        // 背面カメラの映像を画面に表示するためのレイヤーを生成
                        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                        
                        previewLayer.frame = self.view.bounds
                        previewLayer.videoGravity = .resizeAspectFill
                        previewLayer.position = CGPoint(x: width/2, y: height/2)
                        self.view.layer.addSublayer(previewLayer)

                        // 読み取り開始
                        self.session.startRunning()
                    }
                }
            } catch {
                print("Error occured while creating video device input: \(error)")
            }
        }
    }
    
    //QRCodeデータを取得して処理を行う関数
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        for metadata in metadataObjects as! [AVMetadataMachineReadableCodeObject] {
            var message = ""
            
            // QRコード確認
            if metadata.type != .qr             // QRコードのデータかどうかの確認
            || metadata.stringValue == nil{     // QRコードの内容が空かどうかの確認
                //アラート表示
                message = "アプリを立ち上げ直してください"
                self.showAlert(title: "QRコードの読み取りに失敗しました", message: message)
                break
                
                //continue
            }

            // ここでQRコードから取得したデータで何らかの処理を行う
            // 取得したデータは「metadata.stringValue」で使用できる
            print("結果：")
            print("metadata.stringValue")
            
            guard let result=metadata.stringValue else{ return }
            let vc = TaskQRCodeResultViewController()
            vc.passResultQRCode = result
            navigationController?.pushViewController(vc, animated: true)
            //self.present(vc, animated: true, completion: nil)
            self.session.stopRunning()
            break
        }
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
}
