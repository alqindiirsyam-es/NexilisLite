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
import AVFoundation
import AVKit
import Intents

public class APIS: NSObject {
    private static var isAlertPresented = false
    public static func connect(appName: String, apiKey: String, delegate: ConnectDelegate, showButton: Bool = true, fromMAB: Bool = false) {
        APIS.appNm = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        Nexilis.connect(apiKey: apiKey, delegate: delegate, showButton: showButton, fromMAB: fromMAB)
    }
    
    public static func getTotalCounter() -> Int32 {
        var counter: Int32?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                let query = """
                            select SUM(counter) as total_counter 
                            from (
                                select ms.counter from MESSAGE_SUMMARY ms, MESSAGE m, BUDDY b 
                                where ms.l_pin = b.f_pin and ms.message_id = m.message_id and m.is_call_center = 0
                                union all
                                select ms.counter from MESSAGE_SUMMARY ms, MESSAGE m 
                                where ms.l_pin = '-999' and ms.message_id = m.message_id
                                union all
                                select ms.counter from MESSAGE_SUMMARY ms, MESSAGE m 
                                where ms.l_pin = '-997' and ms.message_id = m.message_id
                                union all
                                select ms.counter from MESSAGE_SUMMARY ms, MESSAGE m, GROUPZ b 
                                where ms.l_pin = b.group_id and ms.message_id = m.message_id and m.is_call_center = 0
                                union all
                                select ms.counter from MESSAGE_SUMMARY ms, MESSAGE m, DISCUSSION_FORUM b, GROUPZ c 
                                where b.group_id = c.group_id and ms.l_pin = b.chat_id and ms.message_id = m.message_id and m.is_call_center = 0
                            ) as subquery
                            """
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query), cursor.next() {
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
        guard !isAlertPresented else { return }
        isAlertPresented = true
        let alert = LibAlertController(title: "Set Profile".localized(), message: "You must set your profile to use this feature".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {(_) in
            isAlertPresented = false
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
            navigationController.setNavigationBarHidden(false, animated: false)
            navigationController.navigationBar.isTranslucent = false
            navigationController.defaultStyle()
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
            }
        } else {
            if media != nil || (media == nil && category != nil) {
                if media == nil || media! < 0 || media! > 2 {
                    UIApplication.shared.visibleViewController?.view.makeToast("108:Invalid Contact Center media parameter (0:Chat, 1:Audio Call, 2:Video Call)".localized(), duration: 3)
                    return
                }
            }
            if category != nil {
                if category != 0 {
                    let service = CategoryCC.getDataFromServiceId(service_id: "\(category!)")
                    if service == nil {
                        UIApplication.shared.visibleViewController?.view.makeToast("109:Invalid Contact Center category parameter".localized(), duration: 3)
                        return
                    }
                    let serviceChilds = CategoryCC.getDatafromParent(parent: service!.service_id)
                    if serviceChilds.count > 0 {
                        UIApplication.shared.visibleViewController?.view.makeToast("109:Invalid Contact Center category parameter".localized(), duration: 3)
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
        let navigationController = CustomNavigationController(rootViewController: controller)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
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
            UIApplication.shared.visibleViewController?.view.makeToast("91:Invalid name or you must add Username to your contact first".localized(), duration: 3)
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
    
    public static func openConference() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let navigationController = CustomNavigationController(rootViewController: CreateSeminarViewController())
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
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
            UIApplication.shared.visibleViewController?.view.makeToast("92:Username is empty".localized(), duration: 3)
            return
        }
        let user = User.getDataFromNameCanNil(name: name)
        if user == nil {
            UIApplication.shared.visibleViewController?.view.makeToast("91:Invalid name or you must add Username to your contact first".localized(), duration: 3)
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
            UIApplication.shared.visibleViewController?.view.makeToast("92:Username is empty".localized(), duration: 3)
            return
        }
        let user = User.getDataFromNameCanNil(name: name)
        if user == nil {
            UIApplication.shared.visibleViewController?.view.makeToast("91:Invalid name or you must add Username to your contact first".localized(), duration: 3)
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
    
    public static func openConversation() {
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
    
    public static func openSecureFolder() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "secureFolderView") as! SecureFolderViewController
        let navigationController = CustomNavigationController(rootViewController: controller)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    public static func openSecureBrowser() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let controller = BNIBookingWebView()
        controller.isSecureBrowser = true
        let navigationController = CustomNavigationController(rootViewController: controller)
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
        if UIApplication.shared.visibleViewController is UINavigationController && (UIApplication.shared.visibleViewController as! UINavigationController).rootViewController is SettingTableViewController {
            return
        }
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
    
    public static func openChatWallpaper(){
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "chatWallpaper") as! ChatWallpaperViewController
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
            UIApplication.shared.visibleViewController?.view.makeToast("92:Username is empty".localized(), duration: 3)
            return
        }
        let user = User.getDataFromNameCanNil(name: name)
        if user == nil {
            UIApplication.shared.visibleViewController?.view.makeToast("91:Invalid name or you must add Username to your contact first".localized(), duration: 3)
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
            UIApplication.shared.visibleViewController?.view.makeToast("92:Username is empty".localized(), duration: 3)
            return
        }
        let user = User.getDataFromNameCanNil(name: name)
        if user == nil {
            UIApplication.shared.visibleViewController?.view.makeToast("91:Invalid name or you must add Username to your contact first".localized(), duration: 3)
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
            UIApplication.shared.visibleViewController?.view.makeToast("113:Password is empty".localized(), duration: 3)
            return
        }
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let isAdmin = User.isAdmin()
        if isAdmin {
            UIApplication.shared.visibleViewController?.view.makeToast("112:You already login or registered as Admin".localized(), duration: 3)
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
            UIApplication.shared.visibleViewController?.view.makeToast("111:You must Sign In as Admin to use this feature".localized(), duration: 3)
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
            UIApplication.shared.visibleViewController?.view.makeToast("102:Duplicate username".localized(), duration: 3)
            return
        }
        if finalUname.count == 0 {
            UIApplication.shared.visibleViewController?.view.makeToast("103:Username is empty".localized(), duration: 3)
            return
        }
        if finalUname.count < 3 {
            UIApplication.shared.visibleViewController?.view.makeToast("104:Username length is too short".localized(), duration: 3)
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
    
    public static func sendPushToken(_ token: String, isResend: Bool = false) {
        DispatchQueue.global().async{
            var isResend = isResend
            if Utils.getTokenAPN().isEmpty || token != Utils.getTokenAPN() || isResend {
                Utils.setTokenAPN(value: token)
                isResend = true
            }
            if isResend {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.getToken(token: token))
            }
        }
    }
    
    public static var uuidCall: UUID?
    public static var fpinCall: String?
    public static func showNotificationNexilis(_ userInfo: [AnyHashable : Any]) {
//        let center = UNUserNotificationCenter.current()
//        let content = UNMutableNotificationContent()
//        content.title = "showNotificationNexilis"
//        content.body = ""
//        content.sound = .default
//        content.userInfo = userInfo
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//        let request = UNNotificationRequest(identifier: "HJK", content: content, trigger: trigger)
//        center.add(request) { error in
//            if let error = error {
//                print("Error scheduling notification: \(error.localizedDescription)")
//            }
//        }
        if checkAppStateisBackground() {
            DispatchQueue.main.async {
                if let payload = userInfo["payload"] as? [String: Any] {
                    if let messagePayload = payload["message"] as? [String: Any] {
                        if let data = messagePayload["data"] as? [String: Any] {
                            let code = data["nx_code"] as? String ?? ""
                            while (!API.bnuSDKServiceReady() || API.nGetCLXConnState() == 0) {
                            }
                            if code == "CL01" {
                                if let message = data["bodies"] as? [String: String] {
                                    let messageToSave = TMessage()
                                    messageToSave.mBodies = message
                                    do {
                                        var messageExist = false
                                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message_id from MESSAGE where message_id = '\(message[CoreMessage_TMessageKey.MESSAGE_ID] ?? "")'"), cursor.next() {
                                                messageExist = true
                                                cursor.close()
                                            }
                                        })
                                        if messageExist {
                                            return
                                        }
                                        Nexilis.saveMessage(message: messageToSave, withStatus: false, fromAPNS: true)
                                        DispatchQueue.global().async {
                                            _ = Nexilis.write(message: CoreMessage_TMessageBank.getAckMessage(messageId: message[CoreMessage_TMessageKey.MESSAGE_ID] ?? ""))
                                        }
                                    } catch {
                                        print("error saving message: \(error)")
                                    }
                                    APIS.addNotificationNexilis(messageToSave)
                                }
                            } else if code == "CL03" {
                                let callFromName = data["call-from-name"] as? String ?? ""
                                let callFrom = data["call-from"] as? String ?? ""
                                let callType = data["call-type"] as? String ?? ""
//                                uuidCall = UUID()
                                fpinCall = callFrom
                                Nexilis.callAPNActivated = true
    //                                    CallManager.shared.reportIncomingCall(uuid: uuidCall!, callerName: callFromName, callerId: callFrom, isVideo: callType != "1") { error in
    //                                        if let error = error {
    //                                            print("Error reporting incoming call: \(error.localizedDescription)")
    //                                        } else {
    //                                            print("Incoming call reported successfully")
    //                                        }
    //                                    }
                                copySoundToLocalPath("pb_call_in", false)
                                let center = UNUserNotificationCenter.current()
                                let content = UNMutableNotificationContent()
                                content.title = callFromName
                                if callType == "1" {
                                    content.body = "Incoming Audio Call".localized()
                                } else {
                                    content.body = "Incoming Video Call".localized()
                                }
                                content.userInfo = ["id" : callFrom, "type" : code, "callType": callType]
                                content.sound = UNNotificationSound(named: UNNotificationSoundName("pb_call_in.mp3"))
                                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                                let request = UNNotificationRequest(identifier: callFrom, content: content, trigger: trigger)
                                center.add(request) { error in
                                    if let error = error {
                                        print("Error scheduling notification: \(error.localizedDescription)")
                                    }
                                }
                            } else if code == "CL02" {
                                let callFrom = data["call-from"] as? String ?? ""
//                                if let uuidCall = uuidCall {
                                    Nexilis.callAPNActivated = false
                                    let center = UNUserNotificationCenter.current()
                                    center.removeDeliveredNotifications(withIdentifiers: [callFrom])
    //                                    CallManager.shared.endCall(with: uuidCall)
//                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public static func addNotificationNexilis(_ message: TMessage) {
        var text = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_TEXT)
        text = text.toNormalString()
        let nameUser = message.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME)
        var threadIdentifier = message.getBody(key: CoreMessage_TMessageKey.OPPOSITE_PIN)
        let scope = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_SCOPE_ID)
        if threadIdentifier.isEmpty {
            if scope == "4" {
                threadIdentifier = message.getBody(key: CoreMessage_TMessageKey.CHAT_ID).isEmpty ? message.getBody(key: CoreMessage_TMessageKey.L_PIN) : message.getBody(key: CoreMessage_TMessageKey.CHAT_ID)
            } else {
                threadIdentifier = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
            }
        }
        let messageId = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
        var nameSubtitle = ""
        let imageId = CoreMessage_TMessageKey.IMAGE_ID
        let videoId = CoreMessage_TMessageKey.VIDEO_ID
        let fileId = CoreMessage_TMessageKey.FILE_ID
        let audioId = CoreMessage_TMessageKey.AUDIO_ID
        let attachmentFlag = CoreMessage_TMessageKey.ATTACHMENT_FLAG
        let messageScopeId = CoreMessage_TMessageKey.MESSAGE_SCOPE_ID
        let credential = CoreMessage_TMessageKey.CREDENTIAL
        let gif_id = CoreMessage_TMessageKey.GIF_ID
        let is_secret = CoreMessage_TMessageKey.IS_SECRET
        if message.getBody(key: is_secret) == "1" {
          text = "You got messages..."
        } else if message.getBody(key: gif_id) != "" {
          text = "Sent GIF 🎬"
        } else if !message.getBody(key: imageId).isEmpty {
            text = "Sent Image 📷"
        } else if message.getBody(key: attachmentFlag) == "11" {
            text = "Sent Sticker ❤️"
        } else if !message.getBody(key: videoId).isEmpty {
            text = "Sent Video 📹"
        } else if !message.getBody(key: fileId).isEmpty {
            if message.getBody(key: messageScopeId) == "18" {
                text = "Sent Form 📄"
            } else {
                text = "Sent File 📄"
            }
        } else if !message.getBody(key: audioId).isEmpty {
            text = "Sent Audio ♫"
        } else if text.contains("Share%20location%20") {
            text = "Sent Location 📌"
        } else if message.getBody(key: attachmentFlag) == "27" {
            text = "Sent Live Streaming"
        } else if message.getBody(key: attachmentFlag) == "26" {
            text = "Sent Seminar"
        } else if message.getBody(key: attachmentFlag) == "25" {
            text = "Sent Video Conference Room"
        } else if message.getBody(key: attachmentFlag) == "24" {
            text = "Sent Quiz"
        } else if message.getBody(key: credential) == "1" {
            text = "Sent Confidential Message"
        }
        var type = "1"
        var nameTopic = "Lounge".localized()
        var idGroup = ""
        if scope == "3" || scope == "18" || scope == "5"{
            type = "0"
        }
        var soundId: String = SecureUserDefaults.shared.value(forKey: "newNotifSoundPersonal") ?? "001:Nexilis Message (Default)"
        if type == "1" {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT title, group_id FROM DISCUSSION_FORUM WHERE chat_id='\(threadIdentifier)'"), cursor.next() {
                        nameTopic = cursor.string(forColumnIndex: 0) ?? ""
                        idGroup = cursor.string(forColumnIndex: 1) ?? ""
                        cursor.close()
                    }
                    if idGroup.isEmpty {
                        idGroup = threadIdentifier
                    }
                    if let cursorGroup = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_name, image_id FROM GROUPZ WHERE group_id='\(idGroup)'"), cursorGroup.next() {
                        let nameGroup = cursorGroup.string(forColumnIndex: 0) ?? ""
                        nameSubtitle = "\(nameGroup) (\(nameTopic))"
                        cursorGroup.close()
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            soundId = SecureUserDefaults.shared.value(forKey: "newNotifSoundGroup") ?? "001:Nexilis Message (Default)"
            if idGroup.isEmpty {
                return
            }
        }
        var nameSound = soundId.components(separatedBy: ":")[1].replacingOccurrences(of: " ", with: "_")
        var fromPref = false
        if nameSound.contains("_(Default)") {
            if !Utils.getDefaultIncomingMsg().isEmpty {
                nameSound = Utils.getDefaultIncomingMsg()
                fromPref = true
            } else {
                nameSound = nameSound.replacingOccurrences(of: "_(Default)", with: "")
            }
        }
        copySoundToLocalPath(nameSound, fromPref)
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = nameUser
        if type == "1" {
            content.body = text.richText(group_id: idGroup).string
            content.subtitle = nameSubtitle
        } else {
            content.body = text.richText().string
        }
        content.userInfo = ["id" : threadIdentifier, "type" : type]
        content.sound = UNNotificationSound(named: UNNotificationSoundName("\(nameSound).mp3"))
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: messageId, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = Int(APIS.getTotalCounter())
        }
    }
    
    private static func copySoundToLocalPath(_ nameSound: String, _ fromPref: Bool) {
        var sourceURL: URL?
        if fromPref {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let audioURL = URL(fileURLWithPath: dirPath).appendingPathComponent(nameSound)
                if FileManager.default.fileExists(atPath: audioURL.path) {
                    sourceURL = audioURL
                } else if FileEncryption.shared.isSecureExists(filename: nameSound) {
                    do {
                        if let audioData = try FileEncryption.shared.readSecure(filename: nameSound) {
                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                            let tempPath = cachesDirectory.appendingPathComponent(nameSound)
                            try audioData.write(to: tempPath)
                            sourceURL = tempPath
                        }
                    } catch {
                        
                    }
                }
            }
        } else {
            sourceURL = Bundle.resourceBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
            if sourceURL == nil {
                sourceURL = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
            }
        }
        let fileManager = FileManager.default
        let soundDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Sounds", isDirectory: true)
        if !fileManager.fileExists(atPath: soundDirectory.path) {
            do {
                try fileManager.createDirectory(at: soundDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating Sounds directory: \(error)")
                return
            }
        }
        let destinationURL = soundDirectory.appendingPathComponent("\(nameSound).mp3")
        if !fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.copyItem(at: sourceURL!, to: destinationURL)
            } catch {
                
            }
        }
    }
    
