import Foundation
import CommonCrypto

class TOTPGenerator {
    
    static func generateTOTP(base32Secret: String, digits: Int, timeStepSeconds: Int) throws -> String {
        let secret = base32Decode(base32Secret)
        var timeStep = UInt64(Date().timeIntervalSince1970) / UInt64(timeStepSeconds)
        var data = [UInt8](repeating: 0, count: 8)
        
        // convert timeStep to byte[8]
        for i in stride(from: 7, through: 0, by: -1) {
            data[i] = UInt8(timeStep & 0xFF)
            timeStep >>= 8
        }
        
        let hash = try hmacSha1(key: secret, data: data)
        
        // dynamic truncation
        let offset = Int(hash[hash.count - 1] & 0x0F)
        let binary =
            ((Int(hash[offset]) & 0x7f) << 24) |
            ((Int(hash[offset + 1]) & 0xff) << 16) |
            ((Int(hash[offset + 2]) & 0xff) << 8) |
            (Int(hash[offset + 3]) & 0xff)
        
        let otp = binary % Int(pow(10.0, Double(digits)))
        return String(format: "%0\(digits)d", otp)
    }
    
    static func generateHOTP(base32Secret: String, digits: Int, counter: UInt64) throws -> String {
        let secret = base32Decode(base32Secret)
        var counterValue = counter
        var data = [UInt8](repeating: 0, count: 8)
        
        // convert counter to byte[8]
        for i in stride(from: 7, through: 0, by: -1) {
            data[i] = UInt8(counterValue & 0xFF)
            counterValue >>= 8
        }
        
        let hash = try hmacSha1(key: secret, data: data)
        
        // dynamic truncation
        let offset = Int(hash[hash.count - 1] & 0x0F)
        let binary =
            ((Int(hash[offset]) & 0x7f) << 24) |
            ((Int(hash[offset + 1]) & 0xff) << 16) |
            ((Int(hash[offset + 2]) & 0xff) << 8) |
            (Int(hash[offset + 3]) & 0xff)
        
        let otp = binary % Int(pow(10.0, Double(digits)))
        return String(format: "%0\(digits)d", otp)
    }
    
    // MARK: - Base32 Decoder
    private static func base32Decode(_ base32: String) -> [UInt8] {
        let base32Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let clean = base32.replacingOccurrences(of: "=", with: "").uppercased()
        
        var bytes = [UInt8]()
        var buffer = 0
        var bitsLeft = 0
        
        for char in clean {
            guard let val = base32Chars.firstIndex(of: char) else { continue }
            let idx = base32Chars.distance(from: base32Chars.startIndex, to: val)
            
            buffer <<= 5
            buffer |= idx
            bitsLeft += 5
            
            if bitsLeft >= 8 {
                let byte = UInt8((buffer >> (bitsLeft - 8)) & 0xFF)
                bytes.append(byte)
                bitsLeft -= 8
            }
        }
        
        return bytes
    }
    
    // MARK: - HMAC-SHA1
    private static func hmacSha1(key: [UInt8], data: [UInt8]) throws -> [UInt8] {
        var macData = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), key, key.count, data, data.count, &macData)
        return macData
    }
}
