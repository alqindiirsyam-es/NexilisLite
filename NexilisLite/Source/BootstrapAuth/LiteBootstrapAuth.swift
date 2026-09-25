//
//  LiteBootstrapAuth.swift
//  NexilisLite
//
//  Sign-in before the protected asset opens (Sentinel RC5, point 8) - the iOS counterpart of
//  Android's com.protector.bootstrapauth (MABZTAAndroid, BOOTONLINE_PREDECRYPT_AUTH_PLAN.md).
//
//    ZTA chain: preflight -> App Attest register -> [this] -> /zta/bootstrap/auth -> /zta/key -> asset
//
//  Modes 1 and 2 only. Where the chain reaches user authentication, NexilisZTA calls
//  `LiteBootstrapAuth.provider` with the App Attest key id. It fetches a ZTA install token, puts
//  up the Login form (never signed in) or the TFA form (signed in before) and talks to the
//  institution backend over HTTPS - CPaaS /idp/v1/authn, the Android contract, not nuSDK: the
//  socket session does not exist yet. A successful answer carries the business result and an
//  `idp_assertion` the backend signed; the assertion goes back to the chain (-> /zta/bootstrap/auth),
//  the business result stays in a process-local receipt that `Nexilis.connect` consumes once the
//  chain is through, instead of showing the old form a second time.
//
//  Off until the backend is live: `APIS.enableBootstrapSignIn()` (embedded), NexilisShield.plist
//  `NexilisLite.BootstrapSignIn` (shield), or `config.bootstrapAuthentication = LiteBootstrapAuth.provider`
//  on a configuration the host passes to APISZTA.configure itself.
//

import Foundation
import UIKit
import LocalAuthentication
import NexilisZTA

public enum LiteBootstrapAuth {

    /// The institution backend. The Android client uses the same base.
    public static var baseURL = URL(string: "https://nexilis.io/idp/v1/authn")!

    /// Switched on by `APIS.enableBootstrapSignIn()`; read when the chain is configured.
    public static var isEnabled = false

