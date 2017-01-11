//
//  GroupChatViewModel.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 29/12/16.

import Foundation
import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage

class GroupModel {
    var groupID: String?
    var groupName: String?
    var groupPassword: String?
    required init(id: String, grpName: String, grpPassword: String) {
        groupID = id
        groupName = grpName
        groupPassword = grpPassword
    }
}
class Chat {
    var senderID: String?
    var message: String?
    // Initial Media Type
    var mediaType: MediaType = .Text
    var dateTime = Date()
    var mediaData: Data?
    
    init(chatUser userID: String, message chatMessage: String, mediaType type: MediaType, chatDateTime chatTime: Date, mediaData data: Data?) {
        senderID = userID
        message = chatMessage
        mediaType = type
        dateTime = chatTime
        mediaData = data
    }
    deinit {
        print("Chat Model deinitalised")
    }
}
class GroupChatViewModel {
    
    var ref: FIRDatabaseReference?
    var currentUser: FIRUser?
    var firebaseAuth: FIRAuth?
    var storageReference: FIRStorageReference?
    
    // Singleton
    static let sharedInstance = GroupChatViewModel()
    
    // Some dummy error for few scenarios
    lazy var error: NSError = {
        return NSError(domain: "", code: 0, userInfo: [:])
    }()
    
    required init() {
        ref = FIRDatabase.database().reference()
        
        ref!.keepSynced(true)

        firebaseAuth = FIRAuth.auth()
        currentUser = firebaseAuth?.currentUser
        storageReference = FIRStorage.storage().reference(forURL: URLConstants.storageURL)
    }
    
    // MARK: Get User online status
    func getUserOnlineStatus(completionHandler: @escaping (_ loggedInUser: FIRUser?) -> Void) {
        FireBaseHandler.getUserStatusNetworkStatus(completionHandler: completionHandler)
    }
    
    // MARK: Load Groups
    func loadGroups(groupChildName: String, completionHandler: @escaping (_ snapshot: FIRDataSnapshot?, _ error: Error?) -> Void) {
        guard let databaseRef = ref else {
            completionHandler(nil, error)
            return
        }
        FireBaseHandler.loadGroups(ref: databaseRef, groupChildName: groupChildName, completionHandler: completionHandler)
    }
    // MARK: Add Group
    func addGroup(groupChildName: String, groupName: String, password: String, completionHandler: @escaping(_ groupID: String?, _ error: Error?) -> Void) {
        guard let databaseRef = ref else {
            completionHandler(nil, error)
            return
        }
        
        // Encrypting the group Password by AES Encryption
        var encryptedPassword = password
        if !password.isEmpty {
            encryptedPassword = password.aesEncrypt(key: groupName, iv: password)
        }
        FireBaseHandler.addGroup(ref: databaseRef, groupChildName: groupChildName, groupName: groupName, password: encryptedPassword, completionHandler: completionHandler)
    }
    // MARK: Get Group ID
    func getGroupID(groupName: String) -> String? {
        guard let databaseRef = ref else {
            return nil
        }
        databaseRef.child(groupName).observeSingleEvent(of: .value) { (snap) in
            print(snap.value!)
        }
        let groupID = databaseRef.child(groupName).key
        return groupID
    }
    // MARK: Create, Delete Chat
    func createChat(groupID: String, chatChildName: String, senderName: String, mediaName: String?, chatMessage: String, chatDateTime: Date, mediaType: MediaType, mediaData: Data?, completionHandler: @escaping(_ error: Error?) -> Void) {
        
        guard let user = currentUser else {
            completionHandler(error)
            return
        }
        guard let databaseRef = ref else {
            completionHandler(error)
            return
        }
        guard let storageRef = storageReference else {
            completionHandler(error)
            return
        }
        let chatModel = Chat(chatUser: user.uid, message: chatMessage, mediaType: mediaType, chatDateTime: chatDateTime, mediaData: mediaData)
        
        FireBaseHandler.createChat(ref: databaseRef, storageRef: storageRef, senderName: senderName, chatChildName: chatChildName, chatData: chatModel, mediaName: mediaName, groupID: groupID) { (error) in
            completionHandler(error)
        }
    }
    
