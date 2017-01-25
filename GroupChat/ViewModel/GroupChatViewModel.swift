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

// MARK: Load Existing Group Structure
struct LoadGroup: LoadGroupProtcol {
    internal var groupChildName: String
    internal var ref: FIRDatabaseReference?
    internal var storageRef: FIRStorageReference?
    internal var fireAuth: FIRAuth?
    
    func triggerFirebase(completionHandler: @escaping (String?, Error?, FIRUser?, FIRDatabaseReference?, _ snapshot: FIRDataSnapshot?) -> Void) {
        guard let dRef = ref else {
            return
        }
        dRef.child(groupChildName).observeSingleEvent(of: .value, with: { snap in
            completionHandler(nil, nil, nil, nil, snap)
        }, withCancel: { error in
            completionHandler(nil, error, nil, nil, nil)
        })
    }
}
// MARK: Add a New Group Structure
struct AddGroup: AddGroupProtcol {
    internal var groupChildName: String
    internal var groupName: String
    internal var groupPassword: String
    internal var ref: FIRDatabaseReference?
    internal var storageRef: FIRStorageReference?
    internal var fireAuth: FIRAuth?
    
    internal func triggerFirebase(completionHandler: @escaping (String?, Error?, FIRUser?, FIRDatabaseReference?, FIRDataSnapshot?) -> Void) {
        guard let dRef = ref else {
            return
        }
        let parameters = ["groupName": groupName,
                          "password": groupPassword]
        dRef.child(groupChildName).childByAutoId().setValue(parameters) { (error, databaseRef) in
            completionHandler(databaseRef.key, error, nil, databaseRef, nil)
        }
    }
}
// MARK: Remove Group Structure
struct RemoveGroup: RemoveGroupProtocol {
    internal var groupChildName: String
    internal var groupID: String
    internal var chatChildName: String
    internal var ref: FIRDatabaseReference?
    internal var storageRef: FIRStorageReference?
    internal var fireAuth: FIRAuth?
    
    internal func triggerFirebase(completionHandler: @escaping (String?, Error?, FIRUser?, FIRDatabaseReference?, FIRDataSnapshot?) -> Void) {
        guard let dRef = ref else {
            return
        }
        // First remove the group
        dRef.child(groupChildName).child(groupID).removeValue {(error, ref) in
            if error == nil {
                // Now delete the corresponding chat child
                ref.child(self.chatChildName).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.hasChild(self.groupID) {
                        ref.child(self.chatChildName).child(self.groupID).removeValue(completionBlock: { (error: Error?, ref: FIRDatabaseReference) in
                            completionHandler(self.groupID, error, nil, ref, nil)
                        })
                    }
                    else {
                        completionHandler(self.groupID, error, nil, ref, nil)
                    }
                })
            }
            else {
                completionHandler(self.groupID, error, nil, ref, nil)
            }
        }
    }
}
// MARK: Refresh Token Structure
struct RefreshToken: TokenRefreshProtcol {
    internal var user: FIRUser
    
