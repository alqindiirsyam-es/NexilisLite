//
//  Qmera.swift
//  Runner
//
//  Created by Yayan Dwi on 15/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import nuSDKService
import AVFoundation
import AVKit
import UIKit
import FMDB
import QuickLook
import NotificationBannerSwift
import SDWebImage
import CryptoKit
import WebKit
import CommonCrypto

public class Nexilis: NSObject {
    public static var cpaasVersion = "5.1.18"
    public static var sAPIKey = ""
    
    public static var ADDRESS = ""
    
//    static let ADDRESS_33 = "192.168.0.33"
    
    // static let ADDRESS_RELEASE = "202.158.33.26" //CBN

//    static let ADDRESS_RELEASE = "108.137.84.148" //AWS
    
    //    static let PORT = 45328
    //    static let PORT = 65328 // 33
    static var PORT = PORT_RELEASE
    
    static let PORT_33 = 62328
    
    static let PORT_RELEASE = 42328
    
    static var nSessionMode: Int! = 1
    
    static var dispatch: DispatchGroup?
    
    public static var showFB = false
    public static var fromMAB = false
    
    public static let shared = Nexilis()
    
//    public static var broadcastTimer = Timer()
    
    public static var broadcastList = [[String: String]]()
    
    public static var onGoingPushCC: [String: String] = [:]
    
    public static var openBroadcast = false
    
    public static var loadingAlert = LibAlertController()
    
    public static var floatingButton: FloatingButton!
    public static var defaultFloatingButton: [Int] = []
    
    public static var showButtonFB = false
    static var isOpenPageCall = false
    
    static var hasInit = false
    
    public static var imageCache = NSCache<NSString, UIImage>()
    
    public static let listenerReceiveChat = "onReceiveChatLibLite"
    public static let listenerStatusChat = "onMessageChatLibLite"
    public static let listenerTypingChat = "onTypingChatLibLite"
    public static let listenerStatusCall = "onStatusCallLibLite"
    public static let callFCM = "onCallFCM"
    public static let failedSendMessage = "onFailedSendMessage"
    public static var showLibraryNotification = true
    
    public static let STREAMING_SEMINAR_ENDED = 88
    public static let VIDEO_CALL_END = 38
    public static let VIDEO_CALL_MUTE_UNMUTE = 36
    public static let VIDEO_CALL_ZOOM = 35
    public static let VIDEO_CAMERA_PARAMS_CHANED = 34
    public static let VIDEO_CALL_RINGING = 33
    public static let VIDEO_CALL_OFFHOOK = 32
    public static let VIDEO_CALL_INCOMING = 31
    public static let AUDIO_CALL_END = 28
    public static let AUDIO_CALL_RINGING = 23
    public static let AUDIO_CALL_OFFHOOK = 22
    public static let AUDIO_CALL_INCOMING = 21
    public static let AUDIO_VIDEO_CALL_MUTED = 26
    public static let VIDEO_RINGING = 11
    public static let ENDED = 8
    public static let INITIATING = 4
    public static let AUDIO_RINGING = 1
    public static let OUTGOING_CALL = 0
    public static let OFFLINE = -3
    public static let BUSY = -4
    
    public static let IDX_QUEUE_SYSTEM = 2
    public static let IDX_NOTIF_CENTER = 3
    public static let IDX_CC_STREAM = 4
    public static let IDX_CHAT = 6
    public static let IDX_CALL = 7
    public static let IDX_STREAM = 8
    public static let IDX_CC = 9
    public static let IDX_CALL_AUDIO = 11
    public static let IDX_CALL_VIDEO = 12
    public static let IDX_WHITEBOARD = 13
    public static let IDX_SCREENSHARING = 14
    public static let IDX_WB_SS = 15
    public static let IDX_BROADCAST_FORM = 16
    public static let IDX_CONVERSATION = 17
    public static let IDX_FAVORITEMESSAGE = 18
    public static let IDX_CONFERENCE_ROOM_FORM = 19
    public static let IDX_EMAIL_CONFIGURATION = 20
    public static let IDX_CREATE_GROUP = 21
    public static let IDX_ADDFRIEND = 22
    public static let IDX_SIGNUP_OR_IN_PAGE = 23
    public static let IDX_SECURE_FOLDER = 29
    public static let IDX_SETTING = 32
    public static let IDX_WALLET = 72
    public static let IDX_PPOB = 73
    public static let IDX_POST = 99
    public static let IDX_SELF_ACT = 100
    public static let IDX_SOCIAL_COMMERCE = 101
    public static let IDX_NEWS = 102
    public static let IDX_SECURE_BROWSER = 105
    
    public static var callAPNActivated = false
    
    private static var ringtonePlayer: AVAudioPlayer?
    private static var ringbacktonePlayer: AVAudioPlayer?
    private static var busyPlayer: AVAudioPlayer?
    static var sharedAudioPlayer: AVAudioPlayer?
    
    private static var iRetryCheckSignInSignUp = 0
//    static var firstCall = true
    
    private func createDelegate() {
        //print("createDelegate...")
        callDelegate = self
        messageDelegate = self
        groupDelegate = self
        personInfoDelegate = self
    }
    
    public static func connect(apiKey: String, userId:String = "", delegate: ConnectDelegate, showButton: Bool = true, fromMAB: Bool = false) {
        showFB = showButton
        Nexilis.fromMAB = fromMAB
        floatingButton = FloatingButton()
        
        Nexilis.shared.createDelegate()
        
        Nexilis.sAPIKey = apiKey
        
        Nexilis.showButtonFB = showButton
        
        SecureUserDefaults.shared.removeValue(forKey: "lastAuthenticationTime")
        
        do {
            try MasterKeyUtil.shared.generateAndStoreMasterKey()
            try MasterKeyUtil.shared.generateAndStorePrefsKey()
            // Fix: the previous hardcoded/obfuscated default pin for "newuniverse.io"
            // decrypted to a hash that matches NEITHER the (buggy) raw-key hash the
            // app used to compute NOR the correct SPKI hash of the certificate
            // actually served today (verified via openssl). It was simply stale/wrong
            // from the start, so pinning could never succeed for that domain no
            // matter how correct the runtime hashing code was.
            //
            // Fix: each domain now maps to an ARRAY of accepted hashes rather than a
            // single string, so a future certificate/key rotation can be handled by
            // adding the new hash ahead of time (both old and new accepted during the
            // transition) instead of instantly locking out every user the moment
            // Let's Encrypt rotates the leaf certificate.
            //
            // Fix: bumped to a plain (non-obfuscated) literal - a Subject Public Key
            // Info hash is not a secret (it's derived from the public certificate
            // anyone can fetch via openssl), so the custom cipher added no real
            // protection, only made the value painful to audit/update/rotate.
            let pinningSeedVersion = 3
            if Utils.getCertificatePinningWebview().isEmpty || Utils.getCertificatePinningSeedVersion() < pinningSeedVersion {
                let cert: [String: [String]] = [
                    // Fix: confirmed via on-device log (RSA 2048, computed at runtime)
                    // AND cross-checked independently against `openssl s_client -connect
                    // nexilis.io:443 ... | openssl dgst -sha256 | openssl base64` - see
                    // CHANGELOG. The previous value here (from the old obfuscated seed)
                    // never matched the live server and made pinning impossible for the
                    // domain the app actually connects to.
                    "nexilis.io": ["tIAA8SPvbLBRxOAeQYkymqN3MhVpPuJFAbfLxihiMAU="],
                    "newuniverse.io": ["XFRSd92XlkDObEZQZnAC8eULRrmHCTW4prdwSBYr/N4="]
                ]
                if let jsonData = try? JSONSerialization.data(withJSONObject: cert, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    Utils.setCertificatePinningWebview(value: jsonString)
                    Utils.setCertificatePinningSeedVersion(pinningSeedVersion)
                }
            }
        } catch {
        }
        
        let api: String? = SecureUserDefaults.shared.value(forKey: "apiKey") ?? nil
        if api == nil {
            SecureUserDefaults.shared.set(apiKey, forKey: "apiKey")
        }
        
        Utils.setAppMode(value: Utils.selectedAppMode)
        
        IncomingThread.default.run()
        
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 1024 * 1024 * 200
        
        DispatchQueue.global(qos: .userInitiated).async {
            let bExpectedMode = Utils.isHSAMode() || Utils.isMiddleMode()
            if bExpectedMode {
                if !fromMAB && !Utils.getSetProfile() {
                    DispatchQueue.main.async {
                        var viewController = UIApplication.shared.windows.first?.rootViewController
                        var notNull = false
                        while !notNull {
                            viewController = UIApplication.shared.windows.first?.rootViewController
                            if viewController != nil {
                                notNull = true
                            }
                        }
                        showForceSignIn()
                    }
                } else if Utils.getSetProfile() {
                    DispatchQueue.main.async {
                        var viewController = UIApplication.shared.windows.first?.rootViewController
                        var notNull = false
                        while !notNull {
                            viewController = UIApplication.shared.windows.first?.rootViewController
                            if viewController != nil {
                                notNull = true
                            }
                        }
                        showPassSignIn()
                    }
                }
            } else {
                self.startConnect(showButton: showButton, apiKey: apiKey, delegate: delegate)
            }
        }
        
        NetworkMonitor.shared.startMonitoring()
        
        OutgoingThread.default.run()
        
        InquiryThread.default.run()
        
        if UIFont.systemFont(ofSize: 12).familyName == ".AppleSystemUIFont" {
            UIFont.libOverrideInitialize()
        }
        
        _ = LocationManager()
        FileEncryption.shared.wipeFolderOldSecure()
    }
    
    private static var initCallback: ((Int) -> Void)?
    static var successSui: (() -> Void)?
    static func setInitCallback(initCallback: @escaping (Int) -> Void) {
        self.initCallback = initCallback
    }
    public static func setSuccessSui(successSui: @escaping () -> Void) {
        self.successSui = successSui
    }
    
    static func justInit(isChecking: Bool = false) -> String {
//        print("justInit: \(Nexilis.sAPIKey)")
        do {
            var id = Utils.getConnectionID()
            if !hasInit {
                hasInit = true
                let address = Nexilis.getAddressNew(apiKey:Nexilis.sAPIKey)
                if address.isEmpty {
                    return ""
                }
//                print("ADDRESS LEWAT: \(address)")
                Nexilis.ADDRESS = address.components(separatedBy: ":")[0]
                Nexilis.PORT = Int(address.component(1, separatedBy: ":")) ?? 0
                if id.isEmpty {
                    let sDID = UIDevice.current.identifierForVendor?.uuidString ?? "UNK-DEVICE"
                    id = String(sDID[sDID.index(sDID.endIndex, offsetBy: -5)...]) + "\(Date().currentTimeMillis())"
                    Utils.setConnectionID(value: id)
                }
//                print("INIT CONNECTION: \(id)")
                try API.initConnection(sAPIK: Nexilis.sAPIKey, cbiI: Callback(), sTCPAddr: Nexilis.ADDRESS, nTCPPort: Nexilis.PORT, sUserID: id, sStartWH: "09:00", bUseTLS: true)
            }
            if !isChecking {
                while (API.nGetCLXConnState() == 0) {
//                    print("API.nGetCLXConnState() == 0")
                    Thread.sleep(forTimeInterval: 0.5)
                }
            }
            return id
        } catch {
            return ""
        }
    }
    
    static func startConnect(showButton: Bool = Nexilis.showButtonFB, apiKey: String = Nexilis.sAPIKey, userId: String = "", delegate: ConnectDelegate? = nil, withInit: Bool = true) {
//        print("startConnect")
        do {
//            func forceShowFB() {
//                DispatchQueue.main.async {
//                    var viewController = UIApplication.shared.windows.first?.rootViewController
//                    var notNull = false
//                    while !notNull {
//                        viewController = UIApplication.shared.windows.first?.rootViewController
//                        if viewController != nil && Utils.getFinishInitPrefsr() {
//                            notNull = true
//                        }
//                    }
//                    if showButton {
//                        addFB()
//                    }
//                    if let rootViewController = viewController {
//                        let isDarkMode = rootViewController.traitCollection.userInterfaceStyle == .dark
//                        if isDarkMode {
//                            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
//                            let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
//                            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
//                        } else {
//                            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
//                            let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
//                            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
//                        }
//                    }
//                }
//            }
            if withInit {
                if Utils.getFinishInitPrefsr() {
                    Utils.setFinishInitPrefs(value: false)
                }
                if !Utils.getPrefTheme().isEmpty {
//                    forceShowFB()
                    Utils.setFinishInitPrefs(value: true)
                }
            }
            var id = User.getMyPin() ?? ""
            if withInit {
                id = justInit()
                if id.isEmpty {
                    return
                }
            }
            if(User.getMyPin() == nil) {
                iRetryCheckSignInSignUp = 0
                let maxWaitTime: TimeInterval = 60 * 60 // 1 hour in seconds
                let t0 = Date().currentTimeMillis()
                
                do {
                    while iRetryCheckSignInSignUp <= 30 || Date().currentTimeMillis() - t0 <= Int(maxWaitTime) {
                        var tmessage = CoreMessage_TMessageBank.getSignUpApi(api: apiKey, p_pin: id)
                        if !userId.isEmpty {
                            tmessage = CoreMessage_TMessageBank.getSignInApi(api: apiKey, p_pin: id, name: userId)
                        }
                        if let response = Nexilis.writeSync(message: tmessage, timeout: 30 * 1000) {
                            if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                                let message = "94:Unregistered user"
                                delegate?.onFailed(error: message)
                                initCallback?(0)
                                sendStateToServer(s: message)
                                print("checkSignInSignUp sleep 30s before retrying send to server..\(response.toLogString())")
                                Thread.sleep(forTimeInterval: 30)
                            } else if !response.isOk() {
                                let message = "99:Something went wrong. Invalid response, please check your connection.."
                                delegate?.onFailed(error: message)
                                initCallback?(0)
                                sendStateToServer(s: message)
                                print("checkSignInSignUp sleep 30s before retrying send to server..\(response.toLogString())")
                                Thread.sleep(forTimeInterval: 30)
                            } else {
                                SecureUserDefaults.shared.set(id, forKey: "device_id")
                                id = response.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "")
                                var enable_signup = (response.getBody(key: CoreMessage_TMessageKey.IS_ENABLED_ANONYMOUS, default_value: "0")) == "1"
                                if !enable_signup && !userId.isEmpty {
                                    enable_signup = true
                                    Utils.setProfile(value: true)
                                }
                                KeyManagerNexilis.deleteKey()
                                KeyManagerNexilis.deleteMarker()
                                Utils.setForceAnonymous(value: enable_signup)
                                if(!id.isEmpty) {
                                    SecureUserDefaults.shared.set(id, forKey: "me")
                                }
                                break
                            }
                        } else {
                            iRetryCheckSignInSignUp += 1

                            if iRetryCheckSignInSignUp >= 30 {
                                let message: String
                                if !userId.isEmpty {
                                    message = "99:Something went wrong while Sign-In. Please check your connection.."
                                } else {
                                    message = "99:Something went wrong while Sign-Up. Please check your connection.."
                                }
                                delegate?.onFailed(error: message)
                                initCallback?(0)
                                sendStateToServer(s: message)
                            }

                            print("checkSignInSignUp sleep 30s before retrying send to server..")
                            Thread.sleep(forTimeInterval: 30)
                        }
                    }
                } catch {
                    print("checkSignInSignUp error: \(error.localizedDescription)")
                }
            }
            
            sendVersionToBE()
            getPullPrefs()
            getFeatureAccess()

            startSecurityShield(apiKey: apiKey)

            if let me = User.getMyPin() {
                if Utils.getSetProfile() {
                    if Utils.getSecureFolderOffline() != "0" || !userId.isEmpty || !withInit {
//                        print("MASUK OPEN DB")
                        // Fix: this waited for the key and not the IV, while openDatabase() needs
                        // both - with only half of it in hand openDatabase() skips the open
                        // entirely and every statement after it runs against a nil database, doing
                        // nothing and reporting nothing. It also polled on a one-second beat for
                        // something ensureKeyLoaded() can hand over at once.
                        var waitedForKey: TimeInterval = 0
                        while waitedForKey < 60 {
                            FileEncryption.shared.ensureKeyLoaded()
                            if FileEncryption.shared.aesKey != nil, FileEncryption.shared.aesIV != nil {
                                break
                            }
                            Thread.sleep(forTimeInterval: 0.05)
                            waitedForKey += 0.05
                        }
                        _ = Database.shared.openDatabase()
                    }
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT * FROM BUDDY where f_pin = '\(me)' ") {
                                if !cursorData.next() {
                                    _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: me))
                                }
                                cursorData.close()
                            }
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT image_id FROM GROUPZ where group_type = 1 AND official = 1"), cursorData.next() {
                                do {
                                    let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                    let file = documentDir.appendingPathComponent(cursorData.string(forColumnIndex: 0)!)
                                    if !FileManager().fileExists(atPath: file.path) && !FileEncryption.shared.isSecureExists(filename: cursorData.string(forColumnIndex: 0)!) {
                                        Download().startHTTP(forKey: cursorData.string(forColumnIndex: 0)!) { (name, progress) in}
                                    }
                                } catch {}
                                cursorData.close()
                            }
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
//                    getServiceBank()
//                getPullWorkingArea()
                getPullGroupNoMember()
                getWhitelistFileExt()
                delegate?.onSuccess(userId: me)
                initCallback?(1)
