//
//  TaskManager.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/23.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseUI
import LinkPresentation

//----------------------------------------------------
//  ユーザー管理タスク
//----------------------------------------------------

class UserInfo:Codable{
    var taskId:String
    var userID:String
    var name:String
    var userToken:String
    var uniqueUserId:String         //ユーザーが自分で作成したユーザーID
    var friendIds:[String]          //自分の友達群(友達リストに表示される)
    var groupIds:[String]           //自分が入っているグループ群
    var verifyGroupIds:[String]     //自分が確認したグループ群
    
    var createdAt:Timestamp
    var updatedAt:Timestamp
    
    init(taskId:String,
         userID:String,
         name:String,
         userToken:String,
         uniqueUserId:String,
         friendIds:[String],
         groupIds:[String],
         verifyGroupIds:[String],
         createdAt:Timestamp,
         updatedAt:Timestamp){
        self.taskId = taskId
        self.userID = userID
        self.name = name
        self.userToken = userToken
        self.uniqueUserId = uniqueUserId
        self.friendIds = friendIds
        self.groupIds = groupIds
        self.verifyGroupIds = verifyGroupIds
        
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

protocol UserInfoDelegate:class{
    /* NoAction */
}

class UserInfoManager{
    static let sharedInstance = UserInfoManager()
    
    var userLists:[UserInfo] = [UserInfo(taskId:"", userID:"", name:"", userToken:"", uniqueUserId:"", friendIds:[""], groupIds:[""], verifyGroupIds:[""], createdAt:Timestamp(date:Date()), updatedAt:Timestamp(date:Date()))]
    
    weak var delegate:UserInfoDelegate?
    
    
    /* ユーザーリストの数を取得 */
    func getUserListsCount() -> Int{
        return self.userLists.count
    }
    
    /* ユーザーリストに追加 */
    func appendUserLists(userInfo:UserInfo){
        self.userLists.append(userInfo)
    }
    
    /* 現在のユーザーIDを返す */
    func getCurrentUserID()->String{
        return String(describing:Auth.auth().currentUser?.uid)
    }
    
    /* 現在のユーザーIDを見つけて名前を入れる */
    func setNameAtCurrentUserID(name:String){
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                
                UserInfoManager.sharedInstance.userLists[i].name = name
            }
        }
    }
    
