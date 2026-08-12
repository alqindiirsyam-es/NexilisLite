//
//  FileEncryption.swift
//  NexilisLite
//
//  Created by Maronakins on 03/12/24.
//

import Foundation
import CryptoKit
import CommonCrypto

public class FileEncryption {
    
    public var aesKey: SymmetricKey?
    public var aesIV: Data?
    
    public static let shared = FileEncryption()

    private init() {}
    
    public func readSecure(filename: String, withoutBiometric: Bool = false) throws -> Data? {
        if Utils.getFeatureAccess().isEmpty {
            return nil
        }
        let fileManager = FileManager.default
        let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentDir.appendingPathComponent("Secure").appendingPathComponent(filename)

        let encryptedData = try Data(contentsOf: fileURL)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: MasterKeyUtil.shared.getMasterKey(withoutBiometric: withoutBiometric))

        return decryptedData
    }
    
    public func writeSecure(filename: String? = nil, data: Data? = nil, withoutBiometric: Bool = false) throws {
        do {
            let fileManager = FileManager.default

            // Get the app's Documents directory
            let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

            // Optional: Create a "Secure" subdirectory
            let secureDir = documentDir.appendingPathComponent("Secure", isDirectory: true)
            if !fileManager.fileExists(atPath: secureDir.path) {
                try fileManager.createDirectory(at: secureDir, withIntermediateDirectories: true)
            }

            // Create the file URL
            let fileURL = secureDir.appendingPathComponent(filename ?? "")

            // Encrypt the data
            let sealedBox = try AES.GCM.seal(data ?? Data(), using: MasterKeyUtil.shared.getMasterKey(withoutBiometric: withoutBiometric))
            let encryptedData = sealedBox.combined!

            // Write encrypted data to file
            try encryptedData.write(to: fileURL)
        } catch {
            
        }
    }
    
    public func isSecureExists(filename: String) -> Bool {
        do {
            let fileManager = FileManager.default
            let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileURL = documentDir.appendingPathComponent("Secure").appendingPathComponent(filename)
            return fileManager.fileExists(atPath: fileURL.path)
        } catch {
            return false
        }
    }
    
    public func decryptFileFromServer(data: Data) -> Data? {
        do {
            if aesKey == nil && !Utils.getSecureFolderEncrypt().isEmpty {
                aesKey = try getAESKey()
            }
            if aesIV == nil && !Utils.getSecureFolderEncryptIv().isEmpty {
                aesIV = try getAESIV()
            }
        } catch {
            print("Error retrieving AES key or IV: \(error)")
            return nil
        }
        
        guard let key = aesKey, let iv = aesIV else {
            return nil
        }
        
        do {
            let nonce = try AES.GCM.Nonce(data: iv)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: data.dropLast(16), tag: data.suffix(16))
            let decryptedData = try AES.GCM.open(sealedBox, using: key)

            return decryptedData
        } catch {
//            print("Decryption error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func encryptFileToServer(data: Data) -> Data? {
        do {
            if aesKey == nil && !Utils.getSecureFolderEncrypt().isEmpty {
                aesKey = try getAESKey()
            }
            if aesIV == nil && !Utils.getSecureFolderEncryptIv().isEmpty {
                aesIV = try getAESIV()
            }
        } catch {
            print("Error retrieving AES key or IV: \(error)")
            return nil
        }
        
        guard let key = aesKey, let iv = aesIV else {
            return nil
        }
        
        do {
            let nonce = try AES.GCM.Nonce(data: iv)
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            var encryptedData = sealedBox.ciphertext
            encryptedData.append(sealedBox.tag)

            return encryptedData
        } catch {
//            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    // Fix: reusable version of the on-demand key-loading already done inline in
    // decryptFileFromServer/encryptFileToServer. Needed so Database.swift can safely
    // reopen the DB for a background push write after enterBackground() cleared the key -
    // this reads from Keychain-backed storage, no biometric/user interaction required.
    public func ensureKeyLoaded() {
        do {
            if aesKey == nil && !Utils.getSecureFolderEncrypt().isEmpty {
                aesKey = try getAESKey()
            }
            if aesIV == nil && !Utils.getSecureFolderEncryptIv().isEmpty {
                aesIV = try getAESIV()
            }
        } catch {
            print("Error retrieving AES key or IV: \(error)")
        }
    }
    
    private func getAESKey() throws -> SymmetricKey {
        let keyData = Data(base64Encoded: Utils.getSecureFolderEncrypt(), options: .ignoreUnknownCharacters)!
        return SymmetricKey(data: keyData)
    }
    
    private func getAESIV() throws -> Data {
        return Data(base64Encoded: Utils.getSecureFolderEncryptIv(), options: .ignoreUnknownCharacters)!
    }
    
    func wipeFolderOldSecure() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let secureDir = documentsDirectory.appendingPathComponent("secure")
        if FileManager.default.fileExists(atPath: secureDir.path) {
            do {
                let fileNames = try FileManager.default.contentsOfDirectory(atPath: secureDir.path)
                for fileName in fileNames {
                    let filePath = secureDir.appendingPathComponent(fileName)
                    try FileManager.default.removeItem(atPath: filePath.path)
                }
                try FileManager.default.removeItem(atPath: secureDir.path)
                print("Secure folder deleted successfully")
                wipeFolderDocument()
            } catch {
                print("Error deleting secure folder")
            }
        }
    }
    
    func wipeFolderDocument() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        if FileManager.default.fileExists(atPath: documentsDirectory.path) {
            do {
                let fileNames = try FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path)
                for fileName in fileNames {
                    let filePath = documentsDirectory.appendingPathComponent(fileName)
                    if fileName == "encrypted_db_es.db" {
                        continue
                    }
                    try FileManager.default.removeItem(atPath: filePath.path)
                }
            } catch {
                print("Error deleting secure folder")
            }
        }
    }
    
}