//                forceShowFB()
                if (Utils.getSetProfile() && !Utils.getFinishInitPrefsr()) || (!Utils.getForceAnonymous() && !Utils.getFinishInitPrefsr()) {
                    Utils.setFinishInitPrefs(value: true)
                }
                Nexilis.destroyAll()
                if !Utils.getLoginMultipleFPin().isEmpty {
                    let dialog = DialogUnableAccess()
                    dialog.modalTransitionStyle = .crossDissolve
                    dialog.modalPresentationStyle = .overCurrentContext
                    UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                }
            }
        } catch {
            delegate?.onFailed(error: "99:Something went wrong")
            initCallback?(0)
        }
    }
    
    private static var securityShieldStarted = false
    private static let securityShieldLock = NSLock()

    /// Starts the security checks from inside the library, the way Android does it.
    ///
    /// On Android the check belongs to the library, not to the app that hosts it: `API.startInit`
    /// (io.nexilis.dm) fires `SecurityShield.getInstance().check(...)` on a thread of its own right
    /// after `initService` and `getFeatureAccess`, and the app host's own call in `MainActivity` is
    /// commented out. Ours sat in the host's `AppDelegate.onSuccess`, which left the checks out of
    /// any other app embedding NexilisLite and tied them to a delegate callback that only fires
    /// once a pin exists. Same spot in the sequence as Android now, so every host gets them.
    ///
    /// Runs alongside the app - nothing here waits on the result. A device that fails is told so by
    /// SecurityShield itself, through an alert it puts up on a window of its own.
    static func startSecurityShield(apiKey: String) {
        // startConnect runs again on reconnect and re-login; the checks are meant to happen once
        // per launch, and starting a second chain would stack a second alert on top of the first.
        securityShieldLock.lock()
        let alreadyStarted = securityShieldStarted
        securityShieldStarted = true
        securityShieldLock.unlock()
        guard !alreadyStarted else {
            return
        }
        SecurityShield.check(appName: APIS.getAppNm(), apiKey: apiKey)
    }

    private static var ringtoneID: SystemSoundID = 0

    public static func playRingtoneCall() {
        var ringtonePath = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_call_in_ios", withExtension: "mp3")
        if ringtonePath == nil {
            ringtonePath = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: "pb_call_in_ios", withExtension: "mp3")
        }
        if let a = ringtonePath {
//            AudioServicesCreateSystemSoundID(a as CFURL, &ringtoneID)
//            AudioServicesPlaySystemSound(ringtoneID)
            do {
                Nexilis.sharedAudioPlayer = try AVAudioPlayer(contentsOf: a)
                Nexilis.sharedAudioPlayer?.prepareToPlay()
                Nexilis.sharedAudioPlayer?.numberOfLoops = -1
                Nexilis.sharedAudioPlayer?.play()
            } catch {
                
            }
        }
    }
    
    public static func stopRingtoneCall() {
//        AudioServicesDisposeSystemSoundID(ringtoneID)
        Nexilis.sharedAudioPlayer?.stop()
    }
    
    private static var ringBackToneID: SystemSoundID = 0
    
    public static func playRingbacktoneCall() {
        var ringbacktonePath = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_call_out_ios", withExtension: "mp3")
        if ringbacktonePath == nil {
            ringbacktonePath = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: "pb_call_out_ios", withExtension: "mp3")
        }
        if let a = ringbacktonePath {
//            AudioServicesCreateSystemSoundID(a as CFURL, &ringBackToneID)
//            AudioServicesPlaySystemSound(ringBackToneID)
            do {
                Nexilis.sharedAudioPlayer = try AVAudioPlayer(contentsOf: a)
                Nexilis.sharedAudioPlayer?.prepareToPlay()
                Nexilis.sharedAudioPlayer?.numberOfLoops = -1
                Nexilis.sharedAudioPlayer?.play()
            } catch {
                
            }
        }
    }
    
    public static func stopRingbacktoneCall() {
//        AudioServicesDisposeSystemSoundID(ringBackToneID)
        Nexilis.sharedAudioPlayer?.stop()
    }
    
    private static var busyToneID: SystemSoundID = 0
    
    public static func playBusyCall() {
        var busyPath = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_call_busy", withExtension: "mp3")
        if busyPath == nil {
            busyPath = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: "pb_call_busy", withExtension: "mp3")
        }
        if let a = busyPath {
//            AudioServicesCreateSystemSoundID(a as CFURL, &busyToneID)
//            AudioServicesPlaySystemSound(busyToneID)
            do {
                Nexilis.sharedAudioPlayer = try AVAudioPlayer(contentsOf: a)
                Nexilis.sharedAudioPlayer?.prepareToPlay()
                Nexilis.sharedAudioPlayer?.numberOfLoops = -1
                Nexilis.sharedAudioPlayer?.play()
            } catch {
                
            }
        }
    }
    
    public static func stopBusyCall() {
//        AudioServicesDisposeSystemSoundID(busyToneID)
        Nexilis.sharedAudioPlayer?.stop()
    }
    
    public static func addFB() {
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            keyWindow.addSubview(floatingButton)
        }
        // A button added while a screen it does not belong on is already up must not appear on
        // it - the screen has long since had its viewDidAppear.
        FloatingButton.refresh()
        if fromMAB {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let rootVC = window.rootViewController {
                if let navBar = rootVC as? UINavigationController {
                    floatingButton.mySettingDelegate = navBar.rootViewController as? any SettingMABDelegate
                }
            }
        }
    }
    
    public static func sendVersionToBE() {
        DispatchQueue.global().async {
            _ = Nexilis.write(message: CoreMessage_TMessageBank.updateVersion())
        }
    }
    
    private static func getPullPrefs() {
        DispatchQueue.global(qos: .userInitiated).async {
            let urlString = Utils.getBEId().isEmpty ? Utils.getDomainOpr() + "nexilis/logics/get_baseurl_new?key=\(Nexilis.sAPIKey)" : Utils.getDomainOpr() + "nexilis/logics/get_prefs?be=\(Utils.getBEId())&appId=\(APIS.getAppNm().toStupidString())"
            Utils.fetchDataWithCookiesAndUserAgent(from: URL(string: urlString)!) { data, response, error in
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    if let json = try? JSONSerialization.jsonObject(with: responseString.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [String: Any?] {
                        do {
                            if Utils.getBEId().isEmpty {
                                Utils.setBEId(value: "\(json["be_id"] as? Int ?? 0)")
                                getPullPrefs()
                            } else {
                                let dataArray: [[String: Any?]] = [json]
                                if !dataArray.isEmpty && !Utils.getIsLoadThemeFromOther() {
                                    if let jsonData = try? JSONSerialization.data(withJSONObject: dataArray, options: .prettyPrinted) {
                                        // Convert to JSON String
                                        let jsonString = String(data: jsonData, encoding: .utf8)
                                        Utils.setPrefTheme(value: jsonString ?? "")
                                        Utils.setValueInitialApp(data: jsonString ?? "")
                                    }
                                }
                            }
                        } catch {
                        }
                    }
                }
            }
        }
    }
    
    private static func getPullGroupNoMember() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.pullGroupNoMember(), timeout: 30 * 1000), response.isOk() {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                if !data.isEmpty {
                    if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                for json in jsonArray {
                                    let group_id = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.GROUP_ID)
                                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "GROUP_NM", cvalues: [
                                        "group_id" : group_id,
                                        "f_name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.GROUP_NAME),
                                        "scope_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.MESSAGE_SCOPE_ID),
                                        "image_id": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.THUMB_ID),
                                        "quote": CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.QUOTE),
                                        "last_update" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LAST_UPDATE),
                                        "created_by" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CREATED_BY),
                                        "created_date" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CREATED_DATE),
                                        "ex_block" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.BLOCK),
                                        "folder_id" : "",
                                        "chat_modifier" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.CHAT_MODIFIER),
                                        "group_type" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_ORGANIZATION),
                                        "parent" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.PARENT_ID),
                                        "level" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LEVEL),
                                        "is_open" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_OPEN),
                                        "official" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.OFFICIAL_ACCOUNT),
                                        "level_edu" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LEVEL_EDU),
                                        "materi_edu" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.MATERI_EDU),
                                        "is_education" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.IS_EDUCATION)
                                    ], replace: true)
                                }
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                }
            }
        }
    }
    
    private static func getServiceBank() {
        DispatchQueue.global().async {
            _ = Nexilis.write(message: CoreMessage_TMessageBank.getServiceBank())
        }
    }
    
    public static func sendStateToServer(s: String) {
        DispatchQueue.global().async {
            let parameter: [String : Any] = [
                "f_pin": User.getMyPin() ?? "",
                "state": s
            ]
            Utils.postDataWithCookiesAndUserAgent(from: URL(string: Utils.getDomainOpr() + "logging")!, parameter: parameter) { data, response, error in
//                print("\(response)")
            }
        }
    }
    
    static func getFeatureAccessWithKey(key: [String]) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getFeatureAccessWithKey(key: key), timeout: 5000) {
                print("RESPOND: \(response.toLogString())")
            } else {
                print("ERROR")
            }
        }
    }
    
    static var isGettingFeatureAccess: Bool = false
    static func getFeatureAccess() {
        if isGettingFeatureAccess {
            return
        }
        isGettingFeatureAccess = true
        DispatchQueue.global(qos: .userInitiated).async {
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getFeatureAccessAll(), timeout: 10 * 1000), response.isOk() {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "[]")
                do {
                    if let data = data.data(using: .utf8) {
                        if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyObject] {
                            var jsonFA: [String: Any] = [:]
                            var jsonFAWithAlert: [[String: Any]] = []
                            var keyTemp = ""
                            var keyIvTemp = ""
                            let metadataKeys: Set<String> = ["scr", "action", "alert_title", "alert_message"]
                            for jsonData in jsonArray {
                                guard var tmp = jsonData as? [String: Any] else { continue }
                                tmp.removeValue(forKey: "action")
                                if !tmp.keys.contains("secure_folder_encrypt_key") && !tmp.keys.contains("secure_folder_encrypt_key_iv") {
                                    jsonFAWithAlert.append(tmp)
                                }
                                tmp.removeValue(forKey: "alert_title")
                                tmp.removeValue(forKey: "alert_message")

                                let featureKeys = tmp.keys.filter { !metadataKeys.contains($0) }
                                for featureKey in featureKeys where featureKey != "secure_folder_encrypt_key" && featureKey != "secure_folder_encrypt_key_iv" {
                                    jsonFA[featureKey] = tmp[featureKey]
                                }
                                if let umr = jsonData["upload_max_retry"] as? String {
                                    Utils.setMaxRetryUpload(value: umr)
                                }
                                if let umt = jsonData["upload_max_time"] as? String {
                                    Utils.setMaxRetryTimeUpload(value: umt)
                                }
                                if let df = jsonData["default_fb"]! as? String {
                                    if !Utils.getAfterConfigFB() {
                                        Utils.setConfigModeFB(value: df)
                                        DispatchQueue.main.async {
                                            if Nexilis.showFB {
                                                Nexilis.floatingButton.removeFromSuperview()
                                                FloatingButton.datePull = nil
                                                Nexilis.floatingButton = FloatingButton()
                                                Nexilis.addFB()
                                            }
                                        }
                                    }
                                }
                                if let ad = jsonData["authentication_duration"] as? String {
                                    Utils.setAuthenticationDuration(value: ad)
                                }
                                if let sfek = jsonData["secure_folder_encrypt_key"] as? String {
                                    keyTemp = sfek
                                    if let dataKey = Data(base64Encoded: keyTemp, options: .ignoreUnknownCharacters) {
                                        FileEncryption.shared.aesKey = SymmetricKey(data: dataKey)
                                        if Utils.getSecureFolderOffline() == "0" {
                                            Utils.setSecureFolderEncrypt(value: "")
                                        } else {
                                            Utils.setSecureFolderEncrypt(value: keyTemp)
                                        }
                                    }
                                    if let dispatch = IncomingThread.dispatch {
                                        Database.recreateInstance()
                                        dispatch.leave()
                                    }
                                }
                                if let sfeki = jsonData["secure_folder_encrypt_key_iv"] as? String {
                                    keyIvTemp = sfeki
                                    if let dataKey = Data(base64Encoded: keyIvTemp, options: .ignoreUnknownCharacters) {
                                        FileEncryption.shared.aesIV = dataKey
                                        if Utils.getSecureFolderOffline() == "0" {
                                            Utils.setSecureFolderEncryptIv(value: "")
                                        } else {
                                            Utils.setSecureFolderEncryptIv(value: keyIvTemp)
                                        }
                                    }
                                }
                                if let off = jsonData["secure_folder_offline"] as? String {
                                    Utils.setSecureFolderOffline(value: off)
                                    if off == "0" {
                                        Utils.setSecureFolderEncrypt(value: "")
                                        Utils.setSecureFolderEncryptIv(value: "")
                                    } else {
                                        Utils.setSecureFolderEncrypt(value: keyTemp)
                                        Utils.setSecureFolderEncryptIv(value: keyIvTemp)
                                    }
                                }
                                if let greeting = jsonData["chatbot_greetings"] as? String {
//                                        print("Chatbot greeting: \(greeting)")
                                    Utils.setChatbotGreetings(value: greeting)
                                }
                                if let msu = jsonData["mfa_signup"] as? String {
//                                        print("mfa_signup: \(data)")
                                    Utils.setSignUpLevel(value: msu)
                                }
                                if let msi = jsonData["mfa_signin"] as? String {
//                                        print("mfa_signin: \(data)")
                                    Utils.setSignInLevel(value: msi)
                                }
                                if let mt = jsonData["mfa_trx"] as? String {
//                                        print("mfa_trx: \(data)")
                                    let encoder = JSONEncoder()
                                    encoder.outputFormatting = .prettyPrinted
                                    let jsonData = try encoder.encode(mt)
                                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                                        Utils.setTxnLevel(value: jsonString)
                                    }
                                }
                                if let et = jsonData["enable_totp"] as? String {
                                    if et == "1" {
                                        Utils.setEnableTOTP(value: et)
                                    }
                                }
                            }
                            keyTemp = ""
                            keyIvTemp = ""
                            if let convertJsonFA = try? JSONSerialization.data(withJSONObject: jsonFA, options: .prettyPrinted) {
                                if let jsonFAString = String(data: convertJsonFA, encoding: .utf8) {
                                    Utils.setFeatureAccess(value: jsonFAString)
                                }
                            }
                            if let convertJsonFAAlert = try? JSONSerialization.data(withJSONObject: jsonFAWithAlert, options: .prettyPrinted) {
                                if let jsonFAString = String(data: convertJsonFAAlert, encoding: .utf8) {
                                    Utils.setFeatureAccessAlert(value: jsonFAString)
                                }
                            }
                            isGettingFeatureAccess = false
                        }
                    }
                } catch {
                    print("gagal parsing data:")
                }
            } else {
                print("gagal getfeatureaccess:")
                isGettingFeatureAccess = false
                if Utils.getSecureFolderOffline() == "0" || (Utils.getSecureFolderOffline() == "1" && !Utils.getSetProfile()) {
                    getFeatureAccess()
//                    DispatchQueue.main.async {
//                        if !APIS.checkAppStateisBackground() {
//                            APIS.showRestartApp()
//                        } else {
//                            getFeatureAccess()
//                        }
//                    }
                }
            }
        }
    }
    
    public static func checkingAccess(key: String) -> Bool {
        let dataAccess = Utils.getFeatureAccess()
        if dataAccess.isEmpty {
            if key == "sign_in_up_username" {
                return true
            }
            if Utils.selectedAppMode == 1 && key == "sign_in_up_email" {
                return true
            } else if key == "sms" || key == "email" || key == "whatsapp" || key == "battery_optimization_force" || key == "backup_restore" || key == "check_sim_swap" || key == "admin_features" || key == "can_config_fb" || key == "friend_request_approval" || key == "authentication" || key == "sign_in_up_msisdn" || key == "sign_in_up_email" || key == "create_miniapp" || key == "can_switch_style" {
                return false
            } else {
                return true
            }
        } else if let jsonArray = try? JSONSerialization.jsonObject(with: dataAccess.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
            if let value = jsonArray[key] as? String {
                return value == "1"
            } else {
                if key == "sign_in_up_username" {
                    return true
                }
                if Utils.selectedAppMode == 1 && key == "sign_in_up_email" {
                    return true
                } else if key == "sms" || key == "email" || key == "whatsapp" || key == "battery_optimization_force" || key == "backup_restore" || key == "check_sim_swap" || key == "admin_features" || key == "can_config_fb" || key == "friend_request_approval" || key == "authentication" || key == "sign_in_up_msisdn" || key == "sign_in_up_email" || key == "create_miniapp" || key == "can_switch_style" {
                    return false
                } else {
                    return true
                }
            }
        }
        return false
    }
    
    public static func checkingAccessAlert(key: String) -> String {
        let dataAccess = Utils.getFeatureAccessAlert()
        if let jsonArray = try? JSONSerialization.jsonObject(with: dataAccess.data(using: String.Encoding.utf8)!, options: []) as? [[String: Any]] {
            if let indexKey = jsonArray.firstIndex(where: { $0.keys.contains(key) }) {
                let title = jsonArray[indexKey]["alert_title"] as? String ?? ""
                let message = jsonArray[indexKey]["alert_message"] as? String ?? ""
                return "\(title)|\(message)"
            }
        }
        return ""
    }
    
    static func getWhitelistFileExt() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getWhitelistFileExt(), timeout: 5000), response.isOk() {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "[]")
    //            print("SUCCESS getWhitelistFileExt: \(data)")
                Utils.setWhitelistFileExt(value: data)
            } else {
    //            print("GAGAL getWhitelistFileExt")
            }
        }
    }
    
    private static func getPullWorkingArea() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getWorkingAreaContactCenter(), timeout: 30 * 1000), response.isOk() {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                if !data.isEmpty {
                    if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                for json in jsonArray {
                                    var parent = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.PARENT_ID)
                                    if parent.isEmpty {
                                        parent = "-99"
                                    }
                                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "WORKING_AREA", cvalues: [
                                        "area_id" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.WORKING_AREA),
                                        "name" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.NAME),
                                        "parent" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.PARENT_ID),
                                        "level" : CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LEVEL)
                                    ], replace: true)
                                }
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                }
            }
        }
    }
    
    public static func showForceSignIn(completion: (() -> Void)? = nil) {
        guard let controller = APIS.getControllerSign() else { return }
        if let controller = controller as? SignUpSignIn {
            controller.forceLogin = true
            controller.forceSignIn = true
        } else if let controller = controller as? SignInOption {
            controller.forceLogin = true
            controller.forceSignIn = true
        }
        let navigationController = CustomNavigationController(rootViewController: controller)
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
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        UIApplication.shared.windows.first?.rootViewController?.present(navigationController, animated: false, completion: completion)
    }
    
    static func showPassSignIn(isFromSU: Bool = false) {
        let controller = TFAPasswordVC()
        controller.isFromSU = isFromSU
        let navigationController = CustomNavigationController(rootViewController: controller)
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
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        UIApplication.shared.windows.first?.rootViewController?.present(navigationController, animated: false)
    }
    
    public static func destroyAll() {
        let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
        if !onGoingCC.isEmpty {
            let requester = onGoingCC.components(separatedBy: ",")[0]
            let officer = onGoingCC.isEmpty ? "" : onGoingCC.component(1, separatedBy: ",")
            let complaintId = onGoingCC.isEmpty ? "" : onGoingCC.component(2, separatedBy: ",")
            let idMe = User.getMyPin()!
            let startTimeCC: String = SecureUserDefaults.shared.value(forKey: "startTimeCC") ?? ""
            let date = "\(Date().currentTimeMillis())"
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", cvalues: [
                        "type" : "0",
                        "title" : "Contact Center".localized(),
                        "time" : startTimeCC,
                        "f_pin" : officer,
                        "data" : complaintId,
                        "time_end" : date,
                        "complaint_id" : complaintId,
                        "members" : "",
                        "requester": requester
                    ], replace: true)
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            if officer == idMe {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.endCallCenter(complaint_id: complaintId, l_pin: requester))
            } else {
                if requester == idMe {
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.endCallCenter(complaint_id: complaintId, l_pin: officer))
                } else {
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.leaveCCRoomInvite(ticket_id: complaintId))
                }
            }
            SecureUserDefaults.shared.removeValue(forKey: "onGoingCC")
            SecureUserDefaults.shared.removeValue(forKey: "membersCC")
            SecureUserDefaults.shared.removeValue(forKey: "startTimeCC")
            DispatchQueue.main.async {
                if UIApplication.shared.applicationState == .active {
                    let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Call Center Session has ended".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
        }
        if !Nexilis.onGoingPushCC.isEmpty {
            DispatchQueue.global().async {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.timeOutRequestCallCenter(channel: Nexilis.onGoingPushCC["channel"]!, l_pin: Nexilis.onGoingPushCC["l_pin"]!))
            }
        }
        SecureUserDefaults.shared.removeValue(forKey: "inEditorPersonal")
        SecureUserDefaults.shared.removeValue(forKey: "inEditorGroup")
        SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
    }
    