    /* 現在のユーザーIDの名前を返す */
    func getNameAtCurrentUserID()->String{
        var currentName:String = ""
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                
                currentName = UserInfoManager.sharedInstance.userLists[i].name
            }
        }
        return currentName
    }
    
    /* リクエストされたのユーザーIDの名前を返す */
    func getNameAtRequestUserID(reqUserId:String)->String{
        var currentName:String = ""
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==reqUserId{
                
                currentName = UserInfoManager.sharedInstance.userLists[i].name
            }
        }
        return currentName
    }
    
    /* リクエストされたのユーザーIDのTokenを返す */
    func getTokenAtRequestUserID(reqUserId:String)->String{
        var currentToken:String = ""
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==reqUserId{
                
                currentToken = UserInfoManager.sharedInstance.userLists[i].userToken
            }
        }
        return currentToken
    }
    
    /* 現在のユーザーIDを見つけて名前を入れる */
    func setUniqueUserIdAtCurrentUserID(uniqueUserId:String){
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                
                UserInfoManager.sharedInstance.userLists[i].uniqueUserId = uniqueUserId
            }
        }
    }
    
    /* 現在のユーザーIDのユーザーが作成したユーザーIDを返す */
    func getUniqueUserIdAtCurrentUserID()->String{
        var uniqueUserId:String = ""
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                
                uniqueUserId = UserInfoManager.sharedInstance.userLists[i].uniqueUserId
            }
        }
        return uniqueUserId
    }
    
    /* リクエストされたのユーザーIDのユーザーが作成したユーザーIDを返す */
    func getUniqueUserIdAtRequestUserID(reqUserId:String)->String{
        var uniqueUserId:String = ""
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==reqUserId{
                
                uniqueUserId = UserInfoManager.sharedInstance.userLists[i].uniqueUserId
            }
        }
        return uniqueUserId
    }
    
    /* 現在のユーザーのTaskIDを返す */
    func getTaskIdAtCurrentUserID()->String{
        var currentTaskId:String = ""
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                
                currentTaskId = UserInfoManager.sharedInstance.userLists[i].taskId
            }
        }
        return currentTaskId
    }
    
    /* 現在のユーザーの生成日(createdAt)を返す */
    func getCreatedAtAtCurrentUserID()->Timestamp{
        var currentCreatedAt:Timestamp = Timestamp(date:Date())
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                
                currentCreatedAt = UserInfoManager.sharedInstance.userLists[i].createdAt
            }
        }
        return currentCreatedAt
    }
    
    /* 現在のユーザーの更新日(updatedAt)を返す */
    func getUpdatedAtAtCurrentUserID()->Timestamp{
        var currentUpdatedAt:Timestamp = Timestamp(date:Date())
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                
                currentUpdatedAt = UserInfoManager.sharedInstance.userLists[i].updatedAt
            }
        }
        return currentUpdatedAt
    }
    
    /* 現在のユーザーの友達リストの数を返す */
    func getFriendCountAtCurrentUserID()->Int{
        var currentFriendCount:Int = 0
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                currentFriendCount = UserInfoManager.sharedInstance.userLists[i].friendIds.count
            }
        }
        return currentFriendCount
    }
    
    /* 指定されたユーザーを現在のユーザーの友達リストに追加 */
    func appendFriendAtCurrentUserID(friendUserId:String){
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                UserInfoManager.sharedInstance.userLists[i].friendIds.append(friendUserId)
            }
        }
    }
    
    /* 現在のユーザーの参加グループリストの数を返す */
    func getGroupIdsCountAtCurrentUserID()->Int{
        var currentGroupIdsCount:Int = 0
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                currentGroupIdsCount = UserInfoManager.sharedInstance.userLists[i].groupIds.count
            }
        }
        return currentGroupIdsCount
    }
    
    /* 指定されたグループのタスクIdを現在のユーザーの参加グループリストに追加 */
    func appendGroupIdsAtCurrentUserID(groupId:String){
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                UserInfoManager.sharedInstance.userLists[i].groupIds.append(groupId)
            }
        }
    }
    
    /* 指定されたグループのタスクIdを指定されたユーザーの参加グループリストに追加 */
    func appendGroupIdsAtRequestUserID(groupId:String, reqUserId:String){
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==reqUserId{
                UserInfoManager.sharedInstance.userLists[i].groupIds.append(groupId)
            }
        }
    }
    
    /* 現在のユーザーのクラスの実体を返す */
    func getUserInfoAtCurrentUserID()->UserInfo{
        var currentListNum:Int = 0
        
        for i in 0 ..< UserInfoManager.sharedInstance.getUserListsCount() {
            if UserInfoManager.sharedInstance.userLists[i].userID==String(describing:Auth.auth().currentUser?.uid){
                currentListNum = i
            }
        }
        return UserInfoManager.sharedInstance.userLists[currentListNum]
    }
    
    /*
    /* ユーザーリストを保存 */
    func saveUserInfo(){
        UserInfoRepository.saveUserInfoUserDefaults(userInfo:userLists)
    }
    
    /* ユーザーリストを読込 */
    func loadUserInfo(){
        self.userLists = UserInfoRepository.loadUserInfoUserDefaults()
    }
    */
}

//----------------------------------------------------
//  グループ管理タスク
//----------------------------------------------------
class GroupMemberNamesInfo:Codable{
    var groupMemberNames:String     //メンバー名
    var status:Bool                 //true(話しができる)/false(話ができない)
    var statusMessage:String        //詳細なステータス
    var alwaysPushEnable:Bool       //true(常に通知を行う)/false(常に通知は行わない)
    
    init(groupMemberNames:String, status:Bool, statusMessage:String, alwaysPushEnable:Bool) {
        self.groupMemberNames = groupMemberNames
        self.status = false
        self.statusMessage = statusMessage
        self.alwaysPushEnable = alwaysPushEnable
    }
}

class GroupMemberTalksInfo:Codable{
    var groupMemberNames:String             //発言者のユーザーID
    var groupMemberTalks:String             //発言した内容
    var groupMemberTalksCreatedAt:Timestamp //発言のあった日
    var groupId:String                      //このtalkが行われたグループのId
    var talkId:String                       //talkのId
    
    init(groupMemberNames:String, groupMemberTalks:String, groupMemberTalksCreatedAt:Timestamp, groupId:String, talkId:String) {
        self.groupMemberNames = groupMemberNames
        self.groupMemberTalks = groupMemberTalks
        self.groupMemberTalksCreatedAt = groupMemberTalksCreatedAt
        self.groupId = groupId
        self.talkId = talkId
    }
}

class GroupInfo:Codable{
    var taskId:String
    var groupName:String
    var GroupMemberNamesInfo:[GroupMemberNamesInfo]
    var groupMemberTalksInfo:[GroupMemberTalksInfo]
    
    var createdAt:Timestamp
    var updatedAt:Timestamp
    
