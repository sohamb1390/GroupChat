//
//  AddGroupViewController.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.

import UIKit
import Firebase
import FirebaseDatabase
import SwiftMessages

@objc protocol AddGroupDelegate {
    func loadUpdatedGroups()
}
class AddGroupViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak var yConstraint: NSLayoutConstraint!

    @IBOutlet weak var pwdTextField: UITextField! {
        didSet {
            pwdTextField.isSecureTextEntry = true
            pwdTextField.delegate = self
            pwdTextField.returnKeyType = .next
        }
    }
    @IBOutlet weak var retypePwdTextField: UITextField! {
        didSet {
            retypePwdTextField.isSecureTextEntry = true
            retypePwdTextField.delegate = self
            retypePwdTextField.returnKeyType = .go
        }
    }
    @IBOutlet weak var groupNameTextField: UITextField! {
        didSet {
            groupNameTextField.delegate = self
            groupNameTextField.returnKeyType = .next
        }
    }
    @IBOutlet weak var passwordSwitch: UISwitch! {
        didSet {
            passwordSwitch.setOn(false, animated: true)
        }
    }
    
    // MARK: Variables
    let viewModel = GroupChatViewModel()
    weak var delegate: AddGroupDelegate?

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        title = "Create Group"
        yConstraint.constant = view.frame.size.height
        
//        let encrypt = title!.aesEncrypt(key: "key", iv: title!)
//        let decrypt = title!.aesDecrypt(key: "key", iv: encrypt)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    // MARK: - Action
    @IBAction func cancel(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func onChangeSwitchState(_ sender: UISwitch) {
        sender.setOn(!sender.isOn, animated: true)
        pwdTextField.text = ""
        retypePwdTextField.text = ""
        self.yConstraint.constant = sender.isOn ? -40.0 : self.view.frame.size.height
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 5.0, options: UIViewAnimationOptions.curveLinear, animations: {
            self.view.layoutIfNeeded()
        }) { (animated) in
        }
    }
    @IBAction func addGroup(_ sender: UIButton) {
        guard let groupName = groupNameTextField.text, !groupName.isEmpty else {
            groupNameTextField.shake()
            groupNameTextField.becomeFirstResponder()
            return
        }
        if passwordSwitch.isOn {
            guard let pass = pwdTextField.text, !pass.isEmpty, pass.characters.count >= 6 else {
                pwdTextField.shake()
                pwdTextField.becomeFirstResponder()
                return
            }
            guard let rePass = retypePwdTextField.text, !rePass.isEmpty, rePass.characters.count >= 6, rePass == pass else {
                retypePwdTextField.shake()
                retypePwdTextField.becomeFirstResponder()
                return
            }
        }
        addGroup()
    }
}
extension AddGroupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField.tag == 1 {
            guard let text = textField.text, !text.isEmpty else {
                textField.shake()
                textField.becomeFirstResponder()
                return true
            }
            if passwordSwitch.isOn {
                pwdTextField.becomeFirstResponder()
            }
        }
        else if textField.tag == 2 {
            guard let text = textField.text, !text.isEmpty, text.characters.count >= 6 else {
                textField.shake()
                textField.becomeFirstResponder()
                return true
            }
            retypePwdTextField.becomeFirstResponder()
        }
        else if textField.tag == 3 {
            guard let text = textField.text, !text.isEmpty, text == pwdTextField.text else {
                textField.shake()
                textField.becomeFirstResponder()
                return true
            }
            // Save the new group
            addGroup()
        }
        return true
    }
}
// MARK: - Firebase Actions
extension AddGroupViewController {
    
    // MARK: Add a new group
    func addGroup() {
        UIApplication.shared.showNetworkLoader(messageText: "Adding your group")

        viewModel.checkGroupNameAlreadyExists(groupChildName: "Groups", currentGroupName: groupNameTextField.text!) { (doesExist) in
            // Firebase reference found, now do the next checkings
            if doesExist {
                UIApplication.shared.hideNetworkLoader()
                self.showAlert(title: "Unable to add your group", message: "Group name already exists", notiType: .error)
            }
            else {
                self.viewModel.addGroup(groupChildName: "Groups", groupName: self.groupNameTextField.text!, password: self.retypePwdTextField.text ?? "", completionHandler: { (groupID, error) in
                    UIApplication.shared.hideNetworkLoader()
                    if let err = error {
                        self.showAlert(title: "Unable to add your group", message: FirebaseError.getErrorDesc(error: err), notiType: .error)
                    }
                    else {
                        self.dismiss(animated: true, completion: {
                            if self.delegate != nil {
                                self.delegate?.loadUpdatedGroups()
                            }
                        })
                    }
                })
            }
        }
    }
}
