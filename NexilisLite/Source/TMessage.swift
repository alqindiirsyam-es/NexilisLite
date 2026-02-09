//
//  TMessage.swift
//  Runner
//
//  Created by Yayan Dwi on 15/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation

public class TMessage {
    public var mType: String = ""
    public var mVersion: String = ""
    public var mCode: String = ""
    public var mStatus: String = ""
    public var mPIN: String = ""
    public var mL_PIN: String = ""
    public var mBodies: [String: String] = [String: String]()
    private var mMedia:[UInt8] = [UInt8]()
    
    let C_HEADER:UnicodeScalar = UnicodeScalar(0x01)
    let C_ENTRY:UnicodeScalar = UnicodeScalar(0x02)
    let C_KEYVAL:UnicodeScalar = UnicodeScalar(0x03)
    let C_ARRAY:UnicodeScalar = UnicodeScalar(0x04)
    
    var S_HEADER: String = ""
    var S_ENTRY: String = ""
    var S_KEYVAL: String = ""
    var S_ARRAY: String = ""
    
    
    public static let TYPE_SQLITE_ONLY =  "1"
    public static let TYPE_ALL         =  "2"
    public static let TYPE_NEED_ACK    =  "3"
    
    public init() {
        mVersion = "1.0.120"
        mBodies[CoreMessage_TMessageKey.IMEI] = Nexilis.getCLMUserId()
//        mBodies[CoreMessage_TMessageKey.VERCOD] = UIApplication.appVersion
        mBodies[CoreMessage_TMessageKey.VERCOD] = "2.2.177"
    }
    
    public init(data : String) {
        _ = unpack(data: data)
    }
    
    init(type: String, version: String, code: String,status: String, pin: String, l_pin: String, bodies:[String: String], media:  [UInt8]) {
        mType = type
        mVersion = version
        mCode = code
        mStatus = status
        mPIN = pin
        mL_PIN = l_pin
        mBodies = bodies
        mMedia = media
        mBodies[CoreMessage_TMessageKey.IMEI] = Nexilis.getCLMUserId()
//        mBodies[CoreMessage_TMessageKey.VERCOD] = UIApplication.appVersion
        mBodies[CoreMessage_TMessageKey.VERCOD] = "2.2.177"
    }
    
    public func clone(p_tmessage:TMessage) -> TMessage {
        return TMessage(
            type: p_tmessage.mType,
            version: p_tmessage.mVersion,
            code: p_tmessage.mCode,
            status: p_tmessage.mStatus,
            pin: p_tmessage.mPIN,
            l_pin: p_tmessage.mL_PIN,
            bodies: p_tmessage.mBodies,
            media: p_tmessage.mMedia
        )
    }
    
    public func setMedia(media: [UInt8]) {
        mMedia = media
        mBodies[CoreMessage_TMessageKey.MEDIA_LENGTH] = String(media.count)
    }
    
    public func getCode() -> String {
        return mCode
    }
    public func getStatus() -> String {
        return mStatus
    }
    public func getPIN() -> String {
        return mPIN
    }
    public func getType() -> String {
        return mType
    }
    public func getL_PIN() -> String {
        return mL_PIN
    }
    public func getMedia() -> [UInt8] {
        return mMedia
    }
    public func getBody(key : String) -> String {
        if let data = mBodies[key] {
            return data
        }
        else {
            return ""
        }
    }
    public func getBody(key : String, default_value: String) -> String {
        if ((mBodies[key] == nil)) {
            return default_value
        } else if mBodies[key] == "null" {
            return default_value
        } else {
            return mBodies[key]!
        }
    }
    
    public func getBodyAsInteger(key : String, default_value: Int) -> Int {
        if ((mBodies[key] == nil)) {
            return default_value
        } else if mBodies[key] == "null" {
            return default_value
        } else {
            return Int(mBodies[key]!)!
        }
    }
    public func getBodyAsLong(key : String, default_value: CLong) -> CLong {
        if let body = mBodies[key] {
            if (body == "null") {
                return default_value
            }
            if (body == "nil") {
                return default_value
            }
            return (body as NSString).integerValue
            
        }
        else {
            return default_value
        }
    }
    
    public func pack() -> String {
        if (S_HEADER.isEmpty) { S_HEADER.append(Character(C_HEADER)) }
        
        var data = ""
        data.append(mType)
        data.append(Character(C_HEADER))
        data.append(mVersion)
        data.append(Character(C_HEADER))
        data.append(mCode)
        data.append(Character(C_HEADER))
        data.append(mStatus)
        data.append(Character(C_HEADER))
        data.append(mPIN)
        data.append(Character(C_HEADER))
        data.append(mL_PIN)
        data.append(Character(C_HEADER))
        data.append(toString(body: mBodies))
        data.append(Character(C_HEADER))
        if let media = String(data: Data(getMedia()), encoding: .windowsCP1250) {
            data.append(media)
        }
        return data
        
    }
    
    
    public func toBytes() -> [UInt8] {
        let data:String = pack()
        var result: [UInt8] = Array(data.utf8)
        //print("[bytes_processing] build bytes data:" + String(result.count) + ", media:" + String(getMedia().count))
        if (!getMedia().isEmpty) {
            for index in 0...getMedia().count - 1 {
                result.append(getMedia()[index])
            }
        }
        return result
        
    }
    
