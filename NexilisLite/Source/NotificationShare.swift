//
//  NotificationShare.swift
//  NexilisLite
//
//  What the host's Notification Service Extension needs in order to write a chat notification the
//  way the app writes one - and the bookkeeping the two keep together so that a message is
//  announced, and counted, once.
//
//  The server's push carries the id of the message and nothing of the message (as Android's does).
//  The extension pulls the message by that id from the same pull_notification endpoint the app
//  uses, and needs, to do it and to word it:
//    - the account it asks as (pin, apikey, app name, user agent, cookies, domain) - in the
//      keychain, in the App Group's access group;
//    - whether this app is in a mode where content may be pulled at all (regular mode only: at the
//      Sentinel modes the request needs a token that lives in the app's process alone);
//    - names: people, groups and topics, so that a group message reads "Group (Topic)" and a
//      mention reads @name;
//    - the sounds picked for personal and group chats, as .caf files in the group's Library/Sounds;
//    - the badge as the app last knew it;
//    - the server keys the app has already verified against its pins, so the extension pins too;
//    - which messages the app has already put a banner up for, and which the extension has.
//
//  A host turns this on by putting its App Group in its Info.plist (and the extension's) under
//  NXNotificationAppGroup. Without it nothing here does anything.
//

import Foundation
import UIKit
import Security
import AVFoundation
import UserNotifications
import Intents
import NexilisZTA
import CryptoKit

public enum NotificationShare {

    /// The App Group shared with the extension, from the host's Info.plist.
    public static var appGroup: String? {
        let group = Bundle.main.object(forInfoDictionaryKey: "NXNotificationAppGroup") as? String ?? ""
        return group.isEmpty ? nil : group
    }

    private static var defaults: GroupPrefs? {
        guard let group = appGroup else { return nil }
        return GroupPrefs(group: group)
    }

    private static var container: URL? {
        guard let group = appGroup else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
    }

    private static let queue = DispatchQueue(label: "io.nexilis.notificationshare", qos: .utility)
    private static let importQueue = DispatchQueue(label: "io.nexilis.notificationshare.inbox", qos: .userInitiated)
    private static let keychainService = "io.nexilis.notification"
    private static let keychainAccount = "credentials"

    // Keys - read by the extension under the same names.
    private static let enabledKey = "nx.notif.enabled"
    private static let personNamesKey = "nx.notif.names.person"
    private static let groupNamesKey = "nx.notif.names.group"
    private static let topicsKey = "nx.notif.topics"
    private static let myPinKey = "nx.notif.mypin"
    private static let soundPersonalKey = "nx.notif.sound.personal"
    private static let soundGroupKey = "nx.notif.sound.group"
    private static let badgeKey = "nx.notif.badge"
    private static let pinsKey = "nx.notif.pins"
    private static let systemTrustKey = "nx.notif.systemtrust"
    private static let announcedLocallyKey = "nx.notif.announced.local"
    private static let announcedByPushKey = "nx.notif.announced.push"
    private static let autoDownloadKey = "nx.notif.autodownload"
    private static let personAvatarsKey = "nx.notif.avatars.person"
    private static let groupAvatarsKey = "nx.notif.avatars.group"

    // MARK: - Refreshing what the extension reads

    /// Writes everything the extension reads, off the main thread. Cheap enough to call whenever
    /// the app comes or goes.
    public static func refresh() {
        guard appGroup != nil else { return }
        observeInbox()
        // Read on the caller's thread what is only safe to read there; the rest on the queue.
        let pin = User.getMyPin() ?? ""
        let canPull = !pin.isEmpty && !NXSecurityPolicy.requiresServerChain() && !Utils.isHSAMode()
        let credentials = currentCredentials(pin: pin)
        let autoDownload = Utils.isAutoDownloadOn
        queue.async {
            relaxProtection()
            guard let defaults = defaults else { return }
            // What is only written when it changes is moved over from the UserDefaults now.
            defaults.migrate([pinsKey, systemTrustKey, badgeKey, announcedLocallyKey, announcedByPushKey])
            defaults.set(canPull, forKey: enabledKey)
            defaults.set(pin, forKey: myPinKey)
            defaults.set(autoDownload, forKey: autoDownloadKey)
            if canPull {
                writeCredentials(credentials)
                ensureInboxKey()
                writeNames(into: defaults)
            } else {
                // Nothing about the account or the people in it is left where it is not used.
                deleteCredentials()
                for key in [personNamesKey, groupNamesKey, topicsKey, personAvatarsKey, groupAvatarsKey] {
                    defaults.removeObject(forKey: key)
                }
                removeAvatars()
                removeLists()
            }
            publishSounds(into: defaults)
        }
    }

    /// A Contact Center request has just been sent: the extension may say once again that no officer
    /// has answered it (CC25, which it otherwise says only once in a while).
    public static func noteContactCenterRequest() {
        defaults?.removeObject(forKey: "nx.notif.cc25.at")
    }

    /// The Auto Download setting, as it has just been switched: the extension attaches a picture or
    /// a video itself only when it is on (a thumbnail always, as the app fetches one always).
    public static func noteAutoDownload(_ on: Bool) {
        defaults?.set(on, forKey: autoDownloadKey)
    }

    /// Only the account the extension asks as - after the session cookies have been renewed.
    public static func refreshCredentials() {
        guard appGroup != nil else { return }
        let pin = User.getMyPin() ?? ""
        guard !pin.isEmpty, !NXSecurityPolicy.requiresServerChain(), !Utils.isHSAMode() else { return }
        let credentials = currentCredentials(pin: pin)
        queue.async {
            writeCredentials(credentials)
        }
    }

    private static func currentCredentials(pin: String) -> [String: String] {
        return [
            "pin": pin,
            "apikey": SecureUserDefaults.shared.value(forKey: "apiKey") ?? "",
            "app_id": APIS.getAppNm(),
            "user_agent": Utils.getUserAgent(),
            "cookies": Utils.getCookiesMobile(),
            "domain": Utils.getDomainOpr(),
            // Where attachments are fetched from, and the key the server encrypts them with -
            // so a picture or a video can be shown in the notification itself.
            "media_base": Utils.getURLBase() + "filepalio/image/",
            "media_key": Utils.getSecureFolderEncrypt(),
            "media_iv": Utils.getSecureFolderEncryptIv()
        ]
    }

