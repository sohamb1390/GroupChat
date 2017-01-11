//
//  FireBaseHandler.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 28/12/16.

import UIKit
import FirebaseDatabase
import Firebase
import FirebaseStorage

class FireBaseHandler: NSObject {
    
    // MARK: Load Groups
    class func loadGroups(ref: FIRDatabaseReference, groupChildName: String, completionHandler: @escaping (_ snapshot: FIRDataSnapshot?, _ error: Error?) -> Void) {
        ref.child(groupChildName).observeSingleEvent(of: .value, with: { snap in
            completionHandler(snap, nil)
        }, withCancel: { error in
            completionHandler(nil, error)
        })
    }
    // MARK: Add Group
    class func addGroup(ref: FIRDatabaseReference, groupChildName: String, groupName: String, password: String, completionHandler: @escaping(_ groupID: String?, _ error: Error?) -> Void) {
        
        let parameters = ["groupName": groupName,
                          "password": password]
        ref.child(groupChildName).childByAutoId().setValue(parameters) { (error, databaseRef) in
            completionHandler(databaseRef.key, error)
        }
    }
    // MARK: Remove Group and corresponding group chat
    class func removeGroup(databaseRef: FIRDatabaseReference, grouphildName: String, groupID: String, chatChildName: String, completionHandler: @escaping(_ error: Error?, _ ref: FIRDatabaseReference?) -> Void) {
        // First remove the group
        databaseRef.child(grouphildName).child(groupID).removeValue { (error, ref) in
            if error == nil {
                // Now delete the corresponding chat child
                databaseRef.child(chatChildName).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.hasChild(groupID) {
                        databaseRef.child(chatChildName).child(groupID).removeValue(completionBlock: completionHandler)
                    }
                    else {
                        completionHandler(error, ref)
                    }
                })
            }
            else {
                completionHandler(error, ref)
            }
        }
    }
    
    // MARK: Token Refresh
    class func tokenRefresh(user: FIRUser, completionHandler: @escaping (_ error: Error?) -> Void) {
        user.getTokenForcingRefresh(true) { (idToken, error) in
            completionHandler(error)
        }
    }
    
    // MARK: Online/Offline capabilities
    class func getUserStatusNetworkStatus(completionHandler: @escaping (_ loggedInUser: FIRUser?) -> Void) {
        
        FIRAuth.auth()!.addStateDidChangeListener() { (auth, user) in
            if let user = user {
                print("User is signed in with uid:", user.uid)
                completionHandler(user)
            } else {
                print("No user is signed in.")
                completionHandler(nil)
            }
        }
    }
    
    // MARK: - Create, Delete, Modify Chat
    
    // MARK: Create a new chat
    class func createChat(ref: FIRDatabaseReference, storageRef: FIRStorageReference, senderName: String, chatChildName: String, chatData: Chat, mediaName: String?, groupID: String, completionHandler: @escaping(_ error: Error?) -> Void) {
        
        // Convert Chat Data into detail description
        let userID = chatData.senderID
        let chatMessage = chatData.message
        let chatDateTime = chatData.dateTime
        let mediaType = chatData.mediaType
        let mediaData = chatData.mediaData
        
        // Convert chat date-time in string
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let dateTimeString = dateFormatter.string(from: chatDateTime)
        
        // Create Chat
        let parameters = ["chatUserID": userID,
                          "chatSenderName": senderName,
                          "chatMessage": chatMessage,
                          "chatDateTime": dateTimeString,
                          "mediaURL": ""]
        
        if mediaType == .Audio || mediaType == .Picture || mediaType == .Video, mediaData != nil, mediaName != nil {
            var mediaExtension = ""
            switch mediaType {
            case .Audio:
                mediaExtension = ".mp3"
                break
            case .Picture:
                mediaExtension = ".jpg"
                break
            case .Video:
                mediaExtension = ".mp4"
                break
            default: break
            }
            ref.child(chatChildName).child(groupID).childByAutoId().setValue(parameters) { (error, databaseRef) in
                if error == nil {
                    // Create a reference to the file you want to upload
                    let riversRef = storageRef.child(databaseRef.key).child("\(mediaName!).\(mediaExtension)")
                    // Upload the file to the path "images/rivers.jpg"
                    riversRef.put(mediaData!, metadata: nil) { (metadata, error) in
                        guard let metadata = metadata else {
                            // Uh-oh, an error occurred!
                            completionHandler(error)
                            return
                        }
                        // Metadata contains file metadata such as size, content-type, and download URL.
                        if let downloadURL = metadata.downloadURL() {
                            // Update the existing Chat
                            ref.child(chatChildName).child(groupID).child(databaseRef.key).observeSingleEvent(of: .value, with: { (snapshot) in
                                if var dict = snapshot.value as? [String: Any] {
                                    dict["mediaURL"] = downloadURL.absoluteString
                                    ref.child(chatChildName).child(groupID).child(databaseRef.key).setValue(dict)
                                    completionHandler(nil)
                                }
                                else {
                                    completionHandler(error)
                                }
                            }, withCancel: { (error) in
                                print(error)
                                completionHandler(error)
                            })
                        }
                        else {
                            completionHandler(error)
                        }
                    }
                }
                else {
                    completionHandler(error)
                }
            }
        }
        else {
            ref.child(chatChildName).child(groupID).childByAutoId().setValue(parameters, withCompletionBlock: { (error, ref) in
                completionHandler(error)
            })
        }
    }
    // MARK: SignIn & SignUp & Signout
    class func signIn(fireAuth: FIRAuth ,userEmail: String, password: String, completionHandler: @escaping (_ user: FIRUser?, _ error: Error?) -> Void) {
        fireAuth.signIn(withEmail: userEmail, password: password, completion: { (user: FIRUser?, error: Error?) in
            completionHandler(user, error)
        })
    }
    class func signUp(fireAuth: FIRAuth, databaseRef: FIRDatabaseReference, storageRef: FIRStorageReference, userName: String ,userEmail: String, password: String, userImage: UIImage?, completionHandler: @escaping (_ user: FIRUser?, _ error: Error?) -> Void) {
        fireAuth.createUser(withEmail: userEmail, password: password, completion: { (user: FIRUser?, error: Error?) in
            if user != nil {
                // Update User Name
                let changeRequest = user!.profileChangeRequest()
                changeRequest.displayName = userName
                
                // Upload user photo if user has selected any photo
                if userImage != nil {
                    uploadUserPhoto(userImage: userImage!, storageRefrence: storageRef, databaseReference: databaseRef, firebaseUser: user!, completionHandler: { (hasUploadedPhoto, photoURL) in
                        print("User photo uploaded: \(hasUploadedPhoto)")
                        changeRequest.photoURL = photoURL
                        changeRequest.commitChanges { error in
                            if let error = error {
                                // An error happened.
                                completionHandler(user, error)
                            } else {
                                // Profile updated.
                                // Send Verification Mail
                                user!.sendEmailVerification(completion: { (error) in
                                    completionHandler(user, error)
                                })
                            }
                        }
                    })
                }
                else {
                    changeRequest.commitChanges { error in
                        if let error = error {
                            // An error happened.
                            completionHandler(user, error)
                        } else {
                            // Profile updated.
                            // Send Verification Mail
                            user!.sendEmailVerification(completion: { (error) in
                                completionHandler(user, error)
                            })
                        }
                    }
                }
            }
            else {
                completionHandler(user, error)
            }
        })
    }
    class func resendVerificationMail(_ user: FIRUser, completionHandler: @escaping (_ error: Error?) -> Void) {
        user.sendEmailVerification(completion: { (error) in
            completionHandler(error)
        })
    }
    class func signOut(completionHandler: @escaping(_ error: Error?) -> Void) {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            completionHandler(nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
            completionHandler(signOutError)
        }
    }
    // MARK: Handle User Photo
    class func uploadUserPhoto(userImage image: UIImage, storageRefrence storageRef: FIRStorageReference, databaseReference databaseRef: FIRDatabaseReference, firebaseUser user: FIRUser, completionHandler: @escaping (_ hasUploaded: Bool, _ photoURL: URL?) -> Void) {
        var data = NSData()
        data = UIImageJPEGRepresentation(image, 0.8)! as NSData
        
        // set upload path
        let filePath = "\(user.uid)/\("userPhoto")"
        let metaData = FIRStorageMetadata()
        metaData.contentType = "image/jpg"
        
        storageRef.child(filePath).put(data as Data, metadata: metaData){ (metaData, error) in
            if let error = error {
                print(error.localizedDescription)
                completionHandler(false, nil)
                return
            } else {
                //store downloadURL
                let downloadURL = metaData!.downloadURL()!.absoluteString
                //store downloadURL at database
                databaseRef.child("users").child(user.uid).updateChildValues(["userPhoto": downloadURL])
                completionHandler(true, URL(fileURLWithPath: downloadURL))
            }
        }
    }
    class func deleteUserPhoto(storageRefrence storageRef: FIRStorageReference, completionHandler: @escaping (_ hasDeleted: Bool, _ error: Error?) -> Void) {
        // Create a reference to the file to delete
        let desertRef = storageRef.child("userPhoto")
        
        // Delete the file
        desertRef.delete { error in
            if let error = error {
                // Uh-oh, an error occurred!
                completionHandler(false, error)
            } else {
                // File deleted successfully
                completionHandler(true, error)
            }
        }
    }
    
    // MARK: Checking for existing Group Name
    class func checkGroupNameAlreadyExists(ref: FIRDatabaseReference, groupChildName: String, currentGroupName: String, completionHandler: @escaping (_ nameExists: Bool) -> Void) {
        ref.child(groupChildName).observeSingleEvent(of: .value, with: { snapshot in
            print(snapshot.debugDescription)
            let postDictArray = snapshot.value as? [String : AnyObject] ?? [:]
            if postDictArray.count < 1 {
                // This is for the first time
                // No groups have been added
                completionHandler(false)
            }
            else {
                var found = false
                for dict in postDictArray {
                    if let innerDict = dict.value as? Dictionary<String, String> {
                        if innerDict["groupName"]?.localizedLowercase == currentGroupName.localizedLowercase {
                            found = true
                            break
                        }
                    }
                }
                completionHandler(found)
            }
            
        }) { error in
            completionHandler(false)
        }
    }
}
