//
//  GroupChatExtension.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.

import Foundation
import UIKit
import KRProgressHUD
import SwiftMessages

extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
}
extension UIViewController {
    func showAlert(title: String, message: String, notiType: Theme) {
        let errorView = MessageView.viewFromNib(layout: .CardView)
        errorView.configureTheme(notiType)
        // Set message title, body, and icon. Here, we're overriding the default warning
        errorView.configureContent(title: title, body: message)
        
        // Hide the button
        errorView.button?.isHidden = true
        
        // Add a drop shadow.
        errorView.configureDropShadow()
        SwiftMessages.show(view: errorView)
    }
    func popToSignInSignOutScreen() {
        let controllersArray = navigationController?.viewControllers
        for controller in controllersArray! {
            if controller.isKind(of: SignInSignUpViewController.classForCoder()) {
                _ = navigationController?.popToViewController(controller, animated: true)
            }
        }
    }
}

extension UIApplication {
    func showNetworkLoader(messageText: String) {
        isNetworkActivityIndicatorVisible = true
        KRProgressHUD.show(progressHUDStyle: .black, message: messageText)
    }
    func hideNetworkLoader() {
        KRProgressHUD.dismiss()
        self.isNetworkActivityIndicatorVisible = false
    }
}
extension UIDevice {
    var iPhone: Bool {
        return UIDevice().userInterfaceIdiom == .phone
    }
    enum ScreenType: String {
        case iPhone4
        case iPhone5
        case iPhone6
        case iPhone6Plus
        case unknown
    }
    var screenType: ScreenType {
        guard iPhone else { return .unknown }
        switch UIScreen.main.nativeBounds.height {
        case 960:
            return .iPhone4
        case 1136:
            return .iPhone5
        case 1334:
            return .iPhone6
        case 2208:
            return .iPhone6Plus
        default:
            return .unknown
        }
    }
}
extension UIImage {
    func imageWithImage (sourceImage:UIImage, scaledToWidth: CGFloat) -> UIImage {
        let oldWidth = sourceImage.size.width
        let scaleFactor = scaledToWidth / oldWidth
        
        let newHeight = sourceImage.size.height * scaleFactor
        let newWidth = oldWidth * scaleFactor
        
        UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
        sourceImage.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
extension String {
    func aesEncrypt(key: String, iv: String) -> String{
        return FBEncryptorAES.encryptBase64String(iv, keyString: key, separateLines: false)
    }
    func aesDecrypt(key: String, iv: String) -> String {
        return FBEncryptorAES.decryptBase64String(iv, keyString: key)
    }
}
