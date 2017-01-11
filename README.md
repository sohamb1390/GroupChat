# GroupChat
This is a Group Chat Application using Google Firebase as backend.
A user can register him/herself into this application using a mail id. Once the user register him/herself, a mail will be triggered
to his/her mailbox which has to be verified by clicking on the verification link in order to get completely registered for this application.
Once the user gets into the application, an alert message will come which will notify the user to create atleast one group to 
continue chatting, else the user can get into any registered group if he/she know the group's credential. Yes, each group is having
a password to get into it.Once the user gets into any group, he/she can view all the messages of every other users who are also
part of that group. Initialy I kept the messaging into two parts 1) Text Message & 2) Picture Messaging.

I will keep this repo upadted with new enhancements & fetaures once I complete it.

To complete the Chat Screen I have used "JSQMessagesViewcontroller" (https://github.com/jessesquires/JSQMessagesViewController)
Apart from that I have couple of 3rd party libraries like:

1. JJMaterialTextField (https://github.com/juanjoguevara/JJMaterialTextField)
2. KRProgressHUD (https://github.com/krimpedance/KRProgressHUD)
3. OpinionzAlertView (https://github.com/Opinionz/OpinionzAlertView)
4. PopupDialog (https://github.com/Orderella/PopupDialog)
5. SwiftMessages (https://github.com/SwiftKickMobile/SwiftMessages)

and most importantly Firebase 4.0 pod


I have tried to use the MVVM pattern in this project as I am totally new into this. Please feel free to contact me over the mail
(sohamb.1390@gmail.com) if you see any mistakes. I am always happy to learn from you. :)


[![Sign In Screen](https://github.com/sohamb1390/GroupChat/blob/master/Simulator%20Screen%20Shot%2008-Jan-2017%2C%2012.22.43%20AM.png)](#features)
[![Sign Up Screen](https://github.com/sohamb1390/GroupChat/blob/master/Simulator%20Screen%20Shot%2008-Jan-2017%2C%2012.22.45%20AM.png)](#features)
[![Group List Screen](https://github.com/sohamb1390/GroupChat/blob/master/Simulator%20Screen%20Shot%2008-Jan-2017%2C%2012.23.01%20AM.png)](#features)
[![Chat Screen](https://github.com/sohamb1390/GroupChat/blob/master/UNADJUSTEDNONRAW_thumb_8b.jpg)](#features)


If you want to use it in your personal project the you have to do the following things:
1. CREATE A FIREBASE IOS APP IN YOUR OWN FIREBASE ACCOUNT USING THE APP NAME, BUNDLE ID.
2. YOU WILL GET A GOOGLESERVICES.PLIST FILE ONCE YOU COMPLETE YOUR PROJECT SETUP ON FIREBASE.
3. REPLACE THE EXISTING GOOGLESERVICES.PLIAT FILE WITH THE NEW ONE
4. CHANGE THE APP NAME AND BUNDLE ID ACCORDING TO YOUR NEWLY CREATED PROJECT.
5. CHANGE THE FIRSTORAGE URL.
6. HAPPY CODING 
