//
//  FileEncryption.swift
//  NexilisLite
//
//  Created by Maronakins on 03/12/24.
//

import Foundation
import CryptoKit
import CommonCrypto
import AVFoundation
import UniformTypeIdentifiers
import ObjectiveC
import NexilisZTA

public class FileEncryption {
    
    public var aesKey: SymmetricKey?
    public var aesIV: Data?
    
    public static let shared = FileEncryption()

    private init() {}
    
    // Marker for a file written by unattended work under the lower-privilege media key, which
    // only `.hsa` has. Reading dispatches on the marker rather than on the caller's
    // `withoutBiometric` flag, because the two are not always the same caller: a thumbnail is
    // written by the outgoing thread and read by a chat row. Guessing - trying one key and
    // falling back to the other on failure - would present biometry before discovering it was
    // the wrong key.
    //
    // `.middle` and `.regular` never write this marker, so their files, and every file written
    // before this existed, take exactly the path they always did.
    private static let mediaEnvelopeMagic = Data([0x4e, 0x58, 0x4d, 0x31]) // NXM1

    public func readSecure(filename: String, withoutBiometric: Bool = false) throws -> Data? {
        if Utils.getFeatureAccess().isEmpty {
            return nil
        }
        let fileManager = FileManager.default
        let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentDir.appendingPathComponent("Secure").appendingPathComponent(filename)

        let encryptedData = try Data(contentsOf: fileURL)

        // Only .hsa writes this marker, so only .hsa looks for it. A sealed box begins with a
        // random 96-bit nonce, and one file in 2^32 starts with these four bytes by chance -
        // across an installed base that is not a rounding error, and misreading one as a media
        // envelope would mean a file that no longer opens. Modes 2 and 3 have written millions
        // of files already; they never take this branch at all.
        if NXSecurityPolicy.bindsKeysToUserAuth(), encryptedData.starts(with: Self.mediaEnvelopeMagic) {
            let combined = Data(encryptedData.dropFirst(Self.mediaEnvelopeMagic.count))
            let sealedBox = try AES.GCM.SealedBox(combined: combined)
            return try AES.GCM.open(sealedBox, using: MasterKeyUtil.shared.mediaKey())
        }

        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: MasterKeyUtil.shared.getMasterKey(withoutBiometric: withoutBiometric))

