//
//  SecureStorage.swift
//  Pods
//
//  Created by Qindi on 02/12/24.
//

import CryptoKit
import LocalAuthentication
import UIKit
import NexilisZTA


public class MasterKeyUtil {
    static let shared = MasterKeyUtil()
    private let keyAlias = "_iosx_security_master_key"
    private let prefsKeyAlias = "_iosx_security_master_key_easysoft_"
    private let serverKeyAlias = "_iosx_security_master_key_server_"
    /// Unattended-work key. See `mediaKey()`.
    private let mediaKeyAlias = "_iosx_security_media_key"

    private init() {}
    
    func base64toData(_ base64: String) -> Data? {
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        return data
    }
    
    func generateAndStoreKey(_ alias: String, key_s: String? = nil) throws {
        // Only the .hsa master key gets Keychain-enforced biometric access control, and existing
        // material is migrated into it once without changing the key bytes. Every other item -
        // the preference key, the server key, and the master key of a .middle or .regular host -
        // stays a device-only AfterFirstUnlock item, which is what unattended work needs.
        let hardened = alias == keyAlias && NXSecurityPolicy.bindsKeysToUserAuth()

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: alias,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var attrQuery = baseQuery
        attrQuery[kSecReturnAttributes as String] = true
        var attrsItem: CFTypeRef?
        let attrStatus = SecItemCopyMatching(attrQuery as CFDictionary, &attrsItem)
        let exists = attrStatus == errSecSuccess

        // Does the item's protection already match the mode this launch is running in?
        //
        // Fix: this asked whether the returned attributes carried kSecAttrAccessControl at all,
        // and on iOS they always do - every data-protection item comes back with an `accc`
        // describing its protection class, ACL or not. So every existing item read as
        // "biometric-protected": the preference key, which never is, hit the main-thread refusal
        // below on each launch. At modes 2 and 3 the throw was swallowed as best-effort; at mode
        // 1 it stopped connect() before a single thread was started, and a fresh sign-in sat on
        // top of a session that was never opened. The protection class is what tells the two
        // apart: the hardened item is created WhenUnlockedThisDeviceOnly inside its ACL, every
        // other item AfterFirstUnlockThisDeviceOnly.
        let existingAccessible = (attrsItem as? [String: Any])?[kSecAttrAccessible as String] as? String
        let existingHasAccessControl = exists
            && existingAccessible == (kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)

        if exists, existingHasAccessControl == hardened {
            // Nothing to change. The marker still has to be caught up, though: a key provisioned
            // by a build from before the marker existed takes this path on every launch and would
            // never record itself, so its eventual invalidation would read as "this device never
            // had a key".
            if hardened, !hasProvisionedMarker() { writeProvisionedMarker() }
            return
        }

        var existingData: Data?
        if exists {
            // Reading an access-controlled item presents biometry and blocks until it is
            // answered, which the main queue cannot do. This is the mode-downgrade direction -
            // a device that ran at mode 1 and is now at 2 or 3, whose key is still behind the
            // ACL - and it is repaired from `primeSecureStorage()`, off the main thread. Here it
            // is refused rather than hung.
            if existingHasAccessControl, Thread.isMainThread {
                throw NSError(domain: "KeychainError", code: -95, userInfo: [
                    NSLocalizedDescriptionKey: "The stored key is still protected for app mode 1 and cannot be re-provisioned on the main thread.",
                    NSLocalizedFailureReasonErrorKey: "MasterKeyUtil.primeSecureStorage() performs this off the main queue."
                ])
            }

            var dataQuery = baseQuery
            dataQuery[kSecReturnData as String] = true
            if existingHasAccessControl {
                dataQuery[kSecUseAuthenticationContext as String] = masterKeyQueue.sync { authContextLocked() }
            }
            var dataItem: CFTypeRef?
            let status = SecItemCopyMatching(dataQuery as CFDictionary, &dataItem)
            guard status == errSecSuccess, let d = dataItem as? Data else {
                throw NSError(domain: "KeychainError", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Unable to migrate existing master key"])
            }
            existingData = d
        }

        let generated = key_s == nil ? SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) } : base64toData(key_s!)
        guard let keyData = existingData ?? generated else {
            throw NSError(domain: "KeychainError", code: -90, userInfo: [NSLocalizedDescriptionKey: "Invalid key material"])
        }

        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: alias,
            kSecValueData as String: keyData
        ]

        if hardened {
            var acError: Unmanaged<CFError>?
            guard let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [.biometryCurrentSet],
                &acError
            ) else {
                throw acError?.takeRetainedValue() ?? NSError(domain: "KeychainError", code: -91)
            }
            addQuery[kSecAttrAccessControl as String] = access
        } else {
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: alias
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status == errSecSuccess, hardened {
            writeProvisionedMarker()
        }
        guard status == errSecSuccess else {
            // The delete above has already happened, so a failed add is not a no-op - it destroys
            // the only copy of the key every stored file and the database password are encrypted
            // under. And it is a reachable failure, not a theoretical one: SecItemAdd refuses a
            // biometric access control on a device with no biometry enrolled, which is exactly
            // the device most likely to be taking this path the first time a host sets mode 1.
            //
            // Put back before raising. The original accessibility cannot be read back off an item
            // that no longer exists, so it is restored device-only: the key bytes are what matter,
            // and that protection is no weaker than what was there.
            if let existingData {
                let restoreQuery: [String: Any] = [
                    kSecClass as String: kSecClassKey,
                    kSecAttrApplicationTag as String: alias,
                    kSecValueData as String: existingData,
                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                ]
                _ = SecItemAdd(restoreQuery as CFDictionary, nil)
            }
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: [
                NSLocalizedDescriptionKey: "Unable to store the key for \(alias)."
            ])
        }
    }
    
    func generateAndStorePrefsKey() throws {
        try generateAndStoreKey(prefsKeyAlias)
    }
    
    func generateAndStoreMasterKey() throws {
        try generateAndStoreKey(keyAlias)
    }
    
    func isDeviceNotSecure() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        if !context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) || Utils.shouldRequestAuthentication() {
            return true
        } else {
            return false
        }
    }
    
    func isKeyExists(keyAliasCode: String) throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAliasCode,
            kSecReturnData as String: false // We only check existence, not retrieve data
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecItemNotFound {
            return false
        } else if status == errSecSuccess {
            return true
        } else {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: nil)
        }
    }
    
    private let masterKeyQueue = DispatchQueue(label: "io.nexilis.masterKeyQueue")

    /// The authentication being reused across reads, and when it was established.
    ///
    /// The biometric ACL authorises one Keychain read at a time, so a screen that opens six
    /// attachments asked for six separate Face ID confirmations, queued one behind another on
    /// `masterKeyQueue`. `touchIDAuthenticationAllowableReuseDuration` is how iOS expresses what
    /// Android gets from `setUserAuthenticationValidityDurationSeconds`: one confirmation
    /// authorises the reads that follow it inside the window.
    ///
    /// The window is the host's own `authentication_duration`, capped at what the platform
    /// allows. Only the `.hsa` path uses this; nothing else builds an LAContext here.
    private var reusableAuthContext: LAContext?
    private var reusableAuthContextAt: Date?

    private func authenticationReuseWindow() -> TimeInterval {
        let configured = Double(Utils.getAuthenticationDuration()) ?? 30
        return max(0, min(configured, LATouchIDAuthenticationMaximumAllowableReuseDuration))
    }

    /// Caller holds `masterKeyQueue`.
    private func authContextLocked() -> LAContext {
        let window = authenticationReuseWindow()
        if window > 0,
           let context = reusableAuthContext,
           let establishedAt = reusableAuthContextAt,
           Date().timeIntervalSince(establishedAt) < window {
            return context
        }
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = window
        context.localizedReason = "Authenticate to access protected Nexilis data"
        reusableAuthContext = context
        reusableAuthContextAt = Date()
        return context
    }

    /// The key, once it has been fetched. Never used at `.hsa` - see `deviceKeychainMasterKey`.
    private var deviceKeychainCachedKey: SymmetricKey?

    func getMasterKey(withoutBiometric: Bool = false) throws -> SymmetricKey {
        guard NXSecurityPolicy.bindsKeysToUserAuth() else {
            return try deviceKeychainMasterKey(withoutBiometric: withoutBiometric)
        }
        return try userAuthBoundMasterKey(withoutBiometric: withoutBiometric)
    }

    /// `.hsa`: the key behind its Keychain biometric ACL, fetched afresh every time.
    ///
    /// No process-wide copy is kept: a cached key is a way past the gate the ACL exists to be,
    /// and unattended background access is refused outright rather than quietly weakened.
    private func userAuthBoundMasterKey(withoutBiometric: Bool) throws -> SymmetricKey {
        // Unattended work does not get the biometric key - it gets its own, lower-privilege one.
        // Throwing here instead used to mean the outgoing thread, the downloader and the push
        // handler all failed to persist anything, quietly, for the whole of a .hsa session.
        if withoutBiometric {
            return try mediaKey()
        }

        // Presenting biometry blocks until the person answers, and the main queue is where the
        // answer has to be drawn - so a prompting read from the main thread is an unresponsive
        // app and then a watchdog kill. It is never allowed to happen.
        //
        // Refusing outright would mean no chat row, avatar or attachment could ever be decrypted
        // for display, which is what made mode 1 unusable. So on the main thread the read is
        // attempted with interaction switched off: inside the reuse window established by
        // `primeSecureStorage()` the ACL is already satisfied and the key comes back immediately
        // with no UI at all. Outside it, the Keychain answers errSecInteractionNotAllowed and
        // this returns a clear error instead of hanging - the caller shows a placeholder, and the
        // next foreground priming opens the window again.
        let onMainQueue = Thread.isMainThread

        var retrievedKey: SymmetricKey?
        var thrownError: Error?
        masterKeyQueue.sync {
            let context = authContextLocked()
            var query: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: keyAlias,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecUseAuthenticationContext as String: context
            ]
            if onMainQueue {
                query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
            } else {
                query[kSecUseOperationPrompt as String] = "Authenticate to access protected Nexilis data"
            }
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            guard status == errSecSuccess else {
                // `biometryCurrentSet` means the item dies the moment a finger or face is added
                // or removed. That is the control working as specified, but it is not the same
                // failure as "the person declined the prompt", and reporting both as a bare
                // OSStatus left an unrecoverable state looking like a cancelled one.
                //
                // The Android SDK draws the same line: KeyGeneratorUtil.checkBiometricStatus()
                // returns true for UserNotAuthenticatedException and false only for
                // InvalidKeyException, and the callers that see false show
                // `pb_fingerprint_different` and drive re-enrollment (TFA.java:269,
                // MFA.java:279, MFAOnlyFinger.java:66).
                //
                // Nothing here can recover the data: it was encrypted under a key the Secure
                // Enclave has destroyed. What this does is make that diagnosable instead of
                // silent, so the host can re-provision rather than retry forever.
                if status == errSecInteractionNotAllowed {
                    thrownError = NSError(domain: "KeychainError", code: -94, userInfo: [
                        NSLocalizedDescriptionKey: "Protected data needs the person to authenticate, which cannot be asked for from the main thread.",
                        NSLocalizedFailureReasonErrorKey: "Call MasterKeyUtil.primeSecureStorage() off the main queue to open the authentication window."
                    ])
                } else if status == errSecItemNotFound, hasProvisionedMarker() {
                    thrownError = NSError(domain: "KeychainError", code: -96, userInfo: [
                        NSLocalizedDescriptionKey: "The biometric master key was invalidated by a change to this device's enrolled biometrics.",
                        NSLocalizedFailureReasonErrorKey: "Data stored under it cannot be recovered; the key has to be re-provisioned."
                    ])
                } else {
                    thrownError = NSError(domain: "KeychainError", code: Int(status), userInfo: nil)
                }
                return
            }
            guard let keyData = item as? Data else {
                thrownError = NSError(domain: "KeyRetrievalError", code: -1, userInfo: nil)
                return
            }
            retrievedKey = SymmetricKey(data: keyData)
        }
        if let error = thrownError { throw error }
        guard let key = retrievedKey else {
            throw NSError(domain: "KeychainError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to get key"])
        }
        return key
    }

    /// `.middle` and `.regular`: the key from a device-only AfterFirstUnlock item, with an
    /// app-level biometric prompt in front of it and one copy kept for the rest of the process'
    /// life.
    ///
    /// A screenful of thumbnails after a cold start is a screenful of decryptions, and each one
    /// asks for this key. Without the copy that is a screenful of Keychain lookups queued behind
    /// each other; with the biometric ACL of `.hsa` it would be a screenful of Face ID prompts.
    /// Neither is something these two modes can ship, which is the whole reason they exist. What
    /// guards the key here is the check below, and it still runs on every single call.
    private func deviceKeychainMasterKey(withoutBiometric: Bool) throws -> SymmetricKey {
        var retrievedKey: SymmetricKey?
        var thrownError: Error?

        masterKeyQueue.sync {
            // `!withoutBiometric` first: it is the cheapest of the three by a long way, and the
            // two after it are not - one reads enrollment state or parses the feature-access
            // blob, the other asks the biometry subsystem what it can do. Same answer, in the
            // order that stops early.
            if !withoutBiometric && shouldPromptForBiometry() && isDeviceNotSecure() {
                let semaphore = DispatchSemaphore(value: 0)
                var result = false

                Utils.authenticateWithBiometrics { success, errorMessage in
                    if success {
                        result = true
                    } else {
                        print("Access denied: \(errorMessage ?? "Unknown error")")
                    }
                    semaphore.signal()
                }

                semaphore.wait()

                if !result {
                    // The alert below is presented on the main queue and answered by tapping OK,
                    // and the wait after it blocks until that happens. On the main thread those
                    // two cannot both be true: the block can never run, the tap can never come,
                    // and the app hangs for good. So on the main thread the failure is simply
                    // raised - the caller still learns the key is unavailable, which is the point.
                    //
                    // Mode 3 reaches this only when the service's `authentication` flag is on and
                    // the read is on the main thread - a combination that would already be
                    // freezing today, so nothing that works now changes. Mode 2 reaches it far
                    // more often, because there the prompt is driven by the person's own sign-up
                    // enrollment rather than a server flag.
                    if Thread.isMainThread {
                        thrownError = NSError(domain: "KeychainError", code: -99, userInfo: [
                            NSLocalizedDescriptionKey: "Identity could not be verified for this read."
                        ])
                        return
                    }
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "Failed to Verify Identity".localized(), message: "Biometric authentication hasn't been set up/Biometric invalid.".localized(), preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {(_) in
                            semaphore.signal()
                        }))
                        UIApplication.shared.visibleViewController?.present(alertController, animated: true)
                    }
                    thrownError = NSError(domain: "KeychainError", code: -99, userInfo: nil)
                    semaphore.wait()
                    return
                }
            }

            if let already = deviceKeychainCachedKey {
                retrievedKey = already
                return
            }

            let query: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: keyAlias,
                kSecReturnData as String: true
            ]

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            guard status == errSecSuccess else {
                thrownError = NSError(domain: "KeychainError", code: Int(status), userInfo: nil)
                return
            }
            guard let keyData = item as? Data else {
                thrownError = NSError(domain: "KeyRetrievalError", code: -1, userInfo: nil)
                return
            }

            let key = SymmetricKey(data: keyData)
            deviceKeychainCachedKey = key
            retrievedKey = key
        }

        if let error = thrownError { throw error }
        guard let key = retrievedKey else {
            throw NSError(domain: "KeychainError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to get key"])
        }
        return key
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {(_) in
            if Database.shared.database == nil {
                exit(979)
            }
        }))
        UIApplication.shared.visibleViewController?.present(alertController, animated: true)
    }
    

    /// Says the biometric master key was successfully provisioned at some point.
    ///
    /// iOS does not mark a `biometryCurrentSet` item as invalid when the enrolled set changes -
    /// it removes it. `SecItemCopyMatching` then answers `errSecItemNotFound`, which is the same
    /// answer as "this device never had one", and those two need very different handling: one is
    /// a first launch, the other is unrecoverable data loss.
    ///
    /// So the fact of provisioning is recorded separately, in an item with no user-presence
    /// requirement of its own. The Android SDK gets this for free - an AndroidKeyStore alias
    /// survives its key's invalidation, so `KeyGeneratorUtil.isKeyGenerated()` is the marker and
    /// its callers pair it with `checkBiometricStatus()` (TFA.java:269, MFA.java:279).
    private var provisionedMarkerAccount: String { "io.nexilis.masterkey.provisioned" }

    private func hasProvisionedMarker() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: provisionedMarkerAccount,
            kSecReturnData as String: false
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    private func writeProvisionedMarker() {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: provisionedMarkerAccount
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = Data([1])
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        _ = SecItemAdd(add as CFDictionary, nil)
    }

    /// Opens the authentication window the main thread's reads reuse, and repairs a key whose
    /// protection no longer matches the app mode.
    ///
    /// Mode 1 holds the master key behind a biometric ACL, and the main queue can neither present
    /// that prompt nor wait for it. One confirmation here, off the main thread, authorises the
    /// reads that follow inside `authentication_duration` - which is what lets a chat list render
    /// its avatars and attachments at all.
    ///
    /// It also repairs the mode-downgrade case: a device that ran at mode 1 and now runs at 2 or
    /// 3 still has its key behind the ACL, and nothing else re-provisions it. That repair is the
    /// only thing this does at those modes - no prompt is presented for a key that has none.
    public func primeSecureStorage(completion: ((Error?) -> Void)? = nil) {
        installForegroundPrimingIfNeeded()
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Cheap and silent: reading attributes never asks for authentication, so a device
                // whose protection already matches its mode pays one Keychain lookup and stops.
                try self.generateAndStoreKey(self.keyAlias)
                if NXSecurityPolicy.bindsKeysToUserAuth() {
                    _ = try self.getMasterKey()
                }
                completion?(nil)
            } catch {
                completion?(error)
            }
        }
    }

    private var foregroundPrimingObserver: NSObjectProtocol?

    /// Re-opens the window each time the app comes back to the front.
    ///
    /// The reuse duration is wall-clock, so an app that spent a while in the background returns
    /// with it expired - and the first thing it does is draw a screen full of avatars from the
    /// main thread. Priming on the way in means those reads land inside a fresh window instead of
    /// each returning "authentication required" until something else happens to prime.
    ///
    /// Installed at mode 1 only; the other modes have no window to keep open.
    private func installForegroundPrimingIfNeeded() {
        guard NXSecurityPolicy.bindsKeysToUserAuth(), foregroundPrimingObserver == nil else { return }
        foregroundPrimingObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self, NXSecurityPolicy.bindsKeysToUserAuth() else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                _ = try? self.getMasterKey()
            }
        }
    }

    /// The key that unattended work uses, at `.hsa` only.
    ///
    /// At that mode the master key sits behind a Keychain biometric ACL, which is exactly what
    /// background work cannot satisfy: the outgoing thread persisting a thumbnail, the downloader
    /// writing a file, the push handler storing an attachment. The integration guide's answer is
    /// a separately classified, lower-privilege key rather than weakening the protected one, and
    /// this is that key - device-only, no user presence, and never holding anything a person
    /// reads from behind biometry.
    ///
    /// Created on first use, so a `.middle` or `.regular` install never grows one: those modes
    /// never route through here, and never write a file that would need it.
    func mediaKey() throws -> SymmetricKey {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: mediaKeyAlias
        ]

        var readQuery = baseQuery
        readQuery[kSecReturnData as String] = true
        readQuery[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(readQuery as CFDictionary, &item)
        if status == errSecSuccess, let keyData = item as? Data, keyData.count == 32 {
            return SymmetricKey(data: keyData)
        }
        guard status == errSecItemNotFound else {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Unable to read the unattended-work key"])
        }

        let generated = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        var addQuery = baseQuery
        addQuery[kSecValueData as String] = generated
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemDelete(baseQuery as CFDictionary)
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(addStatus), userInfo: [NSLocalizedDescriptionKey: "Unable to create the unattended-work key"])
        }
        return SymmetricKey(data: generated)
    }

    /// Who decides whether biometry is asked for before the key is handed over.
    ///
    /// `.middle` mirrors Android's Middle mode: the prompt appears when the user enrolled
    /// biometry during sign-up, and it can be answered another way rather than being the only
    /// door. `.regular` keeps the behaviour this library has always had - the service's
    /// `authentication` feature flag decides, and by default nothing is asked.
    private func shouldPromptForBiometry() -> Bool {
        if NXSecurityPolicy.mode == .middle {
            return Utils.getBiometricState() != nil
        }
        return Nexilis.checkingAccess(key: "authentication")
    }

    func deleteAllKeyMaterial() {
        masterKeyQueue.sync {
            deviceKeychainCachedKey = nil
            reusableAuthContext?.invalidate()
            reusableAuthContext = nil
            reusableAuthContextAt = nil
        }
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: provisionedMarkerAccount
        ] as CFDictionary)
        for alias in [keyAlias, prefsKeyAlias, serverKeyAlias, mediaKeyAlias] {
            let query: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: alias
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    func getPrefsKey() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: prefsKeyAlias,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: nil)
        }
        
        guard let keyData = item as? Data else {
            throw NSError(domain: "KeyRetrievalError", code: -1, userInfo: nil)
        }
        
        return SymmetricKey(data: keyData)
    }
    
    func encryptP(data: Data) throws -> Data {
        let key = try getPrefsKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decryptP(data: Data) throws -> Data {
        let key = try getPrefsKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func encryptD(data: Data) throws -> Data {
        let key = try getMasterKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    // Decrypt data
    func decryptD(data: Data) throws -> Data {
        let key = try getMasterKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

class StableDeviceFingerprint {
    static func generate() -> String {
        let device = UIDevice.current
        let screen = UIScreen.main
        let vendorId = device.identifierForVendor?.uuidString ?? "unknown"
        return [
            device.model,
            device.name,
            device.systemName,
            vendorId,
            "\(screen.bounds.width)x\(screen.bounds.height)"
        ].joined(separator: "|")
    }
}

class KeychainHelper {
    static func save(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
}

class AppSecretManager {
    static func getOrCreateKey() -> SymmetricKey {
        let keyTag = "io.nexilis.device.key.\(Bundle.main.infoDictionary?["CFBundleName"] as! String)"
        if let keyData = KeychainHelper.load(key: keyTag) {
            return SymmetricKey(data: keyData)
        } else {
            let key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }
            KeychainHelper.save(key: keyTag, data: keyData)
            return key
        }
    }
}

class HMACDeviceFingerprintNexilis {
    static func generate() -> String {
        let raw = StableDeviceFingerprint.generate()
        let key = AppSecretManager.getOrCreateKey()
        let mac = HMAC<SHA256>.authenticationCode(for: raw.data(using: .utf8)!, using: key)
        return Data(mac).base64EncodedString()
    }
}

class KeyManagerNexilis {
    static let tag = "io.nexilis.fido2.key.\(Bundle.main.infoDictionary?["CFBundleName"] as! String)".data(using: .utf8)!
    static let keyMarkerTag = "io.nexilis.fido2.key.\(Bundle.main.infoDictionary?["CFBundleName"] as! String).marker".data(using: .utf8)!
    static let markerAccount = "nexilis.key.\(Bundle.main.infoDictionary?["CFBundleName"] as! String).marker"
    static func generateKey() {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag
            ]
        ]

        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            print("Failed to generate RSA key: \(String(describing: error))")
            return
        }

        print("RSA key and marker generated successfully.")
        return
    }
    
    static func saveMarker() {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: markerAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary) // Clean up if exists

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: markerAccount,
            kSecValueData as String: Data([1]),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        print("Marker save status: \(status)") // Should be 0
    }
    
    static func getPublicKey(privateKey: SecKey) -> SecKey? {
        return SecKeyCopyPublicKey(privateKey)
    }
    
    static func getRSAX509PublicKeyBase64(privateKey: SecKey) -> String? {
        guard let publicKey = getPublicKey(privateKey: privateKey) else {
            print("No public key available")
            return nil
        }

        var error: Unmanaged<CFError>?
        guard let pubKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            print("Failed to extract public key: \(String(describing: error))")
            return nil
        }

        // X.509 header for RSA 2048 (OID: 1.2.840.113549.1.1.1 for RSA encryption)
        let rsaOIDHeader: [UInt8] = [
            0x30, 0x82, // SEQUENCE
            // ... we'll calculate length dynamically
        ]

        // Standard ASN.1 header for RSA public key
        let rsaAlgorithmIdentifier: [UInt8] = [
            0x30, 0x0D,
            0x06, 0x09,
            0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01, // OID: 1.2.840.113549.1.1.1
            0x05, 0x00 // NULL
        ]

        // Wrap raw key inside BIT STRING
        let pubKeyBitStringPrefix: [UInt8] = [0x03] // BIT STRING
        let pubKeyBitString = [0x00] + [UInt8](pubKeyData) // prepend 0x00 for padding

        let bitStringLength = pubKeyBitString.count
        let fullPubKeyBitString = pubKeyBitStringPrefix + encodeASN1Length(bitStringLength) + pubKeyBitString

        let algorithmBlock = rsaAlgorithmIdentifier
        let subjectPublicKeyInfo = [0x30] + encodeASN1Length(algorithmBlock.count + fullPubKeyBitString.count) +
            algorithmBlock + fullPubKeyBitString

        let finalData = Data(subjectPublicKeyInfo)
        return finalData.base64EncodedString()
    }
    
    private static func encodeASN1Length(_ length: Int) -> [UInt8] {
        if length < 128 {
            return [UInt8(length)]
        }

        var len = length
        var bytes: [UInt8] = []
        while len > 0 {
            bytes.insert(UInt8(len & 0xFF), at: 0)
            len = len >> 8
        }

        return [0x80 | UInt8(bytes.count)] + bytes
    }
    
    static func getPrivateKey(useBiometric: Bool = true, isSaveState: Bool = false) -> SecKey? {
        if useBiometric {
            let semaphore = DispatchSemaphore(value: 0)
            var result = false

            Utils.authenticateWithBiometrics(isSaveState: isSaveState) { success, errorMessage in
                if success {
                    print("Access granted!")
                    result = true
                } else {
                    print("Access denied: \(errorMessage ?? "Unknown error")")
                }
                semaphore.signal()
            }

            semaphore.wait()

            if !result {
                return nil
            }
        }
        let context = LAContext()
        context.localizedReason = "Verify your identity to continue with login.".localized()

        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecReturnRef as String: true,
            kSecUseAuthenticationContext as String: context
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let key = item else {
            print("Private key not found. Status: \(status)")
            return nil
        }

        return (key as! SecKey)
    }
    
    static func deleteKey() {
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag
        ]
        SecItemDelete(keyQuery as CFDictionary)
    }
    
    static func hasGeneratedKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: markerAccount,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func deleteMarker() {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: markerAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)
    }
    
    static func sign(data: Data, privateKey: SecKey) -> Data? {
        let algorithm = SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA256

        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            print("Algorithm not supported for this key.")
            return nil
        }

        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(privateKey,
                                                    algorithm,
                                                    data as CFData,
                                                    &error) as Data? else {
            print("Failed to sign: \(String(describing: error))")
            return nil
        }

        return signature
    }
}

class BiometricStateManager {
    func authenticateAndSaveState(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Daftarkan biometric anda!") { success, _ in
                if success, let domainState = context.evaluatedPolicyDomainState {
                    Utils.setBiometricState(value: domainState)
                }
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    
    func hasBiometricStateChanged(completion: @escaping (Bool, Int) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Validasi biometric anda!") { success, _ in
                if success, let currentState = context.evaluatedPolicyDomainState,
                   let savedState = Utils.getBiometricState() {
                    SecureUserDefaults.shared.set(Date(), forKey: "lastAuthenticationTime")
                    completion(savedState == currentState, 1)
                } else {
                    completion(false, 0)
                }
            }
        } else {
            completion(false, 0)
        }
    }
}