    public static func openNotificationNexilis(_ response: UNNotificationResponse) {
        DispatchQueue.main.async{
            if let userInfo = response.notification.request.content.userInfo as? [String: String] {
                let id = userInfo["id"] ?? ""
                let type = userInfo["type"] ?? ""
                if let navigationC = UIApplication.shared.visibleViewController as? UINavigationController {
                    if navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorPersonal || navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorGroup {
                        navigationC.popViewController(animated: true)
                    }
                }
                if type == "0" {
                    if User.getDataCanNil(pin: id) == nil {
                        return
                    }
                    let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                    editorPersonalVC.hidesBottomBarWhenPushed = true
                    editorPersonalVC.unique_l_pin = id
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
                    if UIApplication.shared.visibleViewController is UINavigationController && Nexilis.fromMAB {
                        editorPersonalVC.fromNotification = false
                        UIApplication.shared.visibleViewController?.show(editorPersonalVC, sender: nil)
                    } else {
                        UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                    }
                } else if type == "1" {
                    var groupExist = false
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        var idGroup = ""
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT title, group_id FROM DISCUSSION_FORUM WHERE chat_id='\(id)'"), cursor.next() {
                            groupExist = true
                            cursor.close()
                        } else {
                            if idGroup.isEmpty {
                                idGroup = id
                            }
                            if let cursorGroup = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_name, image_id FROM GROUPZ WHERE group_id='\(idGroup)'"), cursorGroup.next() {
                                groupExist = true
                                cursorGroup.close()
                            }
                        }
                    })
                    if !groupExist {
                        return
                    }
                    let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "editorGroupVC") as! EditorGroup
                    editorGroupVC.hidesBottomBarWhenPushed = true
                    editorGroupVC.unique_l_pin = id
                    editorGroupVC.fromNotification = true
                    let navigationController = CustomNavigationController(rootViewController: editorGroupVC)
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
                    if UIApplication.shared.visibleViewController is UINavigationController && Nexilis.fromMAB {
                        editorGroupVC.fromNotification = false
                        UIApplication.shared.visibleViewController?.show(editorGroupVC, sender: nil)
                    } else {
                        UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                    }
                } else if type == "CL03" {
                    let callType = userInfo["callType"] ?? ""
                    if callType == "1" {
                        if let user = User.getData(pin: id), user.firstName == "User".localized() {
                            return
                        }
                        let controller = QmeraAudioViewController()
                        controller.isOutgoing = false
                        controller.user = User.getData(pin: id)
                        controller.autoAcceptAPN = true
                        controller.modalPresentationStyle = .overCurrentContext
                        if UIApplication.shared.visibleViewController is UIAlertController {
                            let vc = UIApplication.shared.visibleViewController as! UIAlertController
                            vc.dismiss(animated: true, completion: {
                                if UIApplication.shared.visibleViewController?.navigationController != nil {
                                    UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
                                } else {
                                    UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
                                }
                            })
                            return
                        }
                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                            UIApplication.shared.visibleViewController?.navigationController?.present(controller, animated: true, completion: nil)
                        } else {
                            UIApplication.shared.visibleViewController?.present(controller, animated: true, completion: nil)
                        }
                    } else {
                        if let user = User.getData(pin: id), user.firstName == "User".localized() {
                            return
                        }
                        let videoController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
                        videoController.fPin = id
                        videoController.isInisiator = false
                        videoController.autoAcceptAPN = true
                        let navigationController = CustomNavigationController(rootViewController: videoController)
                        navigationController.modalPresentationStyle = .fullScreen
                        if UIApplication.shared.visibleViewController is UIAlertController {
                            let vc = UIApplication.shared.visibleViewController as! UIAlertController
                            vc.dismiss(animated: true, completion: {
                                if UIApplication.shared.visibleViewController?.navigationController != nil {
                                    UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                                } else {
                                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                                }
                            })
                            return
                        }
                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                        } else {
                            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
//        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    public static func checkAppStateisBackground() -> Bool {
        let state = UIApplication.shared.applicationState
        
        switch state {
        case .active:
            return false
        case .inactive:
            return false
        case .background:
            return true
        @unknown default:
            return false
        }
    }
    
    public static func enterBackground() {
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    }
    
    public static func enterForeground() {
        APIS.checkNotificationPermission(completion: { isAllowed in
            if !isAllowed {
                showEnableNotificationsAlert()
            } else {
                UIApplication.shared.registerForRemoteNotifications()
            }
        })
        DispatchQueue.global().async {
            do {
                if !Nexilis.afterConnect {
                    var id = Utils.getConnectionID()
                    try API.initConnection(sAPIK: Nexilis.sAPIKey, cbiI: Callback(), sTCPAddr: Nexilis.ADDRESS, nTCPPort: Nexilis.PORT, sUserID: id, sStartWH: "09:00")
                }
//                listIdentifierNotif.removeAll()
                Nexilis.afterConnect = false
            } catch {
            }
        }
        checkDataForShareExtension()
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    private static func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .notDetermined:
                    completion(true) // Notifications are allowed
                case .denied, .ephemeral:
                    completion(false) // Notifications are disabled or not requested
                @unknown default:
                    completion(false)
                }
            }
        }
    }
    
    private static func showEnableNotificationsAlert() {
        guard !isAlertPresented else { return }
        isAlertPresented = true
        let alertController = LibAlertController(
            title: "Enable Notification".localized(),
            message: "To stay updated, please enable notification in the Settings.".localized(),
            preferredStyle: .alert
        )
        
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: "Go to Settings".localized(), style: .default, handler: { _ in
            isAlertPresented = false
            openAppSettings()
        }))
        
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(alertController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    private static func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    public static func willTerminate() {
        Nexilis.destroyAll()
    }
    
    public static func checkDataForShareExtension() {
        DispatchQueue.global().async {
            if let userDefaults = UserDefaults(suiteName: nameGroupShared) {
                if let value = userDefaults.string(forKey: "sharedItem") {
                    if !value.isEmpty {
                        if let jsonData = value.data(using: .utf8) {
                            do {
                                if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                                    let typeImage = 2
                                    let typeVideo = 3
                                    let typeFile = 4
                                    let typeAudio = 5
                                    let typeContact = json["typeContact"] as? String ?? "0"
                                    var data = json["data"] as? String ?? ""
                                    let idContact = json["idContact"] as? String ?? ""
                                    let typeShare = json["typeShare"] as? Int ?? 1
                                    var message = TMessage()
                                    var groupId = ""
                                    var chatId = ""
                                    let scopeId = typeContact == "1" ? "4" : "3"
                                    let thumb = json["thumb"] as? String ?? ""
                                    let imageId = json["image"] as? String ?? ""
                                    let videoId = json["video"] as? String ?? ""
                                    let fileId = json["file"] as? String ?? ""
                                    let audioId = json["audio"] as? String ?? ""
                                    var renamedFileId = ""
                                    var renamedAudioId = ""
                                    var attachmentFlag = ""
                                    if scopeId == "4" {
                                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id id FROM DISCUSSION_FORUM WHERE chat_id = '\(idContact)'"), cursor.next() {
                                                groupId = cursor.string(forColumnIndex: 0) ?? ""
                                                chatId = idContact
                                                cursor.close()
                                            } else {
                                                groupId = idContact
                                            }
                                        })
                                    }
                                    if typeShare == typeImage {
                                        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                            let sharedImageURL = appGroupURL.appendingPathComponent(imageId)
                                            let sharedThumbURL = appGroupURL.appendingPathComponent(thumb)
                                            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                            if FileManager.default.fileExists(atPath: sharedImageURL.path) {
                                                let file = documentDir.appendingPathComponent(imageId)
                                                if !FileManager().fileExists(atPath: file.path) {
                                                    try? FileManager.default.copyItem(at: sharedImageURL, to: file)
                                                }
                                            }
                                            if FileManager.default.fileExists(atPath: sharedThumbURL.path) {
                                                let file = documentDir.appendingPathComponent(thumb)
                                                if !FileManager().fileExists(atPath: file.path) {
                                                    try? FileManager.default.copyItem(at: sharedThumbURL, to: file)
                                                }
                                            }
                                        }
                                        attachmentFlag = "1"
                                    } else if typeShare == typeVideo {
                                        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                            let sharedVideoURL = appGroupURL.appendingPathComponent(videoId)
                                            let sharedThumbURL = appGroupURL.appendingPathComponent(thumb)
                                            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                            if FileManager.default.fileExists(atPath: sharedVideoURL.path) {
                                                let file = documentDir.appendingPathComponent(videoId)
                                                if !FileManager().fileExists(atPath: file.path) {
                                                    try? FileManager.default.copyItem(at: sharedVideoURL, to: file)
                                                }
                                            }
                                            if FileManager.default.fileExists(atPath: sharedThumbURL.path) {
                                                let file = documentDir.appendingPathComponent(thumb)
                                                if !FileManager().fileExists(atPath: file.path) {
                                                    try? FileManager.default.copyItem(at: sharedThumbURL, to: file)
                                                }
                                            }
                                        }
                                        attachmentFlag = "2"
                                    } else if typeShare == typeFile {
                                        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                            renamedFileId = "Nexilis_\(Date().currentTimeMillis())_" + fileId
                                            let sharedFileURL = appGroupURL.appendingPathComponent(fileId)
                                            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                            if FileManager.default.fileExists(atPath: sharedFileURL.path) {
                                                let file = documentDir.appendingPathComponent(renamedFileId)
                                                if !FileManager().fileExists(atPath: file.path) {
                                                    try? FileManager.default.copyItem(at: sharedFileURL, to: file)
                                                }
                                            }
                                            data = "\(fileId)|\(data)"
                                        }
                                        attachmentFlag = "6"
                                    } else if typeShare == typeAudio {
                                        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                            renamedAudioId = "Nexilis_\(Date().currentTimeMillis())_" + audioId
                                            let sharedFileURL = appGroupURL.appendingPathComponent(audioId)
                                            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                            if FileManager.default.fileExists(atPath: sharedFileURL.path) {
                                                let file = documentDir.appendingPathComponent(renamedAudioId)
                                                if !FileManager().fileExists(atPath: file.path) {
                                                    try? FileManager.default.copyItem(at: sharedFileURL, to: file)
                                                }
                                            }
                                            data = "\(audioId)|\(data)"
                                        }
                                        attachmentFlag = "5"
                                    }
                                    message = CoreMessage_TMessageBank.sendMessage(l_pin: groupId.isEmpty ? idContact : groupId, message_scope_id: scopeId, status: scopeId == "3" ? "1" : "2", message_text: data, credential: "0", attachment_flag: attachmentFlag, ex_blog_id: "", message_large_text: "", ex_format: "", image_id: imageId, audio_id: renamedAudioId, video_id: videoId, file_id: renamedFileId, thumb_id: thumb, reff_id: "", read_receipts: "4", chat_id: chatId, is_call_center: "0", call_center_id: "", opposite_pin: scopeId == "3" ? (User.getMyPin() ?? "") : idContact, gif_id: "", isForwarded: "0", isSecret: "0")
                                    Nexilis.addQueueMessage(message: message)
                                    userDefaults.set("", forKey: "sharedItem")
                                    userDefaults.synchronize()
                                }
                            } catch {
                                print("Error parsing JSON: \(error)")
                            }
                        }
                    }
                }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5, execute: {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
            })
        }
    }
    
    public static func setDataForShareExtension() {
        DispatchQueue.global().async {
            if let userDefaults = UserDefaults(suiteName: nameGroupShared) {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    var dataShared: [[String: Any]] = []
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin id, image_id image, first_name || ' ' || ifnull(last_name, '') name FROM BUDDY WHERE f_pin != '\(User.getMyPin() ?? "")' AND f_pin != '-997' AND official_account != '1'") {
                        while cursor.next() {
                            var dataTemp: [String: Any] = [:]
                            for columnIndex in 0..<cursor.columnCount {
                                if let columnName = cursor.columnName(for: columnIndex) {
                                    if let value = cursor.object(forColumn: columnName) {
                                        if columnName == "image" {
                                           dataTemp[columnName] = value
                                           if let imageString = dataTemp[columnName] as? String, !imageString.isEmpty {
                                               do {
                                                   let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                                   let file = documentDir.appendingPathComponent(imageString)
                                                   if FileManager().fileExists(atPath: file.path) {
                                                       if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                                           let sharedFileURL = appGroupURL.appendingPathComponent(imageString)
                                                           if !FileManager.default.fileExists(atPath: sharedFileURL.path) {
                                                               try? FileManager.default.copyItem(at: file, to: sharedFileURL)
                                                           }
                                                       }
                                                   }
                                               } catch {
                                                   
                                               }
                                           }
                                        } else {
                                            dataTemp[columnName] = value
                                        }
                                        dataTemp["type"] = 0
                                    }
                                }
                            }
                            dataShared.append(dataTemp)
                        }
                        cursor.close()
                    }
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id id, image_id image, f_name name FROM GROUPZ WHERE official != 1") {
                        while cursor.next() {
                            var dataTemp: [String: Any] = [:]
                            for columnIndex in 0..<cursor.columnCount {
                                if let columnName = cursor.columnName(for: columnIndex) {
                                    if let value = cursor.object(forColumn: columnName) {
                                        if columnName == "name" {
                                            dataTemp[columnName] = "\(value) (Lounge)"
                                        } else if columnName == "image" {
                                            dataTemp[columnName] = value
                                            if let imageString = dataTemp[columnName] as? String, !imageString.isEmpty {
                                                do {
                                                    let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                                    let file = documentDir.appendingPathComponent(imageString)
                                                    if FileManager().fileExists(atPath: file.path) {
                                                        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                                            let sharedFileURL = appGroupURL.appendingPathComponent(imageString)
                                                            if !FileManager.default.fileExists(atPath: sharedFileURL.path) {
                                                                try? FileManager.default.copyItem(at: file, to: sharedFileURL)
                                                            }
                                                        }
                                                    }
                                                } catch {
                                                    
                                                }
                                            }
                                        } else {
                                            dataTemp[columnName] = value
                                        }
                                        dataTemp["type"] = 1
                                    }
                                }
                            }
                            dataShared.append(dataTemp)
                            let group_id = cursor.string(forColumnIndex: 0) ?? ""
                            let image_group = cursor.string(forColumnIndex: 1) ?? ""
                            let name_group = cursor.string(forColumnIndex: 2) ?? ""
                            if let cursorTopic = Database.shared.getRecords(fmdb: fmdb, query: "SELECT chat_id id, thumb image, title name FROM DISCUSSION_FORUM WHERE group_id = '\(group_id)'") {
                                while cursorTopic.next() {
                                    var dataTempTopic: [String: Any] = [:]
                                    for columnIndex in 0..<cursorTopic.columnCount {
                                        if let columnName = cursorTopic.columnName(for: columnIndex) {
                                            if let value = cursorTopic.object(forColumn: columnName) {
                                                if columnName == "name" {
                                                    dataTempTopic[columnName] = "\(name_group) (\(value))"
                                                } else if columnName == "image" {
                                                    dataTempTopic[columnName] = "\(value)".isEmpty ? image_group : "\(value)"
                                                    if let imageString = dataTempTopic[columnName] as? String, !imageString.isEmpty {
                                                        do {
                                                            let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                                            let file = documentDir.appendingPathComponent(imageString)
                                                            if FileManager().fileExists(atPath: file.path) {
                                                                if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                                                    let sharedFileURL = appGroupURL.appendingPathComponent(imageString)
                                                                    if !FileManager.default.fileExists(atPath: sharedFileURL.path) {
                                                                        try? FileManager.default.copyItem(at: file, to: sharedFileURL)
                                                                    }
                                                                }
                                                            }
                                                        } catch {
                                                            
                                                        }
                                                    }
                                                } else {
                                                    dataTempTopic[columnName] = value
                                                }
                                                dataTempTopic["type"] = 1
                                            }
                                        }
                                    }
                                    dataShared.append(dataTempTopic)
                                }
                                cursorTopic.close()
                            }
                        }
                        cursor.close()
                    }
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dataShared, options: .prettyPrinted)
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            userDefaults.set(jsonString, forKey: "shareContacts")
                            userDefaults.synchronize()
                        }
                    } catch {
                        print("Error converting to JSON: \(error)")
                    }
                })
            }
        }
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
    
    public static func setNameGroupShare(_ name: String) {
        nameGroupShared = name
    }
    
    public static func openImageNexilis(image: UIImage, data: Data? = nil, isGIF: Bool = false) {
        let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
        previewImageVC.image = image
        previewImageVC.isHiddenTextField = true
        previewImageVC.isGIF = isGIF
        previewImageVC.dataGIF = data
        previewImageVC.modalPresentationStyle = .custom
        previewImageVC.modalTransitionStyle  = .crossDissolve
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(previewImageVC, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(previewImageVC, animated: true, completion: nil)
        }
    }
    
    public static func openVideoNexilis(videoURL: URL) {
        let player = AVPlayer(url: videoURL)
        let playerVC = AVPlayerViewController()
        playerVC.modalPresentationStyle = .custom
        playerVC.player = player
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(playerVC, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(playerVC, animated: true, completion: nil)
        }
    }
    
    private static var appNm = "";
    public static func getAppNm() -> String {
        return appNm
    }
    
    private static var nameGroupShared = "group.nexilis.share";
    public static func getnameGroupShared() -> String {
        return nameGroupShared
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
