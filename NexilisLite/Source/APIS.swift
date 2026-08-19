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
#if SWIFT_PACKAGE
import Toast
#else
import Toast_Swift
#endif
import nuSDKService
import AVFoundation
import AVKit
import Intents

/// The app's chat list screen, as far as this framework is concerned.
///
/// The framework cannot see the app target's view controllers, but it does need to tell the
/// chat list to refresh itself before pushing an Editor on top of it - a list drawn before
/// the pushed message was stored shows a stale row (or no row at all) behind the chat, and
/// the unread counters it displays are the ones from before the message arrived.
public protocol ChatListTab: UIViewController {
    /// Reloads the list from the database and calls back on the main thread once the new
    /// data is on screen.
    func reloadChatList(completion: @escaping () -> Void)
}

public class APIS: NSObject {
    private static var isAlertPresented = false
    private static var transitioningDelegateRef: ZoomTransitioningDelegate?
    public static func connect(appName: String, apiKey: String, userName: String = "", delegate: ConnectDelegate, showButton: Bool = true, fromMAB: Bool = false) {
        APIS.appNm = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        Nexilis.connect(apiKey: apiKey, userId: userName, delegate: delegate, showButton: showButton, fromMAB: fromMAB)
//        APIS.monitoredActivity()
    }
    
    // MARK: - App icon badge
    //
    // Fix: the badge used to be nudged along with `applicationIconBadgeNumber += 1` from the
    // push handlers. Three things were wrong with that. The increment sat inside a
    // DispatchQueue.main block, and a push handler runs on an app that iOS is about to suspend
    // again - the block often never got its turn, which is the "notif jelas masuk tapi badge
    // tidak nambah" case. A redelivered push for a message already in hand counted twice. And
    // nothing ever brought the number back down when those messages were read. The number of
    // unread messages is already in the database, so that is what the badge is set from now.

    private static var badgeRefreshScheduled = false
    private static let lastBadgeKey = "last_application_badge_nexilis"

    /// Reads the unread total and puts it on the app icon. Does the read on the calling thread,
    /// so a push handler can be sure it has happened before it hands control back to iOS.
    ///
    /// - Parameter fallbackIncrement: for the callers that know a message just landed. The
    ///   database is closed while the app is in the background (see enterBackground), and if it
    ///   cannot be reopened - no key material yet, for instance - there is no count to read.
    ///   Leaving the badge alone then would be the "badge tidak nambah" case all over again, so
    ///   those callers put it up by one instead of leaving it where it was.
    public static func refreshApplicationBadge(fallbackIncrement: Bool = false) {
        // The database is not open by default in the background, and a query against a closed
        // one reads nothing at all.
        Database.shared.ensureOpenForBackgroundWrite()
        if let total = readUnreadTotal() {
            setApplicationBadge(Int(total))
            return
        }
        guard fallbackIncrement else {
            // Fix: a failed read used to be treated as "zero unread", which actively wiped the
            // badge instead of raising it.
            return
        }
        setApplicationBadge(lastKnownBadge + 1)
    }