//    public static func changeUser(f_pin: String){
//        do {
//            //print("change user to fpin")
//            Nexilis.dispatch = DispatchGroup()
//            Nexilis.dispatch?.enter()
//
//            try API.switchUser(cbiI: Callback(), sUserID: f_pin)
//
//            // wait until connection true
//            Nexilis.dispatch?.wait()
//            Nexilis.dispatch = nil
//            //print("success change user to fpin")
////            _ = Nexilis.write(message: CoreMessage_TMessageBank.getChangeConnectionID(p_pin: f_pin))
//        } catch{
//            //print(error)
//        }
//    }
    
    public static func apiSendChat(destination: String, message: String, isGroup: Bool, thumbnailName: String = "", imageName: String = "", videoName: String = "", fileName: String = "", audioName: String = "", replyMessageId : String = "") -> String {
        let message = CoreMessage_TMessageBank.sendMessage(l_pin: destination, message_scope_id: isGroup ? MessageScope.GROUP : MessageScope.WHISPER, status: "3", message_text: message, credential: "", attachment_flag: !imageName.isEmpty ? "1" : !videoName.isEmpty ? "2" : !audioName.isEmpty ? "5" : !fileName.isEmpty ? "6" : "0", ex_blog_id: "", message_large_text: "", ex_format: "", image_id: imageName, audio_id: audioName, video_id: videoName, file_id: fileName, thumb_id: thumbnailName, reff_id: replyMessageId, read_receipts: "4", chat_id: "", is_call_center: "0", call_center_id: "", opposite_pin: User.getMyPin() ?? "", specFile: "")
        addQueueMessage(message: message)
        return message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
    }
    
    public static func apiInitiateAudioCall(destination: String) {
        API.initiateCCall(sParty: destination)
    }
    
    public static func apiReceiveAudioCall(destination: String) {
        API.receiveCCall(sParty: destination)
    }
    
    public static func apiInitiateVideoCall(destination: String, backCamera: Bool = false, listRemoteViews: [UIImageView], localView: UIImageView, remoteViewSpeaker: UIImageView) {
        API.initiateCCall(sParty: destination, nCamIdx: backCamera ? 0 : 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViews, ivLocalView: localView, ivRemoteZ: remoteViewSpeaker)
    }
    
    public static func apiReceiveVideoCall(destination: String, backCamera: Bool = false, listRemoteViews: [UIImageView], localView: UIImageView, remoteViewSpeaker: UIImageView) {
        API.receiveCCall(sParty: destination, nCamIdx: backCamera ? 0 : 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViews, ivLocalView: localView, ivRemoteZ: remoteViewSpeaker)
    }
    
    public static func apiInitiateStreaming(localView: UIImageView, titleStream: String = "", backCamera: Bool = false) {
        API.initiateBC(sTitle: titleStream, nCamIdx: backCamera ? 0 : 1, nResIdx: 2, nVQuality: 4, ivLocalView: localView)
    }
    
    public static func apiJoinStreaming(streamerId: String, remoteView: UIImageView) {
        API.joinBC(sBroadcasterID: streamerId, ivRemoteView: remoteView)
    }
    
    public static func apiTerminateStreaming(streamerId: String?) {
        API.terminateBC(sBroadcasterID: streamerId)
    }
    
    public static func apiEndAllCall() {
        API.terminateCall(sParty: nil)
    }
    
    public static func addQueueMessage(message: TMessage, isEditMessage: Bool = false) {
//        OutgoingThread.default.addQueue(message: message)
//        if isEditMessage {
            OutgoingThread.default.addQueue(message: message)
//        } else {
//            InquiryThread.default.addQueue(message: message)
//        }
    }
    
    public static func deleteQueueMessage(message: TMessage) {
        OutgoingThread.default.addQueue(message: message)
    }
    
    private static var wbDelegate: WhiteboardDelegate?
    private static var wbReceiver: WhiteboardReceiver?
    
    public static func setWhiteboardDelegate(delegate: WhiteboardDelegate?){
        Nexilis.wbDelegate = delegate
    }
    
    public static func getWhiteboardDelegate() -> WhiteboardDelegate? {
        return Nexilis.wbDelegate
    }
    
    public static func setWhiteboardReceiver(receiver: WhiteboardReceiver?){
        Nexilis.wbReceiver = receiver
    }
    
    public static func getWhiteboardReceiver() -> WhiteboardReceiver? {
        return Nexilis.wbReceiver
    }
    
    public static func getEditorPersonal() -> EditorPersonal {
        return AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
    }

    public static func getEditorGroup() -> EditorGroup {
        return AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
    }
    
    public static func getEditorStarMessage() -> EditorStarMessages {
        return AppStoryBoard.Palio.instance.instantiateViewController(identifier: "staredVC") as! EditorStarMessages
    }
    
    static func getAddress(apiKey: String) -> [String] {
        var result = [String]()
        let url = URL(string: "https://nexilis.io/dipp/NuN1v3rs3/Qm3r4i0/get_ip?account=\(apiKey)")!
        let urlConfig = URLSessionConfiguration.default
        let sessionDelegate = PinnedURLSessionNexilisDelegate()
        urlConfig.requestCachePolicy = .returnCacheDataElseLoad
        urlConfig.timeoutIntervalForRequest = 10.0
        urlConfig.timeoutIntervalForResource = 10.0
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession(configuration: urlConfig, delegate: sessionDelegate, delegateQueue: nil).dataTask(with: url) {(data, response, error) in
            guard let data = data else {
                semaphore.signal()
                return
            }
            let html = String(data: data, encoding: .utf8)!
            let base64Address = html.component(1, separatedBy: "<body>").components(separatedBy: "</body>")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            if let addressData = Data(base64Encoded: base64Address), let decodeAddress = String(data: addressData, encoding: .utf8) {
                let rows = decodeAddress.trimmingCharacters(in: CharacterSet.newlines).split(separator: ",")
                for r in rows {
                    let _address = r.split(separator: ":")
                    var ip:String = ""
                    let _data = _address[0].split(separator: ".", maxSplits: 4, omittingEmptySubsequences: false)
                    ip.append(String(_data[3]))
                    ip.append(".")
                    ip.append(String(_data[1]))
                    ip.append(".")
                    ip.append(String(_data[0]))
                    ip.append(".")
                    ip.append(String(_data[2]))
                    result.append(ip + ":" + _address[2])
                }
                
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        //print("[App] getAddress:", result)
        return result
    }
    
    static func getAddressNew(apiKey: String) -> String {
        var result = ""
        
        if !Utils.getHarcodedIp().isEmpty {
            result = Utils.getHarcodedIp()
            return result
        }
        let url = URL(string: Utils.getDomainOpr() + Utils.decrypt(str: "2?vpwqeec[pkcoqf{rk{vgi;2k6t5oS;5ut5x3PwP;rrkf") + apiKey)!
//        print("URL: \(url)")
        let urlConfig = URLSessionConfiguration.default
        let sessionDelegate = PinnedURLSessionNexilisDelegate()
        urlConfig.requestCachePolicy = .returnCacheDataElseLoad
        urlConfig.timeoutIntervalForRequest = 10.0
        urlConfig.timeoutIntervalForResource = 10.0
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession(configuration: urlConfig, delegate: sessionDelegate, delegateQueue: nil).dataTask(with: url) {(data, response, error) in
            guard let data = data,
                let url = response?.url,
                let httpResponse = response as? HTTPURLResponse,
                let fields = httpResponse.allHeaderFields as? [String: String] else {
//                print("MASUK SINI0 \(url)")
                semaphore.signal()
                return
            }
            
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
            //print("MASUK SINI1 \(cookies)")
            Utils.setCookiesMobileForStorage(value: convertCookiesToJSONString(cookies: cookies) ?? "")
            HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
            if let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"] {
             Utils.setCookiesMobile(value: cookieHeader.replacingOccurrences(of: "; ", with: ";"))
            }

            let dataEncode = String(data: data, encoding: .utf8)!
//            print("dataEncode \(dataEncode.trimmingCharacters(in: .whitespacesAndNewlines))")
//            //print("decrypt \(Utils.decrypt(str: "4=sm<wmpm1ir==>wtxxl"))")
            if !dataEncode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let dataDecodeBase64 = String(data: Data(base64Encoded: dataEncode)!, encoding: .utf8)!
                let dataRealDecode = Utils.decrypt(str: dataDecodeBase64)
//                print("dataRealDecode \(dataRealDecode)")
                do {
                    if let jsonData = dataRealDecode.data(using: .utf8), let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                        var newDomain = jsonObject["domain"] as! String
                        let jsonAddress = jsonObject["address"] as! [[String: Any]]
                        let newIp = jsonAddress[0]["ip"] as! String
                        let newPort = jsonAddress[0]["portD"] as! String
                        if newDomain.substring(from: newDomain.count-1, to: nil) != "/" {
                            newDomain += "/"
                        }
                        if !newPort.isEmpty && !newIp.isEmpty && ((newIp+":"+newPort) != Utils.getIpOpr() || newDomain != Utils.getDomainOpr()) {
                            //check new domain
                            if checkNewDomain(newDomain) {
                                Utils.setDomainOpr(value: newDomain)
                                Utils.setIpPortOpr(value: (newIp+":"+newPort))
                            }
                        }
                    }
                } catch {
                    
                }
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        result = Utils.getIpOpr()
        if HTTPCookieStorage.shared.cookies(for: URL(string: Utils.getDomainOpr())!)!.count == 0 && !Utils.getCookiesMobileForStorage().isEmpty {
            HTTPCookieStorage.shared.setCookies(convertJSONStringToCookies(jsonString: Utils.getCookiesMobileForStorage()), for: url, mainDocumentURL: nil)
        }
//        print("[App] getAddress:", result)
        return result
    }
    
    public static func reloadCookies(webView: WKWebView) {
        if !Utils.getCookiesMobileForStorage().isEmpty {
            let cookies = convertJSONStringToCookies(jsonString: Utils.getCookiesMobileForStorage())
            for cookie in cookies {
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
    }
    
    private static func convertCookiesToJSONString(cookies: [HTTPCookie]) -> String? {
        let cookiesArray = cookies.map { cookie -> [String: Any] in
            return [
                "name": cookie.name,
                "value": cookie.value,
                "domain": cookie.domain,
                "path": cookie.path,
                "expiresDate": cookie.expiresDate?.timeIntervalSince1970 ?? NSNull(),
                "isSecure": cookie.isSecure,
                "isHTTPOnly": cookie.isHTTPOnly
            ]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: cookiesArray, options: .prettyPrinted) {
            return String(data: jsonData, encoding: .utf8)
        }
        
        return nil
    }
    
    private static func convertJSONStringToCookies(jsonString: String) -> [HTTPCookie] {
        guard let jsonData = jsonString.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
            return []
        }
        
        var cookies: [HTTPCookie] = []
        
        for cookieDict in jsonArray {
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: cookieDict["name"] as? String ?? "",
                .value: cookieDict["value"] as? String ?? "",
                .domain: cookieDict["domain"] as? String ?? "",
                .path: cookieDict["path"] as? String ?? "/",
                .secure: cookieDict["isSecure"] as? Bool ?? false
            ]
            
            if let expiresTimeInterval = cookieDict["expiresDate"] as? TimeInterval {
                properties[.expires] = Date(timeIntervalSince1970: expiresTimeInterval)
            }
            
            if let cookie = HTTPCookie(properties: properties) {
                cookies.append(cookie)
            }
        }
        
        return cookies
    }
    
    private static func checkNewDomain(_ newDomain: String) -> Bool {
        var result = false
        let url = URL(string: "\(newDomain)dipp/NuN1v3rs3/Qm3r4i0/get_ip_domain?account=\(Nexilis.sAPIKey)")!
        let urlConfig = URLSessionConfiguration.default
        let sessionDelegate = PinnedURLSessionNexilisDelegate()
        urlConfig.requestCachePolicy = .returnCacheDataElseLoad
        urlConfig.timeoutIntervalForRequest = 10.0
        urlConfig.timeoutIntervalForResource = 10.0
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession(configuration: urlConfig, delegate: sessionDelegate, delegateQueue: nil).dataTask(with: url) {(data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    guard let url = response?.url,
                        let fields = httpResponse.allHeaderFields as? [String: String] else {
                        semaphore.signal()
                        return
                    }
                    
                    let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
                    HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
                    Utils.setCookiesMobileForStorage(value: convertCookiesToJSONString(cookies: cookies) ?? "")
                    if let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"] {
                     Utils.setCookiesMobile(value: cookieHeader.replacingOccurrences(of: "; ", with: ";"))
                    }
                    
                    result = true
                }
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        return result
    }
    
    static func getCLMUserId() -> String {
        guard let me = User.getMyPin() else {
            return ""
        }
        return me
    }
    
    public static var isProcessWriteSync = false
    public static func writeSync(message: TMessage, timeout: Int = 15 * 1000) -> TMessage? {
        if !API.bInetConnAvailable() || API.nGetCLXConnState() == 0 {
            return nil
        }
        while Nexilis.isProcessWriteSync {
            Thread.sleep(forTimeInterval: 0.5)
        }
        isProcessWriteSync = true
        do {
//            print(">> SENDING MESSAGE >> ", message.getCode())
            if let data = try API.sGetResponse(sRequest: message.pack(), lTimeout: timeout, bKeepTOResp: true) {
                let response = TMessage(data: data)
//                print("<< RESPONSE MESSAGE << ", response.getCode())
                isProcessWriteSync = false
                return response
            }
        } catch {
            //print(error)
        }
        isProcessWriteSync = false
        return nil
    }
    
    public static func write(message: TMessage, timeout: Int = 15 * 1000) -> String? {
        do {
            if !API.bInetConnAvailable() || API.nGetCLXConnState() == 0 {
                return nil
            }
            //print(">> SENDING MESSAGE >> ", message.toLogString())
            if message.getMedia().count == 0 {
                if let data = try API.sSend(sData: message.pack(), nPriority: 1, lTimeout: timeout) {
                    //print("<< RESPONSE MESSAGE << ", data)
                    return data
                }
            }
            // media
            if let data = try API.sSend(abData: message.toBytes(), nPriority: 2, lTimeout: timeout) {
                //print("<< RESPONSE MESSAGE << ", data)
                return data
            }
        } catch {
            //print(error)
        }
        return nil
    }
    
    public static func writeDraw(data: String, timeout: Int = 15 * 1000) -> String? {
        do {
            if !API.bInetConnAvailable() || API.nGetCLXConnState() == 0 {
                return nil
            }
            //print(">> SENDING MESSAGE >> ", data)
            if let data = try API.sSend(sData: data, nPriority: 1, lTimeout: timeout) {
                //print("<< RESPONSE MESSAGE << ", data)
                return data
            }
        } catch {
            //print(error)
        }
        return nil
    }
    
    public static func response(packetId: String, message: TMessage, timeout: Int = 15 * 1000) -> String? {
        var result: String? = nil
        do {
            if !API.bInetConnAvailable() || API.nGetCLXConnState() == 0 {
                return nil
            }
            //print(">> RESPONSE >> " + packetId + " " + message.toLogString());
            result = try API.sSendResponse(sRequestID: packetId, sResponse: message.pack(), lTimeout: timeout)
        } catch {
            //print(error)
        }
        return result
    }
    
    public static func responseString(packetId: String, message: String, timeout: Int = 15 * 1000) -> String? {
        var result: String? = nil
        do {
            if !API.bInetConnAvailable() || API.nGetCLXConnState() == 0 {
                return nil
            }
            //print(">> RESPONSE >> " + packetId + " " + message);
            result = try API.sSendResponse(sRequestID: packetId, sResponse: message, lTimeout: timeout)
        } catch {
            //print(error)
        }
        return result
    }

    public static func setSpeaker(_ isEnabled: Bool, isVideo: Bool = false) {
        do {
            API.adjustVolume(fValue: isEnabled ? 10.0: isVideo ? 0.0 : 3.0)
        } catch {
        }
    }

    public static func buttonClicked(index: Int, id: String = "") {
        //print("BTNCLICK \(index) \(id)")
        if index == IDX_QUEUE_SYSTEM || index == IDX_NEWS || index == IDX_SOCIAL_COMMERCE || index == IDX_WALLET || index == IDX_PPOB {
            if index == IDX_WALLET {
                if !Nexilis.checkingAccess(key: "wallet") {
                    if Nexilis.checkingAccessAlert(key: "wallet") != "|" && !Nexilis.checkingAccessAlert(key: "wallet").isEmpty {
                        let title = Nexilis.checkingAccessAlert(key: "wallet").components(separatedBy: "|")[0]
                        let message = Nexilis.checkingAccessAlert(key: "wallet").component(1, separatedBy: "|")
                        APIS.nexilisShowAlertWithHTMLMessage(on: UIApplication.shared.visibleViewController ?? UIViewController(), title: title, message: message)
                    } else {
                        UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
                    }
                    return
                }
            }
            if index == IDX_PPOB {
                if !Nexilis.checkingAccess(key: "ppob") {
                    if Nexilis.checkingAccessAlert(key: "ppob") != "|" && !Nexilis.checkingAccessAlert(key: "ppob").isEmpty {
                        let title = Nexilis.checkingAccessAlert(key: "ppob").components(separatedBy: "|")[0]
                        let message = Nexilis.checkingAccessAlert(key: "ppob").component(1, separatedBy: "|")
                        APIS.nexilisShowAlertWithHTMLMessage(on: UIApplication.shared.visibleViewController ?? UIViewController(), title: title, message: message)
                    } else {
                        UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
                    }
                    return
                }
            }
            if id == "fb\(index)"{
                APIS.openUrl(url: "https://google.com/")
            } else {
                APIS.openUrl(url: id)
            }
        } else if index == IDX_NOTIF_CENTER {
            APIS.openNotificationCenter()
        } else if index == IDX_CHAT {
            APIS.openChat()
        } else if index == IDX_CALL {
            APIS.openCall()
        } else if index == IDX_STREAM {
            APIS.openStreaming()
        } else if index == IDX_CC {
            APIS.openContactCenter()
        } else if index == IDX_ADDFRIEND {
            APIS.openAddFriend()
        } else if index == IDX_WB_SS {
            APIS.openWhiteboardAndScreenSharing()
        } else if index == IDX_WHITEBOARD {
            APIS.openWhiteboard()
        } else if index == IDX_SCREENSHARING {
            APIS.openWhiteboardAndScreenSharing()
        } else if index == IDX_POST {
            
        } else if index == IDX_CONVERSATION {
            APIS.openConversation()
        } else if index == IDX_FAVORITEMESSAGE {
            APIS.openFavoriteMessage()
        } else if index == IDX_SECURE_FOLDER {
            APIS.openSecureFolder()
        } else if index == IDX_SECURE_BROWSER {
            APIS.openSecureBrowser()
        } else if index == IDX_CONFERENCE_ROOM_FORM {
            APIS.openConference()
        } else if index == IDX_SETTING {
            if Nexilis.floatingButton.mySettingDelegate != nil {
                Nexilis.floatingButton.mySettingDelegate?.settingDelegate()
            } else {
                APIS.openSetting()
            }
        } else if index == IDX_SELF_ACT {
            openApp(id: id)
        }
    }
    
    public static func openApp(id: String) {
        //print("openApp itms-apps://apple.com/app/\(id)")
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            let alert = LibAlertController(title: "Set Profile".localized(), message: "You must set your profile to use this feature".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                guard let controller = APIS.getControllerSign() else { return }
                if let controller = controller as? SignUpSignIn {
                    controller.forceLogin = true
                } else if let controller = controller as? SignInOption {
                    controller.forceLogin = true
                }
                let navigationController = CustomNavigationController(rootViewController: controller)
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
            }))
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
            }
            return
        }
        if let url = URL(string: "itms-apps://apple.com/app/\(id)") {
            UIApplication.shared.open(url)
        }
    }
    
    static func openmailAction(subject: String = "", body: String = "", to: String = "") {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let toEmail = to
        
        let gmailUrl = URL(string: "googlegmail://co?to=\(toEmail)&subject=\(subjectEncoded)&body=\(bodyEncoded)")!
        let outlookUrl = URL(string: "ms-outlook://compose?to=\(toEmail)&subject=\(subjectEncoded)&body=\(bodyEncoded)")!
        let yahooMail = URL(string: "ymail://mail/compose?to=\(toEmail)&subject=\(subjectEncoded)&body=\(bodyEncoded)")!
        let sparkUrl = URL(string: "readdle-spark://compose?recipient=\(toEmail)&subject=\(subjectEncoded)&body=\(bodyEncoded)")!
        let defaultUrl = URL(string: "mailto:\(toEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)")!
        
        if UIApplication.shared.canOpenURL(gmailUrl as URL) {
            openMail(gmailUrl)
        } else if UIApplication.shared.canOpenURL(outlookUrl as URL) {
            openMail(outlookUrl)
        } else if UIApplication.shared.canOpenURL(yahooMail as URL) {
            openMail(yahooMail)
        } else if UIApplication.shared.canOpenURL(sparkUrl as URL) {
            openMail(sparkUrl)
        } else if UIApplication.shared.canOpenURL(defaultUrl as URL) {
            openMail(defaultUrl)
        }
    }
    
    private static func openMail(_ url: URL) {
        UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
    }
    
    static var alertChangeProfile = LibAlertController()
    public static func checkIsChangePerson() -> Bool {
        let isChangeProfile = Utils.getSetProfile()
        if !isChangeProfile {
            alertChangeProfile.dismiss(animated: false)
            alertChangeProfile = LibAlertController(title: "Set Profile".localized(), message: "You must set your profile to use this feature".localized(), preferredStyle: .alert)
            alertChangeProfile.addAction(UIAlertAction(title: "Cancel".localized(), style: .destructive, handler: nil))
            alertChangeProfile.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                guard let controller = APIS.getControllerSign() else { return }
                if let controller = controller as? SignUpSignIn {
                    controller.forceLogin = true
                } else if let controller = controller as? SignInOption {
                    controller.forceLogin = true
                }
                let navigationController = CustomNavigationController(rootViewController: controller)
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
                let rootVC = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
                if rootVC?.presentedViewController == nil {
                    rootVC?.present(navigationController, animated: true, completion: nil)
                } else {
                    rootVC?.presentedViewController?.present(navigationController, animated: true, completion: nil)
                }
            }))
            let rootVC = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
            if rootVC?.presentedViewController == nil {
                rootVC?.present(alertChangeProfile, animated: true, completion: nil)
            } else {
                rootVC?.presentedViewController?.present(alertChangeProfile, animated: true, completion: nil)
            }
            return false
        }
        return true
    }
    
    public static func showLoader(text: String = "Please wait...".localized()) {
        loadingAlert = LibAlertController(title: nil, message: text, preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()

        loadingAlert.view.addSubview(loadingIndicator)
        UIApplication.shared.visibleViewController?.present(loadingAlert, animated: true, completion: nil)
    }
    
    public static func hideLoader(completion: @escaping () -> ()) {
        loadingAlert.dismiss(animated: true, completion: completion)
    }
    
    private static var listDispatchGroups = [String: DispatchGroup]()
    private static var waitQueue = [String: TMessage]()
    private static let syncQueue = DispatchQueue(label: "io.nexilis.syncQueue")
    
    /// Whether a request sent now would actually leave the device.
    ///
    /// `write` drops the message and returns nil when this is false, but `writeAndWait` has no
    /// way of knowing that and waits its full timeout for an answer to a question nobody asked.
    /// Worth asking before a blocking round trip.
    public static var isLinkUp: Bool {
        return API.bInetConnAvailable() && API.nGetCLXConnState() != 0
    }

    /// Waits, briefly, for the link to come up.
    ///
    /// The moments right after launch or after a resume are exactly when a screen asks for its
    /// data and exactly when the socket is not up yet. A few seconds here turn a request that
    /// would have been thrown away into one that goes out.
    ///
    /// - Returns: whether the link came up within the time given. Call from a background queue.
    @discardableResult
    public static func waitForLink(upTo seconds: TimeInterval) -> Bool {
        if isLinkUp {
            return true
        }
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            Thread.sleep(forTimeInterval: 0.25)
            if isLinkUp {
                return true
            }
        }
        return false
    }

    public static func writeAndWait(message: TMessage, timeout: Int = 15 * 1000) -> TMessage? {
        if message.getStatus().isEmpty {
            return nil
        }

        var groupWait: DispatchGroup?

        syncQueue.sync {
            listDispatchGroups[message.getStatus()] = DispatchGroup()
            groupWait = listDispatchGroups[message.getStatus()]
            groupWait?.enter()
            waitQueue[message.getStatus()] = message
        }

        _ = write(message: message, timeout: timeout)

        if groupWait?.wait(timeout: .now() + .milliseconds(timeout)) == .timedOut {
            syncQueue.sync {
                waitQueue.removeValue(forKey: message.getStatus())
                listDispatchGroups.removeValue(forKey: message.getStatus())
                groupWait?.leave()
            }
            return nil
        }

        var response: TMessage?
        syncQueue.sync {
            listDispatchGroups.removeValue(forKey: message.getStatus())
            response = waitQueue.removeValue(forKey: message.getStatus())
        }
        return response
    }
    
    private static let incomingDataQueue = DispatchQueue(label: "com.nexilis.incomingData")
    private static let waitQueueLock = NSLock()

    static func incomingData(packetId: String, data: AnyObject) {
        // Semua incoming data diproses secara serial
        incomingDataQueue.async {
            let message = TMessage()
            
            if let d = data as? String {
                if !message.unpack(data: d) {
                    // handle WB data...
                    handleWhiteboardData(data: d)
                    return
                }
            } else if let d = data as? [UInt8] {
                guard message.unpack(bytes_data: d) else {
                    return
                }
            }
            
            // Sekarang aman karena di serial queue
            message.mBodies[CoreMessage_TMessageKey.PACKET_ID] = packetId
            
            waitQueueLock.lock()
            let waitEntry = waitQueue[message.getStatus()]
            waitQueueLock.unlock()
            
            if waitEntry != nil {
                if message.mBodies.keys.contains(CoreMessage_TMessageKey.ERRCOD) {
                    waitQueueLock.lock()
                    waitQueue[message.getStatus()] = message
                    let groupWait = listDispatchGroups[message.getStatus()]
                    waitQueueLock.unlock()
                    
                    groupWait?.leave()  // leave SETELAH unlock untuk hindari deadlock
                    return
                }
            }
            
            IncomingThread.default.addQueue(message: message)
        }
    }

    // Pisahkan whiteboard handler agar lebih clean
    private static func handleWhiteboardData(data: String) {
        guard data.hasPrefix("WB") else { return }
        let dataWB = data.components(separatedBy: "/")
        guard dataWB.count > 1 else { return }
        
        DispatchQueue.main.async {
            switch dataWB[1] {
            case "1":
                guard dataWB.count > 9 else { return }
                Nexilis.getWhiteboardDelegate()?.draw(
                    x: dataWB[2], y: dataWB[3],
                    w: dataWB[4], h: dataWB[5],
                    fc: dataWB[6], sw: dataWB[7],
                    xo: dataWB[8], yo: dataWB[9],
                    data: ""
                )
            case "2":
                guard dataWB.count > 2 else { return }
                Nexilis.getWhiteboardReceiver()?.incomingWB(roomId: dataWB[2])
            case "3":
                Nexilis.getWhiteboardDelegate()?.clear()
            case "88":
                guard dataWB.count > 2 else { return }
                Nexilis.getWhiteboardReceiver()?.cancel(roomId: dataWB[2])
            default:
                break
            }
        }
    }
    
    static func saveMessage(message: TMessage, withStatus: Bool = true, fromAPNS: Bool = false) {
//        print("save message \(message.toLogString())")
        guard let me = User.getMyPin() else {
            return
        }
        let message_id = message.getBody(key : CoreMessage_TMessageKey.MESSAGE_ID, default_value : "")
        guard !message_id.isEmpty else {
            if message.getBody(key: CoreMessage_TMessageKey.ATTACHMENT_FLAG) == "61" {
                let nameReq = message.getBody(key: CoreMessage_TMessageKey.TAG_SUBACTIVITY)
                let nameFpin = message.getBody(key: CoreMessage_TMessageKey.TAG_CLIENT)
                var messageExist = false
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message_id from MESSAGE where attachment_flag = '61' and blog_id = '\(nameFpin)'"), cursor.next() {
                        messageExist = true
                        cursor.close()
                    }
                })
                if !messageExist {
                    Nexilis.saveMessageBot(textMessage: "*\(nameReq.trimmingCharacters(in: .whitespaces))*" + "~" + "has requested to be your friend", blog_id: nameFpin, attachment_type: "61")
                    self.makeNotifRequestFriend(message: message)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                }
            }
            return
        }
        let f_pin = message.getBody(key : CoreMessage_TMessageKey.F_PIN, default_value : "")
        guard !f_pin.isEmpty else {
            return
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var messageExist = false
                var lastEditedMessageExist: Int64 = 0
                var lastLockedMessageExist = "0"
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select last_edited, lock from MESSAGE where message_id = '\(message_id)'"), cursor.next() {
                    messageExist = true
                    lastEditedMessageExist = cursor.longLongInt(forColumnIndex: 0)
                    lastLockedMessageExist = cursor.string(forColumnIndex: 1) ?? "0"
                    cursor.close()
                }
                let l_pin = message.getBody(key : CoreMessage_TMessageKey.L_PIN, default_value : "")
                let scope = message.getBody(key : CoreMessage_TMessageKey.MESSAGE_SCOPE_ID, default_value : MessageScope.WHISPER)
                let status = message.getBody(key : CoreMessage_TMessageKey.STATUS, default_value : "")
                let chat_id = message.getBody(key : CoreMessage_TMessageKey.CHAT_ID, default_value : "")
                let broadcast_flag = message.getBody(key: CoreMessage_TMessageKey.BROADCAST_FLAG, default_value: "0")
                let is_call_center = message.getBody(key: CoreMessage_TMessageKey.IS_CALL_CENTER, default_value: "0")
                let call_center_id = message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID, default_value: "")
                let last_edited = message.getBodyAsLong(key: CoreMessage_TMessageKey.LAST_EDIT, default_value: 0)
                let is_secret = message.getBodyAsLong(key: CoreMessage_TMessageKey.IS_SECRET, default_value: 0)
                let is_delete_retention = message.getBodyAsLong(key: CoreMessage_TMessageKey.IS_DELETED_RETENTION, default_value: 0)
                let is_forwarded_message = message.getBodyAsLong(key: CoreMessage_TMessageKey.IS_FORWARDED_MESSAGE, default_value: 0)
                let opposite_pin = message.getBody(key: CoreMessage_TMessageKey.OPPOSITE_PIN, default_value: "")
                let is_bot = message.getBodyAsInteger(key: CoreMessage_TMessageKey.IS_BOT, default_value: 0)
                //print("prepare save db")
                if !messageExist || (lastEditedMessageExist == 0 && lastLockedMessageExist != "1") {
                    do {
                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                            "message_id" : message_id,
                            "f_pin" : f_pin,
                            "f_display_name" : message.getBody(key : CoreMessage_TMessageKey.F_DISPLAY_NAME, default_value : ""),
                            "l_pin" : l_pin,
                            "l_user_id" : message.getBody(key : CoreMessage_TMessageKey.L_USER_ID, default_value : ""),
                            "message_scope_id" : scope,
                            "server_date" : message.getBody(key: CoreMessage_TMessageKey.SERVER_DATE, default_value : String(Date().currentTimeMillis())),
                            "status" : status,
                            "message_text" : message.getBody(key : CoreMessage_TMessageKey.MESSAGE_TEXT, default_value : "").toNormalString(),
                            "audio_id" : message.getBody(key : CoreMessage_TMessageKey.AUDIO_ID, default_value : ""),
                            "video_id" : message.getBody(key : CoreMessage_TMessageKey.VIDEO_ID, default_value : ""),
                            "image_id" : message.getBody(key : CoreMessage_TMessageKey.IMAGE_ID, default_value : ""),
                            "file_id" : message.getBody(key : CoreMessage_TMessageKey.FILE_ID, default_value : ""),
                            "gif_id" : message.getBody(key : CoreMessage_TMessageKey.GIF_ID, default_value : ""),
                            "thumb_id" : message.getBody(key : CoreMessage_TMessageKey.THUMB_ID, default_value : ""),
                            "opposite_pin" : message.getBody(key : CoreMessage_TMessageKey.OPPOSITE_PIN, default_value : ""),
                            "format" : message.getBody(key : CoreMessage_TMessageKey.FORMAT, default_value : ""),
                            "blog_id" : message.getBody(key : CoreMessage_TMessageKey.BLOG_ID, default_value : ""),
                            "read_receipts" : message.getBody(key: CoreMessage_TMessageKey.READ_RECEIPTS, default_value:  "0"),
                            "chat_id" : chat_id,
                            "account_type" : message.getBody(key : CoreMessage_TMessageKey.BUSINESS_CATEGORY, default_value : "1"),
                            "credential" : message.getBody(key : CoreMessage_TMessageKey.CREDENTIAL, default_value : ""),
                            "reff_id" : message.getBody(key : CoreMessage_TMessageKey.REF_ID, default_value : ""),
                            "message_large_text" : message.getBody(key : CoreMessage_TMessageKey.BODY, default_value : "").toNormalString(),
                            "attachment_flag" : message.getBody(key: CoreMessage_TMessageKey.ATTACHMENT_FLAG, default_value:  "0"),
                            "local_timestamp" : message.getBody(key: CoreMessage_TMessageKey.LOCAL_TIMESTAMP, default_value : String(Date().currentTimeMillis())),
                            "broadcast_flag" : broadcast_flag,
                            "is_call_center" : is_call_center,
                            "ex_book" : message.getBody(key: CoreMessage_TMessageKey.EX_BOOK, default_value:  "0"),
                            "ex_book1" : message.getBody(key: CoreMessage_TMessageKey.EX_BOOK1, default_value:  "0"),
                            "call_center_id" : call_center_id,
                            "last_edited" : last_edited,
                            "is_secret" : is_secret,
                            "is_deleted_retention" : is_delete_retention,
                            "is_forwarded_message" : is_forwarded_message,
                            "attachment_speciality" : message.getBody(key: CoreMessage_TMessageKey.ATTACHMENT_SPECIALITY, default_value:  ""),
                            "is_bot" : is_bot
                        ], replace: true)
                    } catch {
                        print("ERROR: \(error)")
                        rollback.pointee = true
                        //print(error)
                    }
                }
                
                if withStatus {
                    do {
                        if scope == MessageScope.GROUP {
                            for pin in getGroupMembers(fmdb: fmdb, l_pin: l_pin) {
                                if f_pin == pin { continue }
//                                print("REPLACE STATUS MESSAGE: \(message_id) <><> \(status) <><> \(pin)")
                                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                    "message_id" : message_id,
                                    "status" : status,
                                    "f_pin" : pin,
                                    "last_update" : Date().currentTimeMillis()
                                ], replace: true)
                            }
                        } else {
                            _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                "message_id" : message_id,
                                "status" : status,
                                "f_pin" : l_pin,
                                "last_update" : Date().currentTimeMillis()
                            ], replace: true)
                        }
                    } catch {
                        rollback.pointee = true
                        //print(error)
                    }
                }
                var pin = opposite_pin
                if pin.isEmpty {
                    if scope == MessageScope.GROUP {
                        pin = chat_id.isEmpty ? l_pin : chat_id
                    } else {
                        pin = f_pin
                    }
                }
                if pin == me {
                    pin = l_pin != me ? l_pin : f_pin
                }
                var counter : Int? = nil
                if !withStatus {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select counter from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                        counter = Int(cursor.int(forColumnIndex: 0))
                        if !messageExist {
                            counter! += 1
                        }
                        cursor.close()
                        //print("select db message summary")
                    }
                    if counter == nil {
                        counter = 1
                        //print("set counter message summary")
                    }
                }
                if is_call_center == "0" {
                    do {
                        var queryGetLastMessageId = "SELECT message_id FROM MESSAGE where (f_pin = '\(pin)' OR l_pin = '\(pin)') AND message_scope_id = '\(MessageScope.WHISPER)' order by server_date desc LIMIT 1"
                        if scope == MessageScope.GROUP {
                            queryGetLastMessageId = "SELECT message_id FROM MESSAGE where l_pin = '\(chat_id.isEmpty ? pin : l_pin)' AND chat_id = '\(chat_id)' AND message_scope_id = '\(MessageScope.GROUP)' order by server_date desc LIMIT 1"
                        } else if scope == MessageScope.GPT_CHATBOT {
                            queryGetLastMessageId = "SELECT message_id FROM MESSAGE where (f_pin = '\(pin)' OR l_pin = '\(pin)') AND message_scope_id = '\(MessageScope.GPT_CHATBOT)' order by server_date desc LIMIT 1"
                        }
                        var messageId = ""
                        var pinned = 0
                        var archived = 0
                        if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: queryGetLastMessageId), cursorData.next() {
                            messageId = cursorData.string(forColumnIndex: 0) ?? ""
                            cursorData.close()
                        }
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select pinned, archived from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                            pinned = Int(cursor.int(forColumnIndex: 0))
                            archived = Int(cursor.int(forColumnIndex: 1))
                        }
                        if !messageId.isEmpty {
                            _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                                "l_pin" : pin,
                                "message_id" : messageId,
                                "counter" : counter ?? 0,
                                "pinned" : pinned,
                                "archived" : archived
                            ], replace: true)
                        }
                    } catch {
                        rollback.pointee = true
                        //print(error)
                    }
                }
                if !withStatus && (!messageExist || last_edited != 0) {
                    DispatchQueue.main.async {
                        // Fix: the chat list has to hear about a message however it got here.
                        // The delegate below is the only thing that used to announce an arrival,
                        // and it is deliberately silent for messages pulled in for a push
                        // (fromAPNS) - which are precisely the ones the list is missing when the
                        // app is opened from the launcher. It also needs a delegate to have been
                        // registered, so anything that landed during the backlog burst before
                        // the app's UI was up announced itself to nobody. Either way the row sat
                        // there stale until something unrelated happened to refresh it.
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                        // Unread went up; the icon should say so. Debounced, because a backlog
                        // arrives one message at a time.
                        APIS.refreshApplicationBadgeSoon()
                        if !fromAPNS, let delegate = Nexilis.shared.messageDelegate, Utils.getSetProfile() {
                            message.mBodies[CoreMessage_TMessageKey.MESSAGE_TEXT] = message.getBody(key : CoreMessage_TMessageKey.MESSAGE_TEXT, default_value : "").toNormalString()
                            delegate.onReceive(message: message)
                        }
                    }
                }
                //print("insert db message summary \(message_id)")
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        
    }
    
    private static func makeNotifRequestFriend(message: TMessage) {
        let nameReq = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_TEXT)
        let profile = message.getBody(key: CoreMessage_TMessageKey.THUMB_ID)
        DispatchQueue.main.async {
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            let inEditorPersonal: String? = SecureUserDefaults.shared.value(forKey: "inEditorPersonal") ?? nil
            if !onGoingCC.isEmpty {
                return
            }
            if inEditorPersonal == "-999"{
                return
            }
            let container = UIView()
            container.backgroundColor = .gray
            let profileImage = UIImageView()
            profileImage.frame.size = CGSize(width: 60, height: 60)
            container.addSubview(profileImage)
            profileImage.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                profileImage.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8.0),
                profileImage.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                profileImage.widthAnchor.constraint(equalToConstant: 60),
                profileImage.heightAnchor.constraint(equalToConstant: 60),
            ])
            
            let title = UILabel()
            container.addSubview(title)
            title.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                title.leadingAnchor.constraint(equalTo: profileImage.trailingAnchor, constant: 8.0),
                title.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                title.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8.0)
            ])
            title.font = UIFont.systemFont(ofSize: 14)
            title.text = nameReq.trimmingCharacters(in: .whitespaces) + " " + "has requested to be your friend".localized()
            title.textColor = .white
            title.numberOfLines = 0
            
            if Nexilis.shared.floating != nil {
                Nexilis.shared.floating.dismiss()
            }
            Nexilis.shared.floating = FloatingNotificationBanner(customView: container)
            Nexilis.shared.floating.bannerHeight = UIScreen.main.bounds.height / 6 - 10
            Nexilis.shared.floating.transparency = 0.9
            Nexilis.shared.floating.onTap = {
                let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                editorPersonalVC.hidesBottomBarWhenPushed = true
                editorPersonalVC.unique_l_pin = "-999"
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
            }
            
            if profile != "" {
                profileImage.circle()
                do {
                    let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    let file = documentDir.appendingPathComponent(profile)
                    if FileManager().fileExists(atPath: file.path) {
                        profileImage.image = UIImage(contentsOfFile: file.path)
                        profileImage.backgroundColor = .clear
                    } else if FileEncryption.shared.isSecureExists(filename: profile) {
                        do {
                            if var data = try FileEncryption.shared.readSecure(filename: profile) {
                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                if dataDecrypt != nil {
                                    data = dataDecrypt!
                                }
                                profileImage.image = UIImage(data: data)
                                profileImage.backgroundColor = .clear
                            }
                        } catch {
                            
                        }
                    } else {
                        Download().startHTTP(forKey: profile) { (name, progress) in
                            guard progress == 100 else {
                                return
                            }
                            
                            DispatchQueue.main.async {
                                if FileEncryption.shared.isSecureExists(filename: profile) {
                                    do {
                                        if var data = try FileEncryption.shared.readSecure(filename: profile) {
                                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                            if dataDecrypt != nil {
                                                data = dataDecrypt!
                                            }
                                            profileImage.image = UIImage(data: data)
                                            profileImage.backgroundColor = .clear
                                        }
                                    } catch {
                                        
                                    }
                                }
                                Nexilis.shared.floating.show(queuePosition: .front, bannerPosition: .top, queue: NotificationBannerQueue(maxBannersOnScreenSimultaneously: 1), on: nil, edgeInsets: UIEdgeInsets(top: 8.0, left: 8.0, bottom: 0, right: 8.0), cornerRadius: 8.0, shadowColor: .clear, shadowOpacity: .zero, shadowBlurRadius: .zero, shadowCornerRadius: .zero, shadowOffset: .zero, shadowEdgeInsets: nil)
                                return
                            }
                        }
                    }
                } catch {}
                profileImage.contentMode = .scaleAspectFill
            } else {
                profileImage.circle()
                profileImage.image = UIImage(systemName: "person")
                profileImage.contentMode = .scaleAspectFit
                profileImage.backgroundColor = .lightGray
                profileImage.tintColor = .white
            }
            Nexilis.shared.floating.show(queuePosition: .front, bannerPosition: .top, queue: NotificationBannerQueue(maxBannersOnScreenSimultaneously: 1), on: nil, edgeInsets: UIEdgeInsets(top: 8.0, left: 8.0, bottom: 0, right: 8.0), cornerRadius: 8.0, shadowColor: .clear, shadowOpacity: .zero, shadowBlurRadius: .zero, shadowCornerRadius: .zero, shadowOffset: .zero, shadowEdgeInsets: nil)
        }
    }
    
    public static func saveMessageBot(textMessage: String, blog_id: String, attachment_type:String)->Void{
        guard let me = User.getMyPin() else {
            return
        }
        
        var user_id:String? = ""
        let message_id = me + CoreMessage_TMessageUtil.getTID()
        
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select user_id from BUDDY where f_pin = '\(me)'"), cursor.next() {
                    user_id = cursor.string(forColumnIndex: 0)
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                    "message_id" : message_id ,
                    "f_pin" : "-999",
                    "f_display_name" : "Bot",
                    "l_pin" : me,
                    "l_user_id" : String(user_id!),
                    "message_scope_id" : MessageScope.WHISPER,
                    "server_date" : String(Date().currentTimeMillis()),
                    "status" : "4",
                    "message_text" : textMessage,
                    "audio_id" : "",
                    "video_id" : "",
                    "image_id" : "",
                    "file_id" : "",
                    "thumb_id" : "",
                    "opposite_pin" : "",
                    "format" : "",
                    "blog_id" : blog_id,
                    "read_receipts" : "0",
                    "chat_id" : "",
                    "account_type" : "1",
                    "credential" :"",
                    "reff_id" : "",
                    "message_large_text" : "",
                    "attachment_flag" : attachment_type,
                    "local_timestamp" : String(Date().currentTimeMillis())
                ], replace: true)
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        let pin = "-999"
        var counter : Int? = nil
        var pinned = 0
        var archived = 0
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select counter, pinned, archived from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                    counter = Int(cursor.int(forColumnIndex: 0))
                    pinned = Int(cursor.int(forColumnIndex: 1))
                    archived = Int(cursor.int(forColumnIndex: 2))
                    counter! += 1
                    cursor.close()
                    //print("select db message summary")
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        if counter == nil {
            counter = 1
            //print("set counter message summary")
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                    "l_pin" : pin,
                    "message_id" : message_id,
                    "counter" : counter!,
                    "pinned" : pinned,
                    "archived" : archived
                ], replace: true)
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        //print("insert db message summary \(message_id)")
    }
    
    public static func saveMessageNotif(textMessage: String, fPin: String, lPin: String, chatId: String, scopeId: String, fmdb: FMDatabase? = nil) -> String {
        guard let me = User.getMyPin() else {
            return ""
        }
        let dataFpin = User.getData(pin: fPin, lPin: lPin, fmdb: fmdb)
        let dataLpin = User.getData(pin: lPin, fmdb: fmdb)
        let message_id = "NTFPIN_" + CoreMessage_TMessageUtil.getTID()
        if fmdb == nil {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                        "message_id" : message_id,
                        "f_pin" : fPin,
                        "f_display_name" : dataFpin != nil ? dataFpin!.fullName : "",
                        "l_pin" : lPin,
                        "l_user_id" : dataLpin != nil ? dataLpin!.pin : "",
                        "message_scope_id" : scopeId,
                        "server_date" : Date().currentTimeMillis(),
                        "status" : "4",
                        "message_text" : textMessage,
                        "audio_id" : "",
                        "video_id" : "",
                        "image_id" : "",
                        "file_id" : "",
                        "thumb_id" : "",
                        "opposite_pin" : "",
                        "format" : "",
                        "blog_id" : "",
                        "read_receipts" : "0",
                        "chat_id" : chatId,
                        "account_type" : "1",
                        "credential" :"",
                        "reff_id" : "",
                        "message_large_text" : "",
                        "attachment_flag" : "",
                        "local_timestamp" : ""
                    ], replace: true)
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        } else {
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb!, table: "MESSAGE", cvalues: [
                    "message_id" : message_id,
                    "f_pin" : fPin,
                    "f_display_name" : dataFpin != nil ? dataFpin!.fullName : "",
                    "l_pin" : lPin,
                    "l_user_id" : dataLpin != nil ? dataLpin!.pin : "",
                    "message_scope_id" : scopeId,
                    "server_date" : Date().currentTimeMillis(),
                    "status" : "4",
                    "message_text" : textMessage,
                    "audio_id" : "",
                    "video_id" : "",
                    "image_id" : "",
                    "file_id" : "",
                    "thumb_id" : "",
                    "opposite_pin" : "",
                    "format" : "",
                    "blog_id" : "",
                    "read_receipts" : "0",
                    "chat_id" : chatId,
                    "account_type" : "1",
                    "credential" :"",
                    "reff_id" : "",
                    "message_large_text" : "",
                    "attachment_flag" : "",
                    "local_timestamp" : ""
                ], replace: true)
            } catch {
                print("Access database error: \(error.localizedDescription)")
            }
        }
        var pin = lPin == me ? fPin : lPin
        if !chatId.isEmpty {
            pin = chatId
        }
        var pinned = 0
        var archived = 0
        if fmdb == nil {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select pinned, archived from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                        pinned = Int(cursor.int(forColumnIndex: 0))
                        archived = Int(cursor.int(forColumnIndex: 1))
                    }
                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                        "l_pin" : pin,
                        "message_id" : message_id,
                        "counter" : 0,
                        "pinned" : pinned,
                        "archived" : archived
                    ], replace: true)
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        } else {
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb!, query: "select pinned, archived from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                    pinned = Int(cursor.int(forColumnIndex: 0))
                    archived = Int(cursor.int(forColumnIndex: 1))
                }
                _ = try Database.shared.insertRecord(fmdb: fmdb!, table: "MESSAGE_SUMMARY", cvalues: [
                    "l_pin" : pin,
                    "message_id" : message_id,
                    "counter" : 0,
                    "pinned" : pinned,
                    "archived" : archived
                ], replace: true)
            } catch {
                print("Access database error: \(error.localizedDescription)")
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        return message_id
    }
    
    public static func saveMessageCall(idCall: String, textMessage: String, fPin: String, lPin: String, timeCall: String, attachment_type:String) {
        guard let me = User.getMyPin() else {
            return
        }
        let dataFpin = User.getDataCanNil(pin: fPin)
        let dataLpin = User.getDataCanNil(pin: lPin)
        var messageExist = false
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select server_date from MESSAGE where server_date = '\(timeCall)'"), cursor.next() {
                messageExist = true
                cursor.close()
            }
        })
        if messageExist {
            return
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                    "message_id" : idCall ,
                    "f_pin" : fPin,
                    "f_display_name" : dataFpin != nil ? dataFpin!.fullName : "",
                    "l_pin" : lPin,
                    "l_user_id" : dataLpin != nil ? dataLpin!.pin : "",
                    "message_scope_id" : attachment_type,
                    "server_date" : timeCall,
                    "status" : "4",
                    "message_text" : textMessage,
                    "audio_id" : "",
                    "video_id" : "",
                    "image_id" : "",
                    "file_id" : "",
                    "thumb_id" : "",
                    "opposite_pin" : "",
                    "format" : "",
                    "blog_id" : "",
                    "read_receipts" : "0",
                    "chat_id" : "",
                    "account_type" : "1",
                    "credential" :"",
                    "reff_id" : "",
                    "message_large_text" : "",
                    "attachment_flag" : attachment_type,
                    "local_timestamp" : timeCall
                ], replace: true)
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        let pin = lPin == me ? fPin : lPin
        var pinned = 0
        var archived = 0
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select pinned, archived from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                    pinned = Int(cursor.int(forColumnIndex: 0))
                    archived = Int(cursor.int(forColumnIndex: 1))
                }
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                    "l_pin" : pin,
                    "message_id" : idCall,
                    "counter" : 0,
                    "pinned" : pinned,
                    "archived" : archived
                ], replace: true)
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["message_id"] = idCall
        dataMessage["pin"] = pin
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshCallLog"), object: nil, userInfo: dataMessage)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
    }
    
    static func updateMessageStatus(message: TMessage) -> Void {
        let message_id = message.getBody(key : CoreMessage_TMessageKey.MESSAGE_ID, default_value : "")
        guard !message_id.isEmpty else {
            return
        }
        let status = message.getBody(key : CoreMessage_TMessageKey.STATUS, default_value : "")
        let latitude = message.getBody(key : CoreMessage_TMessageKey.LATITUDE, default_value : "")
        let longitude = message.getBody(key : CoreMessage_TMessageKey.LONGITUDE, default_value : "")
        let desc = message.getBody(key : CoreMessage_TMessageKey.DESCRIPTION, default_value : "")
        let time = message.getBody(key : CoreMessage_TMessageKey.SERVER_DATE, default_value : String(Date().currentTimeMillis()))
        let lastUpdate = message.getBody(key : CoreMessage_TMessageKey.LAST_UPDATE, default_value : String(Date().currentTimeMillis()))
        guard !status.isEmpty else {
            return
        }
        let l_pin = message.getBody(key : CoreMessage_TMessageKey.L_PIN, default_value : "")
        guard !l_pin.isEmpty else {
            return
        }
//        print("COMING STATUS: \(message_id) <><> \(status) <><> \(l_pin) <><> \(time) <><> \(lastUpdate)")
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if message_id.starts(with: "-1") || message_id.starts(with: "-2") {
                    for s in message_id.split(separator: ",") {
                        let t = s.trimmingCharacters(in: .whitespaces)
                        if t == "-1" || t == "-2" {
                            continue
                        }
                        if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE_STATUS where message_id = '\(t)' and f_pin = '\(l_pin)'"), cursorStatus.next() {
                            let lastStatus = cursorStatus.int(forColumnIndex: 0)
                            if lastStatus < Int(status)! {
                                if status == "3" {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                        "status" : status,
                                        "longitude" : longitude,
                                        "latitude" : latitude,
                                        "location" : desc,
                                        "time_delivered" : time,
                                        "last_update" : lastUpdate], _where: "message_id = '\(t)' and f_pin = '\(l_pin)'")
                                } else if status == "4" {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                        "status" : status,
                                        "time_read" : time,
                                        "longitude" : longitude,
                                        "latitude" : latitude,
                                        "location" : desc,
                                        "last_update" : lastUpdate], _where: "message_id = '\(t)' and f_pin = '\(l_pin)'")
                                } else if status == "8" {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                        "status" : status,
                                        "time_ack" : time,
                                        "longitude" : longitude,
                                        "latitude" : latitude,
                                        "location" : desc,
                                        "last_update" : lastUpdate], _where: "message_id = '\(t)' and f_pin = '\(l_pin)'")
                                } else {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                        "status" : status,
                                        "longitude" : longitude,
                                        "latitude" : latitude,
                                        "location" : desc,
                                        "last_update" : lastUpdate], _where: "message_id = '\(t)' and f_pin = '\(l_pin)'")
                                }
                            }
                            cursorStatus.close()
                        } else {
                            if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE_STATUS where message_id = '\(t)'"), cursorStatus.next() {
                                let lastStatus = cursorStatus.int(forColumnIndex: 0)
                                if lastStatus < Int(status)! {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                        "status" : status,
                                        "time_ack" : time,
                                        "longitude" : longitude,
                                        "latitude" : latitude,
                                        "location" : desc,
                                        "last_update" : lastUpdate], _where: "message_id = '\(t)'")
                                }
                                cursorStatus.close()
                            }
                        }
                    }
                } else {
                    if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE_STATUS where message_id = '\(message_id)' and f_pin = '\(l_pin)'"), cursorStatus.next() {
                        let lastStatus = cursorStatus.int(forColumnIndex: 0)
                        if lastStatus < Int(status)! {
                            if status == "3" {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                    "status" : status,
                                    "time_delivered" : time,
                                    "longitude" : longitude,
                                    "latitude" : latitude,
                                    "location" : desc,
                                    "last_update" : lastUpdate], _where: "message_id = '\(message_id)' and f_pin = '\(l_pin)'")
                            } else if status == "4" {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                    "status" : status,
                                    "time_read" : time,
                                    "longitude" : longitude,
                                    "latitude" : latitude,
                                    "location" : desc,
                                    "last_update" : lastUpdate], _where: "message_id = '\(message_id)' and f_pin = '\(l_pin)'")
                            } else if status == "8" {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                    "status" : status,
                                    "time_ack" : time,
                                    "longitude" : longitude,
                                    "latitude" : latitude,
                                    "location" : desc,
                                    "last_update" : lastUpdate], _where: "message_id = '\(message_id)' and f_pin = '\(l_pin)'")
                            } else {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                    "status" : status,
                                    "longitude" : longitude,
                                    "latitude" : latitude,
                                    "location" : desc,
                                    "last_update" : lastUpdate], _where: "message_id = '\(message_id)' and f_pin = '\(l_pin)'")
                            }
                        }
                        cursorStatus.close()
                    } else if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE_STATUS where message_id = '\(message_id)'"), cursorStatus.next() {
                        let lastStatus = cursorStatus.int(forColumnIndex: 0)
                        if lastStatus < Int(status)! {
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                "status" : status,
                                "time_ack" : time,
                                "longitude" : longitude,
                                "latitude" : latitude,
                                "location" : desc,
                                "last_update" : lastUpdate], _where: "message_id = '\(message_id)'")
                        }
                        cursorStatus.close()
                    }
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    static func getGroupMembers(fmdb: FMDatabase, l_pin: String) -> [String] {
        var result = [String]()
        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin from GROUPZ_MEMBER where group_id = '\(l_pin)'") {
            while cursor.next() {
                if let value = cursor.string(forColumnIndex: 0) {
                    result.append(value)
                }
            }
            cursor.close()
        }
        return result
    }
    
    static func getVideoThumbnail(name: String, completion: @escaping (Bool)->()) {
        DispatchQueue.global().async {
            do {
                let fileManager = FileManager.default
                let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileDir = documentDir.appendingPathComponent(name)
                let path = fileDir.path
                if FileManager.default.fileExists(atPath: path) {
                    let asset = AVAsset(url: URL(fileURLWithPath: path))
                    let avAssetImageGenerator = AVAssetImageGenerator(asset: asset)
                    avAssetImageGenerator.appliesPreferredTrackTransform = true
                    let thumnailTime = CMTimeMake(value: 2, timescale: 1)
                    let thumbImage = UIImage(cgImage: try avAssetImageGenerator.copyCGImage(at: thumnailTime, actualTime: nil))
                    guard let data = thumbImage.jpegData(compressionQuality: 1.0) else {
                        completion(false)
                        return
                    }
                    let thumbFileDir = documentDir.appendingPathComponent("THUMB_" + name)
                    try data.write(to: thumbFileDir)
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                //print(error)
            }
        }
    }
    
    static func resizedImage(at url: URL, for size: CGSize) -> UIImage? {
        var image : UIImage?
        if FileManager.default.fileExists(atPath: url.path){
            image = UIImage(contentsOfFile: url.path)
        }
        else if FileEncryption.shared.isSecureExists(filename: url.lastPathComponent) {
            do {
                if var imageData = try FileEncryption.shared.readSecure(filename: url.lastPathComponent) {
                    let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: imageData)
                    if dataDecrypt != nil {
                        imageData = dataDecrypt!
                    }
                    image = UIImage(data: imageData)
                }
            }
            catch {
                
            }
        }
        if image == nil {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image!.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    static func initFollowing() -> Void {
        if let me = User.getMyPin() {
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getListFollowing(l_pin: me)) {
                let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                if !data.isEmpty {
                    if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                for json in jsonArray {
                                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "FOLLOW", cvalues: [
                                        "f_pin" : CoreMessage_TMessageUtil.getString(json: json, key: "pin")
                                    ], replace: true)
                                }
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                }
            }
        }
    }
    
