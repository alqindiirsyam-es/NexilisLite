//
//  Chat.swift
//  Qmera
//
//  Created by Yayan Dwi on 14/10/21.
//

import Foundation

public class Chat: Model {
    
    public let fpin: String
    public var pin: String
    public let messageId: String
    public var counter: String
    public var messageText: String
    public let serverDate: String
    public let image: String
    public let video: String
    public let file: String
    public let attachmentFlag: String
    public let messageScope: String
    public let name: String
    public let profile: String
    public let official: String
    public let status: String
    public let credential: String
    public var lock: String
    public let thumb: String
    public let audio: String
    public let gif: String
    public let groupId: String
    public let groupName: String
    public var isSelected: Bool
    public var isParent: Bool
    public var pinned: Int64
    public var isBot: Int
    public var isFolPinned: Bool
    
    public init(pin: String) {
        self.fpin = ""
        self.pin = pin
        self.messageId = ""
        self.counter = ""
        self.messageText = ""
        self.serverDate = ""
        self.image = ""
        self.video = ""
        self.file = ""
        self.attachmentFlag = ""
        self.messageScope = ""
        self.name = ""
        self.profile = ""
        self.official = ""
        self.status = ""
        self.credential = ""
        self.lock = ""
        self.thumb = ""
        self.audio = ""
        self.gif = ""
        self.groupId = ""
        self.groupName = ""
        self.isSelected = false
        self.isParent = false
        self.pinned = 0
        self.isBot = 0
        self.isFolPinned = false
    }
    
    public init(profile: String, groupName: String, counter: String, groupId: String) {
        self.fpin = ""
        self.pin = ""
        self.messageId = ""
        self.counter = counter
        self.messageText = ""
        self.serverDate = ""
        self.image = ""
        self.video = ""
        self.file = ""
        self.attachmentFlag = ""
        self.messageScope = ""
        self.name = ""
        self.profile = profile
        self.official = ""
        self.status = ""
        self.credential = ""
        self.lock = ""
        self.thumb = ""
        self.audio = ""
        self.gif = ""
        self.groupId = groupId
        self.groupName = groupName
        self.isSelected = false
        self.isParent = false
        self.pinned = 0
        self.isBot = 0
        self.isFolPinned = false
    }
    
    public init(fpin:String, pin: String, messageId: String, counter: String, messageText: String, serverDate: String, image: String, video: String, file: String, attachmentFlag: String, messageScope: String, name: String, profile: String, official: String, status: String, credential: String, lock: String, thumb: String = "", audio: String = "", gif: String = "", groupId: String = "", groupName: String = "", isSelected: Bool = false, isParent: Bool = false, pinned: Int64 = 0, isBot: Int = 0, isFolPinned: Bool = false) {
        self.fpin = fpin
        self.pin = pin
        self.messageId = messageId
        self.counter = counter
        self.messageText = messageText
        self.serverDate = serverDate
        self.image = image
        self.video = video
        self.file = file
        self.attachmentFlag = attachmentFlag
        self.messageScope = messageScope
        self.name = name
        self.profile = profile
        self.official = official
        self.status = status
        self.credential = credential
        self.lock = lock
        self.thumb = thumb
        self.audio = audio
        self.gif = gif
        self.groupId = groupId
        self.groupName = groupName
        self.isSelected = isSelected
        self.isParent = isParent
        self.pinned = pinned
        self.isBot = isBot
        self.isFolPinned = isFolPinned
    }
    
    public static func == (lhs: Chat, rhs: Chat) -> Bool {
        return lhs.pin == rhs.pin
    }
    
    public func copy() -> Chat {
        return Chat(fpin: self.fpin, pin: self.pin, messageId: self.messageId, counter: self.counter, messageText: self.messageText, serverDate: self.serverDate, image: self.image, video: self.video, file: self.file, attachmentFlag: self.attachmentFlag, messageScope: self.messageScope, name: self.name, profile: self.profile, official: self.official, status: self.status, credential: self.credential, lock: self.lock, thumb: self.thumb, audio: self.audio, gif: self.gif, groupId: self.groupId, groupName: self.groupName, isSelected: self.isSelected, isParent: self.isParent)
    }
    
