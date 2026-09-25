//
//  ShieldPush.swift
//  NexilisLite
//
//  Push notifications and VoIP for a host wrapped by the no-code shield, which has no AppDelegate
//  code of its own. A linked host does the same five things in its AppDelegate (see AppBuilder /
//  OneApp): ask for notification permission and register with APNs, hand the APNs token to
//  APIS.sendPushToken, register PushKit and hand its token to sendPushToken(isCall:), pass
//  incoming pushes to showNotificationNexilis / showNotificationCallKitNexilis, and pass a tapped
//  notification to openNotificationNexilis.
//
//  Installed from NXShieldAutostart at launch - before the ZTA chain and before the session:
//  iOS requires a VoIP push to be reported to CallKit at once, and an app woken by one that does
//  not do so is terminated and eventually stops receiving them. Tokens wait for the session
//  inside sendPushToken; showNotificationCallKitNexilis reports the call immediately.
//
//  The two UIApplicationDelegate callbacks APNs uses are added to the host's app delegate class
//  at runtime. A host (or a Flutter plugin) that already implements them keeps its own code: the
//  original runs first and is the one that completes the fetch handler.
//

import Foundation
import UIKit
import PushKit
import UserNotifications
import ObjectiveC
import NexilisZTA

final class ShieldPush: NSObject, PKPushRegistryDelegate, UNUserNotificationCenterDelegate {

    static let shared = ShieldPush()
    private var registry: PKPushRegistry?
    private var installed = false

    func install(notifications: Bool, voip: Bool) {
        guard !installed else { return }
        installed = true
        if voip {
            let registry = PKPushRegistry(queue: .main)
            registry.delegate = self
            registry.desiredPushTypes = [.voIP]
            self.registry = registry
            log("VoIP: PushKit terdaftar")
        }
        guard notifications else { return }
        hookAppDelegate()
        let center = UNUserNotificationCenter.current()
        if center.delegate == nil {
            center.delegate = self
        } else {
            log("notifikasi: delegate UNUserNotificationCenter sudah dipegang host - tap notifikasi diteruskan oleh host")
        }
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            self.log("notifikasi: izin \(granted ? "diberikan" : "ditolak")\(error.map { " (\($0.localizedDescription))" } ?? "")")
            guard granted else { return }
            DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
        }
    }

    // MARK: - PushKit

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        log("VoIP: token diterima")
        APIS.sendPushToken(Self.hex(pushCredentials.token), isCall: true)
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType, completion: @escaping () -> Void) {
        log("VoIP: push masuk")
        APIS.showNotificationCallKitNexilis(payload: payload.dictionaryPayload, completion: completion)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        APIS.openNotificationNexilis(response)
        completionHandler()
    }

    // MARK: - App delegate callbacks

    private typealias DidRegister = @convention(c) (AnyObject, Selector, UIApplication, Data) -> Void
    private typealias DidReceive = @convention(c) (AnyObject, Selector, UIApplication, NSDictionary,
                                                   @escaping @convention(block) (UInt) -> Void) -> Void

    private func hookAppDelegate() {
        guard let delegate = UIApplication.shared.delegate else {
            log("notifikasi: app delegate belum ada - token APNs tidak dapat diterima")
            return
        }
        let cls: AnyClass = type(of: delegate)

        let registerSel = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
        let registerOriginal = originalIMP(cls, registerSel).map { unsafeBitCast($0, to: DidRegister.self) }
        let register: @convention(block) (AnyObject, UIApplication, Data) -> Void = { this, app, token in
            registerOriginal?(this, registerSel, app, token)
            ShieldPush.shared.log("notifikasi: token APNs diterima")
            APIS.sendPushToken(ShieldPush.hex(token))
        }
        install(cls, registerSel, register, types: "v@:@@")

        let receiveSel = #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:))
        let receiveOriginal = originalIMP(cls, receiveSel).map { unsafeBitCast($0, to: DidReceive.self) }
        let receive: @convention(block) (AnyObject, UIApplication, NSDictionary, @escaping @convention(block) (UInt) -> Void) -> Void = { this, app, userInfo, completion in
            // One completion only - calling it twice is a crash inside Firebase's swizzler.
            let lock = NSLock()
            var done = false
            let once: (UIBackgroundFetchResult) -> Void = { result in
                lock.lock(); let first = !done; done = true; lock.unlock()
                if first { completion(result.rawValue) }
            }
            if let original = receiveOriginal {
                original(this, receiveSel, app, userInfo, { result in once(UIBackgroundFetchResult(rawValue: result) ?? .noData) })
                APIS.showNotificationNexilis(userInfo as? [AnyHashable: Any] ?? [:]) { _ in }
            } else {
                APIS.showNotificationNexilis(userInfo as? [AnyHashable: Any] ?? [:], completion: once)
            }
        }
        install(cls, receiveSel, receive, types: "v@:@@@?")
        log("notifikasi: callback APNs dipasang di \(NSStringFromClass(cls))")
    }

    /// The implementation the class answers with today - its own, or one it inherits (Flutter's
    /// FlutterAppDelegate implements both callbacks and forwards them to plugins).
    private func originalIMP(_ cls: AnyClass, _ sel: Selector) -> IMP? {
        class_getInstanceMethod(cls, sel).map(method_getImplementation)
    }

    private func install(_ cls: AnyClass, _ sel: Selector, _ block: Any, types: String) {
        let imp = imp_implementationWithBlock(block)
        if !class_addMethod(cls, sel, imp, types), let method = class_getInstanceMethod(cls, sel) {
            method_setImplementation(method, imp)
        }
    }

    // MARK: - Helpers

    fileprivate static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    fileprivate func log(_ text: String) {
        NXLogger.general.publicInfo("[NexilisLite] shield push: \(text)")
    }
}