    /// The business entity key (`Api`) /login, /otp/send and /otp/verify must carry (CPaaS 921f53a7): a name
    /// or e-mail is not unique across entities, so the client names the entity. Embedded: the key passed to
    /// `APIS.connect`, recorded before the chain starts. Shield: the form runs before Lite is started, so it
    /// comes from NexilisShield.plist (`NexilisLite.APIKey`).
    static var businessEntityKey: String {
        if !connectAPIKey.isEmpty { return connectAPIKey }
        if let url = Bundle.main.url(forResource: "NexilisShield", withExtension: "plist"),
           let plist = NSDictionary(contentsOf: url) as? [String: Any],
           let lite = plist["NexilisLite"] as? [String: Any],
           let key = (lite["APIKey"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty {
            return key
        }
        return Nexilis.sAPIKey
    }
    static var connectAPIKey = ""

    /// For `NexilisZTAConfiguration.bootstrapAuthentication`: the sign-in form, then the assertion.
    public static let provider: BootstrapAuthenticationProvider = { keyID, completion in
        DispatchQueue.main.async { LiteBootstrapCoordinator.shared.start(keyID: keyID, completion: completion) }
    }

    /// Called on the main thread with the business response of a successful pre-decrypt sign-in,
    /// once the chain is through and before the session connects - for a host that keeps state of
    /// its own beyond what `Nexilis.connect` applies.
    public static var onReceiptApplied: (([String: Any]) -> Void)?

    /// Called by `Nexilis.connect`: applies a pending pre-decrypt sign-in exactly once. Returns true
    /// when one was applied (the old form must not be shown again).
    @discardableResult
    public static func applyPendingReceipt() -> Bool {
        guard let receipt = LiteBootstrapReceipt.consume(forBinding: APISZTA.installBindingID) else { return false }
        let response = receipt.businessResponse
        let account = (response[LiteBootstrapKeys.accountReal] as? String).flatMap { $0.isEmpty ? nil : $0 }
            ?? receipt.account
        SecureUserDefaults.shared.set(account, forKey: "me")
        Utils.setProfile(value: true)
        NXLogger.general.publicInfo("[BootstrapAuth] hasil sign-in pra-aset diterapkan (\(receipt.returningUser ? "TFA" : "login pertama"))")
        pendingContinuation = Continuation(returningUser: receipt.returningUser,
                                           connectionID: response[LiteBootstrapKeys.account] as? String ?? "")
        onReceiptApplied?(response)
        return true
    }

    /// What `Nexilis.connect` still owes an applied sign-in: the steps Lite's own screens run after the
    /// server said yes (ChangeDeviceViewController for a first login, TFAPasswordVC for a returning one),
    /// without putting those screens up again - the person signed in once, in the chain. Android does the
    /// same: DM_LoginActivity / the TFA activity consume the receipt instead of asking the network.
    struct Continuation {
        let returningUser: Bool
        /// A00 of the reply: the CLM connection id this device sent as B10.
        let connectionID: String
    }
    private(set) static var pendingContinuation: Continuation?

    /// Runs the continuation once: post-registration on a first login, then the session connect.
    /// Returns false when there is none, and the caller shows Lite's own sign-in screens as before.
    static func continueAfterSignIn() -> Bool {
        guard let next = pendingContinuation else { return false }
        pendingContinuation = nil
        // Lite's screens open the CLX connection first (justInit: address lookup, initConnection with the
        // connection id, then wait until it is up) and only then send anything; so does this. Without it
        // the post-registration below was dropped and the session never came up.
        NXLogger.general.publicInfo("[BootstrapAuth] membuka koneksi sesi (justInit)")
        guard !Nexilis.justInit().isEmpty else {
            NXLogger.general.publicError("[BootstrapAuth] koneksi sesi tidak dapat dibuka setelah sign-in pra-aset")
            return true
        }
        if !next.returningUser {
            // As ChangeDeviceViewController.successSubmit: a fresh local store, then the server told this
            // device is the account's now.
            NSObject().deleteAllRecordDatabase()
            _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: next.connectionID))
        } else if Utils.isMiddleMode() && Utils.getBiometricState() == nil {
            SecureUserDefaults.shared.set(Date(), forKey: "lastAuthenticationTime")
        }
        Nexilis.setInitCallback { result in
            guard result == 1 else { return }
            Nexilis.successSui?()
            guard !next.returningUser, Nexilis.showFB else { return }
            DispatchQueue.main.async {
                Nexilis.floatingButton?.removeFromSuperview()
                FloatingButton.datePull = nil
                Nexilis.floatingButton = FloatingButton()
                Nexilis.addFB()
            }
        }
        NXLogger.general.publicInfo("[BootstrapAuth] sesi dibuka dari sign-in pra-aset - layar sign-in Lite tidak ditampilkan")
        Nexilis.startConnect(withInit: false)
        return true
    }
}

// MARK: - State

/// Read-only view of the Lite login state before the asset is open (Android: BootstrapIdentityStore).
struct LiteBootstrapIdentity {
    let returningUser: Bool
    let fPin: String
    let hsa: Bool
    /// The CLM connection id (`B10`): the one the session will use once the asset is open.
    let connectionID: String

    static func read() throws -> LiteBootstrapIdentity {
        let mode = APISZTA.configuration.appMode
        guard mode != .regular else { throw LiteBootstrapError("Autentikasi bootstrap hanya berlaku pada mode 1/2.") }
        let pin = User.getMyPin() ?? ""
        return LiteBootstrapIdentity(returningUser: Utils.getSetProfile() && !pin.isEmpty, fPin: pin, hsa: mode == .HSA,
                                     connectionID: try connectionID())
    }

