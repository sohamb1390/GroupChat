//
//  ChatViewController.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 26/12/16.

import UIKit
import JSQMessagesViewController
import Firebase
import FirebaseStorage
import MobileCoreServices
import Photos

class Message: JSQMessage {
    var messageId: String?
}
class ChatViewController: JSQMessagesViewController {

    // MARK: Variables
    var selectedGroupModel: GroupModel?
    private var btnUserProfile: UIButton?
    private let viewModel: GroupChatViewModel = (UIApplication.shared.delegate as! AppDelegate).groupModel!
    private var groupID: String? {
        get {
            if selectedGroupModel != nil {
                return selectedGroupModel?.groupID
            }
            return nil
        }
    }
    private lazy var messageRef: FIRDatabaseReference = {
        return self.getMessageRefrence()
    }()
    private lazy var cache: NSCache<AnyObject, AnyObject> = {
        return NSCache()
    }()

    // Chat properties
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    private lazy var userIsTypingRef: FIRDatabaseReference = {
        self.getRef().child(ChildNameConstants.typingIndicator).child(self.senderId)
    }()
    private var localTyping = false
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
        self.getRef().child(ChildNameConstants.typingIndicator).queryOrderedByValue().queryEqual(toValue: true)
    }()
    
    private var loggedInUsersArray: [FIRUser] = []
    private var updatedMessageRefHandle: FIRDatabaseHandle?
    private var newMessageRefHandle: FIRDatabaseHandle?
    private var removedMessageRefHandle: FIRDatabaseHandle?

    private var messages = [Message]()
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    var imageDictArray = [[String: Any]]()
    
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
        
        //collectionView.collectionViewLayout.springinessEnabled = true
        
        // automatically scrolls down if new message came
        automaticallyScrollsToMostRecentMessage = true
        
        // Customise UI
        customiseUI()
        
        // Observe users
        //observeUsers()
        
        // Observer Messages
        observeMessages()

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Download the user image and set it
        if btnUserProfile?.accessibilityValue == nil {
            guard let currentUser = viewModel.currentUser else {
                return
            }
            let fetchUserPhotoStruct = fetchMedia(ref: viewModel.ref, childName: ChildNameConstants.users, userID: currentUser.uid)
            
            fetchUserPhotoStruct.getUserPhoto(completionHandler: { [weak self] (image: UIImage?) -> Void in
                weak var weakSelf = self
                if weakSelf == nil { return }
                OperationQueue.main.addOperation({ 
                    if let img = image {
                        weakSelf!.btnUserProfile?.setImage(img, for: .normal)
                        weakSelf!.btnUserProfile?.accessibilityValue = "Image"
                    }
                    else {
                        weakSelf!.btnUserProfile?.setImage(UIImage.init(named: "defaultImage"), for: .normal)
                    }
                })
            })
        }
        observeTyping()
        
        scrollToBottom(animated: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    deinit {
        // deinit will never get called for ViewControllers
    }
    
    // MARK: - Customise UI
    func customiseUI() {
        btnUserProfile = UIButton(type: .custom)
        btnUserProfile!.frame = CGRect(x: 0.0, y: 0.0, width: 30.0, height: 30.0)
        btnUserProfile!.layer.cornerRadius = btnUserProfile!.frame.size.width / 2
        btnUserProfile!.layer.borderColor = UIColor.white.cgColor
        btnUserProfile!.layer.borderWidth = 1.0
        btnUserProfile!.layer.masksToBounds = true
        
        let leftMenuItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(back))
        
        navigationItem.setLeftBarButton(leftMenuItem, animated: false);
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btnUserProfile!)
    }
    
    func back() {
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        if let refHandle = removedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        _ = navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Observer
    private func observeMessages() {
        messageRef = viewModel.ref.child(ChildNameConstants.chat).child(groupID!)
        // 1.
        let messageQuery = messageRef.queryOrderedByKey() //messageRef.queryLimited(toLast:25)
        
        // 2. We can use the observe method to listen for new
        // messages being written to the Firebase DB
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            // 3
            let messageData = snapshot.value as! Dictionary<String, String>
            let key =  snapshot.key
            if let id = messageData[ChildNameConstants.chatUserID] as String!, let name = messageData[ChildNameConstants.chatSenderName] as String!, let text = messageData[ChildNameConstants.chatMessage] as String!, let dateTime = messageData[ChildNameConstants.chatDateTime] as String!, text.characters.count > 0 {
                // 4
                
                // Decrypting a chat using AES
                let decryptedChat = text.aesDecrypt(key: id, iv: text)
                self.addMessage(withId: id, name: name, text: decryptedChat, dateTimeString: dateTime, chatId: key)
                
                // 5
                self.finishReceivingMessage(animated: true)
            } else if let id = messageData[ChildNameConstants.chatUserID] as String!, let photoURL = messageData[ChildNameConstants.mediaURL] as String!, !photoURL.isEmpty, let name = messageData[ChildNameConstants.chatSenderName] as String! {
                
                // 2
                if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                    // 3
                    self.addPhotoMessage(withId: id, key: snapshot.key, displayName: name, mediaItem: mediaItem, chatId: key)
                    // 4
//                    if photoURL.hasPrefix("gs://") {
//                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
//                    }
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                }
                
            } else {
                print("Error! Could not decode message data")
            }
        })
        
        removedMessageRefHandle = messageQuery.observe(.childRemoved, with: { (snapshot) -> Void in
            let messageData = snapshot.value as! Dictionary<String, String>
            if let id = messageData[ChildNameConstants.chatUserID] {
                self.removeMessage(DeletedChatId: id, ChatKey: snapshot.key)
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
            }
        })
        updatedMessageRefHandle = messageRef.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            let messageData = snapshot.value as! Dictionary<String, String> // 1
            
            if let photoURL = messageData[ChildNameConstants.mediaURL] as String! { // 2
                // The photo has been updated.
                if let mediaItem = self.photoMessageMap[key] { // 3
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key)
                }
                else {
                    if let id = messageData[ChildNameConstants.chatUserID] as String!, let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId), let name = messageData[ChildNameConstants.chatSenderName] as String! {
                        self.addPhotoMessage(withId: id, key: snapshot.key, displayName: name, mediaItem: mediaItem, chatId: key)
                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                    }
                }
            }
        })
    }
    private func observeTyping() {
        let typingIndicatorRef = getRef().child(ChildNameConstants.typingIndicator)
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
//        viewModel.getUserOnlineStatus { (loggedInUser) in
//            if let user = loggedInUser {
//                self.loggedInUsersArray.append(user)
//            }
//            print(loggedInUser)
//        }
    }
    
    // MARK: - Chat Controls
    private func getMessageRefrence() -> FIRDatabaseReference {
        let messageRef = viewModel.ref.child(ChildNameConstants.chat).child(groupID!)
        messageRef.keepSynced(true)
        return messageRef
    }
    private func getRef() -> FIRDatabaseReference {
        return viewModel.ref
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
    private func addMessage(withId id: String, name: String, text: String, dateTimeString: String, chatId: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let dateTime = dateFormatter.date(from: dateTimeString)

        if dateTime == nil {
            if let message = Message(senderId: id, displayName: name, text: text) {
                message.messageId = chatId
                messages.append(message)
            }
        }
        else {
            if let message = Message(senderId: id, senderDisplayName: name, date: dateTime, text: text) {
                message.messageId = chatId
                messages.append(message)
            }
        }
    }
    private func addPhotoMessage(withId id: String, key: String, displayName: String, mediaItem: JSQPhotoMediaItem, chatId: String) {
        if let message = Message(senderId: id, displayName: displayName, media: mediaItem) {
            message.messageId = chatId
            messages.append(message)
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            collectionView.reloadData()
        }
    }
    private func removeMessage(DeletedChatId deletedChatSenderId: String, ChatKey chatId: String) {
        var tempChatMessages = messages
        for (index, message) in tempChatMessages.enumerated() {
            if message.senderId == deletedChatSenderId, message.messageId == chatId {
                tempChatMessages.remove(at: index)
                break
            }
        }
        messages = tempChatMessages
    }
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        // 1
        let storageRef = FIRStorage.storage().reference(forURL: photoURL)
        
        // 2
        storageRef.data(withMaxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            // 3
            storageRef.metadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                // 4
                // Stop Status Bar network loader
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                mediaItem.image = UIImage(data: data!)
                self.collectionView.reloadData()
                
                // 5
                guard key != nil else {
                    return
                }
                self.photoMessageMap.removeValue(forKey: key!)
            })
        }
    }
    private func handleCameraControl(type: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        picker.sourceType = type
        picker.mediaTypes = [kUTTypeImage as String]
        present(picker, animated: true, completion: nil)
    }
    private func openProfilePictureViewer(indexPath: IndexPath, image: UIImage, isMediaImage: Bool) {
        
        var avatarImage = image
        let message = messages[indexPath.row]

        // Message Object
        if !isMediaImage {
            for imgeDict in imageDictArray {
                if let rowNumber = imgeDict["row"] as? NSNumber, Int(rowNumber) == indexPath.row, let image = imgeDict["image"] as? UIImage {
                    avatarImage = image
                }
            }
        }
        let popupController = PopupController
            .create(self)
            .customize(
                [
                    .animation(.slideUp),
                    .scrollable(false),
                    .backgroundStyle(.blackFilter(alpha: 0.7))
                ]
            )
            .didShowHandler { popup in
                print("showed popup!")
            }
            .didCloseHandler { _ in
                print("closed popup!")
            }
            // Get user status

            _ = popupController.show(UserProfilePopupViewController.instance(userImage: avatarImage, userName: message.senderDisplayName, userEmail: (message.senderId == self.senderId ? self.viewModel.currentUser?.email : nil), onlineStatus: false)) // Still figuring out how to get online status of each user!! :(
        
    }
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        guard let currentUser = viewModel.currentUser else {
            return
        }

        // Create a chat
        isTyping = false
        
        // Encrypting a chat using AES
        let encryptedChat = text.aesEncrypt(key: senderId, iv: text)
        
        // Create a new chat
        // 1. First create the chat model structure
        let chatModel = Chat(senderID: currentUser.uid, message: encryptedChat, mediaType: .Text, dateTime: date, mediaData: nil)
        
        // 2. Create the "New Chat Create Structure"
        let createChatStruct = CreateChat(groupID: groupID!, chatChildName: ChildNameConstants.chat, senderName: senderDisplayName, chatDetails: chatModel, mediaName: nil, ref: viewModel.ref, storageRef: viewModel.storageReference, fireAuth: viewModel.firebaseAuth)
        
        // 3. Trigger Firebase for sending this chat
        createChatStruct.triggerFirebase { [weak self] (groupID: String?, error: Error?, user: FIRUser?, ref: FIRDatabaseReference?, snap: FIRDataSnapshot?) -> Void in
            
            weak var weakSelf = self
            if weakSelf == nil { return }
            
            weakSelf!.finishSendingMessage(animated: true)
        }
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
        
