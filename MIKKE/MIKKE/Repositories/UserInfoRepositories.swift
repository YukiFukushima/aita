//
//  UserInfoRepositories.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/23.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import Foundation

//各ユーザー情報に格納されているグループ情報を更新するフラグの記憶用(現在は未使用)
class UserGroupUpdateRepository {
    // UserDefaults に使うキー
    static let userGroupUpdateSelectsKey:String = "user_group_update"
    
    static func saveUserGroupUpdateDefaults(goUpdate:Bool){
        //UserDefaultsに保存
        UserDefaults.standard.set(goUpdate, forKey: userGroupUpdateSelectsKey)
        
    }
    
    static func loadUserGroupUpdateDefaults()->Bool{
        //UserDefaultsから読み出し
        let goUpdate = UserDefaults.standard.bool(forKey: userGroupUpdateSelectsKey)
        
        return goUpdate
    }
}

//ユーザーTokenの記憶用
class UserTokenRepository {
    // UserDefaults に使うキー
    static let userTokenSelectsKey:String = "user_token"

    static func saveUserTokenUserDefaults(userToken:String){
        //Data型に変換処理
        let encorder = JSONEncoder()
        let data = try! encorder.encode(userToken)
        
        //UserDefaultsに保存
        UserDefaults.standard.set(data, forKey: userTokenSelectsKey)
        
    }

    static func loadUserTokenUserDefaults()->String{
        let decorder = JSONDecoder()
        
        //UserDefaultsから読み出し
        guard let data = UserDefaults.standard.data(forKey: userTokenSelectsKey)else{ return "" }
        
        //dataから[UserInfo]に変換
        let userToken = try! decorder.decode(String.self, from: data)
        
        return userToken
    }
}

//初期画面完了フラグの記憶用
class InitViewCompleteRepository {
    // UserDefaults に使うキー
    static let initViewCompleteSelectsKey:String = "init_view_complete"
    
    static func saveInitViewCompleteDefaults(initComplete:Bool){
        //UserDefaultsに保存
        UserDefaults.standard.set(initComplete, forKey: initViewCompleteSelectsKey)
        
    }
    
    static func loadInitViewCompleteDefaults()->Bool{
        //UserDefaultsから読み出し
        let initComplete = UserDefaults.standard.bool(forKey: initViewCompleteSelectsKey)
        
        return initComplete
    }
}

//チュートリアル画面完了フラグの記憶用
class TutorialViewCompleteRepository {
    // UserDefaults に使うキー
    static let tutorialViewCompleteSelectsKey:String = "tutorial_view_complete"
    
    static func saveTutorialViewCompleteDefaults(tutorialComplete:Bool){
        //UserDefaultsに保存
        UserDefaults.standard.set(tutorialComplete, forKey: tutorialViewCompleteSelectsKey)
        
    }
    
    static func loadTutorialViewCompleteDefaults()->Bool{
        //UserDefaultsから読み出し
        let tutorialComplete = UserDefaults.standard.bool(forKey: tutorialViewCompleteSelectsKey)
        
        return tutorialComplete
    }
}

/*
//ユーザー情報の記憶用
class UserInfoRepository {
    // UserDefaults に使うキー
    static let userInfoSelectsKey:String = "user_info"

    static func saveUserInfoUserDefaults(userInfo:[UserInfo]){
        //Data型に変換処理
        let encorder = JSONEncoder()
        let data = try! encorder.encode(userInfo)
        
        //UserDefaultsに保存
        UserDefaults.standard.set(data, forKey: userInfoSelectsKey)
        
    }

    static func loadUserInfoUserDefaults()->[UserInfo]{
        let decorder = JSONDecoder()
        
        //UserDefaultsから読み出し
        guard let data = UserDefaults.standard.data(forKey: userInfoSelectsKey)else{ return [] }
        
        //dataから[UserInfo]に変換
        let userInfo = try! decorder.decode([UserInfo].self, from: data)
        
        return userInfo
    }
}

//グループ情報の記憶用
class GroupInfoRepository {
    // UserDefaults に使うキー
    static let groupInfoSelectsKey:String = "group_info"

    static func saveGroupInfoUserDefaults(groupInfo:[GroupInfo]){
        //Data型に変換処理
        let encorder = JSONEncoder()
        let data = try! encorder.encode(groupInfo)
        
        //UserDefaultsに保存
        UserDefaults.standard.set(data, forKey: groupInfoSelectsKey)
        
    }

    static func loadGroupInfoUserDefaults()->[GroupInfo]{
        let decorder = JSONDecoder()
        
        //UserDefaultsから読み出し
        guard let data = UserDefaults.standard.data(forKey: groupInfoSelectsKey)else{ return [] }
        
        //dataから[UserInfo]に変換
        let groupInfo = try! decorder.decode([GroupInfo].self, from: data)
        
        return groupInfo
    }
}
*/

