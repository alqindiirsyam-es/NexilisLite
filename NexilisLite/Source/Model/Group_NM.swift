//
//  Group_NM.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 06/07/23.
//

import Foundation

public class GroupNM: Model {
    
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
    public var childs: [GroupNM] = []
    public let level: String
    
    public var isSelected = false
    
    public init(id: String, name: String, profile: String, quote: String, by: String, date: String, parent: String, chatId: String = "", groupType: String, isOpen: String, official: String, isEducation: String = "", isLounge: Bool = false, level: String = "") {
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
    }
    
    var isInternal: Bool {
        return isEducation == "2" || isEducation == "3" || isEducation == "4"
    }
    
    public var description: String {
        return "(\(id), \(name), \(chatId), \(groupType), \(childs)"
    }
    
    public static func == (lhs: GroupNM, rhs: GroupNM) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func getData(group_id: String?) -> GroupNM? {
        guard let group_id = group_id else {
            return nil
        }
        var group: GroupNM?
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select group_id, f_name, image_id, quote, created_by, created_date, parent, group_type, is_open, official from GROUP_NM where group_id = '\(group_id)'"), cursor.next() {
                    group = GroupNM(id: cursor.string(forColumnIndex: 0) ?? "",
                                    name: cursor.string(forColumnIndex: 1) ?? "",
                                    profile: cursor.string(forColumnIndex: 2) ?? "",
                                    quote: cursor.string(forColumnIndex: 3) ?? "",
                                    by: cursor.string(forColumnIndex: 4) ?? "",
                                    date: cursor.string(forColumnIndex: 5) ?? "",
                                    parent: cursor.string(forColumnIndex: 6) ?? "",
                                    groupType: cursor.string(forColumnIndex: 7) ?? "",
                                    isOpen: cursor.string(forColumnIndex: 8) ?? "",
                                    official: cursor.string(forColumnIndex: 9) ?? "")
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
