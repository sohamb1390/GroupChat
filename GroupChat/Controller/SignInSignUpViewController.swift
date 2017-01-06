//
//  SignInSignUpViewController.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import OpinionzAlertView
import JJMaterialTextField
import SwiftMessages

enum Mode: String {
    case SignIn = "SignIn", SignUp = "SignUp"
}

class SignInSignUpViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak var btnSignInSignUp: UIButton!
    @IBOutlet weak var btnPhoto: UIButton! {
        didSet {
            btnPhoto.clipsToBounds = true
            btnPhoto.layer.cornerRadius = btnPhoto.frame.size.width / 2.0
            btnPhoto.layer.borderColor = UIColor.white.cgColor
            btnPhoto.layer.borderWidth = 2.0
            btnPhoto.layer.masksToBounds = true
        }
    }
    
    @IBOutlet weak var signInUserEmailTextField: JJMaterialTextfield! {
        didSet {
            signInUserEmailTextField.returnKeyType = .next
            signInUserEmailTextField.keyboardType = .emailAddress
            signInUserEmailTextField.delegate = self
            signInUserEmailTextField.adjustsFontForContentSizeCategory = true
            signInUserEmailTextField.attributedPlaceholder = NSAttributedString(string: "Email ID",
                                                                   attributes: [NSForegroundColorAttributeName: UIColor.white])
        }
    }
    @IBOutlet weak var signUpUserEmailTextField: JJMaterialTextfield! {
        didSet {
            signUpUserEmailTextField.returnKeyType = .next
            signUpUserEmailTextField.keyboardType = .emailAddress
            signUpUserEmailTextField.delegate = self
            signUpUserEmailTextField.adjustsFontForContentSizeCategory = true
            signUpUserEmailTextField.attributedPlaceholder = NSAttributedString(string: "Email ID",
                                                                                attributes: [NSForegroundColorAttributeName: UIColor.white])
        }
    }
    @IBOutlet weak var userNameTextField: JJMaterialTextfield! {
        didSet {
            userNameTextField.returnKeyType = .next
            userNameTextField.keyboardType = .default
            userNameTextField.delegate = self
            userNameTextField.adjustsFontForContentSizeCategory = true
            userNameTextField.attributedPlaceholder = NSAttributedString(string: "Username",
                                                                          attributes: [NSForegroundColorAttributeName: UIColor.white])

        }
    }
    @IBOutlet weak var signInPwdTextField: JJMaterialTextfield! {
        didSet {
            signInPwdTextField.isSecureTextEntry = true
            signInPwdTextField.returnKeyType = .next
            signInPwdTextField.delegate = self
            signInPwdTextField.adjustsFontForContentSizeCategory = true
            signInPwdTextField.attributedPlaceholder = NSAttributedString(string: "Password",
                                                                         attributes: [NSForegroundColorAttributeName: UIColor.white])

        }
    }
    @IBOutlet weak var signUpPwdTextField: JJMaterialTextfield! {
        didSet {
            signUpPwdTextField.isSecureTextEntry = true
            signUpPwdTextField.returnKeyType = .next
            signUpPwdTextField.delegate = self
            signUpPwdTextField.adjustsFontForContentSizeCategory = true
            signUpPwdTextField.attributedPlaceholder = NSAttributedString(string: "Password",
                                                                    attributes: [NSForegroundColorAttributeName: UIColor.white])
            
        }
    }
    
    @IBOutlet weak var retypePwdTextField: JJMaterialTextfield! {
        didSet {
            retypePwdTextField.isSecureTextEntry = true
            retypePwdTextField.returnKeyType = .next
            retypePwdTextField.delegate = self
            retypePwdTextField.adjustsFontForContentSizeCategory = true
            retypePwdTextField.attributedPlaceholder = NSAttributedString(string: "Retype your password",
                                                                    attributes: [NSForegroundColorAttributeName: UIColor.white])

        }
    }
    @IBOutlet weak var signInViewXConstraint: NSLayoutConstraint!
    @IBOutlet weak var signUpViewXConstraint: NSLayoutConstraint!
    @IBOutlet weak var signInBlurViewYConstraint: NSLayoutConstraint!
    @IBOutlet weak var signUpBlurViewYConstraint: NSLayoutConstraint!

    
    // MARK: Variables
    var viewModel: GroupChatViewModel?
    var currentMode: Mode = .SignIn
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationItem.hidesBackButton = true
        
        // Initialise View Model
        viewModel = GroupChatViewModel()
        
        // Token Refresh
        UIApplication.shared.showNetworkLoader(messageText: "Existing Session")
        
        viewModel!.tokenRefresh { (error, isEmailVerified) in
            UIApplication.shared.hideNetworkLoader()
            if error == nil, isEmailVerified {
                self.performSegue(withIdentifier: SegueConstants.groupListSegue, sender: self)
            }
        }
        // Register Keyboard observer only for smaller devices
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardAppeared(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDismissed(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        signUpViewXConstraint.constant = -view.frame.size.width
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        btnPhoto.isHidden = btnSignInSignUp.tag == 1
    }
    override func viewWillDisappear(_ animated: Bool) {
        if UIDevice().screenType == .iPhone5 || UIDevice().screenType == .iPhone4 {
            // Remove Keyboard observers
            NotificationCenter.default.removeObserver(self)
        }
        super.viewWillDisappear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    // MARK: SignIn, SignUp
    @IBAction func changeMode(sender: UIButton) {
        switch currentMode {
        case .SignIn:
            currentMode = .SignUp
            signInViewXConstraint.constant = -view.frame.size.width
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            }, completion: { (animated) in
                self.signUpViewXConstraint.constant = 0.0
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.layoutIfNeeded()
                })
            })
            break
        case .SignUp:
            currentMode = .SignIn
            self.signUpViewXConstraint.constant = -self.view.frame.size.width

            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            }, completion: { (animated) in
                self.signInViewXConstraint.constant = 0.0
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.layoutIfNeeded()
                })
            })
        }
        
        // Change states of UILabel & UIbutton
        changeState()
    }
    
    @IBAction func toggleSignInSignUp(_ sender: UIButton) {
        switch currentMode {
        case .SignIn:
            guard let email = signInUserEmailTextField.text, !email.isEmpty, isValidEmail(testStr: email) else {
                signInUserEmailTextField.shake()
                return
            }
            guard let password = signInPwdTextField.text, !password.isEmpty else {
                signInPwdTextField.shake()
                return
            }
            signIn(EmailID: email, Password: password)
            break
        case .SignUp:
            guard let userName = userNameTextField.text, !userName.isEmpty else {
                userNameTextField.shake()
                return
            }
            guard let email = signUpUserEmailTextField.text, !email.isEmpty, isValidEmail(testStr: email) else {
                signUpUserEmailTextField.shake()
                return
            }
            guard let password = signUpPwdTextField.text, !password.isEmpty, password.characters.count >= 6 else {
                signUpPwdTextField.shake()
                return
            }
            guard let retypePassword = retypePwdTextField.text, !retypePassword.isEmpty, retypePassword == password else {
                retypePwdTextField.shake()
                return
            }
            signUp(UserName: userName, EmailID: email, Password: retypePassword)
            break
        }
    }
    
    // MARK: Private implementations
    private func changeState() {
        btnPhoto.isHidden = currentMode == .SignIn
        btnSignInSignUp.setTitle(currentMode == .SignIn ? "Don't have an account?" : "Already have an account?", for: .normal)
        
        // Clear textField for Sign Up/ Sign In
        userNameTextField.text = ""
        signInUserEmailTextField.text = ""
        signUpUserEmailTextField.text = ""
        signInPwdTextField.text = ""
        signUpPwdTextField.text = ""
        retypePwdTextField.text = ""
    }
    private func signIn(EmailID email: String, Password pwd: String) {
        
        UIApplication.shared.showNetworkLoader(messageText: "Signing you In")

        // Sign In
        viewModel!.signIn(userEmail: email, password: pwd) { (user: FIRUser?, error: Error?) in
            UIApplication.shared.hideNetworkLoader()
            if let err = error {
                print("Error Info: \(err.localizedDescription)")
                let errorDesc = FirebaseError.getErrorDesc(error: err)
                self.showAlert(title: "Unable to Sign In", message: errorDesc, notiType: .error)

            }
            else {
                print("User Info: \(user.debugDescription)")
                // When email is verified
                if user!.isEmailVerified {
                    // Navigating to Group List Screen
                    self.performSegue(withIdentifier: SegueConstants.groupListSegue, sender: self)
                }
                else {
                    let alertView = OpinionzAlertView(title: "Email is not verified", message: "Please accept the verification mail that has been sent to your email id: \(email). Please verify your mail before proceeding. If you didn't recieve the mail, please send it again.", cancelButtonTitle: "Cancel", otherButtonTitles: ["Send Again"], usingBlockWhenTapButton: { (alertView, index) in
                        
                        self.viewModel?.resendVerificationMail(completionHandler: { error in
                            guard let _ = error else {
                                self.showAlert(title: "Unable to send Verification Mail", message: "We are unable to send the verification mail to your email id, please try again later", notiType: .error)
                                return
                            }
                            self.showAlert(title: "Verification mail sent", message: "Please check your mail and verify your mail address and try to sign in", notiType: .success)
                        })
                        
                    })
                    alertView?.iconType = OpinionzAlertIconWarning
                    alertView?.show()
                }
            }
        }
    }
    private func signUp(UserName uName: String, EmailID email: String, Password pwd: String) {

        // Sign Up
        // Creating the User using Email & Password
        UIApplication.shared.showNetworkLoader(messageText: "Signing Up")

        viewModel!.signUp(userName: uName, userEmail: email, password: pwd, userImage: btnPhoto.imageView?.image, completionHandler: { (user: FIRUser?, error: Error?) in
            UIApplication.shared.hideNetworkLoader()
            if let err = error {
                print("Error Info: \(err.localizedDescription)")
                let errorDesc = FirebaseError.getErrorDesc(error: err)
                self.showAlert(title: "Unable to Sign Up", message: errorDesc, notiType: .error)
            }
            else {
                print("User Info: \(user.debugDescription)")
                self.showAlert(title: "Verification mail sent", message: "Please check your mail and verify your mail address and try to sign in", notiType: .success)
                
                // Now revert back to Sign In UI
                self.changeMode(sender: self.btnSignInSignUp)
            }
        })
    }
    
    
    // MARK: - Capture Photo
    @IBAction func openCameraControl(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Choose your option", message: "", preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(UIAlertAction(title: "Open Camera", style: .default, handler: { action in
                self.handleCameraControl(type: .camera)
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            actionSheet.addAction(UIAlertAction(title: "Open Library", style: .default, handler: { action in
                self.handleCameraControl(type: .photoLibrary)
            }))
        }
        if btnPhoto.accessibilityValue != nil {
            actionSheet.addAction(UIAlertAction(title: "Delete Photo", style: .destructive, handler: { action in
                self.btnPhoto.setImage(UIImage(named: "defaultImage"), for: .normal)
                self.btnPhoto.accessibilityValue = nil
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            actionSheet.dismiss(animated: true, completion: nil)
        }))
        present(actionSheet, animated: true, completion: nil)
    }
    private func handleCameraControl(type: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        picker.sourceType = type
        picker.mediaTypes = [kUTTypeImage as String]
        present(picker, animated: true, completion: nil)
    }
}
// MARK: - UIImagePickerController delegate
extension SignInSignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            print(image.size)
            self.setProfileImage(image: image)
        }
        else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            print(image.size)
            self.setProfileImage(image: image)
        }
        picker.dismiss(animated: true) {}
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    private func setProfileImage(image: UIImage) {
        let newImage = image.resizedImageWithinRect(rectSize: CGSize(width: 200.0, height: 200.0))
        print(newImage.size)
        btnPhoto.setImage(newImage, for: .normal)
        btnPhoto.accessibilityValue = "Image"
        btnPhoto.setNeedsDisplay()
    }
}
// MARK: - Keyboard Listeners
extension SignInSignUpViewController {
    func keyboardAppeared(notification: NSNotification) {
        if let _ = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            switch currentMode {
            case .SignIn:
                if signInBlurViewYConstraint.constant == 0 {
                    signInBlurViewYConstraint.constant -= 100.0
                }
                break
            case .SignUp:
                if signUpBlurViewYConstraint.constant == 0 {
                    signUpBlurViewYConstraint.constant -= 100.0
                }
                break
            }
        }
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
    }
    func keyboardDismissed(notification: NSNotification) {
        if let _ = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            switch currentMode {
            case .SignIn:
                signInBlurViewYConstraint.constant = 0.0
                break
            case .SignUp:
                signUpBlurViewYConstraint.constant = 0.0
                break
            }
        }
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
    }
}

// MARK: - UITextField Delegates
extension SignInSignUpViewController: UITextFieldDelegate {
    
    // MARK: Email checker
    func isValidEmail(testStr:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if currentMode == .SignIn {
            if textField == signInUserEmailTextField {
                signInPwdTextField.becomeFirstResponder()
            }
            else {
                toggleSignInSignUp(btnSignInSignUp)
            }
        }
        else {
            if textField == userNameTextField {
                signUpUserEmailTextField.becomeFirstResponder()
            }
            else if textField == signUpUserEmailTextField {
                signUpPwdTextField.becomeFirstResponder()
            }
            else if textField == signUpPwdTextField {
                retypePwdTextField.becomeFirstResponder()
            }
            else {
                toggleSignInSignUp(btnSignInSignUp)
            }
        }
        return true
    }
}
