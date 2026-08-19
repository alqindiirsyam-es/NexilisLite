//
//  InquiryThread.swift
//  NexilisLite
//
//  Created by Akhmad Al Qindi Irsyam on 23/11/22.
//

import Foundation
import FMDB

class InquiryThread {
    static let `default` = InquiryThread()
    
    private var isRunning = false
    
    private var semaphore = DispatchSemaphore(value: 0)
    
    private var connection = DispatchSemaphore(value: 0)
    
    private var dispatchQueue = DispatchQueue(label: "InquiryThread")
    
    private var queue = [TMessage]()
    
    init() {
        DispatchQueue.global().async { [self] in
            // Usable, not merely open: the connection exists a moment before the tables do.
            while !Database.shared.isReady {
                Thread.sleep(forTimeInterval: 1.0)
            }
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select status, message, id from INQUIRY") {
                        while cursor.next() {
                            let status = cursor.int(forColumnIndex: 0)
                            if status == 1 {
                                delInquiry(fmdb: fmdb, messageId: cursor.string(forColumnIndex: 2)!)
                                continue
                            }
                            if let cursorMessage = Database.shared.getRecords(fmdb: fmdb, query: "select message_id from MESSAGE where message_id = '\(cursor.string(forColumnIndex: 2)!)'") {
                                if cursorMessage.next() {
                                    if let message = cursor.string(forColumnIndex: 1) {
                                        addQueue(message: TMessage(data: message))
                                    }
                                } else {
                                    delInquiry(fmdb: fmdb, messageId: cursor.string(forColumnIndex: 2)!)
                                }
                                cursorMessage.close()
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
    
    private func delInquiry(fmdb: Any, messageId: String) {
        _ = Database.shared.deleteRecord(fmdb: fmdb as! FMDatabase, table: "INQUIRY", _where: "id = '\(messageId)'")
    }
    
    func addQueue(message: TMessage) {
        //print("MASUK INQUIRY ADD")
        addInquiry(message: message)
        queue.append(message)
        semaphore.signal()
    }
    
    private func addQueue(_ message: TMessage, at: Int) {
        Thread.sleep(forTimeInterval: 1)
        queue.insert(message, at: at)
        semaphore.signal()
    }
    
    private func addInquiry(message: TMessage) {
        DispatchQueue.global().async {
            let messageId = message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)
            if !messageId.isEmpty {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        //print("SIMPAN MESSAGE TO INQUIRY TABLE")
                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "INQUIRY", cvalues: [
                            "id" : messageId,
                            "status" : 0,
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
            //print("QUEUE INQUIRY.wait")
//            DispatchQueue.global(qos: .background).async {
                self.semaphore.wait()
//            }
        }
        return queue.remove(at: 0)
    }
    
    func run() {
        //print("RUN QUEUE")
        if (isRunning) {
            return
        }
        //print("isRunning false")
        isRunning = true
        dispatchQueue.async {
            while self.isRunning {
                if self.isWait {
                    //print("CONNECTION INQUIRY.wait")
                    self.connection.wait()
                } else {
                    self.process(message: self.getQueue())
                }
            }
        }
    }
    
    private func process(message: TMessage) {
        //print("inquiry process", message.toLogString())
        mobileInquiry(message: message)
    }
    
    /**
     *
     */
    
    private func mobileInquiry(message: TMessage) {
        Nexilis.saveMessage(message: message)
        //print("save message sendChat")
        if !self.isWait {
            //print("inquiry write", message.toLogString())
            var res = Nexilis.write(message: CoreMessage_TMessageBank.getMobileInquiry(message_id: message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)))
            while res == nil {
                res = Nexilis.write(message: CoreMessage_TMessageBank.getMobileInquiry(message_id: message.getBody(key: CoreMessage_TMessageKey.MESSAGE_ID)))
            }
        } else {
            queue.append(message)
        }
    }
}
