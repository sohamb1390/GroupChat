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
    
    private var loggedInUsersArray: [FIRUser] = []
    private var updatedMessageRefHandle: FIRDatabaseHandle?
    private var newMessageRefHandle: FIRDatabaseHandle?
    private var messages = [JSQMessage]()
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
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Observe messages
        observeMessages()
        
        navigationController?.isNavigationBarHidden = false
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Download the user image and set it
        if btnUserProfile?.accessibilityValue == nil {
            viewModel.getUserPhoto(databaseReference: viewModel.ref, childName: "users", loggedInUser: viewModel.currentUser?.uid, completionHandler: { (image) in
                OperationQueue.main.addOperation({ 
                    if let img = image {
                        self.btnUserProfile?.setImage(img, for: .normal)
                        self.btnUserProfile?.accessibilityValue = "Image"
                    }
                    else {
                        self.btnUserProfile?.setImage(UIImage.init(named: "defaultImage"), for: .normal)
                    }
                })
            })
        }
        observeTyping()
        
        scrollToBottom(animated: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        messages = []
        photoMessageMap = [:]
        loggedInUsersArray = []
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
            newMessageRefHandle = nil
        }
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        super.viewWillDisappear(animated)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    deinit {
        messages = []
        photoMessageMap = [:]
        loggedInUsersArray = []
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
            newMessageRefHandle = nil
        }
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
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
                self.finishReceivingMessage(animated: true)
            } else if let id = messageData["chatUserID"] as String!, let photoURL = messageData["mediaURL"] as String!, !photoURL.isEmpty, let name = messageData["chatSenderName"] as String! {
                
                // 2
                if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                    // 3
                    self.addPhotoMessage(withId: id, key: snapshot.key, displayName: name, mediaItem: mediaItem)
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
        
        newMessageRefHandle = messageQuery.observe(.childRemoved, with: { (snapshot) -> Void in
            let messageData = snapshot.value as! Dictionary<String, String>
            if let id = messageData["chatUserID"] {
                self.removeMessage(DeletedChatId: id)
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
            }
        })
        updatedMessageRefHandle = messageRef.observe(.childChanged, with: { (snapshot) in
            let key = snapshot.key
            let messageData = snapshot.value as! Dictionary<String, String> // 1
            
            if let photoURL = messageData["mediaURL"] as String! { // 2
                // The photo has been updated.
                if let mediaItem = self.photoMessageMap[key] { // 3
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key)
                }
                else {
                    if let id = messageData["chatUserID"] as String!, let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId), let name = messageData["chatSenderName"] as String! {
                        self.addPhotoMessage(withId: id, key: snapshot.key, displayName: name, mediaItem: mediaItem)
                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                    }
                }
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
//        viewModel.getUserOnlineStatus { (loggedInUser) in
//            if let user = loggedInUser {
//                self.loggedInUsersArray.append(user)
//            }
//            print(loggedInUser)
//        }
    }
    
    // MARK: - Chat Controls
    private func getMessageRefrence() -> FIRDatabaseReference {
        let messageRef = viewModel.ref!.child("Chat").child(groupID!)
        messageRef.keepSynced(true)
        return messageRef
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
        if dateTime == nil {
            if let message = JSQMessage.init(senderId: id, displayName: name, text: text) {
                messages.append(message)
            }
        }
        else {
            if let message = JSQMessage(senderId: id, senderDisplayName: name, date: dateTime, text: text) {
                messages.append(message)
            }
        }
    }
    private func addPhotoMessage(withId id: String, key: String, displayName: String, mediaItem: JSQPhotoMediaItem) {
        if let message = JSQMessage(senderId: id, displayName: displayName, media: mediaItem) {
            messages.append(message)
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            collectionView.reloadData()
        }
    }
    private func removeMessage(DeletedChatId deletedChatSenderId: String) {
        var tempChatMessages = messages
        for (index, message) in tempChatMessages.enumerated() {
            if message.senderId == deletedChatSenderId {
                tempChatMessages.remove(at: index - 1)
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
        
        // Create a chat
        isTyping = false
        viewModel.createChat(groupID: groupID!, chatChildName: "Chat", senderName: senderDisplayName, mediaName: nil, chatMessage: text, chatDateTime: date!, mediaType: .Text, mediaData: nil, completionHandler: { (error) in
            self.finishSendingMessage(animated: true)
        })
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
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
        // Create a picture chat
        isTyping = false
        
        var data = NSData()
        data = UIImageJPEGRepresentation(image, 1.0)! as NSData

        // Start Status bar loader
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        viewModel.createChat(groupID: groupID!, chatChildName: "Chat", senderName: senderDisplayName, mediaName: imageName, chatMessage: "", chatDateTime: Date(), mediaType: .Picture, mediaData: data as Data) { (error) in
            self.finishSendingMessage(animated: true)
        }
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
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
                    // set image
                    self.imageDictArray.append(["image": img,
                                           "row": NSNumber.init(value: indexPath.row)])
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
