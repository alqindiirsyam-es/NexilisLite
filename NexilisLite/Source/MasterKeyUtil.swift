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
    
    func generateAndStoreServerKey(_ key_s: String) throws {
        try generateAndStoreKey(serverKeyAlias, key_s: key_s)
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
    
    func getServerKeyIV() -> Data {
        let keyData = base64toData(Utils.getSecureFolderEncryptIv()) ?? Data()
        return keyData
    }
    
    func getMasterKey() throws -> SymmetricKey {
        if (Nexilis.checkingAccess(key: "authentication") && isDeviceNotSecure()) {
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
    
    func getServerKey() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: serverKeyAlias,
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