    internal func tokenRefresh(completionHandler: @escaping (Error?, Bool) -> Void) {
        // Checking whether email is verified or not!
        if !user.isEmailVerified {
            completionHandler(nil, user.isEmailVerified)
            return
        }
        else {
            user.getTokenForcingRefresh(true) { (idToken, error) in
                completionHandler(error, self.user.isEmailVerified)
            }
        }
    }
}
// MARK: Sign Up Structure
struct SignUp: SignUpProtocol, MediaHandlerProtocol, ResendVerificationProtocol {
    internal var userName: String
    internal var userEmail: String
    internal var password: String
    internal var userImage: UIImage?
    typealias mediaType = UIImage
    internal var ref: FIRDatabaseReference?
    internal var storageRef: FIRStorageReference?
    internal var fireAuth: FIRAuth?
    
    
    internal func triggerFirebase(completionHandler: @escaping (String?, Error?, FIRUser?, FIRDatabaseReference?, FIRDataSnapshot?) -> Void) {
        guard let dRef = ref, let sRef = storageRef, let auth = fireAuth else {
            return
        }
        auth.createUser(withEmail: userEmail, password: password, completion: { (user: FIRUser?, error: Error?) in
            if user != nil {
                // Update User Name
                let changeRequest = user!.profileChangeRequest()
                changeRequest.displayName = self.userName
                
                // Upload user photo if user has selected any photo
                if self.userImage != nil {
                    
                    // Upload the Image
                    self.uploadMedia(userMedia: self.userImage!, storageRefrence: sRef, databaseReference: self.ref!, firebaseUser: user!, completionHandler: { (hasUploadedPhoto, photoURL) in
                        
                        changeRequest.photoURL = photoURL
                        changeRequest.commitChanges(completion: { error in
                            if let error = error {
                                // An error happened.
                                completionHandler(nil, error, user, dRef, nil)
                            } else {
                                // Profile updated.
                                // Send Verification Mail
                                if user != nil {
                                    self.resendVerificationMail(firebaseUser: user!, completionHandler: { (error) in
                                        completionHandler(nil, error, user, dRef, nil)
                                    })
                                }
                            }
                        })
                    })
                }
                else {
                    // Normal
                    changeRequest.commitChanges { error in
                        if let error = error {
                            // An error happened.
                            completionHandler(nil, error, user, dRef, nil)
                        } else {
                            // Profile updated.
                            // Send Verification Mail
                            if user != nil {
                                self.resendVerificationMail(firebaseUser: user!, completionHandler: { (error) in
                                    completionHandler(nil, error, user, dRef, nil)
                                })
                            }
                        }
                    }
                }
            }
            else {
                completionHandler(nil, error, user, self.ref, nil)
            }
        })
    }
    func uploadMedia(userMedia media: UIImage, storageRefrence storageRef: FIRStorageReference, databaseReference databaseRef: FIRDatabaseReference, firebaseUser user: FIRUser, completionHandler: @escaping (Bool, URL?) -> Void) {
        var data = NSData()
        data = UIImageJPEGRepresentation(media, 0.8)! as NSData
        
        // set upload path
        let filePath = "\(user.uid)/\("userPhoto")"
        let metaData = FIRStorageMetadata()
        metaData.contentType = "image/jpg"
        
        storageRef.child(filePath).put(data as Data, metadata: metaData){ (metaData, error) in
            if let _ = error {
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
    func resendVerificationMail(firebaseUser user: FIRUser, completionHandler: @escaping (Error?) -> Void) {
        user.sendEmailVerification(completion: { (error) in
            completionHandler(error)
        })
    }
    // Optional function, not required now
    func deleteUserPhoto(storageRefrence storageRef: FIRStorageReference, completionHandler: @escaping (Bool, Error?) -> Void) {
    }
}
// MARK: Sign In Structure
struct SignIn: SignInProtocol, ResendVerificationProtocol {
    internal var userEmail: String
    internal var password: String
    internal var ref: FIRDatabaseReference?
    internal var storageRef: FIRStorageReference?
    internal var fireAuth: FIRAuth?
    
    internal func triggerFirebase(completionHandler: @escaping (String?, Error?, FIRUser?, FIRDatabaseReference?, FIRDataSnapshot?) -> Void) {
        if fireAuth != nil {
            fireAuth!.signIn(withEmail: userEmail, password: password, completion: { (user: FIRUser?, error: Error?) in
                completionHandler(nil, error, user, nil, nil)
            })
        }
    }
    internal func resendVerificationMail(firebaseUser user: FIRUser, completionHandler: @escaping (Error?) -> Void) {
        user.sendEmailVerification(completion: { (error) in
            completionHandler(error)
        })
    }
}
// MARK: Sign Out Structure
struct SignOut: SignOutProtocol {
    func signOut(firebaseAuth auth: FIRAuth, completionHandler: @escaping (Error?) -> Void) {
        do {
            try auth.signOut()
            completionHandler(nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
            completionHandler(signOutError)
        }
    }
}

// MARK: Create Chat Structure
struct CreateChat: CreateChatProtocol {
    internal var groupID: String
    internal var chatChildName: String
    internal var senderName: String
    internal var chatDetails: Chat
    internal var mediaName: String?
    internal var ref: FIRDatabaseReference?
    internal var storageRef: FIRStorageReference?
    internal var fireAuth: FIRAuth?
    
    
    internal func triggerFirebase(completionHandler: @escaping (String?, Error?, FIRUser?, FIRDatabaseReference?, FIRDataSnapshot?) -> Void) {
        
        guard let dRef = ref, let sRef = storageRef else {
            return
        }
        // Convert Chat Data into detail description
        let userID = chatDetails.senderID
        let chatMessage = chatDetails.message
        let chatDateTime = chatDetails.dateTime
        let mediaType = chatDetails.mediaType
        let mediaData = chatDetails.mediaData
        
        // Convert chat date-time in string
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let dateTimeString = dateFormatter.string(from: chatDateTime)
        
        // Create Chat parameter
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
            
            dRef.child(chatChildName).child(groupID).childByAutoId().setValue(parameters) { (error, databaseRef) in
                if error == nil {
                    // Create a reference to the file you want to upload
                    let riversRef = sRef.child(databaseRef.key).child("\(self.mediaName!).\(mediaExtension)")
                    // Upload the file to the path "images/rivers.jpg"
                    riversRef.put(mediaData!, metadata: nil) { (metadata, error) in
                        guard let metadata = metadata else {
                            // Uh-oh, an error occurred!
                            completionHandler(self.groupID, error, nil, self.ref, nil)
                            return
                        }
                        // Metadata contains file metadata such as size, content-type, and download URL.
                        if let downloadURL = metadata.downloadURL() {
                            // Update the existing Chat
                            self.ref!.child(self.chatChildName).child(self.groupID).child(databaseRef.key).observeSingleEvent(of: .value, with: { (snapshot) in
                                if var dict = snapshot.value as? [String: Any] {
                                    
                                    dict["mediaURL"] = downloadURL.absoluteString
                                    dRef.child(self.chatChildName).child(self.groupID).child(databaseRef.key).setValue(dict)
                                    
                                    completionHandler(self.groupID, nil, nil, dRef, snapshot)
                                }
                                else {
                                    completionHandler(self.groupID, error, nil, dRef, snapshot)
                                }
                            }, withCancel: { (error) in
                                completionHandler(self.groupID, error, nil, dRef, nil)
                            })
                        }
                        else {
                            completionHandler(self.groupID, error, nil, dRef, nil)
                        }
                    }
                }
                else {
                    completionHandler(self.groupID, error, nil, dRef, nil)
                }
            }
        }
        else {
            dRef.child(chatChildName).child(groupID).childByAutoId().setValue(parameters, withCompletionBlock: { (error, ref) in
                completionHandler(self.groupID, error, nil, ref, nil)
            })
        }
    }
}
// MARK: Check Existing Group Name Structure
struct CheckGroupName: GroupNameCheckProtocol {
    internal var groupChildName: String
    internal var currentGroupName: String
    internal var ref: FIRDatabaseReference
    
    func checkGroupNameAlreadyExists(completionHandler: @escaping (Bool) -> Void) {
        ref.child(groupChildName).observeSingleEvent(of: .value, with: { snapshot in

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
                        if innerDict["groupName"]?.uppercased() == self.currentGroupName.uppercased() {
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
// MARK: Chat Model Structure
struct Chat {
    var senderID: String?
    var message: String?
    var mediaType: MediaType = .Text
    var dateTime = Date()
    var mediaData: Data?
}
// MARK: Group Model Structure
struct GroupModel {
    var groupID: String?
    var groupName: String?
    var groupPassword: String?
}
// MARK: Fetch User Media Structure
struct fetchMedia: FetchUserMediaProtocol {
    internal var ref: FIRDatabaseReference
    internal var childName: String
    internal var userID: String

    func getUserPhoto(completionHandler: @escaping (UIImage?) -> Void) {
        ref.child(childName).child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
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
}

// MARK: Model Structure
class GroupChatViewModel {
    // Making it Singleton
    static let sharedInstance = GroupChatViewModel()
    
    // Private ivars
    var ref: FIRDatabaseReference = FIRDatabase.database().reference() {
        didSet {
            ref.keepSynced(true)
        }
    }
    var firebaseAuth: FIRAuth = FIRAuth.auth()!
    var storageReference: FIRStorageReference = FIRStorage.storage().reference(forURL: URLConstants.storageURL)
    var currentUser: FIRUser? {
        get {
            let user = firebaseAuth.currentUser
            return user
        }
    }
}
