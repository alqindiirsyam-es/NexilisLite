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
    private static var transitioningDelegateRef: ZoomTransitioningDelegate?
    public static func connect(appName: String, apiKey: String, userName: String = "", delegate: ConnectDelegate, showButton: Bool = true, fromMAB: Bool = false) {
        APIS.appNm = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        Nexilis.connect(apiKey: apiKey, userId: userName, delegate: delegate, showButton: showButton, fromMAB: fromMAB)
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
            guard let controller = APIS.getControllerSign() else { return }
            if let controller = controller as? SignUpSignIn {
                controller.forceLogin = true
            } else if let controller = controller as? SignInOption {
                controller.forceLogin = true
            }
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
        if !Nexilis.checkingAccess(key: "call_center") {
            if Nexilis.checkingAccessAlert(key: "call_center") != "|" && !Nexilis.checkingAccessAlert(key: "call_center").isEmpty {
                let title = Nexilis.checkingAccessAlert(key: "call_center").components(separatedBy: "|")[0]
                let message = Nexilis.checkingAccessAlert(key: "call_center").components(separatedBy: "|")[1]
                APIS.nexilisShowAlertWithHTMLMessage(on: UIApplication.shared.visibleViewController ?? UIViewController(), title: title, message: message)
            } else {
                UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
            }
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
    
    public static func openContactCenterWithContext(context: String) {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        if !Nexilis.checkingAccess(key: "call_center") {
            if Nexilis.checkingAccessAlert(key: "call_center") != "|" && !Nexilis.checkingAccessAlert(key: "call_center").isEmpty {
                let title = Nexilis.checkingAccessAlert(key: "call_center").components(separatedBy: "|")[0]
                let message = Nexilis.checkingAccessAlert(key: "call_center").components(separatedBy: "|")[1]
                APIS.nexilisShowAlertWithHTMLMessage(on: UIApplication.shared.visibleViewController ?? UIViewController(), title: title, message: message)
            } else {
                UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
            }
            return
        }
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
        controller.isContactCenter = true
        controller.contextCC = context
        let navigationController = CustomNavigationController(rootViewController: controller)
        navigationController.defaultStyle()
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
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
        if !Nexilis.checkingAccess(key: "notification_center") {
            UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
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
    
    public static func openChat(withoutUCList: Bool = false) {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let navigationController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
        Utils.addBackground(view: navigationController.view)
        let vc = navigationController.topViewController as! ContactChatViewController
        vc.noUCList = withoutUCList
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
        if !Nexilis.checkingAccess(key: "live_streaming") {
            if Nexilis.checkingAccessAlert(key: "live_streaming") != "|" && !Nexilis.checkingAccessAlert(key: "live_streaming").isEmpty {
                let title = Nexilis.checkingAccessAlert(key: "live_streaming").components(separatedBy: "|")[0]
                let message = Nexilis.checkingAccessAlert(key: "live_streaming").components(separatedBy: "|")[1]
                APIS.nexilisShowAlertWithHTMLMessage(on: UIApplication.shared.visibleViewController ?? UIViewController(), title: title, message: message)
            } else {
                UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
            }
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
        if !Nexilis.checkingAccess(key: "vconf_room") {
            if Nexilis.checkingAccessAlert(key: "vconf_room") != "|" && !Nexilis.checkingAccessAlert(key: "vconf_room").isEmpty {
                let title = Nexilis.checkingAccessAlert(key: "vconf_room").components(separatedBy: "|")[0]
                let message = Nexilis.checkingAccessAlert(key: "vconf_room").components(separatedBy: "|")[1]
                APIS.nexilisShowAlertWithHTMLMessage(on: UIApplication.shared.visibleViewController ?? UIViewController(), title: title, message: message)
            } else {
                UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
            }
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
        if !Nexilis.checkingAccess(key: "audio_call") {
            UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
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
        if !Nexilis.checkingAccess(key: "audio_call") {
            UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
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
        if !Nexilis.checkingAccess(key: "video_call") {
            UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
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
        if !Nexilis.checkingAccess(key: "video_call") {
            UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
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
        if !Nexilis.checkingAccess(key: "broadcast_message") {
            UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
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
    
    private static var mfaCallback: ((String) -> Void)?

    static func getMFACallback() -> ((String) -> Void)? {
        return mfaCallback
    }

    public static func setMFACallback(_ callback: @escaping (String) -> Void) {
        mfaCallback = callback
    }
    
    public static func openMFA(method: String, flag: Int){
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        if flag == MFAViewController.STEP_NEEDED_FIDO {
            DispatchQueue.global().async {
                if let me = User.getMyPin() {
                    do {
                        let message = CoreMessage_TMessageBank.getMFAValidation(data: me)
                        var hasKey = false
                        if !KeyManagerNexilis.hasGeneratedKey() {
                            KeyManagerNexilis.generateKey()
                            KeyManagerNexilis.saveMarker()
                        } else {
                            hasKey = true
                        }
                        guard let privateKey = KeyManagerNexilis.getPrivateKey(useBiometric: false) else {
                            KeyManagerNexilis.deleteKey()
                            KeyManagerNexilis.deleteMarker()
                            DispatchQueue.main.async {
                                let errorMessage = "Failed to get Private Key"
                                let dialog = DialogErrorMFA()
                                dialog.modalTransitionStyle = .crossDissolve
                                dialog.modalPresentationStyle = .overCurrentContext
                                dialog.errorDesc = errorMessage
                                dialog.method = method
                                UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                APIS.getMFACallback()?("Failed: \(errorMessage)")
                            }
                            return
                        }
                        if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChalanger()) {
                            if response.isOk() {
                                let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
                                if data.isEmpty {
                                    DispatchQueue.main.async {
                                        let errorMessage = "Failed to get Auth Data"
                                        let dialog = DialogErrorMFA()
                                        dialog.modalTransitionStyle = .crossDissolve
                                        dialog.modalPresentationStyle = .overCurrentContext
                                        dialog.errorDesc = errorMessage
                                        dialog.method = method
                                        UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                        APIS.getMFACallback()?("Failed: \(errorMessage)")
                                    }
                                    return
                                }
                                let df = HMACDeviceFingerprintNexilis.generate()
                                message.mBodies[CoreMessage_TMessageKey.FINGERPRINT] = df
                                if hasKey {
                                    var sign = ""
                                    if let dataSign = "\(data)!\(df)".data(using: .utf8) {
                                        if let signature = KeyManagerNexilis.sign(data: dataSign, privateKey: privateKey) {
                                            sign = signature.base64EncodedString()
                                        }
                                    }
                                    message.mBodies[CoreMessage_TMessageKey.SIGNATURE] = sign
                                } else {
                                    if let publicKey = KeyManagerNexilis.getRSAX509PublicKeyBase64(privateKey: privateKey) {
                                        message.mBodies[CoreMessage_TMessageKey.PUBLIC_KEY] = publicKey
                                    }
                                }
                                let secret = "JBSWY3DPEHPK3PXP" // Google Authenticator example
                                let otp = try TOTPGenerator.generateTOTP(base32Secret: secret, digits: 6, timeStepSeconds: 30)
                                message.mBodies[CoreMessage_TMessageKey.TOTP] = otp
                                if let response = Nexilis.writeAndWait(message: message) {
                                    if response.isOk() {
                                        DispatchQueue.main.async {
                                            UIApplication.shared.visibleViewController?.view.makeToast("Successfully Authenticated".localized(), duration: 3)
                                        }
                                        APIS.getMFACallback()?("Success")
                                    }
                                    else {
                                        let errorMessage = response.getBody(key: CoreMessage_TMessageKey.MESSAGE_TEXT)
                                        DispatchQueue.main.async {
                                            let errorMessage = "Failed to get Auth Data"
                                            let dialog = DialogErrorMFA()
                                            dialog.modalTransitionStyle = .crossDissolve
                                            dialog.modalPresentationStyle = .overCurrentContext
                                            dialog.errorDesc = errorMessage
                                            dialog.method = method
                                            UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                            APIS.getMFACallback()?("Failed: \(errorMessage)")
                                        }
                                    }
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let errorMessage = "Failed to get Auth Data"
                                let dialog = DialogErrorMFA()
                                dialog.modalTransitionStyle = .crossDissolve
                                dialog.modalPresentationStyle = .overCurrentContext
                                dialog.errorDesc = errorMessage
                                dialog.method = method
                                UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                APIS.getMFACallback()?("Failed: \(errorMessage)")
                            }
                        }
                    } catch {
                    }
                }
            }
        }
        else {
            let controller = MFAViewController()
            controller.METHOD = method
            controller.STEP_NEEDED = flag
            let navigationController = CustomNavigationController(rootViewController: controller)
            navigationController.defaultStyle()
            
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
            }
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
    
    public static func createCommunity() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let startedNewCommunity = UIViewController()
        if let viewComm = startedNewCommunity.view {
            viewComm.backgroundColor = .black.withAlphaComponent(0.1)
            
            let containerView = UIView()
            viewComm.addSubview(containerView)
            containerView.anchor(left: viewComm.leftAnchor, bottom: viewComm.bottomAnchor, right: viewComm.rightAnchor, minHeight: 40)
            containerView.backgroundColor = .white
            containerView.layer.cornerRadius = 15
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            
            let closeButton = UIButton(type: .close)
            containerView.addSubview(closeButton)
            closeButton.anchor(top: containerView.topAnchor, right: containerView.rightAnchor, paddingTop: 10, paddingRight: 10, width: 30, height: 30)
            closeButton.layer.cornerRadius = 15
            closeButton.clipsToBounds = true
            closeButton.backgroundColor = .lightGray.withAlphaComponent(0.1)
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
            closeButton.addAction(UIAction { _ in
                startedNewCommunity.dismiss(animated: true)
            }, for: .touchUpInside)
            
            let imageComm = UIImageView(image: UIImage(named: "pb_community_social", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!)
            containerView.addSubview(imageComm)
            imageComm.anchor(top: closeButton.bottomAnchor, paddingTop: -40, centerX: containerView.centerXAnchor, width: 350, height: 250)
            
            let titleComm = UILabel()
            containerView.addSubview(titleComm)
            titleComm.anchor(top: imageComm.bottomAnchor, left: containerView.leftAnchor, right: containerView.rightAnchor, paddingLeft: 20, paddingRight: 20)
            titleComm.font = .boldSystemFont(ofSize: 30)
            titleComm.textColor = .label
            titleComm.numberOfLines = 0
            titleComm.textAlignment = .center
            titleComm.text = "Create a new community".localized()
            
            let descComm = UILabel()
            containerView.addSubview(descComm)
            descComm.anchor(top: titleComm.bottomAnchor, left: containerView.leftAnchor, right: containerView.rightAnchor, paddingTop: 8, paddingLeft: 20, paddingRight: 20)
            descComm.font = .systemFont(ofSize: 16)
            descComm.textColor = .label
            descComm.numberOfLines = 0
            descComm.textAlignment = .center
            descComm.text = "Bring together a neighborhood, school or more. Create topic-based groups for members, and easily send them admin anouncements.".localized()
            
            let buttonComm = UIButton(type: .custom)
            containerView.addSubview(buttonComm)
            buttonComm.anchor(top: descComm.bottomAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 20, paddingRight: 20, height: 45)
            buttonComm.backgroundColor = .whatsappGreenColor
            buttonComm.layer.cornerRadius = 15
            buttonComm.clipsToBounds = true
            buttonComm.setTitle("Get started".localized(), for: .normal)
            buttonComm.setTitleColor(.white, for: .normal)
            buttonComm.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            buttonComm.addAction(UIAction { _ in
                startedNewCommunity.dismiss(animated: true) {
                    let navigationController = UINavigationController(rootViewController: CommunityNew())
                    UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                }
            }, for: .touchUpInside)
        }
        startedNewCommunity.modalPresentationStyle = .overCurrentContext
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(startedNewCommunity, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(startedNewCommunity, animated: true, completion: nil)
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
        guard let controller = APIS.getControllerSign() else { return }
        if let controller = controller as? SignUpSignIn {
            controller.forceLogin = true
        } else if let controller = controller as? SignInOption {
            controller.forceLogin = true
        }
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
    
    public static func logOut() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        Nexilis.destroyAll()
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getLogout())
    }
    
    public static func openPPOB() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let idx = Nexilis.IDX_PPOB
        let url = getURLFB(idx: idx)
        print("HUHU: \(idx) <><> \(url)")
        Nexilis.buttonClicked(index: idx, id: url)
    }
    
    public static func openSocialCommerce() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let idx = Nexilis.IDX_SOCIAL_COMMERCE
        let url = getURLFB(idx: idx)
        Nexilis.buttonClicked(index: idx, id: url)
    }
    
    private static func getURLFB(idx: Int) -> String {
        let data = Utils.getHistoryPullFB()
        if !data.isEmpty {
            if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                let filteredData = jsonArray.filter({
                    let package_id = ($0["package_id"] as! String)
                    if package_id.contains("_fb") {
                        let listSplit = package_id.split(separator: "_", maxSplits: 2)
                        let numIdx = listSplit[listSplit.firstIndex(where: { $0.contains("fb") }) ?? 0]
                        let indexTap = Int(String(numIdx).substring(from: 2, to: numIdx.count)) ?? 0
                        return indexTap == idx
                    }
                    return package_id.isEmpty
                })
                if filteredData.count != 0 {
                    let data = filteredData[0] as? [String: Any]
                    let package_id = data?["package_id"] as! String
                    let listSplit = package_id.split(separator: "_", maxSplits: 2)
                    return String(listSplit[2])
                }
            }
        }
        return ""
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
    
    public static func sendPushToken(_ token: String, isResend: Bool = false, isCall: Bool = false) {
        DispatchQueue.global().async{
            if !isCall {
                if Utils.getTokenAPN().isEmpty || token != Utils.getTokenAPN() {
                    Utils.setTokenAPN(value: token)
                }
                DispatchQueue.global().async {
                    while API.nGetCLXConnState() == 0 {
                        Thread.sleep(forTimeInterval: 1)
                    }
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.getToken(token: token, tokenCall: Utils.getTokenCall()))
                }
            }
            else {
                if Utils.getTokenCall().isEmpty || token != Utils.getTokenCall() {
                    Utils.setTokenCall(value: token)
                }
//                DispatchQueue.global().async {
//                    while API.nGetCLXConnState() == 0 {
//                        Thread.sleep(forTimeInterval: 1)
//                    }
//                    print("SEND TOKEN CALL")
//                    _ = Nexilis.write(message: CoreMessage_TMessageBank.getToken(token: token, isCall: true))
//                }
            }
        }
    }
    
    public static var uuidCall: UUID?
    public static var fpinCall: String?
    public static func showNotificationNexilis(_ userInfo: [AnyHashable : Any]) {
//        print("MASUK SHOW NOTIFICATION NEXILIS: \(userInfo)")
        if checkAppStateisBackground() {
//            Nexilis.sendStateToServer(s: "MASUK SHOW NOTIFICATION NEXILIS")
//            print("MASUK SHOW NOTIFICATION NEXILIS: \(userInfo)")
            DispatchQueue.main.async {
                if let payload = userInfo["payload"] as? [String: Any] {
                    if let messagePayload = payload["message"] as? [String: Any] {
                        if let data = messagePayload["data"] as? [String: Any] {
                            let code = data["nx_code"] as? String ?? ""
                            if code == "CL01" {
                                if let message = data["bodies"] as? [String: String] {
                                    let idAck = data["message_id"] as? String ?? ""
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
                                            ackAPN(id: idAck)
                                            return
                                        }
                                    } catch {
                                        print("error saving message: \(error)")
                                    }
                                    APIS.addNotificationNexilis(messageToSave)
                                    ackAPN(id: idAck)
                                    Nexilis.saveMessage(message: messageToSave, withStatus: false, fromAPNS: true)
                                }
                            } else if code == "CL03" {
                                let callFromName = data["call-from-name"] as? String ?? ""
                                let callFrom = data["call-from"] as? String ?? ""
                                let callType = data["call-type"] as? String ?? ""
//                                uuidCall = UUID()
                                fpinCall = callFrom
                                Nexilis.callAPNActivated = true
                                let center = UNUserNotificationCenter.current()
                                let content = UNMutableNotificationContent()
                                content.title = callFromName
                                if callType == "1" {
                                    content.body = "Incoming Audio Call".localized()
                                } else {
                                    content.body = "Incoming Video Call".localized()
                                }
                                content.userInfo = ["id" : callFrom, "type" : code, "callType": callType]
                                content.sound = nil
                                let request = UNNotificationRequest(identifier: callFrom, content: content, trigger: nil)
                                center.add(request) { error in
                                    if let error = error {
                                        print("Error scheduling notification: \(error.localizedDescription)")
                                    }
                                }
                                let session = AVAudioSession.sharedInstance()
                                do {
                                    try session.setCategory(.playback, options: [.duckOthers])
                                    try session.setActive(true)
                                } catch {
                                    print("Audio session error: \(error)")
                                }
                                Nexilis.playRingtoneCall()
                            } else if code == "CL02" {
                                print("data \(data)")
                                let callFromName = data["call-cancel-name"] as? String ?? ""
                                let callFrom = data["call-cancel"] as? String ?? ""
                                let callType = data["call-type"] as? String ?? ""
//                                if let uuidCall = uuidCall {
                                Nexilis.stopRingtoneCall()
                                Nexilis.callAPNActivated = false
                                let center = UNUserNotificationCenter.current()
                                center.removeDeliveredNotifications(withIdentifiers: [callFrom])
                                var textCall = ""
                                if callType == "1" {
                                    textCall = "audio"
                                } else {
                                    textCall = "video"
                                }
                                let content = UNMutableNotificationContent()
                                content.title = callFromName
                                content.body = "☎️ Missed \(textCall) call".localized()
                                content.userInfo = ["id" : callFrom, "type" : code, "callType": callType]
                                content.sound = nil
                                let request = UNNotificationRequest(identifier: callFrom, content: content, trigger: nil)
                                center.add(request) { error in
                                    if let error = error {
                                        print("Error scheduling notification: \(error.localizedDescription)")
                                    }
                                }
                                Nexilis.saveMessageCall(idCall: (User.getMyPin() ?? "") + CoreMessage_TMessageUtil.getTID(), textMessage: "Missed \(textCall) call".localized() + " at 0", fPin: callFrom, lPin: (User.getMyPin() ?? ""), timeCall: String(Date().currentTimeMillis()), attachment_type: MessageScope.MISSED_CALL)
                            }
                        }
                    }
                } else if let message_id = userInfo["message_id"] as? String {
                    getMessageById(id: message_id)
                }
            }
        }
    }
    
    public static func showNotificationCallKitNexilis(payload: [AnyHashable : Any], completion: @escaping () -> ()) {
        if let messagePayload = payload["payload"] as? [String: Any] {
            if let message = messagePayload["message"] as? [String: Any] {
                if let data = message["data"] as? [String: Any] {
                    let nxCode = data["nx_code"] as? String ?? ""
                    let callFromName = data["call-from-name"] as? String ?? ""
                    let callCancelName = data["call-cancel-name"] as? String ?? ""
                    let callFrom = data["call-from"] as? String ?? ""
                    let callCancel = data["call-cancel"] as? String ?? ""
                    let callType = data["call-type"] as? String ?? ""
                    if nxCode == "CL03" {
                        Nexilis.callAPNActivated = true
                        APIS.uuidCall = UUID()
                        CallManager.shared.reportIncomingCall(uuid: APIS.uuidCall ?? UUID(), callerName: callFromName, callerId: callFrom, isVideo: callType != "1")
                    } else {
                        if APIS.uuidCall != nil {
                            CallManager.shared.endCall(uuid: APIS.uuidCall!) {
                                Nexilis.callAPNActivated = false
                                APIS.uuidCall = nil
                                let center = UNUserNotificationCenter.current()
                                var textCall = ""
                                if callType == "1" {
                                    textCall = "audio"
                                } else {
                                    textCall = "video"
                                }
                                let content = UNMutableNotificationContent()
                                content.title = callCancelName
                                content.body = "☎️ Missed \(textCall) call".localized()
                                content.userInfo = ["id" : callFrom, "type" : nxCode, "callType": callType]
                                content.sound = nil
                                let request = UNNotificationRequest(identifier: callCancel, content: content, trigger: nil)
                                center.add(request) { error in
                                    if let error = error {
                                        print("Error scheduling notification: \(error.localizedDescription)")
                                    }
                                }
                                Nexilis.saveMessageCall(idCall: (User.getMyPin() ?? "") + CoreMessage_TMessageUtil.getTID(), textMessage: "Missed \(textCall) call".localized() + " at 0", fPin: callCancel, lPin: (User.getMyPin() ?? ""), timeCall: String(Date().currentTimeMillis()), attachment_type: MessageScope.MISSED_CALL)
                            }
                        } else if UIApplication.shared.visibleViewController is QmeraAudioViewController || UIApplication.shared.visibleViewController is QmeraVideoViewController {
                            var dataMessage: [AnyHashable : Any] = [:]
                            dataMessage["call_cancel"] = true
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.callFCM), object: nil, userInfo: dataMessage)
                        }
                    }
                }
            }
        }
    }
    
    static func ackAPN(id: String) {
        DispatchQueue.global().async {
//            Nexilis.sendStateToServer(s: "send ack from apn")
            let parameter: [String : Any] = [
                "pin": User.getMyPin() ?? "",
                "message_id": id
            ]
            Utils.postDataWithCookiesAndUserAgent(from: URL(string: Utils.getDomainOpr() + "ack_message")!, parameter: parameter, isFormData: true) { data, response, error in
            }
        }
    }
    
    private static func getMessageById(id: String) {
        DispatchQueue.global().async {
            let parameter: [String : Any] = [
                "pin": User.getMyPin() ?? "",
                "message_id": id
            ]
//            HttpBackgroundManager().startUpload(parameter: parameter, to: URL(string: Utils.getDomainOpr() + "pull_notification")!, identifier: "pull_notification")
            Utils.postDataWithCookiesAndUserAgent(from: URL(string: Utils.getDomainOpr() + "pull_notification")!, parameter: parameter, isFormData: true) { data, response, error in
                if let data = data {
                    do {
                        if let dataString = String(data: data, encoding: .utf8) {
                            if let jsonObj = try JSONSerialization.jsonObject(with: dataString.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                                let dataObj = jsonObj["data"] as? String ?? ""
                                let message = TMessage(data: dataObj)
                                if Utils.getSecureFolderOffline() == "0" && IncomingThread.dispatch == nil {
                                    if API.nGetCLXConnState() == 0 {
                                        do {
                                            let id = Utils.getConnectionID()
                                            try API.initConnection(sAPIK: Nexilis.sAPIKey, cbiI: Callback(), sTCPAddr: Nexilis.ADDRESS, nTCPPort: Nexilis.PORT, sUserID: id, sStartWH: "09:00")
                                        } catch {}
                                    }
                                    if FileEncryption.shared.aesKey == nil {
                                        IncomingThread.dispatch = DispatchGroup()
                                        IncomingThread.dispatch?.enter()
                                        Nexilis.getFeatureAccess()
                                        IncomingThread.dispatch?.wait()
                                        IncomingThread.dispatch = nil
                                    }
                                }
                                print("save from APIS")
                                Nexilis.saveMessage(message: message, withStatus: false, fromAPNS: true)
                                ackAPN(id: id)
                                DispatchQueue.main.async {
                                    UIApplication.shared.applicationIconBadgeNumber = Int(APIS.getTotalCounter())
                                }
                            }
                        }
                    } catch {
                        
                    }
                }
            }
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = Int(APIS.getTotalCounter())
            }
//            Nexilis.sendStateToServer(s: "send ack from apn")
//            do {
//                if API.nGetCLXConnState() == 0 {
//                    let id = Utils.getConnectionID()
//                    try API.initConnection(sAPIK: Nexilis.sAPIKey, cbiI: Callback(), sTCPAddr: Nexilis.ADDRESS, nTCPPort: Nexilis.PORT, sUserID: id, sStartWH: "09:00")
//                    while API.nGetCLXConnState() == 0 {
//                        print("nGetCLXConnState: 0")
//                        Thread.sleep(forTimeInterval: 1)
//                    }
//                    print("nGetCLXConnState: lewat")
//                    getMessage()
//                } else {
//                    getMessage()
//                }
//                func getMessage() {
//                    if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.getMessageById(messageId: id), timeout: 30 * 1000) {
//                        print("result: \(result.toLogString())")
//                        if result.isOk() {
//                            let respData = result.getBody(key: CoreMessage_TMessageKey.DATA)
//                            if let data = Data(base64Encoded: respData, options: .ignoreUnknownCharacters),
//                               let decodedString = String(data: data, encoding: .utf8) {
//                                let message = TMessage(data: decodedString)
//                                print("message: \(message.toLogString())")
//                            }
//                        } else {
//
//                        }
//                    } else {
//                    }
//                }
//            } catch {
//
//            }
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
        let request = UNNotificationRequest(identifier: messageId, content: content, trigger: nil)
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
                        if var audioData = try FileEncryption.shared.readSecure(filename: nameSound) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: audioData)
                            if dataDecrypt != nil {
                                audioData = dataDecrypt!
                            }
                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                            let tempPath = cachesDirectory.appendingPathComponent(nameSound)
                            try audioData.write(to: tempPath)
                            sourceURL = tempPath
                        }
                    } catch {
                        
                    }
                } else {
                    sourceURL = Bundle.resourceBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
                    if sourceURL == nil {
                        sourceURL = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
                    }
                }
            }
        } else {
            sourceURL = Bundle.resourceBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
            if sourceURL == nil {
                sourceURL = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
            }
        }
        if sourceURL == nil {
            return
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
                let callType = userInfo["callType"] ?? ""
                if let navigationC = UIApplication.shared.visibleViewController as? UINavigationController {
                    if navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorPersonal || navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorGroup {
                        navigationC.popViewController(animated: true)
                    }
                }
                showEditorOrCallFromAPN(id, type, callType)
            } else {
                let userInfo = response.notification.request.content.userInfo
                DispatchQueue.main.async {
                    if let message_id = userInfo[CoreMessage_TMessageKey.MESSAGE_ID] as? String {
                        var f_pin = ""
                        var l_pin = ""
                        var message_scope_id = ""
                        var pin = ""
                        var chat_id = ""
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, l_pin, message_scope_id, chat_id from MESSAGE where message_id = '\(message_id)'"), cursor.next() {
                                f_pin = cursor.string(forColumnIndex: 0) ?? ""
                                l_pin = cursor.string(forColumnIndex: 1) ?? ""
                                message_scope_id = cursor.string(forColumnIndex: 2) ?? ""
                                chat_id = cursor.string(forColumnIndex: 3) ?? ""
                                pin = f_pin == User.getMyPin() ? l_pin : f_pin
                                if message_scope_id == "4" {
                                    pin = chat_id.isEmpty ? l_pin : chat_id
                                }
                                cursor.close()
                            }
                        })
                        if let navigationC = UIApplication.shared.visibleViewController as? UINavigationController {
                            if navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorPersonal || navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorGroup {
                                navigationC.popViewController(animated: false)
                            }
                        }
                        showEditorOrCallFromAPN(pin, message_scope_id == "4" ? "1" : !message_scope_id.isEmpty ? "0" : "", "CL01")
                    }
                }
            }
        }