//    do {
//        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", cvalues: [
//            "type" : "1",
//            "title" : displayName,
//            "time" : timeStart,
//            "f_pin" : f_pin,
//            "data" : dataCC,
//            "time_end" : date,
//            "complaint_id" : complaint_id.isEmpty ? "C\(date)" : complaint_id,
//            "members" : "",
//            "requester": ""
//        ], replace: true)
//        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "PREFS", cvalues: [
//            "key" : "CC:\(f_pin)",
//            "value" : status,
//        ], replace: true)
//        ret = true
//    } catch {
//        rollback.pointee = true
//        //print(error)
//    }
    
    private static var uploadQueue = DispatchQueue(label: "UPLOAD_DICT", attributes: .concurrent)
    
    private static var UPLOAD_DICT = [String: Network]()
    
    static func removeUploadFile(forKey: String) -> Network? {
        var _result: Network? = nil
        uploadQueue.sync {
            _result = self.UPLOAD_DICT.removeValue(forKey: forKey)
        }
        return _result
    }
    
    static func putUploadFile(forKey: String, uploader: Network) {
        uploadQueue.async (flags: .barrier) {
            self.UPLOAD_DICT[forKey] = uploader
        }
    }
    
    static func getUploadFile(forKey: String) -> Network? {
        var _result: Network? = nil
        uploadQueue.sync {
            _result = self.UPLOAD_DICT[forKey]
        }
        return _result
    }
    
    private static var downloadQueue = DispatchQueue(label: "DOWNLOAD_DICT", attributes: .concurrent)
    
    private static var DOWNLOAD_DICT = [String:Download]()
    
    static func addDownload(forKey : String, download: Download){
        downloadQueue.async (flags: .barrier) {
            self.DOWNLOAD_DICT[forKey] = download
        }
    }
    
    static func getDownload(forKey: String) -> Download? {
        var _result: Download? = nil
        downloadQueue.sync {
            _result = self.DOWNLOAD_DICT[forKey]
        }
        return _result
    }
    
    static func removeDownload(forKey: String) -> Download? {
        var _result: Download? = nil
        downloadQueue.sync {
            _result = self.DOWNLOAD_DICT.removeValue(forKey: forKey)
        }
        return _result
    }
    
    static func writeImageToFile(data: Data, fileName: String){
        guard let directory = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).last else {
            return
        }
        let fileURL = directory.appendingPathComponent("\(fileName)")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                //print("Can't open file to write")
            }
        } else {
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                //print("Unable to write in new file")
            }
        }
    }
    
    static func writeVideoToFile(data: Data, fileName: String){
        guard let directory = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).last else {
            return
        }
        let fileURL = directory.appendingPathComponent("\(fileName)")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                //print("Can't open file to write")
            }
        } else {
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                //print("Unable to write in new file")
            }
        }
    }
    
    static func writeDocumentsToFile(data: Data, fileName: String){
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            return
        }
        let fileURL = directory.appendingPathComponent("\(fileName)")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                //print("Can't open file to write")
            }
        } else {
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                //print("Unable to write in new file")
            }
        }
    }
    
    public static func checkMicPermission() -> Bool {
        var permissionCheck: Bool = false

        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            permissionCheck = true
        case .denied:
            permissionCheck = false
        case .undetermined:
            Nexilis.dispatch = DispatchGroup()
            Nexilis.dispatch?.enter()
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                if granted {
                    permissionCheck = true
                } else {
                    permissionCheck = false
                }
                if let dispatch = Nexilis.dispatch {
                    dispatch.leave()
                }
            })
            Nexilis.dispatch?.wait()
            Nexilis.dispatch = nil
        default:
            break
        }

        return permissionCheck
    }
    
    public static func checkCameraPermission() -> Int {
        var permissionCheck: Int = -1
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            permissionCheck = 1
        } else if AVCaptureDevice.authorizationStatus(for: .video) ==  .denied {
            permissionCheck = 0
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) -> Void in
               
            })
        }
        return permissionCheck
    }
    
    public static func disclaimerConsent(
        isMic: Bool = true,
        isCamera: Bool = true,
        completion: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(
            title: "Disclaimer and Consent".localized(),
            message: isMic && isCamera
                ? "does not store, share, or assign your camera and microphone input to third parties under any circumstances.".localized()
                : isMic
                    ? "does not store, share, or assign your microphone input to third parties under any circumstances.".localized()
                    : "does not store, share, or assign your camera input to third parties under any circumstances.".localized(),
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: "Accept".localized(), style: .default) { _ in
            if isMic && isCamera {
                Utils.setAcceptDisclaimerConsentMic(value: true)
                Utils.setAcceptDisclaimerConsentCamera(value: true)
            } else if isMic {
                Utils.setAcceptDisclaimerConsentMic(value: true)
            } else {
                Utils.setAcceptDisclaimerConsentCamera(value: true)
            }
            completion(true)
        }

        let cancelAction = UIAlertAction(title: "Decline".localized(), style: .cancel) { _ in
            completion(false)
        }

        alert.addAction(cancelAction)
        alert.addAction(okAction)

        if let nav = UIApplication.shared.visibleViewController?.navigationController {
            nav.present(alert, animated: true)
        } else {
            UIApplication.shared.visibleViewController?.present(alert, animated: true)
        }
    }
    