    public var description: String {
        return ""
    }
    
    public static func getCountSearchMessage(key: String, pin: String, chatId:String = "", isPersonal: Bool, isCC: Int = 0) -> Int {
        var query = ""
        var count = 0
        if isPersonal {
            if isCC == 1 {
                query = "select message_id FROM MESSAGE where message_text LIKE '%\(key)%' and call_center_id = '\(pin)'"
            } else {
                query = "select message_id FROM MESSAGE where message_text LIKE '%\(key)%' and (l_pin = '\(pin)' or f_pin = '\(pin)')"
            }
        } else {
            query = "select message_id FROM MESSAGE where message_text LIKE '%\(key)%' and l_pin = '\(pin)' and chat_id = '\(chatId)'"
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                while cursorData.next() {
                    count+=1
                }
            }
        })
        return count
    }
    
    public static func getMessageFromSearch(text: String = "") -> [Chat] {
        var messages: [Chat] = []
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                let myPin = User.getMyPin() ?? ""
                let query = """
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   b.first_name || ' ' || ifnull(b.last_name, '') as name,
                                   b.image_id as profile, b.official_account,
                                   m.status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            join BUDDY b on (m.l_pin = b.f_pin OR m.f_pin = b.f_pin)
                            where b.f_pin <> '\(myPin)' and m.message_scope_id = '3' and (m.lock IS NULL OR m.lock <> '1') and (m.message_text LIKE '%\(text)%' OR name LIKE '%\(text)%') and m.is_call_center = 0
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   'Bot' as name, '' as profile, '' as official_account,
                                   m.status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            where m.l_pin = '-999' and (m.lock IS NULL OR m.lock <> '1')
                              and (m.message_text LIKE '%\(text)%' OR name LIKE '%\(text)%') and m.is_call_center = 0
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   'GPT SmartBot' as name, '' as profile, '' as official_account,
                                   m.status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            where m.l_pin = '-997' and (m.lock IS NULL OR m.lock <> '1')
                              and (m.message_text LIKE '%\(text)%' OR name LIKE '%\(text)%') and m.is_call_center = 0
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   '\("Lounge".localized())' as name,
                                   g.image_id as profile, g.official,
                                   m.status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   g.group_id, g.f_name as group_name, m.is_bot
                            from MESSAGE m
                            join GROUPZ g on m.l_pin = g.group_id
                            where m.chat_id = '' and (m.lock IS NULL OR m.lock <> '1') and (m.message_text LIKE '%\(text)%' OR name LIKE '%\(text)%' OR group_name LIKE '%\(text)%') and m.is_call_center = 0
                            union
                            select m.f_pin, m.chat_id, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   d.title, g.image_id as profile, '' as official_account,
                                   m.status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   g.group_id, g.f_name as group_name, m.is_bot
                            from MESSAGE m
                            join DISCUSSION_FORUM d on m.chat_id = d.chat_id
                            join GROUPZ g on d.group_id = g.group_id
                            where (m.lock IS NULL OR m.lock <> '1') and (m.message_text LIKE '%\(text)%' OR d.title LIKE '%\(text)%' OR group_name LIKE '%\(text)%') and m.is_call_center = 0

                            order by 5 desc
                            """
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    while cursorData.next() {
                        let chat = Chat(fpin: cursorData.string(forColumnIndex: 0) ?? "",
                                        pin: cursorData.string(forColumnIndex: 1) ?? "",
                                        messageId: cursorData.string(forColumnIndex: 2) ?? "",
                                        counter: "0",
                                        messageText: cursorData.string(forColumnIndex: 3) ?? "",
                                        serverDate: cursorData.string(forColumnIndex: 4) ?? "",
                                        image: cursorData.string(forColumnIndex: 5) ?? "",
                                        video: cursorData.string(forColumnIndex: 6) ?? "",
                                        file: cursorData.string(forColumnIndex: 7) ?? "",
                                        attachmentFlag: cursorData.string(forColumnIndex: 8) ?? "",
                                        messageScope: cursorData.string(forColumnIndex: 9) ?? "",
                                        name: cursorData.string(forColumnIndex: 10) ?? "",
                                        profile: cursorData.string(forColumnIndex: 11) ?? "",
                                        official: cursorData.string(forColumnIndex: 12) ?? "",
                                        status: cursorData.string(forColumnIndex: 13) ?? "",
                                        credential: cursorData.string(forColumnIndex: 14) ?? "",
                                        lock: cursorData.string(forColumnIndex: 15) ?? "",
                                        thumb: cursorData.string(forColumnIndex: 16) ?? "",
                                        audio: cursorData.string(forColumnIndex: 17) ?? "",
                                        gif: cursorData.string(forColumnIndex: 18) ?? "",
                                        groupId: cursorData.string(forColumnIndex: 19) ?? "",
                                        groupName: cursorData.string(forColumnIndex: 20) ?? "",
                                        pinned: 0,
                                        isBot: Int(cursorData.string(forColumnIndex: 21) ?? "0") ?? 0)
                        messages.append(chat)
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return messages
    }
    
    public static func getMessageFromId(message_id: String = "") -> [Chat] {
        var messages: [Chat] = []
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                let myPin = User.getMyPin() ?? ""
                let query = """
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   b.first_name || ' ' || ifnull(b.last_name, '') as name,
                                   b.image_id as profile, b.official_account,
                                   m.status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            join BUDDY b on (m.l_pin = b.f_pin OR m.f_pin = b.f_pin)
                            where b.f_pin <> '\(myPin)' and m.message_scope_id = '3' m.message_id = '\(message_id)'
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   'Bot' as name, '' as profile, '' as official_account,
                                   m.status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            where m.l_pin = '-999'
                              and m.message_id = '\(message_id)'
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   'GPT SmartBot' as name, '' as profile, '' as official_account,
                                   m.status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            where m.l_pin = '-997'
                              and m.message_id = '\(message_id)'
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   '\("Lounge".localized())' as name,
                                   g.image_id as profile, g.official,
                                   m.status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   g.group_id, g.f_name as group_name, m.is_bot
                            from MESSAGE m
                            join GROUPZ g on m.l_pin = g.group_id
                            where m.message_id = '\(message_id)'
                            union
                            select m.f_pin, m.chat_id, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   d.title, g.image_id as profile, '' as official_account,
                                   m.status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   g.group_id, g.f_name as group_name, m.is_bot
                            from MESSAGE m
                            join DISCUSSION_FORUM d on m.chat_id = d.chat_id
                            join GROUPZ g on d.group_id = g.group_id
                            where m.message_id = '\(message_id)'

                            order by 5 desc
                            """
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    while cursorData.next() {
                        let chat = Chat(fpin: cursorData.string(forColumnIndex: 0) ?? "",
                                        pin: cursorData.string(forColumnIndex: 1) ?? "",
                                        messageId: cursorData.string(forColumnIndex: 2) ?? "",
                                        counter: "0",
                                        messageText: cursorData.string(forColumnIndex: 3) ?? "",
                                        serverDate: cursorData.string(forColumnIndex: 4) ?? "",
                                        image: cursorData.string(forColumnIndex: 5) ?? "",
                                        video: cursorData.string(forColumnIndex: 6) ?? "",
                                        file: cursorData.string(forColumnIndex: 7) ?? "",
                                        attachmentFlag: cursorData.string(forColumnIndex: 8) ?? "",
                                        messageScope: cursorData.string(forColumnIndex: 9) ?? "",
                                        name: cursorData.string(forColumnIndex: 10) ?? "",
                                        profile: cursorData.string(forColumnIndex: 11) ?? "",
                                        official: cursorData.string(forColumnIndex: 12) ?? "",
                                        status: cursorData.string(forColumnIndex: 13) ?? "",
                                        credential: cursorData.string(forColumnIndex: 14) ?? "",
                                        lock: cursorData.string(forColumnIndex: 15) ?? "",
                                        thumb: cursorData.string(forColumnIndex: 16) ?? "",
                                        audio: cursorData.string(forColumnIndex: 17) ?? "",
                                        gif: cursorData.string(forColumnIndex: 18) ?? "",
                                        groupId: cursorData.string(forColumnIndex: 19) ?? "",
                                        groupName: cursorData.string(forColumnIndex: 20) ?? "",
                                        pinned: 0,
                                        isBot: Int(cursorData.string(forColumnIndex: 21) ?? "0") ?? 0)
                        messages.append(chat)
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return messages
    }
    
//    public static func getUcList() {
//        Database.shared.database?.inTransaction({ (fmdb, rollback) in
//            let query = " select ms.message_id from MESSAGE_SUMMARY ms"
//            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
//                while cursorData.next() {
//                    print("HMMKAMPRET2 \(cursorData.string(forColumnIndex: 0))")
//                }
//                cursorData.close()
//            }
//        })
//    }
    
    public static func getData(isImage: Bool = false, isDoc: Bool = false, isVideo: Bool = false, isGIF: Bool = false, isLink: Bool = false, isAudio: Bool = false, isArchived: Bool = false, withText: String = "") -> [Chat] {
        var chats: [Chat] = []
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var lastQuery = ""
                var text = withText
                if text.contains("~"){
                    text = withText.components(separatedBy: "~")[1].trimmingCharacters(in: .whitespaces)
                }
                if isImage {
                    lastQuery = "m.image_id IS NOT NULL AND m.image_id != ''"
                } else if isDoc {
                    lastQuery = "m.file_id IS NOT NULL AND m.file_id != ''"
                } else if isVideo {
                    lastQuery = "m.video_id IS NOT NULL AND m.video_id != ''"
                } else if isGIF {
                    lastQuery = "m.gif_id IS NOT NULL AND m.gif_id != ''"
                } else if isLink {
                    lastQuery = "m.message_text IS NOT NULL AND m.message_text != '' AND (m.message_text LIKE '%https://%' OR m.message_text LIKE '%www.%')"
                } else if isAudio {
                    lastQuery = "m.audio_id IS NOT NULL AND m.audio_id != ''"
                }
                if !lastQuery.isEmpty && !text.isEmpty {
                    lastQuery += "AND (m.message_text LIKE '%\(text)%' OR name LIKE '%\(text)%')"
                }
                var query = """
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.first_name || ' ' || ifnull(b.last_name, '') name, b.image_id profile, b.official_account, m.status, m.credential, m.lock, m.audio_id, m.gif_id, '' group_id, '' group_name, ms.pinned, m.is_bot from MESSAGE_SUMMARY ms, MESSAGE m, BUDDY b where ms.l_pin = b.f_pin and ms.message_id = m.message_id and m.is_call_center = 0 \(isArchived ? "and ms.archived <> 0" : "and ms.archived = 0")
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, 'Bot' name, '' profile, '', m.status, m.credential, m.lock, m.audio_id, m.gif_id, '' group_id, '' group_name, ms.pinned, m.is_bot from MESSAGE_SUMMARY ms, MESSAGE m where ms.l_pin = '-999' and ms.message_id = m.message_id \(isArchived ? "and ms.archived <> 0" : "and ms.archived = 0")
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, 'GPT SmartBot' name, '' profile, '', m.status, m.credential, m.lock, m.audio_id, m.gif_id, '' group_id, '' group_name, ms.pinned, m.is_bot from MESSAGE_SUMMARY ms, MESSAGE m where ms.l_pin = '-997' and ms.message_id = m.message_id \(isArchived ? "and ms.archived <> 0" : "and ms.archived = 0")
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, '\("Lounge".localized())' name, b.image_id profile, b.official, m.status, m.credential, m.lock, m.audio_id, m.gif_id, b.group_id, b.f_name group_name, ms.pinned, m.is_bot from MESSAGE_SUMMARY ms, MESSAGE m, GROUPZ b where ms.l_pin = b.group_id and ms.message_id = m.message_id and m.is_call_center = 0 \(isArchived ? "and ms.archived <> 0" : "and ms.archived = 0")
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.title, c.image_id profile, '', m.status, m.credential, m.lock, m.audio_id, m.gif_id, c.group_id, c.f_name group_name, ms.pinned, m.is_bot from MESSAGE_SUMMARY ms, MESSAGE m, DISCUSSION_FORUM b, GROUPZ c where b.group_id = c.group_id and ms.l_pin = b.chat_id and ms.message_id = m.message_id and m.is_call_center = 0 \(isArchived ? "and ms.archived <> 0" : "and ms.archived = 0")
                            order by 6 desc
                            """
                if !lastQuery.isEmpty {
                    query = "select m.f_pin, m.opposite_pin, m.message_id, m.thumb_id, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.first_name || ' ' || ifnull(b.last_name, '') name, b.image_id profile, b.official_account, m.credential, m.lock, m.audio_id, m.gif_id, m.l_pin, m.chat_id from MESSAGE m JOIN BUDDY b ON m.f_pin = b.f_pin where \(lastQuery) and m.is_call_center = 0 and m.credential <> '1' order by 6 desc"
                }
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    while cursorData.next() {
//                        if !lastQuery.isEmpty {
//                            for columnIndex in 0..<cursorData.columnCount {
//                                if let columnName = cursorData.columnName(for: columnIndex) {
//                                    if let value = cursorData.object(forColumn: columnName) {
//                                        print("\(columnName): \(value)")
//                                    } else {
//                                        print("\(columnName): nil")
//                                    }
//                                }
//                            }
//                            print("---------------------")
//                        }
                        let chat = Chat(fpin: cursorData.string(forColumnIndex: 0) ?? "",
                                        pin: cursorData.string(forColumnIndex: 1) ?? "",
                                        messageId: cursorData.string(forColumnIndex: 2) ?? "",
                                        counter: !lastQuery.isEmpty ? "0" : cursorData.string(forColumnIndex: 3) ?? "",
                                        messageText: cursorData.string(forColumnIndex: 4) ?? "",
                                        serverDate: cursorData.string(forColumnIndex: 5) ?? "",
                                        image: cursorData.string(forColumnIndex: 6) ?? "",
                                        video: cursorData.string(forColumnIndex: 7) ?? "",
                                        file: cursorData.string(forColumnIndex: 8) ?? "",
                                        attachmentFlag: cursorData.string(forColumnIndex: 9) ?? "",
                                        messageScope: cursorData.string(forColumnIndex: 10) ?? "",
                                        name: cursorData.string(forColumnIndex: 11) ?? "",
                                        profile: cursorData.string(forColumnIndex: 12) ?? "",
                                        official: cursorData.string(forColumnIndex: 13) ?? "",
                                        status: cursorData.string(forColumnIndex: 14) ?? "",
                                        credential: !lastQuery.isEmpty ? cursorData.string(forColumnIndex: 14) ?? "" : cursorData.string(forColumnIndex: 15) ?? "",
                                        lock: !lastQuery.isEmpty ? cursorData.string(forColumnIndex: 15) ?? "" : cursorData.string(forColumnIndex: 16) ?? "",
                                        thumb: !lastQuery.isEmpty ? cursorData.string(forColumnIndex: 3) ?? "" : "",
                                        audio: !lastQuery.isEmpty ? cursorData.string(forColumnIndex: 16) ?? "" : cursorData.string(forColumnIndex: 17) ?? "",
                                        gif: !lastQuery.isEmpty ? cursorData.string(forColumnIndex: 17) ?? "" : cursorData.string(forColumnIndex: 18) ?? "",
                                        groupId: cursorData.string(forColumnIndex: 19) ?? "",
                                        groupName: cursorData.string(forColumnIndex: 20) ?? "",
                                        pinned: cursorData.longLongInt(forColumnIndex: 21),
                                        isBot: Int(cursorData.string(forColumnIndex: 22) ?? "0") ?? 0)
                        if chat.pin.isEmpty && !lastQuery.isEmpty {
                            chat.pin = cursorData.string(forColumnIndex: 18) ?? ""
                            let chatId = cursorData.string(forColumnIndex: 19) ?? ""
                            if !chatId.isEmpty {
                                chat.pin = chatId
                            }
                        }
                        chats.append(chat)
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return chats
    }
    
}
