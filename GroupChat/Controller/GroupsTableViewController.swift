//
//  GroupsTableViewController.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import OpinionzAlertView
import SwiftMessages

class GroupsTableViewController: UITableViewController {
    
    // MARK: Variables
    var groupsArray: [GroupModel] = []
    let viewModel: GroupChatViewModel = GroupChatViewModel.sharedInstance
    var selectedGroupModel: GroupModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        navigationController?.isNavigationBarHidden = false
        tableView.tableFooterView = UIView()
        
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
        viewModel.signOut { error in
            if error != nil {
                print ("Error signing out: %@", error!)
                self.showAlert(title: "Unable to sign out", message: error!.localizedDescription, notiType: .error)
            }
            else {
                self.popToSignInSignOutScreen()
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
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifierConstants.groupCellID, for: indexPath)
        
        // Configure the cell...
        let grpModel = groupsArray[indexPath.row]
        cell.textLabel?.text = grpModel.groupName
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let grpModel = groupsArray[indexPath.row]
        
        // Get selected group name
        selectedGroupModel = grpModel
        
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
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == SegueConstants.addGroupScreenSegue, let vc = segue.destination as? AddGroupViewController {
            vc.delegate = self
        }
        else if segue.identifier == SegueConstants.chatScreenSegue, let vc = segue.destination as? ChatViewController {
            if let currentUser = viewModel.currentUser, let displayName = currentUser.displayName {
                vc.senderDisplayName = displayName
                vc.senderId = currentUser.uid
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
        
        viewModel.loadGroups(groupChildName: "Groups") { (snapshot, error) in
            UIApplication.shared.hideNetworkLoader()
            OperationQueue.main.addOperation({
                if error != nil {
                    self.showAlert(title: "Unable to fetch your groups", message: "Some unknown error occured, please try again later", notiType: .error)
                }
                else {
                    let postDictArray = snapshot!.value as? [String : AnyObject] ?? [:]
                    if postDictArray.count < 1 {
                        // No groups found
                        // Add atleast one group to continue
                        let alertView = OpinionzAlertView(title: "No groups found", message: "Please add atleast one group to continue", cancelButtonTitle: "Cancel", otherButtonTitles: ["Add one group"], usingBlockWhenTapButton: { (alertView, index) in
                            if index == 1 {
                                self.performSegue(withIdentifier: SegueConstants.addGroupScreenSegue, sender: self)
                            }
                        })
                        alertView?.iconType = OpinionzAlertIconWarning
                        alertView?.show()
                    }
                    else {
                        // remove previous values
                        self.groupsArray.removeAll()
                        // Loading the groups again
                        for dict in postDictArray {
                            if let innerDict = dict.value as? Dictionary<String, String> {
                                let groupID = dict.key
                                let grpName = innerDict["groupName"]
                                let password = innerDict["password"]
                                let grpModel = GroupModel(id: groupID, grpName: grpName ?? "", grpPassword: password ?? "")
                                self.groupsArray.append(grpModel)
                            }
                        }
                        self.tableView.reloadSections(IndexSet.init(integer: 0), with: .automatic)
                    }
                }
            })
        }
    }
}
