//
//  Database.swift
//  Runner
//
//  Created by Yayan Dwi on 15/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import FMDB
import Security
import KeychainAccess

public class Database {
    
    public init() {
        let databasePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/encrypted_db_es.db"
        if FileManager.default.fileExists(atPath: databasePath) && database == nil {
            DispatchQueue.global().async {
                _ = FileEncryption.shared.encryptFileToServer(data: Data())
                while FileEncryption.shared.aesKey == nil {
                    Thread.sleep(forTimeInterval: 1)
                }
                self.setDBInstance()
            }
        }
    }
    
    public static func recreateInstance() {
        Database.shared = Database()
    }
    
    public static var shared = Database()
    
    public var database: FMDatabaseQueue!
    
    func setupDatabaseQueue(withPath databasePath: String) -> FMDatabaseQueue? {
        if !FileManager.default.fileExists(atPath: databasePath) {
            FileManager.default.createFile(atPath: databasePath, contents: nil, attributes: nil)
        }
        
        do {
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: databasePath)
//            print("File protection attribute set to 'complete'.")
        } catch {
//            print("Error setting file protection attribute: \(error)")
            return nil
        }
        
        guard let dbQueue = FMDatabaseQueue(path: databasePath) else {
//            print("Failed to create FMDatabaseQueue.")
            return nil
        }
        
