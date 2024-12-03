//
//  Archive.swift
//  Runner
//
//  Created by Yayan Dwi on 16/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import Compression

public class MyArchive {
    
    public static func zip(sourceString: String) -> [UInt8] {
        var sourceBuffer = Array(sourceString.utf8)
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: sourceString.count)
        let compressedSize = compression_encode_buffer(destinationBuffer, sourceString.count,
                                                       &sourceBuffer, sourceString.count,
                                                       nil,
                                                       COMPRESSION_ZLIB)
        if compressedSize == 0 {
            fatalError("Encoding failed.")
        }
        let data = NSData(bytesNoCopy: destinationBuffer, length: compressedSize)
        var buffer = [UInt8](repeating: 0, count: data.length)
        data.getBytes(&buffer, length: data.length)
        return buffer
    }
    
    public static func unzip(bytes: [UInt8]) -> String {
        let decodedCapacity = 8_000_000
        let decodedDestinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: decodedCapacity)
        let data = Data(bytes)
        let decodedString = data.withUnsafeBytes {
            (encodedSourceBuffer: UnsafePointer<UInt8>) -> String in
            
            let decodedCharCount = compression_decode_buffer(decodedDestinationBuffer,
                                                             decodedCapacity,
                                                             encodedSourceBuffer,
                                                             data.count,
                                                             nil,
                                                             COMPRESSION_ZLIB)
            
            if decodedCharCount == 0 {
                fatalError("Decoding failed.")
            }
            
            return String(cString: decodedDestinationBuffer)
        }
        return decodedString
    }

}