    private func toString(body : [String: String]) -> String {
        if (S_ENTRY.isEmpty) { S_ENTRY.append(Character(C_ENTRY)) }
        if (S_KEYVAL.isEmpty) { S_KEYVAL.append(Character(C_KEYVAL)) }
        
        var result = ""
        for (key, value) in body {
            result += key + S_KEYVAL + value + S_ENTRY
        }
        if (!result.isEmpty) {
            result = String(result.prefix(result.count - 1))
        }
        return result
    }
    
    private func toMediaBytes(image: String) ->  [UInt8] {
        if (image == "null") {
            return [UInt8]()
        }
        if let data = NSData(base64Encoded: image, options: .ignoreUnknownCharacters) {
            var buffer = [UInt8](repeating: 0, count: data.length)
            data.getBytes(&buffer, length: data.length)
            return buffer
        }
        return [UInt8]()
    }
    
    public func unpack(data: String) -> Bool {
        var result  = false
        if (S_HEADER.isEmpty) { S_HEADER.append(Character(C_HEADER)) }
        let headers = data.split(separator: Character(C_HEADER), maxSplits: 8, omittingEmptySubsequences: false)
        if (headers.count == 8) {
            mType    = String(headers[0])
            mVersion = String(headers[1])
            mCode    = String(headers[2])
            mStatus  = String(headers[3])
            mPIN     = String(headers[4])
            mL_PIN   = String(headers[5])
            mBodies  = toBodies(data: String(headers[6]))
            mMedia   = toMediaBytes(image: String(headers[7]))
            result   = true
        }
        return result
    }
    
    public func unpack(bytes_data: [UInt8]) -> Bool {
        var result  = false
        let data = getData(bytes_data: bytes_data)
        let headers = data.split(separator: Character(C_HEADER), maxSplits: 8, omittingEmptySubsequences: false)
        if (headers.count >= 8) {
            mType    = String(headers[0])
            mVersion = String(headers[1])
            mCode    = String(headers[2])
            mStatus  = String(headers[3])
            mPIN     = String(headers[4])
            mL_PIN   = String(headers[5])
            mBodies  = toBodies(data: String(headers[6]))
            mMedia   = getMedia(bytes_data: bytes_data)
            result   = true
        }
        else {
            //print("[bytes_processing] Invalid header length: " + String(headers.count))
        }
        return result
    }
    
    private func toBodies(data: String) -> [String: String]  {
        var cvalues = [String: String]()
        
        if (data.isEmpty || data == "") {
            return cvalues
        }
        if (S_ENTRY.isEmpty) { S_ENTRY.append(Character(C_ENTRY)) }
        if (S_KEYVAL.isEmpty) { S_KEYVAL.append(Character(C_KEYVAL)) }
        
        let elements = data.split(separator: Character(C_ENTRY), omittingEmptySubsequences: false)
        
        for element in elements {
            let keyval = element.split(separator: Character(C_KEYVAL), omittingEmptySubsequences: false)
            cvalues[String(keyval[0])] = String(keyval[1])
        }
        return cvalues
    }
    
    private func getData(bytes_data : [UInt8]) -> String {
        var result = ""
        if (S_HEADER.isEmpty) { S_HEADER.append(Character(C_HEADER)) }
        
        var iLength = 0
        for bData in bytes_data {
            let chr = Character(UnicodeScalar(bData))
            
            if (chr == Character(C_HEADER)) {
                iLength = iLength + 1
                if (iLength == 8) {
                    break
                }
            }
            result.append(chr)
        }
        return result
    }
    
    private func getMedia(bytes_data:  [UInt8]) ->  [UInt8] {
        var result:[UInt8] = [UInt8]()
        if bytes_data.count > 0 {
            var ml = getBodyAsInteger(key: CoreMessage_TMessageKey.MEDIA_LENGTH, default_value: 0)
            if ml == 0 {
                ml = getBodyAsInteger(key: CoreMessage_TMessageKey.FILE_SIZE, default_value: 0)
            }
            if ml > 0 {
                let start = bytes_data.count - ml
                for index in start...bytes_data.count - 1 {
                    result.append(bytes_data[index])
                }
            }
        }
        return result
    }
    
    public func toLogString() -> String {
        var result = ""
        result += ("[" + mType + "]")
        result += ("[" + mVersion + "]")
        result += ("[" + mCode + "]")
        result += ("[" + mStatus + "]")
        result += ("[" + mPIN + "]")
        result += ("[" + mL_PIN + "]")
        result += ("[" + toBodyLogString() + "]")
        result += ("[" + String(mMedia.count) + "]")
        return result
    }
    
    private func toBodyLogString() -> String {
        if (S_ENTRY.isEmpty) { S_ENTRY.append(Character(C_ENTRY)) }
        if (S_KEYVAL.isEmpty) { S_KEYVAL.append(Character(C_KEYVAL)) }
        
        var result = ""
        for (key, value) in mBodies {
            result += "{" + key + "=" + value + "}"
        }
        return result
    }
    
    public func isOk() -> Bool {
        return getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "00"
    }
}
