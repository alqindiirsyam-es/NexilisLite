//
//  User.swift
//  Qmera
//
//  Created by Yayan Dwi on 28/09/21.
//

import Foundation
import FMDB

public class User: Model {
    
    public var pin: String
    public var firstName: String
    public var lastName: String
    public var thumb: String
    public var official: String?
    public var userType: String?
    public var privacy_flag: String?
    public var offline_mode: String?
    public var ex_block: String?
    public var ex_offmp: String?
    public var device_id: String
    public var status: String
    public var beId: String
    
    public var isSelected: Bool = false
    public var isMuted: Bool = false
    public var isConnected: Bool = false
    
    public init(pin: String) {
        self.pin = pin
        self.firstName = ""
        self.lastName = ""
        self.thumb = ""
        self.userType = ""
        self.privacy_flag = ""
        self.offline_mode = ""
        self.ex_block = ""
        self.ex_offmp = ""
        self.device_id = ""
        self.status = ""
        self.beId = ""
    }
    
    public init(pin: String, firstName: String, lastName: String, thumb: String, userType: String = "0", privacy_flag: String = "", offline_mode: String = "", ex_block: String = "", official: String = "", ex_offmp: String = "", device_id: String = "", status: String = "", beId: String = "") {
        self.pin = pin
        self.firstName = firstName
        self.lastName = lastName
        self.thumb = thumb
        self.userType = userType
        self.privacy_flag = privacy_flag
        self.offline_mode = offline_mode
        self.official = official
        self.ex_block = ex_block
        self.ex_offmp = ex_offmp
        self.device_id = device_id
        self.status = status
        self.beId = beId
    }
    
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.pin == rhs.pin
    }
    
    public var description: String {
        return "\(pin) \(firstName) \(lastName) \(thumb)"
    }
    
    public var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    public static func isOfficial(official_account: String) -> Bool {
        return official_account == "1"
    }
    
    public static func isVerified(official_account: String) -> Bool {
        return official_account == "2"
    }
    
    public static func isOfficialRegular(official_account: String) -> Bool {
        return official_account == "3"
    }
    
    public static func isInternal(userType: String) -> Bool {
        return userType == "23"
    }
    
    public static func isCallCenter(userType: String) -> Bool {
        return userType == "24"
    }
    
    public static func isAdmin(fmdb: FMDatabase? = nil) -> Bool {
        var position = ""
        if fmdb == nil {
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    var groupId = ""
                    if let cursorGroup = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id FROM GROUPZ where group_type = 1 AND official = 1"), cursorGroup.next() {
                        groupId = cursorGroup.string(forColumnIndex: 0) ?? ""
                        cursorGroup.close()
                    }
                    if let cursorIsAdmin = Database.shared.getRecords(fmdb: fmdb, query: "SELECT position FROM GROUPZ_MEMBER where group_id = '\(groupId)' AND f_pin = '\(User.getMyPin()!)'"), cursorIsAdmin.next() {
                        position = cursorIsAdmin.string(forColumnIndex: 0) ?? ""
                        cursorIsAdmin.close()
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        } else {
            var groupId = ""
            if let cursorGroup = Database.shared.getRecords(fmdb: fmdb!, query: "SELECT group_id FROM GROUPZ where group_type = 1 AND official = 1"), cursorGroup.next() {
                groupId = cursorGroup.string(forColumnIndex: 0) ?? ""
                cursorGroup.close()
            }
            if let cursorIsAdmin = Database.shared.getRecords(fmdb: fmdb!, query: "SELECT position FROM GROUPZ_MEMBER where group_id = '\(groupId)' AND f_pin = '\(User.getMyPin()!)'"), cursorIsAdmin.next() {
                position = cursorIsAdmin.string(forColumnIndex: 0) ?? ""
                cursorIsAdmin.close()
            }
        }
        return position == "1"
    }
    
    public static func getMyPin() -> String? {
        if let value: String = SecureUserDefaults.shared.value(forKey: "me") {
            return value
        }
        return nil
    }
    
    public static func getData(pin: String?, lPin: String = "", fmdb: FMDatabase? = nil) -> User? {
        guard let pin = pin else {
            return nil
        }
        var user: User?
        if fmdb != nil {
            if let cursor = Database.shared.getRecords(fmdb: fmdb!, query: "select f_pin, first_name, last_name, image_id, user_type, privacy_flag, offline_mode, ex_block, device_id, official_account, quote, be_info from BUDDY where f_pin = '\(pin)' OR device_id = '\(pin)'"), cursor.next() {
                user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
                            firstName: cursor.string(forColumnIndex: 1) ?? "",
                            lastName: cursor.string(forColumnIndex: 2) ?? "",
                            thumb: cursor.string(forColumnIndex: 3) ?? "",
                            userType: cursor.string(forColumnIndex: 4) ?? "",
                            privacy_flag: cursor.string(forColumnIndex: 5) ?? "",
                            offline_mode: cursor.string(forColumnIndex: 6) ?? "",
                            ex_block: cursor.string(forColumnIndex: 7) ?? "",
                            official: cursor.string(forColumnIndex: 9) ?? "",
                            device_id: cursor.string(forColumnIndex: 8) ?? "",
                            status: cursor.string(forColumnIndex: 10) ?? "",
                            beId: cursor.string(forColumnIndex: 11) ?? "")
                cursor.close()
            } else if let cursor = Database.shared.getRecords(fmdb: fmdb!, query: """
                                                              SELECT a.f_pin, a.first_name, a.last_name, a.thumb_id
                                                              FROM GROUPZ_MEMBER a
                                                              LEFT JOIN DISCUSSION_FORUM b ON a.group_id = b.group_id
                                                              LEFT JOIN GROUPZ c ON a.group_id = c.group_id
                                                              WHERE a.f_pin = '\(pin)'
                                                              AND (
                                                                  (b.chat_id = '\(lPin)' AND a.group_id = b.group_id)
                                                                  OR 
                                                                  (c.group_id = '\(lPin)' AND a.group_id = c.group_id)
                                                              )
                                                              """), cursor.next() {
                user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
                            firstName: cursor.string(forColumnIndex: 1) ?? "",
                            lastName: cursor.string(forColumnIndex: 2) ?? "",
                            thumb: cursor.string(forColumnIndex: 3) ?? "",
                            userType: "",
                            privacy_flag: "",
                            offline_mode: "",
                            ex_block: "")
            } else if pin == "-997" {
                user = User(pin: "-997",
                            firstName: Utils.getGPTBotName(),
                            lastName: "",
                            thumb: "",
                            userType: "0",
                            official: "1")
            } else {
                user = User(pin: pin,
                            firstName: "User".localized(),
                            lastName: "",
                            thumb: "",
                            userType: "",
                            privacy_flag: "",
                            offline_mode: "",
                            ex_block: "")
            }
        } else {
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, first_name, last_name, image_id, user_type, privacy_flag, offline_mode, ex_block, device_id, official_account, quote, be_info from BUDDY where f_pin = '\(pin)' OR device_id = '\(pin)'"), cursor.next() {
                        user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
                                    firstName: cursor.string(forColumnIndex: 1) ?? "",
                                    lastName: cursor.string(forColumnIndex: 2) ?? "",
                                    thumb: cursor.string(forColumnIndex: 3) ?? "",
                                    userType: cursor.string(forColumnIndex: 4) ?? "",
                                    privacy_flag: cursor.string(forColumnIndex: 5) ?? "",
                                    offline_mode: cursor.string(forColumnIndex: 6) ?? "",
                                    ex_block: cursor.string(forColumnIndex: 7) ?? "",
                                    official: cursor.string(forColumnIndex: 9) ?? "",
                                    device_id: cursor.string(forColumnIndex: 8) ?? "",
                                    status: cursor.string(forColumnIndex: 10) ?? "",
                                    beId: cursor.string(forColumnIndex: 11) ?? "")
                        cursor.close()
                    } else if let cursor = Database.shared.getRecords(fmdb: fmdb, query: """
                                                              SELECT a.f_pin, a.first_name, a.last_name, a.thumb_id
                                                              FROM GROUPZ_MEMBER a
                                                              LEFT JOIN DISCUSSION_FORUM b ON a.group_id = b.group_id
                                                              LEFT JOIN GROUPZ c ON a.group_id = c.group_id
                                                              WHERE a.f_pin = '\(pin)'
                                                              AND (
                                                                  (b.chat_id = '\(lPin)' AND a.group_id = b.group_id)
                                                                  OR 
                                                                  (c.group_id = '\(lPin)' AND a.group_id = c.group_id)
                                                              )
                                                              """), cursor.next() {
                        user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
                                    firstName: cursor.string(forColumnIndex: 1) ?? "",
                                    lastName: cursor.string(forColumnIndex: 2) ?? "",
                                    thumb: cursor.string(forColumnIndex: 3) ?? "",
                                    userType: "",
                                    privacy_flag: "",
                                    offline_mode: "",
                                    ex_block: "")
                    } else if pin == "-997" {
                        user = User(pin: "-997",
                                    firstName: Utils.getGPTBotName(),
                                    lastName: "",
                                    thumb: "",
                                    userType: "0",
                                    official: "1")
                    } else {
                        user = User(pin: pin,
                                    firstName: "User".localized(),
                                    lastName: "",
                                    thumb: "",
                                    userType: "",
                                    privacy_flag: "",
                                    offline_mode: "",
                                    ex_block: "")
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
        return user
    }
    
    public static func getDataCanNil(pin: String?, fmdb: FMDatabase? = nil) -> User? {
        guard let pin = pin else {
            return nil
        }
        var user: User?
        if fmdb != nil {
            if let cursor = Database.shared.getRecords(fmdb: fmdb!, query: "select f_pin, first_name, last_name, image_id, user_type, privacy_flag, offline_mode, ex_block, device_id, official_account from BUDDY where f_pin = '\(pin)' OR device_id = '\(pin)'"), cursor.next() {
                user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
                            firstName: cursor.string(forColumnIndex: 1) ?? "",
                            lastName: cursor.string(forColumnIndex: 2) ?? "",
                            thumb: cursor.string(forColumnIndex: 3) ?? "",
                            userType: cursor.string(forColumnIndex: 4) ?? "",
                            privacy_flag: cursor.string(forColumnIndex: 5) ?? "",
                            offline_mode: cursor.string(forColumnIndex: 6) ?? "",
                            ex_block: cursor.string(forColumnIndex: 7) ?? "",
                            official: cursor.string(forColumnIndex: 9) ?? "",
                            device_id: cursor.string(forColumnIndex: 8) ?? "")
                cursor.close()
            }
        } else {
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, first_name, last_name, image_id, user_type, privacy_flag, offline_mode, ex_block, device_id, official_account from BUDDY where f_pin = '\(pin)' OR device_id = '\(pin)'"), cursor.next() {
                        user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
                                    firstName: cursor.string(forColumnIndex: 1) ?? "",
                                    lastName: cursor.string(forColumnIndex: 2) ?? "",
                                    thumb: cursor.string(forColumnIndex: 3) ?? "",
                                    userType: cursor.string(forColumnIndex: 4) ?? "",
                                    privacy_flag: cursor.string(forColumnIndex: 5) ?? "",
                                    offline_mode: cursor.string(forColumnIndex: 6) ?? "",
                                    ex_block: cursor.string(forColumnIndex: 7) ?? "",
                                    official: cursor.string(forColumnIndex: 9) ?? "",
                                    device_id: cursor.string(forColumnIndex: 8) ?? "")
                        cursor.close()
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
        return user
    }
    
    public static func getDataFromNameCanNil(name: String?, fmdb: FMDatabase? = nil) -> User? {
        guard let name = name else {
            return nil
        }
        let listName = name.components(separatedBy: " ")
        let firstName = listName[0]
        var lastName = ""
        //print("firstName: \(firstName) <> lastName: \(lastName)")
        if listName.count > 1 {
            for i in 1..<listName.count {
                if lastName.isEmpty {
                    lastName = listName[i]
                } else {
                    lastName = lastName + " " + listName[i]
                }
            }
        }
        var user: User?
        if fmdb != nil {
            if let cursor = Database.shared.getRecords(fmdb: fmdb!, query: "select f_pin, first_name, last_name, image_id, user_type, privacy_flag, offline_mode, ex_block, device_id, official_account from BUDDY where LOWER(first_name) = '\(firstName.lowercased())' AND LOWER(last_name) = '\(lastName.lowercased())'"), cursor.next() {
                user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
                            firstName: cursor.string(forColumnIndex: 1) ?? "",
                            lastName: cursor.string(forColumnIndex: 2) ?? "",
                            thumb: cursor.string(forColumnIndex: 3) ?? "",
                            userType: cursor.string(forColumnIndex: 4) ?? "",
                            privacy_flag: cursor.string(forColumnIndex: 5) ?? "",
                            offline_mode: cursor.string(forColumnIndex: 6) ?? "",
                            ex_block: cursor.string(forColumnIndex: 7) ?? "",
                            official: cursor.string(forColumnIndex: 9) ?? "",
                            device_id: cursor.string(forColumnIndex: 8) ?? "")
                cursor.close()
            }
        } else {
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, first_name, last_name, image_id, user_type, privacy_flag, offline_mode, ex_block, device_id, official_account from BUDDY where LOWER(first_name) = '\(firstName.lowercased())' AND LOWER(last_name) = '\(lastName.lowercased())'"), cursor.next() {
                        user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
                                    firstName: cursor.string(forColumnIndex: 1) ?? "",
                                    lastName: cursor.string(forColumnIndex: 2) ?? "",
                                    thumb: cursor.string(forColumnIndex: 3) ?? "",
                                    userType: cursor.string(forColumnIndex: 4) ?? "",
                                    privacy_flag: cursor.string(forColumnIndex: 5) ?? "",
                                    offline_mode: cursor.string(forColumnIndex: 6) ?? "",
                                    ex_block: cursor.string(forColumnIndex: 7) ?? "",
                                    official: cursor.string(forColumnIndex: 9) ?? "",
                                    device_id: cursor.string(forColumnIndex: 8) ?? "")
                        cursor.close()
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
        return user
    }
    
}