        return dbQueue
    }
    
    func setDBInstance() {
        let databasePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/encrypted_db_es.db"
        database = setupDatabaseQueue(withPath: databasePath)
        database?.inDatabase({(fmdb) in
            let p = Utils.getPassEncDB()
            if p.isEmpty {
                let pragmas = [
                    "PRAGMA cipher_page_size = 1024",
                    "PRAGMA kdf_iter = 64000",
                    "PRAGMA cipher_hmac_algorithm = HMAC_SHA512",
                    "PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512",
                    "PRAGMA cipher = 'aes-256-gcm'"
                ]
                
                for pragma in pragmas {
                    if !fmdb.executeStatements(pragma) {
                        print("Failed to set pragma: \(pragma)")
                    }
                }
                let key = FileEncryption.shared.aesKey?.withUnsafeBytes { Data($0) }
                let keyIv = FileEncryption.shared.aesIV
                var keyString = ""
                if key != nil {
                    keyString = key!.base64EncodedString()
                }
                if keyIv != nil {
                    keyString += keyIv!.base64EncodedString()
                }
                fmdb.setKey(keyString)
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "databaseOpened"), object: nil, userInfo: nil)
        })
    }

    
    func openDatabase() -> Int {
        if FileEncryption.shared.aesKey != nil {
            setDBInstance()
        }
        var result = 0
        database?.inTransaction({(fmdb, rollback) in
            do {
                try createDatabase(fmdb: fmdb)
                addColumnIfNeeded(database: fmdb, tableName: "MESSAGE_SUMMARY", columnName: "pinned", columnType: "INTEGER", defaultValue: "0")
                addColumnIfNeeded(database: fmdb, tableName: "MESSAGE_SUMMARY", columnName: "archived", columnType: "INTEGER", defaultValue: "0")
                addColumnIfNeeded(database: fmdb, tableName: "MESSAGE", columnName: "is_pinned", columnType: "TEXT", defaultValue: "0")
                addColumnIfNeeded(database: fmdb, tableName: "MESSAGE", columnName: "attachment_speciality", columnType: "TEXT", defaultValue: "")
                result = 1
//                    print("Create Done")
            } catch {
            }
        })
        return result
    }
    
    func addColumnIfNeeded(database: FMDatabase, tableName: String, columnName: String, columnType: String, defaultValue: String? = nil) {
        do {
            // 1. Check if the column already exists
            let rs = try database.executeQuery("PRAGMA table_info(\(tableName))", values: nil)
            var columnExists = false
            while rs.next() {
                if let existingColumn = rs.string(forColumn: "name"), existingColumn == columnName {
                    columnExists = true
                    break
                }
            }
            rs.close()

            // 2. If it doesn't exist, add the column
            if !columnExists {
                var alterSQL = "ALTER TABLE \(tableName) ADD COLUMN \(columnName) \(columnType)"
                if let defaultValue = defaultValue {
                    // Wrap string values in single quotes, leave numeric unquoted
                    if columnType.lowercased().contains("char") || columnType.lowercased().contains("text") {
                        alterSQL += " DEFAULT '\(defaultValue)'"
                    } else {
                        alterSQL += " DEFAULT \(defaultValue)"
                    }
                }
                try database.executeUpdate(alterSQL, values: nil)
//                print("Added column \(columnName)")
            } else {
//                print("Column \(columnName) already exists")
            }
        } catch {
            print("Error checking or adding column: \(error.localizedDescription)")
        }
    }
    
    func createDatabase(fmdb:FMDatabase) throws -> Void{
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'BUDDY' (" +
                                "'_id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL," +
                                "'f_pin' text NOT NULL UNIQUE," +
                                "'upline_pin' text," +
                                "'first_name' text," +
                                "'last_name' text," +
                                "'image_id' TEXT," +
                                "'user_id' TEXT," +
                                "'quote' TEXT," +
                                "'connected' TEXT DEFAULT (0)," +
                                "'last_update' TEXT," +
                                "'latitude' text," +
                                "'longitude' text," +
                                "'altitude' text," +
                                "'cell' text," +
                                "'last_loc_update' text," +
                                "'type' text," +
                                "'empty_2' text," +
                                "'timezone' text," +
                                "'privacy_flag' text," +
                                "'msisdn' text," +
                                "'email' text," +
                                "'created_date' text," +
                                "'offline_mode' text DEFAULT (0)," +
                                "'network_type' text DEFAULT (0)," +
                                "'ex_block' TEXT DEFAULT (0)," +
                                "'ex_follow' TEXT DEFAULT (0)," +
                                "'ex_offmp' TEXT DEFAULT (0)," +
                                "'ex_follower' TEXT DEFAULT (0)," +
                                "'ex_status' TEXT DEFAULT (0)," +
                                "'auto_quote' TEXT ," +
                                "'auto_quote_type' TEXT ," +
                                "'ex_broadcasting' TEXT DEFAULT (0) ," +
                                "'indicator_status' TEXT DEFAULT (0)," +
                                "'muted' TEXT DEFAULT (0)," +
                                "'pos_flag' TEXT DEFAULT (0)," +
                                "'shop_code' TEXT DEFAULT (0)," +
                                "'shop_name' TEXT DEFAULT (0)," +
                                "'android_version' INTEGER DEFAULT 0," +
                                "'device_id' TEXT DEFAULT (0)," +
                                "'extension' TEXT DEFAULT (0)," +
                                "'auto_quote_status' TEXT DEFAULT (0)," +
                                "'connection_speed' TEXT DEFAULT (0)," +
                                "'be_info' TEXT," +
                                "'org_id' TEXT," +
                                "'org_name' TEXT," +
                                "'org_thumb' TEXT," +
                                "'card_type' TEXT," +
                                "'card_id' TEXT," +
                                "'gender' TEXT," +
                                "'birthdate' TEXT," +
                                "'type_ads' TEXT DEFAULT (0)," +
                                "'type_lp' TEXT DEFAULT (0)," +
                                "'type_post' TEXT DEFAULT (0)," +
                                "'address' TEXT," +
                                "'bidang_industri' TEXT," +
                                "'visi' TEXT," +
                                "'misi' TEXT," +
                                "'company_lat' TEXT," +
                                "'company_lng' TEXT," +
                                "'web' TEXT," +
                                "'certificate_image' TEXT," +
                                "'official_account' TEXT DEFAULT (0)," +
                                "'user_type' TEXT DEFAULT (0)," +
                                "'real_name' TEXT," +
                                "'is_sub_account' TEXT DEFAULT (0)," +
                                "'last_sign' TEXT," +
                                "'android_id' TEXT," +
                                "'is_change_profile' TEXT DEFAULT (0)," +
                                "'area' TEXT DEFAULT (0)," +
                                "'is_second_layer' TEXT DEFAULT (0)" +
                                ")", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_message_id on BUDDY (msisdn)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_f_pin on BUDDY (f_pin)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_user_id on BUDDY (user_id)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_ex_status on BUDDY (ex_status)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_first_name on BUDDY (first_name)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_extension on BUDDY (extension)", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'GROUPZ' (" +
                                "'_id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL," +
                                "'group_id' text NOT NULL UNIQUE," +
                                "'f_name' text," +
                                "'scope_id' text," +
                                "'image_id' TEXT," +
                                "'quote' text," +
                                "'last_update' text," +
                                "'created_by' text," +
                                "'created_date' text," +
                                "'ex_block' TEXT DEFAULT (0)," +
                                "'folder_id' TEXT," +
                                "'chat_modifier' TEXT," +
                                "'group_type' INTEGER DEFAULT 0," +
                                "'parent' text," +
                                "'level' text," +
                                "'muted' INTEGER DEFAULT 0," +
                                "'is_open' INTEGER DEFAULT 0," +
                                "'official' INTEGER DEFAULT 0," +
                                "'level_edu' INTEGER DEFAULT -1," +
                                "'materi_edu' INTEGER DEFAULT -1," +
                                "'is_education' INTEGER DEFAULT 0)", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'MESSAGE' (" +
                                "'message_id' TEXT NOT NULL UNIQUE," +
                                "'f_pin' TEXT," +
                                "'l_pin' TEXT," +
                                "'message_scope_id' TEXT," +
                                "'server_date' INTEGER," +
                                "'status' TEXT," +
                                "'message_text' TEXT," +
                                "'audio_id' TEXT," +
                                "'video_id' TEXT," +
                                "'image_id' TEXT," +
                                "'thumb_id' TEXT," +
                                "'opposite_pin' TEXT," +
                                "'lock' TEXT," +
                                "'format' TEXT," +
                                "'broadcast_flag' INTEGER DEFAULT 0," +
                                "'blog_id' TEXT," +
                                "'f_user_id' TEXT," +
                                "'l_user_id' TEXT," +
                                "'read_receipts' INTEGER DEFAULT 0," +
                                "'chat_id' TEXT," +
                                "'file_id' TEXT," +
                                "'delivery_receipts' INTEGER DEFAULT 0," +
                                "'account_type' TEXT," +
                                "'contact' TEXT," +
                                "'credential' TEXT," +
                                "'attachment_flag' INTEGER DEFAULT 0," +
                                "'is_stared' INTEGER DEFAULT 0," +
                                "'f_display_name' TEXT," +
                                "'reff_id' TEXT," +
                                "'sent_qty' INTEGER DEFAULT 0," +
                                "'delivered_qty' INTEGER DEFAULT 0," +
                                "'read_qty' INTEGER DEFAULT 0," +
                                "'ack_qty' INTEGER DEFAULT 0," +
                                "'read_local_qty' INTEGER DEFAULT 0," +
                                "'delivered_pin' TEXT," +
                                "'read_pin' TEXT," +
                                "'ack_pin' TEXT," +
                                "'read_local_pin' TEXT," +
                                "'expired_qty' TEXT," +
                                "'message_large_text' TEXT," +
                                "'tag_forum' TEXT," +
                                "'tag_activity' TEXT," +
                                "'unk_numbers' INTEGER DEFAULT 0," +
                                "'conn_state' INTEGER DEFAULT 1," +
                                "'tag_client' TEXT," +
                                "'gif_id' TEXT," +
                                "'tag_subactivity' TEXT," +
                                "'messagenumber' INTEGER DEFAULT 0," +
                                "'mail_account' TEXT," +
                                "'message_text_plain' TEXT," +
                                "'local_timestamp' TEXT," +
                                "'is_consult' INTEGER DEFAULT 0," +
                                "'is_call_center' INTEGER DEFAULT 0," +
                                "'call_center_id' TEXT," +
                                "'last_edited' INTEGER DEFAULT 0," +
                                "'is_secret' INTEGER DEFAULT 0," +
                                "'is_deleted_retention' INTEGER DEFAULT 0," +
                                "'is_forwarded_message' INTEGER DEFAULT 0," +
                                "'is_pinned' INTEGER DEFAULT 0," +
                                "'attachment_speciality' TEXT" +
                                ")", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_m_opposite on MESSAGE (opposite_pin, chat_id)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_m_chat_id on MESSAGE (chat_id)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_m_server_date on MESSAGE (server_date)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_m_account_type on MESSAGE (account_type)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_m_mail_account on MESSAGE (mail_account)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_m_reff_id on MESSAGE (reff_id)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_m_local_timestamp on MESSAGE (local_timestamp)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_m_is_call_center on MESSAGE (is_call_center)", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'GROUPZ_MEMBER' (" +
                                "'group_id' TEXT NOT NULL," +
                                "'f_pin' TEXT NOT NULL," +
                                "'position' TEXT DEFAULT (0)," +
                                "'user_id' NOT NULL DEFAULT '-'," +
                                "'ac' NOT NULL DEFAULT '-'," +
                                "'ac_desc' NOT NULL DEFAULT '-'," +
                                "'first_name' TEXT NOT NULL," +
                                "'last_name' TEXT NOT NULL," +
                                "'msisdn' TEXT NOT NULL," +
                                "'thumb_id' TEXT NOT NULL," +
                                "'created_date' TEXT DEFAULT (0)," +
                                "PRIMARY KEY ('group_id', 'f_pin'))", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'DISCUSSION_FORUM' (" +
                                "'_id' integer PRIMARY KEY AUTOINCREMENT NOT NULL," +
                                "'chat_id' text UNIQUE," +
                                "'title' text," +
                                "'group_id' text," +
                                "'anonym' text," +
                                "'scope_id' text," +
                                "'thumb' text," +
                                "'category' text," +
                                "'activity' text," +
                                "'milis' text," +
                                "'sharing_flag' text," +
                                "'clients' text," +
                                "'owner' text," +
                                "'follow' integer NOT NULL default 0," +
                                "'raci_r' text," +
                                "'raci_a' text," +
                                "'raci_c' text," +
                                "'raci_i' text," +
                                "'act_thumb' text," +
                                "'client_thumb' text)", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'POST' (" +
                                "'post_id' TEXT NOT NULL UNIQUE," +
                                "'author_f_pin' TEXT NOT NULL," +
                                "'author_name' TEXT NOT NULL," +
                                "'author_thumbnail' TEXT NOT NULL," +
                                "'type' INTEGER DEFAULT '0'," +
                                "'created_date' TEXT DEFAULT ''," +
                                "'title' TEXT DEFAULT ''," +
                                "'description' TEXT DEFAULT ''," +
                                "'privacy' INTEGER DEFAULT '1'," +
                                "'audition_date' TEXT DEFAULT '0'," +
                                "'total_comment' INTEGER DEFAULT '0'," +
                                "'total_like' INTEGER DEFAULT '0'," +
                                "'total_dislike' INTEGER DEFAULT '0'," +
                                "'last_update' TEXT DEFAULT '0'," +
                                "'file_type' INTEGER DEFAULT '0'," +
                                "'thumb_id' TEXT DEFAULT ''," +
                                "'file_id' TEXT DEFAULT ''," +
                                "'video_duration' INTEGER DEFAULT '0'," +
                                "'category_id' INTEGER DEFAULT '0'," +
                                "'like_flag' INTEGER DEFAULT '0'," +
                                "'report_flag' TEXT DEFAULT '0'," +
                                "'last_edit' INTEGER DEFAULT '0'," +
                                "'post_id_participate' TEXT," +
                                "'participate_date' INTEGER DEFAULT '0'," +
                                "'certificates' TEXT," +
                                "'participate_size' INTEGER," +
                                "'total_view' INTEGER DEFAULT '0'," +
                                "'view_flag' INTEGER DEFAULT '0'," +
                                "'total_followers' INTEGER DEFAULT '0'," +
                                "'score' INTEGER DEFAULT '0'," +
                                "'share_sosmed_type' INTEGER DEFAULT '0'," +
                                "'link' TEXT DEFAULT ''," +
                                "'category_flag' TEXT DEFAULT ''," +
                                "'official_account' INTEGER DEFAULT '0'," +
                                "'roc_date' INTEGER DEFAULT '0'," +
                                "'roc_size' INTEGER DEFAULT '0'," +
                                "'level_edu' INTEGER DEFAULT '0'," +
                                "'materi_edu' INTEGER DEFAULT '0'," +
                                "'finaltest_edu' INTEGER DEFAULT '0'," +
                                "'file_summarization' TEXT DEFAULT ''," +
                                "'target' INTEGER DEFAULT '0'," +
                                "'pricing' INTEGER DEFAULT '0'," +
                                "'pricing_money' TEXT DEFAULT ''" +
                                ")", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'MESSAGE_STATUS' (" +
                                "'_id' integer PRIMARY KEY AUTOINCREMENT NOT NULL," +
                                "'message_id' text NOT NULL," +
                                "'status' integer NOT NULL DEFAULT 0," +
                                "'f_pin' text NOT NULL DEFAULT ''," +
                                "'user_id' text NOT NULL DEFAULT ''," +
                                "'last_update' integer," +
                                "'time_delivered' integer," +
                                "'time_read' integer," +
                                "'time_ack' integer," +
                                "'longitude' text NOT NULL DEFAULT ''," +
                                "'latitude' text NOT NULL DEFAULT ''," +
                                "'location' text NOT NULL DEFAULT '')", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS MESSAGE_STATUS_UK1 on MESSAGE_STATUS (message_id)", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'MESSAGE_SUMMARY' (" +
                                "'l_pin' text NOT NULL DEFAULT ''," +
                                "'message_id' text NOT NULL," +
                                "'counter' integer NOT NULL default 0," +
                                "'pinned' integer NOT NULL default 0," +
                                "'archived' integer NOT NULL default 0," +
                                "PRIMARY KEY ('l_pin'))", values: nil)
        
        try fmdb.executeUpdate("CREATE UNIQUE INDEX IF NOT EXISTS index_MESSAGE_SUMMARY_UK1 on MESSAGE_SUMMARY (l_pin)", values: nil)
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS index_MESSAGE_SUMMARY_UK2 on MESSAGE_SUMMARY (message_id)", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'OUTGOING' (" +
                                "'id' text PRIMARY KEY NOT NULL," +
                                "'package' text," +
                                "'message' text" +
                                ")", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'INQUIRY' (" +
                                "'id' text PRIMARY KEY NOT NULL," +
                                "'status' integer NOT NULL default 0," +
                                "'message' text" +
                                ")", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'FOLLOW' (" +
                                "'f_pin' text PRIMARY KEY NOT NULL" +
                                ")", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'MESSAGE_FAVORITE' (" +
        "'message_id' text PRIMARY KEY NOT NULL" +
        ")", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'LINK_PREVIEW' (" +
        "'id' text PRIMARY KEY NOT NULL," +
        "'link' text NOT NULL UNIQUE," +
        "'data_link' text," +
        "'retry' integer DEFAULT 0" +
        ")", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'PULL_DB' (" +
        "'id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL," +
        "'pull_type' text NOT NULL," +
        "'pull_key' text NOT NULL DEFAULT ('0')," +
        "'time' text" +
        ")", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'PREFS' (" +
        "'id' integer PRIMARY KEY AUTOINCREMENT NOT NULL," +
        "'key' text UNIQUE," +
        "'value' text" +
        ")", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'CALL_CENTER_HISTORY' (" +
        "'id' integer PRIMARY KEY AUTOINCREMENT NOT NULL," +
        "'type' integer NOT NULL," +
        "'title' text," +
        "'time' text," +
        "'f_pin' text," +
        "'data' text," +
        "'time_end' text," +
        "'complaint_id' text NOT NULL UNIQUE," +
        "'members' text," +
        "'requester' text" +
        ")", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'FORM_DATA' (" +
        "'id' integer PRIMARY KEY AUTOINCREMENT NOT NULL," +
        "'reff_id' TEXT NOT NULL UNIQUE," +
        "'form_id' TEXT," +
        "'title' text," +
        "'description' text," +
        "'created_by' text," +
        "'created_date' text," +
        "'target_date' text," +
        "'status' integer" +
        ")", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'TASK_PIC' (" +
        "'id' integer PRIMARY KEY AUTOINCREMENT NOT NULL," +
        "'reff_id' text," +
        "'sq_no' integer," +
        "'ac' text," +
        "'ac_desc' text," +
        "'f_pin' text," +
        "'submit_date' text," +
        "'submit_type' text," +
        "'submit_info' text," +
        "'submit_id' text)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS TASK_PIC_UK1 on TASK_PIC (reff_id,submit_date,f_pin,submit_info)", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'TASK_DETAIL' (" +
        "'id' integer PRIMARY KEY AUTOINCREMENT NOT NULL," +
        "'reff_id' text," +
        "'key' text," +
        "'value' text)", values: nil)
        
        try fmdb.executeUpdate("CREATE INDEX IF NOT EXISTS TASK_DETAIL_UK1 on TASK_DETAIL (reff_id,key)", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'SERVICE_BANK' (" +
        "'id' integer PRIMARY KEY AUTOINCREMENT NOT NULL," +
        "'service_id' text NOT NULL UNIQUE," +
        "'service_name' text," +
        "'description' text," +
        "'parent' text," +
        "'is_tablet' text)", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'WORKING_AREA' (" +
        "'id' integer PRIMARY KEY AUTOINCREMENT NOT NULL," +
        "'area_id' text NOT NULL UNIQUE," +
        "'name' text," +
        "'parent' text," +
        "'level' text)", values: nil)
        
        try fmdb.executeUpdate("CREATE TABLE IF NOT EXISTS 'GROUP_NM' (" +
                                "'_id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL," +
                                "'group_id' text NOT NULL UNIQUE," +
                                "'f_name' text," +
                                "'scope_id' text," +
                                "'image_id' TEXT," +
                                "'quote' text," +
                                "'last_update' text," +
                                "'created_by' text," +
                                "'created_date' text," +
                                "'ex_block' TEXT DEFAULT (0)," +
                                "'folder_id' TEXT," +
                                "'chat_modifier' INTEGER DEFAULT 1," +
                                "'group_type' INTEGER DEFAULT 0," +
                                "'parent' text," +
                                "'level' text," +
                                "'muted' INTEGER DEFAULT 0," +
                                "'is_open' INTEGER DEFAULT 0," +
                                "'official' INTEGER DEFAULT 0," +
                                "'level_edu' INTEGER DEFAULT -1," +
                                "'materi_edu' INTEGER DEFAULT -1," +
                                "'is_education' INTEGER DEFAULT 0)", values: nil)
    }
    
    public func executes(fmdb: FMDatabase, queries: [String]) {
        do {
            for sql in queries {
                try fmdb.executeUpdate(sql, values: nil)
            }
        } catch {
            //print(error.localizedDescription)
        }
    }
    
    public func rawQuery(fmdb: FMDatabase, queries: String) {
        do {
            try fmdb.executeUpdate(queries, values: nil)
        } catch {
            //print(error.localizedDescription)
        }
    }
    
    public func insertRecord(fmdb: FMDatabase, table: String, cvalues: [String:Any], replace: Bool) throws -> Int {
        var _result = 0
        var fields = ""
        var values = ""
        var delim = ""
        var data = [String]()
        for (key, value) in cvalues {
            fields += delim + key
            values += delim + "?"
            delim = ","
            if let stringval = value as? String{
                data.append(stringval)
            }
            else {
                let objval = String(describing: value)
                data.append(objval)
            }
            
        }
        try fmdb.executeUpdate((replace ? "replace" : "insert") + " into " + table + "(" + fields + ") values (" + values + ")", values: data)
        _result = 1
        return _result
    }
    
    public func getRecords(fmdb: FMDatabase, table: String, fields: [String], _where : String, group_by : String, order_by: String) -> FMResultSet? {
        var _result: FMResultSet? = nil
        do {
            var _fields = ""
            var delim = ""
            for field in fields {
                _fields += delim + field
                delim = ","
            }
            var _whereClause = ""
            if (!_where.isEmpty) {
                _whereClause = " where " + _where
            }
            if !group_by.isEmpty {
                _whereClause += " group by " + group_by
            }
            if !order_by.isEmpty {
                _whereClause += " order by " + order_by
            }
            _result = try fmdb.executeQuery("select " + _fields + " from " + table + _whereClause, values: nil)
        } catch {
            //print(error.localizedDescription)
        }
        return _result
    }
    
    public func getRecords(fmdb: FMDatabase, query: String) -> FMResultSet? {
        var _result: FMResultSet? = nil
        do {
            _result = try fmdb.executeQuery(query, values: nil)
        } catch {
            //print(error)
        }
        return _result
    }
    
    public func updateAllRecord(fmdb: FMDatabase, table: String, cvalues: [String:Any]) -> Int {
        var _result = 0
        do {
            var fields = ""
            var delim = ""
            var data = [Any]()
            for (key, value) in cvalues {
                fields += delim + key + " = ?"
                delim = ","
                data.append(value)
            }
            try fmdb.executeUpdate("update " + table + " set " + fields, values: data)
            _result = 1
        } catch {
            //print(error.localizedDescription)
        }
        return _result
    }
    
    public func updateRecord(fmdb: FMDatabase, table: String, cvalues: [String:Any], _where: String) -> Int {
        var _result = 0
        do {
            var fields = ""
            var delim = ""
            var data = [Any]()
            for (key, value) in cvalues {
                fields += delim + key + " = ?"
                delim = ","
                data.append(value)
            }
            var _whereClause = ""
            if (!_where.isEmpty) {
                _whereClause = " where " + _where
            }
            try fmdb.executeUpdate("update " + table + " set " + fields + _whereClause, values: data)
            _result = 1
        } catch {
            //print(error.localizedDescription)
        }
        return _result
    }
    
    public func deleteRecord(fmdb: FMDatabase, table: String, _where : String) -> Int {
        var _result = 0
        do {
            var _whereClause = ""
            if (!_where.isEmpty) {
                _whereClause = " where " + _where
            }
            try fmdb.executeUpdate("delete from " + table + _whereClause, values: nil)
            _result = 1
        } catch {
            //print(error.localizedDescription)
        }
        return _result
    }
}
