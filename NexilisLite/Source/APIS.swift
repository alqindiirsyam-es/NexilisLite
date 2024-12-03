//
//  APIS.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 05/05/23.
//

import Foundation
import UIKit
import FMDB
import NotificationBannerSwift
import Toast_Swift
import nuSDKService

public class APIS: NSObject {
    public static func connect(appName: String, apiKey: String, delegate: ConnectDelegate, showButton: Bool = true, fromMAB: Bool = false) {
        APIS.appNm = appName
        Nexilis.connect(apiKey: apiKey, delegate: delegate, showButton: showButton, fromMAB: fromMAB)
    }
    
    public static func getTotalCounter() -> Int32 {
        var counter: Int32?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT SUM(counter) FROM MESSAGE_SUMMARY"), cursor.next() {
                    counter = cursor.int(forColumnIndex: 0)
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return counter ?? 0
    }
    
    private static func showChangeProfile() {
        let alert = LibAlertController(title: "Change Profile".localized(), message: "You must change your name to use this feature".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {(_) in
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "signupsignin") as! SignUpSignIn
            controller.forceLogin = true
            let navigationController = CustomNavigationController(rootViewController: controller)
            navigationController.defaultStyle()
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
            }
        }))
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    public static func openContactCenter(media: Int? = nil, category: Int? = nil) {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        if User.isCallCenter(userType: (User.getData(pin: User.getMyPin())?.userType)!) {
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "myHistoryCC") as! HistoryCCViewController
            controller.isOfficer = true
            controller.fromAPI = true
            let navigationController = CustomNavigationController(rootViewController: controller)
            navigationController.defaultStyle()
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
            }
        } else {
            if media != nil || (media == nil && category != nil) {
                if media == nil || media! < 0 || media! > 2 {
                    UIApplication.shared.visibleViewController?.view.makeToast("108:Invalid Contact Center media parameter (0:Chat, 1:Audio Call, 2:Video Call)".localized(), duration: 2)
                    return
                }
            }
            if category != nil {
                if category != 0 {
                    let service = CategoryCC.getDataFromServiceId(service_id: "\(category!)")
                    if service == nil {
                        UIApplication.shared.visibleViewController?.view.makeToast("109:Invalid Contact Center category parameter".localized(), duration: 2)
                        return
                    }
                    let serviceChilds = CategoryCC.getDatafromParent(parent: service!.service_id)
                    if serviceChilds.count > 0 {
                        UIApplication.shared.visibleViewController?.view.makeToast("109:Invalid Contact Center category parameter".localized(), duration: 2)
                        return
                    }
                }
            }
            let isWaitingRequestCC: Bool = SecureUserDefaults.shared.value(forKey: "waitingRequestCC") ?? false
            if isWaitingRequestCC {
                let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "You have requested Call Center, please wait for response.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            controller.isContactCenter = true
            if media != nil {
                controller.isDirectCC = true
                controller.channelContactCenter = "\(media!)"
                controller.serviceIdCC = category == nil ? "" : "\(category!)"
            }
            let navigationController = CustomNavigationController(rootViewController: controller)
            navigationController.defaultStyle()
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    public static func openUrl(url: String) {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let controller = BNIBookingWebView()
        controller.customUrl = url
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
        }
    }
    
    public static func openNotificationCenter() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let controller = HistoryBroadcastViewController()
        let navigationController = CustomNavigationController(rootViewController: controller)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func openChat() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let navigationController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
        Utils.addBackground(view: navigationController.view)
        let vc = navigationController.topViewController as! ContactChatViewController
        vc.noUCList = true
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func openSmartChatbot() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let smartChatVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "chatGptVC") as! ChatGPTBotView
        smartChatVC.hidesBottomBarWhenPushed = true
        let navigationController = CustomNavigationController(rootViewController: smartChatVC)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func startChat(name: String) {
        if name.isEmpty {
            UIApplication.shared.visibleViewController?.view.makeToast("92:Username is empty".localized(), duration: 2)
            return
        }
        let user = User.getDataFromNameCanNil(name: name)
        if user == nil {
            UIApplication.shared.visibleViewController?.view.makeToast("91:Invalid name or you must add Username to your contact first".localized(), duration: 2)
            return
        }
        let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
        editorPersonalVC.hidesBottomBarWhenPushed = true
        editorPersonalVC.unique_l_pin = user!.pin
        editorPersonalVC.fromNotification = true
        let navigationController = CustomNavigationController(rootViewController: editorPersonalVC)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.navigationBar.tintColor = .white
        navigationController.navigationBar.barTintColor = UIApplication.shared.visibleViewController?.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.overrideUserInterfaceStyle = .dark
        navigationController.navigationBar.barStyle = .black
        let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController.navigationBar.titleTextAttributes = textAttributes
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func openCall() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let callContact = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactSID")
        let navigationController = CustomNavigationController(rootViewController: callContact)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func openStreaming() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let navigationController = CustomNavigationController(rootViewController: QmeraCreateStreamingViewController())
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
//    public static func openSeminar() {
//        let isChangeProfile = Utils.getSetProfile()
//        if !isChangeProfile {
//            APIS.showChangeProfile()
//            return
//        }
//        let navigationController = CustomNavigationController(rootViewController: CreateSeminarViewController())
//        navigationController.defaultStyle()
//        if UIApplication.shared.visibleViewController?.navigationController != nil {
//            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
//        } else {
//            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
//        }
//    }
    
    public static func openAudioCall() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let callContact = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactSID") as! ContactCallViewController
        callContact.onlyAudioOrVideo = 1
        let navigationController = CustomNavigationController(rootViewController: callContact)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func startAudioCall(name: String) {
        if name.isEmpty {
            UIApplication.shared.visibleViewController?.view.makeToast("92:Username is empty".localized(), duration: 2)
            return
        }
        let user = User.getDataFromNameCanNil(name: name)
        if user == nil {
            UIApplication.shared.visibleViewController?.view.makeToast("91:Invalid name or you must add Username to your contact first".localized(), duration: 2)
            return
        }
        if !CheckConnection.isConnectedToNetwork() {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        let controller = QmeraAudioViewController()
        controller.user = user
        controller.isOutgoing = true
        controller.modalPresentationStyle = .overFullScreen
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
        }
    }
    
    public static func openVideoCall() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let callContact = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactSID") as! ContactCallViewController
        callContact.onlyAudioOrVideo = 2
        let navigationController = CustomNavigationController(rootViewController: callContact)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func startVideoCall(name: String) {
        if name.isEmpty {
            UIApplication.shared.visibleViewController?.view.makeToast("92:Username is empty".localized(), duration: 2)
            return
        }
        let user = User.getDataFromNameCanNil(name: name)
        if user == nil {
            UIApplication.shared.visibleViewController?.view.makeToast("91:Invalid name or you must add Username to your contact first".localized(), duration: 2)
            return
        }
        if !CheckConnection.isConnectedToNetwork() {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        let videoVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
        var data: [String: String?] = [:]
        data["f_pin"] = user!.pin
        data["name"] = user!.fullName
        data["picture"] = user!.thumb
        data["isOfficial"] = user!.official
        data["deviceId"] = user!.device_id
        data["isOffline"] = user!.offline_mode
        data["user_type"] = user!.userType
        videoVC.dataPerson.append(data)
        videoVC.isPresent = true
        videoVC.modalPresentationStyle = .overFullScreen
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(videoVC, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(videoVC, animated: true, completion: nil)
        }
    }
    
    public static func openBroadcastForm() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "broadcastNav")
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
        }
    }
    
    public static func startConversation() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let navigationController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
        Utils.addBackground(view: navigationController.view)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func openFavoriteMessage() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let editorStaredVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "staredVC") as! EditorStarMessages
        editorStaredVC.fromNotification = true
        let navigationController = CustomNavigationController(rootViewController: editorStaredVC)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func openCreateGroup() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "createGroupNav") as! UINavigationController
        Utils.addBackground(view: controller.view)
        let vc = controller.topViewController as! GroupCreateViewController
        vc.isDismiss = { id in
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "groupDetailView") as! GroupDetailViewController
            controller.data = id
            controller.fromNotification = true
            let navigationController = CustomNavigationController(rootViewController: controller)
            navigationController.defaultStyle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                }
            })
        }
        controller.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
        }
    }
    
    public static func openAddFriend() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "addFriendNav") as! UINavigationController
        Utils.addBackground(view: controller.view)
        controller.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
        }
    }
    
    public static func openSignUpOrSignIn() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "signupsignin") as! SignUpSignIn
        controller.forceLogin = true
        let navigationController = CustomNavigationController(rootViewController: controller)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func openSetting() {
        let navigationController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "settingNav") as! UINavigationController
        let vc = navigationController.rootViewController as! SettingTableViewController
        vc.fromAPI = true
        Utils.addBackground(view: navigationController.view)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func openProfile() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
        controller.data = User.getMyPin()!
        controller.flag = .me
        controller.fromAPI = true
        controller.dismissImage = { image, imageName in
            var dataImage: [AnyHashable : Any] = [:]
            dataImage["name"] = imageName
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
        }
        let navigationController = CustomNavigationController(rootViewController: controller)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func openWhiteboard() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let callContact = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactSID") as! ContactCallViewController
        callContact.startWhiteBoard = true
        let navigationController = CustomNavigationController(rootViewController: callContact)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func startWhiteboard(name: String) {
        if name.isEmpty {
            UIApplication.shared.visibleViewController?.view.makeToast("92:Username is empty".localized(), duration: 2)
            return
        }
        let user = User.getDataFromNameCanNil(name: name)
        if user == nil {
            UIApplication.shared.visibleViewController?.view.makeToast("91:Invalid name or you must add Username to your contact first".localized(), duration: 2)
            return
        }
        if !CheckConnection.isConnectedToNetwork() {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "wbVC") as! WhiteboardViewController
        controller.modalPresentationStyle = .overFullScreen
        controller.fromContact = 0
        controller.user = user
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
        }
    }
    
