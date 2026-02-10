//
//  OutgoingThread.swift
//  Runner
//
//  Created by Yayan Dwi on 20/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import FMDB

class OutgoingThread {
    
    static let `default` = OutgoingThread()
    
    private var isRunning = false
    
    private var semaphore = DispatchSemaphore(value: 0)
    
    private var connection = DispatchSemaphore(value: 0)
    
    private var dispatchQueue = DispatchQueue(label: "OutgoingThread")
    
    private var queue = [TMessage]()
    
    init() {
        DispatchQueue.global().async { [self] in
            while Database.shared.database == nil {
                Thread.sleep(forTimeInterval: 1.0)
            }
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message, id from OUTGOING") {
                        while cursor.next() {
                            if let message = cursor.string(forColumnIndex: 0) {
                                let id = cursor.string(forColumnIndex: 1) ?? ""
//                                print("KOK ADA: \(id)")
                                let tMessage = TMessage(data: message)
                                let message_id = tMessage.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
                                if let cursorM = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE WHERE message_id='\(message_id)'"), cursorM.next() {
                                    let statusM = cursorM.string(forColumnIndex: 0) ?? "0"
                                    if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE_STATUS WHERE message_id='\(message_id)'") {
                                        var listStatus: [Int] = []
                                        while cursorStatus.next() {
                                            listStatus.append(Int(cursorStatus.string(forColumnIndex: 0)!)!)
                                        }
                                        let status = "\(listStatus.min() ?? Int(statusM)!)"
                                        if status == "1" {
                                            self.appendAndRunQueue(message: tMessage)
                                        } else {
                                            self.delOutgoing(fmdb: fmdb, messageId: id)
                                        }
                                        cursorStatus.close()
                                    } else {
                                        self.delOutgoing(fmdb: fmdb, messageId: id)
                                    }
                                    cursorM.close()
                                } else {
                                    self.delOutgoing(fmdb: fmdb, messageId: id)
                                }
                            }
                        }
                        cursor.close()
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
    }
    
    func addQueue(message: TMessage) {
        if message.getCode() == CoreMessage_TMessageCode.SEND_CHAT || message.getCode() == CoreMessage_TMessageCode.EDIT_MESSAGE {
            Nexilis.saveMessage(message: message)
        }
        appendAndRunQueue(message: message)
    }
    
    func appendAndRunQueue(message: TMessage) {
        queue.append(message)
        semaphore.signal()
        addOugoing(message: message)
    }
    
    private func addQueue(_ message: TMessage, at: Int) {
        Thread.sleep(forTimeInterval: 1)
        queue.insert(message, at: at)
        semaphore.signal()
    }
    
    private func addOugoing(message: TMessage) {
        DispatchQueue.global().async {
            let messageId = message.getStatus()
//            print("SAVE OUTGOING \(messageId)")
            if !messageId.isEmpty {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "OUTGOING", cvalues: [
                            "id" : messageId,
                            "message" : message.pack(),
                        ], replace: true)
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
            }
        }
    }
    
    private func delOutgoing(fmdb: Any, messageId: String) {
//        print("DELETE OUTGOING \(messageId)")
        _ = Database.shared.deleteRecord(fmdb: fmdb as! FMDatabase, table: "OUTGOING", _where: "id = '\(messageId)'")
    }
    
    func delOutgoing(fmdb: Any, packageId: String) {
        _ = Database.shared.deleteRecord(fmdb: fmdb as! FMDatabase, table: "OUTGOING", _where: "package = '\(packageId)'")
    }
    
    private var isWait = false
    
    func set(wait: Bool) {
        isWait = wait
        if !isWait {
            connection.signal()
            semaphore.signal()
        }
    }
    
    func getQueue() -> TMessage {
        while queue.isEmpty || queue.count == 0 {
            //print("QUEUE.wait")
//            DispatchQueue.global(qos: .background).async {
                self.semaphore.wait()
//            }
        }
        return queue.remove(at: 0)
    }
    
    func run() {
        if (isRunning) {
            return
        }
        isRunning = true
        dispatchQueue.async {
            while self.isRunning {
                if self.isWait {
                    //print("CONNECTION.wait")
                    self.connection.wait()
                } else {
                    self.process(message: self.getQueue())
                }
            }
        }
    }
    
    private func process(message: TMessage) {
//        print("outgoing process", message.toLogString())
        if self.isWait {
            queue.append(message)
            return
        }
        if message.getCode() == CoreMessage_TMessageCode.SEND_CHAT || message.getCode() == CoreMessage_TMessageCode.EDIT_MESSAGE {
            sendChat(message: message)
        } else if message.getCode() == CoreMessage_TMessageCode.DELETE_CTEXT {
            deleteMessage(message: message)
        }
    }
    
    /**
     *
     */
    
    private var maxRetryUpload: [String: Int] = [:]
    private var maxRetryUploadTime: [String: Int] = [:]
    
    private func sendChat(message: TMessage) {
        // if media exist upload first
        var fileName = message.getBody(key: CoreMessage_TMessageKey.IMAGE_ID, default_value: "")
        if fileName.isEmpty {
            fileName = message.getBody(key: CoreMessage_TMessageKey.AUDIO_ID)
        }
        if fileName.isEmpty {
            fileName = message.getBody(key: CoreMessage_TMessageKey.VIDEO_ID)
        }
        if fileName.isEmpty {
            fileName = message.getBody(key: CoreMessage_TMessageKey.FILE_ID)
        }
        let isMedia = !fileName.isEmpty
        if isMedia {
            if maxRetryUpload[message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)] == nil {
                maxRetryUpload[message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)] = 0
                maxRetryUploadTime[message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)] = Date().currentTimeMillis()
            }
            if (!message.getBody(key: CoreMessage_TMessageKey.THUMB_ID).isEmpty) {
                Network().uploadHTTP(name: message.getBody(key: CoreMessage_TMessageKey.THUMB_ID)) { (result, progress) in
                    if result, progress == 100 {
                        do {
                            do{
                                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                                let fileURL = documentsDirectory.appendingPathComponent(CoreMessage_TMessageKey.THUMB_ID)
                                try FileEncryption.shared.writeSecure(filename: CoreMessage_TMessageKey.THUMB_ID, data: Data(contentsOf: fileURL))
                                try FileManager.default.removeItem(atPath: fileURL.path)
                                if var data = try FileEncryption.shared.readSecure(filename: CoreMessage_TMessageKey.THUMB_ID) {
                                    let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                    if dataDecrypt != nil {
                                        data = dataDecrypt!
                                    }
                                    message.setMedia(media: [UInt8] (data))
                                }
                            } catch {
                                
                            }
                        } catch {}
                        Network().uploadHTTP(name: fileName) { (result, progress) in
                            if result {
                                if let delegate = Nexilis.shared.messageDelegate {
                                    delegate.onUpload(name: fileName, progress: progress)
                                }
                                if progress == 100 {
                                    if let response = Nexilis.writeSync(message: message) {
                                        let messageId = response.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
                                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                            do {
                                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                    "status" : response.getBody(key: CoreMessage_TMessageKey.STATUS, default_value: "2")
                                                ], _where: "message_id = '\(messageId)'")
                                                self.delOutgoing(fmdb: fmdb, messageId: message.getStatus())
                                            } catch {
                                                rollback.pointee = true
                                                print("Access database error: \(error.localizedDescription)")
                                            }
                                        })
                                        do {
                                            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                                            let fileURL = documentsDirectory.appendingPathComponent(fileName)
                                            try FileEncryption.shared.writeSecure(filename: fileName, data: Data(contentsOf: fileURL))
                                            try FileManager.default.removeItem(atPath: fileURL.path)
                                        } catch {
                                            
                                        }
                                    } else {
                                        self.retryUpload(message: message, fileName: fileName)
                                    }
                                }
                            } else {
                                self.retryUpload(message: message, fileName: fileName)
                            }
                        }
                    } else {
                        if !result {
                            self.retryUpload(message: message, fileName: fileName)
                        }
                    }
                }
            } else {
                Network().uploadHTTP(name: fileName) { (result, progress) in
                    if result {
                        if let delegate = Nexilis.shared.messageDelegate {
                            delegate.onUpload(name: fileName, progress: progress)
                        }
                        if progress == 100 {
                            if let response = Nexilis.writeSync(message: message) {
                                //print("sendChat", response.toLogString())
                                let messageId = response.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                            "status" : response.getBody(key: CoreMessage_TMessageKey.STATUS, default_value: "2")
                                        ], _where: "message_id = '\(messageId)'")
                                        self.delOutgoing(fmdb: fmdb, messageId: message.getStatus())
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                do{
                                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                                    let fileURL = documentsDirectory.appendingPathComponent(fileName)
                                    try FileEncryption.shared.writeSecure(filename: fileName, data: Data(contentsOf: fileURL))
                                    try FileManager.default.removeItem(atPath: fileURL.path)
                                } catch {
                                    
                                }
                            } else {
                                self.retryUpload(message: message, fileName: fileName)
                            }
                        }
                    } else {
                        self.retryUpload(message: message, fileName: fileName)
                    }
                }
            }
        } else {
            if let response = Nexilis.writeSync(message: message) {
//                print("sendChatRESP", response.toLogString())
                if !response.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID).isEmpty {
                    let messageId = response.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                "status" : response.getBody(key: CoreMessage_TMessageKey.STATUS, default_value: "2")
                            ], _where: "message_id = '\(messageId)'")
                            self.delOutgoing(fmdb: fmdb, messageId: message.getStatus())
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                } else {
//                    print("retry sendChat")
                    OutgoingThread.default.addQueue(message: message)
                }
            } else {
//                print("retry sendChat")
                OutgoingThread.default.addQueue(message: message)
            }
        }
    }
    
    private func retryUpload(message: TMessage, fileName: String) {
        //print("masuk Retry")
        var maxRetry = Utils.getMaxRetryUpload()
        var maxRetryTime = Utils.getMaxRetryTimeUpload()
        
        if maxRetry == "0" {
            maxRetry = "5"
        }
        if maxRetryTime == "0" {
            maxRetryTime = "60000"
        }
        
        var countRetry = 0
        do {
            countRetry = maxRetryUpload[message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)] ?? 0
            countRetry += 1
            //print("masuk Retry1 = \(countRetry)")
            maxRetryUpload.updateValue(countRetry, forKey: message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID))
        } catch {}
        if countRetry >= Int(maxRetry)! {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                        "status" : "0"
                    ], _where: "message_id = '\(message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID))'")
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                        "status" : "0"
                    ], _where: "message_id = '\(message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID))'")
                    self.delOutgoing(fmdb: fmdb, messageId: message.getStatus())
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            var dataMessage: [AnyHashable : Any] = [:]
            dataMessage["message_id"] = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
            dataMessage["status"] = "0"
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.failedSendMessage), object: nil, userInfo: dataMessage)
            maxRetryUpload.removeValue(forKey: message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID))
            maxRetryUploadTime.removeValue(forKey: message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID))
            if let delegate = Nexilis.shared.messageDelegate {
                delegate.onUpload(name: fileName, progress: 100)
            }
        } else {
            DispatchQueue.global().asyncAfter(deadline: .now() + 5, execute: { [self] in
                let timeRetry = maxRetryUploadTime[message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)] ?? 0
                if timeRetry != 0 {
                    if (timeRetry + Int(maxRetryTime)!) <= Date().currentTimeMillis() {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                    "status" : "0"
                                ], _where: "message_id = '\(message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID))'")
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                                    "status" : "0"
                                ], _where: "message_id = '\(message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID))'")
                                self.delOutgoing(fmdb: fmdb, messageId: message.getStatus())
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                        var dataMessage: [AnyHashable : Any] = [:]
                        dataMessage["message_id"] = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
                        dataMessage["status"] = "0"
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Nexilis.failedSendMessage), object: nil, userInfo: dataMessage)
                        maxRetryUpload.removeValue(forKey: message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID))
                        maxRetryUploadTime.removeValue(forKey: message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID))
                        if let delegate = Nexilis.shared.messageDelegate {
                            delegate.onUpload(name: fileName, progress: 100)
                        }
                        return
                    }
                }
                //print("retry sukses")
                var messageExist = false
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select message_id from MESSAGE where message_id = '\(message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID))'"), cursor.next() {
                        messageExist = true
                        cursor.close()
                    }
                })
                if messageExist {
                    sendChat(message: message)
                }
            })
        }
    }
    
    private func deleteMessage(message: TMessage) {
        let messageId = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
        let type = message.getBody(key: CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG)
        
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if type == "1" {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                        "message_text" : "🚫 _This message was deleted_",
                        "lock" : "1",
                        "thumb_id" : "",
                        "image_id" : "",
                        "file_id" : "",
                        "audio_id" : "",
                        "video_id" : "",
                        "reff_id" : "",
                        "attachment_flag" : 0,
                        "is_stared" : "0",
                        "credential" : "0",
                        "read_receipts" : "4"
                    ], _where: "message_id = '\(messageId)'")
                    if let package = Nexilis.write(message: message) {
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "OUTGOING", cvalues: [
                            "package" : package
                        ], _where: "id = '\(messageId)'")
                    }
                    if let delegate = Nexilis.shared.messageDelegate {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                        delegate.onMessage(message: message)
                    }
                } else {
                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "message_id = '\(messageId)'")
                    _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "message_id = '\(messageId)'")
                    let l_pin = message.getBody(key: CoreMessage_TMessageKey.L_PIN)
                    let chat = message.getBody(key: CoreMessage_TMessageKey.CHAT_ID)
                    let scope = message.getBody(key: CoreMessage_TMessageKey.SCOPE_ID)
                    do {
                        var pin = l_pin
                        if !chat.isEmpty {
                            pin = chat
                        }
                        var pinned = 0
                        var archived = 0
                        var queryGetLastMessageId = "SELECT message_id FROM MESSAGE where (f_pin = '\(pin)' OR l_pin = '\(pin)') AND (message_scope_id = '\(MessageScope.FORM)' OR message_scope_id = '\(MessageScope.MISSED_CALL)' OR message_scope_id = '\(MessageScope.CALL)' OR message_scope_id = '\(MessageScope.WHISPER)') AND is_call_center = 0 order by server_date desc LIMIT 1"
                        if scope == "4" {
                            queryGetLastMessageId = "SELECT message_id FROM MESSAGE where l_pin = '\(chat.isEmpty ? pin : l_pin)' AND chat_id = '\(chat)' AND message_scope_id = '\(MessageScope.GROUP)' AND is_call_center = 0 order by server_date desc LIMIT 1"
                        }
                        var messageId = ""
                        if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: queryGetLastMessageId), cursorData.next() {
                            messageId = cursorData.string(forColumnIndex: 0) ?? ""
                            cursorData.close()
                        }
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select pinned, archived from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                            pinned = Int(cursor.int(forColumnIndex: 0))
                            archived = Int(cursor.int(forColumnIndex: 1))
                        }
                        if !messageId.isEmpty {
                            _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                                "l_pin" : pin,
                                "message_id" : messageId,
                                "counter" : 0,
                                "pinned" : pinned,
                                "archived" : archived
                            ], replace: true)
                        }
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                    } catch {
                        rollback.pointee = true
                        //print(error)
                    }
                    self.delOutgoing(fmdb: fmdb, messageId: message.getStatus())
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
}
