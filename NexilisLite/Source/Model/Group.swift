//
//  Group.swift
//  Qmera
//
//  Created by Yayan Dwi on 28/09/21.
//

import Foundation

public class Group: Model {
    
    public let id: String
    public let name: String
    public var profile: String
    public let quote: String
    public let by: String
    public let date: String
    public let parent: String
    public let chatId: String
    public var isOpen: String
    public let official: String
    public let isEducation: String
    public let groupType: String
    public let isLounge: Bool
    public var topics: [Topic] = []
    public var childs: [Group] = []
    public var members: [Member] = []
    public let level: String
    public let chatModifier: String
    
    public var isSelected = false
    
    public init(id: String, name: String, profile: String, quote: String, by: String, date: String, parent: String, chatId: String = "", groupType: String, isOpen: String, official: String, isEducation: String = "", isLounge: Bool = false, level: String = "", chatModifier: String = "") {
        self.id = id
        self.name = name
        self.profile = profile
        self.quote = quote
        self.by = by
        self.date = date
        self.parent = parent
        self.chatId = chatId
        self.groupType = groupType
        self.isOpen = isOpen
        self.official = official
        self.isEducation = isEducation
        self.isLounge = isLounge
        self.level = level
        self.chatModifier = chatModifier
    }
    
    var isInternal: Bool {
        return isEducation == "2" || isEducation == "3" || isEducation == "4"
    }
    
    public var description: String {
        return "(\(id), \(name), \(chatId), \(groupType), \(childs)"
    }
    
    public static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func getData(group_id: String?) -> Group? {
        guard let group_id = group_id else {
            return nil
        }
        var group: Group?
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select group_id, f_name, image_id, quote, created_by, created_date, parent, group_type, is_open, official, chat_modifier from GROUPZ where group_id = '\(group_id)'"), cursor.next() {
                    group = Group(id: cursor.string(forColumnIndex: 0) ?? "",
                                  name: cursor.string(forColumnIndex: 1) ?? "",
                                  profile: cursor.string(forColumnIndex: 2) ?? "",
                                  quote: cursor.string(forColumnIndex: 3) ?? "",
                                  by: cursor.string(forColumnIndex: 4) ?? "",
                                  date: cursor.string(forColumnIndex: 5) ?? "",
                                  parent: cursor.string(forColumnIndex: 6) ?? "",
                                  groupType: cursor.string(forColumnIndex: 7) ?? "",
                                  isOpen: cursor.string(forColumnIndex: 8) ?? "",
                                  official: cursor.string(forColumnIndex: 9) ?? "",
                                  chatModifier: cursor.string(forColumnIndex: 10) ?? "")
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return group
    }
    
}

public class Topic: Model {
    
    public let chatId: String
    public let title: String
    public let thumb: String
    
    public init(chatId: String, title: String, thumb: String) {
        self.chatId = chatId
        self.title = title
        self.thumb = thumb
    }
    
    public static func == (lhs: Topic, rhs: Topic) -> Bool {
        return lhs.chatId == rhs.chatId
    }
    
    public var description: String {
        return ""
    }
    
    public static func getData(topic_id: String?) -> Topic? {
        guard let topic_id = topic_id else {
            return nil
        }
        var topic: Topic?
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select chat_id, title, thumb from DISCUSSION_FORUM where chat_id = '\(topic_id)'"), cursor.next() {
                    topic = Topic(chatId: cursor.string(forColumnIndex: 0) ?? "",
                                  title: cursor.string(forColumnIndex: 1) ?? "",
                                  thumb: cursor.string(forColumnIndex: 2) ?? "")
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return topic
    }
    
}

public class Member: User {
    
    public var position: String
    
    override init(pin: String) {
        self.position = "0"
        super.init(pin: pin)
    }
    
    public init(pin: String, firstName: String, lastName: String, thumb: String, position: String) {
        self.position = position
        super.init(pin: pin, firstName: firstName, lastName: lastName, thumb: thumb)
    }
    
    public static func getAllMember(group_id: String) -> [Member] {
        var members: [Member] = []
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, first_name, last_name, thumb_id, position from GROUPZ_MEMBER where group_id = '\(group_id)' OR group_id = (select group_id from DISCUSSION_FORUM where chat_id = '\(group_id)')") {
                    while cursor.next() {
                        members.append(Member(pin: cursor.string(forColumnIndex: 0) ?? "",
                                              firstName: cursor.string(forColumnIndex: 1) ?? "",
                                              lastName: cursor.string(forColumnIndex: 2) ?? "",
                                              thumb: cursor.string(forColumnIndex: 3) ?? "",
                                              position: cursor.string(forColumnIndex: 4) ?? ""))
                    }
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return members
    }
    
    public static func getMember(f_pin: String) -> Member? {
        var member: Member?
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, first_name, last_name, thumb_id, position from GROUPZ_MEMBER where f_pin = '\(f_pin)'") {
                    while cursor.next() {
                        member = Member(pin: cursor.string(forColumnIndex: 0) ?? "",
                                        firstName: cursor.string(forColumnIndex: 1) ?? "",
                                        lastName: cursor.string(forColumnIndex: 2) ?? "",
                                        thumb: cursor.string(forColumnIndex: 3) ?? "",
                                        position: cursor.string(forColumnIndex: 4) ?? "")
                    }
                    if f_pin == "-997" {
                        member = Member(pin: "-997",
                                        firstName: Utils.getGPTBotName(),
                                        lastName: "",
                                        thumb: "",
                                        position: "")
                    }
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return member
    }
    
    public static func getMemberInGroup(f_pin: String, group_id: String) -> Member? {
        var member: Member?
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, first_name, last_name, thumb_id, position from GROUPZ_MEMBER where f_pin = '\(f_pin)' AND (group_id = '\(group_id)' OR group_id = (select group_id from DISCUSSION_FORUM where chat_id = '\(group_id)'))") {
                    while cursor.next() {
                        member = Member(pin: cursor.string(forColumnIndex: 0) ?? "",
                                        firstName: cursor.string(forColumnIndex: 1) ?? "",
                                        lastName: cursor.string(forColumnIndex: 2) ?? "",
                                        thumb: cursor.string(forColumnIndex: 3) ?? "",
                                        position: cursor.string(forColumnIndex: 4) ?? "")
                    }
                    if f_pin == "-997" {
                        member = Member(pin: "-997",
                                        firstName: Utils.getGPTBotName(),
                                        lastName: "",
                                        thumb: "",
                                        position: "")
                    }
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return member
    }
}
