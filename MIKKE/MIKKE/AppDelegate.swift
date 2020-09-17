//
//  AppDelegate.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/23.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseMessaging
import UserNotificationsUI
import Firebase
import IQKeyboardManagerSwift
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var notificationGranted = true
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        
        //Firebase Cloud Messaging用
        if #available(iOS 13.5, *){
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
            
            let authOptions:UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in})
        }else{
            let settings:UIUserNotificationSettings = UIUserNotificationSettings(types:[.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]){
            (granted, error) in
            self.notificationGranted = granted
            if let error = error{
                print("granted, but Error in notifacation permission:\(error.localizedDescription)")
            }
        }
        //Firebase Cloud Messaging用終わり
        
        //端末毎のTokenの取得
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error{
                print("Error fetching remote instance ID:\(error)")
            }else if let result = result{
                print("Remote instance ID token:\(result.token)")
                UserTokenRepository.saveUserTokenUserDefaults(userToken: result.token)
            }
        }
        
        //registerForPushNotifications()                        /* もう一つのPush通知の方法(うまくいかなかった) */
        
        UIApplication.shared.applicationIconBadgeNumber = 0     /* バッジを消す */
        IQKeyboardManager.shared.enable = true                  /* キーボード自動調整 */
        IQKeyboardManager.shared.enableAutoToolbar = false      /* ツールバーを消す */
        
        return true
    }
    
    /*
    //もう一つのPush通知の方法(うまくいかなかった)
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            // 1. Check if permission granted
            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    */
    
    /*
    //もう一つのPush通知の方法(うまくいかなかった)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 1. Convert device token to string
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        // 2. Print device token to use for PNs payloads
        print("Device Token: \(token)")
        
        UserTokenRepository.saveUserTokenUserDefaults(userToken: token)
    }
     
    //もう一つのPush通知の方法(うまくいかなかった)
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // 1. Print out error if PNs registration not successful
        print("Failed to register for remote notifications with error: \(error)")
    }
    */
    
    //Firebase Cloud Messaging用
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        if let messageID = userInfo["gcm.message_id"]{
            print("MessageID:\(messageID)")
        }
        //print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let messageID = userInfo["gem.message_id"]{
            print("MessageID:\(messageID)")
        }
        //print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    //Firebase Cloud Messaging用終わり
    
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

//Firebase Cloud Messaging用
@available(iOS 10, *)
extension AppDelegate:UNUserNotificationCenterDelegate{
    // アプリがフォアグラウンドで起動している際にプッシュ通知が届いたら呼ばれる。
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let messageID = userInfo["gcm.message_id"]{
            print("Message ID:\(messageID)")
        }
        
        //title取得
        let userTitle = notification.request.content.title
        
        //updateフラグを上げる
        if userTitle=="招待されました"{
            UserGroupUpdateRepository.saveUserGroupUpdateDefaults(goUpdate: true)
            
            /*
            var window:UIWindow?
            window = UIWindow(frame: UIScreen.main.bounds)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(identifier: "GroupTableView")
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
            */
        }
        //print(userInfo)
        
        completionHandler([])
    }
    
    // プッシュ通知に対しタッチ等のアクションを行った時に呼ばれる。
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let messageID = userInfo["gcm.message_id"]{
            print("Message ID:\(messageID)")
        }
        
        //title取得
        let userTitle = response.notification.request.content.title
        print("Title:"+userTitle)
        
        //updateフラグを上げる
        if userTitle=="招待されました"{
            UserGroupUpdateRepository.saveUserGroupUpdateDefaults(goUpdate: true)
            
            /*
            var window:UIWindow?
            window = UIWindow(frame: UIScreen.main.bounds)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(identifier: "GroupTableView")
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
            */
        }
        //print(userInfo)
        
        completionHandler()
    }
}
//Firebase Cloud Messaging用終わり