    init(taskId:String, groupName:String, GroupMemberNamesInfo:[GroupMemberNamesInfo], groupMemberTalksInfo:[GroupMemberTalksInfo], createdAt:Timestamp, updatedAt:Timestamp){
        self.taskId = taskId
        self.groupName = groupName
        self.GroupMemberNamesInfo = GroupMemberNamesInfo        //グループメンバーのId+Status群
        self.groupMemberTalksInfo = groupMemberTalksInfo
        
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

protocol GroupInfoDelegate:class{
    /* NoAction */
}

class GroupInfoManager{
    static let sharedInstance = GroupInfoManager()
    
    var groupInfo:[GroupInfo] = [GroupInfo(
            taskId:"",
            groupName:"",
            GroupMemberNamesInfo: [GroupMemberNamesInfo.init(groupMemberNames: "", status:false, statusMessage:"", alwaysPushEnable:false)],
            //groupMemberTalks:[""],
            groupMemberTalksInfo: [GroupMemberTalksInfo.init(groupMemberNames: "", groupMemberTalks: "",
                                                             groupMemberTalksCreatedAt: Timestamp(date:Date()), groupId:"", talkId:"")],
            createdAt:Timestamp(date:Date()),
            updatedAt:Timestamp(date:Date()))]
    weak var delegate:GroupInfoDelegate?
    
    /* グループリストの数を取得 */
    func getGroupInfoCount() -> Int{
        return self.groupInfo.count
    }
    
    /* 指定したグループを取得 */
    func getGroupInfo(num:Int)->GroupInfo{
        return self.groupInfo[num]
    }
    
    /* グループを追加 */
    func appendGroupInfo(groupInfo:GroupInfo){
        self.groupInfo.append(groupInfo)
    }
    
    /* 指定したグループのメッセージ情報を追加 */
    func appendGroupInfoTalksInfo(num:Int, messageInfo:GroupMemberTalksInfo){
        self.groupInfo[num].groupMemberTalksInfo.append(messageInfo)
    }
    
    /* 指定したtaskIdのグループのメッセージ情報を追加 */
    func appendGroupInfoTalksInfoAtRequestTaskId(reqTaskId:String, messageInfo:GroupMemberTalksInfo){
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            if GroupInfoManager.sharedInstance.groupInfo[i].taskId==reqTaskId{
                //GroupInfoManager.sharedInstance.groupInfo[i].groupMemberTalksInfo.append(messageInfo)
                self.groupInfo[i].groupMemberTalksInfo.append(messageInfo)
                break
            }
        }
    }
    
    /* 指定したtaskIdのグループの実態を返す */
    func getGroupInfoAtRequestTaskId(reqTaskId:String)->GroupInfo{
        var reqIdListNum:Int = 0
        
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            if GroupInfoManager.sharedInstance.groupInfo[i].taskId==reqTaskId{
                reqIdListNum = i
            }
        }
        return GroupInfoManager.sharedInstance.groupInfo[reqIdListNum]
    }
    
    /* グループを削除 */
    func removeGroupInfo(num:Int){
        self.groupInfo.remove(at: num)
    }
    
