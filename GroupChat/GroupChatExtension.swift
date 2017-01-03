//
//  GroupChatExtension.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import UIKit
import ALLoadingView

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
    func showAlert(title: String, message: String, action: [UIAlertAction]) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for actionItem in action {
            alertController.addAction(actionItem)
        }
        self.present(alertController, animated: true, completion: nil)
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
    func showNetworkLoader(messageText: String, shouldUseBlurredBG: Bool, font: UIFont) {
        isNetworkActivityIndicatorVisible = true
        
        ALLoadingView.manager.messageText = messageText
        ALLoadingView.manager.messageFont = font
        ALLoadingView.manager.blurredBackground = shouldUseBlurredBG
        ALLoadingView.manager.showLoadingView(ofType: .messageWithIndicator, windowMode: .fullscreen, completionBlock: nil)
    }
    func hideNetworkLoader(delay: TimeInterval, completionBlock: @escaping(_ completed: Bool) -> Void) {
        ALLoadingView.manager.hideLoadingView(withDelay: delay) {
            self.isNetworkActivityIndicatorVisible = false
            completionBlock(true)
        }
    }
    func hideNetworkLoaderWithoutCompletionHandler() {
        ALLoadingView.manager.hideLoadingView()
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
//    func crop(toWidth: CGFloat, toHeight: CGFloat) -> UIImage? {
//        let toHeight = size.height / size.width * toWidth
//        return crop(toWidth: toWidth, toHeight: toHeight)
//    }
    /// Returns a image that fills in newSize
    func resizedImage(newSize: CGSize) -> UIImage {
        // Guard newSize is different
        guard self.size != newSize else { return self }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        draw(in: CGRect(x: 0.0, y: 0.0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /// Returns a resized image that fits in rectSize, keeping it's aspect ratio
    /// Note that the new image size is not rectSize, but within it.
    func resizedImageWithinRect(rectSize: CGSize) -> UIImage {
        let widthFactor = size.width / rectSize.width
        let heightFactor = size.height / rectSize.height
        
        var resizeFactor = widthFactor
        if size.height > size.width {
            resizeFactor = heightFactor
        }
        let newSize = CGSize(width: size.width/resizeFactor, height: size.height/resizeFactor)
        let resized = resizedImage(newSize: newSize)
        return resized
    }
}
