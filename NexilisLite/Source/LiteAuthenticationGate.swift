//
//  LiteAuthenticationGate.swift
//  NexilisLite
//
//  Re-authentication on Lite's shared timer at app modes 1 and 2: `authentication_duration` from feature
//  access (30 s by default at mode 1, 60 s at mode 2), counted from the last successful Face ID / Touch ID
//  (`lastAuthenticationTime`).
//
//    - Foreground returns and protected screens after expiry use the same gate:
//      biometrics -> signed online challenge + TOTP -> CPaaS acceptance -> shared window.
//    - Local biometric success alone never opens the window. Failures show DialogErrorMFA.
//    - Mode 2 installs that declined biometrics bypass this timer gate entirely.
//
//  Installed by Nexilis.connect; observes the app itself, so a host does not have to forward anything.
//

import UIKit
import ObjectiveC
import NexilisZTA
import LocalAuthentication

public enum LiteAuthenticationGate {

    private static var installed = false
    private static var backgroundedAt: Date?
    private static var prompting = false
    private static var waiting: [(Bool) -> Void] = []
    private static var verifiedContext: LAContext?
    private static var failureCount = 0
    private static weak var protectedPresenter: UIViewController?
    private static var presenterWasInteractive = true
    private static var validationLoading: LibAlertController?
    private static let validationQueue = DispatchQueue(label: "io.nexilis.timerValidation", qos: .userInitiated)

    /// The window, as Utils.shouldRequestAuthentication counts it.
    static var duration: TimeInterval {
        Double(Utils.getAuthenticationDuration()) ?? (Utils.isMiddleMode() ? 60 : 30)
    }

    /// Mode 1 is mandatory; mode 2 only gates installs that opted into biometry.
    static var applies: Bool {
        (Utils.isHSAMode() || (Utils.isMiddleMode() && Utils.getBiometricState() != nil))
            && Utils.getSetProfile() && Nexilis.hasInit
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
        NXLogger.general.publicInfo("[AuthGate] timer background habis - biometrik dan validasi signature diminta")
        expire()
        guard !isTFAShowing else { return }
        requireRecentAuthentication { _ in }
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
        guard Thread.isMainThread else {
            DispatchQueue.main.async { requireRecentAuthentication(done) }
            return
        }
        if prompting { waiting.append(done); return }
        guard applies, Utils.shouldRequestAuthentication() else { done(true); return }
        waiting.append(done)
        prompting = true
        protectedPresenter = currentPresenter()
        presenterWasInteractive = protectedPresenter?.view.isUserInteractionEnabled ?? true
        protectedPresenter?.view.isUserInteractionEnabled = false
        failureCount = 0
        authenticateAndValidate()
    }

    private static func authenticateAndValidate() {
        expire()
        verifiedContext = nil
        NXLogger.general.publicInfo("[AuthGate] timer habis - biometrik dahulu, lalu validasi signature server")
        Utils.authenticateWithBiometrics(verifySavedState: Utils.isMiddleMode(), recordAuthentication: false,
                                         onVerifiedContext: { context in
                                             DispatchQueue.main.async { verifiedContext = context }
                                         }) { ok, message in
            DispatchQueue.main.async {
                guard ok, let context = verifiedContext else {
                    showTimerFailure(message ?? "Biometrik gagal atau dibatalkan.")
                    return
                }
                showValidationLoading {
                    validationQueue.async {
                        do {
                            try validateTimerSignature()
                            DispatchQueue.main.async {
                                hideValidationLoading {
                                    MasterKeyUtil.shared.adoptAuthenticatedContext(context)
                                    SecureUserDefaults.shared.set(Date(), forKey: "lastAuthenticationTime")
                                    NXLogger.general.publicInfo("[AuthGate] signature diterima server; akses dibuka")
                                    finishTimerAuthentication(true)
                                }
                            }
                        } catch {
                            DispatchQueue.main.async { showTimerFailure(error.localizedDescription) }
                        }
                    }
                }
            }
        }
    }

