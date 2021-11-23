//
//  SendMessages.swift
//  MIKKE
//
//  Created by 福島悠樹 on 2020/07/30.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import Foundation

//Push通知用
class SendMessage {
    static func sendMessageToUser(userIdToken:String, title:String, body:String){
        let serverKey:String = "AAAAjvB7MVs:APA91bGaz801RdvVaGPp8YxtgyFqzzv-FJVw1sP7LRGqvpHpDPwBHv47ZylkPVn3rx8MI5CIAc7D2tqdt38W2sFhJXy013G03tkMfeaABYLqhiTIyKj6FEz6T_x6gUdQCSQLEauoDnG4"
        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        let userIdToken:String = userIdToken
        var request = URLRequest(url: url)               //Requestを生成
        
        let postMessage: [String: Any] = [
            "to": userIdToken,
            "priority": "high",         // highにするとアプリが非起動時・バックグラウンドでも通知が来る
            "content_available" : true, // こうすることでバックグラウンド時にdidReceiveRemoteNotificationが呼ばれる
            "notification": [
                "badge": 1,
                "body": body,
                "title": title
            ]
        ]
        
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        
        do {
           request.httpBody = try JSONSerialization.data(withJSONObject: postMessage, options: JSONSerialization.WritingOptions())
           print("Succeeded serialization.: \(postMessage)")
        } catch {
           print("Failed serialization.: \(error)")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in

           if let realResponse = response as? HTTPURLResponse {
               if realResponse.statusCode == 200 {
                   print("Succeeded post!")
               } else {
                   print("Failed post: \(realResponse.statusCode)")
               }
           }

           if let getString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as String? {
               print("notification_key: \(getString)")
           }
        }

        task.resume()
    }
}