    /// Lite's `connection_id`, created exactly as Nexilis.justInit does on a first run (the last five characters of
    /// the vendor id + milliseconds) when there is none yet - the session will then find it. The server takes
    /// [A-Za-z0-9_-]{8,48} (Android: CONN_ID / pb_android_id, BootstrapIdentityStore.connectionId).
    static func connectionID() throws -> String {
        var id = Utils.getConnectionID()
        if id.isEmpty {
            let vendor = UIDevice.current.identifierForVendor?.uuidString ?? "UNK-DEVICE"
            id = String(vendor[vendor.index(vendor.endIndex, offsetBy: -5)...]) + "\(Date().currentTimeMillis())"
            Utils.setConnectionID(value: id)
        }
        guard id.range(of: "^[A-Za-z0-9_-]{8,48}$", options: .regularExpression) != nil else {
            throw LiteBootstrapError("Connection ID tidak valid.")
        }
        return id
    }
}

/// The first-login reply waiting for its TFA stage (Android: BootstrapAuthReceipt.stageLogin). Memory only, for as
/// long as the server keeps the attempt (bootstrap_auth_idem_ttl_ms, 10 minutes).
enum LiteBootstrapLoginStage {
    private static let lock = NSLock()
    private static var reply: [String: Any]?
    private static var binding = "", attempt = ""
    private static var at: TimeInterval = 0

    static func stage(binding: String, attempt: String, reply: [String: Any]) {
        lock.lock(); defer { lock.unlock() }
        self.reply = reply; self.binding = binding; self.attempt = attempt
        at = ProcessInfo.processInfo.systemUptime
    }

    static func reply(binding: String, attempt: String) -> [String: Any]? {
        lock.lock(); defer { lock.unlock() }
        guard let reply, ProcessInfo.processInfo.systemUptime - at <= 600 else { self.reply = nil; return nil }
        return self.binding == binding && self.attempt == attempt ? reply : nil
    }

    static func clear() { lock.lock(); reply = nil; lock.unlock() }
}

/// Process-local, single-use, five minutes (Android: BootstrapAuthReceipt). Never persisted, never
/// passed through a view controller's result.
struct LiteBootstrapReceipt {
    let binding: String
    let returningUser: Bool
    let account: String
    let businessResponse: [String: Any]
    let createdAt: TimeInterval

    private static let lock = NSLock()
    private static var pending: LiteBootstrapReceipt?

    static func store(_ receipt: LiteBootstrapReceipt) { lock.lock(); pending = receipt; lock.unlock() }
    static func clear() { lock.lock(); pending = nil; lock.unlock() }

    static func consume(forBinding binding: String?) -> LiteBootstrapReceipt? {
        lock.lock(); defer { lock.unlock() }
        guard let receipt = pending else { return nil }
        pending = nil
        guard ProcessInfo.processInfo.systemUptime - receipt.createdAt <= 300,
              let binding, receipt.binding == binding else { return nil }
        return receipt
    }
}

// MARK: - Device proof

/// The FIDO-style proof the legacy forms send (Android: BootstrapDeviceProof): FPR always; with a
/// device key already present, a signature over "challenge!fingerprint"; without one, a new key
/// and its public half.
enum LiteBootstrapDeviceProof {
    static var hasDeviceKey: Bool { KeyManagerNexilis.hasGeneratedKey() }