//        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    private static func showEditorOrCallFromAPN(_ id: String, _ type: String, _ callType: String) {
        if type.isEmpty {
            return
        }
        if type == "0" {
            if User.getDataCanNil(pin: id) == nil && id != "-999" && id != "-997" {
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
            Nexilis.stopRingtoneCall()
            if !Nexilis.callAPNActivated {
                return
            }
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
//        if !API.bAVisOngoing() {
//            API.deinitConnection()
//        }
        notifTimer.invalidate()
        stopNotif = true
        if Utils.getSecureFolderOffline() == "0" {
            Database.shared.database = nil
            FileEncryption.shared.aesKey = nil
            FileEncryption.shared.aesIV = nil
        }
        FloatingButton.datePull = nil
    }
    
    public static var notifTimer = Timer()
    public static var stopNotif = false
    public static var afterEnterBackground = false
    public static func enterForeground() {
        APIS.checkNotificationPermission(completion: { isAllowed in
            if !isAllowed {
                showEnableNotificationsAlert()
            } else {
                UIApplication.shared.registerForRemoteNotifications()
            }
        })
        DispatchQueue.main.async {
            stopNotif = true
            self.notifTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
                stopNotif = false
            }
            do {
                if !Nexilis.afterConnect && API.nGetCLXConnState() == 0 {
                    let id = Utils.getConnectionID()
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
        if Utils.getSecureFolderOffline() == "0" && afterEnterBackground && Database.shared.database == nil && Utils.getSetProfile() {
            Database.recreateInstance()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "disconnected_nexilis"), object: nil, userInfo: nil)
            if let navigationC = UIApplication.shared.visibleViewController as? UINavigationController {
                if navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorPersonal || navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorGroup {
                    navigationC.popViewController(animated: true)
                }
            }
//            Nexilis.getFeatureAccessWithKey(key: ["secure_folder_encrypt_key", "secure_folder_encrypt_iv", "secure_folder_offline"])
            Nexilis.getFeatureAccess()
        }
        if (FloatingButton.datePull == nil || !afterEnterBackground) && Utils.getSetProfile() {
            DispatchQueue.global().async {
                while API.nGetCLXConnState() == 0 || User.getMyPin() == nil {
                    Thread.sleep(forTimeInterval: 0.5)
                }
                if let vers = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.checkVersion()) {
                    let dataVersion = vers.getBody(key: CoreMessage_TMessageKey.DATA)
                    let type = vers.getBody(key: CoreMessage_TMessageKey.TYPE)
                    if dataVersion != "1" {
                        DispatchQueue.main.async {
                            showExpiredVersion(mandatory: type == "1")
                        }
                    }
                }
            }
        }
        afterEnterBackground = true
    }
    
    public static func willEnterForeground() {
//        if APIS.uuidCall != nil {
//            CallManager.shared.endCall(uuid: APIS.uuidCall!) {
//                APIS.uuidCall = nil
//            }
//        }
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
    
    public static func nexilisShowAlertWithHTMLMessage(on viewController: UIViewController, title: String, message: String = "<b>Bold</b> and <i>italic</i> text in an alert") {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        
        let titleFont = UIFont.boldSystemFont(ofSize: 16)
        let titleAttributes = [NSAttributedString.Key.font: titleFont]
        alert.setValue(NSAttributedString(string: title, attributes: titleAttributes), forKey: "attributedTitle")
        
        var message = message
        message = message.replacingOccurrences(of: "<b>", with: "*")
        message = message.replacingOccurrences(of: "</b>", with: "*")
        message = message.replacingOccurrences(of: "<i>", with: "_")
        message = message.replacingOccurrences(of: "</i>", with: "_")
        
        alert.setValue(message.richText(fontSize: 14), forKey: "attributedMessage")
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    static func showWarningFile(type: Int) {
        alertControllerExpired = LibAlertController(
            title: type == -1 ? "⚠️ Suspicious File Detected".localized() : "⚠️ Unrecognized File Type".localized(),
            message: type == -1 ? "The file appears to have a mismatched name and extension, which may indicate a malicious file. Please verify the file’s source and format before uploading it.".localized() : "The selected item is not listed in the system dashboard.".localized(),
            preferredStyle: .alert
        )
        
        alertControllerExpired.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: nil))
        
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(alertControllerExpired, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(alertControllerExpired, animated: true, completion: nil)
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
        
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { _ in
            isAlertPresented = false
        }))
        
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
    
    static func showRestartApp() {
        alertControllerExpired = LibAlertController(
            title: "Restart Required".localized(),
            message: "Oops! Something went wrong. Please restart the app to continue.".localized(),
            preferredStyle: .alert
        )
        
        alertControllerExpired.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: { _ in
            exit(0)
        }))
        
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(alertControllerExpired, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(alertControllerExpired, animated: true, completion: nil)
        }
    }
    
    private static var alertControllerExpired: LibAlertController!
    public static func showExpiredVersion(mandatory: Bool) {
        func showAl() {
            alertControllerExpired = LibAlertController(
                title: "Update Available".localized(),
                message: "A new version is now available. Please update to the latest version to enjoy new features and important improvements.".localized(),
                preferredStyle: .alert
            )
            if !mandatory {
                alertControllerExpired.addAction(UIAlertAction(title: "Later".localized(), style: .cancel, handler: nil))
            }
            
            alertControllerExpired.addAction(UIAlertAction(title: "Update Now".localized(), style: .default, handler: { _ in
                if APIS.appNm == "OneApp" {
                    let appStoreURL = URL(string: "https://apps.apple.com/app/id6741251571")!
                    UIApplication.shared.open(appStoreURL)
                } else {
                    let appStoreURL = URL(string: "https://apps.apple.com/app/")!
                    UIApplication.shared.open(appStoreURL)
                }
            }))
            
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(alertControllerExpired, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(alertControllerExpired, animated: true, completion: nil)
            }
        }
        if alertControllerExpired != nil {
            alertControllerExpired.dismiss(animated: true) {
                showAl()
            }
        } else {
            showAl()
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
    
    private static var isCheckingDataForShare = false
    public static func checkDataForShareExtension() {
        DispatchQueue.global().async {
            if let userDefaults = UserDefaults(suiteName: nameGroupShared) {
                if let value = userDefaults.string(forKey: "sharedItem") {
                    if !value.isEmpty {
                        if isCheckingDataForShare {
                            return
                        }
                        isCheckingDataForShare = true
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
                                        attachmentFlag = "1"
                                        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                            let sharedImageURL = appGroupURL.appendingPathComponent(imageId)
                                            let sharedThumbURL = appGroupURL.appendingPathComponent(thumb)
                                            if Nexilis.checkingAccess(key: "content_inspection") {
                                                DispatchQueue.main.async {
                                                    Nexilis.showLoader(text: "Scanning File...".localized())
                                                }
                                                let result = sharedImageURL.validateFile()
                                                DispatchQueue.main.async {
                                                    Nexilis.hideLoader {
                                                        if result == 1 {
                                                            copyData()
                                                            sendIt()
                                                        } else {
                                                            APIS.showWarningFile(type: result)
                                                            resetPrefs()
                                                        }
                                                    }
                                                }
                                            } else {
                                                copyData()
                                                sendIt()
                                            }
                                            func copyData() {
                                                do {
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
                                                } catch {
                                                    
                                                }
                                            }
                                        }
                                    } else if typeShare == typeVideo {
                                        attachmentFlag = "2"
                                        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                            let sharedVideoURL = appGroupURL.appendingPathComponent(videoId)
                                            let sharedThumbURL = appGroupURL.appendingPathComponent(thumb)
                                            if Nexilis.checkingAccess(key: "content_inspection") {
                                                DispatchQueue.main.async {
                                                    Nexilis.showLoader(text: "Scanning File...".localized())
                                                }
                                                let result = sharedVideoURL.validateFile()
                                                DispatchQueue.main.async {
                                                    Nexilis.hideLoader {
                                                        if result == 1 {
                                                            copyData()
                                                            sendIt()
                                                        } else {
                                                            APIS.showWarningFile(type: result)
                                                            resetPrefs()
                                                        }
                                                    }
                                                }
                                            } else {
                                                copyData()
                                                sendIt()
                                            }
                                            func copyData() {
                                                do {
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
                                                } catch {
                                                    
                                                }
                                            }
                                        }
                                    } else if typeShare == typeFile {
                                        attachmentFlag = "6"
                                        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                            renamedFileId = "Nexilis_\(Date().currentTimeMillis())_" + fileId
                                            let sharedFileURL = appGroupURL.appendingPathComponent(fileId)
                                            if Nexilis.checkingAccess(key: "content_inspection") {
                                                DispatchQueue.main.async {
                                                    Nexilis.showLoader(text: "Scanning File...".localized())
                                                }
                                                let result = sharedFileURL.validateFile()
                                                DispatchQueue.main.async {
                                                    Nexilis.hideLoader {
                                                        if result == 1 {
                                                            copyData()
                                                            sendIt()
                                                        } else {
                                                            APIS.showWarningFile(type: result)
                                                            resetPrefs()
                                                        }
                                                    }
                                                }
                                            } else {
                                                copyData()
                                                sendIt()
                                            }
                                            func copyData() {
                                                do {
                                                    let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                                    if FileManager.default.fileExists(atPath: sharedFileURL.path) {
                                                        let file = documentDir.appendingPathComponent(renamedFileId)
                                                        if !FileManager().fileExists(atPath: file.path) {
                                                            try? FileManager.default.copyItem(at: sharedFileURL, to: file)
                                                        }
                                                    }
                                                    data = "\(fileId)|\(data)"
                                                } catch {
                                                    
                                                }
                                            }
                                        }
                                    } else if typeShare == typeAudio {
                                        attachmentFlag = "5"
                                        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                            renamedAudioId = "Nexilis_\(Date().currentTimeMillis())_" + audioId
                                            let sharedFileURL = appGroupURL.appendingPathComponent(audioId)
                                            if Nexilis.checkingAccess(key: "content_inspection") {
                                                DispatchQueue.main.async {
                                                    Nexilis.showLoader(text: "Scanning File...".localized())
                                                }
                                                let result = sharedFileURL.validateFile()
                                                DispatchQueue.main.async {
                                                    Nexilis.hideLoader {
                                                        if result == 1 {
                                                            copyData()
                                                            sendIt()
                                                        } else {
                                                            APIS.showWarningFile(type: result)
                                                            resetPrefs()
                                                        }
                                                    }
                                                }
                                            } else {
                                                copyData()
                                                sendIt()
                                            }
                                            func copyData() {
                                                do {
                                                    let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                                    if FileManager.default.fileExists(atPath: sharedFileURL.path) {
                                                        let file = documentDir.appendingPathComponent(renamedAudioId)
                                                        if !FileManager().fileExists(atPath: file.path) {
                                                            try? FileManager.default.copyItem(at: sharedFileURL, to: file)
                                                        }
                                                    }
                                                    data = "\(audioId)|\(data)"
                                                } catch {
                                                    
                                                }
                                            }
                                        }
                                    }
                                    func sendIt() {
                                        message = CoreMessage_TMessageBank.sendMessage(l_pin: groupId.isEmpty ? idContact : groupId, message_scope_id: scopeId, status: scopeId == "3" ? "1" : "2", message_text: data, credential: "0", attachment_flag: attachmentFlag, ex_blog_id: "", message_large_text: "", ex_format: "", image_id: imageId, audio_id: renamedAudioId, video_id: videoId, file_id: renamedFileId, thumb_id: thumb, reff_id: "", read_receipts: "4", chat_id: chatId, is_call_center: "0", call_center_id: "", opposite_pin: scopeId == "3" ? (User.getMyPin() ?? "") : idContact, gif_id: "", isForwarded: "0", isSecret: "0", specFile: "")
                                        Nexilis.addQueueMessage(message: message)
                                        resetPrefs()
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                                    }
                                    func resetPrefs() {
                                        userDefaults.set("", forKey: "sharedItem")
                                        userDefaults.synchronize()
                                        isCheckingDataForShare = false
                                    }
                                }
                            } catch {
                                print("Error parsing JSON: \(error)")
                            }
                        }
                    }
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
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
                                                   if FileEncryption.shared.isSecureExists(filename: imageString) {
                                                       if var data = try FileEncryption.shared.readSecure(filename: imageString) {
                                                           let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                                           if dataDecrypt != nil {
                                                               data = dataDecrypt!
                                                           }
                                                           if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                                               let sharedFileURL = appGroupURL.appendingPathComponent(imageString)
                                                               if !FileManager.default.fileExists(atPath: sharedFileURL.path) {
                                                                   try? data.write(to: sharedFileURL)
                                                               }
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
                                                    if FileEncryption.shared.isSecureExists(filename: imageString) {
                                                        if var data = try FileEncryption.shared.readSecure(filename: imageString) {
                                                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                                            if dataDecrypt != nil {
                                                                data = dataDecrypt!
                                                            }
                                                            if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                                                let sharedFileURL = appGroupURL.appendingPathComponent(imageString)
                                                                if !FileManager.default.fileExists(atPath: sharedFileURL.path) {
                                                                    try? data.write(to: sharedFileURL)
                                                                }
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
                                                            if FileEncryption.shared.isSecureExists(filename: imageString) {
                                                                if var data = try FileEncryption.shared.readSecure(filename: imageString) {
                                                                    let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                                                    if dataDecrypt != nil {
                                                                        data = dataDecrypt!
                                                                    }
                                                                    if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared) {
                                                                        let sharedFileURL = appGroupURL.appendingPathComponent(imageString)
                                                                        if !FileManager.default.fileExists(atPath: sharedFileURL.path) {
                                                                            try? data.write(to: sharedFileURL)
                                                                        }
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
    
    public static func openImageNexilis(imageView: UIImageView, data: Data? = nil, isGIF: Bool = false) {
        let image = UIImage(data: data ?? Data())
        let imageViewer = MediaViewerViewController()
        if !isGIF {
            imageViewer.media = .image(image ?? UIImage())
        } else {
            imageViewer.media = .gif(UIImage.gifImageWithData(data ?? Data()) ?? UIImage())
        }
        
        let navigationController = UINavigationController(rootViewController: imageViewer)
        navigationController.defaultStyle()
        navigationController.view.backgroundColor = .clear
        navigationController.modalPresentationCapturesStatusBarAppearance = true
        navigationController.modalPresentationStyle = .overFullScreen
        
        let backAction = UIAction { _ in
            navigationController.dismiss(animated: true)
        }
        let backButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "chevron.backward"), primaryAction: backAction, menu: nil)
        imageViewer.navigationItem.leftBarButtonItem = backButton
        
        let name = ""
        imageViewer.title = name
        
        let transitionDelegate = ZoomTransitioningDelegate()
        transitionDelegate.originImageView = imageView
        navigationController.transitioningDelegate = transitionDelegate
        self.transitioningDelegateRef = transitionDelegate
        
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true) {
                imageViewer.animateBackgroundIn()
            }
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true) {
                imageViewer.animateBackgroundIn()
            }
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
    
    public static func checkSignMethod() -> (Int, Int) {
        var countMethod = 0
        var typeMethod = 0
        if Nexilis.checkingAccess(key: "sign_in_up_msisdn") {
            countMethod+=1
            typeMethod = 0
        }
        if Nexilis.checkingAccess(key: "sign_in_up_email") {
            countMethod+=1
            typeMethod = 1
        }
        if Nexilis.checkingAccess(key: "sign_in_up_username") {
            countMethod+=1
            typeMethod = 2
        }
        return (countMethod,typeMethod)
    }
    
    public static func getControllerSign(forceSignIn: Bool = false) -> UIViewController? {
        let data = APIS.checkSignMethod()
        let count = data.0
        let type = data.1
        if count > 0 {
            var controller: UIViewController!
            if count == 1 {
                if forceSignIn {
                    let vc = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeDevice") as! ChangeDeviceViewController
                    if type == 0 {
                        vc.isMSISDN = true
                        controller = vc
                    } else if type == 1 {
                        vc.isEmail = true
                    }
                    controller = vc
                } else {
                    let vc = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "signupsignin") as! SignUpSignIn
                    if type == 0 {
                        vc.isMSISDN = true
                        controller = vc
                    } else if type == 1 {
                        vc.isEmail = true
                    }
                    controller = vc
                }
            } else {
                let vc = SignInOption()
                vc.forceSignIn = forceSignIn
                controller = vc
            }
            return controller
        }
        return nil
    }
    
    public static func monitoredActivity() {
        UIViewController.swizzleViewDidAppearImplementation
        UINavigationController.swizzlePushViewControllerImplementation
        UINavigationController.swizzlePopViewControllerImplementation
        _ = DataCaptured()
        UIApplication.swizzleSendAction
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
        self.navigationBar.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        self.navigationBar.isTranslucent = false
        self.navigationBar.overrideUserInterfaceStyle = .dark
        self.navigationBar.barStyle = .black
        let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        self.navigationBar.titleTextAttributes = textAttributes
    }
}