    /// The same, but at most once every half second - for the paths that run once per arriving
    /// message, where a backlog would otherwise mean one five-way SUM per message.
    public static func refreshApplicationBadgeSoon() {
        guard !badgeRefreshScheduled else {
            return
        }
        badgeRefreshScheduled = true
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
            badgeRefreshScheduled = false
            refreshApplicationBadge()
        }
    }

    /// What the badge was last set to. Kept here rather than read back from UIApplication,
    /// which only answers on the main thread and only while the app is running.
    private static var lastKnownBadge: Int {
        return UserDefaults.standard.integer(forKey: lastBadgeKey)
    }

    /// What the badge should read now that one more message has arrived.
    ///
    /// Fix: reading the database alone is not enough here, because the CL01 push path puts the
    /// notification up *before* it saves the message - so the count still says what it said a
    /// moment ago, the badge gets set to the number it already had, and the arrival is invisible.
    /// One more than the last number shown is the floor; the database's own count wins when it
    /// is higher (it already counts this message on the socket path, and it catches up on
    /// everything read or received elsewhere).
    private static func badgeTargetForNewMessage() -> Int {
        Database.shared.ensureOpenForBackgroundWrite()
        let counted = Int(readUnreadTotal() ?? 0)
        return max(counted, lastKnownBadge + 1)
    }

    private static func setApplicationBadge(_ value: Int) {
        UserDefaults.standard.set(value, forKey: lastBadgeKey)
        if #available(iOS 16.0, *) {
            // Settable from any thread and without the app being active, unlike the old
            // property - which is exactly what a background push handler needs.
            UNUserNotificationCenter.current().setBadgeCount(value)
            return
        }
        if Thread.isMainThread {
            UIApplication.shared.applicationIconBadgeNumber = value
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = value
            }
        }
    }

    public static func getTotalCounter() -> Int32 {
        guard let total = readUnreadTotal() else {
            return 0
        }
        setApplicationBadge(Int(total))
        return total
    }

    /// The number of unread messages, or nil when the database could not be read at all - which
    /// is not the same thing as there being none.
    private static func readUnreadTotal() -> Int32? {
        var counter: Int32?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                let query = """
                    SELECT SUM(counter) as total_counter
                    FROM (
                        SELECT ms.counter 
                        FROM MESSAGE_SUMMARY ms, MESSAGE m, BUDDY b
                        WHERE ms.l_pin = b.f_pin 
                          AND ms.message_id = m.message_id 
                          AND m.is_call_center = 0
                          AND ms.archived = 0

                        UNION ALL

                        SELECT ms.counter 
                        FROM MESSAGE_SUMMARY ms, MESSAGE m
                        WHERE ms.l_pin = '-999' 
                          AND ms.message_id = m.message_id
                          AND ms.archived = 0

                        UNION ALL

                        SELECT ms.counter 
                        FROM MESSAGE_SUMMARY ms, MESSAGE m
                        WHERE ms.l_pin = '-997' 
                          AND ms.message_id = m.message_id
                          AND ms.archived = 0

                        UNION ALL

                        SELECT ms.counter 
                        FROM MESSAGE_SUMMARY ms, MESSAGE m, GROUPZ b
                        WHERE ms.l_pin = b.group_id 
                          AND ms.message_id = m.message_id 
                          AND m.is_call_center = 0
                          AND ms.archived = 0

                        UNION ALL

                        SELECT ms.counter 
                        FROM MESSAGE_SUMMARY ms, MESSAGE m, DISCUSSION_FORUM b, GROUPZ c
                        WHERE b.group_id = c.group_id 
                          AND ms.l_pin = b.chat_id 
                          AND ms.message_id = m.message_id 
                          AND m.is_call_center = 0
                          AND ms.archived = 0
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
        return counter
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
    
    // MARK: - Calls in progress

    /// The call screens that are alive right now - on screen, or shrunk into a corner.
    ///
    /// Weak on purpose: a screen that has gone leaves nothing behind even if some path forgot to
    /// say so, and a flag that gets stuck at "a call is running" would lock the reader out of
    /// calling anyone for the rest of the session. While a call is minimised the managers hold
    /// the screen, so these stay valid exactly as long as the call does.
    private static weak var activeAudioCall: QmeraAudioViewController?
    private static weak var activeVideoCall: QmeraVideoViewController?

    static func callSessionBegan(audio: QmeraAudioViewController?) {
        activeAudioCall = audio
    }

    static func callSessionBegan(video: QmeraVideoViewController?) {
        activeVideoCall = video
    }

    static func callSessionEnded(audio: QmeraAudioViewController) {
        if activeAudioCall === audio {
            activeAudioCall = nil
        }
    }

    static func callSessionEnded(video: QmeraVideoViewController) {
        if activeVideoCall === video {
            activeVideoCall = nil
        }
    }

    /// Whether a call is running right now, on screen or minimised.
    public static var isCallInProgress: Bool {
        return activeAudioCall != nil || activeVideoCall != nil
    }

    /// Says so, and answers whether the thing that was asked for has to be dropped.
    ///
    /// Everything that takes the microphone, the camera or the call engine goes through here:
    /// starting another call, live streaming, a conference, the contact centre. They cannot run
    /// alongside a call - the call is what would break - so they are turned away with a word
    /// rather than left to fail in the middle.
    @discardableResult
    static func blockedByCallInProgress() -> Bool {
        guard isCallInProgress else {
            return false
        }
        DispatchQueue.main.async {
            let message = activeVideoCall != nil
                ? "A video call is in progress".localized()
                : "An audio call is in progress".localized()
            UIApplication.shared.visibleViewController?.view.makeToast(message, duration: 3)
        }
        return true
    }

    public static func openContactCenter(media: Int? = nil, category: Int? = nil) {
        if blockedByCallInProgress() {
            return
        }
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
        if blockedByCallInProgress() {
            return
        }
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
    
    public static func openSmartChatbot(text: String = "") {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let smartChatVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "chatGptVC") as! ChatGPTBotView
        smartChatVC.hidesBottomBarWhenPushed = true
        smartChatVC.autoText = text
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
        if blockedByCallInProgress() {
            return
        }
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
        if blockedByCallInProgress() {
            return
        }
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
        if blockedByCallInProgress() {
            return
        }
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
        if blockedByCallInProgress() {
            return
        }
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
        if blockedByCallInProgress() {
            return
        }
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
    
    public static func setMainColor(hexString: String) {
        UIColor.hexMainColorString = hexString
    }
    
    /*
     0
     Success
     1
     Invalid PIN/Password
     2
     Auth Failure
     3
     Device Key Signature Mismatch
     4
     Policy Level Not Met
     5
     PPKey Generated Failed
     6
     Challenge-Response Failed
     7
     TOTOP Mismatch
     9
     Server Error Code
     10
     Invalid Face ID or Face ID mismatch
     11
     Invalid Fingerprint
     12
     Invalid SIM Card does not match the one registered in our system
     13
     Unable to access servers. Check your internet connection and try again later
     99
     Back / Cancel
     */
    private static var mfaCallback: ((Int) -> Void)?
    
    private static var methodSetted = ""

    public static func setTxnAuthActivity(activity: String) {
        methodSetted = activity
    }
    static func getMFACallback() -> ((Int) -> Void)? {
        return mfaCallback
    }
    
    static func setMFACallback(mfaCallback: @escaping (Int) -> Void) {
        self.mfaCallback = mfaCallback
    }
    
    public static func signUp(userId: String, mfaCallback: @escaping (Int) -> Void) {
        self.mfaCallback = mfaCallback
        let method = "Sign Up"
        let policyLevel = Utils.getSignUpLevel()
//        print("signUp: \(policyLevel)")
        signUpSignInMFA(method: method, userId: userId, policyLevel: policyLevel)
    }
    
    public static func signIn(userId: String, mfaCallback: @escaping (Int) -> Void) {
        self.mfaCallback = mfaCallback
        let method = "Sign In"
        let policyLevel = Utils.getSignInLevel()
//        print("signIn: \(policyLevel)")
        signUpSignInMFA(method: method, userId: userId, policyLevel: policyLevel)
    }
    
    public static func txnAuth(userId: String, txnId: String, amount: Double, mfaCallback: @escaping (Int) -> Void) {
        self.mfaCallback = mfaCallback
        var method = "Transaction"
        if !methodSetted.isEmpty {
            method = methodSetted
        }
        var dataTxn = Utils.getTxnLevel()
        dataTxn = dataTxn.replacingOccurrences(of: "\\\"", with: "\"")
                                    .replacingOccurrences(of: "\"[", with: "[")
                                    .replacingOccurrences(of: "]\"", with: "]")
        var policyLevel = "1,2"
//        print("txnAuth: \(dataTxn)")
        if !dataTxn.isEmpty {
            if let data = dataTxn.data(using: .utf8) {
                do {
                    // Parse to generic JSON array
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        for json in jsonArray {
                            let min = json["min"] as? Double ?? 0
                            let max = json["max"] as? Double ?? 0
                            let policy = json["policy"] as? String ?? ""
                            if max == -1 {
                                if amount >= min {
                                    policyLevel = policy
                                    break
                                }
                            } else {
                                if amount >= min && amount <= max {
                                    policyLevel = policy
                                    break
                                }
                            }
                        }
                        openMFA(method: method, flag: policyLevel)
                    }
                } catch {
                    print("Error converting string to JSONArray:", error)
                }
            }
        }
    }
    
    private static func signUpSignInMFA(method: String, userId: String, policyLevel: String) {
        Nexilis.showLoader()
        DispatchQueue.global().async {
            var id = ""
            if Utils.isMiddleMode() || Utils.isHSAMode() {
                id = Nexilis.justInit()
            } else {
                id = User.getMyPin() ?? ""
            }
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignUpSignInAPI(p_name: userId, p_password: "", xPin: id), timeout: 15 * 1000) {
                if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader {
                            let errMessage = "Invalid user / Username and password does not match".localized()
                            UIApplication.shared.visibleViewController?.view.makeToast(errMessage, duration: 3)
                            APIS.getMFACallback()?(2)
                        }
                    }
                } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader {
                            let errMessage = "Failed, unknown user".localized()
                            UIApplication.shared.visibleViewController?.view.makeToast(errMessage, duration: 3)
                            APIS.getMFACallback()?(2)
                        }
                    }
                } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "4u" {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader {
                            let errMessage = "Failed, blocked user".localized()
                            UIApplication.shared.visibleViewController?.view.makeToast(errMessage, duration: 3)
                            APIS.getMFACallback()?(2)
                        }
                    }
                } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "13" {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader {
                            let errMessage = "Failed, This user is not registered on this device".localized()
                            UIApplication.shared.visibleViewController?.view.makeToast(errMessage, duration: 3)
                            APIS.getMFACallback()?(2)
                        }
                    }
                } else if !response.isOk() {
                    DispatchQueue.main.async {
                        Nexilis.hideLoader {
                            let errMessage = "Failed".localized()
                            UIApplication.shared.visibleViewController?.view.makeToast(errMessage, duration: 3)
                            APIS.getMFACallback()?(2)
                        }
                    }
                } else {
                    if Database.shared.openDatabase() == 0 {
                        APIS.showRestartApp()
                        KeyManagerNexilis.deleteKey()
                        KeyManagerNexilis.deleteMarker()
                        return
                    }
                    let sign = response.getBody(key: CoreMessage_TMessageKey.SIGN, default_value: "")
                    if sign == "1" {
                        let id = response.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "")
                        let f_pin = response.getBody(key: CoreMessage_TMessageKey.F_PIN_REAL, default_value: "")
                        let device_id = response.getBody(key: CoreMessage_TMessageKey.IMEI, default_value: id)
                        let last_sign = response.getBody(key: CoreMessage_TMessageKey.LAST_SIGN, default_value: "0")
                        if last_sign != "0" {
                            Utils.setLoginMultipleFPin(value: f_pin)
                            DispatchQueue.main.async {
                                let errMessage = "Multiple Login Detected...".localized()
                                UIApplication.shared.visibleViewController?.view.makeToast(errMessage, duration: 3)
                                if Nexilis.showFB {
                                    Nexilis.floatingButton.removeFromSuperview()
                                    FloatingButton.datePull = nil
                                    Nexilis.floatingButton = FloatingButton()
                                    Nexilis.addFB()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                                    let dialog = DialogUnableAccess()
                                    dialog.modalTransitionStyle = .crossDissolve
                                    dialog.modalPresentationStyle = .overCurrentContext
                                    UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                })
                            }
                            return
                        }
                        DispatchQueue.main.async {
                            UIApplication.shared.visibleViewController?.deleteAllRecordDatabase()
                        }
                        if(!id.isEmpty) {
                            SecureUserDefaults.shared.set(device_id, forKey: "device_id")
                            Utils.setProfile(value: true)
                            // pos registration
                            _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: id))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                Nexilis.hideLoader(completion: {
                                    if Nexilis.showFB {
                                        Nexilis.floatingButton.removeFromSuperview()
                                        FloatingButton.datePull = nil
                                        Nexilis.floatingButton = FloatingButton()
                                        Nexilis.addFB()
                                    }
                                    Nexilis.getFeatureAccess()
                                    openMFA(method: method, flag: policyLevel)
                                })
                            })
                        }
                    } else {
                        let idMe = User.getMyPin()!
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: idMe))
                        Utils.setProfile(value: true)
                        DispatchQueue.main.async {
                            Nexilis.hideLoader(completion: {
                                openMFA(method: method, flag: policyLevel)
                            })
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    Nexilis.hideLoader {
                        let errMessage = "Unable to access servers. Check your internet connection and try again later".localized()
                        UIApplication.shared.visibleViewController?.view.makeToast(errMessage, duration: 3)
                        APIS.getMFACallback()?(13)
                    }
                }
            }
        }
    }
    
    private static func openMFA(method: String, flag: String) {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        if flag == MFAViewController.STEP_FIDO || flag == MFAViewController.STEP_FIDO_BIOFACE || flag == MFAViewController.STEP_FIDO_BIOFINGER {
            checkFidoWithOrBIO(method: method, flag: flag)
        } else {
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
    
    private static func checkFidoWithOrBIO(method: String, flag: String) {
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
                            let errorMessage = "PPKey Generated Failed".localized()
                            let dialog = DialogErrorMFA()
                            dialog.modalTransitionStyle = .crossDissolve
                            dialog.modalPresentationStyle = .overCurrentContext
                            dialog.errorDesc = errorMessage
                            dialog.method = method
                            UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                            APIS.getMFACallback()?(5)
                        }
                        return
                    }
                    var id = ""
                    if Utils.isMiddleMode() || Utils.isHSAMode() {
                        id = Nexilis.justInit()
                    } else {
                        id = User.getMyPin() ?? ""
                    }
                    if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChalanger(xPin: id)) {
                        if response.isOk() {
                            let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
                            if data.isEmpty {
                                KeyManagerNexilis.deleteKey()
                                KeyManagerNexilis.deleteMarker()
                                DispatchQueue.main.async {
                                    let errorMessage = "Auth Failure".localized()
                                    let dialog = DialogErrorMFA()
                                    dialog.modalTransitionStyle = .crossDissolve
                                    dialog.modalPresentationStyle = .overCurrentContext
                                    dialog.errorDesc = errorMessage
                                    dialog.method = method
                                    UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                    APIS.getMFACallback()?(2)
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
//                            let secret = "JBSWY3DPEHPK3PXP" // Google Authenticator example
                            let otp = try TOTPGenerator.generateTOTP(base32Secret: TOTPGenerator.getTOTP(), digits: 6, timeStepSeconds: 300)
                            message.mBodies[CoreMessage_TMessageKey.TOTP] = otp
                            if let response = Nexilis.writeAndWait(message: message) {
                                if response.isOk() {
                                    if flag == MFAViewController.STEP_FIDO_BIOFACE || flag == MFAViewController.STEP_FIDO_BIOFINGER {
                                        let semaphore = DispatchSemaphore(value: 0)
                                        var result = true
                                        var stateErr = 0
                                        let manager = BiometricStateManager()
                                        if method == "Sign Up" {
                                            manager.authenticateAndSaveState { res in
                                                result = res
                                                semaphore.signal()
                                            }
                                        } else {
                                            manager.hasBiometricStateChanged { (res, state) in
                                                result = res
                                                stateErr = state
                                                semaphore.signal()
                                            }
                                        }
                                        
                                        semaphore.wait()

                                        if result {
                                            DispatchQueue.main.async {
                                                UIApplication.shared.visibleViewController?.view.makeToast("Successfully Authenticated".localized(), duration: 3)
                                            }
                                            APIS.getMFACallback()?(0)
                                        } else {
                                            KeyManagerNexilis.deleteKey()
                                            KeyManagerNexilis.deleteMarker()
                                            DispatchQueue.main.async {
                                                var errorMessage = "Gagal mendeteksi Biometric (Touch/Face ID)"
                                                var errCode = 10
                                                if stateErr == 1 {
                                                    errorMessage = "Terjadi Perubahan Biometric (Touch/Face ID)"
                                                    errCode = 14
                                                }
                                                let dialog = DialogErrorMFA()
                                                dialog.modalTransitionStyle = .crossDissolve
                                                dialog.modalPresentationStyle = .overCurrentContext
                                                dialog.errorDesc = errorMessage
                                                dialog.method = method
                                                dialog.hideTryAgain = (stateErr == 1)
                                                dialog.isDismiss = { res in
                                                    if res == 0 {
                                                        APIS.logOut()
                                                        APIS.getMFACallback()?(errCode)
                                                    }
                                                }
                                                UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                            }
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            UIApplication.shared.visibleViewController?.view.makeToast("Successfully Authenticated".localized(), duration: 3)
                                        }
                                        APIS.getMFACallback()?(0)
                                    }
                                }
                                else {
                                    KeyManagerNexilis.deleteKey()
                                    KeyManagerNexilis.deleteMarker()
                                    let errorMessage = response.getBody(key: CoreMessage_TMessageKey.MESSAGE_TEXT, default_value: "Auth Failure".localized())
                                    let errCode = response.getBodyAsInteger(key: CoreMessage_TMessageKey.ERRAPICOD, default_value: 2)
                                    DispatchQueue.main.async {
                                        let dialog = DialogErrorMFA()
                                        dialog.modalTransitionStyle = .crossDissolve
                                        dialog.modalPresentationStyle = .overCurrentContext
                                        dialog.errorDesc = errorMessage
                                        dialog.method = method
                                        UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                        APIS.getMFACallback()?(errCode)
                                    }
                                }
                            } else {
                                KeyManagerNexilis.deleteKey()
                                KeyManagerNexilis.deleteMarker()
                                DispatchQueue.main.async {
                                    let errorMessage = "Unable to access servers. Check your internet connection and try again later".localized()
                                    let dialog = DialogErrorMFA()
                                    dialog.modalTransitionStyle = .crossDissolve
                                    dialog.modalPresentationStyle = .overCurrentContext
                                    dialog.errorDesc = errorMessage
                                    dialog.method = method
                                    UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                    APIS.getMFACallback()?(13)
                                }
                            }
                        }
                    } else {
                        KeyManagerNexilis.deleteKey()
                        KeyManagerNexilis.deleteMarker()
                        DispatchQueue.main.async {
                            let errorMessage = "Unable to access servers. Check your internet connection and try again later".localized()
                            let dialog = DialogErrorMFA()
                            dialog.modalTransitionStyle = .crossDissolve
                            dialog.modalPresentationStyle = .overCurrentContext
                            dialog.errorDesc = errorMessage
                            dialog.method = method
                            UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                            APIS.getMFACallback()?(13)
                        }
                    }
                } catch {
                }
            }
        }
    }
    
    public static func setFloatingButton(isShow: Bool) {
        DispatchQueue.main.async {
            Nexilis.floatingButton.removeFromSuperview()
            FloatingButton.datePull = nil
            if isShow {
                Nexilis.floatingButton = FloatingButton()
                Nexilis.addFB()
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
        if blockedByCallInProgress() {
            return
        }
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
        if blockedByCallInProgress() {
            return
        }
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
        Nexilis.buttonClicked(index: idx, id: url)
    }
    
    public static func openWallet() {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            APIS.showChangeProfile()
            return
        }
        let idx = Nexilis.IDX_WALLET
        let url = getURLFB(idx: idx)
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
                        let listSplit = package_id.split(separator: "_", maxSplits: 2, omittingEmptySubsequences: false).map { String($0) }
                        let numIdx = listSplit[listSplit.firstIndex(where: { $0.contains("fb") }) ?? 0]
                        let indexTap = Int(String(numIdx).substring(from: 2, to: numIdx.count)) ?? 0
                        return indexTap == idx
                    }
                    return package_id.isEmpty
                })
                if filteredData.count != 0 {
                    let data = filteredData[0] as? [String: Any]
                    let package_id = data?["package_id"] as! String
                    let listSplit = package_id.split(separator: "_", maxSplits: 2, omittingEmptySubsequences: false).map { String($0) }
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
    
    public static var uuidCall: UUID?
    public static var fpinCall: String?
    static var isHasFormCS: Bool = false
    static var listMessageFromAPN: [String] = []
    private static let listMessageFromAPNLock = NSLock()
    public static func showNotificationNexilis(_ userInfo: [AnyHashable : Any], completion: @escaping (UIBackgroundFetchResult) -> Void = { _ in }) {
        // Take a background task assertion so iOS doesn't suspend us the instant
        // completion() runs elsewhere; also acts as a hard safety-net deadline.
        var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
        var didFinish = false
        let finishLock = NSLock()
        func finish(_ result: UIBackgroundFetchResult) {
            finishLock.lock()
            defer { finishLock.unlock() }
            if didFinish { return }
            didFinish = true
            completion(result)
            if backgroundTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskId)
                backgroundTaskId = .invalid
            }
        }
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "showNotificationNexilis") {
            // Expiration handler: OS is about to kill us regardless. Report .failed
            // so we don't silently drop the message with no signal at all.
            finish(.failed)
        }
        // Fix: FirebaseAuth sends itself a fake "prober" notification through the app
        // delegate to check that notifications are being forwarded to it
        // (AuthNotificationManager.checkNotificationForwarding). It carries no message and
        // nothing here can do anything with it, but it used to go through the whole incoming
        // -message pipeline - a background assertion, DB opens, retries - and hold the
        // handler for it.
        if let firebaseAuthPayload = userInfo["com.google.firebase.auth"] as? [String: Any],
           firebaseAuthPayload["warning"] != nil {
            finish(.noData)
            return
        }
        DispatchQueue.main.async {
            if checkAppStateisBackground() {
                if let data = userInfo["data"] as? [String: Any] {
                    ccActionFromAPN(data: data)
                    finish(.newData)
                } else {
                    DispatchQueue.global(qos: .background).async {
                        if let payload = userInfo["payload"] as? [String: Any] {
                            if let messagePayload = payload["message"] as? [String: Any] {
                                if let data = messagePayload["data"] as? [String: Any] {
                                    let code = data["nx_code"] as? String ?? ""
                                    if code == "CL01" {
                                        if let message = data["bodies"] as? [String: String] {
                                            let idAck = data["message_id"] as? String ?? ""
                                            let messageId = message[CoreMessage_TMessageKey.MESSAGE_ID] ?? ""
                                            let messageToSave = TMessage()
                                            messageToSave.mBodies = message
                                            // Fix: the DB "does this message_id already exist" check below is not
                                            // atomic with the save that follows - a redelivered/duplicate CL01 push
                                            // for the same message_id arriving a few ms apart (APNs redelivery,
                                            // multiple device registrations, etc.) could pass this check on both
                                            // deliveries before either had finished writing, causing two concurrent
                                            // save attempts. The pull-based path already guards this with an
                                            // in-flight id lock (listMessageFromAPN); reuse the same lock here so
                                            // both push paths dedup consistently.
                                            var alreadyInFlightCL01 = false
                                            if !messageId.isEmpty {
                                                listMessageFromAPNLock.lock()
                                                if listMessageFromAPN.contains(messageId) {
                                                    alreadyInFlightCL01 = true
                                                } else {
                                                    listMessageFromAPN.append(messageId)
                                                }
                                                listMessageFromAPNLock.unlock()
                                            }
                                            if alreadyInFlightCL01 {
                                                finish(.noData)
                                                return
                                            }
                                            func releaseCL01InFlight() {
                                                guard !messageId.isEmpty else { return }
                                                listMessageFromAPNLock.lock()
                                                listMessageFromAPN.removeAll { $0 == messageId }
                                                listMessageFromAPNLock.unlock()
                                            }
                                            do {
                                                var messageExist = false
                                                // Fix: make sure DB is actually open before checking - otherwise
                                                // this silently always reports "not exist" while backgrounded.
                                                Database.shared.ensureOpenForBackgroundWrite()
                                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message_id from MESSAGE where message_id = '\(messageId)'"), cursor.next() {
                                                        messageExist = true
                                                        cursor.close()
                                                    }
                                                })
                                                if messageExist {
                                                    ackAPN(id: idAck)
                                                    releaseCL01InFlight()
                                                    finish(.noData)
                                                    return
                                                }
                                            } catch {
                                                print("error saving message: \(error)")
                                            }
                                            APIS.addNotificationNexilis(messageToSave)
                                            // Fix: ackAPN used to be called here, BEFORE saveMessage had
                                            // actually written the row - if saveMessage silently bailed out
                                            // (empty message_id/f_pin guard), rolled back on an insert error,
                                            // or the DB connection had been cleared by enterBackground() while
                                            // the app was minimized, the server would already consider the
                                            // message delivered and never resend it, permanently losing it.
                                            // Now: save (with DB-reopen + retry-with-backoff on failure via
                                            // saveIncomingMessageWithRetry), verify, and only then ACK.
                                            saveIncomingMessageWithRetry(message: messageToSave, messageId: messageId) { success in
                                                if success {
                                                    ackAPN(id: idAck)
                                                } else {
                                                    // Fix: do NOT ack after exhausting retries - leaving this
                                                    // un-acked lets the server redeliver later instead of losing it.
                                                    print("WARNING: giving up persisting message \(idAck) after retries - skipping ACK so server can redeliver")
                                                }
                                                releaseCL01InFlight()
                                                finish(.newData)
                                            }
                                        } else {
                                            finish(.newData)
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
                                        finish(.newData)
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
                                        finish(.newData)
                                    } else {
                                        finish(.noData)
                                    }
                                } else {
                                    finish(.noData)
                                }
                            } else {
                                finish(.noData)
                            }
                        } else if let message_id = userInfo["message_id"] as? String {
                            // No badge bump here: this fires for redeliveries too, and it fired
                            // before the message was even saved. The badge is set from the
                            // database once the message is actually in it (see
                            // saveIncomingMessageWithRetry).
                            var alreadyInFlight = false
                            listMessageFromAPNLock.lock()
                            if listMessageFromAPN.contains(message_id) {
                                alreadyInFlight = true
                            } else {
                                listMessageFromAPN.append(message_id)
                            }
                            listMessageFromAPNLock.unlock()
                            if alreadyInFlight {
                                // Duplicate/redelivered push for a message we're already
                                // fetching (or just fetched) — don't fire another request.
                                finish(.noData)
                            } else {
                                // Fix: persist the id (UserDefaults-backed, survives app
                                // restarts/force-quit) BEFORE attempting the fetch, so if this
                                // process gets killed mid-flight, enterForeground()'s
                                // reconciliation can still pick it up and retry later - the
                                // in-memory listMessageFromAPN dedup list alone doesn't survive
                                // a kill.
                                PendingMessageStore.shared.save(message_id)
                                // retry: real retry count (was always 0 before, so it never fired),
                                // and we now wait for the network call before signalling completion.
                                getMessageById(id: message_id, retry: 2) { result, _ in
                                    listMessageFromAPNLock.lock()
                                    listMessageFromAPN.removeAll { $0 == message_id }
                                    listMessageFromAPNLock.unlock()
                                    finish(result)
                                }
                            }
                        } else {
                            finish(.noData)
                        }
                    }
                }
            } else {
                if let data = userInfo["data"] as? [String: Any] {
                    ccActionFromAPN(data: data)
                }
                // Fix: this branch - the app being in the foreground - never called the
                // completion handler at all. Every push while the app was open therefore
                // left the handler outstanding until the background-task assertion above
                // expired ~30s later and fired finish(.failed) for it. iOS throttles
                // background delivery for an app that keeps not answering, and on the
                // Firebase-swizzled path the handler is what balances a dispatch group, so
                // leaving it outstanding for half a minute is exactly the window in which a
                // late second call to it turns into an unbalanced dispatch_group_leave.
                // There is nothing to fetch when the app is already open and connected, so
                // the answer is simply .noData, straight away.
                finish(.noData)
            }
        }
    }
    
    private static func ccActionFromAPN(data: [String: Any], fromTapNotif: Bool = false) {
        var nxCode = data["nx_code"] as? String ?? ""
        let packetId = data[CoreMessage_TMessageKey.PACKET_ID] as? String ?? ""
        if nxCode.isEmpty {
            nxCode = data["nxc"] as? String ?? ""
        }
        if nxCode == CoreMessage_TMessageCode.PUSH_CALL_CENTER {
            if !fromTapNotif || (fromTapNotif && !isHasFormCS) {
                isHasFormCS = true
                let pin = data[CoreMessage_TMessageKey.L_PIN] as? String ?? ""
                let fUserId = data[CoreMessage_TMessageKey.F_USER_ID] as? String ?? ""
                let channel = data[CoreMessage_TMessageKey.CHANNEL] as? String ?? ""
                let dataUser = User.getData(pin: pin, lPin: fUserId)
                let displayName = dataUser?.fullName ?? ""
                let thumb = dataUser?.thumb ?? ""
                let complainId = data[CoreMessage_TMessageKey.DATA] as? String ?? ""
                Nexilis.viewFormCS(pin: pin, channel: channel, displayName: displayName, thumb: thumb, id: complainId)
            }
        } else if nxCode == CoreMessage_TMessageCode.ACCEPT_CALL_CENTER {
            let fPinContacCenter = data[CoreMessage_TMessageKey.F_PIN] as? String ?? ""
            let requester = data[CoreMessage_TMessageKey.UPLINE_PIN] as? String ?? ""
            let complaintId = data[CoreMessage_TMessageKey.DATA] as? String ?? ""
            let channel = data[CoreMessage_TMessageKey.CHANNEL] as? String ?? ""
            if !fromTapNotif {
                let message = TMessage()
                message.mBodies[CoreMessage_TMessageKey.F_PIN] = fPinContacCenter
                message.mBodies[CoreMessage_TMessageKey.DATA] = complaintId
                message.mBodies[CoreMessage_TMessageKey.CHANNEL] = channel
                message.mCode = nxCode
                var dataMessage: [AnyHashable : Any] = [:]
                dataMessage["message"] = message
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil, userInfo: dataMessage)
            }
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            if !requester.isEmpty && onGoingCC.isEmpty {
                SecureUserDefaults.shared.set("\(requester),\(fPinContacCenter),\(complaintId)", forKey: "onGoingCC")
                SecureUserDefaults.shared.set("\(fPinContacCenter)", forKey: "membersCC")
            }
        } else if nxCode == CoreMessage_TMessageCode.INVITE_TO_ROOM_CONTACT_CENTER {
            if !fromTapNotif || (fromTapNotif && !isHasFormCS) {
                isHasFormCS = true
                let pin = data[CoreMessage_TMessageKey.L_PIN] as? String ?? ""
                let channel = data[CoreMessage_TMessageKey.CHANNEL] as? String ?? ""
                let complainId = data[CoreMessage_TMessageKey.CALL_CENTER_ID] as? String ?? ""
                let nameInvited = data[CoreMessage_TMessageKey.F_DISPLAY_NAME] as? String ?? ""
                let thumbInvited = data[CoreMessage_TMessageKey.THUMB_ID] as? String ?? ""
                Nexilis.viewFormCSInvited(pin: pin, channel: channel, id: complainId, nameInvited: nameInvited, thumbInvited: thumbInvited)
            }
        } else if nxCode == CoreMessage_TMessageCode.PUSH_MEMBER_ROOM_CONTACT_CENTER && !fromTapNotif {
            let dataM = data[CoreMessage_TMessageKey.DATA] as? String ?? ""
            let message = TMessage()
            message.mBodies[CoreMessage_TMessageKey.DATA] = dataM
            message.mCode = nxCode
            var dataMessage: [AnyHashable : Any] = [:]
            dataMessage["message"] = message
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil, userInfo: dataMessage)
        } else if (nxCode == CoreMessage_TMessageCode.INVITE_END_CONTACT_CENTER || nxCode == CoreMessage_TMessageCode.END_CALL_CENTER || nxCode == CoreMessage_TMessageCode.INVITE_EXIT_CONTACT_CENTER) && !fromTapNotif {
            let dataM = data[CoreMessage_TMessageKey.DATA] as? String ?? ""
            let f_pin = data[CoreMessage_TMessageKey.F_PIN] as? String ?? ""
            let l_pin = data[CoreMessage_TMessageKey.L_PIN] as? String ?? ""
            let message = TMessage()
            message.mBodies[CoreMessage_TMessageKey.DATA] = dataM
            message.mBodies[CoreMessage_TMessageKey.F_PIN] = f_pin
            message.mPIN = l_pin
            message.mCode = nxCode
            var dataMessage: [AnyHashable : Any] = [:]
            dataMessage["message"] = message
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil, userInfo: dataMessage)
        }
        if nxCode == CoreMessage_TMessageCode.PUSH_CALL_CENTER || nxCode == CoreMessage_TMessageCode.PUSH_SECOND_CONTACT_CENTER || nxCode == CoreMessage_TMessageCode.INVITE_TO_ROOM_CONTACT_CENTER {
            DispatchQueue.global().async {
                _ = Nexilis.justInit()
                _ = Nexilis.responseString(packetId: packetId, message: "00")
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
                        } else if Nexilis.isOpenPageCall {
//                            CallManager.shared.reportIncomingCall(uuid: APIS.uuidCall ?? UUID(), callerName: callCancelName, callerId: callFrom, isVideo: callType != "1", isAutoCancel: true)
                            var dataMessage: [AnyHashable : Any] = [:]
                            dataMessage["call_cancel"] = true
                            dataMessage["pin"] = callCancel
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.callFCM), object: nil, userInfo: dataMessage)
                        } else {
                            CallManager.shared.reportIncomingCall(uuid: APIS.uuidCall ?? UUID(), callerName: callCancelName, callerId: callFrom, isVideo: callType != "1", isAutoCancel: true)
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
                    }
                }
            }
        }
    }
    
    static func ackAPN(id: String) {
        DispatchQueue.global(qos: .background).async {
            let parameter: [String : Any] = [
                "pin": User.getMyPin() ?? "",
                "message_id": id
            ]
            Utils.postDataWithCookiesAndUserAgent(from: URL(string: Utils.getDomainOpr() + "ack_message")!, parameter: parameter, isFormData: true, session: Utils.pushPullSession) { data, response, error in
            }
        }
    }

    // Fix: shared "save then verify, retry with backoff on failure" used by both the
    // CL01 push path and the pull_notification (getMessageById) path. This is what
    // actually closes the message-loss gap when the app has been backgrounded/minimized
    // for a while:
    //  1. Database.shared.ensureOpenForBackgroundWrite() re-derives the encryption key
    //     and reopens the DB connection if enterBackground() had cleared it (which was
    //     silently turning every saveMessage() call into a no-op).
    //  2. If the save still doesn't verify (e.g. a transient SQLITE_BUSY from the
    //     incoming-push write queue being momentarily contended), it retries a few times
    //     with a short backoff instead of giving up immediately.
    // Always hops onto a background queue internally, so it's safe to call this from
    // main-thread contexts too (e.g. getMessageById's network completion handler)
    // without blocking the UI during the retry delays.
    private static func saveIncomingMessageWithRetry(message: TMessage, messageId: String, maxAttempts: Int = 3, completion: @escaping (Bool) -> Void) {
        guard !messageId.isEmpty else {
            completion(false)
            return
        }
        // Fix: persist the id (UserDefaults-backed, survives app restarts/force-quit)
        // before the first attempt, so if the process gets killed mid-save,
        // enterForeground()'s reconciliation can still retry it later. Covers the CL01
        // path too (which previously never registered with PendingMessageStore at all).
        PendingMessageStore.shared.save(messageId)
        func attempt(_ attemptNumber: Int) {
            DispatchQueue.global(qos: .utility).async {
                Database.shared.ensureOpenForBackgroundWrite()
                Nexilis.saveMessage(message: message, withStatus: false, fromAPNS: true)
                var messageSaved = false
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message_id from MESSAGE where message_id = '\(messageId)'"), cursor.next() {
                        messageSaved = true
                        cursor.close()
                    }
                })
                if messageSaved {
                    // Fix: only clear it from the pending store once we've actually
                    // confirmed it's saved - not just attempted.
                    PendingMessageStore.shared.remove(messageId)
                    // A notification tap may have been waiting for exactly this message
                    // (it wasn't on disk when the user tapped it); now it can be honoured.
                    satisfyPendingNotificationOpen(resolvedIdHint: messageId)
                    // Still on this queue, before the push handler hands control back to iOS:
                    // the count on the icon is now the count in the database.
                    refreshApplicationBadge(fallbackIncrement: true)
                    completion(true)
                    return
                }
                print("WARNING: attempt \(attemptNumber)/\(maxAttempts) failed to persist message \(messageId) to DB")
                if attemptNumber < maxAttempts {
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + Double(attemptNumber) * 0.5) {
                        attempt(attemptNumber + 1)
                    }
                } else {
                    // Fix: deliberately NOT removing from PendingMessageStore here - it
                    // stays recorded so the next time the app comes to foreground,
                    // reconciliation gets another chance to fetch and save it.
                    completion(false)
                }
            }
        }
        attempt(1)
    }
    
    // `resolvedId` is the MESSAGE_ID the server actually answered with, which is not always
    // the id that was asked for - see APNMessageAliasStore. Callers that need to find the
    // message afterwards (the notification tap) must use it rather than the id they passed in.
    private static func getMessageById(id: String, retry: Int = 0, completion: @escaping (UIBackgroundFetchResult, String?) -> Void = { _, _ in }) {
        //HTTPS
        let parameter: [String : Any] = [
            "pin": User.getMyPin() ?? "",
            "message_id": id
        ]
        // Fix: single place that decides whether to retry the pull. Previously only a
        // transport-level `error` (no connectivity, DNS failure, etc) triggered a retry -
        // a non-2xx HTTP status, malformed JSON, or an empty "data" field from the server
        // all fell through to completion(.failed) immediately, even with retry attempts
        // still available and even though the network request itself succeeded.
        func retryFetch(reason: String, attemptsLeft: Int, serverHasNothing: Bool = false) {
            print("pull_notification failed for \(id) (\(attemptsLeft) retries left): \(reason)")
            if attemptsLeft > 0 {
                // Fix: small backoff that grows with each attempt, giving a flaky/
                // reconnecting network (e.g. cellular handoff) a bit more time to
                // recover instead of immediately retrying into the same failure.
                let attemptNumber = retry - attemptsLeft + 1
                let delay = Double(attemptNumber) * 1.5
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.getMessageById(id: id, retry: attemptsLeft - 1, completion: completion)
                }
            } else {
                if serverHasNothing {
                    // Fix: the server answered, and its answer was "there is no message for
                    // this id" - it had already been delivered and acked earlier. Retrying
                    // that on every launch is what produced the endless "pull_notification
                    // failed ... empty message payload" loop: the id could never leave
                    // PendingMessageStore because the pull could never succeed again.
                    PendingMessageStore.shared.remove(id)
                }
                completion(.failed, nil)
            }
        }
        Utils.postDataWithCookiesAndUserAgent(from: URL(string: Utils.getDomainOpr() + "pull_notification")!, parameter: parameter, isFormData: true, session: Utils.pushPullSession) { data, response, error in
            if let error = error {
                retryFetch(reason: "transport error: \(error.localizedDescription)", attemptsLeft: retry)
                return
            }
            // Fix: HTTP status was never checked before - a 4xx/5xx response (which still
            // has `error == nil`, since the request itself completed) was silently treated
            // as if the pull had succeeded.
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                retryFetch(reason: "HTTP \(httpResponse.statusCode)", attemptsLeft: retry)
                return
            }
            guard let data = data else {
                retryFetch(reason: "empty response body", attemptsLeft: retry)
                return
            }
            DispatchQueue.main.async {
                do {
                    guard let jsonObj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        retryFetch(reason: "invalid JSON", attemptsLeft: retry)
                        return
                    }
                    let dataObj = jsonObj["data"] as? String ?? ""
                    // Fix: an empty "data" field used to silently produce a message with
                    // no message_id - saveIncomingMessageWithRetry can only retry the SAVE,
                    // not the fetch, so this used to just drop the message with no retry
                    // even though the server might return real data on the next attempt.
                    guard !dataObj.isEmpty else {
                        retryFetch(reason: "empty message payload from server", attemptsLeft: retry, serverHasNothing: true)
                        return
                    }
                    let message = TMessage(data: dataObj)
                    
                    // simpan message
                    let messageId = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID, default_value: "")
                    guard !messageId.isEmpty else {
                        retryFetch(reason: "parsed message has no message_id", attemptsLeft: retry)
                        return
                    }
                    // Fix: same reasoning as the CL01 path - use the shared retry helper so a
                    // cleared DB connection (app was backgrounded) or a transient save failure
                    // gets retried instead of silently losing the message. This whole block
                    // runs on the main thread (JSON parsing), but saveIncomingMessageWithRetry
                    // always hops to a background queue internally so this won't block the UI.
                    saveIncomingMessageWithRetry(message: message, messageId: messageId) { success in
                        if success {
                            // Fix: the id that was asked for has to be released as well. It is
                            // not always the id the message was saved under, and everything
                            // downstream (PendingMessageStore, the notification tap) keys off
                            // the one the push carried - leaving it behind meant this exact
                            // message was pulled again on every single foreground, forever.
                            APNMessageAliasStore.shared.record(apnId: id, storedId: messageId)
                            PendingMessageStore.shared.remove(id)
                            ackAPN(id: id)
                        } else {
                            // Fix: do NOT ack after exhausting retries - leaving this un-acked
                            // lets the server redeliver later instead of losing the message.
                            print("WARNING: giving up persisting message \(id) after retries - skipping ACK so server can redeliver")
                        }
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                        }
                        completion(.newData, messageId)
                    }
                } catch {
                    retryFetch(reason: "JSON parse error: \(error)", attemptsLeft: retry)
                }
            }
        }
    }
    
    public static func addNotificationNexilis(_ message: TMessage) {
        var text = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_TEXT)
//        text = text.toNormalString()
        text = "You got messages..."
        let nameUser = message.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME)
        var threadIdentifier = message.getBody(key: CoreMessage_TMessageKey.OPPOSITE_PIN)
        let scope = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_SCOPE_ID)
        if threadIdentifier.isEmpty || threadIdentifier == User.getMyPin() {
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
        // Fix: the badge travels with the notification. Set this way iOS applies it when the
        // banner is delivered, so it no longer depends on this process still being awake to run
        // some later block - which is what made the badge "sometimes" not move at all.
        let badge = badgeTargetForNewMessage()
        content.badge = NSNumber(value: badge)
        let request = UNNotificationRequest(identifier: messageId, content: content, trigger: nil)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
        // And straight away as well, for the case where the banner is suppressed (the reader is
        // already in the app) but the count still went up.
        setApplicationBadge(badge)
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
    
    /// The screen the user is actually looking at, digging through the tab bar and the
    /// navigation stack rather than stopping at the container that holds them.
    private static func topmostViewController() -> UIViewController? {
        var controller = UIApplication.shared.visibleViewController
        // Containers only ever nest a handful deep; the counter is here so a malformed
        // hierarchy cannot spin this forever.
        for _ in 0..<10 {
            if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
                controller = selected
            } else if let navigation = controller as? UINavigationController, let top = navigation.topViewController {
                controller = top
            } else {
                break
            }
        }
        return controller
    }

    /// Opens a chat from a notification, refreshing the chat list first when that is the
    /// screen the Editor is about to cover.
    ///
    /// The message that the notification is about has usually just been written to the
    /// database (either by the silent push or by the pull on tap), which is after the list
    /// last read from it. Reloading first means the row is already correct when the user
    /// comes back out of the Editor, instead of the list catching up visibly afterwards.
    private static func reloadChatListThenOpen(_ open: @escaping () -> Void) {
        guard let chatList = topmostViewController() as? ChatListTab, chatList.isViewLoaded else {
            open()
            return
        }
        var hasOpened = false
        // Everything here runs on the main thread, so a plain flag is enough to make sure
        // the chat is opened once - by whichever of the reload and the deadline lands first.
        func openOnce() {
            if hasOpened {
                return
            }
            hasOpened = true
            open()
        }
        chatList.reloadChatList {
            openOnce()
        }
        // A reload that stalls (no connection, a query that never calls back) must never be
        // able to swallow the tap: the chat opens regardless shortly after.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            openOnce()
        }
    }

    /// Opens the chat a locally stored message belongs to.
    ///
    /// Returns false when the chat cannot be opened - the message is not on disk (yet), or the
    /// app is in the background so nothing can be presented - so the caller can keep the
    /// request pending instead of dropping it. Reading the message's f_pin/l_pin/scope from the
    /// database is the only way to know which Editor a push belongs to; when the row isn't
    /// there, showEditorOrCallFromAPN would be handed an empty pin and type and open nothing at
    /// all, which is exactly the "tapping the notification does not go to the Editor" case.
    @discardableResult
    private static func openChatForLocalMessage(_ localMessageId: String) -> Bool {
        guard !localMessageId.isEmpty, !checkAppStateisBackground() else {
            return false
        }
        var f_pin = ""
        var l_pin = ""
        var message_scope_id = ""
        var pin = ""
        var chat_id = ""
        Database.shared.ensureOpenForBackgroundWrite()
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, l_pin, message_scope_id, chat_id from MESSAGE where message_id = '\(localMessageId)'"), cursor.next() {
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
        let type = message_scope_id == "4" ? "1" : !message_scope_id.isEmpty ? "0" : ""
        if type.isEmpty || pin.isEmpty {
            return false
        }
        if let navigationC = UIApplication.shared.visibleViewController as? UINavigationController {
            if navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorPersonal || navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorGroup {
                navigationC.popViewController(animated: false)
            }
        }
        // The message this notification is about was written to the database moments ago, so
        // the chat list behind the Editor is one message behind. Refresh it before covering it.
        reloadChatListThenOpen {
            showEditorOrCallFromAPN(pin, type, "CL01")
        }
        return true
    }

    /// Opens the chat for a notification tap that could not be honoured when it happened,
    /// as soon as the message it was about is on disk. Safe to call from anywhere a message
    /// may just have been saved; it does nothing when there is no tap waiting.
    @discardableResult
    public static func satisfyPendingNotificationOpen(resolvedIdHint: String? = nil) -> Bool {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                _ = satisfyPendingNotificationOpen(resolvedIdHint: resolvedIdHint)
            }
            return false
        }
        guard let apnId = APNPendingOpenStore.shared.pendingId() else {
            stopPendingOpenWatchdog()
            return false
        }
        // The message can be on disk under the id the push carried, under the id the server
        // answered with, or under the alias a previous pull recorded - try all of them.
        var candidates: [String] = []
        if let hint = resolvedIdHint, !hint.isEmpty {
            candidates.append(hint)
        }
        if let alias = APNMessageAliasStore.shared.storedId(forAPNId: apnId), !candidates.contains(alias) {
            candidates.append(alias)
        }
        if !candidates.contains(apnId) {
            candidates.append(apnId)
        }
        for candidate in candidates where openChatForLocalMessage(candidate) {
            APNPendingOpenStore.shared.clear()
            stopPendingOpenWatchdog()
            return true
        }
        return false
    }

    // Keeps checking for the tapped message for a short while after the tap. The message can
    // arrive from the pull, from the reconciliation loop, or from the socket once it
    // reconnects - only the first of those can report back directly, so the other two are
    // covered by simply looking again.
    private static var pendingOpenWatchdog: Timer?
    private static var pendingOpenAttemptsLeft = 0
    private static func startPendingOpenWatchdog() {
        DispatchQueue.main.async {
            // ~75s: long enough for a cold launch to finish connecting and for the 12s
            // reconciliation loop to get a few attempts in, short enough that a chat never
            // opens itself long after the user has moved on.
            pendingOpenAttemptsLeft = 30
            guard pendingOpenWatchdog == nil else {
                return
            }
            pendingOpenWatchdog = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                pendingOpenAttemptsLeft -= 1
                if pendingOpenAttemptsLeft <= 0 || APNPendingOpenStore.shared.pendingId() == nil {
                    stopPendingOpenWatchdog()
                    return
                }
                // A backgrounded app can't present anything; the store keeps the request and
                // enterForeground() picks it up again.
                if checkAppStateisBackground() {
                    stopPendingOpenWatchdog()
                    return
                }
                _ = satisfyPendingNotificationOpen()
            }
        }
    }

    private static func stopPendingOpenWatchdog() {
        pendingOpenWatchdog?.invalidate()
        pendingOpenWatchdog = nil
        pendingOpenAttemptsLeft = 0
    }

    /// Runs `work` once the session the HTTPS pulls need has been restored.
    ///
    /// Fix: a notification tapped on a cold launch runs before login state is back, so the pull
    /// went out with an empty pin and could only fail - burning every retry it had within a few
    /// seconds of launch, before the app was ever able to answer. Waiting a moment costs
    /// nothing and turns those retries into attempts that can actually succeed.
    private static func whenSessionReady(attemptsLeft: Int = 12, _ work: @escaping () -> Void) {
        if !(User.getMyPin() ?? "").isEmpty && !Utils.getDomainOpr().isEmpty {
            work()
            return
        }
        guard attemptsLeft > 0 else {
            // Out of patience - try anyway rather than never asking at all.
            work()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            whenSessionReady(attemptsLeft: attemptsLeft - 1, work)
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
                // Only chats wait for the list: an incoming call has to be answered now, and
                // there is no list row behind it to get out of date anyway.
                if type == "0" || type == "1" {
                    reloadChatListThenOpen {
                        showEditorOrCallFromAPN(id, type, callType)
                    }
                } else {
                    showEditorOrCallFromAPN(id, type, callType)
                }
            } else {
                let userInfo = response.notification.request.content.userInfo
                DispatchQueue.main.async {
                    if let message_id = userInfo["message_id"] as? String {
                        // Fix: check the fast path first (message already saved - the common
                        // case), and only fall back to an active network pull if it's genuinely
                        // missing, so tapping a notification that was already processed normally
                        // doesn't pay for an extra round trip.
                        // The push's id first, then whatever a previous pull for it resolved
                        // to - a message pulled earlier is on disk under that one.
                        let localMessageId = APNMessageAliasStore.shared.storedId(forAPNId: message_id) ?? message_id
                        Database.shared.ensureOpenForBackgroundWrite()
                        var alreadyExists = false
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message_id from MESSAGE where message_id = '\(localMessageId)'"), cursor.next() {
                                alreadyExists = true
                                cursor.close()
                            }
                        })
                        if alreadyExists {
                            if !openChatForLocalMessage(localMessageId) {
                                // The row is there but the chat couldn't be presented yet (the
                                // app is still coming up). Keep the tap and let the watchdog
                                // open it once it can, rather than dropping it here.
                                APNPendingOpenStore.shared.record(apnId: message_id)
                                startPendingOpenWatchdog()
                                reloadChatListThenOpen { }
                            }
                        } else {
                            print("Message \(localMessageId) not found locally on notification tap - pulling from server before opening chat")
                            // Fix: the tap used to be a single shot - one pull, and if that pull
                            // failed the tap was lost entirely: no chat opened, and (because the
                            // id was never registered as pending) nothing kept chasing the
                            // message either, so the list only caught up once the user
                            // backgrounded the app and the socket reconnect delivered it. On a
                            // cold launch that pull is very likely to fail: it can run before the
                            // session the request needs has been restored. Now the request is
                            // remembered, the id joins the reconciliation queue, and a watchdog
                            // opens the chat as soon as the message lands - whichever path
                            // (this pull, the reconciliation loop, or the socket) brings it in.
                            APNPendingOpenStore.shared.record(apnId: message_id)
                            PendingMessageStore.shared.save(message_id)
                            startPendingMessageReconciliationLoop()
                            startPendingOpenWatchdog()
                            // The list is behind by this message either way, so refresh it now
                            // rather than leaving the user looking at a stale row while the pull
                            // runs.
                            reloadChatListThenOpen { }
                            whenSessionReady {
                                APIS.getMessageById(id: message_id, retry: 4) { _, resolvedId in
                                    DispatchQueue.main.async {
                                        // Whatever the server said this message really is, that
                                        // is the row to open the chat from.
                                        satisfyPendingNotificationOpen(resolvedIdHint: resolvedId ?? localMessageId)
                                    }
                                }
                            }
                        }
                    } else if let data = userInfo["data"] as? [String: Any] {
                        ccActionFromAPN(data: data, fromTapNotif: true)
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

//    public static func checkClone(window: inout UIWindow?) {
//        CloneCheck.enforceAllChecks(window: &window)
//    }
    
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
        // Fix: stop the pending-message reconciliation loop too - it's only useful
        // (and only reliably fires) while the app is actually in the foreground.
        // enterForeground() restarts it on the next return to the app.
        pendingReconcileTimer?.invalidate()
        pendingReconcileTimer = nil
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
    // Fix: enterForeground() used to drain PendingMessageStore exactly once, right at
    // the moment the app becomes active. If that single burst (getMessageById's own
    // retry:2 backoff) still failed - e.g. the network was reconnecting at that exact
    // instant, or the server pull_notification endpoint hiccuped - the id just sat in
    // PendingMessageStore untouched until the NEXT full background->foreground cycle.
    // A user who opens the app and stays in it (no more backgrounding) could keep
    // looking at a chat missing a message indefinitely, with nothing left "listening"
    // for it. This repeating timer keeps re-attempting any still-pending ids on a
    // fixed cadence for as long as the app stays in the foreground, so an unacked
    // message keeps getting chased instead of only being retried on the next launch.
    private static var pendingReconcileTimer: Timer?
    private static func startPendingMessageReconciliationLoop() {
        DispatchQueue.main.async {
            pendingReconcileTimer?.invalidate()
            pendingReconcileTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { _ in
                // Stop looping once the app leaves the foreground - a background app
                // gets no reliable Timer execution anyway, and enterForeground() will
                // restart this loop on the next return to foreground.
                guard !checkAppStateisBackground() else {
                    pendingReconcileTimer?.invalidate()
                    pendingReconcileTimer = nil
                    return
                }
                if PendingMessageStore.shared.load().isEmpty {
                    pendingReconcileTimer?.invalidate()
                    pendingReconcileTimer = nil
                    return
                }
                pullPendingMessages()
            }
        }
    }
    // Fix: pending ids used to be fired straight at the network, on every foreground and on
    // every tick of the reconciliation timer. An id whose message is already on disk - very
    // much including one saved under a different id (see APNMessageAliasStore) - can never be
    // satisfied by another pull: the server handed it over once and answers "no message for
    // this id" from then on, which is the endless "pull_notification failed ... empty message
    // payload from server" in the logs. Asking the database first is what stops it.
    private static func pullPendingMessages() {
        let pendingIds = PendingMessageStore.shared.load()
        guard !pendingIds.isEmpty else {
            return
        }
        DispatchQueue.global(qos: .utility).async {
            Database.shared.ensureOpenForBackgroundWrite()
            for id in pendingIds {
                let localId = APNMessageAliasStore.shared.storedId(forAPNId: id) ?? id
                var exists = false
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message_id from MESSAGE where message_id = '\(localId)'"), cursor.next() {
                        exists = true
                        cursor.close()
                    }
                })
                if exists {
                    PendingMessageStore.shared.remove(id)
                    // The message arrived by some other route (the socket, most often) after a
                    // notification for it was tapped - the waiting tap can be honoured now.
                    satisfyPendingNotificationOpen(resolvedIdHint: localId)
                    continue
                }
                APIS.getMessageById(id: id, retry: 2)
            }
        }
    }

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
            if !Utils.isHSAMode() && !Utils.isMiddleMode(){
                _ = Nexilis.justInit(isChecking: true)
            }
            // Fix: revives PendingMessageStore reconciliation (was fully commented out).
            // Safety net for cases the push-based paths can't cover on their own - e.g.
            // the app was force-quit by the user while a message was still in flight, so
            // no background code ran at all until they manually reopened the app.
            // getMessageById already handles retry, verification, and removes the id
            // from PendingMessageStore once confirmed saved (see
            // saveIncomingMessageWithRetry) - a still-failing pull just leaves that id
            // here for the next foreground/launch to retry, nothing is force-cleared.
            pullPendingMessages()
            // Whatever happened while the app was away - messages arriving, or being read on
            // another device - the icon should agree with the database again.
            refreshApplicationBadgeSoon()
            // Anything the reader sent while the app was in the background and the link was
            // down is still at status "1"; this is the first chance to finish sending it.
            OutgoingThread.default.resendPending()
            // Fix: keep chasing any id that's still pending after the burst above,
            // instead of going silent until the next background/foreground cycle.
            startPendingMessageReconciliationLoop()
            // A notification tapped while the app couldn't act on it yet (message not on
            // disk, or the app still launching) left its request recorded. Give it another
            // chance now that the app is up: if the message has since arrived, this opens
            // the chat; if it hasn't, the watchdog keeps looking for a short while.
            if APNPendingOpenStore.shared.pendingId() != nil {
                if !satisfyPendingNotificationOpen() {
                    startPendingOpenWatchdog()
                }
            }
        }
        if let me = User.getMyPin() {
            DispatchQueue.global(qos: .userInitiated).async {
                let _ = Nexilis.write(message: CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: me, last_update: 0))
            }
        }
        checkDataForShareExtension()
//        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        if Utils.getSecureFolderOffline() == "0" && afterEnterBackground && Database.shared.database == nil && Utils.getSetProfile() && !Utils.isHSAMode() {
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
            DispatchQueue.global(qos: .userInitiated).async {
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
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "checkNewMessagesNexilis"), object: nil, userInfo: nil)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                if Utils.shouldRequestAuthentication() && Utils.getSetProfile() && (Utils.isMiddleMode() || Utils.isHSAMode()) && Nexilis.hasInit {
                    DispatchQueue.main.async {
                        var viewController = UIApplication.shared.windows.first?.rootViewController
                        var notNull = false
                        while !notNull {
                            viewController = UIApplication.shared.windows.first?.rootViewController
                            if viewController != nil {
                                notNull = true
                            }
                        }
                        Nexilis.showPassSignIn()
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
    
    static func showWarningMaxFile() {
        alertControllerExpired = LibAlertController(
            title: "⚠️ Failed to Load Files".localized(),
            message: "You can select up to 10 files only.".localized(),
            preferredStyle: .alert
        )
        
        alertControllerExpired.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: nil))
        
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(alertControllerExpired, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(alertControllerExpired, animated: true, completion: nil)
        }
    }
    
    static func showMessageGuardFile(mime: String) {
        alertControllerExpired = LibAlertController(
            title: "⚠️ Message Guard Announcement".localized(),
            message: mime == "image/jpeg" ? "Your image have been blocked by Message Guard. Please attach valid image.".localized() : "Your pdf file have been blocked by Message Guard. Please attach valid file.".localized() ,
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
        if Nexilis.callAPNActivated {
            if let uuid = APIS.uuidCall {
                if let callInfo = CallManager.shared.activeCalls[uuid] {
                    if !callInfo.isAccepted {
                        print("send cancel from destroyall")
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.getCancelCall(fPin: callInfo.callerId, type: !callInfo.isVideo ? "1" : "2"))
                        APIS.uuidCall = nil
                        Nexilis.callAPNActivated = false
                    }
                }
            }
        }
        Nexilis.destroyAll()
    }
    
    private static var isCheckingDataForShare = false

    public static func checkDataForShareExtension() {
        DispatchQueue.global().async {

            guard let userDefaults = UserDefaults(suiteName: nameGroupShared),
                  let value = userDefaults.string(forKey: "sharedItem"),
                  !value.isEmpty,
                  !isCheckingDataForShare else {
                return
            }

            isCheckingDataForShare = true

            guard let jsonData = value.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                print("Error parsing JSON")
                isCheckingDataForShare = false
                return
            }

            // MARK: - Extract JSON values
            let typeShare = json["typeShare"] as? Int ?? 1
            let idContact = json["idContact"] as? String ?? ""
            let typeContact = json["typeContact"] as? String ?? "0"
            var data = json["data"] as? String ?? ""

            let imageId = json["image"] as? String ?? ""
            let videoId = json["video"] as? String ?? ""
            let fileId = json["file"] as? String ?? ""
            let audioId = json["audio"] as? String ?? ""
            let thumb = json["thumb"] as? String ?? ""

            let SCOPE = (typeContact == "1") ? "4" : "3"

            // MARK: - Determine groupId & chatId
            var groupId = ""
            var chatId = ""

            if SCOPE == "4" {
                Database.shared.database?.inTransaction { fmdb, _ in
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id id FROM DISCUSSION_FORUM WHERE chat_id = '\(idContact)'"),
                       cursor.next() {
                        groupId = cursor.string(forColumnIndex: 0) ?? ""
                        chatId = idContact
                        cursor.close()
                    } else {
                        groupId = idContact
                    }
                }
            }

            // paths
            let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: nameGroupShared)
            let documentDir = try? FileManager.default.url(for: .documentDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: true)

            // MARK: - Unified validate logic
            func validateIfNeeded(url: URL, completion: @escaping (_ passed: Bool) -> Void) {
                guard Nexilis.checkingAccess(key: "content_inspection") else {
                    completion(true)
                    return
                }

                DispatchQueue.main.async {
                    Nexilis.showLoader(text: "Scanning File...".localized())
                }

                let result = url.validateFile()

                DispatchQueue.main.async {
                    Nexilis.hideLoader {
                        if result == 1 { completion(true) }
                        else {
                            APIS.showWarningFile(type: result)
                            resetPrefs()
                            completion(false)
                        }
                    }
                }
            }

            // MARK: - Unified copy function
            func safeCopy(from: URL?, to: URL?) {
                guard let from = from, let to = to else { return }
                guard FileManager.default.fileExists(atPath: from.path),
                      !FileManager.default.fileExists(atPath: to.path) else { return }
                try? FileManager.default.copyItem(at: from, to: to)
            }

            // MARK: - Message Sender
            func sendIt(attachmentFlag: String,
                        renamedFileId: String = "",
                        renamedAudioId: String = "") {

                let message = CoreMessage_TMessageBank.sendMessage(
                    l_pin: groupId.isEmpty ? idContact : groupId,
                    message_scope_id: SCOPE,
                    status: SCOPE == "3" ? "1" : "2",
                    message_text: data,
                    credential: "0",
                    attachment_flag: attachmentFlag,
                    ex_blog_id: "",
                    message_large_text: "",
                    ex_format: "",
                    image_id: imageId,
                    audio_id: renamedAudioId,
                    video_id: videoId,
                    file_id: renamedFileId,
                    thumb_id: thumb,
                    reff_id: "",
                    read_receipts: "4",
                    chat_id: chatId,
                    is_call_center: "0",
                    call_center_id: "",
                    opposite_pin: SCOPE == "3" ? (User.getMyPin() ?? "") : idContact,
                    gif_id: "",
                    isForwarded: "0",
                    isSecret: "0",
                    specFile: ""
                )

                Nexilis.addQueueMessage(message: message)
                resetPrefs()

                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("reloadTabChats"), object: nil)
                }
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.5, execute: {
                    handleOpenEditor()
                })
            }

            // MARK: - Reset
            func resetPrefs() {
                userDefaults.set("", forKey: "sharedItem")
                userDefaults.synchronize()
                isCheckingDataForShare = false
            }

            // MARK: - Open editor if needed
            func handleOpenEditor() {
                DispatchQueue.main.async {
                    let isPersonal = (SCOPE == MessageScope.WHISPER || SCOPE == MessageScope.FORM || SCOPE == MessageScope.CHATROOM)
                    let inEditorPersonal: String? = SecureUserDefaults.shared.value(forKey: "inEditorPersonal") ?? nil
                    let inEditorGroup: [String]? = SecureUserDefaults.shared.value(forKey: "inEditorGroup") ?? nil
                    if isPersonal && inEditorPersonal != nil {
                        return
                    } else if inEditorGroup != nil{
                        return
                    }

                    let targetVC: UIViewController = {
                        if isPersonal {
                            let vc = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                            vc.unique_l_pin = idContact
                            vc.fromNotification = true
                            return vc
                        } else {
                            let vc = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "editorGroupVC") as! EditorGroup
                            vc.unique_l_pin = chatId.isEmpty ? groupId : chatId
                            vc.fromNotification = true
                            return vc
                        }
                    }()

                    let nav = CustomNavigationController(rootViewController: targetVC)
                    nav.modalPresentationStyle = .fullScreen
                    nav.navigationBar.tintColor = .white
                    nav.navigationBar.barTintColor = UIApplication.shared.visibleViewController?.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
                    nav.navigationBar.isTranslucent = false
                    nav.navigationBar.overrideUserInterfaceStyle = .dark
                    nav.navigationBar.barStyle = .black

                    if UIApplication.shared.visibleViewController is UINavigationController && Nexilis.fromMAB {
                        if targetVC is EditorPersonal {
                            (targetVC as? EditorPersonal)?.fromNotification = false
                        } else {
                            (targetVC as? EditorGroup)?.fromNotification = false
                        }
                        UIApplication.shared.visibleViewController?.show(targetVC, sender: nil)
                    } else {
                        UIApplication.shared.visibleViewController?.present(nav, animated: true, completion: nil)
                    }
                }
            }

            // MARK: - Switch by typeShare
            guard let appURL = appGroupURL else { return }
            guard let doc = documentDir else { return }

            switch typeShare {

            // -------------------- IMAGE --------------------
            case 2:
                let sharedURL = appURL.appendingPathComponent(imageId)
                let thumbURL = appURL.appendingPathComponent(thumb)

                validateIfNeeded(url: sharedURL) { ok in
                    guard ok else { return }

                    let toImage = doc.appendingPathComponent(imageId)
                    let toThumb = doc.appendingPathComponent(thumb)

                    safeCopy(from: sharedURL, to: toImage)
                    safeCopy(from: thumbURL, to: toThumb)

                    sendIt(attachmentFlag: "1")
                }

            // -------------------- VIDEO --------------------
            case 3:
                let sharedURL = appURL.appendingPathComponent(videoId)
                let thumbURL = appURL.appendingPathComponent(thumb)

                validateIfNeeded(url: sharedURL) { ok in
                    guard ok else { return }

                    safeCopy(from: sharedURL,
                             to: doc.appendingPathComponent(videoId))
                    safeCopy(from: thumbURL,
                             to: doc.appendingPathComponent(thumb))

                    sendIt(attachmentFlag: "2")
                }

            // -------------------- FILE --------------------
            case 4:
                let renamed = "Nexilis_\(Date().currentTimeMillis())_\(fileId)"
                let sharedURL = appURL.appendingPathComponent(fileId)

                validateIfNeeded(url: sharedURL) { ok in
                    guard ok else { return }

                    let dest = doc.appendingPathComponent(renamed)
                    safeCopy(from: sharedURL, to: dest)

                    data = "\(fileId)|\(data)"

                    sendIt(attachmentFlag: "6", renamedFileId: renamed)
                }

            // -------------------- AUDIO --------------------
            case 5:
                let renamed = "Nexilis_\(Date().currentTimeMillis())_\(audioId)"
                let sharedURL = appURL.appendingPathComponent(audioId)

                validateIfNeeded(url: sharedURL) { ok in
                    guard ok else { return }

                    let dest = doc.appendingPathComponent(renamed)
                    safeCopy(from: sharedURL, to: dest)
                    data = "\(audioId)|\(data)"

                    sendIt(attachmentFlag: "5", renamedAudioId: renamed)
                }

            // -------------------- TEXT ONLY --------------------
            default:
                sendIt(attachmentFlag: "0")
            }
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
    
    public static func openImageNexilis(imageView: UIImageView, data: Data? = nil, isGIF: Bool = false, nameSender: String = "", time: String = "") {
        let image = UIImage(data: data ?? Data())
        let imageViewer = MediaViewerViewController()
        if !isGIF {
            imageViewer.media = .image(image ?? UIImage())
        } else {
            imageViewer.media = .gif(data ?? Data())
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
        imageViewer.titleCustom = nameSender
        if !time.isEmpty {
            if let timestamp = Double(time) {
                let date = Date(timeIntervalSince1970: timestamp / 1000)
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yy HH:mm"
                imageViewer.subtitleCustom = formatter.string(from: date)
            }
        }
        
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
    
    public static func openVideoNexilis(imageView: UIImageView, videoURL: URL, nameSender: String = "", time: String = "") {
        let imageViewer = MediaViewerViewController()
        imageViewer.media = .video(videoURL)
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
        imageViewer.titleCustom = nameSender
        if !time.isEmpty {
            if let timestamp = Double(time) {
                let date = Date(timeIntervalSince1970: timestamp / 1000)
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yy HH:mm"
                imageViewer.subtitleCustom = formatter.string(from: date)
            }
        }
        
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
    
    public static func setAppMode(mode: Int) {
        Utils.selectedAppMode = mode
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
        UIViewController.swizzleViewDidDisappearImplementation
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
    
    public static func openQris() {
        let scannerVC = QRScannerViewController()
        scannerVC.modalPresentationStyle = .fullScreen
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(scannerVC, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(scannerVC, animated: true, completion: nil)
        }
    }
}

extension UINavigationController {
    public func defaultStyle() {
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
