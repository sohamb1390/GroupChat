//
//  FirebaseProtocol.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 23/01/17.
//

import Foundation
import UIKit
import FirebaseDatabase
import Firebase
import FirebaseStorage

// MARK: Common Method Handlers
protocol CommonMethodHandlerProtcol {
    var ref: FIRDatabaseReference? { get }
    var storageRef: FIRStorageReference? { get }
    var fireAuth: FIRAuth? { get }
    func triggerFirebase(completionHandler: @escaping(_ groupID: String?, _ error: Error?, _ user: FIRUser?, _ ref: FIRDatabaseReference?, _ snapshot: FIRDataSnapshot?) -> Void)
}
// MARK: Media Handlers
protocol MediaHandlerProtocol {
    associatedtype mediaType
    func uploadMedia(userMedia media: mediaType, storageRefrence storageRef: FIRStorageReference, databaseReference databaseRef: FIRDatabaseReference, firebaseUser user: FIRUser, completionHandler: @escaping (_ hasUploaded: Bool, _ mediaURL: URL?) -> Void)
    func deleteUserPhoto(storageRefrence storageRef: FIRStorageReference, completionHandler: @escaping (_ hasDeleted: Bool, _ error: Error?) -> Void)
}
// MARK: Token Refresh {
protocol TokenRefreshProtcol {
    var user: FIRUser { get }
    func tokenRefresh(completionHandler: @escaping (_ error: Error?, _ isEmailVerified: Bool) -> Void)
}
// MARK: Resend Verification
protocol ResendVerificationProtocol {
    func resendVerificationMail(firebaseUser user: FIRUser, completionHandler: @escaping (_ error: Error?) -> Void)
}
// MARK: Required Firebase Handlers
protocol LoadGroupProtcol: CommonMethodHandlerProtcol {
    var groupChildName: String { get }
}
// MARK: Group Name Check Protocol
protocol GroupNameCheckProtocol {
    var groupChildName: String { get }
    var currentGroupName: String { get }
    var ref: FIRDatabaseReference { get }

    func checkGroupNameAlreadyExists(completionHandler: @escaping (_ nameExists: Bool) -> Void)
}
protocol FetchUserMediaProtocol {
    var ref: FIRDatabaseReference { get }
    var childName: String { get }
    var userID: String { get }
    func getUserPhoto(completionHandler: @escaping (_ image: UIImage?) -> Void)
}

// MARK: Other Firebase Handlers Protocol
protocol AddGroupProtcol: CommonMethodHandlerProtcol {
    var groupChildName: String { get }
    var groupName: String { get}
    var groupPassword: String { get }
}
protocol RemoveGroupProtocol: CommonMethodHandlerProtcol {
    var groupChildName: String { get }
    var groupID: String { get}
    var chatChildName: String { get }
}
protocol CreateChatProtocol: CommonMethodHandlerProtcol {
    var groupID: String { get }
    var chatChildName: String { get }
    var senderName: String { get }
    var chatDetails: Chat { get }
    var mediaName: String? { get }
}
protocol SignInProtocol: CommonMethodHandlerProtcol {
    var userEmail: String { get }
    var password: String { get }
}
protocol SignUpProtocol: CommonMethodHandlerProtcol {
    var userName: String { get }
    var userEmail: String { get }
    var password: String { get }
    var userImage: UIImage? { get }
}
protocol SignOutProtocol {
    func signOut(firebaseAuth auth: FIRAuth, completionHandler: @escaping(_ error: Error?) -> Void)
}
