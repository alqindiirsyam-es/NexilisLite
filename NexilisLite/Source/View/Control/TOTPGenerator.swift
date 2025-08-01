//
//  TOTPGenerator.swift
//  Pods
//
//  Created by Maronakins on 01/08/25.
//


import Foundation
import CryptoKit

/// A utility for generating Time-based One-Time Passwords (TOTP).
public struct TOTPGenerator {

    /// Generates a Time-based One-Time Password (TOTP) using the given parameters.
    ///
    /// This implementation follows the standards defined in RFC 4226 (HOTP) and RFC 6238 (TOTP).
    ///
    /// - Parameters:
    ///   - base32Secret: The shared secret key, encoded in Base32 string format.
    ///   - digits: The number of digits the OTP should have (typically 6 or 8).
    ///   - timeStepSeconds: The time interval in seconds for which an OTP is valid (typically 30 or 60).
    /// - Returns: A formatted OTP string with the specified number of digits, or `nil` if the Base32 secret is invalid.
    public static func generate(base32Secret: String, digits: Int, timeStepSeconds: Int) -> String? {
        // 1. Decode the Base32 secret into raw bytes.
        guard let secretData = base32Decode(base32Secret) else {
            print("Error: Invalid Base32 secret string.")
            return nil
        }

        // 2. Calculate the current time step (counter).
        // This is the number of `timeStepSeconds` intervals that have passed since the Unix epoch.
        let timeStep = UInt64(Date().timeIntervalSince1970) / UInt64(timeStepSeconds)

        // 3. Convert the time step to an 8-byte, big-endian data representation.
        let timeStepData = withUnsafeBytes(of: timeStep.bigEndian) { Data($0) }
        
        // 4. Compute the HMAC-SHA1 hash.
        let key = SymmetricKey(data: secretData)
        let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: timeStepData, using: key)

        // 5. Perform dynamic truncation to get a 4-byte value.
        // Convert HMAC to an array of bytes to work with.
        let hashBytes = Array(hmac)
        
        // The last 4 bits of the hash determine the offset.
        let offset = Int(hashBytes.last! & 0x0F)
        
        // Extract 4 bytes from the hash at the calculated offset.
        let truncatedHash =
            (UInt32(hashBytes[offset]     & 0x7F) << 24) |
            (UInt32(hashBytes[offset + 1] & 0xFF) << 16) |
            (UInt32(hashBytes[offset + 2] & 0xFF) << 8)  |
            (UInt32(hashBytes[offset + 3] & 0xFF))

        // 6. Generate the final OTP value.
        // Calculate the divisor (10^digits).
        let divisor = NSDecimalNumber(decimal: pow(10, digits)).uint32Value
        
        // The OTP is the remainder of the division.
        let otp = truncatedHash % divisor

        // 7. Format the OTP string, padding with leading zeros if necessary.
        return String(format: "%0\(digits)d", otp)
    }

    /// Decodes a Base32 encoded string into raw data bytes.
    ///
    /// This minimal decoder adheres to RFC 4648 and ignores padding characters.
    ///
    /// - Parameter base32: The Base32 encoded string.
    /// - Returns: A `Data` object containing the decoded bytes, or `nil` if the input is malformed.
    private static func base32Decode(_ base32: String) -> Data? {
        let base32Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let base32CharsMap = Dictionary(uniqueKeysWithValues: base32Chars.enumerated().map { ($1, $0) })
        
        // Sanitize the input: convert to uppercase and remove any padding.
        let sanitizedBase32 = base32.uppercased().replacingOccurrences(of: "=", with: "")
        
        var data = Data()
        var buffer = 0
        var bitsLeft = 0
        
        for char in sanitizedBase32 {
            guard let value = base32CharsMap[char] else {
                // Invalid character found in the Base32 string.
                return nil
            }
            
            buffer <<= 5
            buffer |= value
            bitsLeft += 5
            
            if bitsLeft >= 8 {
                let byte = (buffer >> (bitsLeft - 8)) & 0xFF
                data.append(UInt8(byte))
                bitsLeft -= 8
            }
        }
        
        return data
    }
}