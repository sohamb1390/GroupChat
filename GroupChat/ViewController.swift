//
//  ViewController.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import FirebaseStorage
class ViewController: JSQMessagesViewController {

    // MARK: Variables
    var selectedGroupModel: GroupModel?
    var btnUserProfile: UIButton?
    let viewModel: GroupChatViewModel = GroupChatViewModel.sharedInstance
    var groupID: String? {
        get {
            if selectedGroupModel != nil {
                return selectedGroupModel?.groupID
            }
            return nil
        }
    }

    // Chat properties
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: .lightGray)
    let outgoingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: .green)
    var messages = [JSQMessage]()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        if let grpModel = selectedGroupModel, let groupName = grpModel.groupName  {
            title = groupName
        }
        else {
            title = senderDisplayName
        }
        
        // Customise UI
        customiseUI()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Download the user image and set it
        if btnUserProfile?.imageView?.image == nil {
            viewModel.getUserPhoto(databaseReference: viewModel.ref, childName: "users", loggedInUser: viewModel.currentUser, completionHandler: { (image) in
                if let img = image {
                    self.btnUserProfile?.setImage(img, for: .normal)
                }
                else {
                    self.btnUserProfile?.setImage(nil, for: .normal)
                }
            })
        }
        
        // Create a chat
        let imageData = UIImageJPEGRepresentation(UIImage(named: "image")!, 0.8)! as Data
        viewModel.createChat(groupID: groupID!, chatChildName: "Chat", mediaName: "image", chatMessage: "hello", chatDateTime: Date(), mediaType: .Picture, mediaData: imageData, completionHandler: { (error) in
            
        })
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Customise UI
    func customiseUI() {
        btnUserProfile = UIButton(type: .custom)
        btnUserProfile!.frame = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0)
        btnUserProfile!.layer.cornerRadius = btnUserProfile!.frame.size.width / 2
        btnUserProfile!.layer.borderColor = UIColor.white.cgColor
        btnUserProfile!.layer.borderWidth = 1.0
        btnUserProfile!.layer.masksToBounds = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btnUserProfile!)
    }
    
    // MARK: - Chat Controls
    func reloadMessagesView() {
        collectionView?.reloadData()
    }
}