//    public static func openScreenSharing() {
//        let isChangeProfile = Utils.getSetProfile()
//        if !isChangeProfile {
//            APIS.showChangeProfile()
//            return
//        }
//        let callContact = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactSID") as! ContactCallViewController
//        callContact.startSS = true
//        let navigationController = CustomNavigationController(rootViewController: callContact)
//        navigationController.defaultStyle()
//        if UIApplication.shared.visibleViewController?.navigationController != nil {
//            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
//        } else {
//            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
//        }
//    }
    
    public static func startScreenSharing(name: String) {
        if name.isEmpty {
            UIApplication.shared.visibleViewController?.view.makeToast("92:Username is empty".localized(), duration: 2)
            return
        }
        let user = User.getDataFromNameCanNil(name: name)
        if user == nil {
            UIApplication.shared.visibleViewController?.view.makeToast("91:Invalid name or you must add Username to your contact first".localized(), duration: 2)
            return
        }
        if !CheckConnection.isConnectedToNetwork() {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        let controller = ScreenSharingViewController()
        controller.modalPresentationStyle = .overFullScreen
        controller.fromContact = 0
        controller.user = user
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
        }
    }
    
    public static func openWhiteboardAndScreenSharing() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let callContact = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactSID") as! ContactCallViewController
        callContact.startSS = true
        callContact.startWhiteBoard = true
        let navigationController = CustomNavigationController(rootViewController: callContact)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func signInAdmin(password: String) {
        if password.isEmpty {
            UIApplication.shared.visibleViewController?.view.makeToast("113:Password is empty".localized(), duration: 2)
            return
        }
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let isAdmin = User.isAdmin()
        if isAdmin {
            UIApplication.shared.visibleViewController?.view.makeToast("112:You already login or registered as Admin".localized(), duration: 2)
            return
        }
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        Nexilis.showLoader()
        self.signInAdmin(password: password, completion: { result in
            if result {
                DispatchQueue.main.async {
                    Nexilis.hideLoader {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Successfully Sign-In Admin".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    Nexilis.hideLoader {}
                }
            }
        })
    }
    
    private static func signInAdmin(password: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            let idMe = User.getMyPin() as String?
            let p_password = password
            let md5Hex = p_password
            var result: Bool = false
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignInApiAdmin(p_name: idMe!, p_password: md5Hex)) {
                if response.isOk() {
                    result = true
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                    banner.show()
                }
            }
            completion(result)
        }
    }
    
    public static func openSetAsOfficerForm() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let isAdmin = User.isAdmin()
        if !isAdmin {
            UIApplication.shared.visibleViewController?.view.makeToast("111:You must Sign In as Admin to use this feature".localized(), duration: 2)
            return
        }
        let controller = SetInternalCSAccount()
        controller.isSetCS = true
        controller.fromNotification = true
        let navigationController = CustomNavigationController(rootViewController: controller)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func sendSMS(phoneNumber: String, message: String = ""){
        let formattedNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
        let urlStringEncoded = message.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let paramMessage = message.isEmpty ? "" : "&body=\(urlStringEncoded!)"
        let url = URL(string: "sms:\(formattedNumber)\(paramMessage)")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!)
        }
    }
    
    public static func sendWhatsapp(phoneNumber: String, message: String = "") {
        let formattedNumber = phoneNumber.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "-", with: "")
        let urlStringEncoded = message.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let paramMessage = message.isEmpty ? "" : "?text=\(urlStringEncoded!)"
        let url  = URL(string: "https://wa.me/\(formattedNumber)\(paramMessage)")
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!, options: [:]) { (success) in
//                if success {
//                    //print("WhatsApp accessed successfully")
//                } else {
//                    //print("Error accessing WhatsApp")
//                }
            }
        }
    }
    
    public static func changeUsername(uname: String) {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let finalUname = uname.replacingOccurrences(of: "[\\n\\r\\t~%()\"]", with: "", options: .regularExpression)
        if finalUname == User.getData(pin: User.getMyPin())?.fullName {
            UIApplication.shared.visibleViewController?.view.makeToast("102:Duplicate username".localized(), duration: 2)
            return
        }
        if finalUname.count == 0 {
            UIApplication.shared.visibleViewController?.view.makeToast("103:Username is empty".localized(), duration: 2)
            return
        }
        if finalUname.count < 3 {
            UIApplication.shared.visibleViewController?.view.makeToast("104:Username length is too short".localized(), duration: 2)
            return
        }
        let a = finalUname.split(separator: " ", maxSplits: 1)
        let first = String(a[0])
        let last = a.count == 2 ? String(a[1]) : ""
        DispatchQueue.global().async {
            if let resp = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangePersonInfoName(firstname: first, lastname: last)) {
                if resp.isOk() {
                    Database.shared.database?.inTransaction({ fmdb, rollback in
                        do {
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: ["first_name": first , "last_name": last], _where: "f_pin = '\(User.getMyPin())'")
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateFifthTab"), object: nil, userInfo: nil)
                    DispatchQueue.main.async {
                        Nexilis.hideLoader {
                            let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Successfully changed name".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                    }
                } else if resp.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "1a" {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username has been registered, please use another name".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            }
        }
    }
    
    public static func openMail() {
        Nexilis.openmailAction()
    }
    
    public static func setCheckEmulator(isActive: Bool) {
//        Utils.bCheckEmulator = isActive
    }
    
    public static func setCheckRootedDevice(isActive: Bool) {
//        Utils.bCheckRooted = isActive
    }
    
    public static func setPreventScreenCapture(isActive: Bool) {
//        Utils.bPreventScreenCapture = isActive
    }
    
    private static var appNm = "";
    public static func getAppNm() -> String {
        return appNm
    }
}

extension UINavigationController {
    func defaultStyle() {
        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        self.modalPresentationStyle = .fullScreen
        self.navigationBar.tintColor = .white
        self.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        self.navigationBar.isTranslucent = false
        self.navigationBar.overrideUserInterfaceStyle = .dark
        self.navigationBar.barStyle = .black
        let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        self.navigationBar.titleTextAttributes = textAttributes
    }
}
