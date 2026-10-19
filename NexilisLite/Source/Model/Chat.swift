//
//  Chat.swift
//  Qmera
//
//  Created by Yayan Dwi on 14/10/21.
//

import Foundation
import CryptoKit
import Security
import SystemConfiguration

/// A row of the chat list: who it is with, and the last thing said.
///
/// Fix: every one of the queries below read the tick to draw from MESSAGE.status. Nothing keeps
/// that column up to date - a delivery or read receipt arriving is written into MESSAGE_STATUS
/// and only there (see Nexilis.updateMessageStatus) - so the tick in the list was the tick the
/// message was first saved with and never changed again. The conversation itself has always read
/// the newest MESSAGE_STATUS row instead, which is why the same message showed two blue ticks
/// inside the chat and one grey one in the list. Both read the same thing now.
///
/// For a group there is a row per member and this takes the most recently written of them, which
/// is what the conversation does too: the point is that the two agree.
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
    /// Whether something unread in this conversation names me - what the row's "@" is about.
    ///
    /// Not read with the conversation itself: it is settled alongside the unread counts, which
    /// are what it depends on. See UnreadMentions.
    public var namesMe = false
    
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
    
    public static func getCountSearchMessage(key: String, pin: String, chatId:String = "", scope: Int, isCC: Int = 0) -> Int {
        var query = ""
        var count = 0
        if isCC == 1 {
            query = "select message_id FROM MESSAGE where message_text LIKE '%\(key)%' and message_id NOT LIKE '%NTFPIN%' and call_center_id = '\(pin)'"
        } else {
            if scope == 3 {
                query = "select message_id FROM MESSAGE where message_text LIKE '%\(key)%' and message_id NOT LIKE '%NTFPIN%' and (l_pin = '\(pin)' or f_pin = '\(pin)') and is_call_center = 0"
            } else {
                query = "select message_id FROM MESSAGE where message_text LIKE '%\(key)%' and message_id NOT LIKE '%NTFPIN%' and l_pin = '\(pin)' and chat_id = '\(chatId)' and is_call_center = 0"
            }
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
                                   ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            join BUDDY b on (m.l_pin = b.f_pin OR m.f_pin = b.f_pin)
                            where b.f_pin <> '\(myPin)' and m.message_scope_id = '3' and (m.lock IS NULL OR m.lock <> '1') and (m.message_text LIKE '%\(text)%' OR name LIKE '%\(text)%') and m.is_call_center = 0
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   'Bot' as name, '' as profile, '' as official_account,
                                   ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            where m.l_pin = '-999' and (m.lock IS NULL OR m.lock <> '1')
                              and (m.message_text LIKE '%\(text)%' OR name LIKE '%\(text)%') and m.is_call_center = 0
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   'GPT SmartBot' as name, '' as profile, '' as official_account,
                                   ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            where m.l_pin = '-997' and (m.lock IS NULL OR m.lock <> '1')
                              and (m.message_text LIKE '%\(text)%' OR name LIKE '%\(text)%') and m.is_call_center = 0
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   '\("Lounge".localized())' as name,
                                   g.image_id as profile, g.official,
                                   ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   g.group_id, g.f_name as group_name, m.is_bot
                            from MESSAGE m
                            join GROUPZ g on m.l_pin = g.group_id
                            where m.chat_id = '' and (m.lock IS NULL OR m.lock <> '1') and (m.message_text LIKE '%\(text)%' OR name LIKE '%\(text)%' OR group_name LIKE '%\(text)%') and m.is_call_center = 0
                            union
                            select m.f_pin, m.chat_id, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   d.title, g.image_id as profile, '' as official_account,
                                   ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
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
                                   ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            join BUDDY b on (
                                (
                                    m.l_pin LIKE b.f_pin || ',%'
                                    OR m.l_pin LIKE '%,' || b.f_pin || ',%'
                                    OR m.l_pin LIKE '%,' || b.f_pin
                                    OR m.l_pin = b.f_pin
                                )
                                OR m.f_pin = b.f_pin
                            )
                            where b.f_pin <> '\(myPin)' and m.message_id = '\(message_id)'
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   'Bot' as name, '' as profile, '' as official_account,
                                   ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            where m.l_pin = '-999'
                              and m.message_id = '\(message_id)'
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   'GPT SmartBot' as name, '' as profile, '' as official_account,
                                   ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   '' as group_id, '' as group_name, m.is_bot
                            from MESSAGE m
                            where m.l_pin = '-997'
                              and m.message_id = '\(message_id)'
                            union
                            select m.f_pin, m.l_pin, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   '\("Lounge".localized())' as name,
                                   g.image_id as profile, g.official,
                                   ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
                                   g.group_id, g.f_name as group_name, m.is_bot
                            from MESSAGE m
                            join GROUPZ g on m.l_pin = g.group_id
                            where m.message_id = '\(message_id)'
                            union
                            select m.f_pin, m.chat_id, m.message_id, m.message_text, m.server_date,
                                   m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id,
                                   d.title, g.image_id as profile, '' as official_account,
                                   ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.thumb_id, m.audio_id, m.gif_id,
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
    
    /// Whether any conversation has been archived at all.
    ///
    /// Every branch of the archived query is filtered on `ms.archived <> 0`, so when nothing
    /// is archived the whole five-way union is guaranteed to come back empty - and the chat
    /// list ran it on every refresh only to find that out. This answers the same question
    /// with one indexed lookup.
    public static func hasArchived() -> Bool {
        var result = false
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select 1 from MESSAGE_SUMMARY where archived <> 0 limit 1") {
                result = cursor.next()
                cursor.close()
            }
        })
        return result
    }

    public static func getData(isUnread: Bool = false, isImage: Bool = false, isDoc: Bool = false, isVideo: Bool = false, isGIF: Bool = false, isLink: Bool = false, isAudio: Bool = false, isArchived: Bool = false, withText: String = "") -> [Chat] {
        var chats: [Chat] = []
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var lastQuery = ""
                // Fix: this used to cut the text at a tilde, because the screen above wrote one
                // into its search field as a marker and it arrived here along with the words. The
                // marker is gone, and cutting at a tilde now only means a reader who types one
                // cannot search for it.
                let text = withText.trimmingCharacters(in: .whitespaces)
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

                // Kondisi tambahan untuk query aggregate (default)
                var extraCondition = isArchived ? " and ms.archived <> 0" : " and ms.archived = 0"
                if isUnread {
                    extraCondition += " and ms.counter > 0"
                }

                var query = """
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.first_name || ' ' || ifnull(b.last_name, '') name, b.image_id profile, b.official_account, ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.audio_id, m.gif_id, '' group_id, '' group_name, ms.pinned, m.is_bot from MESSAGE_SUMMARY ms, MESSAGE m, BUDDY b where ms.l_pin = b.f_pin and ms.message_id = m.message_id and m.is_call_center = 0\(extraCondition)
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, 'Bot' name, '' profile, '', ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.audio_id, m.gif_id, '' group_id, '' group_name, ms.pinned, m.is_bot from MESSAGE_SUMMARY ms, MESSAGE m where ms.l_pin = '-999' and ms.message_id = m.message_id\(extraCondition)
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, 'GPT SmartBot' name, '' profile, '', ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.audio_id, m.gif_id, '' group_id, '' group_name, ms.pinned, m.is_bot from MESSAGE_SUMMARY ms, MESSAGE m where ms.l_pin = '-997' and ms.message_id = m.message_id\(extraCondition)
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, '\("Lounge".localized())' name, b.image_id profile, b.official, ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.audio_id, m.gif_id, b.group_id, b.f_name group_name, ms.pinned, m.is_bot from MESSAGE_SUMMARY ms, MESSAGE m, GROUPZ b where ms.l_pin = b.group_id and ms.message_id = m.message_id and m.is_call_center = 0\(extraCondition)
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.title, c.image_id profile, '', ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.audio_id, m.gif_id, c.group_id, c.f_name group_name, ms.pinned, m.is_bot from MESSAGE_SUMMARY ms, MESSAGE m, DISCUSSION_FORUM b, GROUPZ c where b.group_id = c.group_id and ms.l_pin = b.chat_id and ms.message_id = m.message_id and m.is_call_center = 0\(extraCondition)
                            order by 6 desc
                            """
                if !lastQuery.isEmpty {
                    query = "select m.f_pin, m.opposite_pin, m.message_id, m.thumb_id, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.first_name || ' ' || ifnull(b.last_name, '') name, b.image_id profile, b.official_account, m.credential, m.lock, m.audio_id, m.gif_id, m.l_pin, m.chat_id from MESSAGE m JOIN BUDDY b ON m.f_pin = b.f_pin where \(lastQuery) and m.is_call_center = 0 and m.credential <> '1' order by 6 desc"
                } else if isUnread && !text.isEmpty {
                    query = """
                            select m.f_pin, m.opposite_pin, m.message_id, m.thumb_id, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.first_name || ' ' || ifnull(b.last_name, '') name, b.image_id profile, b.official_account, ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.audio_id, m.gif_id, '' group_id, '' group_name, 0 pinned, m.is_bot, m.l_pin
                            from MESSAGE m
                            JOIN BUDDY b ON m.f_pin = b.f_pin
                            where m.is_call_center = 0
                              and (m.message_text LIKE '%\(text)%' OR b.first_name LIKE '%\(text)%' OR b.last_name LIKE '%\(text)%')
                              and exists (select 1 from MESSAGE_SUMMARY ms where ms.l_pin = b.f_pin and ms.counter > 0 \(isArchived ? "and ms.archived <> 0" : "and ms.archived = 0"))
                            union all
                            select m.f_pin, m.opposite_pin, m.message_id, m.thumb_id, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.f_name name, b.image_id profile, b.official, ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.audio_id, m.gif_id, b.group_id, b.f_name group_name, 0 pinned, m.is_bot, m.l_pin
                            from MESSAGE m
                            JOIN GROUPZ b ON m.l_pin = b.group_id
                            where m.is_call_center = 0
                              and (m.message_text LIKE '%\(text)%' OR b.f_name LIKE '%\(text)%')
                              and exists (select 1 from MESSAGE_SUMMARY ms where ms.l_pin = b.group_id and ms.counter > 0 \(isArchived ? "and ms.archived <> 0" : "and ms.archived = 0"))
                            union all
                            select m.f_pin, m.opposite_pin, m.message_id, m.thumb_id, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, d.title name, c.image_id profile, '' official, ifnull((select s.status from MESSAGE_STATUS s where s.message_id = m.message_id order by s._id desc limit 1), m.status) status, m.credential, m.lock, m.audio_id, m.gif_id, c.group_id, c.f_name group_name, 0 pinned, m.is_bot, m.l_pin
                            from MESSAGE m
                            JOIN DISCUSSION_FORUM d ON m.l_pin = d.chat_id
                            JOIN GROUPZ c ON d.group_id = c.group_id
                            where m.is_call_center = 0
                              and (m.message_text LIKE '%\(text)%' OR d.title LIKE '%\(text)%')
                              and exists (select 1 from MESSAGE_SUMMARY ms where ms.l_pin = d.chat_id and ms.counter > 0 \(isArchived ? "and ms.archived <> 0" : "and ms.archived = 0"))
                            order by 6 desc
                            """
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
                        // Fix: a result of the attachment filters pointed at the wrong
                        // conversation, and was titled with the wrong name. `opposite_pin` is not
                        // the other side of the conversation - it is the pin that names the
                        // conversation *for whoever receives the message*, so on my own copy of
                        // something I sent it holds my own pin (that is what the sending paths
                        // write into it for a one-to-one chat). Read literally it sent every
                        // attachment I had sent myself to a conversation with myself, and named
                        // the row after me. The same reading was already worked out once, where
                        // an arriving message is filed into the conversation list; it is applied
                        // here so a filter result answers with the conversation the chat list
                        // would answer with.
                        // The two queries that read `opposite_pin` are the ones that need it;
                        // the aggregate query above reads the conversation straight out of
                        // MESSAGE_SUMMARY and is already right. They do not carry `l_pin` in the
                        // same column.
                        let readsOppositePin = !lastQuery.isEmpty
                        if readsOppositePin || (isUnread && !text.isEmpty) {
                            let me = User.getMyPin() ?? ""
                            let listenerPin = cursorData.string(forColumnIndex: readsOppositePin ? 18 : 23) ?? ""
                            let isPersonal = chat.messageScope == MessageScope.WHISPER
                                || chat.messageScope == MessageScope.CALL
                                || chat.messageScope == MessageScope.MISSED_CALL
                            var conversation = chat.pin
                            if conversation.isEmpty, readsOppositePin {
                                let chatId = cursorData.string(forColumnIndex: 19) ?? ""
                                conversation = isPersonal
                                    ? chat.fpin
                                    : (chatId.isEmpty ? listenerPin : chatId)
                            }
                            // My own pin never names a conversation of mine: the other side does.
                            if isPersonal, !me.isEmpty, conversation == me {
                                conversation = listenerPin != me ? listenerPin : chat.fpin
                            }
                            chat.pin = conversation
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

// MARK: - The chat list as it was last shown

/// The chat list as it was last on screen, kept so a cold launch can show it at once.
///
/// Opened from the launcher after the app had been ended, the list had nothing to show until the
/// database was open again and its first read was done - "Loading Data...", then the list, where
/// WhatsApp shows the list straight away. What was last on screen is kept here and shown first;
/// the real read replaces it a moment later, row by row.
///
/// It holds names and the last message of every conversation, so it is sealed: AES-GCM with a key
/// of its own in the keychain, kept on this device and readable only while it is unlocked, in a
/// file under complete protection. It is only for the account that wrote it, shown nowhere reading
/// is not allowed (OfflinePolicy), and gone with the account (NotificationShare.clear).
public enum ChatListSnapshot {

    public struct Content {
        public let chats: [Chat]
        public let groupMaps: [String: [Chat]]
        public let archived: [Chat]
        public let maxArchived: [String: [String]]
        public let senderNames: [String: String]

        public init(chats: [Chat], groupMaps: [String: [Chat]], archived: [Chat],
                    maxArchived: [String: [String]], senderNames: [String: String]) {
            self.chats = chats
            self.groupMaps = groupMaps
            self.archived = archived
            self.maxArchived = maxArchived
            self.senderNames = senderNames
        }
    }

    private static let queue = DispatchQueue(label: "io.nexilis.chatlist.snapshot", qos: .utility)
    /// The write waiting for a burst to settle, per list. Main thread only.
    private static var pendingWrites: [String: DispatchWorkItem] = [:]
    private static let keychainService = "io.nexilis.chatlist"
    private static let keychainAccount = "snapshot"

    /// Keeps the list as it is now - a second after the last change, so a burst is written once.
    /// Called on the main thread, where the rows are changed.
    public static func save(_ list: String, content: Content) {
        guard let me = User.getMyPin(), !me.isEmpty, !OfflinePolicy.isBlocking, !content.chats.isEmpty else {
            return
        }
        // Taken now, on this thread: the rows go on changing after this returns.
        let plist: [String: Any] = [
            "version": 1,
            "me": me,
            "chats": content.chats.map { $0.snapshotFields },
            "groups": content.groupMaps.mapValues { $0.map { $0.snapshotFields } },
            "archived": content.archived.map { $0.snapshotFields },
            "maxArchived": content.maxArchived,
            "names": content.senderNames
        ]
        pendingWrites[list]?.cancel()
        let work = DispatchWorkItem {
            write(plist, to: list)
        }
        pendingWrites[list] = work
        queue.asyncAfter(deadline: .now() + 1, execute: work)
    }

    /// The list last kept for this account, where it may be shown.
    public static func load(_ list: String) -> Content? {
        guard let me = User.getMyPin(), !me.isEmpty, mayShow,
              let key = key(creating: false),
              let sealed = try? Data(contentsOf: file(list)),
              let box = try? AES.GCM.SealedBox(combined: sealed),
              let plain = try? AES.GCM.open(box, using: key),
              let plist = (try? PropertyListSerialization.propertyList(from: plain, options: [], format: nil)) as? [String: Any],
              plist["me"] as? String == me else {
            return nil
        }
        func rows(_ value: Any?) -> [Chat] {
            return (value as? [[String: Any]] ?? []).map { Chat.fromSnapshot($0) }
        }
        let chats = rows(plist["chats"])
        guard !chats.isEmpty else { return nil }
        return Content(chats: chats,
                       groupMaps: (plist["groups"] as? [String: Any] ?? [:]).mapValues { rows($0) },
                       archived: rows(plist["archived"]),
                       maxArchived: plist["maxArchived"] as? [String: [String]] ?? [:],
                       senderNames: plist["names"] as? [String: String] ?? [:])
    }

    /// Every list kept, and its key - when the account goes.
    public static func clear() {
        // A write still waiting would put back what is being taken away.
        DispatchQueue.main.async {
            pendingWrites.values.forEach { $0.cancel() }
            pendingWrites.removeAll()
        }
        queue.async {
            try? FileManager.default.removeItem(at: folder)
            SecItemDelete(keyQuery() as CFDictionary)
        }
    }

    /// Not while reading is blocked; and where offline means no reading, not without a network to
    /// be online on - the block itself is only decided a moment after launch.
    private static var mayShow: Bool {
        if OfflinePolicy.isBlocking {
            return false
        }
        if OfflinePolicy.applies && !hasRoute {
            return false
        }
        return true
    }

    private static var hasRoute: Bool {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        guard let reachability = withUnsafePointer(to: &address, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        var flags = SCNetworkReachabilityFlags()
        guard SCNetworkReachabilityGetFlags(reachability, &flags) else {
            return false
        }
        return flags.contains(.reachable) && !flags.contains(.connectionRequired)
    }

    private static var folder: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("ChatListSnapshot", isDirectory: true)
    }

    private static func file(_ list: String) -> URL {
        return folder.appendingPathComponent(list + ".snapshot")
    }

    private static func write(_ plist: [String: Any], to list: String) {
        guard let key = key(creating: true),
              let plain = try? PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0),
              let sealed = try? AES.GCM.seal(plain, using: key).combined else {
            return
        }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? sealed.write(to: file(list), options: [.atomic, .completeFileProtection])
    }

    private static func keyQuery() -> [String: Any] {
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAccount]
    }

    private static func key(creating: Bool) -> SymmetricKey? {
        var query = keyQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data, data.count == 32 {
            return SymmetricKey(data: data)
        }
        guard creating else { return nil }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        var item = keyQuery()
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemDelete(keyQuery() as CFDictionary)
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { return nil }
        return key
    }
}

extension Chat {

    /// The row as a property list, for ChatListSnapshot.
    var snapshotFields: [String: Any] {
        return ["fpin": fpin, "pin": pin, "messageId": messageId, "counter": counter,
                "messageText": messageText, "serverDate": serverDate, "image": image, "video": video,
                "file": file, "attachmentFlag": attachmentFlag, "messageScope": messageScope,
                "name": name, "profile": profile, "official": official, "status": status,
                "credential": credential, "lock": lock, "thumb": thumb, "audio": audio, "gif": gif,
                "groupId": groupId, "groupName": groupName, "isParent": isParent,
                "pinned": NSNumber(value: pinned), "isBot": isBot, "isFolPinned": isFolPinned,
                "namesMe": namesMe]
    }

    static func fromSnapshot(_ fields: [String: Any]) -> Chat {
        func text(_ key: String) -> String { fields[key] as? String ?? "" }
        let chat = Chat(fpin: text("fpin"), pin: text("pin"), messageId: text("messageId"), counter: text("counter"),
                        messageText: text("messageText"), serverDate: text("serverDate"), image: text("image"),
                        video: text("video"), file: text("file"), attachmentFlag: text("attachmentFlag"),
                        messageScope: text("messageScope"), name: text("name"), profile: text("profile"),
                        official: text("official"), status: text("status"), credential: text("credential"),
                        lock: text("lock"), thumb: text("thumb"), audio: text("audio"), gif: text("gif"),
                        groupId: text("groupId"), groupName: text("groupName"),
                        isParent: fields["isParent"] as? Bool ?? false,
                        pinned: (fields["pinned"] as? NSNumber)?.int64Value ?? 0,
                        isBot: fields["isBot"] as? Int ?? 0,
                        isFolPinned: fields["isFolPinned"] as? Bool ?? false)
        chat.namesMe = fields["namesMe"] as? Bool ?? false
        return chat
    }
}