    /// Only the sounds - after one has been picked in Settings.
    public static func refreshSounds() {
        guard appGroup != nil else { return }
        queue.async {
            guard let defaults = defaults else { return }
            publishSounds(into: defaults)
        }
    }

    /// Everything written here, gone - when the account is signed out of.
    public static func clear() {
        // The chat list kept for a cold launch is the account's too.
        ChatListSnapshot.clear()
        guard let defaults = defaults else { return }
        deleteCredentials()
        for key in [enabledKey, personNamesKey, groupNamesKey, topicsKey, myPinKey, badgeKey,
                    announcedLocallyKey, announcedByPushKey, personAvatarsKey, groupAvatarsKey] {
            defaults.removeObject(forKey: key)
        }
        queue.async {
            removeAvatars()
            removeLists()
            if let folder = inboxFolder {
                try? FileManager.default.removeItem(at: folder)
            }
            if let delivered = container?.appendingPathComponent("Delivered", isDirectory: true) {
                try? FileManager.default.removeItem(at: delivered)
            }
            if let query = inboxKeyQuery() {
                SecItemDelete(query as CFDictionary)
            }
        }
    }

    // MARK: - Inbox: messages the extension pulled, saved here

    /// The messages the extension pulled for the notifications it showed, waiting to be saved: it
    /// has told the server they arrived (so the server stops pushing them and the sender sees them
    /// delivered), and keeps each one here - encrypted with a key only this app and the extension
    /// hold - until the app saves it into the database. Nothing is told "arrived" before it is in
    /// here, so nothing is lost between the two.
    private static var inboxFolder: URL? {
        return container?.appendingPathComponent("Inbox", isDirectory: true)
    }

    /// Whether anything is waiting in the inbox - a directory listing, cheap enough for every
    /// reload of the chat list.
    private static var observingInbox = false