        return decryptedData
    }
    
    public func writeSecure(filename: String? = nil, data: Data? = nil, withoutBiometric: Bool = false) throws {
        let fileManager = FileManager.default
        let documentDir = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let secureDir = documentDir.appendingPathComponent("Secure", isDirectory: true)
        if !fileManager.fileExists(atPath: secureDir.path) {
            try fileManager.createDirectory(at: secureDir, withIntermediateDirectories: true)
        }
        let fileURL = secureDir.appendingPathComponent(filename ?? "")

        // Unattended work at .hsa writes under the media key and says so in the file, so the
        // read side never has to present biometry to find out. Every other mode, and every
        // attended write, is untouched.
        let unattendedAtHSA = withoutBiometric && NXSecurityPolicy.bindsKeysToUserAuth()
        let key = unattendedAtHSA
            ? try MasterKeyUtil.shared.mediaKey()
            : try MasterKeyUtil.shared.getMasterKey(withoutBiometric: withoutBiometric)

        let sealedBox = try AES.GCM.seal(data ?? Data(), using: key)
        guard let combined = sealedBox.combined else {
            throw NSError(domain: "NexilisFileEncryption", code: -3101, userInfo: [NSLocalizedDescriptionKey: "AES-GCM failed to create a combined sealed box"])
        }
        var encryptedData = unattendedAtHSA ? Self.mediaEnvelopeMagic : Data()
        encryptedData.append(combined)
        try encryptedData.write(to: fileURL, options: .atomic)
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
    
    // Server transport envelope: ASCII "NXG1" || CryptoKit combined sealed box
    // (12-byte random nonce || ciphertext || 16-byte tag). The nonce is generated
    // independently for every encryption.
    //
    // At .hsa this is the only accepted format, in both directions: the fixed-IV GCM it replaced
    // reused one nonce for every file under one key, which is the whole of NX-02.
    //
    // At .middle and .regular the backend has not necessarily migrated yet, and a client that
    // writes a format its server cannot read is a client that has stopped working. The envelope
    // is a backend contract, not a client posture, and a .middle host talks to the same UCPaaS
    // backend a .regular one does - so both read either format and write whichever the server
    // has configured them for: NXG1 when no legacy IV is set, legacy when one is. Clearing
    // `secure_folder_encrypt_iv` on the server is what moves a host onto NXG1, per host, once
    // that backend is ready.
    private static let serverEnvelopeMagic = Data([0x4e, 0x58, 0x47, 0x31]) // NXG1

    public func decryptFileFromServer(data: Data) -> Data? {
        do {
            if aesKey == nil && !Utils.getSecureFolderEncrypt().isEmpty {
                aesKey = try getAESKey()
            }
            guard let key = aesKey else { return nil }

            if data.starts(with: Self.serverEnvelopeMagic) {
                let combined = Data(data.dropFirst(Self.serverEnvelopeMagic.count))
                if let sealedBox = try? AES.GCM.SealedBox(combined: combined),
                   let opened = try? AES.GCM.open(sealedBox, using: key) {
                    return opened
                }
                // Not necessarily an NXG1 envelope: a legacy payload whose ciphertext happens to
                // begin with these four bytes looks exactly like one. Rare - 1 in 2^32 - but the
                // installed base is large enough to meet it, and the cost of being sure is one
                // failed open. Falling through is what keeps that file readable.
            }

            guard !NXSecurityPolicy.isHSA() else { return nil }
            return try legacyDecryptFromServer(data: data, key: key)
        } catch {
            return nil
        }
    }

    func encryptFileToServer(data: Data) -> Data? {
        do {
            if aesKey == nil && !Utils.getSecureFolderEncrypt().isEmpty {
                aesKey = try getAESKey()
            }
            guard let key = aesKey else { return nil }

            // Legacy while the server still speaks it. The IV alone cannot be the signal: it is
            // also half the SQLCipher password, so an operator clearing it to move a host onto
            // NXG1 would lock that host out of its own database. `secure_folder_envelope` is the
            // switch for this decision, and it defaults to legacy.
            if !NXSecurityPolicy.isHSA(),
               Utils.getSecureFolderEnvelope() != "2",
               !Utils.getSecureFolderEncryptIv().isEmpty {
                return try legacyEncryptToServer(data: data, key: key)
            }

            let sealedBox = try AES.GCM.seal(data, using: key) // fresh 96-bit nonce
            guard let combined = sealedBox.combined else { return nil }
            var envelope = Self.serverEnvelopeMagic
            envelope.append(combined)
            return envelope
        } catch {
            return nil
        }
    }

    /// The pre-NXG1 wire format: raw ciphertext || 16-byte tag, under the server-supplied fixed
    /// IV. Unreachable at `.hsa`, and elsewhere only for a backend still speaking it.
    private func legacyDecryptFromServer(data: Data, key: SymmetricKey) throws -> Data? {
        if aesIV == nil && !Utils.getSecureFolderEncryptIv().isEmpty {
            aesIV = try getAESIV()
        }
        guard let iv = aesIV else { return nil }
        let nonce = try AES.GCM.Nonce(data: iv)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce,
                                              ciphertext: data.dropLast(16),
                                              tag: data.suffix(16))
        return try AES.GCM.open(sealedBox, using: key)
    }

    private func legacyEncryptToServer(data: Data, key: SymmetricKey) throws -> Data? {
        if aesIV == nil {
            aesIV = try getAESIV()
        }
        guard let iv = aesIV else { return nil }
        let nonce = try AES.GCM.Nonce(data: iv)
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        var encrypted = sealedBox.ciphertext
        encrypted.append(sealedBox.tag)
        return encrypted
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
        guard let keyData = Data(base64Encoded: Utils.getSecureFolderEncrypt(), options: .ignoreUnknownCharacters), keyData.count == 32 else {
            throw NSError(domain: "NexilisFileEncryption", code: -3102, userInfo: [NSLocalizedDescriptionKey: "Invalid server AES-256 key"])
        }
        return SymmetricKey(data: keyData)
    }
    
    private func getAESIV() throws -> Data {
        guard let iv = Data(base64Encoded: Utils.getSecureFolderEncryptIv(), options: .ignoreUnknownCharacters) else {
            throw NSError(domain: "NexilisFileEncryption", code: -3103, userInfo: [NSLocalizedDescriptionKey: "Invalid legacy server IV"])
        }
        return iv
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
    
    func hardWipeAllDocuments() {
        aesKey = nil
        aesIV = nil
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        do {
            let names = try FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path)
            for name in names {
                try? FileManager.default.removeItem(at: documentsDirectory.appendingPathComponent(name))
            }
        } catch {
            // Hard wipe is best-effort locally; server-side token revocation has already occurred.
        }
    }

}