//    public static func startTimer(){
//        broadcastTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: {_ in
//            if(!openBroadcast && !broadcastList.isEmpty){
//                openBroadcast = true
//                let m = broadcastList.removeFirst()
//                //print("broadcast show: \(m)")
//                DispatchQueue.main.async {
//                    Nexilis.shared.showBroadcastMessage(m: m)
//                }
//            }
//        })
//    }
    public static func debugBroadcast(){
        if(Utils.getDebugBC() != nil) {
            let m = Utils.getDebugBC()
            Nexilis.shared.showBroadcastMessage(m: m!)
        }
    }
    
    /*
     * Delegate
     */
    
    weak open var loginDelegate: LoginDelegate?
    
    weak open var messageDelegate: MessageDelegate?
    
    weak open var groupDelegate: GroupDelegate?
    
    weak open var callDelegate: CallDelegate?
    
    weak open var streamingDelagate: LiveStreamingDelegate?
    
    weak open var seminarDelegate: SeminarDelegate?
    
    weak open var personInfoDelegate: PersonInfoDelegate?
    
    weak open var screenSharingDelegate: ScreenSharingDelegate?
    
    weak open var commentDelegate: CommentDelegate?
    
    weak open var uploadDelegate: UploadDelegate?
    
    weak open var timelineDelegate: TimelineDelegate?
    
    weak open var connectionDelegate: ConnectionDelegate?
    
    var floating: FloatingNotificationBanner!
    
    var stateUnfriend = ""
    
}

struct LibFontName {
    static let regular = "Poppins-Regular"
    static let bold = "Poppins-SemiBold"
    static let italic = "Poppins-Italic"
    static let medium = "Poppins-Medium"
    static let boldItalic = "Poppins-SemiBoldItalic"
}

extension UIFontDescriptor.AttributeName {
    static let nsctFontUIUsage = UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")
}

extension UIFont {
    static var isOverrided: Bool = false
    static let FONT_SELECT = 0

    @objc class func libSystemFont(ofSize size: CGFloat) -> UIFont? {
        if UIFont(name: LibFontName.regular, size: size) == nil {
            jbs_registerFont(withFilenameString: LibFontName.regular)
        }
        return UIFont(name: LibFontName.regular, size: size)
    }
    
    @objc class func libSystemFontWeight(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont? {
        if weight == .medium {
            if UIFont(name: LibFontName.medium, size: size) == nil {
                jbs_registerFont(withFilenameString: LibFontName.medium)
            }
            return UIFont(name: LibFontName.medium, size: size)
        } else if weight == .semibold {
            if UIFont(name: LibFontName.boldItalic, size: size) == nil {
                jbs_registerFont(withFilenameString: LibFontName.boldItalic)
            }
            return UIFont(name: LibFontName.boldItalic, size: size)
        }
        return UIFont(name: LibFontName.regular, size: size)
    }

    @objc class func libBoldSystemFont(ofSize size: CGFloat) -> UIFont? {
        if UIFont(name: LibFontName.bold, size: size) == nil {
            jbs_registerFont(withFilenameString: LibFontName.bold)
        }
        return UIFont(name: LibFontName.bold, size: size)
    }

    @objc class func libItalicSystemFont(ofSize size: CGFloat) -> UIFont? {
        if UIFont(name: LibFontName.italic, size: size) == nil {
            jbs_registerFont(withFilenameString: LibFontName.italic)
        }
        return UIFont(name: LibFontName.italic, size: size)
    }

    @objc convenience init(myCoder aDecoder: NSCoder) {
        guard
            let fontDescriptor = aDecoder.decodeObject(forKey: "UIFontDescriptor") as? UIFontDescriptor,
            let fontAttribute = fontDescriptor.fontAttributes[.nsctFontUIUsage] as? String else {
                self.init(myCoder: aDecoder)
                return
        }
        var fontName = ""
        switch fontAttribute {
        case "CTFontRegularUsage":
            fontName = LibFontName.regular
        case "CTFontEmphasizedUsage", "CTFontBoldUsage":
            fontName = LibFontName.bold
        case "CTFontObliqueUsage":
            fontName = LibFontName.italic
        default:
            fontName = LibFontName.regular
        }
        self.init(name: fontName, size: fontDescriptor.pointSize)!
    }

    class func libOverrideInitialize() {
        guard self == UIFont.self, !isOverrided, FONT_SELECT == 0 else { return }

        // Avoid method swizzling run twice and revert to original initialize function
        isOverrided = true

        if let systemFontMethod = class_getClassMethod(self, #selector(systemFont(ofSize:))),
            let mySystemFontMethod = class_getClassMethod(self, #selector(libSystemFont(ofSize:))) {
            method_exchangeImplementations(systemFontMethod, mySystemFontMethod)
        }
        
        if let systemFontWeightMethod = class_getClassMethod(self, #selector(systemFont(ofSize:weight:))),
           let mySystemFontWeightMethod = class_getClassMethod(self, #selector(libSystemFontWeight(ofSize:weight:))) {
            method_exchangeImplementations(systemFontWeightMethod, mySystemFontWeightMethod)
        }

        if let boldSystemFontMethod = class_getClassMethod(self, #selector(boldSystemFont(ofSize:))),
            let myBoldSystemFontMethod = class_getClassMethod(self, #selector(libBoldSystemFont(ofSize:))) {
            method_exchangeImplementations(boldSystemFontMethod, myBoldSystemFontMethod)
        }

        if let italicSystemFontMethod = class_getClassMethod(self, #selector(italicSystemFont(ofSize:))),
            let myItalicSystemFontMethod = class_getClassMethod(self, #selector(libItalicSystemFont(ofSize:))) {
            method_exchangeImplementations(italicSystemFontMethod, myItalicSystemFontMethod)
        }

        if let initCoderMethod = class_getInstanceMethod(self, #selector(UIFontDescriptor.init(coder:))), // Trick to get over the lack of UIFont.init(coder:))
            let myInitCoderMethod = class_getInstanceMethod(self, #selector(UIFont.init(myCoder:))) {
            method_exchangeImplementations(initCoderMethod, myInitCoderMethod)
        }
    }
    
    class func jbs_registerFont(withFilenameString filenameString: String) {

//        guard let pathForResourceString = Bundle.resourceBundle(for: Nexilis.self).path(forResource: filenameString, ofType: "otf") else { //resourcesMediaBundle
//            //print("UIFont+:  Failed to register font - path for resource not found.")
//            return
//        }
        
        var pathForResourceURL = Bundle.resourceBundle(for: Nexilis.self).url(forResource: filenameString, withExtension: "otf")
        if pathForResourceURL == nil {
            pathForResourceURL = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: filenameString, withExtension: "otf")
        }
        
//        guard let pathForResourceURL = Bundle.resourceBundle(for: Nexilis.self).url(forResource: filenameString, withExtension: "otf") else { //resourcesMediaBundle
//            //print("UIFont+:  Failed to register font - path for resource not found.")
//            return
//        }
        
        var errorRef: Unmanaged<CFError>? = nil
        CTFontManagerRegisterFontsForURL(pathForResourceURL! as CFURL, .process, &errorRef)

//        guard let fontData = NSData(contentsOfFile: pathForResourceString) else {
//            //print("UIFont+:  Failed to register font - font data could not be loaded.")
//            return
//        }
//
//        guard let dataProvider = CGDataProvider(data: fontData) else {
//            //print("UIFont+:  Failed to register font - data provider could not be loaded.")
//            return
//        }
//
//        guard let font = CGFont(dataProvider) else {
//            //print("UIFont+:  Failed to register font - font could not be loaded.")
//            return
//        }
//
//        var errorRef: Unmanaged<CFError>? = nil
//        if (CTFontManagerRegisterGraphicsFont(font, &errorRef) == false) {
//        }
    }
}

public protocol LoginDelegate: NSObjectProtocol {
    func onProgress(code: String, progress: Int)
    func onProcess(message: String, status: String)
}

public protocol MessageDelegate: NSObjectProtocol {
    func onReceive(message: TMessage)
    func onReceiveComment(message: TMessage)
    func onReceive(message: [AnyHashable: Any?])
    func onMessage(message: TMessage)
    func onUpload(name: String, progress: Double)
    func onTyping(message: TMessage)
}

public protocol GroupDelegate: NSObjectProtocol {
    func onGroup(code: String, f_pin: String, groupId: String)
    func onTopic(code: String, f_pin: String, topicId: String)
    func onMember(code: String, f_pin: String, groupId: String, member: String)
}

public protocol DownloadDelegate: NSObjectProtocol {
    func onDownloadProgress(fileName: String, progress: Double)
}

public protocol CallDelegate: NSObjectProtocol {
    func onIncomingCall(state: Int, message: String)
    func onStatusCall(state: Int, message: String)
}

public protocol LiveStreamingDelegate: NSObjectProtocol {
    func onStartLS(state: Int, message: String)
    func onJoinLS(state: Int, message: String)
}

public protocol SeminarDelegate: NSObjectProtocol {
    func onStartSeminar(state: Int, message: String)
    func onJoinSeminar(state: Int, message: String)
}

public protocol VideoCallDelegate: NSObjectProtocol {
    func onInitiateVideoCall(destination:String,state: Int, message: String)
    func onAcceptVideoCall(originator:String,state: Int, message: String)
    func onVideoCallReceiverTerminate(originator:String,state: Int, message: String)
    
}

public protocol PersonInfoDelegate: NSObjectProtocol {
    func onUpdatePersonInfo(state: Int, message: String)
}

public protocol ScreenSharingDelegate: NSObjectProtocol {
    func onStartScreenSharing(state:Int,message:String)
    func onJoinScreenSharing(state:Int,message:String)
}

public protocol CommentDelegate: NSObjectProtocol {
    func onReceiveComment(message: TMessage)
    func onDeleteComment(message: TMessage)
}

public protocol UploadDelegate: NSObjectProtocol {
    func onUploadProgress(fileName: String, progress: Double)
}

public protocol TimelineDelegate: NSObjectProtocol {
    func onPostUpdate(status: String, message: String)
}

public protocol ConnectionDelegate: NSObjectProtocol {
    func connectionStateChanged(userId: String!, deviceId: String, state: Bool)
}

public protocol ConnectDelegate: NSObjectProtocol {
    func onSuccess(userId: String)
    func onFailed(error: String)
}

public enum AppStoryBoard: String {
    
    case Palio = "Palio"
    
    public var instance: UIStoryboard {
        return UIStoryboard(name: self.rawValue, bundle: Bundle.resourceBundle(for: Nexilis.self))
    }
    
}

public var uuidOngoing = UUID()

extension Nexilis: CallDelegate {
    
    public func onIncomingCall(state: Int, message: String) {
        DispatchQueue.main.async {
            let idMe = User.getMyPin()!
            let myData = User.getData(pin: idMe)
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            if !onGoingCC.isEmpty {
                return
            }
            let deviceId = message.split(separator: ",")[0]
            if myData?.offline_mode == "1" || self.stateUnfriend == deviceId {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    API.terminateCall(sParty: nil)
                })
                return
            }
            var isShowAlert: Double?
            let canShow = UIApplication.shared.visibleViewController
            if canShow != nil && !(canShow is UINavigationController) {
                if !(canShow is EditorPersonal) {
                    isShowAlert = 0
                } else {
                    isShowAlert = 1.5
                }
            } else if canShow != nil {
                if canShow is UINavigationController {
                    let canShowNC = canShow as! UINavigationController
                    if !(canShowNC.visibleViewController is EditorPersonal) {
                        isShowAlert = 0
                    } else {
                        isShowAlert = 1.5
                    }
                } else {
                    isShowAlert = 0
                }
            }
            if (state == Nexilis.AUDIO_CALL_INCOMING && message.split(separator: ",")[1] != "joining Ac.room on channel 0" && message.split(separator: ",")[1] != "joining Vc.room on channel 0") {
                if Nexilis.callAPNActivated || APIS.checkAppStateisBackground() {
                    return
                }
                let data = User.getDataCanNil(pin: String(deviceId))
                if data == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        API.terminateCall(sParty: nil)
                    })
                    return
                }
                let controller = QmeraAudioViewController()
                controller.user = User.getData(pin: String(deviceId))
                controller.isOutgoing = false
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
            } else if (state == Nexilis.VIDEO_CALL_INCOMING && message.split(separator: ",")[1] != "joining Ac.room on channel 0" && message.split(separator: ",")[1] != "joining Vc.room on channel 0") {
                if Nexilis.callAPNActivated || APIS.checkAppStateisBackground() {
                    return
                }
                let dataUser = User.getDataCanNil(pin: String(deviceId))
                if dataUser == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        API.terminateCall(sParty: nil)
                    })
                    return
                }
                let videoController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
                videoController.fPin = String(deviceId)
                videoController.isInisiator = false
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
    
    public func onStatusCall(state: Int, message: String) {
        var dataCall: [AnyHashable : Any] = [:]
        dataCall["state"] = state
        dataCall["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.listenerStatusCall), object: nil, userInfo: dataCall)
    }
    
}

var previewItem : NSURL?
var listCCIdInv: [String] = []
var imageGif: UIImageView!
var posGif = "0"
var loopGif = "0"
var timerAnimationGif = Timer()

extension Nexilis: MessageDelegate {
    public func onReceiveComment(message: TMessage) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onReceiveComment"), object: nil, userInfo: dataMessage)
    }
    
    @objc func tapLinkBroadcast(_ sender: ObjectGesture) {
        var stringURl = sender.message_id.lowercased()
        if stringURl.starts(with: "www.") {
            stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
        }
        guard let url = URL(string: stringURl) else { return }
        UIApplication.shared.open(url)
    }
    
