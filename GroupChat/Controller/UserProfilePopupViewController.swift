//
//  UserProfilePopupViewController.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 06/01/17.

import UIKit

class UserProfilePopupViewController: UIViewController {

    // MARK: - IBOutlets
//    @IBOutlet weak var lblEmail: UILabel!
//    @IBOutlet weak var lblUserName: UILabel!
//    @IBOutlet weak var imgButton: UIButton! {
//        didSet {
//            imgButton.clipsToBounds = true
//            imgButton.layer.cornerRadius = imgButton.frame.size.width / 2.0
//            imgButton.layer.borderColor = UIColor.white.cgColor
//            imgButton.layer.borderWidth = 2.0
//            imgButton.layer.masksToBounds = true
//        }
//    }
    @IBOutlet weak var bannerImageView: UIImageView!
    
    // MARK: Variable
    static var image: UIImage!
    static var uEmail: String?
    static var uName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UserProfilePopupViewController.image != nil {
//            imgButton.setImage(UserProfilePopupViewController.image, for: .normal)
//            imgButton.contentMode = .scaleAspectFill
            bannerImageView.image = UserProfilePopupViewController.image
            
//            lblUserName.text = UserProfilePopupViewController.uName
//            lblEmail.isHidden = UserProfilePopupViewController.uEmail == nil
//            if UserProfilePopupViewController.uEmail != nil {
//                lblEmail.text = UserProfilePopupViewController.uEmail
//            }
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    class func instance(userImage: UIImage, userName: String, userEmail: String?, onlineStatus: Bool) -> UserProfilePopupViewController {
        let vc = UserProfilePopupViewController(nibName: "UserProfilePopupViewController", bundle: nil)
        image = userImage
        uName = userName
        uEmail = userEmail
        return vc
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
extension UserProfilePopupViewController: PopupContentViewController {
    func sizeForPopup(_ popupController: PopupController, size: CGSize, showingKeyboard: Bool) -> CGSize {
//        if UserProfilePopupViewController.uEmail == nil {
//            return CGSize(width: 320,height: 200)
//        }
        return CGSize(width: 320,height: 250)
    }
}
