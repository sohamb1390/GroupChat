//
//  SignInSignUpViewController.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import FTIndicator
import Firebase
import RxSwift
import RxCocoa
import MobileCoreServices
import OpinionzAlertView
import JJMaterialTextField

class SignInSignUpViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak var lblSignInSignUp: UILabel!
    @IBOutlet weak var btnSignInSignUp: UIButton!
    @IBOutlet weak var btnPhoto: UIButton!
    
    @IBOutlet weak var userEmailTextField: JJMaterialTextfield! {
        didSet {
            userEmailTextField.returnKeyType = .next
            userEmailTextField.keyboardType = .emailAddress
            userEmailTextField.delegate = self
            userEmailTextField.adjustsFontForContentSizeCategory = true
            userEmailTextField.attributedPlaceholder = NSAttributedString(string: "Email ID",
                                                                   attributes: [NSForegroundColorAttributeName: UIColor.white])
        }
    }
    @IBOutlet weak var userNameTextField: UITextField! {
        didSet {
            userNameTextField.returnKeyType = .next
            userNameTextField.keyboardType = .default
            userNameTextField.delegate = self
        }
    }
    @IBOutlet weak var pwdTextField: JJMaterialTextfield! {
        didSet {
            pwdTextField.isSecureTextEntry = true
            pwdTextField.returnKeyType = .next
            pwdTextField.delegate = self
        }
    }
    @IBOutlet weak var retypePwdTextField: JJMaterialTextfield! {
        didSet {
            retypePwdTextField.isSecureTextEntry = true
            retypePwdTextField.returnKeyType = .next
            retypePwdTextField.delegate = self
        }
    }
    @IBOutlet weak var topConstraintRetypePasswordField: NSLayoutConstraint!
    @IBOutlet weak var topConstraintPasswordField: NSLayoutConstraint!
    @IBOutlet weak var topConstraintEmailField: NSLayoutConstraint!
    @IBOutlet weak var buttonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var blurViewTopConstraint: NSLayoutConstraint!
    // MARK: Variables
    var viewModel: GroupChatViewModel?
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationController?.isNavigationBarHidden = true
        navigationItem.hidesBackButton = true
        
        // Initialise View Model
        viewModel = GroupChatViewModel()
        
        // Token Refresh
        UIApplication.shared.showNetworkLoader(messageText: "Checking for existing session")
        
        viewModel!.tokenRefresh { (error, isEmailVerified) in
            UIApplication.shared.hideNetworkLoader()
            if error == nil, isEmailVerified {
                self.performSegue(withIdentifier: SegueConstants.groupListSegue, sender: self)
            }
        }
        // Register Keyboard observer only for smaller devices
        if UIDevice().screenType == .iPhone5 || UIDevice().screenType == .iPhone4 {
            // Keyboard observers
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    @IBAction func toggleSignInSignUp(sender: UIButton) {
        
        let smallConstant = Double(20.0)
        let bigConstant = Double(30.0)
        
        var buttonPreviousConstant: Double = 0.0
        var userEmailConstant: Double = 0.0
        var updatedConstant: Double = 0.0
        
        switch sender.tag {
        case 1:
            // Sign Up
            sender.tag = 2
            
            buttonPreviousConstant = bigConstant + (Double)(retypePwdTextField.frame.size.height)
            userEmailConstant = smallConstant
            updatedConstant = smallConstant
            
            // Focus on UserName TextField for Sign Up
            userNameTextField.becomeFirstResponder()
            break
        case 2:
            // Sign In
            sender.tag = 1
            updatedConstant = -((Double)(retypePwdTextField.frame.size.height) + smallConstant)
            userEmailConstant = -bigConstant
            buttonPreviousConstant = smallConstant
            userEmailTextField.becomeFirstResponder()
            break
        default:
            break
        }
        topConstraintEmailField.constant = CGFloat(userEmailConstant)
        topConstraintRetypePasswordField.constant = CGFloat(updatedConstant)
        buttonTopConstraint.constant = CGFloat(buttonPreviousConstant)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
        
        // Change states of UILabel & UIbutton
        changeState(sender: btnSignInSignUp)
    }
    func signInSignUp() {
        if btnSignInSignUp.tag == 1 {
            signIn()
        }
        else if btnSignInSignUp.tag == 2 {
            signUp()
        }
    }
    
    // MARK: Private implementations
    private func changeState(sender: UIButton) {
        btnPhoto.isHidden = sender.tag == 1
        retypePwdTextField.isHidden = sender.tag == 1
        userNameTextField.isHidden = sender.tag == 1
        lblSignInSignUp.text = sender.tag == 1 ? "Sign In" : "Sign Up"
        btnSignInSignUp.setTitle(sender.tag == 1 ? "Don't have an account?" : "Already have an account?", for: .normal)
        
        // Clear textField for Sign Up/ Sign In
        userNameTextField.text = ""
        userEmailTextField.text = ""
        pwdTextField.text = ""
        retypePwdTextField.text = ""
        
    }
    private func signIn() {
        
        UIApplication.shared.showNetworkLoader(messageText: "Signing you In")

        // Sign In
        viewModel!.signIn(userEmail: userEmailTextField.text!, password: pwdTextField.text!) { (user: FIRUser?, error: Error?) in
            UIApplication.shared.hideNetworkLoader()
            if let err = error {
                print("Error Info: \(err.localizedDescription)")
                let errorDesc = FirebaseError.getErrorDesc(error: err)
                self.showAlert(title: "Unable to Sign In", message: errorDesc, alertBGColor: .red)

            }
            else {
                print("User Info: \(user.debugDescription)")
                // When email is verified
                if user!.isEmailVerified {
                    // Navigating to Group List Screen
                    self.performSegue(withIdentifier: SegueConstants.groupListSegue, sender: self)
                }
                else {
                    let alertView = OpinionzAlertView(title: "Email is not verified", message: "Please accept the verification mail that has been sent to your email id: \(self.userEmailTextField.text!). Please verify your mail before proceeding. If you didn't recieve the mail, please send it again.", cancelButtonTitle: "Cancel", otherButtonTitles: ["Send Again"], usingBlockWhenTapButton: { (alertView, index) in
                        
                        self.viewModel?.resendVerificationMail(completionHandler: { error in
                            guard let _ = error else {
                                self.showAlert(title: "Unable to send Verification Mail", message: "We are unable to send the verification mail to your email id, please try again later", alertBGColor: .red)
                                return
                            }
                            self.showAlert(title: "Verification mail sent", message: "Please check your mail and verify your mail address and try to sign in", alertBGColor: .green)
                        })
                        
                    })
                    alertView?.iconType = OpinionzAlertIconWarning
                    alertView?.show()
//                    
//                    self.showAlert(title: "Email is not verified", message: "Please accept the verification mail that has been sent to your email id: \(self.userEmailTextField.text!). Please verify your mail before proceeding. If you didn't recieve the mail, please send it again.", action: [UIAlertAction(title: "Send Again", style: .default, handler: { action in
//                        self.viewModel?.resendVerificationMail(completionHandler: { error in
//                            guard let _ = error else {
//                                self.showAlert(title: "Unable to send Verification Mail", message: "We are unable to send the verification mail to your email id, please try again later", action: [UIAlertAction(title: "Ok", style: .default, handler: nil)])
//                                return
//                            }
//                            self.showAlert(title: "Verification mail sent", message: "Please check your mail and verify your mail address and try to sign in", action: [UIAlertAction(title: "Ok", style: .default, handler: nil)])
//                        })
//                    }), UIAlertAction(title: "Ok", style: .default, handler: nil)])
                }
            }
        }
    }
    private func signUp() {

        // Sign Up
        // Creating the User using Email & Password
        UIApplication.shared.showNetworkLoader(messageText: "Signing Up")

        viewModel!.signUp(userName: userNameTextField.text!, userEmail: userEmailTextField.text!, password: retypePwdTextField.text!, userImage: btnPhoto.imageView?.image, completionHandler: { (user: FIRUser?, error: Error?) in
            UIApplication.shared.hideNetworkLoader()
            if let err = error {
                print("Error Info: \(err.localizedDescription)")
                let errorDesc = FirebaseError.getErrorDesc(error: err)
                self.showAlert(title: "Unable to Sign Up", message: errorDesc, alertBGColor: .red)
            }
            else {
                print("User Info: \(user.debugDescription)")
                self.showAlert(title: "Verification mail sent", message: "Please check your mail and verify your mail address and try to sign in", alertBGColor: .green)
                
                // Now revert back to Sign In UI
                self.toggleSignInSignUp(sender: self.btnSignInSignUp)
            }
        })
    }
    
    
    // MARK: - Capture Photo
    @IBAction func openCameraControl(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Choose your option", message: "", preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(UIAlertAction(title: "Open Camera", style: .default, handler: { action in
                self.openCamera()
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            actionSheet.addAction(UIAlertAction(title: "Open Library", style: .default, handler: { action in
                self.openLibrary()
            }))
        }
        if btnPhoto.imageView?.image != nil {
            actionSheet.addAction(UIAlertAction.init(title: "Delete Photo", style: .destructive, handler: { action in
                self.btnPhoto.setImage(nil, for: .normal)
                self.btnPhoto.setTitle("Photo", for: .normal)
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            actionSheet.dismiss(animated: true, completion: nil)
        }))
        present(actionSheet, animated: true, completion: nil)
    }
    private func openCamera() {
        
    }
    private func openLibrary() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        picker.sourceType = .photoLibrary
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
        btnPhoto.setTitle("", for: .normal)
        btnPhoto.setImage(newImage, for: .normal)
    }
}
// MARK: - Keyboard Listeners
extension SignInSignUpViewController {
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardRect = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if blurViewTopConstraint.constant == 0{
                blurViewTopConstraint.constant -= (50)
            }
        }
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
    }
    func keyboardWillHide(notification: NSNotification) {
        if let _ = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if blurViewTopConstraint.constant != 0{
                blurViewTopConstraint.constant = 0
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
    private func isValidEmail(testStr:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    // MARK: Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        switch textField.tag {
        case 1:
            guard let text = textField.text, !text.isEmpty else {
                textField.shake()
                textField.becomeFirstResponder()
                return true
            }
            userEmailTextField.becomeFirstResponder()
            break
        case 2:
            guard let text = textField.text, !text.isEmpty, isValidEmail(testStr: text) else {
                textField.shake()
                textField.becomeFirstResponder()
                return true
            }
            pwdTextField.becomeFirstResponder()
            break
        case 3:
            guard let text = textField.text, !text.isEmpty, text.characters.count >= 6 else {
                textField.shake()
                textField.becomeFirstResponder()
                return true
            }
            // For SignUp Process
            if btnSignInSignUp.tag == 2 {
                // show the retype password textfield
                retypePwdTextField.becomeFirstResponder()
            }
            else {
                // Sign In
                signInSignUp()
            }
            break
        case 4:
            guard let text = textField.text, !text.isEmpty, text == pwdTextField.text else {
                textField.shake()
                textField.becomeFirstResponder()
                return true
            }
            // Sign Up
            signInSignUp()
            
            break
        default: break
        }
        return true
    }
}