    /* 指定したtaskIdのグループの名前を返す*/
    func getGroupNamgeAtRequestTaskId(reqTaskId:String) -> String{
        var resultGroupName:String = ""
        
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            if GroupInfoManager.sharedInstance.groupInfo[i].taskId==reqTaskId{
                resultGroupName = GroupInfoManager.sharedInstance.groupInfo[i].groupName
                break
            }
        }
        return resultGroupName
    }
    
    /* 引数で渡されたGrNoのトーク情報の最初5つ分を空で埋める */
    func createGroupTalkTopAllay(groupNum:Int){
        let initMessageInfo:GroupMemberTalksInfo = GroupMemberTalksInfo.init(groupMemberNames: UserInfoManager.sharedInstance.getCurrentUserID(), groupMemberTalks: "", groupMemberTalksCreatedAt: Timestamp(), groupId: GroupInfoManager.sharedInstance.getGroupInfo(num: groupNum).taskId, talkId:"")
        for _ in 0 ..< 5 {
            GroupInfoManager.sharedInstance.appendGroupInfoTalksInfo(num: groupNum, messageInfo: initMessageInfo)
        }
    }
    
    /* 引数で渡されたGrNoのトーク情報の最初5つ分を空で埋める */
    func initGroupTalkInfo(){
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            GroupInfoManager.sharedInstance.getGroupInfo(num: i).groupMemberTalksInfo.removeAll()
            GroupInfoManager.sharedInstance.createGroupTalkTopAllay(groupNum: i)
        }
    }
    
    // タップされたindexPathから現在のグループ番号を取得する関数
    func getCurrentGroupNumberFromTappedGroup(tappedIndexPathRow:Int)->Int{
        let detailedGroupId:String = UserInfoManager.sharedInstance.getUserInfoAtCurrentUserID().groupIds[tappedIndexPathRow]
        var resultGroupNo:Int = 0
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfoCount() {
            if detailedGroupId==GroupInfoManager.sharedInstance.getGroupInfo(num: i).taskId{
                resultGroupNo = i
                break
            }
        }
        
        return resultGroupNo
    }
    
    // 引数でリクエストされたグループ内の現在のユーザーIDのステータスを取得する関数
    func getCurrentUserStatusInReqGroup(reqGroupNo:Int)->Bool{
        //var currentGroupNo:Int = 0
        var currentUserStatus:Bool = false
        
        //グループ番号取得
        //currentGroupNo = getCurrentGroupNumberFromTappedGroup()
        
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: reqGroupNo).GroupMemberNamesInfo.count{
            if GroupInfoManager.sharedInstance.getGroupInfo(num: reqGroupNo).GroupMemberNamesInfo[i].groupMemberNames==UserInfoManager.sharedInstance.getCurrentUserID(){
                currentUserStatus = GroupInfoManager.sharedInstance.getGroupInfo(num: reqGroupNo).GroupMemberNamesInfo[i].status
                break
            }
        }
        
        return currentUserStatus
    }
    
    // 引数でリクエストされたグループ内の現在のユーザーIDのステータスを変更する関数
    func setCurrentUserStatusInCurrentGroup(reqGroupNo:Int, status:Bool){
        //var currentGroupNo:Int = 0
        
        //グループ番号取得
        //currentGroupNo = getCurrentGroupNumberFromTappedGroup()
        
        for i in 0 ..< GroupInfoManager.sharedInstance.getGroupInfo(num: reqGroupNo).GroupMemberNamesInfo.count{
            if GroupInfoManager.sharedInstance.getGroupInfo(num: reqGroupNo).GroupMemberNamesInfo[i].groupMemberNames==UserInfoManager.sharedInstance.getCurrentUserID(){
                GroupInfoManager.sharedInstance.getGroupInfo(num: reqGroupNo).GroupMemberNamesInfo[i].status = status
                break
            }
        }
    }
    
    /*
    /* グループリストを保存 */
    func saveGroupInfo(){
        GroupInfoRepository.saveGroupInfoUserDefaults(groupInfo:groupInfo)
    }
    
    /* グループリストを読込 */
    func loadGroupInfo(){
        self.groupInfo = GroupInfoRepository.loadGroupInfoUserDefaults()
    }
    */
}

//----------------------------------------------------
//  ShareSheet用クラス(UIActivityItemSourceに準拠したものを返す)
//----------------------------------------------------
class ShareItem<T>: NSObject, UIActivityItemSource {
    
    private let item: T
    
    init(_ item: T) {
        self.item = item
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return item
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return activityViewControllerPlaceholderItem(activityViewController)
    }
    
    /*
    @available(iOS 13.0, *)
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        
        let metadata = LPLinkMetadata()
        metadata.title = "Mikke!"
        metadata.originalURL = NSURL(string: "https://www.yahoo.co.jp/")! as URL
        
        return metadata
    }
    */
}

//----------------------------------------------------
//  IDチェック戻り値用enum型
//----------------------------------------------------
enum ResultUniqueId: String {
    case sameId = "既に使用済みのID"
    case eregularId = "半角英数以外のID"
    case availableId = "使用可能なID"
}

//----------------------------------------------------
//  各種extension
//----------------------------------------------------
extension UIImage{
    //画像をリサイズする処理
    func resize(toWidth width:CGFloat) ->UIImage?{
        //描画するサイズを指定
        //let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        let canvasSize = CGSize(width: width, height: width)    //正方形に！
        
        //Contextを開始
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        
        //遅延実行(defer内部で書かれた処理は、スコープを抜けるときに呼ばれる)
        defer {
            //Contextを終了
            UIGraphicsEndImageContext()
        }
        //指定されたサイズのCGRectで描画
        draw(in: CGRect(origin: .zero, size: canvasSize))
        
        //リサイズされた画像を戻り値として返す
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIViewController{
    //保存先のRefを取得する関数
    func getUserRef() -> StorageReference{
        //CloudStorageをインスタンス化
        let storage = Storage.storage()
        
        //ルートのレファレンスを作成
        let storageRef = storage.reference()
        
        //ユーザーIDを取得
        let userId = UserInfoManager.sharedInstance.getCurrentUserID()
        
        //"ユーザーID.png"の名前のレファレンスを取得
        let userRef = storageRef.child("userImages/\(userId).png")
        
        return userRef
    }
    
    //引数で指定されたユーザーIDの保存先のRefを取得する関数
    func getRequestUserRef(userId:String) -> StorageReference{
        //CloudStorageをインスタンス化
        let storage = Storage.storage()
        
        //ルートのレファレンスを作成
        let storageRef = storage.reference()
        
        //"ユーザーID.png"の名前のレファレンスを取得
        let userRef = storageRef.child("userImages/\(userId).png")
        
        return userRef
    }
    
}
