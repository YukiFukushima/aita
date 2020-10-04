//
//  TaskInitViewController.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/08/16.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

class TaskInitViewController: UIViewController, UserInfoDelegate {
    let db = Firestore.firestore()
    let dispatchGroup = DispatchGroup()
    let dispatchQueue1 = DispatchQueue(label: "initView1", attributes: .concurrent)
    let dispatchQueue2 = DispatchQueue(label: "initView2", attributes: .concurrent)
    let dispatchQueue3 = DispatchQueue(label: "initView3", attributes: .concurrent)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        UserInfoManager.sharedInstance.delegate = self      //己をセット
        
        //配列を全削除
        UserInfoManager.sharedInstance.userLists.removeAll()
        GroupInfoManager.sharedInstance.groupInfo.removeAll()
        
        //dataをFirestoreから読み込み
        self.loadFromFirestore()
    }

    //Firestoreから全データを読み込み
    func loadFromFirestore(){
        //print("SyncStart")
        
        readUserInfoFromFirestore()
        readGroupInfoFromFirestore()
        
        dispatchGroup.notify(queue: DispatchQueue.main){    //全てのタスクが完了したらコールされる
            //print("SyncEnd")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                InitViewCompleteRepository.saveInitViewCompleteDefaults(initComplete: true)
                self.dismiss(animated: true, completion: nil)   //Main画面に戻る
                /*
                if UserGroupUpdateRepository.loadUserGroupUpdateDefaults()==true{           //新しいグループに招待されているなら
                    let vc = TaskGroupViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                }else{
                    self.dismiss(animated: true, completion: nil)   //Main画面に戻る
                }
                */
            }
        }
    }
    
    //Firestoreからのデータ(ユーザー情報)の読み込み
    func readUserInfoFromFirestore(){
        //同期処理開始
        dispatchGroup.enter()
        
        //print("UserSyncStart")
        
        //Firebaseから読み込み
        self.db.collection("Users").order(by: "taskId", descending: true).getDocuments { (querySnapShot, err) in
            if let err = err{
                print("エラー:\(err)")
            }else{
                //同期登録
                self.dispatchQueue1.async(group: self.dispatchGroup){
                    //取得したDocument群の1つ1つのDocumentについて処理をする
                    for document in querySnapShot!.documents{
                        //各DocumentからはDocumentIDとその中身のdataを取得できる
                        /*print("\(document.documentID) => \(document.data())")*/
                        //型をUserInfo型に変換
                        do {
                            let decodedTask = try Firestore.Decoder().decode(UserInfo.self, from: document.data())
                            //変換に成功
                            UserInfoManager.sharedInstance.appendUserLists(userInfo: decodedTask)
                            
                            //print("SyncUserInfo")
                            
                        } catch let error as NSError{
                            print("エラー:\(error)")
                        }
                    }
                    //同期処理終了
                    self.dispatchGroup.leave()
                }
                
                //print("UserSyncEnd")
            }
        }
    }
    
    //Firestoreからのトーク情報の読み込み
    func readTalksInfoFromFireStore(){
        //同期処理開始
        dispatchGroup.enter()
        
        //print("GroupTalkSyncStart")
        
        self.db.collection("Talks").order(by: "groupMemberTalksCreatedAt", descending: true).getDocuments { (querySnapShot, err) in
            //トーク情報を初期化
            GroupInfoManager.sharedInstance.initGroupTalkInfo()
            
            //再度読み直して配列に保存
            if let err = err{
                print("エラー:\(err)")
            }else{
                //同期登録
                self.dispatchQueue3.async(group: self.dispatchGroup){
                    //取得したDocument群の1つ1つのDocumentについて処理をする
                    for document in querySnapShot!.documents{
                        //各DocumentからはDocumentIDとその中身のdataを取得できる
                        //print("\(document.documentID) => \(document.data())")
                        //型をUserInfo型に変換([String:Any]型で記録する為、変換が必要)
                        do {
                            
                            let decodedTask = try Firestore.Decoder().decode(GroupMemberTalksInfo.self, from: document.data())
                            //変換に成功
                            GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId:decodedTask.groupId).groupMemberTalksInfo.insert(decodedTask, at: 6)
                            //GroupInfoManager.sharedInstance.getGroupInfoAtRequestTaskId(reqTaskId:decodedTask.groupId).groupMemberTalksInfo.append(decodedTask)
                            //GroupInfoManager.sharedInstance.getGroupInfo(num: groupNum).groupMemberTalksInfo.append(decodedTask)
                            //GroupInfoManager.sharedInstance.appendGroupInfo(groupInfo: decodedTask)
                            //GroupInfoManager.sharedInstance.groupInfo.insert(decodedTask, at: self.groupNumber)
                        } catch let error as NSError{
                            print("エラー:\(error)")
                        }
                    }
                    
                    //print("GroupTalkSyncEnd")
                    
                    //同期処理終了
                    self.dispatchGroup.leave()
                }
            }
        }
    }
    
    //Firestoreからのデータ(会話グループ情報)の読み込み
    func readGroupInfoFromFirestore(){
        //同期処理開始
        dispatchGroup.enter()
        
        //print("GroupSyncStart")
        
        //Firebaseから読み込み
        self.db.collection("Groups").order(by: "createdAt", descending: true).getDocuments { (querySnapShot, err) in
            //配列を全削除
            GroupInfoManager.sharedInstance.groupInfo.removeAll()
            
            if let err = err{
                print("エラー:\(err)")
            }else{
                //同期登録
                self.dispatchQueue2.async(group: self.dispatchGroup){
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
                    //トーク情報読み込み
                    self.readTalksInfoFromFireStore()
                    
                    //同期処理終了
                    self.dispatchGroup.leave()
                }
                
                //print("GroupSyncEnd")
            }
        }
    }
}
