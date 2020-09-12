//
//  TaskQRCodeViewController.swift
//  TaskFirebaseAuthApp2
//
//  Created by 福島悠樹 on 2020/06/24.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import FirebaseAuth
import CoreImage

class TaskQRCodeViewController: UIViewController {

    @IBOutlet weak var qrCodeImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        makeQRCode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    //QRCodeの作成と表示
    func makeQRCode(){
        let userID:String = String(describing:Auth.auth().currentUser?.uid)
        //let stringQRCode:String = userID+"fukushima"
        let stringQRCode:String = userID

        // NSString から NSDataへ変換
        guard let transStringQRCode = stringQRCode.data(using: String.Encoding.utf8) else{ return }
        
        // QRコード生成のフィルター
        // NSData型でデーターを用意
        // inputCorrectionLevelは、誤り訂正レベル
        guard let qr = CIFilter(name: "CIQRCodeGenerator", parameters: ["inputMessage": transStringQRCode, "inputCorrectionLevel": "M"]) else{return}
        let sizeTransform = CGAffineTransform(scaleX: 10, y: 10)
        guard let ciImage = qr.outputImage?.transformed(by: sizeTransform)else{ return }
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)else{ return }
        
        qrCodeImageView.image = UIImage(cgImage:cgImage)
    }
}