    /// Existing online CPaaS DF01 contract, not the pre-asset HTTPS /tfa flow.
    /// No password, no key generation/enrollment, and no second biometric prompt.
    private static func validateTimerSignature() throws {
        func failure(_ text: String) -> NSError {
            NSError(domain: "NexilisTimerAuthentication", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: text])
        }
        let account = User.getMyPin() ?? ""
        let connection = Utils.getConnectionID()
        guard !account.isEmpty, !connection.isEmpty, Nexilis.waitForLink(upTo: 5) else {
            throw failure("Koneksi CPaaS belum tersedia. Coba lagi.")
        }
        guard KeyManagerNexilis.hasGeneratedKey(),
              let key = KeyManagerNexilis.getPrivateKey(useBiometric: false) else {
            throw failure("Kunci perangkat terdaftar tidak tersedia. Lakukan Sign-In ulang.")
        }
        guard let challenge = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChalanger(xPin: connection), timeout: 10000),
              challenge.isOk() else {
            throw failure("Permintaan challenge server gagal. Coba lagi.")
        }
        let data = challenge.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
        let fingerprint = HMACDeviceFingerprintNexilis.generate()
        guard !data.isEmpty, !fingerprint.isEmpty,
              let signature = KeyManagerNexilis.sign(data: Data("\(data)!\(fingerprint)".utf8), privateKey: key),
              !signature.isEmpty else {
            throw failure("Signature perangkat tidak dapat dibuat.")
        }
        let request = CoreMessage_TMessageBank.getMFAValidation(data: account)
        request.mBodies[CoreMessage_TMessageKey.ACTVITY] = "Sign In"
        request.mBodies[CoreMessage_TMessageKey.FINGERPRINT] = fingerprint
        request.mBodies[CoreMessage_TMessageKey.SIGNATURE] = signature.base64EncodedString()
        request.mBodies[CoreMessage_TMessageKey.SUBMIT_DATE] = "\(Date().currentTimeMillis())"
        request.mBodies[CoreMessage_TMessageKey.TOTP] = try TOTPGenerator.generateTOTP(
            base32Secret: TOTPGenerator.getTOTP(), digits: 6, timeStepSeconds: 300)
        guard let response = Nexilis.writeAndWait(message: request, timeout: 10000) else {
            throw failure("Validasi signature server timeout. Coba lagi.")
        }
        guard response.isOk() else {
            throw failure(response.getBody(key: CoreMessage_TMessageKey.MESSAGE_TEXT, default_value: "Validasi signature ditolak server."))
        }
    }

    private static func currentPresenter() -> UIViewController? {
        let windows = UIApplication.shared.windows
        let window = windows.first { $0.isKeyWindow && $0.windowLevel == .normal }
            ?? windows.first { !$0.isHidden && $0.windowLevel == .normal }
        var top = window?.rootViewController
        while let current = top {
            if let presented = current.presentedViewController, !presented.isBeingDismissed { top = presented }
            else if let nav = current as? UINavigationController, let visible = nav.visibleViewController { top = visible }
            else if let tabs = current as? UITabBarController, let selected = tabs.selectedViewController { top = selected }
            else { return current }
        }
        return nil
    }

    private static func showTimerFailure(_ message: String) {
        hideValidationLoading { presentTimerFailure(message) }
    }

    /// Wait for presentation/dismissal to complete so fast server replies cannot
    /// leave a loading alert above the accepted screen or the MFA failure dialog.
    private static func showValidationLoading(_ ready: @escaping () -> Void) {
        guard validationLoading == nil,
              let presenter = protectedPresenter ?? currentPresenter() else { ready(); return }
        let loading = LibAlertController(title: nil, message: "Memvalidasi autentikasi...", preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        spinner.style = .medium
        spinner.startAnimating()
        loading.view.addSubview(spinner)
        validationLoading = loading
        presenter.present(loading, animated: true, completion: ready)
    }

    private static func hideValidationLoading(_ completion: @escaping () -> Void) {
        guard let loading = validationLoading else { completion(); return }
        validationLoading = nil
        loading.dismiss(animated: true, completion: completion)
    }

    private static func presentTimerFailure(_ message: String) {
        verifiedContext?.invalidate()
        verifiedContext = nil
        expire()
        failureCount += 1
        if failureCount >= 3 { finishTimerAuthentication(false); exit(0) }
        let dialog = DialogErrorMFA()
        dialog.errorDesc = message
        dialog.method = "Timer Authentication"
        dialog.countRetry = failureCount
        dialog.modalTransitionStyle = .crossDissolve
        dialog.modalPresentationStyle = .overCurrentContext
        dialog.isDismiss = { result in
            if result == 1 { authenticateAndValidate() }
            else { finishTimerAuthentication(false); exit(0) }
        }
        guard let presenter = protectedPresenter ?? currentPresenter() else {
            finishTimerAuthentication(false)
            return
        }
        NXLogger.general.publicInfo("[AuthGate] autentikasi/validasi gagal; DialogErrorMFA ditampilkan")
        presenter.present(dialog, animated: true)
    }

    private static func finishTimerAuthentication(_ accepted: Bool) {
        prompting = false
        verifiedContext = nil
        if accepted {
            protectedPresenter?.view.isUserInteractionEnabled = presenterWasInteractive
            protectedPresenter?.view.nxReloadLists()
        }
        protectedPresenter = nil
        let callbacks = waiting
        waiting.removeAll()
        callbacks.forEach { $0(accepted) }
    }
}

// MARK: - Protected screens

extension UIViewController {

    /// Sign-in, TFA and the dialogs around them are how a person authenticates; gating them would ask twice.
    private static let nxUngatedScreens: Set<String> = [
        "TFAPasswordVC", "SignUpSignIn", "SignInOption", "ChangeDeviceViewController", "MFAViewController",
        "DialogErrorMFA", "DialogSignIn", "DialogUnableAccess", "VerifyEmail", "TOTPInputViewController",
        "ContactCenterOfficerRequestDialog",
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
