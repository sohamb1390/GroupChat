//
//  GroupChatConstants.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.

import Foundation
import UIKit
import Firebase
import FirebaseAuth

struct CellIdentifierConstants {
    static let groupCellID = "GroupCellID"
}
struct URLConstants {
    static let storageURL = "gs://groupchat-7471f.appspot.com"
}
struct SegueConstants {
    static let chatScreenSegue = "ChatScreenSegue"
    static let addGroupScreenSegue = "AddGroupScreenSegue"
    static let groupListSegue =  "GroupListSegue"
    static let signInSignUpSegue = "SignInSignUpSegue"
}
struct ColorConstants {
    static let baseColor = UIColor(red: 255.0/255.0, green: 98.0/255.0, blue: 76.0/255.0, alpha: 1.0)
}
enum MediaType: String {
    case Text = "text", Picture = "picture", Audio = "audio", Video = "video"
}
class FirebaseError {
    class func getErrorDesc(error: Error) -> String {
        if let errCode = FIRAuthErrorCode(rawValue: error._code) {
            switch errCode {
            case .errorCodeInvalidCustomToken:
                return "A Validation error with the custom token"
            case .errorCodeCustomTokenMismatch:
                return "The Service account and the API key belong to different projects"
            case .errorCodeInvalidCredential:
                return "The IDP token or requestUri is invalid"
            case .errorCodeUserDisabled:
                return "The user's account is disabled on the server"
            case .errorCodeOperationNotAllowed:
                return "The Administrator disabled sign in with the specified identity provider"
            case .errorCodeEmailAlreadyInUse:
                return "The email used to attempt a sign up is already in use"
            case .errorCodeInvalidEmail:
                return "The email is invalid"
            case .errorCodeWrongPassword:
                return "The user attempted sign in with a wrong password"
            case .errorCodeUserNotFound:
                return "The user account was not found"
            case .errorCodeAccountExistsWithDifferentCredential:
                return "Account linking is required"
            case .errorCodeRequiresRecentLogin:
                return "The user has attemped to change email or password more than 5 minutes after signing in"
            case .errorCodeProviderAlreadyLinked:
                return "An attempt to link a provider to which the account is already linked"
            case .errorCodeNoSuchProvider:
                return "An attempt to unlink a provider that is not linked"
            case .errorCodeInvalidUserToken:
                return "User's saved auth credential is invalid, the user needs to sign in again"
            case .errorCodeNetworkError:
                return "a network error occurred (such as a timeout, interrupted connection, or unreachable host)"
            case .errorCodeUserTokenExpired:
                return "The saved token has expired, for example, the user may have changed account password on another device. The user needs to sign in again on the device that made this request"
            case .errorCodeInvalidAPIKey:
                return "An invalid API key was supplied in the request"
            case .errorCodeUserMismatch:
                return "An attempt was made to reauthenticate with a user which is not the current user"
            case .errorCodeCredentialAlreadyInUse:
                return "An attempt to link with a credential that has already been linked with a different Firebase account"
            case .errorCodeWeakPassword:
                return "An attempt to set a password that is considered too weak"
            case .errorCodeAppNotAuthorized:
                return "The App is not authorized to use Firebase Authentication with the provided API Key"
            case .errorCodeExpiredActionCode:
                return "The OOB code is expired"
            case .errorCodeInvalidActionCode:
                return "The OOB code is invalid"
            case .errorCodeKeychainError:
                return "An error occurred while attempting to access the keychain"
            case .errorCodeInternalError:
                return "An error occurred while attempting to access the keychain"
            default:
                return "Unknown error occured"
            }
        }
        return ""
    }
}