    static func add(to request: inout [String: Any], challenge: String?, hsa: Bool) throws {
        let fingerprint = HMACDeviceFingerprintNexilis.generate()
        request[LiteBootstrapKeys.fingerprint] = fingerprint
        if KeyManagerNexilis.hasGeneratedKey() {
            guard let challenge, !challenge.isEmpty else { throw LiteBootstrapError("Challenge FIDO tidak tersedia.") }
            guard let key = KeyManagerNexilis.getPrivateKey(useBiometric: hsa),
                  let signature = KeyManagerNexilis.sign(data: Data("\(challenge)!\(fingerprint)".utf8), privateKey: key) else {
                throw LiteBootstrapError("Tanda tangan perangkat tidak tersedia.")
            }
            request[LiteBootstrapKeys.signature] = signature.base64EncodedString()
        } else {
            KeyManagerNexilis.generateKey()
            KeyManagerNexilis.saveMarker()
            guard let key = KeyManagerNexilis.getPrivateKey(useBiometric: false),
                  let publicKey = KeyManagerNexilis.getRSAX509PublicKeyBase64(privateKey: key) else {
                throw LiteBootstrapError("Kunci perangkat tidak dapat dibuat.")
            }
            request[LiteBootstrapKeys.publicKey] = publicKey
        }
    }
}

// MARK: - Coordinator

/// One sign-in at a time: install token, the form in its own window, the result to the chain.
final class LiteBootstrapCoordinator {
    static let shared = LiteBootstrapCoordinator()
    private var window: UIWindow?
    private var completion: ((Result<String, Error>) -> Void)?

    func start(keyID: String, completion: @escaping (Result<String, Error>) -> Void) {
        if let previous = self.completion {
            previous(.failure(LiteBootstrapError("Sign-in digantikan oleh permintaan baru.")))
        }
        self.completion = completion
        LiteBootstrapReceipt.clear()
        LiteBootstrapLoginStage.clear()
        let identity: LiteBootstrapIdentity
        do { identity = try LiteBootstrapIdentity.read() } catch { finish(.failure(error)); return }
        Task { @MainActor in
            do {
                let token = try await APISZTA.requestInstallToken()
                let client = LiteBootstrapHTTPSClient(baseURL: LiteBootstrapAuth.baseURL, installToken: token)
                let form: LiteBootstrapFormViewController = identity.returningUser
                    ? LiteBootstrapTfaViewController(identity: identity, bindingID: keyID, client: client)
                    : LiteBootstrapLoginViewController(identity: identity, bindingID: keyID, client: client)
                form.onFinish = { [weak self] result in self?.finish(result) }
                present(form)
                NXLogger.general.publicInfo("[BootstrapAuth] form \(identity.returningUser ? "TFA" : "Login") pra-aset ditampilkan")
            } catch {
                finish(.failure(error))
            }
        }
    }

    private func present(_ form: UIViewController) {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = scene.map { UIWindow(windowScene: $0) } ?? UIWindow(frame: UIScreen.main.bounds)
        // Above the Sentinel checking cover and the ZTA error screen, below the privacy cover.
        window.windowLevel = UIWindow.Level.alert + 5
        let navigation = UINavigationController(rootViewController: form)
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        self.window = window
    }

    private func finish(_ result: Result<String, Error>) {
        DispatchQueue.main.async {
            let scene = self.window?.windowScene
            self.window?.isHidden = true
            self.window = nil
            // Key back to the topmost window still up - the Sentinel cover while the chain runs - so the
            // ZTA error screen, if this ends in one, presents where it is seen.
            SentinelSecurityCover.restoreKeyWindow(in: scene)
            let done = self.completion
            self.completion = nil
            LiteBootstrapLoginStage.clear()
            if case .failure = result { LiteBootstrapReceipt.clear() }
            done?(result)
        }
    }
}

// MARK: - Shield

/// For the no-code shield, which cannot link NexilisLite: NXShieldAutostart finds this class by
/// name and hands it the chain's user-authentication step (NexilisShield.plist
/// `NexilisLite.BootstrapSignIn`).
@objc(NXLiteBootstrapAuthBridge)
public final class LiteBootstrapAuthBridge: NSObject {
    @objc public static func authenticate(keyId: String, completion: @escaping (String?, NSError?) -> Void) {
        LiteBootstrapAuth.provider(keyId) { result in
            switch result {
            case .success(let assertion): completion(assertion, nil)
            case .failure(let error): completion(nil, error as NSError)
            }
        }
    }
}

