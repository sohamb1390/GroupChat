//
//  AddGroupViewController.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import SwiftMessages

@objc protocol AddGroupDelegate {
    func loadUpdatedGroups()
}
class AddGroupViewController: UIViewController {
    
    // MARK: IBOutlets
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
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    // MARK: Variables
    let viewModel = GroupChatViewModel()
    weak var delegate: AddGroupDelegate?

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        title = "Create Group"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Action
    @IBAction func cancel(sender: UIButton) {
        dismiss(animated: true, completion: nil)
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
            pwdTextField.becomeFirstResponder()
        }
        else if textField.tag == 2 {
            guard let text = textField.text, !text.isEmpty, text.characters.count >= 6 else {
                textField.shake()
                textField.becomeFirstResponder()
                return true
            }
            // show the retype password textfield
            if topConstraint.constant != 0.0 {
                topConstraint.constant = 20.0
                retypePwdTextField.isHidden = false
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                })
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
                self.viewModel.addGroup(groupChildName: "Groups", groupName: self.groupNameTextField.text!, password: self.retypePwdTextField.text!, completionHandler: { (groupID, error) in
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