/// Serves an already-decrypted asset to `AVPlayer` from memory.
///
/// The ordinary way to play a protected attachment is to decrypt it into the temporary directory
/// and hand `AVPlayer` that file URL. App mode 1 does not allow that: the point of the mode is
/// that decrypted content never lands on disk outside the secure store, so that path is closed
/// and broadcast video simply did not play there.
///
/// AVFoundation's own answer is a resource loader. The asset is built on a URL whose scheme the
/// system does not recognise, so every read AVPlayer performs is routed here instead of to the
/// filesystem or the network, and each byte range is answered from the buffer this object holds.
///
/// Modes 2 and 3 keep the temporary-file path unchanged - they have no reason to pay for this,
/// and changing how they play media is exactly what must not happen to hosts already shipping.
final class SecureMediaPlayback: NSObject, AVAssetResourceLoaderDelegate {

    /// The scheme has to be one AVFoundation will not try to handle itself; anything unknown
    /// routes to the delegate, and this one is unambiguous in logs.
    private static let scheme = "nexilis-secure"

    private let payload: Data
    private let contentType: String
    private let queue = DispatchQueue(label: "io.nexilis.secureMediaPlayback")

    private init(payload: Data, contentType: String) {
        self.payload = payload
        self.contentType = contentType
    }

    /// Builds a player item backed by `data`, and ties the loader's lifetime to `owner`.
    ///
    /// `AVAssetResourceLoader` holds its delegate weakly, so without an owner the loader would be
    /// released the moment this returns and every read would fail. Associating it with the view
    /// controller that presents the player keeps it alive for exactly as long as playback can
    /// happen, and lets it go with the screen.
    static func playerItem(for data: Data, filename: String, retainedBy owner: AnyObject) -> AVPlayerItem? {
        guard !data.isEmpty else { return nil }

        // A path component keeps the extension visible to AVFoundation's own type sniffing; the
        // percent-encoding keeps a filename with spaces or punctuation from breaking the URL.
        let name = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "asset"
        guard let url = URL(string: "\(scheme):///\(name)") else { return nil }

        let loader = SecureMediaPlayback(payload: data, contentType: contentType(for: filename))
        let asset = AVURLAsset(url: url)
        asset.resourceLoader.setDelegate(loader, queue: loader.queue)
        objc_setAssociatedObject(owner, &SecureMediaPlayback.ownerKey, loader, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return AVPlayerItem(asset: asset)
    }

    private static var ownerKey: UInt8 = 0

    private static func contentType(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension
        if !ext.isEmpty, let type = UTType(filenameExtension: ext), type.conforms(to: .audiovisualContent) {
            return type.identifier
        }
        // Everything this path carries is recorded or transcoded as MP4, and AVFoundation needs a
        // concrete answer before it will ask for a single byte.
        return UTType.mpeg4Movie.identifier
    }

    // MARK: - AVAssetResourceLoaderDelegate

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if let information = loadingRequest.contentInformationRequest {
            information.contentType = contentType
            information.contentLength = Int64(payload.count)
            // Without this AVPlayer has to read the whole asset before it can start, and seeking
            // is not offered at all.
            information.isByteRangeAccessSupported = true
        }

        if let dataRequest = loadingRequest.dataRequest {
            // `currentOffset`, not `requestedOffset`: AVFoundation reissues a partially satisfied
            // request from where the last response stopped, and answering from the original
            // offset would resend bytes it already has and corrupt the stream.
            let start = Int(dataRequest.currentOffset)
            guard start >= 0, start <= payload.count else {
                loadingRequest.finishLoading(with: NSError(
                    domain: "NexilisSecureMedia", code: -4101,
                    userInfo: [NSLocalizedDescriptionKey: "Requested range lies outside the asset"]))
                return true
            }

            let remaining = payload.count - start
            let length = dataRequest.requestsAllDataToEndOfResource
                ? remaining
                : min(Int(dataRequest.requestedLength), remaining)
            if length > 0 {
                dataRequest.respond(with: payload.subdata(in: start ..< (start + length)))
            }
        }

        loadingRequest.finishLoading()
        return true
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        // Nothing is in flight - every request is answered synchronously from memory - so there is
        // no work to unwind here.
    }
}