    private func runAnimationGif() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: { [self] in
            if imageGif != nil {
                timerAnimationGif.invalidate()
                timerAnimationGif = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(animateGif), userInfo: nil, repeats: true)
            }
        })
    }
    
    @objc func animateGif() {
        DispatchQueue.main.async {
            if posGif == "0" { //left
                if imageGif.frame.origin.x < (UIScreen.main.bounds.width - imageGif.frame.width) {
                    imageGif.frame.origin.x+=0.1
                } else {
                    timerAnimationGif.invalidate()
                }
            } else if posGif == "1" { //right
                if imageGif.frame.origin.x > 0 {
                    imageGif.frame.origin.x-=0.1
                } else {
                    timerAnimationGif.invalidate()
                }
            } else if posGif == "2" { //top
                if imageGif.frame.origin.y < (UIScreen.main.bounds.height - imageGif.frame.height) {
                    imageGif.frame.origin.y+=0.1
                } else {
                    timerAnimationGif.invalidate()
                }
            } else { //bottom
                if imageGif.frame.origin.y > 20 {
                    imageGif.frame.origin.y-=0.1
                } else {
                    timerAnimationGif.invalidate()
                }
            }
        }
    }
    
    func showBroadcastMessage(m: [String: String]) {
        let fileType = m[CoreMessage_TMessageKey.CATEGORY_FLAG]!
        let gifId = m[CoreMessage_TMessageKey.GIF_ID] ?? ""
        let scopeBrodcast = m[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]
        if scopeBrodcast == "18" {
            DispatchQueue.global().async {
                while (API.nGetCLXConnState() == 0) {
                    Thread.sleep(forTimeInterval: 0.5)
                }
                if let stringForm = m[CoreMessage_TMessageKey.MESSAGE_TEXT] {
                    if let data = stringForm.data(using: .utf8) {
                        do {
                            if let jsonForm = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                let formId = jsonForm["form_id"] as! String
                                if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.pullFormSyc(formId: formId)) {
                                    if response.isOk() {
                                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                            do {
                                                let formId = response.getBody(key: CoreMessage_TMessageKey.FORM_ID)
                                                let title = response.getBody(key: CoreMessage_TMessageKey.TITLE)
                                                let createdDate = response.getBody(key: CoreMessage_TMessageKey.CREATED_DATE)
                                                let createdBy = response.getBody(key: CoreMessage_TMessageKey.CREATED_BY)
                                                let seq = response.getBodyAsLong(key: CoreMessage_TMessageKey.SEQUENCE, default_value: 0)
                                                let iconTitle = response.getBody(key: CoreMessage_TMessageKey.ICON_TITLE)
                                                let iconSuffix = response.getBody(key: CoreMessage_TMessageKey.ICON_SUFFIX)
                                                let footer = response.getBody(key: CoreMessage_TMessageKey.FOOTER)
                                                let form = FormM(formId: formId, title: title, createdDate: createdDate, createdBy: createdBy, sqNo: Int64(seq), iconTitle: iconTitle, iconSuffix: iconSuffix, footer: footer)
                                                
                                                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "FORM", cvalues: [
                                                    "form_id" : formId,
                                                    "name" : title,
                                                    "created_date" : createdDate,
                                                    "created_by" : createdBy,
                                                    "sq_no" : seq,
                                                    "icon_title" : iconTitle,
                                                    "icon_suffix" : iconSuffix,
                                                    "footer" : footer
                                                ], replace: true)
                                                var isButton = false
                                                let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                                                var firstFormItem: FormItemM = FormItemM(formId: "")
                                                if !data.isEmpty {
                                                    if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                                                        for json in jsonArray {
                                                            let key = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.KEY)
                                                            let label = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.LABEL)
                                                            let value = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.VALUE)
                                                            let type = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.TYPE)
                                                            let background = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.BACKGROUND)
                                                            let color = CoreMessage_TMessageUtil.getString(json: json, key: CoreMessage_TMessageKey.COLOR)
                                                            let formItem = FormItemM(formId: formId, label: label, value: value, key: key, sqNo: Int64(seq), type: type, background: background, color: color)
                                                            firstFormItem = formItem
                                                            if type == "26" {
                                                                isButton = true
                                                            }
                                                            
                                                            _ = try Database.shared.insertRecord(fmdb: fmdb, table: "FORM_ITEM", cvalues: [
                                                                "form_id" : formId,
                                                                "key" : key,
                                                                "label" : label,
                                                                "value" : value,
                                                                "type" : type,
                                                                "sq_no" : seq,
                                                                "background" : background,
                                                                "color" : color
                                                            ], replace: true)
                                                        }
                                                    }
                                                }
                                                if isButton {
                                                    DispatchQueue.main.async {
                                                        let dialog = DialogBroadcastInApp()
                                                        dialog.modalTransitionStyle = .crossDissolve
                                                        dialog.modalPresentationStyle = .overCurrentContext
                                                        dialog.form = form
                                                        dialog.formItem = firstFormItem
                                                        dialog.listTitleButton = (m["exbook1"]!).components(separatedBy: ",")
                                                        let brdTitle = jsonForm["brd_title"] as? String
                                                        let formL = jsonForm["form_label"] as? String
                                                        if brdTitle != nil && formL != nil{
                                                            dialog.labelForm = formL ?? ""
                                                        }
                                                        dialog.message = m
                                                        UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                                                    }
                                                } else {
                                                    print("show broadcast no button \(response.toLogString())")
                                                }
                                            } catch {
                                                rollback.pointee = true
                                                print("Access database error: \(error.localizedDescription)")
                                            }
                                        })
                                    } else {
                                        self.showBroadcastMessage(m: m)
                                    }
                                } else {
                                    self.showBroadcastMessage(m: m)
                                }
                            }
                        } catch {
                            print("Error converting string to JSON:", error)
                        }
                    }
                }
            }
            return
        }
        let broadcastVC = UIViewController()
        if let viewBroadcast = broadcastVC.view {
            broadcastVC.modalPresentationStyle = .custom
            viewBroadcast.backgroundColor = .black.withAlphaComponent(0.3)
            if !gifId.isEmpty {
                let urlGif = "\(Utils.getURLBase())filepalio/image/\(gifId)"
                let scale = m[CoreMessage_TMessageKey.SCALE] ?? "0"
                let link = m[CoreMessage_TMessageKey.LINK] ?? ""
                posGif = m[CoreMessage_TMessageKey.START_ANIMATION] ?? "0"
                loopGif = m[CoreMessage_TMessageKey.LOOP_ANIMATION] ?? "0"
                
                imageGif = UIImageView()
                viewBroadcast.addSubview(imageGif)
                imageGif.isUserInteractionEnabled = true
                imageGif.contentMode = .scaleAspectFit
                
                let buttonClose = UIButton(type: .close)
                buttonClose.frame.size = CGSize(width: 30, height: 30)
                buttonClose.layer.cornerRadius = 15.0
                buttonClose.clipsToBounds = true
                buttonClose.backgroundColor = .black.withAlphaComponent(0.5)
                buttonClose.actionHandle(controlEvents: .touchUpInside,
                 ForAction:{() -> Void in
                    broadcastVC.dismiss(animated: true, completion: {
                        imageGif = nil
                        Nexilis.broadcastList.remove(at: 0)
                        if Nexilis.broadcastList.count > 0 {
                            Nexilis.shared.showBroadcastMessage(m: Nexilis.broadcastList[0])
                        }
                    })
                 })
                imageGif.addSubview(buttonClose)
                buttonClose.anchor(top: imageGif.topAnchor, right: imageGif.rightAnchor, width: 30, height: 30)
                
                var xpos: CGFloat = 0
                var ypos: CGFloat = 0
                var widthImage: CGFloat = 300
                var heightImage: CGFloat = 300
                if scale == "2" { //50%
                    widthImage = 150
                    heightImage = 150
                } else if scale == "1" { //75%
                    widthImage = 225
                    heightImage = 225
                }
                
                if posGif == "0" { //left
                    xpos = 0
                    ypos = (viewBroadcast.frame.size.height / 2) - (heightImage / 2)
                } else if posGif == "1" { //right
                    xpos = viewBroadcast.frame.size.width - widthImage
                    ypos = (viewBroadcast.frame.size.height / 2) - (heightImage / 2)
                } else if posGif == "2" { //top
                    xpos = (viewBroadcast.frame.size.width / 2) - (widthImage / 2)
                    ypos = 20
                } else { //bottom
                    xpos = (viewBroadcast.frame.size.width / 2) - (widthImage / 2)
                    ypos = viewBroadcast.frame.size.height - heightImage
                }
                imageGif.frame = CGRect(x: xpos, y: ypos, width: widthImage, height: heightImage)
                imageGif.loadImageAsync(with: urlGif, isGif: true)
                runAnimationGif()
                imageGif.actionHandle(controlEvents: .touchUpInside, ForAction: {
                    broadcastVC.dismiss(animated: true, completion: {
                        imageGif = nil
                        Nexilis.broadcastList.remove(at: 0)
                        if Nexilis.broadcastList.count > 0 {
                            Nexilis.shared.showBroadcastMessage(m: Nexilis.broadcastList[0])
                        }
                        if !link.isEmpty {
                            APIS.openUrl(url: link)
                        }
                    })
                })
                
            } else {
                let stringLink = m[CoreMessage_TMessageKey.LINK] ?? ""
                
                let containerView = UIView()
                viewBroadcast.addSubview(containerView)
                if stringLink.isEmpty {
                    containerView.anchor(centerX: viewBroadcast.centerXAnchor, centerY: viewBroadcast.centerYAnchor, width: viewBroadcast.bounds.width - 40, minHeight: 100, maxHeight: viewBroadcast.bounds.height - 100)
                } else {
                    containerView.anchor(centerX: viewBroadcast.centerXAnchor, centerY: viewBroadcast.centerYAnchor, width: viewBroadcast.bounds.width - 40, minHeight: 200, maxHeight: viewBroadcast.bounds.height - 100)
                }
                containerView.backgroundColor = .white.withAlphaComponent(0.9)
                containerView.layer.cornerRadius = 15.0
                containerView.clipsToBounds = true
                
                let subContainerView = UIView()
                subContainerView.backgroundColor = .clear
                containerView.addSubview(subContainerView)
                subContainerView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 20.0, paddingLeft: 10.0, paddingBottom: 20.0, paddingRight: 10.0)
                
                let buttonClose = UIButton(type: .close)
                buttonClose.frame.size = CGSize(width: 30, height: 30)
                buttonClose.layer.cornerRadius = 15.0
                buttonClose.clipsToBounds = true
                buttonClose.backgroundColor = .secondaryColor.withAlphaComponent(0.5)
                buttonClose.actionHandle(controlEvents: .touchUpInside,
                 ForAction:{() -> Void in
                    broadcastVC.dismiss(animated: true, completion: {
                        Nexilis.broadcastList.remove(at: 0)
                        if Nexilis.broadcastList.count > 0 {
                            Nexilis.shared.showBroadcastMessage(m: Nexilis.broadcastList[0])
                        }
                    })
                 })
                containerView.addSubview(buttonClose)
                buttonClose.anchor(top: containerView.topAnchor, right: containerView.rightAnchor, width: 30, height: 30)
                
                let title = UILabel()
                title.font = .systemFont(ofSize: 18, weight: .bold)
                title.text = m["MERNAM"]
                title.textAlignment = .center
                subContainerView.addSubview(title)
                title.anchor(top: subContainerView.topAnchor, left: subContainerView.leftAnchor, right: subContainerView.rightAnchor)
                
                let titleBroadcast = UILabel()
                subContainerView.addSubview(titleBroadcast)
                titleBroadcast.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    titleBroadcast.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 20.0),
                    titleBroadcast.leadingAnchor.constraint(equalTo: subContainerView.leadingAnchor),
                    titleBroadcast.trailingAnchor.constraint(equalTo: subContainerView.trailingAnchor),
                ])
                titleBroadcast.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
                titleBroadcast.numberOfLines = 0
                titleBroadcast.attributedText = m[CoreMessage_TMessageKey.TITLE]!.richText()
                titleBroadcast.textColor = .black
                
                let descBroadcast = UILabel()
                subContainerView.addSubview(descBroadcast)
                descBroadcast.translatesAutoresizingMaskIntoConstraints = false
                let constraintDesc = descBroadcast.bottomAnchor.constraint(equalTo: subContainerView.bottomAnchor)
                if !stringLink.isEmpty{
                    constraintDesc.constant = constraintDesc.constant - 30
                }
                if fileType != BroadcastViewController.FILE_TYPE_CHAT {
                    constraintDesc.constant = constraintDesc.constant - 260
                }
                NSLayoutConstraint.activate([
                    descBroadcast.topAnchor.constraint(equalTo: titleBroadcast.bottomAnchor, constant: 10),
                    descBroadcast.leadingAnchor.constraint(equalTo: subContainerView.leadingAnchor),
                    descBroadcast.trailingAnchor.constraint(equalTo: subContainerView.trailingAnchor),
                    constraintDesc,
                ])
                descBroadcast.font = UIFont.systemFont(ofSize: 12)
                descBroadcast.numberOfLines = 0
                descBroadcast.attributedText = m[CoreMessage_TMessageKey.MESSAGE_TEXT_ENG]!.richText()
                descBroadcast.textColor = .black
                
                let linkBroadcast = UILabel()
                if !stringLink.isEmpty {
                    subContainerView.addSubview(linkBroadcast)
                    linkBroadcast.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        linkBroadcast.topAnchor.constraint(equalTo: descBroadcast.bottomAnchor, constant: 10),
                        linkBroadcast.leadingAnchor.constraint(equalTo: subContainerView.leadingAnchor),
                        linkBroadcast.trailingAnchor.constraint(equalTo: subContainerView.trailingAnchor),
                    ])
                    linkBroadcast.font = UIFont.systemFont(ofSize: 12)
                    linkBroadcast.isUserInteractionEnabled = true
                    linkBroadcast.numberOfLines = 2
                    let attributedString = NSMutableAttributedString(string: stringLink, attributes:[NSAttributedString.Key.link: URL(string: stringLink)!])
                    linkBroadcast.attributedText = attributedString
                    let tap = ObjectGesture(target: self, action: #selector(tapLinkBroadcast))
                    tap.message_id = stringLink
                    linkBroadcast.addGestureRecognizer(tap)
                }
                
                let thumb = m[CoreMessage_TMessageKey.THUMB_ID] ?? ""
                let image = m[CoreMessage_TMessageKey.IMAGE_ID] ?? ""
                let video = m[CoreMessage_TMessageKey.VIDEO_ID] ?? ""
                let file = m[CoreMessage_TMessageKey.FILE_ID] ?? ""
                if fileType != BroadcastViewController.FILE_TYPE_CHAT {
                    let imageBroadcast = UIImageView()
                    subContainerView.addSubview(imageBroadcast)
                    imageBroadcast.translatesAutoresizingMaskIntoConstraints = false
                    var constImage = imageBroadcast.topAnchor.constraint(equalTo: descBroadcast.bottomAnchor, constant: 10)
                    if !stringLink.isEmpty {
                        constImage = imageBroadcast.topAnchor.constraint(equalTo: linkBroadcast.bottomAnchor, constant: 10)
                    }
                    NSLayoutConstraint.activate([
                        constImage,
                        imageBroadcast.leadingAnchor.constraint(equalTo: subContainerView.leadingAnchor),
                        imageBroadcast.trailingAnchor.constraint(equalTo: subContainerView.trailingAnchor),
                        imageBroadcast.heightAnchor.constraint(equalToConstant: 250)
                    ])
                    imageBroadcast.layer.cornerRadius = 10.0
                    imageBroadcast.clipsToBounds = true
                    if fileType != BroadcastViewController.FILE_TYPE_DOCUMENT {
                        imageBroadcast.contentMode = .scaleAspectFill
                        imageBroadcast.setImage(name: thumb)
                
                        if fileType == BroadcastViewController.FILE_TYPE_VIDEO {
                            let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                            imageBroadcast.addSubview(imagePlay)
                            imagePlay.clipsToBounds = true
                            imagePlay.translatesAutoresizingMaskIntoConstraints = false
                            imagePlay.centerYAnchor.constraint(equalTo: imageBroadcast.centerYAnchor).isActive = true
                            imagePlay.centerXAnchor.constraint(equalTo: imageBroadcast.centerXAnchor).isActive = true
                            imagePlay.widthAnchor.constraint(equalToConstant: 60).isActive = true
                            imagePlay.heightAnchor.constraint(equalToConstant: 60).isActive = true
                            imagePlay.tintColor = .gray.withAlphaComponent(0.5)
                        }
                    } else {
                        imageBroadcast.image = UIImage(systemName: "doc.fill")
                        imageBroadcast.tintColor = .mainColor
                        imageBroadcast.contentMode = .scaleAspectFit
                    }
                
                    imageBroadcast.actionHandle(controlEvents: .touchUpInside,
                     ForAction:{() -> Void in
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if fileType == BroadcastViewController.FILE_TYPE_IMAGE {
                            if let dirPath = paths.first {
                                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(image)
                                if FileManager.default.fileExists(atPath: imageURL.path) {
                                    do {
                                        APIS.openImageNexilis(imageView: imageBroadcast, data: try Data(contentsOf: imageURL))
                                    } catch {
                                        
                                    }
                                } else if FileEncryption.shared.isSecureExists(filename: image) {
                                    do {
                                        if var data = try FileEncryption.shared.readSecure(filename: image) {
                                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                            if dataDecrypt != nil {
                                                data = dataDecrypt!
                                            }
                                            APIS.openImageNexilis(imageView: imageBroadcast, data: data)
                                        }
                                    } catch {
                                        
                                    }
                                } else {
                                    Download().startHTTP(forKey: image) { (name, progress) in
                                        guard progress == 100 else {
                                            return
                                        }
                
                                        DispatchQueue.main.async {
                                            var data : Data?
                                            if FileManager.default.fileExists(atPath: imageURL.path) {
                                                do {
                                                    data = try Data(contentsOf: imageURL)
                                                } catch {
                                                    
                                                }
                                            }
                                            else if FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                                                do {
                                                    if let imageData = try FileEncryption.shared.readSecure(filename: imageURL.lastPathComponent) {
                                                        if let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: imageData) {
                                                            if dataDecrypt == nil {
                                                                data = imageData
                                                            } else {
                                                                data = dataDecrypt
                                                            }
                                                        }
                                                    }
                                                } catch {
                                                    
                                                }
                                            }
                                            APIS.openImageNexilis(imageView: imageBroadcast, data: data)
                                        }
                                    }
                                }
                            }
                        } else if fileType == BroadcastViewController.FILE_TYPE_VIDEO {
                            //https://qmera.io/filepalio/image/
                            let player = AVPlayer(url: URL(string: "https://nexilis.io/get_file?account=\(Nexilis.sAPIKey)&image=\(video)")!)
                            let playerVC = AVPlayerViewController()
                            playerVC.player = player
                            playerVC.modalPresentationStyle = .custom
                            if UIApplication.shared.visibleViewController?.navigationController != nil {
                                UIApplication.shared.visibleViewController?.navigationController?.present(playerVC, animated: true, completion: nil)
                            } else {
                                UIApplication.shared.visibleViewController?.present(playerVC, animated: true, completion: nil)
                            }
                        } else if fileType == BroadcastViewController.FILE_TYPE_DOCUMENT {
                            if let dirPath = paths.first {
                                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(file)
                                if FileManager.default.fileExists(atPath: fileURL.path) {
                                    previewItem = fileURL as NSURL
                                    let previewController = QLPreviewController()
                                    let rightBarButton = UIBarButtonItem()
                                    previewController.navigationItem.rightBarButtonItem = rightBarButton
                                    previewController.dataSource = self
                                    previewController.modalPresentationStyle = .overFullScreen
                
                                    if UIApplication.shared.visibleViewController?.navigationController != nil {
                                        UIApplication.shared.visibleViewController?.navigationController?.present(previewController, animated: true, completion: nil)
                                    } else {
                                        UIApplication.shared.visibleViewController?.present(previewController, animated: true, completion: nil)
                                    }
                                } else if FileEncryption.shared.isSecureExists(filename: file) {
                                    do {
                                        if var docData = try FileEncryption.shared.readSecure(filename: file) {
                                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: docData)
                                            if dataDecrypt != nil {
                                                docData = dataDecrypt!
                                            }
                                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                                            let tempPath = cachesDirectory.appendingPathComponent(file)
                                            try docData.write(to: tempPath)
                                            previewItem = tempPath as NSURL
                                            let previewController = QLPreviewController()
                                            let rightBarButton = UIBarButtonItem()
                                            previewController.navigationItem.rightBarButtonItem = rightBarButton
                                            previewController.dataSource = self
                                            previewController.modalPresentationStyle = .overFullScreen
                                            
                                            if UIApplication.shared.visibleViewController?.navigationController != nil {
                                                UIApplication.shared.visibleViewController?.navigationController?.present(previewController, animated: true, completion: nil)
                                            } else {
                                                UIApplication.shared.visibleViewController?.present(previewController, animated: true, completion: nil)
                                            }
                                        }
                                    } catch {
                                        
                                    }
                                } else {
                                    Download().startHTTP(forKey: file) { (name, progress) in
                                        DispatchQueue.main.async {
                                            guard progress == 100 else {
                                                return
                                            }
                                            do {
                                                if var docData = try FileEncryption.shared.readSecure(filename: file) {
                                                    let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: docData)
                                                    if dataDecrypt != nil {
                                                        docData = dataDecrypt!
                                                    }
                                                    let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                                                    let tempPath = cachesDirectory.appendingPathComponent(file)
                                                    try docData.write(to: tempPath)
                                                    previewItem = tempPath as NSURL
                                                    let previewController = QLPreviewController()
                                                    let rightBarButton = UIBarButtonItem()
                                                    previewController.navigationItem.rightBarButtonItem = rightBarButton
                                                    previewController.dataSource = self
                                                    previewController.modalPresentationStyle = .overFullScreen
                                                    
                                                    if UIApplication.shared.visibleViewController?.navigationController != nil {
                                                        UIApplication.shared.visibleViewController?.navigationController?.present(previewController, animated: true, completion: nil)
                                                    } else {
                                                        UIApplication.shared.visibleViewController?.present(previewController, animated: true, completion: nil)
                                                    }
                                                }
                                            }
                                            catch {
                                                
                                            }
                                        }
                                    }
                                }
                            }
                        }
                     })
                }
            }

            broadcastVC.modalTransitionStyle = .crossDissolve
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(broadcastVC, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(broadcastVC, animated: true, completion: nil)
            }
        }
    }
    
    static func viewFormCS(pin: String, channel: String, displayName: String, thumb: String, id: String) {
        if User.getDataCanNil(pin: pin) == nil {
            Nexilis.addFriendSilent(fpin: pin)
            sleep(1)
        }
        DispatchQueue.main.async {
            if Nexilis.onGoingPushCC.isEmpty {
                var data: [String: String] = [:]
                data["channel"] = channel
                data["l_pin"] = pin
                data["f_display_name"] = displayName
                Nexilis.onGoingPushCC = data
            } else if Nexilis.onGoingPushCC["l_pin"] == pin {
                return
            }
            let alert = LibAlertController(title: "", message: "\n\n\n\n\n\n\n\n\n\n".localized(), preferredStyle: .alert)
            let newWidth = UIScreen.main.bounds.width * 0.90 - 270
            // update width constraint value for main view
            if let viewWidthConstraint = alert.view.constraints.filter({ return $0.firstAttribute == .width }).first{
                viewWidthConstraint.constant = newWidth
            }
            // update width constraint value for container view
            if let containerViewWidthConstraint = alert.view.subviews.first?.constraints.filter({ return $0.firstAttribute == .width }).first {
                containerViewWidthConstraint.constant = newWidth
            }
            let titleFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.black]
            let titleAttrString = NSMutableAttributedString(string: "Call Center".localized(), attributes: titleFont)
            alert.setValue(titleAttrString, forKey: "attributedTitle")
            alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = .lightGray
            alert.view.tintColor = .black
            let rejectAction = UIAlertAction(title: "Pass to other representative".localized(), style: .destructive, handler: {(_) in
                APIS.isHasFormCS = false
                DispatchQueue.global().async {
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.timeOutRequestCallCenter(channel: channel, l_pin: pin))
                }
                Nexilis.onGoingPushCC.removeAll()
                alert.dismiss(animated: true, completion: nil)
            })
            let acceptAction = UIAlertAction(title: "I'll handle the customer".localized(), style: .default, handler: {(_) in
                APIS.isHasFormCS = false
                let goAudioCall = Nexilis.checkMicPermission()
                if !goAudioCall && channel == "1" {
                    let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow microphone permission in your settings".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: { _ in
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }))
                    if UIApplication.shared.visibleViewController?.navigationController != nil {
                        UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
                    } else {
                        UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
                    }
                    DispatchQueue.global().async {
                        DispatchQueue.global().async {
                            _ = Nexilis.write(message: CoreMessage_TMessageBank.timeOutRequestCallCenter(channel: channel, l_pin: pin))
                            
                        }
                    }
                    Nexilis.onGoingPushCC.removeAll()
                    return
                }
                if channel == "2" {
                    var permissionCheck = -1
                    if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
                        permissionCheck = 1
                    } else if AVCaptureDevice.authorizationStatus(for: .video) ==  .denied {
                        permissionCheck = 0
                    } else {
                        Nexilis.dispatch = DispatchGroup()
                        Nexilis.dispatch?.enter()
                        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) -> Void in
                            if granted == true {
                                permissionCheck = 1
                            } else {
                                permissionCheck = 0
                            }
                            if let dispatch = Nexilis.dispatch {
                                dispatch.leave()
                            }
                        })
                        Nexilis.dispatch?.wait()
                        Nexilis.dispatch = nil
                    }
                    if permissionCheck == 0 {
                        let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow camera permission in your settings".localized(), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: { _ in
                            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        }))
                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                            UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
                        } else {
                            UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
                        }
                        DispatchQueue.global().async {
                            DispatchQueue.global().async {
                                _ = Nexilis.write(message: CoreMessage_TMessageBank.timeOutRequestCallCenter(channel: channel, l_pin: pin))
                            }
                        }
                        Nexilis.onGoingPushCC.removeAll()
                        return
                    }
                }
                if UIApplication.shared.visibleViewController is UINavigationController {
                    let nc = UIApplication.shared.visibleViewController as! UINavigationController
                    if nc.visibleViewController is QmeraStreamingViewController {
                        let vc = nc.visibleViewController as! QmeraStreamingViewController
                        var alert = LibAlertController(title: "", message: "Are you sure you want to end Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                        if !vc.isLive {
                            alert = LibAlertController(title: "", message: "Are you sure you want to leave Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                        }
                        alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: { _ in
                            DispatchQueue.global().async {
                                _ = Nexilis.write(message: CoreMessage_TMessageBank.timeOutRequestCallCenter(channel: channel, l_pin: pin))
                            }
                            Nexilis.onGoingPushCC.removeAll()
                            alert.dismiss(animated: true, completion: nil)
                        }))
                        alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: { _ in
                            DispatchQueue.global().async {
                                API.terminateBC(sBroadcasterID: vc.isLive ? nil : vc.data)
                                vc.sendLeft()
                            }
                            vc.dismiss(animated: true, completion: {
                                acceptCC()
                            })
                        }))
                        nc.present(alert, animated: true, completion: nil)
                    } else if nc.visibleViewController is SeminarViewController {
                        let vc = nc.visibleViewController as! SeminarViewController
                        var alert = LibAlertController(title: "", message: "Are you sure you want to end Seminar, and open notification?".localized(), preferredStyle: .alert)
                        if !vc.isLive {
                            alert = LibAlertController(title: "", message: "Are you sure you want to leave Seminar, and open notification?".localized(), preferredStyle: .alert)
                        }
                        alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: { _ in
                            DispatchQueue.global().async {
                                _ = Nexilis.write(message: CoreMessage_TMessageBank.timeOutRequestCallCenter(channel: channel, l_pin: pin))
                            }
                            Nexilis.onGoingPushCC.removeAll()
                            alert.dismiss(animated: true, completion: nil)
                        }))
                        alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: { _ in
                            DispatchQueue.global().async {
                                API.terminateBC(sBroadcasterID: vc.isLive ? nil : vc.data)
                                vc.sendLeft()
                            }
                            vc.dismiss(animated: true, completion: {
                                acceptCC()
                            })
                        }))
                        nc.present(alert, animated: true, completion: nil)
                    }  else {
                        acceptCC()
                    }
                } else {
                    acceptCC()
                }
                func acceptCC() {
                    if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptRequestCallCenter(channel: channel, l_pin: pin, complaint_id: id)) {
                        if (response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "00") {
                            Nexilis.onGoingPushCC.removeAll()
                            let complaintId = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
                            if !complaintId.isEmpty {
                                alert.dismiss(animated: true, completion: nil)
                                let idMe = User.getMyPin()!
                                SecureUserDefaults.shared.set("\(pin),\(idMe),\(complaintId)", forKey: "onGoingCC")
                                SecureUserDefaults.shared.set("\(pin)", forKey: "membersCC")
                                SecureUserDefaults.shared.set("\(channel)", forKey: "channelCC")
                                if channel == "0" {
                                    let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                                    editorPersonalVC.isContactCenter = true
                                    editorPersonalVC.isRequestContactCenter = false
                                    editorPersonalVC.unique_l_pin = pin
                                    editorPersonalVC.complaintId = complaintId
                                    editorPersonalVC.channelContactCenter = channel
                                    editorPersonalVC.fPinContacCenter = pin
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
                                } else {
                                    SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: "startTimeCC")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                        if channel == "1" {
                                            let controller = QmeraAudioViewController()
                                            controller.user = User.getData(pin: pin)
                                            controller.isOutgoing = true
                                            controller.ticketId = complaintId
                                            controller.modalPresentationStyle = .overCurrentContext
                                            let navigationController = CustomNavigationController(rootViewController: controller)
                                            navigationController.modalPresentationStyle = .fullScreen
                                            if UIApplication.shared.visibleViewController?.navigationController != nil {
                                                UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                                            } else {
                                                UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                                            }
                                        } else if channel == "2" {
                                            let videoVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
                                            videoVC.fPin = pin
                                            videoVC.users.append(User.getData(pin: pin)!)
                                            videoVC.ticketId = complaintId
                                            let navigationController = CustomNavigationController(rootViewController: videoVC)
                                            navigationController.modalPresentationStyle = .fullScreen
                                            if UIApplication.shared.visibleViewController?.navigationController != nil {
                                                UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                                            } else {
                                                UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                                            }
                                        }
                                    })
                                }
                            }
                        }
                    } else {
                        print("RESPONSE NIL")
                    }
                }
            })
            alert.addAction(acceptAction)
            alert.addAction(rejectAction)
            
            let containerView = UIView(frame: CGRect(x: 20, y: 60, width: alert.view.bounds.size.width * 0.9 - 40, height: 150))
            alert.view.addSubview(containerView)
            containerView.layer.cornerRadius = 10.0
            containerView.clipsToBounds = true
            containerView.backgroundColor = .secondaryColor.withAlphaComponent(0.5)
            
            let imageProfile = UIImageView()
            containerView.addSubview(imageProfile)
            imageProfile.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageProfile.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
                imageProfile.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
                imageProfile.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
                imageProfile.widthAnchor.constraint(equalToConstant: 100)
            ])
            imageProfile.layer.cornerRadius = 10.0
            imageProfile.clipsToBounds = true
            imageProfile.backgroundColor = .lightGray.withAlphaComponent(0.3)
            imageProfile.tintColor = .secondaryColor
            imageProfile.image = UIImage(systemName: "person")
            if thumb != "" {
                imageProfile.setImage(name: thumb)
                imageProfile.contentMode = .scaleAspectFill
            }
            
            let labelName = UILabel()
            containerView.addSubview(labelName)
            labelName.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                labelName.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
                labelName.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
            ])
            labelName.font = UIFont.systemFont(ofSize: 12)
            labelName.text = "Name".localized()
            labelName.textColor = .mainColor
            
            let valueName = UILabel()
            containerView.addSubview(valueName)
            valueName.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                valueName.topAnchor.constraint(equalTo: labelName.bottomAnchor),
                valueName.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
            ])
            valueName.font = UIFont.systemFont(ofSize: 12)
            valueName.text = displayName
            valueName.textColor = .mainColor
            
            let labelType = UILabel()
            containerView.addSubview(labelType)
            labelType.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                labelType.topAnchor.constraint(equalTo: valueName.bottomAnchor, constant: 5),
                labelType.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
            ])
            labelType.font = UIFont.systemFont(ofSize: 12)
            labelType.text = "Request Type".localized()
            labelType.textColor = .mainColor
            
            let valueType = UILabel()
            containerView.addSubview(valueType)
            valueType.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                valueType.topAnchor.constraint(equalTo: labelType.bottomAnchor),
                valueType.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
            ])
            valueType.font = UIFont.systemFont(ofSize: 12)
            if channel == "0" {
                valueType.text = "Chat".localized()
            } else if channel == "1" {
                valueType.text = "Audio Call".localized()
            } else if channel == "2" {
                valueType.text = "Video Call".localized()
            } else {
                valueType.text = "Email".localized()
            }
            valueType.textColor = .mainColor
            
            let labelIdentity = UILabel()
            containerView.addSubview(labelIdentity)
            labelIdentity.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                labelIdentity.topAnchor.constraint(equalTo: valueType.bottomAnchor, constant: 5),
                labelIdentity.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
            ])
            labelIdentity.font = UIFont.systemFont(ofSize: 12)
            labelIdentity.text = "Complaint ID".localized()
            labelIdentity.textColor = .mainColor
            
            let valueIdentity = UILabel()
            containerView.addSubview(valueIdentity)
            valueIdentity.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                valueIdentity.topAnchor.constraint(equalTo: labelIdentity.bottomAnchor),
                valueIdentity.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5),
                valueIdentity.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
            valueIdentity.font = UIFont.systemFont(ofSize: 12)
            valueIdentity.text = id
            valueIdentity.numberOfLines = 0
            valueIdentity.textColor = .mainColor
            
            var isShowAlert: Int?
            let canShow = UIApplication.shared.visibleViewController
            if canShow != nil && !(canShow is UINavigationController) {
                if !(canShow is EditorPersonal) && !(canShow is QmeraAudioViewController) && !(canShow is QmeraVideoViewController) {
                    isShowAlert = 0
                } else {
                    isShowAlert = 3
                }
            } else if canShow != nil {
                if canShow is UINavigationController {
                    let canShowNC = canShow as! UINavigationController
                    if !(canShowNC.visibleViewController is EditorPersonal) && !(canShowNC.visibleViewController is QmeraAudioViewController) && !(canShowNC.visibleViewController is QmeraVideoViewController) {
                        isShowAlert = 0
                    } else {
                        isShowAlert = 3
                    }
                } else {
                    isShowAlert = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(isShowAlert!), execute: {
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
                }
            })
        }
    }
    
    static func viewFormCSInvited(pin: String, channel: String, id: String, nameInvited: String, thumbInvited: String) {
        DispatchQueue.main.async {
            let alert = LibAlertController(title: "", message: "\n\n\n\n\n\n\n\n\n\n".localized(), preferredStyle: .alert)
            let newWidth = UIScreen.main.bounds.width * 0.90 - 270
            // update width constraint value for main view
            if let viewWidthConstraint = alert.view.constraints.filter({ return $0.firstAttribute == .width }).first{
                viewWidthConstraint.constant = newWidth
            }
            // update width constraint value for container view
            if let containerViewWidthConstraint = alert.view.subviews.first?.constraints.filter({ return $0.firstAttribute == .width }).first {
                containerViewWidthConstraint.constant = newWidth
            }
            let titleFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: UIColor.black]
            let titleAttrString = NSMutableAttributedString(string: "You're invited to\nCall Center".localized(), attributes: titleFont)
            alert.setValue(titleAttrString, forKey: "attributedTitle")
            alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = .lightGray
            alert.view.tintColor = .black
            let rejectAction = UIAlertAction(title: "Reject".localized(), style: .destructive, handler: {(_) in
                APIS.isHasFormCS = false
                listCCIdInv.removeAll(where: {$0 == id})
                DispatchQueue.global().async {
                    if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptCCRoomInvite(l_pin: pin, type: 0, ticket_id: id)) {
                        if result.isOk() {
                            return
                        }
                    }
                }
                alert.dismiss(animated: true, completion: nil)
            })
            let acceptAction = UIAlertAction(title: "Accept".localized(), style: .default, handler: {(_) in
                listCCIdInv.removeAll(where: {$0 == id})
                let goAudioCall = Nexilis.checkMicPermission()
                if !goAudioCall && channel == "1" {
                    let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow microphone permission in your settings".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: { _ in
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }))
                    if UIApplication.shared.visibleViewController?.navigationController != nil {
                        UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
                    } else {
                        UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
                    }
                    DispatchQueue.global().async {
                        if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptCCRoomInvite(l_pin: pin, type: 0, ticket_id: id)) {
                            if result.isOk() {
                                return
                            }
                        }
                    }
                    return
                }
                if channel == "2" {
                    var permissionCheck = -1
                    if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
                        permissionCheck = 1
                    } else if AVCaptureDevice.authorizationStatus(for: .video) ==  .denied {
                        permissionCheck = 0
                    } else {
                        Nexilis.dispatch = DispatchGroup()
                        Nexilis.dispatch?.enter()
                        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) -> Void in
                            if granted == true {
                                permissionCheck = 1
                            } else {
                                permissionCheck = 0
                            }
                            if let dispatch = Nexilis.dispatch {
                                dispatch.leave()
                            }
                        })
                        Nexilis.dispatch?.wait()
                        Nexilis.dispatch = nil
                    }
                    
                    if permissionCheck == 0 {
                        let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow camera permission in your settings".localized(), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: { _ in
                            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        }))
                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                            UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
                        } else {
                            UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
                        }
                        DispatchQueue.global().async {
                            if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptCCRoomInvite(l_pin: pin, type: 0, ticket_id: id)) {
                                if result.isOk() {
                                    return
                                }
                            }
                        }
                        return
                    }
                }
                if UIApplication.shared.visibleViewController is UINavigationController {
                    let nc = UIApplication.shared.visibleViewController as! UINavigationController
                    if nc.visibleViewController is QmeraStreamingViewController {
                        let vc = nc.visibleViewController as! QmeraStreamingViewController
                        var alert = LibAlertController(title: "", message: "Are you sure you want to end Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                        if !vc.isLive {
                            alert = LibAlertController(title: "", message: "Are you sure you want to leave Live Streaming, and open notification?".localized(), preferredStyle: .alert)
                        }
                        alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: { _ in
                            DispatchQueue.global().async {
                                if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptCCRoomInvite(l_pin: pin, type: 0, ticket_id: id)) {
                                    if result.isOk() {
                                        return
                                    }
                                }
                            }
                            alert.dismiss(animated: true, completion: nil)
                        }))
                        alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: { _ in
                            DispatchQueue.global().async {
                                API.terminateBC(sBroadcasterID: vc.isLive ? nil : vc.data)
                                vc.sendLeft()
                            }
                            vc.dismiss(animated: true, completion: {
                                acceptCC()
                            })
                        }))
                        nc.present(alert, animated: true, completion: nil)
                    } else if nc.visibleViewController is SeminarViewController {
                        let vc = nc.visibleViewController as! SeminarViewController
                        var alert = LibAlertController(title: "", message: "Are you sure you want to end Seminar, and open notification?".localized(), preferredStyle: .alert)
                        if !vc.isLive {
                            alert = LibAlertController(title: "", message: "Are you sure you want to leave Seminar, and open notification?".localized(), preferredStyle: .alert)
                        }
                        alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: { _ in
                            DispatchQueue.global().async {
                                if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptCCRoomInvite(l_pin: pin, type: 0, ticket_id: id)) {
                                    if result.isOk() {
                                        return
                                    }
                                }
                            }
                            alert.dismiss(animated: true, completion: nil)
                        }))
                        alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: { _ in
                            DispatchQueue.global().async {
                                API.terminateBC(sBroadcasterID: vc.isLive ? nil : vc.data)
                                vc.sendLeft()
                            }
                            vc.dismiss(animated: true, completion: {
                                acceptCC()
                            })
                        }))
                        nc.present(alert, animated: true, completion: nil)
                    } else {
                        acceptCC()
                    }
                } else {
                    acceptCC()
                }
                func acceptCC() {
                    APIS.isHasFormCS = false
                    DispatchQueue.global().async {
                        if let result = Nexilis.writeSync(message: CoreMessage_TMessageBank.acceptCCRoomInvite(l_pin: pin, type: 1, ticket_id: id)) {
                            if result.isOk() {
                                let requester = result.getBody(key: CoreMessage_TMessageKey.UPLINE_PIN)
                                let officer = result.getBody(key: CoreMessage_TMessageKey.FRIEND_FPIN)
                                let data = result.getBody(key: CoreMessage_TMessageKey.DATA)
                                let complaintId = id
                                SecureUserDefaults.shared.set("\(requester),\(officer),\(complaintId)", forKey: "onGoingCC")
                                SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: "startTimeCC")
                                if !data.isEmpty {
                                    if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                                        var members = ""
                                        var user : [User] = []
                                        let idMe = User.getMyPin()!
                                        
                                        for json in jsonArray {
                                            if "\(json)" != idMe {
                                                if let userData = User.getDataCanNil(pin: "\(json)") {
                                                    user.append(userData)
                                                } else {
                                                    Nexilis.addFriendSilent(fpin: "\(json)")
                                                    while User.getDataCanNil(pin: "\(json)") == nil {
                                                        Thread.sleep(forTimeInterval: 0.5)
                                                    }
                                                    if let userData = User.getData(pin: "\(json)") {
                                                        user.append(userData)
                                                    }
                                                }
                                                if members.isEmpty {
                                                    members = "\(json)"
                                                } else {
                                                    members += ",\(json)"
                                                }
                                            }
                                        }
                                        SecureUserDefaults.shared.set("\(members)", forKey: "membersCC")
                                        DispatchQueue.main.async {
                                            if channel == "0" {
                                                let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                                                editorPersonalVC.hidesBottomBarWhenPushed = true
                                                editorPersonalVC.unique_l_pin = officer
                                                editorPersonalVC.fromNotification = true
                                                editorPersonalVC.isContactCenter = true
                                                editorPersonalVC.fPinContacCenter = members
                                                editorPersonalVC.complaintId = complaintId
                                                editorPersonalVC.onGoingCC = true
                                                editorPersonalVC.isRequestContactCenter = false
                                                editorPersonalVC.users = user
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
                                            } else {
                                                SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: "startTimeCC")
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                                    if channel == "1" {
                                                        let pin = officer
                                                        let controller = QmeraAudioViewController()
                                                        controller.user = User.getData(pin: pin)
                                                        controller.isOutgoing = false
                                                        controller.ticketId = complaintId
                                                        controller.modalPresentationStyle = .overCurrentContext
                                                        let navigationController = CustomNavigationController(rootViewController: controller)
                                                        navigationController.modalPresentationStyle = .fullScreen
                                                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                                                            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                                                        } else {
                                                            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                                                        }
                                                    } else if channel == "2" {
                                                        let videoVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
                                                        videoVC.fPin = officer
                                                        videoVC.users.append(User.getData(pin: officer)!)
                                                        videoVC.ticketId = complaintId
                                                        videoVC.isInisiator = false
                                                        videoVC.isAutoAccept = true
                                                        let navigationController = CustomNavigationController(rootViewController: videoVC)
                                                        navigationController.modalPresentationStyle = .fullScreen
                                                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                                                            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                                                        } else {
                                                            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                                                        }
                                                    }
                                                })
                                            }
                                        }
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Call Center Session has ended".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                                    banner.show()
                                }
                            }
                        }
                    }
                }
            })
            alert.addAction(rejectAction)
            alert.addAction(acceptAction)
            
            let containerView = UIView(frame: CGRect(x: 50, y: 80, width: alert.view.bounds.size.width * 0.9 - 100, height: 150))
            alert.view.addSubview(containerView)
            containerView.layer.cornerRadius = 10.0
            containerView.clipsToBounds = true
            containerView.backgroundColor = .secondaryColor.withAlphaComponent(0.5)
            
            let imageProfile = UIImageView()
            containerView.addSubview(imageProfile)
            imageProfile.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageProfile.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
                imageProfile.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
                imageProfile.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
                imageProfile.widthAnchor.constraint(equalToConstant: 100)
            ])
            imageProfile.layer.cornerRadius = 10.0
            imageProfile.clipsToBounds = true
            imageProfile.backgroundColor = .lightGray.withAlphaComponent(0.3)
            imageProfile.tintColor = .secondaryColor
            imageProfile.image = UIImage(systemName: "person")
            imageProfile.setImage(name: thumbInvited)
            imageProfile.contentMode = .scaleAspectFill
            
            let labelName = UILabel()
            containerView.addSubview(labelName)
            labelName.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                labelName.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
                labelName.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
            ])
            labelName.font = UIFont.systemFont(ofSize: 12)
            labelName.text = "Name".localized()
            labelName.textColor = .mainColor
            
            let valueName = UILabel()
            containerView.addSubview(valueName)
            valueName.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                valueName.topAnchor.constraint(equalTo: labelName.bottomAnchor),
                valueName.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
            ])
            valueName.font = UIFont.systemFont(ofSize: 12)
            valueName.text = nameInvited
            valueName.textColor = .mainColor
            
            let labelType = UILabel()
            containerView.addSubview(labelType)
            labelType.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                labelType.topAnchor.constraint(equalTo: valueName.bottomAnchor, constant: 5),
                labelType.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
            ])
            labelType.font = UIFont.systemFont(ofSize: 12)
            labelType.text = "Request Type".localized()
            labelType.textColor = .mainColor
            
            let valueType = UILabel()
            containerView.addSubview(valueType)
            valueType.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                valueType.topAnchor.constraint(equalTo: labelType.bottomAnchor),
                valueType.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
            ])
            valueType.font = UIFont.systemFont(ofSize: 12)
            if channel == "0" {
                valueType.text = "Chat".localized()
            } else if channel == "1" {
                valueType.text = "Audio Call".localized()
            } else if channel == "2" {
                valueType.text = "Video Call".localized()
            } else {
                valueType.text = "Email".localized()
            }
            valueType.textColor = .mainColor
            
            let labelIdentity = UILabel()
            containerView.addSubview(labelIdentity)
            labelIdentity.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                labelIdentity.topAnchor.constraint(equalTo: valueType.bottomAnchor, constant: 5),
                labelIdentity.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5)
            ])
            labelIdentity.font = UIFont.systemFont(ofSize: 12)
            labelIdentity.text = "Complaint ID".localized()
            labelIdentity.textColor = .mainColor
            
            let valueIdentity = UILabel()
            containerView.addSubview(valueIdentity)
            valueIdentity.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                valueIdentity.topAnchor.constraint(equalTo: labelIdentity.bottomAnchor),
                valueIdentity.leadingAnchor.constraint(equalTo: imageProfile.trailingAnchor, constant: 5),
                valueIdentity.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
            valueIdentity.font = UIFont.systemFont(ofSize: 12)
            valueIdentity.text = id
            valueIdentity.numberOfLines = 0
            valueIdentity.textColor = .mainColor
            
            if UIApplication.shared.visibleViewController?.navigationController != nil {
                UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
            } else {
                UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    public func onReceive(message: TMessage) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil, userInfo: dataMessage)
        if message.getCode() == CoreMessage_TMessageCode.PUSH_CALL_CENTER {
            Nexilis.viewFormCS(pin: message.getBody(key: CoreMessage_TMessageKey.L_PIN), channel: message.getBody(key: CoreMessage_TMessageKey.CHANNEL), displayName: message.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME), thumb: message.getBody(key: CoreMessage_TMessageKey.THUMB_ID), id: message.getBody(key: CoreMessage_TMessageKey.DATA))
        } else if message.getCode() == CoreMessage_TMessageCode.ACCEPT_CALL_CENTER {
            let fPinContacCenter = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
            let requester = message.getBody(key: CoreMessage_TMessageKey.UPLINE_PIN)
            let complaintId = message.getBody(key: CoreMessage_TMessageKey.DATA)
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            if !requester.isEmpty && onGoingCC.isEmpty {
                SecureUserDefaults.shared.set("\(requester),\(fPinContacCenter),\(complaintId)", forKey: "onGoingCC")
                SecureUserDefaults.shared.set("\(fPinContacCenter)", forKey: "membersCC")
            }
        } else if message.getCode() == CoreMessage_TMessageCode.INVITE_TO_ROOM_CONTACT_CENTER {
            if listCCIdInv.contains(message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID)) {
                return
            }
            listCCIdInv.append(message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID))
            if !APIS.isHasFormCS {
                Nexilis.viewFormCSInvited(pin: message.getPIN(), channel: message.getBody(key: CoreMessage_TMessageKey.CHANNEL), id: message.getBody(key: CoreMessage_TMessageKey.CALL_CENTER_ID), nameInvited: message.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME), thumbInvited: message.getBody(key: CoreMessage_TMessageKey.THUMB_ID))
            }
        } else if message.getCode() != CoreMessage_TMessageCode.PUSH_CALL_CENTER && message.getCode() != CoreMessage_TMessageCode.ACCEPT_CALL_CENTER && message.getCode() != CoreMessage_TMessageCode.END_CALL_CENTER && message.getCode() != CoreMessage_TMessageCode.TIMEOUT_CONTACT_CENTER && message.getCode() != CoreMessage_TMessageCode.ACCEPT_CONTACT_CENTER && message.getCode() != CoreMessage_TMessageCode.PUSH_MEMBER_ROOM_CONTACT_CENTER && message.getCode() != CoreMessage_TMessageCode.INVITE_END_CONTACT_CENTER && message.getCode() != CoreMessage_TMessageCode.INVITE_EXIT_CONTACT_CENTER || !message.getBody(key: CoreMessage_TMessageKey.MERCHANT_NAME).isEmpty {
            let m = message.mBodies
            if !message.getBody(key: CoreMessage_TMessageKey.MERCHANT_NAME).isEmpty {
//                Utils.setDebugBC(value: m)
                DispatchQueue.main.async {
                    if !Nexilis.broadcastList.isEmpty {
                        Nexilis.broadcastList.append(m)
                    } else {
                        Nexilis.broadcastList.append(m)
                        Nexilis.shared.showBroadcastMessage(m: m)
                    }
                }
                return
            }
            if !Nexilis.showLibraryNotification || APIS.checkAppStateisBackground() || APIS.stopNotif {
                return
            }
            let sender = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
            let me = User.getMyPin()!
            if(sender != me) {
                let inEditorPersonal: String? = SecureUserDefaults.shared.value(forKey: "inEditorPersonal") ?? nil
                let inEditorGroup: [String]? = SecureUserDefaults.shared.value(forKey: "inEditorGroup") ?? nil
                var text = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_TEXT)
                let imageId = CoreMessage_TMessageKey.IMAGE_ID
                let videoId = CoreMessage_TMessageKey.VIDEO_ID
                let fileId = CoreMessage_TMessageKey.FILE_ID
                let audioId = CoreMessage_TMessageKey.AUDIO_ID
                let attachmentFlag = CoreMessage_TMessageKey.ATTACHMENT_FLAG
                let messageScopeId = CoreMessage_TMessageKey.MESSAGE_SCOPE_ID
                let messageText = CoreMessage_TMessageKey.MESSAGE_TEXT
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
                    if message.getBody(key: messageScopeId) == MessageScope.FORM {
                        text = "Sent Form 📄"
                    } else {
                        text = "Sent File 📄"
                    }
                } else if !message.getBody(key: audioId).isEmpty {
                    text = "Sent Audio ♫"
                } else if message.getBody(key: messageText).contains("Share%20location%20") {
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
                var nameUser: String?
                var profile = ""
                var threadIdentifier = sender
                let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                if !onGoingCC.isEmpty {
                    return
                }
//                if Utils.inTabChats{
//                    return
//                }
                if message.getBody(key: messageScopeId) == MessageScope.WHISPER || message.getBody(key: messageScopeId) == MessageScope.FORM || message.getBody(key: messageScopeId) == MessageScope.CHATROOM {
                    if inEditorPersonal == sender || (inEditorPersonal != nil && inEditorPersonal!.contains(",")) {
                        return
                    }
                    if(nameUser == nil) {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT first_name, last_name, image_id FROM BUDDY WHERE f_pin='\(String(describing: sender))'") {
                                    while cursor.next() {
                                        let first_name = cursor.string(forColumnIndex: 0)!
                                        let last_name = cursor.string(forColumnIndex: 1)!
                                        nameUser = "\(first_name) \(last_name)".trimmingCharacters(in: .whitespaces)
                                        profile = cursor.string(forColumnIndex: 2)!
                                    }
                                    cursor.close()
                                }
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                } else {
                    let idGroup =  message.getBody(key: CoreMessage_TMessageKey.L_PIN)
                    var topicGroup: String?
                    var idTopic: String?
                    if !message.getBody(key: CoreMessage_TMessageKey.CHAT_ID).isEmpty {
                        idTopic = message.getBody(key: CoreMessage_TMessageKey.CHAT_ID)
                    }
                    if (idTopic == nil) {
                        idTopic = "Lounge"
                        topicGroup = "Lounge"
                    } else {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT title FROM DISCUSSION_FORUM WHERE chat_id='\(idTopic!)'") {
                                    while cursor.next() {
                                        let title = cursor.string(forColumnIndex: 0)
                                        topicGroup = title
                                    }
                                    cursor.close()
                                }
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                    if (inEditorGroup != nil) {
                        let editorIdGroup = inEditorGroup![0]
                        let editorIdTopic = inEditorGroup![1]
                        var idTempTopic = idTopic
                        if (idTempTopic == "Lounge") {
                            idTempTopic = ""
                        }
                        if (editorIdGroup == idGroup && editorIdTopic == idTempTopic) {
                            return
                        }
                    }
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_name, image_id FROM GROUPZ WHERE group_id='\(idGroup)'") {
                                while cursor.next() {
                                    let f_name = cursor.string(forColumnIndex: 0)
                                    var senderName = message.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME)
                                    if senderName.isEmpty {
                                        senderName = "Bot"
                                    }
                                    nameUser =
                                    "\(senderName) \u{2022} \(f_name!)(\(topicGroup!))"
                                    profile = cursor.string(forColumnIndex: 1)!
                                }
                                cursor.close()
                            }
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                    if idTopic == "Lounge" {
                        threadIdentifier = idGroup
                    } else {
                        threadIdentifier = idTopic!
                    }
                }
                if nameUser == nil && threadIdentifier == "-999" {
                    nameUser = "Bot"
                }
                DispatchQueue.main.async { [self] in
                    let container = UIView()
                    container.backgroundColor = .gray
                    let profileImage = UIImageView()
                    profileImage.frame.size = CGSize(width: 60, height: 60)
                    container.addSubview(profileImage)
                    profileImage.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        profileImage.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8.0),
                        profileImage.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                        profileImage.widthAnchor.constraint(equalToConstant: 60),
                        profileImage.heightAnchor.constraint(equalToConstant: 60),
                    ])
                    
                    let title = UILabel()
                    container.addSubview(title)
                    title.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        title.leadingAnchor.constraint(equalTo: profileImage.trailingAnchor, constant: 8.0),
                        title.topAnchor.constraint(equalTo: container.topAnchor, constant: 20.0),
                    ])
                    title.font = UIFont.systemFont(ofSize: 14)
                    title.text = nameUser ?? "Unknown"
                    title.textColor = .white
                    
                    let subtitle = UILabel()
                    container.addSubview(subtitle)
                    subtitle.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        subtitle.leadingAnchor.constraint(equalTo: profileImage.trailingAnchor, constant: 8.0),
                        subtitle.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15.0),
                        subtitle.topAnchor.constraint(equalTo: title.bottomAnchor),
                    ])
                    subtitle.font = UIFont.systemFont(ofSize: 12)
                    subtitle.attributedText = text.richText()
                    subtitle.textColor = .white
                    
                    if floating != nil {
                        return
                    }
                    
                    if UIApplication.shared.visibleViewController is UINavigationController {
                        let nc = UIApplication.shared.visibleViewController as! UINavigationController
                        if nc.visibleViewController is QmeraStreamingViewController {
                            return
                        } else if nc.visibleViewController is SeminarViewController {
                            return
                        }
                    }
                    if UIApplication.shared.visibleViewController is UIAlertController {
                        return
                    }
                    
                    displayNotif()
                    
                    func displayNotif() {
                        floating = FloatingNotificationBanner(customView: container)
                        floating.bannerHeight = UIScreen.main.bounds.height / 6 - 10
                        floating.transparency = 0.9
                        
                        if threadIdentifier == "-999" {
                            if !Utils.getIconDock().isEmpty {
                                let dataImage = try? Data(contentsOf: URL(string: Utils.getUrlDock()!)!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                                if dataImage != nil {
                                    profileImage.image = UIImage(data: dataImage!)
                                }
                            } else {
                                profileImage.image = UIImage(named: "pb_button", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                            }
                        } else if profile != "" {
                            profileImage.circle()
                            do {
                                let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                let file = documentDir.appendingPathComponent(profile)
                                if FileManager().fileExists(atPath: file.path) {
                                    profileImage.image = UIImage(contentsOfFile: file.path)
                                    profileImage.backgroundColor = .clear
                                } else if FileEncryption.shared.isSecureExists(filename: profile) {
                                    do {
                                        if var data = try FileEncryption.shared.readSecure(filename: profile) {
                                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                            if dataDecrypt != nil {
                                                data = dataDecrypt!
                                            }
                                            profileImage.image = UIImage(data: data)
                                            profileImage.backgroundColor = .clear
                                        }
                                    } catch {
                                        
                                    }
                                } else {
                                    Download().startHTTP(forKey: profile) { (name, progress) in
                                        guard progress == 100 else {
                                            return
                                        }
                                        
                                        DispatchQueue.main.async { [self] in
                                            if FileEncryption.shared.isSecureExists(filename: profile) {
                                                do {
                                                    if var data = try FileEncryption.shared.readSecure(filename: profile) {
                                                        let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                                        if dataDecrypt != nil {
                                                            data = dataDecrypt!
                                                        }
                                                        profileImage.image = UIImage(data: data)
                                                        profileImage.backgroundColor = .clear
                                                    }
                                                } catch {
                                                    
                                                }
                                            }
                                            if !onGoingCC.isEmpty {
                                                floating.autoDismiss = false
                                            }
                                            floating.show(queuePosition: .front, bannerPosition: .top, queue: NotificationBannerQueue(maxBannersOnScreenSimultaneously: 1), on: nil, edgeInsets: UIEdgeInsets(top: 8.0, left: 8.0, bottom: 0, right: 8.0), cornerRadius: 8.0, shadowColor: .clear, shadowOpacity: .zero, shadowBlurRadius: .zero, shadowCornerRadius: .zero, shadowOffset: .zero, shadowEdgeInsets: nil)
                                            floating.onTap = {
                                                self.floating = nil
                                                showNotif()
                                            }
                                            var soundId: String = SecureUserDefaults.shared.value(forKey: "newNotifSoundPersonal") ?? "001:Nexilis Message (Default)"
                                            if message.getBody(key: CoreMessage_TMessageKey.MESSAGE_SCOPE_ID) == MessageScope.GROUP {
                                                soundId = SecureUserDefaults.shared.value(forKey: "newNotifSoundGroup") ?? "001:Nexilis Message (Default)"
                                            }
                                            do {
                                                var nameSound = soundId.component(1, separatedBy: ":").replacingOccurrences(of: " ", with: "_")
                                                var fromPref = false
                                                if nameSound.contains("_(Default)") {
                                                    if !Utils.getDefaultIncomingMsg().isEmpty {
                                                        nameSound = Utils.getDefaultIncomingMsg()
                                                        fromPref = true
                                                    } else {
                                                        nameSound = nameSound.replacingOccurrences(of: "_(Default)", with: "")
                                                    }
                                                }
                                                var soundURL: URL?
                                                if fromPref {
                                                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                                    if let dirPath = paths.first {
                                                        let audioURL = URL(fileURLWithPath: dirPath).appendingPathComponent(nameSound)
                                                        if !FileManager.default.fileExists(atPath: audioURL.path) && !FileEncryption.shared.isSecureExists(filename: nameSound) {
                                                            Download().startHTTP(forKey: nameSound,downloadUrl: Utils.getURLBase() + "filepalio/ringtone/") { (name, progress) in
                                                                guard progress == 100 else {
                                                                    return
                                                                }
                                                                playAudio()
                                                            }
                                                        } else {
                                                            playAudio()
                                                        }
                                                        
                                                        func playAudio() {
                                                            if FileManager.default.fileExists(atPath: audioURL.path) {
                                                                do {
                                                                    do {
                                                                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                                                                        try AVAudioSession.sharedInstance().setActive(true)
                                                                    } catch {
                                                                        
                                                                    }
                                                                    Nexilis.sharedAudioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                                                                    Nexilis.sharedAudioPlayer?.prepareToPlay()
                                                                    Nexilis.sharedAudioPlayer?.play()
                                                                } catch {
                                                                    
                                                                }
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
                                                                        do {
                                                                            do {
                                                                                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                                                                                try AVAudioSession.sharedInstance().setActive(true)
                                                                            } catch {
                                                                                
                                                                            }
                                                                            Nexilis.sharedAudioPlayer = try AVAudioPlayer(contentsOf: tempPath)
                                                                            Nexilis.sharedAudioPlayer?.prepareToPlay()
                                                                            Nexilis.sharedAudioPlayer?.play()
                                                                        } catch {
                                                                            
                                                                        }
                                                                    }
                                                                } catch {
                                                                    
                                                                }
                                                            }
                                                        }
                                                    }
                                                } else {
                                                    soundURL = Bundle.resourceBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
                                                    if soundURL == nil {
                                                        soundURL = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
                                                    }
                                                    do {
                                                        do {
                                                            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                                                            try AVAudioSession.sharedInstance().setActive(true)
                                                        } catch {
                                                            
                                                        }
                                                        Nexilis.sharedAudioPlayer = try AVAudioPlayer(contentsOf: soundURL!)
                                                        Nexilis.sharedAudioPlayer?.prepareToPlay()
                                                        Nexilis.sharedAudioPlayer?.play()
                                                    } catch {
                                                        
                                                    }
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                                                    self.floating = nil
                                                })
                                            } catch {
                                                
                                            }
                                        }
                                    }
                                    return
                                }
                            } catch {}
                            profileImage.contentMode = .scaleAspectFill
                        } else {
                            profileImage.circle()
                            if message.getBody(key: messageScopeId) == MessageScope.WHISPER {
                                profileImage.image = UIImage(systemName: "person")
                            } else {
                                profileImage.image = UIImage(systemName: "person.3")
                            }
                            profileImage.contentMode = .scaleAspectFit
                            profileImage.backgroundColor = .lightGray
                            profileImage.tintColor = .white
                        }
                        
                        floating.show(queuePosition: .front, bannerPosition: .top, queue: NotificationBannerQueue(maxBannersOnScreenSimultaneously: 1), on: nil, edgeInsets: UIEdgeInsets(top: 8.0, left: 8.0, bottom: 0, right: 8.0), cornerRadius: 8.0, shadowColor: .clear, shadowOpacity: .zero, shadowBlurRadius: .zero, shadowCornerRadius: .zero, shadowOffset: .zero, shadowEdgeInsets: nil)
    //                    let vibrateMode: Bool = SecureUserDefaults.shared.value(forKey: "vibrateMode") ?? false
                        var soundId: String = SecureUserDefaults.shared.value(forKey: "newNotifSoundPersonal") ?? "001:Nexilis Message (Default)"
                        if message.getBody(key: CoreMessage_TMessageKey.MESSAGE_SCOPE_ID) == MessageScope.GROUP {
                            soundId = SecureUserDefaults.shared.value(forKey: "newNotifSoundGroup") ?? "001:Nexilis Message (Default)"
                        }
                        do {
                            var nameSound = soundId.component(1, separatedBy: ":").replacingOccurrences(of: " ", with: "_")
                            var fromPref = false
                            if nameSound.contains("_(Default)") {
                                if !Utils.getDefaultIncomingMsg().isEmpty {
                                    nameSound = Utils.getDefaultIncomingMsg()
                                    fromPref = true
                                } else {
                                    nameSound = nameSound.replacingOccurrences(of: "_(Default)", with: "")
                                }
                            }
                            var soundURL: URL?
                            if fromPref {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let audioURL = URL(fileURLWithPath: dirPath).appendingPathComponent(nameSound)
                                    if !FileManager.default.fileExists(atPath: audioURL.path) && !FileEncryption.shared.isSecureExists(filename: nameSound) {
                                        Download().startHTTP(forKey: nameSound,downloadUrl: Utils.getURLBase() + "filepalio/ringtone/") { (name, progress) in
                                            guard progress == 100 else {
                                                return
                                            }
                                            playAudio()
                                        }
                                    } else {
                                        playAudio()
                                    }
                                    
                                    func playAudio() {
                                        if FileManager.default.fileExists(atPath: audioURL.path) {
                                            do {
                                                do {
                                                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                                                    try AVAudioSession.sharedInstance().setActive(true)
                                                } catch {
                                                    
                                                }
                                                Nexilis.sharedAudioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                                                Nexilis.sharedAudioPlayer?.prepareToPlay()
                                                Nexilis.sharedAudioPlayer?.play()
                                            } catch {
                                                
                                            }
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
                                                    do {
                                                        do {
                                                            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                                                            try AVAudioSession.sharedInstance().setActive(true)
                                                        } catch {
                                                            
                                                        }
                                                        Nexilis.sharedAudioPlayer = try AVAudioPlayer(contentsOf: tempPath)
                                                        Nexilis.sharedAudioPlayer?.prepareToPlay()
                                                        Nexilis.sharedAudioPlayer?.play()
                                                    } catch {
                                                        
                                                    }
                                                }
                                            } catch {
                                                
                                            }
                                        }
                                    }
                                }
                            } else {
                                soundURL = Bundle.resourceBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
                                if soundURL == nil {
                                    soundURL = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: nameSound, withExtension: "mp3")
                                }
                                do {
                                    do {
                                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                                        try AVAudioSession.sharedInstance().setActive(true)
                                    } catch {
                                        
                                    }
                                    Nexilis.sharedAudioPlayer = try AVAudioPlayer(contentsOf: soundURL!)
                                    Nexilis.sharedAudioPlayer?.prepareToPlay()
                                    Nexilis.sharedAudioPlayer?.play()
                                } catch {
                                    
                                }
                            }
                        } catch {
                            
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                            self.floating = nil
                        })
