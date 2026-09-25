//
//  LiteAuthenticationGate.swift
//  NexilisLite
//
//  Re-authentication on Lite's shared timer at app modes 1 and 2: `authentication_duration` from feature
//  access (30 s by default at mode 1, 60 s at mode 2), counted from the last successful Face ID / Touch ID
//  (`lastAuthenticationTime`).
//
//    - Back from the background after at least that long: the authentication has lapsed - the master key's
//      reuse window is closed and Lite's TFA screen is put up (password, then Face ID on Submit).
//    - A NexilisLite screen that appears once the timer has run out asks for Face ID before its content is
//      used; success reloads what it shows (reads made while the window was closed came back empty), failure
//      closes it.
//
//  Installed by Nexilis.connect; observes the app itself, so a host does not have to forward anything.
//

import UIKit
import ObjectiveC
import NexilisZTA

public enum LiteAuthenticationGate {

    private static var installed = false
    private static var backgroundedAt: Date?
    private static var prompting = false

    /// The window, as Utils.shouldRequestAuthentication counts it.
    static var duration: TimeInterval {
        Double(Utils.getAuthenticationDuration()) ?? (Utils.isMiddleMode() ? 60 : 30)
    }

    /// Modes 1 and 2, signed in, session started.
    static var applies: Bool {
        (Utils.isHSAMode() || Utils.isMiddleMode()) && Utils.getSetProfile() && Nexilis.hasInit
    }

    static func install() {
        DispatchQueue.main.async {
            guard !installed else { return }
            installed = true
            NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                   object: nil, queue: .main) { _ in
                backgroundedAt = Date()
            }
            NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                   object: nil, queue: .main) { _ in
                returnedToForeground()
            }
            UIViewController.nxInstallProtectedScreenGate()
        }
    }

    private static func returnedToForeground() {
        guard let at = backgroundedAt else { return }
        backgroundedAt = nil
        let away = Date().timeIntervalSince(at)
        guard applies, away >= duration else { return }
        NXLogger.general.publicInfo("[AuthGate] \(Int(away))s di background (batas \(Int(duration))s) - TFA diminta lagi")
        expire()
        presentTFA()
    }

    /// Ends the current authentication: the next protected access asks again.
    static func expire() {
        SecureUserDefaults.shared.removeValue(forKey: "lastAuthenticationTime")
        MasterKeyUtil.shared.invalidateAuthentication()
    }

    static var isTFAShowing: Bool {
        var controller = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? UIApplication.shared.windows.first?.rootViewController
        while let current = controller {
            if current is TFAPasswordVC { return true }
            if let nav = current as? UINavigationController, nav.viewControllers.contains(where: { $0 is TFAPasswordVC }) {
                return true
            }
            controller = current.presentedViewController
        }
        return false
    }

    static func presentTFA() {
        guard !isTFAShowing else { return }
        Nexilis.showPassSignIn()
    }

    /// For a protected screen or action: `done(true)` once the person is inside the window - at once when they
    /// already are, after Face ID / Touch ID when it has run out. `done(false)` when they declined.
    public static func requireRecentAuthentication(_ done: @escaping (Bool) -> Void) {
        guard applies, Utils.shouldRequestAuthentication() else { done(true); return }
        guard !prompting else { return }
        prompting = true
        NXLogger.general.publicInfo("[AuthGate] timer habis - Face ID diminta sebelum data terlindungi dibuka")
        Utils.authenticateWithBiometrics { ok, _ in
            DispatchQueue.main.async {
                prompting = false
                done(ok)
            }
        }
    }
}

// MARK: - Protected screens

extension UIViewController {

    /// Sign-in, TFA and the dialogs around them are how a person authenticates; gating them would ask twice.
    private static let nxUngatedScreens: Set<String> = [
        "TFAPasswordVC", "SignUpSignIn", "SignInOption", "ChangeDeviceViewController", "MFAViewController",
        "DialogErrorMFA", "DialogSignIn", "DialogUnableAccess", "VerifyEmail", "TOTPInputViewController",
        "LiteBootstrapLoginViewController", "LiteBootstrapTfaViewController",
    ]

    private static var nxGateInstalled = false

    static func nxInstallProtectedScreenGate() {
        guard !nxGateInstalled,
              let original = class_getInstanceMethod(UIViewController.self, #selector(viewDidAppear(_:))),
              let gated = class_getInstanceMethod(UIViewController.self, #selector(nx_gated_viewDidAppear(_:))) else { return }
        nxGateInstalled = true
        method_exchangeImplementations(original, gated)
    }

    @objc private func nx_gated_viewDidAppear(_ animated: Bool) {
        nx_gated_viewDidAppear(animated)
        let name = NSStringFromClass(type(of: self))
        guard name.hasPrefix("NexilisLite."),
              !(self is UINavigationController), !(self is UITabBarController), !(self is UIAlertController),
              !Self.nxUngatedScreens.contains(String(name.dropFirst("NexilisLite.".count))),
              LiteAuthenticationGate.applies, Utils.shouldRequestAuthentication(),
              !LiteAuthenticationGate.isTFAShowing else { return }
        LiteAuthenticationGate.requireRecentAuthentication { [weak self] ok in
            guard let self else { return }
            if ok {
                self.view.nxReloadLists()
                return
            }
            NXLogger.general.publicInfo("[AuthGate] Face ID ditolak - \(name) ditutup")
            if let nav = self.navigationController, nav.viewControllers.count > 1, nav.topViewController === self {
                nav.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }
}

private extension UIView {
    /// Lists drawn while the window was closed show placeholders for protected content; draw them again.
    func nxReloadLists() {
        if let table = self as? UITableView { table.reloadData() }
        if let collection = self as? UICollectionView { collection.reloadData() }
        subviews.forEach { $0.nxReloadLists() }
    }
}
