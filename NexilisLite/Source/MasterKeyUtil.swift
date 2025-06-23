//
//  SecureStorage.swift
//  Pods
//
//  Created by Qindi on 02/12/24.
//

import CryptoKit
import LocalAuthentication


public class MasterKeyUtil {
    static let shared = MasterKeyUtil()
    private let keyAlias = "_iosx_security_master_key"
    private let prefsKeyAlias = "_iosx_security_master_key_easysoft_"
    private let serverKeyAlias = "_iosx_security_master_key_server_"

    private init() {}
    
    func base64toData(_ base64: String) -> Data? {
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        return data
    }
    
    func generateAndStoreKey(_ alias: String, key_s: String? = nil) throws {
        if try isKeyExists(keyAliasCode: alias) {
//            print("Master Key already exists, skipping generation.")
            return
        }
        
        let key = (key_s != nil) ? nil : SymmetricKey(size: .bits256)
        guard let keyData = key?.withUnsafeBytes({ Data($0) }) ?? base64toData(key_s!) else {
            return
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: alias,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary) // Remove if it exists
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: nil)
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
    
    func getMasterKey() throws -> SymmetricKey {
        if Nexilis.checkingAccess(key: "authentication") && isDeviceNotSecure() && Nexilis.dispatch == nil {
            var result = false
            Nexilis.dispatch = DispatchGroup()
            Nexilis.dispatch?.enter()
            Utils.authenticateWithBiometrics { success, errorMessage in
                if success {
                    print("Access granted!")
                    result = true
                } else {
                    print("Access denied: \(errorMessage ?? "Unknown error")")
                }
                if let dispatch = Nexilis.dispatch {
                    dispatch.leave()
                }
            }
            Nexilis.dispatch?.wait()
            Nexilis.dispatch = nil
            if !result {
                DispatchQueue.main.async {
                    Utils.showAlert(title: "Failed to get Master Key".localized(), message: "Biometric authentication hasn't been set up/Biometric invalid.".localized())
                }
                throw NSError(domain: "KeychainError", code: -99, userInfo: nil)
            }
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias,
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
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
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
        let accessControl = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [.userPresence], nil)!

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessControl as String: accessControl
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
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
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
    
    static func getPrivateKey() -> SecKey? {
        let context = LAContext()
        context.localizedReason = "Verify your identity to continue with login.".localized()

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print("Biometric auth not available: \(String(describing: error))")
            return nil
        }

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
