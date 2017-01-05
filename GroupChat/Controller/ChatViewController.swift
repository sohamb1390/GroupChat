//
//  ChatViewController.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import FirebaseStorage
class ChatViewController: JSQMessagesViewController {

    // MARK: Variables
    var selectedGroupModel: GroupModel?
    private var btnUserProfile: UIButton?
    private let viewModel: GroupChatViewModel = GroupChatViewModel.sharedInstance
    private var groupID: String? {
        get {
            if selectedGroupModel != nil {
                return selectedGroupModel?.groupID
            }
            return nil
        }
    }
    private lazy var messageRef: FIRDatabaseReference = {
        return self.getMessage()
    }()
    private var newMessageRefHandle: FIRDatabaseHandle?
    private lazy var cache: NSCache<AnyObject, AnyObject> = {
        return NSCache()
    }()

    // Chat properties
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    private lazy var userIsTypingRef: FIRDatabaseReference = {
        self.getRef().child("TypingIndicator").child(self.senderId) // 1
    }()
    private var localTyping = false // 2
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            // 3
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    private lazy var usersTypingQuery: FIRDatabaseQuery = {
        self.getRef().child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    }()

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
        
        // Observe messages
        observeMessages()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Download the user image and set it
        if btnUserProfile?.imageView?.image == nil {
            viewModel.getUserPhoto(databaseReference: viewModel.ref, childName: "users", loggedInUser: viewModel.currentUser?.uid, completionHandler: { (image) in
                OperationQueue.main.addOperation({ 
                    if let img = image {
                        self.btnUserProfile?.setImage(img, for: .normal)
                    }
                    else {
                        self.btnUserProfile?.setImage(nil, for: .normal)
                    }
                })
            })
        }
        observeTyping()
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
    
    // MARK: - Observer
    private func observeMessages() {
        messageRef = viewModel.ref!.child("Chat").child(groupID!)
        // 1.
        let messageQuery = messageRef.queryOrderedByKey() //messageRef.queryLimited(toLast:25)
        
        // 2. We can use the observe method to listen for new
        // messages being written to the Firebase DB
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            // 3
            let messageData = snapshot.value as! Dictionary<String, String>
            
            if let id = messageData["chatUserID"] as String!, let name = messageData["chatSenderName"] as String!, let text = messageData["chatMessage"] as String!, let dateTime = messageData["chatDateTime"] as String!, text.characters.count > 0 {
                // 4
                self.addMessage(withId: id, name: name, text: text, dateTimeString: dateTime)
                
                // 5
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
            }
        })
        
        newMessageRefHandle = messageQuery.observe(.childRemoved, with: { (snapshot) -> Void in
            let messageData = snapshot.value as! Dictionary<String, String>
            if let id = messageData["chatUserID"] {
                self.removeMessage(DeletedChatId: id)
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
            }
        })
    }
    private func observeTyping() {
        let typingIndicatorRef = getRef().child("TypingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        
        // 1
        usersTypingQuery.observe(.value) { (data: FIRDataSnapshot) in
            // 2 You're the only one typing, don't show the indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            // 3 Are there others typing?
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        }
    }
    private func observeUsers() {
        
    }
    
    // MARK: - Chat Controls
    private func getMessage() -> FIRDatabaseReference {
        return viewModel.ref!.child("Chat").child(groupID!)
    }
    private func getRef() -> FIRDatabaseReference {
        return viewModel.ref!
    }
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    private func reloadMessagesView() {
        collectionView?.reloadData()
    }
    private func addMessage(withId id: String, name: String, text: String, dateTimeString: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let dateTime = dateFormatter.date(from: dateTimeString)
        
        if let message = JSQMessage(senderId: id, senderDisplayName: name, date: dateTime, text: text) {
            messages.append(message)
        }
    }
    private func removeMessage(DeletedChatId deletedChatSenderId: String) {
        let deletedChatMessages = messages.filter { message -> Bool in
            return message.senderId == deletedChatSenderId
        }
        messages = deletedChatMessages
    }

    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        // Create a chat
        //let imageData = UIImageJPEGRepresentation(UIImage(named: "image")!, 0.8)! as Data
        isTyping = false
        viewModel.createChat(groupID: groupID!, chatChildName: "Chat", senderName: senderDisplayName, mediaName: nil, chatMessage: text, chatDateTime: date, mediaType: .Text, mediaData: nil, completionHandler: { (error) in
            self.finishSendingMessage()
        })
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
    }
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
    }
    
    // MARK: - JSQMessageController UICollectionView delegates
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let avatar = JSQMessagesAvatarImageFactory.avatarImage(withPlaceholder: UIImage(named: "defaultImage"), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        return avatar
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        // set placeholder image
        let placeholder = UIImage(named: "defaultImage")
        let avatarImage = JSQMessagesAvatarImageFactory.circularAvatarImage(placeholder, withDiameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        
        cell.avatarImageView.image = avatarImage
        
        // get actual user image from server
        if cache.object(forKey: indexPath.row as AnyObject) != nil, let image = cache.object(forKey: indexPath.row as AnyObject) as? UIImage {
            cell.avatarImageView.image = JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault)).avatarImage
            print("Avatar is already downloaded, no need to download it")
        }
        else {
            
            viewModel.getUserPhoto(databaseReference: viewModel.ref, childName: "users", loggedInUser: message.senderId, completionHandler: { (image) in
                if let img = image {
                    OperationQueue.main.addOperation({ 
                        cell.avatarImageView.image = JSQMessagesAvatarImageFactory.avatarImage(with: img, diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault)).avatarImage
                        self.cache.setObject(img, forKey: indexPath.row as AnyObject)
                    })
                }
            })
        }
        return cell
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        switch message.senderId {
        case senderId:
            return nil
        default:
            guard let senderDisplayName = message.senderDisplayName else {
                return nil
            }
            return NSAttributedString(string: senderDisplayName)
        }
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        guard let chatDate = message.date else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let chatDateString = dateFormatter.string(from: chatDate)
        return NSAttributedString(string: "Sent on \(chatDateString)")
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 20.0
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        return 20.0
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapCellAt indexPath: IndexPath!, touchLocation: CGPoint) {
        view.endEditing(true)
    }
    
    // MARK: - UITextView Delegates
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        isTyping = textView.text != ""
    }
}

