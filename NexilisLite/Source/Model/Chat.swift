//
//  Chat.swift
//  Qmera
//
//  Created by Yayan Dwi on 14/10/21.
//

import Foundation

public class Chat: Model {
    
    public let fpin: String
    public let pin: String
    public let messageId: String
    public let counter: String
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
    }
    
    public init(fpin:String, pin: String, messageId: String, counter: String, messageText: String, serverDate: String, image: String, video: String, file: String, attachmentFlag: String, messageScope: String, name: String, profile: String, official: String, status: String, credential: String, lock: String, thumb: String = "", audio: String = "", gif: String = "") {
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
    }
    
    public static func == (lhs: Chat, rhs: Chat) -> Bool {
        return lhs.pin == rhs.pin
    }
    
    public var description: String {
        return ""
    }
    
    public static func getMessageFromSearch(text: String = "") -> [String] {
        var messages: [String] = []
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                let query = "select message_id FROM MESSAGE where message_text LIKE '%\(text)%'"
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    while cursorData.next() {
                        let data = cursorData.string(forColumnIndex: 0) ?? ""
                        messages.append(data)
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
    
    public static func getData(messageId: String = "", isImage: Bool = false, isDoc: Bool = false, isVideo: Bool = false, isGIF: Bool = false, isLink: Bool = false, isAudio: Bool = false) -> [Chat] {
        var chats: [Chat] = []
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var lastQuery = ""
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
                var query = """
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.first_name || ' ' || ifnull(b.last_name, '') name, b.image_id profile, b.official_account, m.status, m.credential, m.lock, m.audio_id, m.gif_id from MESSAGE_SUMMARY ms, MESSAGE m, BUDDY b where ms.l_pin = b.f_pin and ms.message_id = m.message_id \(messageId.isEmpty ? "" : " and m.message_id = '\(messageId)'") and m.is_call_center = 0
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, 'Bot' name, '' profile, '', m.status, m.credential, m.lock, m.audio_id, m.gif_id from MESSAGE_SUMMARY ms, MESSAGE m where ms.l_pin = '-999' and "ms.message_id = m.message_id \(messageId.isEmpty ? "" : " and m.message_id = '\(messageId)'")" and m.is_call_center = 0
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, 'GPT SmartBot' name, '' profile, '', m.status, m.credential, m.lock, m.audio_id, m.gif_id from MESSAGE_SUMMARY ms, MESSAGE m where ms.l_pin = '-997' and "ms.message_id = m.message_id \(messageId.isEmpty ? "" : " and m.message_id = '\(messageId)'")" and m.is_call_center = 0
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.f_name || ' (\("Lounge".localized()))', b.image_id profile, b.official, m.status, m.credential, m.lock, m.audio_id, m.gif_id from MESSAGE_SUMMARY ms, MESSAGE m, GROUPZ b where ms.l_pin = b.group_id and ms.message_id = m.message_id \(messageId.isEmpty ? "" : " and m.message_id = '\(messageId)'") and m.is_call_center = 0
                            union
                            select m.f_pin, ms.l_pin, ms.message_id, ms.counter, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, c.f_name || ' (' || b.title || ')', c.image_id profile, '', m.status, m.credential, m.lock, m.audio_id, m.gif_id from MESSAGE_SUMMARY ms, MESSAGE m, DISCUSSION_FORUM b, GROUPZ c where b.group_id = c.group_id and ms.l_pin = b.chat_id and ms.message_id = m.message_id \(messageId.isEmpty ? "" : " and m.message_id = '\(messageId)'") and m.is_call_center = 0
                            order by 6 desc
                            """
                if !lastQuery.isEmpty {
                    query = "select m.f_pin, m.opposite_pin, m.message_id, m.thumb_id, m.message_text, m.server_date, m.image_id, m.video_id, m.file_id, m.attachment_flag, m.message_scope_id, b.first_name || ' ' || ifnull(b.last_name, '') name, b.image_id profile, b.official_account, m.credential, m.lock, m.audio_id, m.gif_id from MESSAGE m JOIN BUDDY b ON m.f_pin = b.f_pin where \(lastQuery) order by 6 desc"
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
                                        credential: !lastQuery.isEmpty ? cursorData.string(forColumnIndex: 11) ?? "" : cursorData.string(forColumnIndex: 15) ?? "",
                                        lock: !lastQuery.isEmpty ? cursorData.string(forColumnIndex: 12) ?? "" : cursorData.string(forColumnIndex: 16) ?? "",
                                        thumb: !lastQuery.isEmpty ? cursorData.string(forColumnIndex: 3) ?? "" : "",
                                        audio: !lastQuery.isEmpty ? cursorData.string(forColumnIndex: 13) ?? "" : cursorData.string(forColumnIndex: 17) ?? "",
                                        gif: !lastQuery.isEmpty ? cursorData.string(forColumnIndex: 14) ?? "" : cursorData.string(forColumnIndex: 18) ?? "")
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