    /// Fix: what the extension kept waited in the inbox until the app next came to the front, and
    /// the chat list then waited for it. The extension says when it has kept one, and a running app
    /// - in front, or not yet suspended behind - takes it into its database there and then; the
    /// list reloads itself once it is in (importInbox).
    static func observeInbox() {
        guard !observingInbox else { return }
        observingInbox = true
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, { _, _, _, _, _ in
            NotificationShare.importInbox()
        }, "io.nexilis.notification.inbox" as CFString, nil, .deliverImmediately)
    }

    public static var hasInbox: Bool {
        guard let folder = inboxFolder,
              let files = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else {
            return false
        }
        return files.contains { $0.hasSuffix(".msg") }
    }

    private static let importLock = NSLock()
    private static var isImporting = false
    private static var importWaiters: [() -> Void] = []
    private static var importRetriesLeft = 0

    /// Saves every message waiting in the inbox into the database, then calls `completion` on the
    /// main thread. Cheap when the inbox is empty, which is nearly always. A message that cannot be
    /// saved yet (the database not open) stays for the next time.
    public static func importInbox(completion: (() -> Void)? = nil) {
        func done() {
            if let completion = completion {
                DispatchQueue.main.async(execute: completion)
            }
        }
        guard let folder = inboxFolder,
              let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil),
              files.contains(where: { $0.pathExtension == "msg" }) else {
            done()
            return
        }
        importLock.lock()
        if isImporting {
            if let completion = completion {
                importWaiters.append(completion)
            }
            importLock.unlock()
            return
        }
        isImporting = true
        importLock.unlock()
        // Its own queue: on `queue` it waited behind refresh(), which enterForeground starts the
        // moment before - every name and picture in the app written out for the extension.
        importQueue.async {
            let key = readInboxKey()
            let messages = files.filter { $0.pathExtension == "msg" }
                .sorted { ($0.lastPathComponent) < ($1.lastPathComponent) }
            let began = Date()
            var readable: [(file: URL, packed: String, pushId: String)] = []
            for file in messages {
                guard let key = key, let sealed = try? Data(contentsOf: file),
                      let box = try? AES.GCM.SealedBox(combined: sealed),
                      let plain = try? AES.GCM.open(box, using: key),
                      let entry = (try? JSONSerialization.jsonObject(with: plain)) as? [String: String],
                      let packed = entry["packed"], !packed.isEmpty else {
                    // Unreadable - a key that changed, a file cut short. Nothing can be done with it.
                    try? FileManager.default.removeItem(at: file)
                    continue
                }
                readable.append((file, packed, entry["push_id"] ?? ""))
            }
            // All of them at once (see APIS.saveInboxMessages), not one after another.
            var saved = 0
            var failed = 0
            if !readable.isEmpty {
                let group = DispatchGroup()
                group.enter()
                APIS.saveInboxMessages(readable.map { (packed: $0.packed, pushId: $0.pushId) }) { results in
                    for (index, success) in results.enumerated() {
                        if success {
                            try? FileManager.default.removeItem(at: readable[index].file)
                            saved += 1
                        } else {
                            failed += 1
                        }
                    }
                    group.leave()
                }
                group.wait()
                noteFromApp("inbox \(readable.count): saved \(saved), failed \(failed) in \(Int(Date().timeIntervalSince(began) * 1000))ms")
            }
            if saved > 0 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                }
            }
            importLock.lock()
            isImporting = false
            let waiters = importWaiters
            importWaiters.removeAll()
            // The server has been told these arrived and will not send them again: one that could
            // not be saved yet (the database still closed) is tried again shortly, not left until
            // the app next comes to the front.
            if failed > 0 {
                if importRetriesLeft == 0 {
                    importRetriesLeft = 6
                }
                importRetriesLeft -= 1
                if importRetriesLeft > 0 {
                    importQueue.asyncAfter(deadline: .now() + 5) { importInbox() }
                }
            } else {
                importRetriesLeft = 0
            }
            importLock.unlock()
            done()
            for waiter in waiters {
                DispatchQueue.main.async(execute: waiter)
            }
        }
    }

    /// A message this app has just taken over its own connection, left for the extension under the
    /// push's delivery id (the message's header id, which the push carries as message_id).
    ///
    /// The push for a message also wakes the app, and the app - connected - can take the message and
    /// acknowledge it before the extension asks the server for it; the server then has nothing to
    /// give, and the notification said only "You got messages...". Sealed with the inbox key, bodies
    /// only (no media), and kept two days at most.
    public static func rememberDelivered(_ message: TMessage) {
        let deliveryId = message.mStatus
        guard !deliveryId.isEmpty, defaults?.bool(forKey: enabledKey) == true,
              let key = readInboxKey(), let container = container else { return }
        let folder = container.appendingPathComponent("Delivered", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        guard let plain = try? JSONSerialization.data(withJSONObject: ["bodies": message.mBodies]),
              let sealed = try? AES.GCM.seal(plain, using: key).combined else { return }
        try? sealed.write(to: folder.appendingPathComponent(safeName(deliveryId) + ".msg"),
                          options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        // Old copies go: nothing is pushed for a message two days on.
        if let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey]) {
            let cutoff = Date().addingTimeInterval(-2 * 24 * 3600)
            for file in files {
                let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
                if modified < cutoff {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
    }

    private static let inboxKeyAccount = "inbox"

    private static func inboxKeyQuery() -> [String: Any]? {
        guard let group = appGroup else { return nil }
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: inboxKeyAccount,
                kSecAttrAccessGroup as String: group]
    }

    private static func readInboxKey() -> SymmetricKey? {
        guard var query = inboxKeyQuery() else { return nil }
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data, data.count == 32 else { return nil }
        return SymmetricKey(data: data)
    }

    /// Made once and kept: the extension seals what it keeps with it, the app opens it.
    private static func ensureInboxKey() {
        guard readInboxKey() == nil, var query = inboxKeyQuery() else { return }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    // MARK: - Generic notifications, for the diagnostics

    /// Notes, in the extension's log, every bare "You got messages..." still in the tray - the push's
    /// id and when it came - so it can be matched against the extension's own lines: no "start" for
    /// that id means the system never ran the extension for it.
    public static func noteGenericNotifications() {
        guard let container = container else { return }
        UNUserNotificationCenter.current().getDeliveredNotifications { delivered in
            let lines = delivered.compactMap { genericLine($0, how: "in tray") }
            guard !lines.isEmpty else { return }
            appendToLog(lines, in: container)
        }
    }

    /// The same, for a bare "You got messages..." that was tapped - gone from the tray by the time
    /// the app looks there.
    public static func noteOpened(_ response: UNNotificationResponse) {
        guard let container = container, let line = genericLine(response.notification, how: "tapped") else { return }
        appendToLog([line], in: container)
    }

    /// A line about a notification that says no more than "You got messages..." - a push the
    /// extension did not word, or a banner of the app's own - nil for any other, or one noted before.
    private static func genericLine(_ note: UNNotification, how: String) -> String? {
        let content = note.request.content
        let info = content.userInfo
        let body = content.body
        guard info["nx_message_id"] == nil,
              body.hasPrefix("You got messages") || body.hasPrefix(NotificationText.generic) else { return nil }
        let isPush = info["aps"] != nil
        let pushId = info["message_id"] as? String ?? ""
        guard firstTime("generic|\(note.request.identifier)") else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date()) + (pushId.isEmpty ? "" : " …" + String(pushId.suffix(6)))
            + " generic \(how), came \(formatter.string(from: note.date))"
            + " \(isPush ? "push" : "local") code=\(info["nxc"] as? String ?? "-")"
            + " mutable=\((info["aps"] as? [String: Any])?["mutable-content"] as? Int ?? 0)"
            + " body=\"\(body.prefix(24))\""
    }

    /// A line from the app itself in the extension's log - "app" in front, so the two can be told
    /// apart: the app's own banner that fell back to "You got messages...", and why.
    public static func noteFromApp(_ line: String) {
        guard let container = container else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        appendToLog([formatter.string(from: Date()) + " app " + line], in: container)
    }

    private static let logLock = NSLock()

    private static func appendToLog(_ lines: [String], in container: URL) {
        logLock.lock()
        defer { logLock.unlock() }
        let folder = container.appendingPathComponent("Library/Diag", isDirectory: true)
        GroupPrefs.makeFolder(folder)
        let file = folder.appendingPathComponent("notif.log")
        let text = lines.joined(separator: "\n") + "\n"
        if let handle = FileHandle(forWritingAtPath: file.path) {
            handle.seekToEndOfFile()
            handle.write(Data(text.utf8))
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: file.path, contents: Data(text.utf8), attributes: GroupPrefs.protection)
        }
    }

    // MARK: - Pictures on the app's own banners

    /// The banner as a message from a person - the sender's picture in place of the app's icon,
    /// and for a group its name and picture - the way the Notification Service Extension words its
    /// notifications (INSendMessageIntent). The content as it was if that cannot be done.
    public static func asMessageFromPerson(_ content: UNMutableNotificationContent, senderPin: String, senderName: String,
                                           myPin: String, thread: String, groupTitle: String, groupId: String) -> UNNotificationContent {
        guard !senderPin.isEmpty else { return content }
        let picture = avatarData(list: "avatars-people", id: senderPin) ?? placeholderAvatar
        let sender = INPerson(personHandle: INPersonHandle(value: senderPin, type: .unknown), nameComponents: nil,
                              displayName: senderName.isEmpty ? nil : senderName,
                              image: INImage(imageData: picture), contactIdentifier: nil, customIdentifier: senderPin)
        var recipients: [INPerson]?
        var groupName: INSpeakableString?
        if !groupTitle.isEmpty {
            let me = INPerson(personHandle: INPersonHandle(value: myPin, type: .unknown), nameComponents: nil,
                              displayName: nil, image: nil, contactIdentifier: nil, customIdentifier: myPin, isMe: true)
            recipients = [me, sender]
            groupName = INSpeakableString(spokenPhrase: groupTitle)
        }
        let intent = INSendMessageIntent(recipients: recipients, outgoingMessageType: .outgoingMessageText,
                                         content: content.body, speakableGroupName: groupName,
                                         conversationIdentifier: thread, serviceName: nil, sender: sender, attachments: nil)
        if groupName != nil, let groupPicture = avatarData(list: "avatars-groups", id: groupId) {
            intent.setImage(INImage(imageData: groupPicture), forParameterNamed: \.speakableGroupName)
        }
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        interaction.donate { _ in }
        return (try? content.updating(from: intent)) ?? content
    }

    private static func avatarData(list: String, id: String) -> Data? {
        guard !id.isEmpty, let container = container,
              let file = (readList(named: list) as? [String: String])?[id] else { return nil }
        return try? Data(contentsOf: container.appendingPathComponent("Avatars/" + file))
    }

    /// A grey circle with a white silhouette - the picture of somebody who has none, as the
    /// extension draws it.
    private static let placeholderAvatar: Data = {
        let side: CGFloat = 192
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            UIColor(red: 0.75, green: 0.78, blue: 0.82, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
            let config = UIImage.SymbolConfiguration(pointSize: side * 0.62, weight: .regular)
            if let person = UIImage(systemName: "person.fill", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let size = person.size
                person.draw(in: CGRect(x: (side - size.width) / 2, y: side - size.height * 0.92,
                                       width: size.width, height: size.height))
            }
        }
        return image.pngData() ?? Data()
    }()

    // MARK: - Reply from the notification

    /// The category of a chat notification that can be answered from where it is, and its action.
    /// The extension and the app's own banners file chat notifications under it.
    public static let replyCategory = "nx.chat"
    public static let replyAction = "nx.reply"

    /// Where a reply to a notification goes, as the extension and the banners write it into the
    /// notification's userInfo: the conversation's l_pin, scope, chat_id and opposite_pin.
    public static func replyTarget(personal: Bool, senderPin: String, groupId: String, chatId: String) -> [String: String] {
        if personal {
            return ["nx_reply_lpin": senderPin, "nx_reply_scope": "3", "nx_reply_chat": "", "nx_reply_opposite": senderPin]
        }
        return ["nx_reply_lpin": groupId, "nx_reply_scope": "4", "nx_reply_chat": chatId,
                "nx_reply_opposite": chatId.isEmpty ? groupId : chatId]
    }

    /// Registers the Reply action - a text field on the notification, as WhatsApp's - keeping any
    /// category the host has registered itself.
    public static func registerReplyCategory() {
        let indonesian = (Locale.preferredLanguages.first ?? "").hasPrefix("id")
        let reply = UNTextInputNotificationAction(identifier: replyAction,
                                                  title: indonesian ? "Balas" : "Reply",
                                                  options: [],
                                                  textInputButtonTitle: indonesian ? "Kirim" : "Send",
                                                  textInputPlaceholder: "")
        let category = UNNotificationCategory(identifier: replyCategory, actions: [reply],
                                              intentIdentifiers: [], options: [])
        let center = UNUserNotificationCenter.current()
        center.getNotificationCategories { existing in
            var categories = existing.filter { $0.identifier != replyCategory }
            categories.insert(category)
            center.setNotificationCategories(categories)
        }
    }

    /// Sends what was typed into a notification's Reply field, the way the conversation sends a
    /// message: queued - and so kept in the database - and sent as soon as there is a
    /// connection. Says whether the response was a reply at all; `completion` is called either way
    /// once it has been dealt with.
    public static func handleReply(_ response: UNNotificationResponse, completion: @escaping () -> Void) -> Bool {
        guard response.actionIdentifier == replyAction,
              let typed = response as? UNTextInputNotificationResponse else {
            return false
        }
        let info = response.notification.request.content.userInfo
        func value(_ key: String) -> String { info[key] as? String ?? "" }
        let text = typed.userText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lPin = value("nx_reply_lpin")
        guard !text.isEmpty, !lPin.isEmpty else {
            completion()
            return true
        }
        var task: UIBackgroundTaskIdentifier = .invalid
        task = UIApplication.shared.beginBackgroundTask(withName: "nx.reply") {
            UIApplication.shared.endBackgroundTask(task)
            task = .invalid
        }
        DispatchQueue.global(qos: .userInitiated).async {
            Database.shared.ensureOpenForBackgroundWrite()
            let scope = value("nx_reply_scope").isEmpty ? MessageScope.WHISPER : value("nx_reply_scope")
            let message = CoreMessage_TMessageBank.sendMessage(
                l_pin: lPin, message_scope_id: scope, status: "1", message_text: text, credential: "0",
                attachment_flag: "0", ex_blog_id: "", message_large_text: "", ex_format: "",
                image_id: "", audio_id: "", video_id: "", file_id: "", thumb_id: "", reff_id: "",
                read_receipts: scope == MessageScope.WHISPER ? "4" : "", chat_id: value("nx_reply_chat"),
                is_call_center: "0", call_center_id: "", opposite_pin: value("nx_reply_opposite"), specFile: "")
            Nexilis.addQueueMessage(message: message)
            // A little time for the queue to hand it over while the app is awake; if there is no
            // connection yet it stays queued and goes with the next one.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                completion()
                if task != .invalid {
                    UIApplication.shared.endBackgroundTask(task)
                    task = .invalid
                }
            }
        }
        return true
    }

    // MARK: - Names

    private static func writeNames(into defaults: GroupPrefs) {
        guard !OfflinePolicy.isBlocking else { return }
        var people: [String: String] = [:]
        var groups: [String: String] = [:]
        var topics: [String: [String: String]] = [:]
        var peoplePictures: [String: String] = [:]
        var groupPictures: [String: String] = [:]
        Database.shared.database?.inTransaction({ (fmdb, _) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name, last_name, thumb_id FROM GROUPZ_MEMBER") {
                while cursor.next() {
                    let pin = cursor.string(forColumnIndex: 0) ?? ""
                    let name = "\(cursor.string(forColumnIndex: 1) ?? "") \(cursor.string(forColumnIndex: 2) ?? "")"
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !pin.isEmpty, !name.isEmpty {
                        people[pin] = name
                    }
                    let picture = cursor.string(forColumnIndex: 3) ?? ""
                    if !pin.isEmpty, !picture.isEmpty {
                        peoplePictures[pin] = picture
                    }
                }
                cursor.close()
            }
            // Contacts after group members: the name the reader saved somebody under wins.
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name, last_name, image_id FROM BUDDY") {
                while cursor.next() {
                    let pin = cursor.string(forColumnIndex: 0) ?? ""
                    let name = "\(cursor.string(forColumnIndex: 1) ?? "") \(cursor.string(forColumnIndex: 2) ?? "")"
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !pin.isEmpty, !name.isEmpty {
                        people[pin] = name
                    }
                    let picture = cursor.string(forColumnIndex: 3) ?? ""
                    if !pin.isEmpty, !picture.isEmpty {
                        peoplePictures[pin] = picture
                    }
                }
                cursor.close()
            }
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id, f_name, image_id FROM GROUPZ") {
                while cursor.next() {
                    let id = cursor.string(forColumnIndex: 0) ?? ""
                    if !id.isEmpty {
                        groups[id] = cursor.string(forColumnIndex: 1) ?? ""
                        let picture = cursor.string(forColumnIndex: 2) ?? ""
                        if !picture.isEmpty {
                            groupPictures[id] = picture
                        }
                    }
                }
                cursor.close()
            }
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT chat_id, title, group_id FROM DISCUSSION_FORUM") {
                while cursor.next() {
                    let id = cursor.string(forColumnIndex: 0) ?? ""
                    if !id.isEmpty {
                        topics[id] = ["title": cursor.string(forColumnIndex: 1) ?? "",
                                      "group": cursor.string(forColumnIndex: 2) ?? ""]
                    }
                }
                cursor.close()
            }
        })
        // Only written when the database answered: an empty read is no reason to forget names.
        if !people.isEmpty || !groups.isEmpty {
            // Fix: these lists sat in the shared defaults, and reading any one setting there loads
            // the whole of them - every member of every group - into the extension, whose memory is
            // a few megabytes: a picture on top of that and the system ended it mid-notification,
            // which then showed only "You got messages...". They are files of their own now, read
            // only when a notification needs a name.
            writeList(people, named: "people")
            writeList(groups, named: "groups")
            writeList(topics, named: "topics")
            writeList(exportAvatars(peoplePictures, folder: "people", known: readList(named: "avatars-people") as? [String: String] ?? [:]),
                      named: "avatars-people")
            writeList(exportAvatars(groupPictures, folder: "groups", known: readList(named: "avatars-groups") as? [String: String] ?? [:]),
                      named: "avatars-groups")
            for key in [personNamesKey, groupNamesKey, topicsKey, personAvatarsKey, groupAvatarsKey] {
                defaults.removeObject(forKey: key)
            }
        }
    }

    /// A list the extension reads (names, topics, pictures), as a binary property list in the
    /// group's Shared folder.
    private static func writeList(_ value: Any, named name: String) {
        guard let container = container,
              let data = try? PropertyListSerialization.data(fromPropertyList: value, format: .binary, options: 0) else { return }
        let folder = container.appendingPathComponent("Shared", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? data.write(to: folder.appendingPathComponent(name + ".plist"),
                        options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    private static func readList(named name: String) -> Any? {
        guard let container = container,
              let data = try? Data(contentsOf: container.appendingPathComponent("Shared/\(name).plist")) else { return nil }
        return try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    }

    private static func removeLists() {
        guard let container = container else { return }
        try? FileManager.default.removeItem(at: container.appendingPathComponent("Shared", isDirectory: true))
    }

    // MARK: - Pictures

    /// The pictures of people and groups, small, where the extension can read them: a
    /// notification shows the sender's face beside the message, as WhatsApp's do. Only pictures
    /// already on this phone are used - nothing is downloaded for this - and a picture is written
    /// once per version of it (its file is named after the picture it came from).
    ///
    /// Returns id -> file name (relative to the group's "Avatars" folder).
    private static func exportAvatars(_ pictures: [String: String], folder: String, known: [String: String]) -> [String: String] {
        guard let container = container else { return [:] }
        let directory = container.appendingPathComponent("Avatars/\(folder)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        var result: [String: String] = [:]
        var made = 0
        for (id, picture) in pictures {
            let fileName = "\(folder)/" + safeName(id) + "_" + safeName(picture) + ".jpg"
            let target = container.appendingPathComponent("Avatars/" + fileName)
            if known[id] == fileName, FileManager.default.fileExists(atPath: target.path) {
                result[id] = fileName
                continue
            }
            // A few hundred new pictures at most per refresh; the rest follow on the next one.
            guard made < 300 else { continue }
            var data: Data?
            if let documents = documents {
                let plain = documents.appendingPathComponent(picture)
                if FileManager.default.fileExists(atPath: plain.path) {
                    data = try? Data(contentsOf: plain)
                }
            }
            if data == nil, FileEncryption.shared.isSecureExists(filename: picture),
               var stored = try? FileEncryption.shared.readSecure(filename: picture, withoutBiometric: true) {
                if let plain = FileEncryption.shared.decryptFileFromServer(data: stored) {
                    stored = plain
                }
                data = stored
            }
            guard let data = data, let image = UIImage(data: data), let small = squared(image, side: 192),
                  let jpeg = small.jpegData(compressionQuality: 0.8) else {
                continue
            }
            if let old = known[id], old != fileName {
                try? FileManager.default.removeItem(at: container.appendingPathComponent("Avatars/" + old))
            }
            if (try? jpeg.write(to: target, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])) != nil {
                result[id] = fileName
                made += 1
            }
        }
        return result
    }

    private static func squared(_ image: UIImage, side: CGFloat) -> UIImage? {
        let size = CGSize(width: side, height: side)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let scale = max(side / max(image.size.width, 1), side / max(image.size.height, 1))
            let drawn = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            image.draw(in: CGRect(x: (side - drawn.width) / 2, y: (side - drawn.height) / 2,
                                  width: drawn.width, height: drawn.height))
        }
    }

    private static func safeName(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return String(text.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" })
    }

    private static func removeAvatars() {
        guard let container = container else { return }
        try? FileManager.default.removeItem(at: container.appendingPathComponent("Avatars", isDirectory: true))
    }

    // MARK: - Sounds

    /// The sound picked for personal or group chats, as a .caf in the group's Library/Sounds -
    /// where both this app's banners and the extension's can name it. A notification only plays
    /// linear PCM in .caf, .aiff or .wav; the picked sounds ship as .mp3, so they are converted.
    private static func publishSounds(into defaults: GroupPrefs) {
        for (settingKey, sharedKey) in [("newNotifSoundPersonal", soundPersonalKey), ("newNotifSoundGroup", soundGroupKey)] {
            let soundId: String = SecureUserDefaults.shared.value(forKey: settingKey) ?? "001:Nexilis Message (Default)"
            let resolved = APIS.notificationSoundName(for: soundId)
            if let file = cafSound(named: resolved.name, fromPref: resolved.fromPref) {
                defaults.set(file, forKey: sharedKey)
            } else {
                defaults.removeObject(forKey: sharedKey)
            }
        }
    }

    /// The file name of the .caf for this sound in the group's Library/Sounds, made if it is not
    /// there yet. Nil when the sound cannot be found or converted.
    public static func cafSound(named name: String, fromPref: Bool) -> String? {
        guard !name.isEmpty, let container = container else { return nil }
        let folder = container.appendingPathComponent("Library/Sounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let fileName = "nx_" + name.replacingOccurrences(of: "/", with: "_") + ".caf"
        let target = folder.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: target.path) {
            return fileName
        }
        guard let source = APIS.notificationSoundSource(name, fromPref) else { return nil }
        return convertToCaf(source, target) ? fileName : nil
    }

    private static func convertToCaf(_ source: URL, _ target: URL) -> Bool {
        do {
            let input = try AVAudioFile(forReading: source)
            let format = input.processingFormat
            var settings = input.fileFormat.settings
            settings[AVFormatIDKey] = kAudioFormatLinearPCM
            settings[AVLinearPCMBitDepthKey] = 16
            settings[AVLinearPCMIsFloatKey] = false
            settings[AVLinearPCMIsBigEndianKey] = false
            settings[AVLinearPCMIsNonInterleaved] = false
            let partial = target.appendingPathExtension("part")
            try? FileManager.default.removeItem(at: partial)
            let output = try AVAudioFile(forWriting: partial, settings: settings,
                                         commonFormat: format.commonFormat, interleaved: format.isInterleaved)
            // A notification sound may run thirty seconds at most.
            let limit = AVAudioFramePosition(format.sampleRate * 29)
            let chunk: AVAudioFrameCount = 8192
            while input.framePosition < min(input.length, limit) {
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunk) else { break }
                try input.read(into: buffer, frameCount: chunk)
                if buffer.frameLength == 0 { break }
                try output.write(from: buffer)
            }
            try? FileManager.default.removeItem(at: target)
            try FileManager.default.moveItem(at: partial, to: target)
            return true
        } catch {
            print("NotificationShare: sound conversion failed \(error.localizedDescription)")
            return false
        }
    }

    /// The .caf already made for this sound, for a banner the app puts up itself.
    public static func publishedSound(personal: Bool) -> String? {
        return defaults?.string(forKey: personal ? soundPersonalKey : soundGroupKey)
    }

    // MARK: - Badge

    /// The badge as the app has just set it, so the extension counts on from there.
    public static func noteBadge(_ value: Int) {
        defaults?.set(value, forKey: badgeKey)
    }

    public static var sharedBadge: Int {
        return defaults?.integer(forKey: badgeKey) ?? 0
    }

    // MARK: - Pins

    /// A server key the app has just verified against its pins - the extension accepts the same
    /// key for the same host, and no other.
    private static let rememberedLock = NSLock()
    private static var remembered = Set<String>()

    /// Whether this was already written in this launch - asked on every TLS handshake.
    private static func firstTime(_ key: String) -> Bool {
        rememberedLock.lock()
        defer { rememberedLock.unlock() }
        return remembered.insert(key).inserted
    }

    static func rememberVerifiedKey(host: String, hash: String) {
        guard let defaults = defaults, !host.isEmpty, !hash.isEmpty, firstTime("pin|\(host)|\(hash)") else { return }
        var pins = defaults.dictionary(forKey: pinsKey) as? [String: [String]] ?? [:]
        var known = pins[host] ?? []
        guard !known.contains(hash) else { return }
        known.append(hash)
        pins[host] = Array(known.suffix(12))
        defaults.set(pins, forKey: pinsKey)
    }

    /// Every certificate of a chain that has just passed the app's own pin check - the leaf and
    /// the CAs above it - as the extension may accept for this host. The app's policy matches its
    /// pins against any certificate of the chain, so one host can answer with different leaves
    /// (servers behind a balancer, a renewal); the extension, having only seen one of them, used
    /// to refuse the rest - and the picture never came.
    static func rememberVerifiedChain(host: String, trust: SecTrust) {
        for hash in spkiHashes(of: trust) {
            rememberVerifiedKey(host: host, hash: hash)
        }
    }

    private static let rsa2048: [UInt8] = [0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
                                           0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00]
    private static let rsa3072: [UInt8] = [0x30, 0x82, 0x01, 0xa2, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
                                           0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x8f, 0x00]
    private static let rsa4096: [UInt8] = [0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
                                           0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00]
    private static let ec256: [UInt8] = [0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
                                         0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00]
    private static let ec384: [UInt8] = [0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
                                         0x01, 0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00]

    /// The SubjectPublicKeyInfo SHA-256 (base64) of every certificate in a chain - the hash
    /// PinnedURLSessionNexilisDelegate computes for the leaf.
    static func spkiHashes(of trust: SecTrust) -> [String] {
        let chain = (SecTrustCopyCertificateChain(trust) as? [SecCertificate]) ?? []
        return chain.compactMap { certificate in
            guard let key = SecCertificateCopyKey(certificate),
                  let raw = SecKeyCopyExternalRepresentation(key, nil) as Data?,
                  let attributes = SecKeyCopyAttributes(key) as? [CFString: Any],
                  let type = attributes[kSecAttrKeyType] as? String,
                  let bits = attributes[kSecAttrKeySizeInBits] as? Int else { return nil }
            let header: [UInt8]?
            if type == (kSecAttrKeyTypeRSA as String) {
                header = bits == 2048 ? rsa2048 : bits == 3072 ? rsa3072 : bits == 4096 ? rsa4096 : nil
            } else if type == (kSecAttrKeyTypeECSECPrimeRandom as String) {
                header = bits == 256 ? ec256 : bits == 384 ? ec384 : nil
            } else {
                header = nil
            }
            guard let header = header else { return nil }
            var spki = Data(header)
            spki.append(raw)
            return Data(SHA256.hash(data: spki)).base64EncodedString()
        }
    }

    // MARK: - Data protection

    /// Run once per launch, on the queue.
    private static var protectionChecked = false

    /// What relaxProtection found, for the diagnostics ("notif"): A complete, B complete unless
    /// open, C until the first unlock, D none.
    private static var protectionReport = ""

    /// Fix (see GroupPrefs): what was written into the group's container without a protection of its
    /// own - the extension's log and lock, the sounds, the shared defaults - may have taken the app's
    /// "complete" one, and could not be read by the extension while the phone was locked. Made
    /// readable from the first unlock on.
    private static func relaxProtection() {
        guard !protectionChecked, let container = container, let group = appGroup else { return }
        protectionChecked = true
        func label(_ url: URL) -> String {
            guard let protection = (try? url.resourceValues(forKeys: [.fileProtectionKey]))?.fileProtection else {
                return "?"
            }
            switch protection {
            case URLFileProtection.complete: return "A"
            case URLFileProtection.completeUnlessOpen: return "B"
            case URLFileProtection.completeUntilFirstUserAuthentication: return "C"
            case URLFileProtection.none: return "D"
            default: return "?"
            }
        }
        let prefs = container.appendingPathComponent("Library/Preferences/\(group).plist")
        let before = "root=\(label(container)) prefs=\(label(prefs))"
        var found: [String: Int] = [:]
        var relaxed = 0
        var items = [container]
        if let enumerator = FileManager.default.enumerator(at: container, includingPropertiesForKeys: [.fileProtectionKey]) {
            while let url = enumerator.nextObject() as? URL {
                items.append(url)
            }
        }
        for url in items {
            let found1 = label(url)
            found[found1, default: 0] += 1
            if found1 == "A" || found1 == "B",
               (try? FileManager.default.setAttributes(GroupPrefs.protection, ofItemAtPath: url.path)) != nil {
                relaxed += 1
            }
        }
        protectionReport = "protection " + before + " "
            + found.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" }.joined(separator: " ")
            + " relaxed \(relaxed)"
    }

    // MARK: - Diagnostics

    /// What the extension noted about the last notifications it worked on - why a picture did not
    /// come, for one - newest last. Shown by the Version diagnostics box ("notif").
    public static var diagnostics: String {
        var lines = defaults?.stringArray(forKey: "nx.notif.diag") ?? []
        // The extension writes its notes to a file now (a process ended mid-way keeps what it wrote
        // up to then); the older notes in the defaults are only a fallback.
        // In Library/Diag since the log is made readable while the phone is locked (see GroupPrefs);
        // Diag/notif.log is where it was before.
        if let container = container,
           let text = (try? String(contentsOf: container.appendingPathComponent("Library/Diag/notif.log"), encoding: .utf8))
            ?? (try? String(contentsOf: container.appendingPathComponent("Diag/notif.log"), encoding: .utf8)) {
            lines = text.split(separator: "\n").map(String.init)
        }
        let enabled = defaults?.bool(forKey: enabledKey) ?? false
        let pins = (defaults?.dictionary(forKey: pinsKey) as? [String: [String]] ?? [:]).map { "\($0.key):\($0.value.count)" }
        let system = defaults?.stringArray(forKey: systemTrustKey) ?? []
        var head = "enabled=\(enabled) autodl=\(defaults?.object(forKey: autoDownloadKey) as? Bool ?? true)"
        head += "\npins " + pins.joined(separator: ", ") + (system.isEmpty ? "" : "\nsystem " + system.joined(separator: ", "))
        if !protectionReport.isEmpty {
            head += "\n" + protectionReport
        }
        return ([head] + lines.suffix(15)).joined(separator: "\n")
    }

    /// A host the app does not pin - the extension trusts the system for it, as the app does.
    static func rememberSystemTrust(host: String) {
        guard let defaults = defaults, !host.isEmpty, firstTime("system|\(host)") else { return }
        var hosts = defaults.stringArray(forKey: systemTrustKey) ?? []
        guard !hosts.contains(host) else { return }
        hosts.append(host)
        defaults.set(hosts, forKey: systemTrustKey)
    }

    // MARK: - Announced once

    /// The app has put a banner up for this message.
    static func markAnnouncedLocally(_ messageId: String) {
        append(messageId, to: announcedLocallyKey)
    }

    /// Whether the extension has already announced this message - the app's banner would be a
    /// second one.
    static func wasAnnouncedByPush(_ messageId: String) -> Bool {
        guard !messageId.isEmpty else { return false }
        return (defaults?.stringArray(forKey: announcedByPushKey) ?? []).contains(messageId)
    }

    private static func append(_ messageId: String, to key: String) {
        guard let defaults = defaults, !messageId.isEmpty else { return }
        var ids = defaults.stringArray(forKey: key) ?? []
        guard !ids.contains(messageId) else { return }
        ids.append(messageId)
        defaults.set(Array(ids.suffix(300)), forKey: key)
    }

    // MARK: - Keychain

    private static func keychainQuery() -> [String: Any]? {
        guard let group = appGroup else { return nil }
        return [kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: keychainAccount,
                kSecAttrAccessGroup as String: group]
    }

    private static func writeCredentials(_ credentials: [String: String]) {
        guard var query = keychainQuery(),
              let data = try? JSONSerialization.data(withJSONObject: credentials) else { return }
        let update: [String: Any] = [kSecValueData as String: data,
                                     kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        if SecItemUpdate(query as CFDictionary, update as CFDictionary) == errSecItemNotFound {
            query.merge(update) { $1 }
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    private static func deleteCredentials() {
        guard let query = keychainQuery() else { return }
        SecItemDelete(query as CFDictionary)
    }
}

/// What a chat notification says, the way WhatsApp says it - the text itself, or for an attachment
/// its icon and its caption ("📷 Photo" when there is none). The Notification Service Extension
/// carries its own copy of these rules (NotificationService.swift in the host); the two must say
/// the same thing.
public enum NotificationText {

    private static var indonesian: Bool {
        return (Locale.preferredLanguages.first ?? "").hasPrefix("id")
    }

    private static func say(_ english: String, _ bahasa: String) -> String {
        return indonesian ? bahasa : english
    }

    /// What is shown when the content may not be: a secret message, a mode that keeps content
    /// off the lock screen, or a message that could not be read.
    public static var generic: String {
        return say("You got messages...", "Anda mendapat pesan...")
    }

    /// The body for a message, from its bodies. `name` answers a pin with the name to show for it.
    public static func body(_ bodies: [String: String], name: (String) -> String?) -> String {
        func value(_ key: String) -> String { bodies[key] ?? "" }
        if value(CoreMessage_TMessageKey.IS_SECRET) == "1" {
            return generic
        }
        if value(CoreMessage_TMessageKey.CREDENTIAL) == "1" {
            return "🔒 " + say("Confidential message", "Pesan rahasia")
        }
        let raw = value(CoreMessage_TMessageKey.MESSAGE_TEXT)
        if raw.contains("Share%20location%20") || raw.contains("Share location ") {
            return "📍 " + say("Location", "Lokasi")
        }
        var text = raw.toNormalString()
        // What follows the black square is the app's own business, never shown.
        text = text.components(separatedBy: "\u{25A0}").first ?? ""
        let flag = value(CoreMessage_TMessageKey.ATTACHMENT_FLAG)
        let scope = value(CoreMessage_TMessageKey.MESSAGE_SCOPE_ID)
        let file = value(CoreMessage_TMessageKey.FILE_ID)
        let image = value(CoreMessage_TMessageKey.IMAGE_ID)
        let caption = readable(text, name: name)

        switch flag {
        case "11": return say("Sticker", "Stiker")
        case "24": return "📝 " + say("Quiz", "Kuis")
        case "25": return "📹 " + say("Video conference", "Konferensi video")
        case "26": return "🎓 Seminar"
        case "27": return "🔴 Live streaming"
        default: break
        }
        if scope == "18" {
            return "📄 " + say("Form", "Formulir")
        }
        if !value(CoreMessage_TMessageKey.AUDIO_ID).isEmpty {
            return "🎤 " + say("Voice message", "Pesan suara")
        }
        if !value(CoreMessage_TMessageKey.GIF_ID).isEmpty || image.lowercased().hasSuffix(".gif") {
            return caption.isEmpty ? "GIF" : "GIF " + caption
        }
        if !value(CoreMessage_TMessageKey.VIDEO_ID).isEmpty {
            return "🎥 " + (caption.isEmpty ? say("Video", "Video") : caption)
        }
        if !image.isEmpty {
            return "📷 " + (caption.isEmpty ? say("Photo", "Foto") : caption)
        }
        if !file.isEmpty {
            // A file message is "name|caption"; without the bar there is no name in the text.
            var fileName = ""
            if text.contains("|") {
                fileName = text.components(separatedBy: "|")[0].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if fileName.isEmpty {
                fileName = value(CoreMessage_TMessageKey.REAL_NAME_FILE_ID)
            }
            return "📄 " + (fileName.isEmpty ? say("Document", "Dokumen") : fileName)
        }
        return caption.isEmpty ? generic : caption
    }

    /// The text as it reads: mentions as names, without the formatting marks around words.
    static func readable(_ text: String, name: (String) -> String?) -> String {
        var result = text
        if result.contains("@"), let regex = try? NSRegularExpression(pattern: "@([\\w-]+)") {
            let written = NSMutableString(string: result)
            for match in regex.matches(in: result, range: NSRange(location: 0, length: written.length)).reversed() {
                let range = match.range(at: 1)
                if let shown = name(written.substring(with: range)), !shown.isEmpty {
                    written.replaceCharacters(in: range, with: shown)
                }
            }
            result = written as String
        }
        // *bold* _italic_ ~struck~ ^underlined^ - the words, without the marks.
        if let marks = try? NSRegularExpression(pattern: "([*_~^])(\\S(?:[^\\n]*?\\S)?)\\1") {
            result = marks.stringByReplacingMatches(in: result, range: NSRange(location: 0, length: (result as NSString).length),
                                                    withTemplate: "$2")
        }
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.count > 600 {
            result = String(result.prefix(600)) + "…"
        }
        return result
    }
}

// MARK: - Settings shared with the Notification Service Extension

/// What the app and the Notification Service Extension share, kept as files in the group's
/// Library/NotifState - one per setting - instead of the group's UserDefaults.
///
/// Fix: the group's UserDefaults (and files made without a protection of their own) can take the
/// app's data protection - "complete" in its provisioning profile: while the phone is locked the
/// extension then read nothing there - nor wrote its log - and the first push after the phone had
/// been locked a while came out as the server's "You got messages...", with no line in the log. These files are readable from the first unlock after a restart on, as the
/// keychain items beside them are. What only the UserDefaults still holds is read from there until
/// it is written again.
final class GroupPrefs {

    static let protection: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]

    let folder: URL
    private let legacy: UserDefaults?

    init?(group: String) {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            return nil
        }
        folder = container.appendingPathComponent("Library/NotifState", isDirectory: true)
        legacy = UserDefaults(suiteName: group)
    }

    /// A folder in the group's container, made readable while the phone is locked.
    static func makeFolder(_ url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: protection)
    }

    private func file(_ key: String) -> URL {
        return folder.appendingPathComponent(key + ".plist")
    }

    func object(forKey key: String) -> Any? {
        if let data = try? Data(contentsOf: file(key)),
           let box = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any] {
            return box["v"]
        }
        return legacy?.object(forKey: key)
    }

    func set(_ value: Any?, forKey key: String) {
        guard let value = value else {
            removeObject(forKey: key)
            return
        }
        GroupPrefs.makeFolder(folder)
        guard let data = try? PropertyListSerialization.data(fromPropertyList: ["v": value], format: .binary, options: 0),
              (try? data.write(to: file(key), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])) != nil else {
            return
        }
        if legacy?.object(forKey: key) != nil {
            legacy?.removeObject(forKey: key)
        }
    }

    func removeObject(forKey key: String) {
        try? FileManager.default.removeItem(at: file(key))
        legacy?.removeObject(forKey: key)
    }

    /// These settings, out of the UserDefaults and into their files, where only the UserDefaults
    /// still hold them.
    func migrate(_ keys: [String]) {
        for key in keys where !FileManager.default.fileExists(atPath: file(key).path) {
            if let value = legacy?.object(forKey: key) {
                set(value, forKey: key)
            }
        }
    }

    func bool(forKey key: String) -> Bool {
        return object(forKey: key) as? Bool ?? false
    }

    func integer(forKey key: String) -> Int {
        return object(forKey: key) as? Int ?? 0
    }

    func string(forKey key: String) -> String? {
        return object(forKey: key) as? String
    }

    func stringArray(forKey key: String) -> [String]? {
        return object(forKey: key) as? [String]
    }

    func dictionary(forKey key: String) -> [String: Any]? {
        return object(forKey: key) as? [String: Any]
    }
}
