//
//  CoreMessage_TMessageUtil.swift
//  Runner
//
//  Created by Yayan Dwi on 15/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation

public class CoreMessage_TMessageUtil {
        
    private static var mTID = NSDate().timeIntervalSince1970 * 1000
    
    public static func getTID() -> String {
        mTID = Double(Int(mTID) + Int(1))
        return String(Int(mTID))
    }
    
    public static func getString(json: Any, key: String) -> String {
        return getString(json: json, key: key, def: "")
    }
    
    public static func getString(json: Any, key: String, def: String) -> String {
        if let dict = json as? [String: Any], let value = dict[key] as? String {
            if !value.isEmpty {
                return value
            }
        }
        return def
    }
    
    public static func getInt(json: Any, key: String, def: Int) -> Int {
        if let dict = json as? [String: Any], let value = dict[key] as? Int {
            return value
        }
        return def
    }
    
    public static func getIntAsString(json: Any, key: String, def: Int) -> String {
        return String(getInt(json: json, key: key, def: def))
    }
    
    public static func getLong(json: Any, key: String, def: CLong) -> CLong {
        if let dict = json as? [String: Any], let value = dict[key] as? CLong {
            return value
        }
        return def
    }
    
}
