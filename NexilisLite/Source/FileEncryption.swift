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
    
    static let shared = FileEncryption()

    private init() {}
    
    func generateIV() -> Data {
        var iv = Data(count: kCCBlockSizeAES128)
        let result = iv.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, $0.baseAddress!)
        }
        precondition(result == errSecSuccess, "Failed to generate IV")
        return iv
    }
    
    func readDataFromFile(fileURL: URL) -> Data? {
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            print("Failed to read file: \(error)")
            return nil
        }
    }
    
    func wipeData(_ data: inout Data) {
        data.resetBytes(in: 0..<data.count)
        data.count = 0
    }
    
    func encryptFile(_ fileURL: URL) -> Data? {
        guard let fileData = readDataFromFile(fileURL: fileURL) else { return nil }
        do {
            let sealedBox = try AES.GCM.seal(fileData, using: MasterKeyUtil.shared.getMasterKey())
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    func encryptFile(_ inputURL: URL, _ outputURL: URL, _ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let iv = generateIV()
        let data = try Data(contentsOf: inputURL)
        let encryptedData = Data(count: data.count + kCCBlockSizeAES128)
        var finalData = encryptedData
        
        var numBytesEncrypted: size_t = 0

        let status = finalData.withUnsafeMutableBytes { encryptedBytes in
            data.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, keyData.count,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, data.count,
                            encryptedBytes.baseAddress, encryptedData.count,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }

        guard status == kCCSuccess else {
            throw NSError(domain: "EncryptionError", code: Int(status), userInfo: nil)
        }

        finalData.count = numBytesEncrypted

        // Write IV and encrypted data to the output file
        var outputData = Data()
        outputData.append(iv)
        outputData.append(finalData)
        try outputData.write(to: outputURL)
    }
    
    func decryptToMemory(_ encryptedData: Data) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: MasterKeyUtil.shared.getMasterKey())
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }

    func decryptToMemory(_ encryptedData: URL) throws -> Data? {
        let encryptedData = try Data(contentsOf: encryptedData)
        return decryptToMemory(encryptedData)
    }
    
    func decryptToMemory(_ encryptedURL: URL, _ key: SymmetricKey) throws -> Data? {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let encryptedData = try Data(contentsOf: encryptedURL)
        let iv = encryptedData.prefix(kCCBlockSizeAES128)
        let cipherText = encryptedData.suffix(from: kCCBlockSizeAES128)
        let decryptedData = Data(count: cipherText.count + kCCBlockSizeAES128)
        var finalData = decryptedData
        var numBytesDecrypted: size_t = 0

        let status = finalData.withUnsafeMutableBytes { decryptedBytes in
            cipherText.withUnsafeBytes { cipherBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, keyData.count,
                            ivBytes.baseAddress,
                            cipherBytes.baseAddress, cipherText.count,
                            decryptedBytes.baseAddress, decryptedData.count,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }

        guard status == kCCSuccess else {
            throw NSError(domain: "DecryptionError", code: Int(status), userInfo: nil)
        }

        finalData.count = numBytesDecrypted
        return finalData
    }
    
    
}
