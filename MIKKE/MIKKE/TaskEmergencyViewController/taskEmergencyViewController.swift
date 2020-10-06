//
//  taskEmergencyViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/10/06.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

class taskEmergencyViewController: UIViewController {
    let db = Firestore.firestore()
    var groupId:String = ""
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var eMailText: UITextField!
    @IBOutlet weak var blackNameText: UITextField!
    @IBOutlet weak var messageText: UITextView!
    @IBOutlet weak var btnLabel: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //タブを隠す
        self.tabBarController?.tabBar.isHidden = true
        
        //タイトル設定
        self.title = "通報"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //タブを隠す
        self.tabBarController?.tabBar.isHidden = false
    }
    
    /* タッチした時にキーボードを消す(UIViewControllerに用意されているメソッド) */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    //Firestoreに保存する関数
    func saveEmergencyInfoToFirestore(){
        //データをアンラップ
        guard let name=nameText.text else{return}
        guard let eMail=eMailText.text else{return}
        guard let blackName=blackNameText.text else{return}
        guard let message=messageText.text else{return}
        
        //新しくタスクIDを取得
        let taskId = db.collection("Emergencies").document().documentID
        
        //グループ候補格納変数
        let emergencyInfo = EmergencyInfo(name:name,
                                          eMail:eMail,
                                          blackName:blackName,
                                          message:message,
                                          groupId:groupId,
                                          createdAt:Timestamp(date:Date()),
                                          updatedAt:Timestamp(date:Date()))
        
        //Firestoreに保存
        do{
            //Firestoreに保存出来るように変換する
            let encodeEmergencyInfo:[String:Any] = try Firestore.Encoder().encode(emergencyInfo)
            
            //保存
            db.collection("Emergencies").document(taskId).setData(encodeEmergencyInfo)
            
        }catch let error as NSError{
            print("エラー\(error)")
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
    
    @IBAction func tappedEmergencyBtn(_ sender: Any) {
        //データをアンラップ
        guard let name=nameText.text else{return}
        guard let eMail=eMailText.text else{return}
        guard let blackName=blackNameText.text else{return}
        guard let message=messageText.text else{return}
        
        if name.isEmpty{
            showAlert( title:"エラー", message:"名前を入力して下さい" )
        }else if eMail.isEmpty{
            showAlert( title:"エラー", message:"メールアドレスを入力して下さい" )
        }else if blackName.isEmpty{
            showAlert( title:"エラー", message:"通報するユーザー名を入力して下さい" )
        }else if message.isEmpty{
            showAlert( title:"エラー", message:"メッセージを入力して下さい" )
        }else{
            self.saveEmergencyInfoToFirestore()
            
            btnLabel.setTitle("送信しました", for: .normal)
            self.nameText.text = ""
            self.eMailText.text = ""
            self.blackNameText.text = ""
            self.messageText.text = ""
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){
                self.btnLabel.setTitle("送信", for: .normal)
            }
        }
    }
}
