import Foundation
import CryptoKit
import UIKit
import CoreImage.CIFilterBuiltins

final class TOTPManager {

    // MARK: - Constants

    static let defaultPeriod: Int = 30
    static let defaultDigits: Int = 6
    static let backupCodeCount: Int = 10

    // MARK: - Secret Key

    /// Generate Base32 secret (20 bytes, Google Auth compatible)
    static func generateSecretKey() -> String {
        var bytes = [UInt8](repeating: 0, count: 20)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return base32Encode(Data(bytes)).replacingOccurrences(of: "=", with: "")
    }

    // MARK: - TOTP

    static func generateTOTP(
        secret: String,
        period: Int = defaultPeriod,
        digits: Int = defaultDigits,
        timestamp: TimeInterval = Date().timeIntervalSince1970
    ) -> String? {
        let counter = UInt64(timestamp) / UInt64(period)
        return generateHOTP(secret: secret, counter: counter, digits: digits)
    }

    static func verifyTOTP(
        secret: String,
        code: String,
        window: Int = 1,
        period: Int = defaultPeriod
    ) -> Bool {
        let currentCounter = UInt64(Date().timeIntervalSince1970) / UInt64(period)

        for i in -window...window {
            let counter = currentCounter + UInt64(i)
            if generateHOTP(secret: secret, counter: counter) == code {
                return true
            }
        }
        return false
    }

    // MARK: - HOTP Core

    static func generateHOTP(
        secret: String,
        counter: UInt64,
        digits: Int = defaultDigits
    ) -> String? {

        guard let keyData = base32Decode(secret) else { return nil }

        var counterBE = counter.bigEndian
        let counterData = Data(
            bytes: &counterBE,
            count: MemoryLayout.size(ofValue: counterBE)
        )

        let key = SymmetricKey(data: keyData)
        let hmac = HMAC<Insecure.SHA1>.authenticationCode(
            for: counterData,
            using: key
        )
        
        let hash = Array(hmac)

        guard let last = hash.last else { return nil }
        let offset = Int(last & 0x0F)

        guard offset + 3 < hash.count else { return nil }

        let binary =
            ((UInt32(hash[offset]) & 0x7F) << 24) |
            ((UInt32(hash[offset + 1]) & 0xFF) << 16) |
            ((UInt32(hash[offset + 2]) & 0xFF) << 8) |
            (UInt32(hash[offset + 3]) & 0xFF)

        let otp = binary % UInt32(pow(10.0, Double(digits)))
        return String(format: "%0*u", digits, otp)
    }

    // MARK: - QR Code (otpauth://)

    static func generateQRCode(
        account: String,
        issuer: String,
        secret: String,
        size: CGFloat = 512
    ) -> UIImage? {

        let uri =
        "otpauth://totp/\(issuer):\(account)" +
        "?secret=\(secret)&issuer=\(issuer)"

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(uri.utf8)

        guard let outputImage = filter.outputImage else { return nil }

        let scaleX = size / outputImage.extent.size.width
        let scaleY = size / outputImage.extent.size.height
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Remaining Seconds

    static func remainingSeconds(period: Int = defaultPeriod) -> Int {
        period - Int(Date().timeIntervalSince1970) % period
    }
}

private extension TOTPManager {

    static let base32Alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

    static func base32Encode(_ data: Data) -> String {
        var bits = ""
        for byte in data {
            bits += String(byte, radix: 2).leftPadded(to: 8)
        }

        var result = ""
        for i in stride(from: 0, to: bits.count, by: 5) {
            let start = bits.index(bits.startIndex, offsetBy: i)
            let end = bits.index(start, offsetBy: 5, limitedBy: bits.endIndex) ?? bits.endIndex
            let chunk = String(bits[start..<end]).rightPadded(to: 5)
            let index = Int(chunk, radix: 2)!
            result.append(base32Alphabet[index])
        }

        return result
    }

    static func base32Decode(_ string: String) -> Data? {
        let cleaned = string.uppercased().replacingOccurrences(of: "=", with: "")
        var bits = ""

        for char in cleaned {
            guard let index = base32Alphabet.firstIndex(of: char) else { return nil }
            bits += String(index, radix: 2).leftPadded(to: 5)
        }

        var data = Data()
        for i in stride(from: 0, to: bits.count, by: 8) {
            let start = bits.index(bits.startIndex, offsetBy: i)
            let end = bits.index(start, offsetBy: 8, limitedBy: bits.endIndex) ?? bits.endIndex
            if let byte = UInt8(bits[start..<end], radix: 2) {
                data.append(byte)
            }
        }
        return data
    }
}

extension TOTPManager {

    struct BackupCode: Codable {
        let codeHash: String
        var isUsed: Bool
        var usedAt: TimeInterval?
    }

    static func generateBackupCodes(count: Int = backupCodeCount) -> [String] {
        (0..<count).map { _ in
            let number = String(format: "%08d", Int.random(in: 0..<100_000_000))
            return "\(number.prefix(4))-\(number.suffix(4))"
        }
    }

    static func hashBackupCode(_ code: String) -> String {
        let data = Data(code.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}


extension TOTPManager {

    /// Present TOTP dialog (equivalent to Android openTOTPDialog)
    static func openTOTPDialog(
        from presentingViewController: UIViewController,
        userId: String,
        password: String,
        onSuccess: (() -> Void)? = nil,
        onFailure: (() -> Void)? = nil
    ) {

        let totpVC = TOTPInputViewController(
            userId: userId,
            password: password
        )

        totpVC.modalPresentationStyle = .fullScreen

        totpVC.onSuccess = {
            onSuccess?()
        }

        totpVC.onFailure = {
            onFailure?()
        }

        presentingViewController.present(
            totpVC,
            animated: true
        )
    }
}

extension String {

    func leftPadded(to length: Int, with character: Character = "0") -> String {
        guard count < length else { return self }
        return String(repeating: character, count: length - count) + self
    }

    func rightPadded(to length: Int, with character: Character = "0") -> String {
        guard count < length else { return self }
        return self + String(repeating: character, count: length - count)
    }
}