//                        if !onGoingCC.isEmpty {
//                            floating.autoDismiss = false
//                        }
                        floating.onTap = {
                            self.floating = nil
                            showNotif()
                        }
                    }
                    func showNotif() {
                        if UIApplication.shared.visibleViewController is UINavigationController {
                            let nc = UIApplication.shared.visibleViewController as! UINavigationController
                            if nc.visibleViewController is QmeraStreamingViewController {
                                return
                            } else if nc.visibleViewController is SeminarViewController {
                                return
                            }
                            if let navigationC = UIApplication.shared.visibleViewController as? UINavigationController {
                                if navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorPersonal || navigationC.viewControllers[navigationC.viewControllers.count - 1] is EditorGroup {
                                    navigationC.popViewController(animated: true)
                                }
                            }
                        } else if UIApplication.shared.visibleViewController is UIAlertController {
                            return
                        }
                        if message.getBody(key: attachmentFlag) == "59" {
                            let date = Date(milliseconds: Int64(message.getBody(key: CoreMessage_TMessageKey.LOCAL_TIMESTAMP))!)
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                            var timeSignIn = formatter.string(from: date as Date)
                            
                            let dialog = DialogSignIn()
                            dialog.valueDevice = message.getBody(key: CoreMessage_TMessageKey.DEVICE_BRAND)
                            dialog.valueTime = timeSignIn
                            dialog.valueLocation = message.getBody(key: CoreMessage_TMessageKey.PLACE_NAME)
                            dialog.valueToken = message.getBody(key: CoreMessage_TMessageKey.TOKEN)
                            dialog.valueUser = message.getBody(key: CoreMessage_TMessageKey.USER_ID)
                            dialog.modalTransitionStyle = .crossDissolve
                            dialog.modalPresentationStyle = .overCurrentContext
                            UIApplication.shared.visibleViewController?.present(dialog, animated: true)
                            return
                        }
                        if !onGoingCC.isEmpty {
                            floating.dismiss()
                        }
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT first_name, last_name FROM BUDDY where f_pin = '\(User.getMyPin()!)'"), cursorData.next() {
                                    if (cursorData.string(forColumnIndex: 0)! + " " + cursorData.string(forColumnIndex: 1)!).trimmingCharacters(in: .whitespaces) == "USR\(User.getMyPin()!)" {
                                        let alert = LibAlertController(title: "Set Profile".localized(), message: "You must set your profile to use this feature".localized(), preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                                            guard let controller = APIS.getControllerSign() else { return }
                                            if let controller = controller as? SignUpSignIn {
                                                controller.forceLogin = true
                                            } else if let controller = controller as? SignInOption {
                                                controller.forceLogin = true
                                            }
                                            let navigationController = CustomNavigationController(rootViewController: controller)
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
                                        }))
                                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                                            UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
                                        } else {
                                            UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
                                        }
                                    }
                                    cursorData.close()
                                    return
                                }
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                        if message.getBody(key: messageScopeId) == MessageScope.WHISPER || message.getBody(key: messageScopeId) == MessageScope.FORM || message.getBody(key: messageScopeId) == MessageScope.CHATROOM {
                            let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                            editorPersonalVC.hidesBottomBarWhenPushed = true
                            editorPersonalVC.unique_l_pin = threadIdentifier
                            editorPersonalVC.fromNotification = true
                            if !onGoingCC.isEmpty {
                                let compalintId = onGoingCC.component(2, separatedBy: ",")
                                let fPinCC = onGoingCC.isEmpty ? "" : onGoingCC.component(1, separatedBy: ",")
                                editorPersonalVC.isContactCenter = true
                                editorPersonalVC.fPinContacCenter = fPinCC
                                editorPersonalVC.complaintId = compalintId
                                editorPersonalVC.onGoingCC = true
                                editorPersonalVC.isRequestContactCenter = false
                            }
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
                        } else {
                            let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "editorGroupVC") as! EditorGroup
                            editorGroupVC.hidesBottomBarWhenPushed = true
                            editorGroupVC.unique_l_pin = threadIdentifier
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
                        }
                    }
                }
            }
        }
    }
    
    public static func addFriend(fpin: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getAddFriendQRCode(fpin: fpin)), response.isOk() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    public static func addFriendSilent(fpin: String) {
        DispatchQueue.global().async {
            _ = Nexilis.write(message: CoreMessage_TMessageBank.getAddFriendQRCodeSilent(fpin: fpin))
        }
    }
    
    public func onReceive(message: [AnyHashable : Any?]) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil, userInfo: dataMessage)
    }
    
    public func onMessage(message: TMessage) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.listenerStatusChat), object: nil, userInfo: dataMessage)
    }
    
    public func onUpload(name: String, progress: Double) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["name"] = name
        dataMessage["progress"] = progress
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onUploadChat"), object: nil, userInfo: dataMessage)
    }
    
    public func onTyping(message: TMessage) {
        var dataMessage: [AnyHashable : Any] = [:]
        dataMessage["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.listenerTypingChat), object: nil, userInfo: dataMessage)
    }
    
//    public static func faceDetect(fd: FaceDetector?,image: UIImage, completion: ((Bool) -> ())?){
//        //print("enter vision")
//        let visionImage = VisionImage(image: image)
//        //print("exit vision")
//        var retval = false
//        visionImage.orientation = image.imageOrientation
//        var fd1 : FaceDetector?
//        if(fd == nil){
//            fd1 = FaceDetector.faceDetector()
//        }
//        else {
//            fd1 = fd
//        }
//
//        // [START detect_faces]
//        fd1?.process(visionImage) {faces, error in
//            guard error == nil, let faces = faces, !faces.isEmpty else {
//              //print("faces empty")
//                completion?(false)
//                return
//            }
//            if(faces.count > 0){
//                //print("face count: \(faces.count)")
//                retval = true
//            }
//            completion?(retval)
//        }
//
//    }
}