//        viewModel.createChat(groupID: groupID!, chatChildName: "Chat", senderName: senderDisplayName, mediaName: nil, chatMessage: encryptedChat, chatDateTime: date!, mediaType: .Text, mediaData: nil, completionHandler: { (error) in
//            self.finishSendingMessage(animated: true)
//        })
//        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
    }
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let actionSheet = UIAlertController(title: "Media", message: "Select your option", preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(UIAlertAction(title: "Open Camera", style: .default, handler: { action in
                self.handleCameraControl(type: .camera)
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            actionSheet.addAction(UIAlertAction(title: "Open Library", style: .default, handler: { action in
                self.handleCameraControl(type: .photoLibrary)
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            actionSheet.dismiss(animated: true, completion: nil)
        }))
        present(actionSheet, animated: true, completion: nil)
    }
    
    func sendPictureMessage(image: UIImage, imageName: String) {
        
        guard let currentUser = viewModel.currentUser else {
            return
        }
        // Create a picture chat
        isTyping = false
        
        var data = NSData()
        data = UIImageJPEGRepresentation(image, 1.0)! as NSData

        // Start Status bar loader
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Create a new chat
        // 1. First create the chat model structure
        let chatModel = Chat(senderID: currentUser.uid, message: nil, mediaType: .Picture, dateTime: Date(), mediaData: data as Data)
        
        // 2. Create the "New Chat Create Structure"
        let createChatStruct = CreateChat(groupID: groupID!, chatChildName: ChildNameConstants.chat, senderName: senderDisplayName, chatDetails: chatModel, mediaName: imageName, ref: viewModel.ref, storageRef: viewModel.storageReference, fireAuth: viewModel.firebaseAuth)
        
        // 3. Trigger Firebase for sending this chat
        createChatStruct.triggerFirebase { [weak self] (groupID: String?, error: Error?, user: FIRUser?, ref: FIRDatabaseReference?, snap: FIRDataSnapshot?) -> Void in
            
            weak var weakSelf = self
            if weakSelf == nil { return }
            
            weakSelf!.finishSendingMessage(animated: true)
        }
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4

        
//        viewModel.createChat(groupID: groupID!, chatChildName: "Chat", senderName: senderDisplayName, mediaName: imageName, chatMessage: "", chatDateTime: Date(), mediaType: .Picture, mediaData: data as Data) { (error) in
//            self.finishSendingMessage(animated: true)
//        }
//        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
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
            let fetchUserPhotoStruct = fetchMedia(ref: viewModel.ref, childName: ChildNameConstants.users, userID: message.senderId)
            
            fetchUserPhotoStruct.getUserPhoto(completionHandler: { [weak self] (image: UIImage?) -> Void in
                weak var weakSelf = self
                if weakSelf == nil { return }
                
                if let img = image {
                    weakSelf!.imageDictArray.append(["image": img,
                                                     "row": NSNumber(value: indexPath.row)])
                    OperationQueue.main.addOperation({
                        cell.avatarImageView.image = JSQMessagesAvatarImageFactory.avatarImage(with: img, diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault)).avatarImage
                        weakSelf!.cache.setObject(img, forKey: indexPath.row as AnyObject)
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
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let message = messages[indexPath.row]
        if message.isMediaMessage {
            let mediaItem = message.media
            let photoItem = mediaItem as! JSQPhotoMediaItem
            openProfilePictureViewer(indexPath: indexPath, image: photoItem.image, isMediaImage: true)
        }
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        openProfilePictureViewer(indexPath: indexPath, image: avatarImageView.image!, isMediaImage: false)
    }
    // MARK: - UITextView Delegates
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        isTyping = textView.text != ""
    }
}

// MARK: - UIImagePickerController Handlers
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion:nil)
        var selectedImage: UIImage?
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            print(image.size)
            selectedImage = image
            //sendPictureMessage(image: image)
        }
        else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            print(image.size)
            //sendPictureMessage(image: image)
            selectedImage = image
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let dateString = dateFormatter.string(from: Date())
        let imageURL = info[UIImagePickerControllerReferenceURL] as! URL
        let imageName = "\(dateString)-\(imageURL.lastPathComponent)"

        if selectedImage != nil {
            sendPictureMessage(image: selectedImage!, imageName: imageName)
        }
    }
}