    // MARK: Token Refresh
    func tokenRefresh(completionHandler: @escaping (_ error: Error?, _ isEmailVerified: Bool) -> Void) {
        // Checking whether user exists or not!
        guard let user = currentUser else {
            completionHandler(error, false)
            return
        }
        // Checking whether email is verified or not!
        if !user.isEmailVerified {
            completionHandler(nil, user.isEmailVerified)
            return
        }
        FireBaseHandler.tokenRefresh(user: user) { error in
            completionHandler(error, user.isEmailVerified)
        }
    }
    // MARK: SignIn & SignUp & Signout
    func signIn(userEmail: String, password: String, completionHandler: @escaping (_ user: FIRUser?, _ error: Error?) -> Void) {
        guard let firebaseAuth = FIRAuth.auth() else {
            completionHandler(nil ,error)
            return
        }
        FireBaseHandler.signIn(fireAuth: firebaseAuth, userEmail: userEmail, password: password) { (user, error) in
            if error == nil {
                self.currentUser = firebaseAuth.currentUser
            }
            completionHandler(user, error)
        }
    }
    func signUp(userName: String, userEmail: String, password: String, userImage: UIImage?, completionHandler: @escaping (_ user: FIRUser?, _ error: Error?) -> Void) {
        guard let firebaseAuth = FIRAuth.auth() else {
            completionHandler(nil ,error)
            return
        }
        guard let databaseRef = ref else {
            completionHandler(nil, error)
            return
        }
        guard let storageRef = storageReference else {
            completionHandler(nil, error)
            return
        }
        FireBaseHandler.signUp(fireAuth: firebaseAuth, databaseRef: databaseRef, storageRef: storageRef, userName: userName, userEmail: userEmail, password: password, userImage: userImage) { (user, error) in
            if error == nil {
                self.currentUser = firebaseAuth.currentUser
            }
            completionHandler(user, error)
        }
    }
    func signOut(completionHandler: @escaping(_ error: Error?) -> Void) {
        guard let firebaseAuth = FIRAuth.auth() else {
            completionHandler(error)
            return
        }
        do {
            try firebaseAuth.signOut()
            // Removing the existing user
            currentUser = nil
            completionHandler(nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
            completionHandler(signOutError)
        }
    }
    func resendVerificationMail(completionHandler: @escaping(_ error: Error?) -> Void) {
        guard let currentUser = currentUser else {
            completionHandler(error)
            return
        }
        FireBaseHandler.resendVerificationMail(currentUser) { error in
            completionHandler(error)
        }
    }
    // MARK: Handle User Photo
    func deleteUserPhoto(storageRefrence storageRef: FIRStorageReference, completionHandler: @escaping (_ hasDeleted: Bool, _ error: Error?) -> Void) {
        guard let storageRef = storageReference else {
            completionHandler(false, error)
            return
        }
        FireBaseHandler.deleteUserPhoto(storageRefrence: storageRef, completionHandler: completionHandler)
    }
    func getUserPhoto(databaseReference ref: FIRDatabaseReference?, childName child: String, loggedInUser userID: String?, completionHandler: @escaping (_ image: UIImage?) -> Void) {
        guard let databaseRef = ref, let currentUserID = userID  else {
            completionHandler(nil)
            return
        }
        databaseRef.child(child).child(currentUserID).observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot.key)
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot], snapshots.count > 0, let value = snapshots[0].value {
                // Photo URL should always be in the first index
                if let photoURL = URL(string: value as! String) {
                    NetworkHandler.callAPI(apiURL: photoURL, { (data: Data?, response: URLResponse?, error: Error?) in
                        guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                            let data = data, error == nil,
                            let image = UIImage(data: data) else {
                                completionHandler(nil)
                                return
                        }
                        completionHandler(image)
                    })
                }
                else {
                    completionHandler(nil)
                }
            }
            else {
                completionHandler(nil)
            }
        })
    }
    // MARK: Checking for existing Group Name
    func checkGroupNameAlreadyExists(groupChildName: String, currentGroupName: String, completionHandler: @escaping (_ nameExists: Bool) -> Void) {
        guard let firebaseRef = ref else {
            completionHandler(false)
            return
        }
        FireBaseHandler.checkGroupNameAlreadyExists(ref: firebaseRef, groupChildName: groupChildName, currentGroupName: currentGroupName) { (nameExists) in
            completionHandler(nameExists)
        }
    }
}