extension Nexilis: GroupDelegate {
    public func onGroup(code: String, f_pin: String, groupId: String) {
        var data: [AnyHashable : Any] = [:]
        data["code"] = code
        data["f_pin"] = f_pin
        data["groupId"] = groupId
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onGroup"), object: nil, userInfo: data)
    }
    
    public func onTopic(code: String, f_pin: String, topicId: String) {
        var data: [AnyHashable : Any] = [:]
        data["code"] = code
        data["f_pin"] = f_pin
        data["topicId"] = topicId
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onTopic"), object: nil, userInfo: data)
    }
    
    public func onMember(code: String, f_pin: String, groupId: String, member: String) {
        var data: [AnyHashable : Any] = [:]
        data["code"] = code
        data["f_pin"] = f_pin
        data["groupId"] = groupId
        data["member"] = member
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onMember"), object: nil, userInfo: data)
    }
    
    
}

extension Nexilis: PersonInfoDelegate {
    public func onUpdatePersonInfo(state: Int, message: String) {
        var data: [AnyHashable : Any] = [:]
        data["state"] = state
        data["message"] = message
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onUpdatePersonInfo"), object: nil, userInfo: data)
    }
}

extension Nexilis: QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return previewItem!
    }
}

public class SelfSignedURLSessionDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            }
        }
    }
}

final class PinnedURLSessionNexilisDelegate: NSObject,
    URLSessionTaskDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                   URLCredential?) -> Void) {

        guard challenge.protectionSpace.authenticationMethod
                == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        var cfError: CFError?
        guard SecTrustEvaluateWithError(trust, &cfError) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Fix: every branch below must call completionHandler exactly once and then
        // return. Previously, each branch already called completionHandler, but
        // execution still fell through to an unconditional final call
        // (`completionHandler(.useCredential, URLCredential(trust: trust))`) - that's
        // the "completion handler called more than once" API misuse. Worse, when JSON
        // parsing of the stored pin failed there was no else-branch at all, so the
        // *only* call that ran was that unconditional final one - meaning a corrupted/
        // unparseable pin silently bypassed pinning entirely (fail-open) instead of
        // rejecting the connection (fail-closed).
        guard let publicKeyHash = extractPublicKeyHash(from: serverTrust) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let domain = challenge.protectionSpace.host
        let storedCertificate = Utils.getCertificatePinningWebview()
        guard let jsonData = storedCertificate.data(using: .utf8) else {
            // Fix: fail closed - don't trust the connection if the pin can't be read.
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Fix: support both the new format (domain -> array of accepted hashes, so a
        // certificate/key rotation can be handled by listing old+new hash together
        // ahead of time) and the legacy format (domain -> single hash string) still
        // possibly cached on a device from before this migration, so existing
        // installs don't get hard-locked-out mid-migration.
        let acceptedHashes: [String]
        if let certJsonArray = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: [String]] {
            acceptedHashes = certJsonArray[domain] ?? []
        } else if let certJsonLegacy = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] {
            acceptedHashes = certJsonLegacy[domain].map { [$0] } ?? []
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        if acceptedHashes.contains(publicKeyHash) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    // Fix: SecKeyCopyExternalRepresentation does NOT return the same bytes as
    // `openssl pkey -pubin -outform DER` (SubjectPublicKeyInfo). It returns just the
    // raw key material - PKCS#1 (modulus + exponent) for RSA, or a raw X9.63 point for
    // EC - with no ASN.1 "AlgorithmIdentifier" header. openssl hashes the FULL SPKI
    // (header + key), so hashing the raw bytes directly produces a hash that will
    // NEVER match a pin captured via openssl/browser dev tools/most pinning
    // generators, even when it's the exact correct certificate. This is a well known
    // iOS pinning pitfall (see TrustKit, OWASP Mobile Pinning Guide). Fix: detect the
    // key's type/size and prepend the matching DER header before hashing, so the
    // computed hash matches what `openssl ... | openssl dgst -sha256 | openssl base64`
    // produces.
    private static let rsa2048Asn1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]
    private static let rsa3072Asn1Header: [UInt8] = [
        0x30, 0x82, 0x01, 0xa2, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x8f, 0x00
    ]
    private static let rsa4096Asn1Header: [UInt8] = [
        0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00
    ]
    private static let ecDsaSecp256r1Asn1Header: [UInt8] = [
        0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
        0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00
    ]
    private static let ecDsaSecp384r1Asn1Header: [UInt8] = [
        0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
        0x01, 0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00
    ]

    private func spkiHeader(keyType: String, sizeInBits: Int) -> [UInt8]? {
        if keyType == (kSecAttrKeyTypeRSA as String) {
            switch sizeInBits {
            case 2048: return PinnedURLSessionNexilisDelegate.rsa2048Asn1Header
            case 3072: return PinnedURLSessionNexilisDelegate.rsa3072Asn1Header
            case 4096: return PinnedURLSessionNexilisDelegate.rsa4096Asn1Header
            default: return nil
            }
        } else if keyType == (kSecAttrKeyTypeECSECPrimeRandom as String) {
            switch sizeInBits {
            case 256: return PinnedURLSessionNexilisDelegate.ecDsaSecp256r1Asn1Header
            case 384: return PinnedURLSessionNexilisDelegate.ecDsaSecp384r1Asn1Header
            default: return nil
            }
        }
        return nil
    }

    func extractPublicKeyHash(from serverTrust: SecTrust) -> String? {
        guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else { return nil }
        guard let publicKey = SecCertificateCopyKey(certificate) else { return nil }

        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }

        guard let attributes = SecKeyCopyAttributes(publicKey) as? [CFString: Any],
              let keyType = attributes[kSecAttrKeyType] as? String,
              let sizeInBits = attributes[kSecAttrKeySizeInBits] as? Int,
              let header = spkiHeader(keyType: keyType, sizeInBits: sizeInBits) else {
            // Fix: unknown/unsupported key type or size - fail closed instead of
            // silently hashing the wrong (raw, non-SPKI) bytes and always mismatching.
            return nil
        }

        var spki = Data(header)
        spki.append(publicKeyData)

        // Compute SHA-256 hash of the reconstructed SubjectPublicKeyInfo, matching
        // what `openssl x509 -pubkey | openssl pkey -pubin -outform DER | openssl dgst -sha256` produces.
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        spki.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(spki.count), &hash)
        }

        let hashData = Data(hash)
        let base64Hash = hashData.base64EncodedString()

        return base64Hash
    }
}
