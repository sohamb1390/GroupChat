//
//  GroupsTableViewController.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.

import UIKit
import JSQMessagesViewController
import OpinionzAlertView
import SwiftMessages
import Firebase
import FirebaseDatabase
import FirebaseStorage

class GroupsTableViewController: UITableViewController {
    
    // MARK: Variables
    var groupsArray: [GroupModel] = []
    var viewModel: GroupChatViewModel?
    var selectedGroupModel: GroupModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        navigationController?.isNavigationBarHidden = false
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableViewAutomaticDimension
        
        viewModel = (UIApplication.shared.delegate as! AppDelegate).groupModel!
        
        // Load groups
        loadGroups()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    @IBAction func addGroup(sender: UIButton) {
        performSegue(withIdentifier: SegueConstants.addGroupScreenSegue, sender: self)
    }
    @IBAction func signOut(sender: UIButton) {
        // Sign Out
        let signoutStruct = SignOut()
        signoutStruct.signOut(firebaseAuth: viewModel!.firebaseAuth) { [weak self] (error: Error?) -> Void in
            
            weak var weakSelf = self
            if weakSelf == nil { return }

            if error != nil {
                print ("Error signing out: %@", error!)
                weakSelf!.showAlert(title: "Unable to sign out", message: error!.localizedDescription, notiType: .error)
            }
            else {
                weakSelf!.popToSignInSignOutScreen()
            }
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsArray.count
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifierConstants.groupCellID, for: indexPath)
        
        // Configure the cell...
        let grpModel = groupsArray[indexPath.row]
        cell.textLabel?.text = grpModel.groupName
        
        // If the group has a password
        cell.detailTextLabel!.text = "Secured"
        cell.detailTextLabel!.textColor = .red
        
        // If the group doesn't have a password
        if grpModel.groupPassword == "" {
            cell.detailTextLabel!.text = "Open"
            cell.detailTextLabel!.textColor = .blue
        }
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let grpModel = groupsArray[indexPath.row]
        
        // Get selected group name
        selectedGroupModel = grpModel
        
        // Group password is there
        if !grpModel.groupPassword!.isEmpty {
            // Prompt user to provide group password to continue
            let alertController = UIAlertController(title: "Group Password needed", message: "Please provide your group password to continue", preferredStyle: .alert)
            let saveAction = UIAlertAction(title: "Go", style: UIAlertActionStyle.default, handler: {
                alert -> Void in
                let passwordTextField = alertController.textFields![0] as UITextField
                guard let password = passwordTextField.text, !password.isEmpty else {
                    print("Password is blank")
                    self.showAlert(title: "Password cannot be empty", message: "Please provide a valid password", notiType: .error)
                    return
                }
                if password == grpModel.groupPassword  {
                    // Navigate to the chat screen
                    print("Password matched")
                    self.performSegue(withIdentifier: SegueConstants.chatScreenSegue, sender: self)
                }
                else {
                    print("Password didn't match")
                    self.showAlert(title: "Invalid Password", message: "Please provide a valid password", notiType: .error)
                }
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {
                (action : UIAlertAction!) -> Void in
            })
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Group Pasword"
                textField.isSecureTextEntry = true
            }
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        }
        else {
            // For open group which doesn't have any password
            self.performSegue(withIdentifier: SegueConstants.chatScreenSegue, sender: self)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let grpModel = groupsArray[indexPath.row]

            // Show alert for deleting group
            let alertView = OpinionzAlertView(title: "Delete \(grpModel.groupName!)", message: "Do you really want to delete this group?", cancelButtonTitle: "No", otherButtonTitles: ["Yes"], usingBlockWhenTapButton: { [weak self] (alertView, index) -> Void in
                
                weak var weakSelf = self
                if weakSelf == nil { return }

                if index == 1 {
                    // Remove Group
                    let removeGroupStruct = RemoveGroup(groupChildName: "Groups", groupID: grpModel.groupID!, chatChildName: "Chat", ref: weakSelf!.viewModel!.ref, storageRef: weakSelf!.viewModel!.storageReference, fireAuth: weakSelf!.viewModel!.firebaseAuth)
                    
                    removeGroupStruct.triggerFirebase(completionHandler: { (groupID: String?, error: Error?, user: FIRUser?, ref: FIRDatabaseReference?, snap: FIRDataSnapshot?) in
                        if error == nil {
                            weakSelf!.groupsArray.remove(at: indexPath.row)
                            tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    })
                }
            })
            alertView?.iconType = OpinionzAlertIconWarning
            alertView?.show()
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == SegueConstants.addGroupScreenSegue, let vc = segue.destination as? AddGroupViewController {
            vc.delegate = self
        }
        else if segue.identifier == SegueConstants.chatScreenSegue, let vc = segue.destination as? ChatViewController {
            let currentUser = viewModel!.currentUser
            if let displayName = currentUser?.displayName {
                vc.senderDisplayName = displayName
                vc.senderId = currentUser?.uid
                vc.selectedGroupModel = selectedGroupModel
            }
        }
    }
}
// MARK: - Load Updated Groups
extension GroupsTableViewController: AddGroupDelegate {
    func loadUpdatedGroups() {
        loadGroups()
    }
}

// MARK: - Firebase Actions
extension GroupsTableViewController {
    
    // MARK: Firebase Data Change Observer
    func loadGroups() {
        UIApplication.shared.showNetworkLoader(messageText: "Fetching your groups")
        
        // fetch Groups
        let loadGroupsStruct = LoadGroup(groupChildName: "Groups", ref: viewModel!.ref, storageRef: viewModel!.storageReference, fireAuth: viewModel!.firebaseAuth)
        loadGroupsStruct.triggerFirebase { [weak self] (groupID: String?, error: Error?, user: FIRUser?, ref: FIRDatabaseReference?, snap: FIRDataSnapshot?) -> Void in
            UIApplication.shared.hideNetworkLoader()
            
            weak var weakSelf = self
            if weakSelf == nil { return }
            
            if error != nil {
                weakSelf!.showAlert(title: "Unable to fetch your groups", message: "Some unknown error occured, please try again later", notiType: .error)
                return
            }
            if snap == nil {
                print("Snapshot not found")
                return
            }
            
            OperationQueue.main.addOperation({
                let postDictArray = snap!.value as? [String : AnyObject] ?? [:]
                if postDictArray.count < 1 {
                    // No groups found
                    // Add atleast one group to continue
                    let alertView = OpinionzAlertView(title: "No groups found", message: "Please add atleast one group to continue", cancelButtonTitle: "Cancel", otherButtonTitles: ["Add one group"], usingBlockWhenTapButton: { (alertView, index) in
                        if index == 1 {
                            weakSelf!.performSegue(withIdentifier: SegueConstants.addGroupScreenSegue, sender: weakSelf!)
                        }
                    })
                    alertView?.iconType = OpinionzAlertIconInfo
                    alertView?.show()
                }
                else {
                    // remove previous values
                    weakSelf!.groupsArray.removeAll()
                    // Loading the groups again
                    for dict in postDictArray {
                        if let innerDict = dict.value as? Dictionary<String, String> {
                            let groupID = dict.key
                            let grpName = innerDict["groupName"]
                            var password = innerDict["password"]
                            
                            // Decrypt Password
                            if !password!.isEmpty {
                                password = password!.aesDecrypt(key: grpName!, iv: password!)
                            }
                            let grpModel = GroupModel(groupID: groupID, groupName: grpName ?? "", groupPassword: password ?? "")
                            weakSelf!.groupsArray.append(grpModel)
                        }
                    }
                    weakSelf!.tableView.reloadSections(IndexSet.init(integer: 0), with: .automatic)
                }
            })
        }
    }
}
