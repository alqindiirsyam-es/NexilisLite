//
//  EditorGroup.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 20/09/21.
//

import UIKit
import AVKit
import AVFoundation
import QuickLook
import Photos
import NotificationBannerSwift
import nuSDKService
import SwiftLinkPreview
import SDWebImage
import PhotosUI

public class EditorGroup: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate, ChatBubbleContextMenuPresenting {
    @IBOutlet var wallpaperView: UIImageView!
    @IBOutlet var viewButton: UIView!
    @IBOutlet var constraintViewTextField: NSLayoutConstraint!
    @IBOutlet var buttonVoice: UIButton!
    @IBOutlet var buttonSendImage: UIButton!
    @IBOutlet var buttonSendPhoto: UIButton!
    @IBOutlet var buttonSendSticker: UIButton!
    @IBOutlet var buttonSendFile: UIButton!
    @IBOutlet var textFieldSend: CustomTextView!
    @IBOutlet var heightTextFieldSend: NSLayoutConstraint!
    @IBOutlet var buttonSendChat: UIButton!
    @IBOutlet var tableChatView: UITableView!
    @IBOutlet var constraintTopTextField: NSLayoutConstraint!
    @IBOutlet var constraintBottomAttachment: NSLayoutConstraint!
    @IBOutlet var viewTextfield: UIView!
    @IBOutlet weak var buttonAckConfidential: UIButton!
    @IBOutlet weak var constraintBottomTableViewWithTextfield: NSLayoutConstraint!
    @IBOutlet weak var viewAttachment: UIStackView!
    @IBOutlet weak var tableMention: UITableView!
    @IBOutlet weak var heightTableMention: NSLayoutConstraint!
    @IBOutlet weak var contraintBottomMention: NSLayoutConstraint!
    public var dataGroup: [String: Any?] = [:]
    public var dataTopic: [String: Any?] = [:]
    var dataMessages: [[String: Any?]] = []
    var dataDates: [String] = []

    /// The messages of one date section, grouped once instead of searched for over and over.
    ///
    /// Fix: every table-view callback used to filter the whole loaded conversation to find the
    /// rows belonging to its section - cellForRow, heightForRow, willDisplay, didSelect, each of
    /// them once per row. With a few hundred messages loaded that is tens of thousands of
    /// dictionary lookups and string comparisons to draw one screenful, and it is the largest
    /// single reason scrolling dragged on an older phone.
    ///
    /// What is kept is each section's *positions* in the list, not copies of the messages.
    ///
    /// Fix: copies were kept at first, and a message read through them was the message as it had
    /// been when the section was grouped. Ticking a bubble in multiple-select writes straight
    /// into the list and redraws that one row in the same breath - so the row was drawn from the
    /// copy taken a moment earlier and the tick did not move, while the "N Selected" count,
    /// which reads the list itself, did. The same went for a delivery mark arriving, or any
    /// other field changing under a row already on screen. Positions cost nothing to follow and
    /// always lead to the message as it is now.
    ///
    /// The positions themselves are kept only for the turn of the run loop that asked for them:
    /// a screenful is drawn within one turn, and anything that adds or removes a message happens
    /// in another. A message added or removed is caught straight away by the count no longer
    /// matching, so the rows and their number can never disagree.
    private var messageIndexesByDate: [String: [Int]]?
    private var messageIndexesByDateCount = -1

    func messages(onDate date: String) -> [[String: Any?]] {
        guard Thread.isMainThread else {
            // Off the main thread this is one of the loading paths, not the drawing path, and
            // what is kept here belongs to the main thread alone.
            return dataMessages.filter({ $0["chat_date"] as? String ?? "" == date })
        }
        if messageIndexesByDate == nil || messageIndexesByDateCount != dataMessages.count {
            var grouped: [String: [Int]] = [:]
            for (index, message) in dataMessages.enumerated() {
                grouped[message["chat_date"] as? String ?? "", default: []].append(index)
            }
            messageIndexesByDate = grouped
            messageIndexesByDateCount = dataMessages.count
            DispatchQueue.main.async { [weak self] in
                self?.messageIndexesByDate = nil
            }
        }
        guard let indexes = messageIndexesByDate?[date] else {
            return []
        }
        return indexes.compactMap { $0 < dataMessages.count ? dataMessages[$0] : nil }
    }

    public var dataMessageForward: [[String: Any?]]?
    /// A picture to open as soon as this conversation has finished loading.
    public var openMediaOnceLoaded = ""
    /// A message to scroll to as soon as this conversation has finished loading.
    public var goToMessageOnceLoaded = ""
    /// True when this conversation is only loaded to answer for another screen and is never shown.
    public var isBackgroundHelper = false
    /// Asked, when this conversation is only a helper, to put a real one on screen at a message.
    public var onNeedsRealConversation: ((String) -> Void)?
    var imageVideoPicker: ImageVideoPicker!
    var documentPicker: DocumentPicker!
    var currentIndexpath: IndexPath?
    var previewItem: NSURL?
    var reffId: String?
    var stickers = [String]()
    public var unique_l_pin = ""
    public var fromNotification = false
    public var referenceMessageId = ""
    public var referenceChatDate = ""
    var isHistoryCC = false
    var complaintId = ""
    var counter = 0
    var markerCounter: String?

    // MARK: - Paging
    //
    // Opening a group used to read every message it ever had (the query said LIMIT -1) on the
    // main thread, then ask the table to scroll to the last row - which forces a height
    // measurement of every row above it. In a busy group that is seconds of frozen UI, which
    // is why the table used to be faded in from alpha 0 after a delay: the freeze was hidden
    // rather than fixed. Now only the newest slice is read, and older messages arrive when the
    // user scrolls up to them.
    private static let initialMessagePageSize: Int64 = 50
    // Deliberately generous. Putting older messages in costs a contentOffset assignment, and
    // that assignment ends whatever deceleration the scroll is running on - so the cure is to
    // reach the end of the loaded messages as rarely as possible, not to make the trip there
    // cheaper.
    private static let olderMessagePageSize: Int64 = 100
    /// Database offset of the oldest message currently loaded.
    private var loadedOffset: Int64 = 0
    /// How many database rows the loaded window covers. Not the same as dataMessages.count -
    /// grouped image collages take several rows out of the list.
    private var loadedCount: Int64 = 0
    private var isLoadingOlderMessages = false
    private var isLoadingNewerMessages = false
    /// When a page of older messages last came back with nothing in it. Deleted messages can
    /// shift offsets enough for that to happen, and without a pause the triggers below would
    /// ask again on the very next frame.
    private var lastEmptyOlderPage: Date?
    /// Message ids matching the current in-chat search, newest first.
    ///
    /// Read from the database rather than by sifting through what is loaded, so searching
    /// reaches the whole conversation without the screen having to hold it. Jumping to a hit
    /// pulls in what it needs, exactly like tapping a quoted message does.
    private var searchMatchIds: [String] = []
    /// Whether the loaded window reaches the newest message of the conversation.
    ///
    /// Normally it does: the chat opens at the end and only grows upwards. Jumping to a much
    /// older message moves the window off the end, and until the reader comes back the screen
    /// must not treat what it shows as the end of the chat - a message arriving then would be
    /// drawn directly underneath one from months ago.
    private var isWindowAtNewest = true
    /// How many messages a jump reads around its target.
    private static let jumpWindowSize: Int64 = 60
    /// A target closer than this to the window is reached by reading everything in between,
    /// which keeps the window in one piece. Further away, reading the gap would mean
    /// thousands of messages, so the window is moved instead.
    private static let maxBridgedMessages: Int64 = 200
    /// Set while the first page is being put on screen, so the scroll driven work (new-message
    /// checks, the scroll-to-bottom button) stays quiet until the chat is settled. This is what
    /// the old `tableChatView.alpha != 1` checks were really asking.
    private var isInitialLoading = true
    /// The chat opens at its newest message; this makes sure that is true of the first frame
    /// the table lays out, not just of the moment after it.
    private var pendingInitialScrollToBottom = false
    /// The first unread message, while the chat is still being placed at it.
    private var pendingUnreadMarkerScroll: String?
    private var remainingUnreadMarkerScrollPasses = 0
    /// Enough layout passes for the estimated row heights above the marker to be replaced by
    /// measured ones, and few enough that a conversation that will not settle gives up rather
    /// than re-scrolling under the reader's finger.
    private static let unreadMarkerScrollPasses = 8
    /// Measured row heights, keyed by message id, so the table estimates with real numbers
    /// instead of guessing - which is what keeps the scroll position steady when older
    /// messages are inserted above.
    private var measuredRowHeights: [String: CGFloat] = [:]
    var buttonScrollToBottom = UIButton()
    let indicatorCounterBSTB = UIView()
    let labelCounter = UILabel()
    let containerActionGroup = UIView()
    var removed = false
    var isConfidential = false
    var isAck = false
    var copySession = false
    var forwardSession = false
    var deleteSession = false
    var summarizeSession = false
    var isSearching = false
    let containerMultpileSelectSession = UIView()
    let viewSticker = UIView()
    let containerLink = UIView()
    let containerPreviewReply = UIView()
    let containerPin = UIView()
    let textPin = UILabel()
    let signSelectedPin = UIStackView()
    var bottomAnchorPreviewReply = NSLayoutConstraint()
    let containerAction = UIView()
    var allowTyping = true
    let contactChatNav = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
    var searchBar: UISearchBar!
    var constraintBottomContainerMultpileSelectSession = NSLayoutConstraint()
    var titleSearchMatches: UILabel!
    var textSearch = ""
    var countMatchesSearch = 0
    var lastScrollIdxSearch = 0
    var nextPinShowed = 0
    var buttonUp: UIButton!
    var buttonDown: UIButton!
    var keyboardHeightForMention: CGFloat?
    var listMentionWithText:[User] = []
    var listMentionInTextField:[User] = []
    var tempListMentionWithText:[User] = []
    var tempListMentionInTextField:[User] = []
    var showingLink = ""
    var isAlwaysHideLinkPreview = false
    var timerCheckLink: Timer?
    var lastPositionCursorMention = 0
    var lastTextLength = 0
    var timerFakeProgress: Timer?
    var showMenuContext = false
    var touchedSubview = UIView()
    var listViewOnSection: [UIView] = []
    var fakeProgMultip = 0
    let maxFakeProgMultip = 2
    var groupImages: [String:[ImageGrouping]] = [:]


    /// The size a picture's bubble was first given, kept so it never changes afterwards.
    ///
    /// Fix: a picture not yet downloaded was measured as a placeholder, and the moment its
    /// thumbnail arrived the bubble was measured again against the real thing. The row changed
    /// height and everything below it slid down - the drop the reader sees. What is reserved for
    /// a picture is decided once now and held: the thumbnail, when it comes, fills exactly the
    /// space that was already being kept for it, so the only thing that changes on screen is the
    /// picture appearing. Reopening the chat starts afresh, by which time the file is there and
    /// its real proportions are used from the start.
    private var imageBubbleSizes: [String: CGSize] = [:]

    func imageBubbleSize(messageId: String, thumb: String) -> CGSize {
        if let known = imageBubbleSizes[messageId] {
            return known
        }
        let size = ListGroupImages.getImageSize(image: thumb, screenWidth: self.view.frame.size.width * 0.6, screenHeight: 305)
        if !messageId.isEmpty {
            imageBubbleSizes[messageId] = size
        }
        return size
    }


    /// Joins a run of pictures that a page boundary split in two.
    ///
    /// Fix: pictures are gathered into a collage while a page of messages is being read, and
    /// every page starts with nothing in hand - so a run that happened to straddle the boundary
    /// between two pages was always broken, leaving one picture on its own directly above a
    /// collage of the rest, for no reason the reader can see. Once the two pages are side by
    /// side the seam between them is looked at again, and the halves are joined if they were one
    /// run all along.
    private func mergeImageRunAcrossSeam(at seam: Int) {
        guard seam > 0, seam < dataMessages.count else {
            return
        }
        let above = dataMessages[seam - 1]
        let below = dataMessages[seam]
        let aboveId = above["message_id"] as? String ?? ""
        let belowId = below["message_id"] as? String ?? ""
        guard !aboveId.isEmpty, !belowId.isEmpty else {
            return
        }
        // Each side is either a collage already, or a lone picture that could begin one.
        let aboveRun: [ImageGrouping]
        if let existing = groupImages[aboveId] {
            aboveRun = existing
        } else if isCollageCandidate(above) {
            aboveRun = [imageGrouping(from: above)]
        } else {
            return
        }
        let belowRun: [ImageGrouping]
        if let existing = groupImages[belowId] {
            belowRun = existing
        } else if isCollageCandidate(below) {
            belowRun = [imageGrouping(from: below)]
        } else {
            return
        }
        guard let last = aboveRun.last, let first = belowRun.first,
              (last.dataMessage["f_pin"] as? String ?? "") == (first.dataMessage["f_pin"] as? String ?? ""),
              (above["chat_date"] as? String ?? "") == (below["chat_date"] as? String ?? ""),
              aboveRun.count + belowRun.count <= EditorGroup.maximumImagesInCollage else {
            return
        }
        let minutesApart = getSecondsDifferenceFromTwoDates(
            start: Date(milliseconds: Int64(last.time) ?? 0),
            end: Date(milliseconds: Int64(first.time) ?? 0)) / 60
        guard minutesApart < 11 else {
            return
        }
        groupImages[belowId] = nil
        groupImages[aboveId] = aboveRun + belowRun
        dataMessages.remove(at: seam)
    }



    // MARK: - Media viewer

    /// Every picture and video of this conversation, in the order they were sent, for the strip
    /// along the foot of the viewer.
    ///
    /// A collage is one row standing for several messages, so its members are unfolded here -
    /// the strip is about the pictures, not about how they happen to be grouped in the list.
    func conversationMediaStrip() -> [MediaViewerViewController.StripItem] {
        var entries: [(date: Double, order: Int, item: MediaViewerViewController.StripItem)] = []
        var seen = Set<String>()
        // Carried forward so a row whose date will not parse keeps the place it had in the list
        // rather than being flung to one end by the sort below.
        var lastDate: Double = 0
        for message in dataMessages {
            let rowId = message["message_id"] as? String ?? ""
            let rows = groupImages[rowId]?.map { $0.dataMessage } ?? [message]
            for row in rows {
                let messageId = row["message_id"] as? String ?? ""
                let thumb = row["thumb_id"] as? String ?? ""
                let isVideo = !(row["video_id"] as? String ?? "").isEmpty
                let hasPicture = isVideo || !(row["image_id"] as? String ?? "").isEmpty
                guard !messageId.isEmpty, !thumb.isEmpty, hasPicture, !seen.contains(messageId) else {
                    continue
                }
                // A message taken back, or one that only opens once, is not part of the run.
                guard (row["lock"] as? String ?? "") != "1", (row["credential"] as? String ?? "") != "1" else {
                    continue
                }
                seen.insert(messageId)
                let profile = getDataProfile(f_pin: row["f_pin"] as? String ?? "", message_id: messageId)
                var when = ""
                let timestamp = Double(row[TypeDataMessage.server_date] as? String ?? "")
                if let timestamp = timestamp {
                    when = DateFormatterPool.shared.string(from: Date(timeIntervalSince1970: timestamp / 1000), format: "dd/MM/yy HH:mm")
                }
                lastDate = timestamp ?? lastDate
                entries.append((lastDate, entries.count, MediaViewerViewController.StripItem(
                    messageId: messageId,
                    thumbFileName: thumb,
                    mediaFileName: isVideo ? (row["video_id"] as? String ?? "") : (row["image_id"] as? String ?? ""),
                    isVideo: isVideo,
                    caption: row["message_text"] as? String ?? "",
                    title: profile["name"] ?? "",
                    subtitle: when,
                    isStarred: (row["is_stared"] as? String ?? "0") == "1")))
            }
        }

        appendMediaOutsideWindow(to: &entries, seen: &seen)

        // The two runs have to be woven together by date, not simply joined: the window is not
        // always sitting at the newest end of the conversation - opening a message from search
        // leaves it in the middle - so what is missing can be on either side of it.
        return entries
            .sorted { $0.date == $1.date ? $0.order < $1.order : $0.date < $1.date }
            .map { $0.item }
    }

    /// Full rows for media the window in memory does not hold, so the viewer's caption, star,
    /// forward and delete still have a message to work with once the strip reaches past the page.
    private var mediaRowsOutsideWindowStorage: [String: [String: Any?]] = [:]

    /// Adds the conversation's media that pagination has left out of memory.
    ///
    /// Fix: the strip was built from `dataMessages` alone, which is a window on the conversation
    /// rather than the whole of it - so a viewer opened straight after the conversation showed a
    /// handful of pictures, and the same viewer opened after scrolling up showed far more. Reading
    /// every message back in would answer it, but it would also undo the paging that keeps this
    /// screen quick on an older phone. Only the media rows are wanted, and there are far fewer of
    /// those than there are messages, so they are read on their own.
    /// Every message of this conversation matching an extra condition, whatever page it lives on.
    ///
    /// Pagination means `dataMessages` is only a window on the conversation, so anything that has
    /// to speak for the whole of it - the strip under a picture, the media browser - cannot be
    /// built from memory alone. Reading every message back in would answer it and undo the paging
    /// that keeps this screen quick on an older phone; this reads only the rows that qualify.
    func messageRows(matching condition: String) -> [[String: Any?]] {
        var rows: [[String: Any?]] = []
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            let query = """
                SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, \
                audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, \
                attachment_flag, reff_id, lock, is_stared, blog_id, credential, is_call_center, \
                call_center_id, opposite_pin, last_edited, gif_id, is_forwarded_message, \
                attachment_speciality, is_pinned FROM MESSAGE \
                where \(self.messageWhereClause()) AND \(condition) \
                AND (lock IS NULL OR lock <> '1') AND (credential IS NULL OR credential <> '1') \
                order by server_date asc
                """
            guard let cursor = Database.shared.getRecords(fmdb: fmdb, query: query) else {
                return
            }
            while cursor.next() {
                let messageId = cursor.string(forColumnIndex: 0) ?? ""
                if messageId.isEmpty {
                    continue
                }
                var row: [String: Any?] = [:]
                row["message_id"] = messageId
                row["f_pin"] = cursor.string(forColumnIndex: 1)
                row["l_pin"] = cursor.string(forColumnIndex: 2)
                row["message_scope_id"] = cursor.string(forColumnIndex: 3)
                row["server_date"] = cursor.string(forColumnIndex: 4)
                row["status"] = cursor.string(forColumnIndex: 5)
                row["message_text"] = cursor.string(forColumnIndex: 6)
                row["audio_id"] = cursor.string(forColumnIndex: 7)
                row["video_id"] = cursor.string(forColumnIndex: 8)
                row["image_id"] = cursor.string(forColumnIndex: 9)
                row["thumb_id"] = cursor.string(forColumnIndex: 10)
                row["read_receipts"] = cursor.string(forColumnIndex: 11)
                row["chat_id"] = cursor.string(forColumnIndex: 12)
                row["file_id"] = cursor.string(forColumnIndex: 13)
                row["attachment_flag"] = cursor.string(forColumnIndex: 14)
                row["reff_id"] = cursor.string(forColumnIndex: 15)
                row["lock"] = cursor.string(forColumnIndex: 16)
                row["is_stared"] = cursor.string(forColumnIndex: 17)
                row["blog_id"] = cursor.string(forColumnIndex: 18)
                row["credential"] = cursor.string(forColumnIndex: 19)
                row[TypeDataMessage.is_call_center] = cursor.string(forColumnIndex: 20)
                row[TypeDataMessage.call_center_id] = cursor.string(forColumnIndex: 21)
                row[TypeDataMessage.opposite_pin] = cursor.string(forColumnIndex: 22)
                row[TypeDataMessage.last_edit] = cursor.longLongInt(forColumnIndex: 23)
                row[TypeDataMessage.gif_id] = cursor.string(forColumnIndex: 24)
                row[TypeDataMessage.is_forwarded] = Int(cursor.int(forColumnIndex: 25))
                row[TypeDataMessage.spec_file] = cursor.string(forColumnIndex: 26)
                row[TypeDataMessage.is_pinned] = cursor.string(forColumnIndex: 27)
                row["progress"] = 0.0
                row["isSelected"] = false
                rows.append(row)
            }
            cursor.close()
        })
        return rows
    }

    /// How long each video of this conversation runs, for the grid to label them with.
    ///
    /// One small query rather than a column added to the message loader: the loader maps its
    /// columns by position, and threading another one through it to reach a label is a poor trade.
    func videoDurations() -> [String: Int] {
        var found: [String: Int] = [:]
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            let query = "SELECT message_id, video_duration FROM MESSAGE where \(self.messageWhereClause()) AND video_duration > 0"
            guard let cursor = Database.shared.getRecords(fmdb: fmdb, query: query) else {
                return
            }
            while cursor.next() {
                let messageId = cursor.string(forColumnIndex: 0) ?? ""
                if !messageId.isEmpty {
                    found[messageId] = Int(cursor.int(forColumnIndex: 1))
                }
            }
            cursor.close()
        })
        return found
    }

    /// The documents and the links of this conversation, for the browser's other two tabs.
    ///
    /// Read on the same terms as the pictures: whole conversation, not the page in memory. The
    /// rows are kept as well as the summaries, so following one back to its message - or
    /// forwarding it, or deleting it - does not need a second trip to the database.
    func conversationDocsAndLinks() -> (docs: [MediaBrowserViewController.DocItem], links: [MediaBrowserViewController.LinkItem]) {
        let rows = messageRows(matching: "((file_id IS NOT NULL AND file_id <> '') "
                               + "OR (message_text LIKE '%http://%' OR message_text LIKE '%https://%'))")
        var docs: [MediaBrowserViewController.DocItem] = []
        var links: [MediaBrowserViewController.LinkItem] = []
        for row in rows {
            let messageId = row["message_id"] as? String ?? ""
            mediaRowsOutsideWindowStorage[messageId] = row
            let when = Double(row["server_date"] as? String ?? "") ?? 0
            let text = row["message_text"] as? String ?? ""
            let file = row["file_id"] as? String ?? ""
            if !file.isEmpty {
                // A file message carries its own name, size and kind in the text, separated by
                // bars - the same reading the bubble in the conversation does.
                let parts = text.components(separatedBy: "|")
                docs.append(MediaBrowserViewController.DocItem(messageId: messageId,
                                                              fileName: parts.first ?? file,
                                                              storedName: file,
                                                              detail: parts.count > 1 ? parts[1] : "",
                                                              date: when))
            } else if let url = MediaBrowserViewController.firstLink(in: text) {
                links.append(MediaBrowserViewController.LinkItem(messageId: messageId,
                                                                 url: url,
                                                                 caption: text,
                                                                 thumbFileName: row["thumb_id"] as? String ?? "",
                                                                 date: when))
            }
        }
        return (docs, links)
    }

    private func appendMediaOutsideWindow(to entries: inout [(date: Double, order: Int, item: MediaViewerViewController.StripItem)],
                                          seen: inout Set<String>) {
        guard hasOlderMessages else {
            return
        }
        // Pictures and video: anything carrying a thumbnail and something to open behind it.
        let rows = messageRows(matching: "thumb_id IS NOT NULL AND thumb_id <> '' "
                               + "AND ((image_id IS NOT NULL AND image_id <> '') "
                               + "OR (video_id IS NOT NULL AND video_id <> ''))")
            .filter { !seen.contains($0["message_id"] as? String ?? "") }
        for row in rows {
            seen.insert(row["message_id"] as? String ?? "")
        }

        // Names are resolved out here on purpose. `getDataProfile` opens a transaction of its own,
        // and the database is a serial queue - asking for one from inside the block above would
        // have it waiting on itself.
        var profiles: [String: [String: String]] = [:]
        for row in rows {
            let messageId = row["message_id"] as? String ?? ""
            let fPin = row["f_pin"] as? String ?? ""
            let profile: [String: String]
            if let known = profiles[fPin], !fPin.isEmpty {
                profile = known
            } else {
                profile = getDataProfile(f_pin: fPin, message_id: messageId)
                if !fPin.isEmpty {
                    profiles[fPin] = profile
                }
            }
            let isVideo = !(row["video_id"] as? String ?? "").isEmpty
            var when = ""
            let timestamp = Double(row["server_date"] as? String ?? "")
            if let timestamp = timestamp {
                when = DateFormatterPool.shared.string(from: Date(timeIntervalSince1970: timestamp / 1000), format: "dd/MM/yy HH:mm")
            }
            mediaRowsOutsideWindowStorage[messageId] = row
            entries.append((timestamp ?? 0, entries.count, MediaViewerViewController.StripItem(
                messageId: messageId,
                thumbFileName: row["thumb_id"] as? String ?? "",
                mediaFileName: isVideo ? (row["video_id"] as? String ?? "") : (row["image_id"] as? String ?? ""),
                isVideo: isVideo,
                caption: row["message_text"] as? String ?? "",
                title: profile["name"] ?? "",
                subtitle: when,
                isStarred: (row["is_stared"] as? String ?? "0") == "1")))
        }
    }

    /// Opens the list of everything sent in this conversation, at the picture being looked at.
    ///
    /// The same screen a collage opens - the pictures of a whole conversation are the same kind
    /// of thing as the pictures of one collage, so there is no reason for a second one.
    /// Opens the picture viewer on one message, wherever the browser found it.
    ///
    /// The tap handler this hands off to works from the conversation's own list, so the message
    /// has to be on a loaded page before it can be pointed at - the browser reaches past the page
    /// in memory, and a picture from years back would otherwise have no row to open.
    /// Brings this conversation to the front and shows one of its messages.
    ///
    /// Three cases: it is already what the reader is looking at, it is somewhere below in the
    /// stack, or it is not on screen at all - which is what a profile keeps, a conversation loaded
    /// behind a browser purely to answer for it. Only the last one needs a conversation opened.
    /// Scrolls to a message and flashes it, the way arriving from a search does.
    ///
    /// The same thing `referenceMessageId` does when this screen is opened fresh - but this one
    /// works on a conversation already loaded, where that has long since been read.
    func highlightMessage(_ messageId: String) {
        _ = ensureMessageLoaded(messageId: messageId)
        guard let indexPath = indexPath(forMessageId: messageId) else {
            return
        }
        tableChatView.safeScrollToRow(at: indexPath, at: .middle, animated: false)
        tableChatView.cellForRow(at: indexPath)?.contentView.backgroundColor = .yellow
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.tableChatView.cellForRow(at: indexPath)?.contentView.backgroundColor = .clear
        }
    }

    func reveal(messageId: String, from presenter: UIViewController?) {
        // Fix: a conversation kept behind a browser is the root of a navigation controller of its
        // own, so "am I in my own stack" was true and it took the first branch - popping nothing
        // and scrolling a table nobody could see. Being a helper is not something that can be
        // worked out from the hierarchy, so it is said outright.
        if !isBackgroundHelper, let stack = navigationController, stack.viewControllers.contains(self) {
            guard stack.topViewController !== self else {
                highlightMessage(messageId)
                return
            }
            // Fix: the scroll used to be asked for while the pop was still running, and the two
            // fought over the table - which is why it landed near the message rather than on it.
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                self?.highlightMessage(messageId)
            }
            stack.popToViewController(self, animated: true)
            CATransaction.commit()
            return
        }
        // Whoever keeps this conversation behind their screen decides how to hand over to a real
        // one - they are the ones who know what of theirs should be left behind.
        if let handOver = onNeedsRealConversation {
            handOver(messageId)
            return
        }
        guard let stack = presenter?.navigationController else {
            return
        }
        let fresh = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
        fresh.unique_l_pin = unique_l_pin
        fresh.hidesBottomBarWhenPushed = true
        // The same field a search result sets: the conversation scrolls to it while it loads
        // and flashes the bubble, rather than jumping there afterwards.
        fresh.referenceMessageId = messageId
        stack.pushViewController(fresh, animated: true)
    }

    func openMedia(messageId: String, from presenter: UIViewController? = nil, origin: UIImageView? = nil) {
        // Only when nobody else is showing it. Opened from a collage the viewer goes up over that
        // screen, so closing it lands back on the collage rather than skipping past it.
        if presenter == nil {
            navigationController?.popViewController(animated: false)
        }
        _ = ensureMessageLoaded(messageId: messageId)
        guard let indexPath = indexPath(forMessageId: messageId),
              let row = messageForMedia(messageId: messageId) else {
            return
        }
        let gesture = ObjectGesture()
        gesture.indexPath = indexPath
        gesture.message_id = messageId
        gesture.image_id = row["image_id"] as? String ?? ""
        gesture.video_id = row["video_id"] as? String ?? ""
        gesture.gif_id = row[TypeDataMessage.gif_id] as? String ?? ""
        gesture.file_id = row["file_id"] as? String ?? ""
        gesture.specFile = row[TypeDataMessage.spec_file] as? String ?? ""
        gesture.isInitiator = (row["f_pin"] as? String) == User.getMyPin()
        gesture.presenter = presenter
        if let origin = origin {
            gesture.imageView = origin
        } else if let cell = tableChatView.cellForRow(at: indexPath),
                  let thumbnail = Self.firstImageView(in: cell.contentView) {
            gesture.imageView = thumbnail
        }
        contentMessageTapped(gesture)
    }

    func showAllMedia(startingAt messageId: String, in stack: UINavigationController? = nil, returningTo viewer: MediaViewerViewController? = nil) {
        let browser = MediaBrowserViewController()
        let durations = videoDurations()
        browser.media = conversationMediaStrip().map {
            MediaBrowserViewController.MediaItem(messageId: $0.messageId,
                                                 thumbFileName: $0.thumbFileName,
                                                 mediaFileName: $0.mediaFileName,
                                                 isVideo: $0.isVideo,
                                                 durationSeconds: durations[$0.messageId] ?? 0,
                                                 date: Double(messageForMedia(messageId: $0.messageId)?["server_date"] as? String ?? "") ?? 0)
        }
        let other = conversationDocsAndLinks()
        browser.docs = other.docs
        browser.links = other.links
        browser.conversationName = titleText ?? ""
        browser.onOpenMedia = { [weak self, weak viewer, weak stack] shown in
            // Opened from the picture viewer, so a picture chosen here goes back to it rather
            // than dropping the reader into the conversation.
            if let viewer = viewer, let stack = stack {
                viewer.show(messageId: shown)
                stack.popViewController(animated: true)
                return
            }
            self?.openMedia(messageId: shown)
        }
        browser.onGoToMessage = { [weak self] shown in
            guard let self = self else {
                return
            }
            // The conversation is behind everything the viewer put up, so it is that whole stack
            // that has to come down before the message can be shown.
            if stack != nil {
                self.dismiss(animated: true) {
                    self.goToMessage(messageId: shown)
                }
            } else {
                self.navigationController?.popViewController(animated: true)
                self.goToMessage(messageId: shown)
            }
        }
        // The browser has no idea what forwarding or deleting means; it only knows what was
        // ticked. Both are handed back to the conversation, which already owns the rules.
        browser.onForward = { [weak self] ids in
            guard let self = self else {
                return
            }
            let rows = ids.compactMap { self.messageForMedia(messageId: $0) }
            self.presentForwardChooser(for: rows, from: browser)
        }
        browser.onDelete = { [weak self] ids in
            guard let self = self else {
                return
            }
            let rows = ids.compactMap { self.messageForMedia(messageId: $0) }
            self.presentDeleteOptions(for: rows, from: browser)
        }
        browser.focusMessageId = messageId
        if let stack = stack, let viewer = viewer {
            // Held on the browser so it lives as long as the two screens do - a navigation
            // controller does not keep its delegate.
            let zoom = MediaGridTransitionDelegate(viewer: viewer, browser: browser)
            browser.transitionKeeper = zoom
            stack.delegate = zoom
        }
        (stack ?? navigationController)?.pushViewController(browser, animated: true)
    }

    /// The picture inside a bubble, for the viewer to shrink back into when it closes.
    static func firstImageView(in view: UIView) -> UIImageView? {
        for subview in view.subviews {
            if let imageView = subview as? UIImageView, imageView.image != nil, imageView.bounds.width > 40 {
                return imageView
            }
            if let found = firstImageView(in: subview) {
                return found
            }
        }
        return nil
    }

    /// The message a picture belongs to, wherever it is - a row of its own, or inside a collage.
    func messageForMedia(messageId: String) -> [String: Any?]? {
        if let row = dataMessages.first(where: { ($0["message_id"] as? String) == messageId }) {
            return row
        }
        for (_, images) in groupImages {
            if let image = images.first(where: { $0.messageId == messageId }) {
                return image.dataMessage
            }
        }
        // Media the strip reached past the end of the window for. Read once while the strip was
        // built, so following one of these costs nothing here.
        return mediaRowsOutsideWindowStorage[messageId]
    }

    /// Brings a message into view, reading the page it lives on first if it is not loaded.
    func goToMessage(messageId: String) {
        guard !messageId.isEmpty else {
            return
        }
        _ = ensureMessageLoaded(messageId: messageId)
        guard let indexPath = indexPath(forMessageId: messageId) else {
            return
        }
        tableChatView.scrollToRow(at: indexPath, at: .middle, animated: true)
    }

    /// Turns the star on a message on or off, in the database and in what is on screen.
    func toggleStar(messageId: String) {
        guard let row = messageForMedia(messageId: messageId) else {
            return
        }
        let starred = (row["is_stared"] as? String ?? "0") == "1"
        let value = starred ? "0" : "1"
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                        "is_stared" : Int(value) ?? 0
                    ], _where: "message_id = '\(messageId)'")
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
        if let idx = dataMessages.firstIndex(where: { ($0["message_id"] as? String) == messageId }) {
            dataMessages[idx]["is_stared"] = value
        }
        for (key, images) in groupImages {
            if let index = images.firstIndex(where: { $0.messageId == messageId }) {
                groupImages[key]?[index].dataMessage["is_stared"] = value
            }
        }
        if mediaRowsOutsideWindowStorage[messageId] != nil {
            mediaRowsOutsideWindowStorage[messageId]?["is_stared"] = value
        }
        tableChatView.reloadData()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "listenerStarMessage"), object: nil, userInfo: nil)
    }

    /// Starts the forward or delete session with this one message already picked - which is what
    /// those buttons mean when they are pressed from a picture: do this to the one I am looking
    /// at. The session itself is the one the long-press menu opens; nothing here is a second way
    /// of doing it.
    func beginMessageSession(forwarding: Bool, messageId: String) {
        if isSearching {
            cancelAction()
        }
        if reffId != nil {
            deleteReplyView()
        }
        if forwarding {
            forwardSession = true
        } else {
            deleteSession = true
        }
        let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
        cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
        if !isHistoryCC {
            navigationItem.rightBarButtonItems = nil
        }
        navigationItem.rightBarButtonItem = cancelButton
        changeAppBar()
        if let idx = dataMessages.firstIndex(where: { ($0["message_id"] as? String) == messageId }) {
            dataMessages[idx]["isSelected"] = true
        }
        addMultipleSelectSession()
        tableChatView.reloadData()
    }

    /// Opens the picker for where messages are being forwarded to.
    ///
    /// Shared by the selection session and by the viewer's forward button. Pulled out so the
    /// picture path is not a second way of forwarding that can drift from the first - the rules
    /// about unfolding a collage and about which screen the choice lands on live here only.
    func presentForwardChooser(for messages: [[String: Any?]], from presenter: UIViewController? = nil) {
        var dataMessages = messages
        let countSelected = dataMessages.count
        guard countSelected > 0 else {
            return
        }
        for i in 0..<countSelected {
            if let groupingImages = groupImages[dataMessages[i]["message_id"]  as? String ?? ""] {
                var tempData = dataMessages
                tempData.remove(at: 0)
                var dataMessageInGrouping = (groupImages[dataMessages[i]["message_id"]  as? String ?? ""]!).map({ $0.dataMessage })
                tempData.insert(contentsOf: dataMessageInGrouping, at: i)
                dataMessages = tempData
            }
        }
        // A card that slides up over whatever is on screen rather than a full-screen takeover, so
        // the conversation - or the picture the forward was pressed from - stays behind it.
        contactChatNav.modalPresentationStyle = .pageSheet
        if let sheet = contactChatNav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        contactChatNav.navigationBar.tintColor = .white
        contactChatNav.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        contactChatNav.navigationBar.isTranslucent = false
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        contactChatNav.navigationBar.titleTextAttributes = textAttributes
        let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        contactChatNav.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        if let controller = contactChatNav.viewControllers.first as? ContactChatViewController {
            controller.isChooser = { [weak self] scope, pin in
                guard let self = self else {
                    return
                }
                let openDestination = {
                    if scope == MessageScope.WHISPER || scope == MessageScope.CALL || scope == MessageScope.MISSED_CALL {
                        let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                        editorPersonalVC.unique_l_pin = pin
                        editorPersonalVC.dataMessageForward = dataMessages
                        self.navigationController?.replaceAllViewController(with: editorPersonalVC, animated: true)
                    } else {
                        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                        editorGroupVC.unique_l_pin = pin
                        editorGroupVC.dataMessageForward = dataMessages
                        self.navigationController?.replaceAllViewController(with: editorGroupVC, animated: true)
                    }
                }
                guard presenter != nil else {
                    openDestination()
                    return
                }
                // Opened from a picture, so there is a viewer between the conversation and the
                // chooser. Dismissing what the conversation itself presented takes both down at
                // once - otherwise the destination is swapped in underneath two screens and the
                // reader is left looking at the photo they just forwarded.
                self.dismiss(animated: false, completion: openDestination)
            }
        }
        (presenter ?? self).present(contactChatNav, animated: true, completion: nil)
    }

    /// Asks whether a message is being taken back for everyone or only here.
    ///
    /// Shared by the selection session and by the viewer's delete button, for the same reason as
    /// the chooser above: which of the two offers appear depends on who sent the message, whether
    /// it is locked and whether it ever left the phone, and that belongs in one place.
    func presentDeleteOptions(for messages: [[String: Any?]], from presenter: UIViewController? = nil) {
        let dataMessages = messages
        // Anything shown over the conversation is holding a message that is about to stop
        // existing, so it is taken down with it rather than left displaying a gap.
        let onDeleted: (() -> Void)? = presenter.map { shown in
            return { [weak shown] in shown?.dismiss(animated: true) }
        }
        let countSelected = dataMessages.count
        guard countSelected > 0 else {
            return
        }
        var options: [BottomChoiceSheet.Option] = []
        options.append(BottomChoiceSheet.Option(title: "Delete".localized() + " \(countSelected) " + "For Me".localized(), isDestructive: true) { [weak self] in
            self?.performDelete(for: "me", dataMessages: dataMessages, onDone: onDeleted)
        })
        let idMe = User.getMyPin() as String?
        let dataFilterFpin = dataMessages.filter({ $0["f_pin"] as? String != idMe})
        let dataFilterLock = dataMessages.filter({ $0["lock"] as? String == "1"})
//            let statusDataRead = dataMessages.filter({ Int($0["status"]  as? String ?? "")! >= 4})
        let statusFailed = dataMessages.filter({ (Int($0["status"] as? String ?? "") ?? -1) == 0})
        if dataFilterFpin.count == 0 && dataFilterLock.count == 0 && statusFailed.count == 0 {
            options.append(BottomChoiceSheet.Option(title: "Delete".localized() + " \(countSelected) " + "For Everyone".localized(), isDestructive: true) { [weak self] in
                self?.performDelete(for: "everyone", dataMessages: dataMessages, onDone: onDeleted)
            })
        }
        // There is no Cancel among the answers: the card carries a close button and shuts on a tap
        // outside, the way the design asks for.
        let sheet = BottomChoiceSheet(question: "Delete message?".localized(),
                                      options: options,
                                      appearance: presenter == nil ? .unspecified : .dark)
        // Putting a sheet up from a controller that is not on screen does nothing at all, so it is
        // whoever is in front that shows it - the conversation, or the picture viewer over it.
        (presenter ?? self).present(sheet, animated: true)
    }

    // MARK: - Preview

    /// The conversation's name, across the top, while this screen is a preview.
    ///
    /// Fix: a preview is not inside a navigation controller, so the header this screen normally
    /// hands to the navigation bar has nowhere to go - the card opened straight into the
    /// messages with nothing saying which conversation they belong to. WhatsApp puts the name
    /// there, and so does this. Only ever built for a preview; the real screen has its bar.
    private weak var previewHeader: UIVisualEffectView?
    private weak var previewHeaderLabel: UILabel?

    private func addPreviewHeaderIfNeeded() {
        guard isPreview, previewHeaderLabel == nil else {
            return
        }
        let header = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        view.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        header.contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: header.contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: header.contentView.trailingAnchor, constant: -16),
            label.centerXAnchor.constraint(equalTo: header.contentView.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: header.contentView.bottomAnchor, constant: -11)
        ])
        label.font = UIFont.systemFont(ofSize: 15 + offset()).bold
        label.textColor = .label
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.text = titleText
        previewHeader = header
        previewHeaderLabel = label
    }

    /// Built to be looked at rather than opened: the preview behind the chat list's long-press
    /// menu. Reading a conversation is something the reader does on purpose, so everything that
    /// says they have - the unread count, and the read marks the other side sees - waits here
    /// until the preview is actually opened.
    public var isPreview = false

    /// Read marks the loading pass would have sent, held back while this is only a preview.
    private var deferredReadReceipts: [(chatId: String, fPin: String, scope: String, messageId: String)] = []

    /// The preview has been tapped: it is a real conversation now, so everything held back
    /// happens at once.
    public func didOpenFromPreview() {
        guard isPreview else {
            return
        }
        isPreview = false
        // The navigation bar is about to say the name properly; two headers would be one too many.
        previewHeader?.removeFromSuperview()
        previewHeader = nil
        previewHeaderLabel = nil
        let pending = deferredReadReceipts
        deferredReadReceipts.removeAll()
        for receipt in pending {
            sendReadMessageStatus(chat_id: receipt.chatId, f_pin: receipt.fPin, message_scope_id: receipt.scope, message_id: receipt.messageId)
        }
        if counter > 0 {
            counter = 0
            updateCounter(counter: counter)
        }
        scheduleAutoDownloadSweep()
    }


    /// Starts fetching one of a message's files, exactly the way tapping it does.
    ///
    /// Fix: the sweep that fetches attachments as they come into view used to start a transfer of
    /// its own, beside this one. It fetched the file and nothing more - so a document's row kept
    /// its download icon afterwards, because what clears that icon is the message's own
    /// `progress`, and only the tap was writing it. There is one way to start a transfer now, and
    /// the sweep takes the same one: same guard against starting it twice, same ring, same row
    /// redrawn when it lands.
    ///
    /// Returns whether a transfer was actually started - one already running is left to finish.
    @discardableResult
    func beginTransfer(ofFileNamed filename: String, from indexPath: IndexPath? = nil, onFinish: (() -> Void)? = nil) -> Bool {
        // Fix: this used to compare the index path too, so the same file could be started again
        // from a row that had shifted, stacking a second progress ring on the bubble. All that
        // matters is whether this screen is already following it.
        guard !filename.isEmpty, downloadList[filename] == nil, !Download.isDownloading(forKey: filename) else {
            return false
        }
        // Asked for on purpose, so it is worth another try whatever happened last time.
        unreachableFiles.remove(filename)
        downloadList[filename] = indexPath ?? IndexPath(row: 0, section: 0)
        // Fix: this used to build a progress ring by hand, onto the one cell instance that had
        // been tapped - lost the moment that cell was recycled. cellForRow draws it now, and
        // onDownloadChat moves it, so this only has to start the transfer.
        Download().startHTTP(forKey: filename) { [weak self] (name, progress) in
            guard progress >= 100 || progress < 0 else {
                return
            }
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                // A download that failed used to stay in downloadList forever, and the guard
                // above then swallowed every retry.
                self.downloadList.removeValue(forKey: name)
                if progress < 0 {
                    // Fix: a file the server will not give up failed, was forgotten, and was
                    // picked straight back up by the next auto-download sweep - which redrew the
                    // row, which ran the sweep again. That loop is what made the bubble flicker.
                    // A failure is remembered, so nothing starts it again on its own; tapping it
                    // still can, and clears the mark.
                    self.unreachableFiles.insert(name)
                } else if progress >= 100 {
                    self.unreachableFiles.remove(name)
                    // A video that has just landed can be measured now, so the lengths are read
                    // again rather than staying as they were when this screen opened.
                    self.videoLengths = nil
                }
                if progress >= 100, let idx = self.dataMessages.firstIndex(where: {
                    ($0["video_id"] as? String ?? "") == name || ($0["file_id"] as? String ?? "") == name
                }) {
                    // What the bubble reads to decide whether it still offers to fetch this.
                    self.dataMessages[idx]["progress"] = 100.0
                }
                self.reloadMessageRow(withFileNamed: name)
                onFinish?()
            }
        }
        // Draw the row again so the ring appears straight away, at whatever progress the
        // transfer is already at.
        reloadMessageRow(withFileNamed: filename)
        return true
    }


    // MARK: - Bubble reuse

    /// Bumped whenever a file arrives, so a bubble drawn against "not downloaded yet" is not
    /// mistaken for one that is still current.
    private static var transferTick = 0

    private static var bubbleSignatureKey: UInt8 = 0

    /// Everything the drawing of one bubble depends on, in one string.
    ///
    /// The whole message goes in, not a chosen few of its fields. Choosing which fields matter
    /// is exactly how a bubble ends up showing yesterday's state, and a field costs nothing to
    /// include - where the answer is "something changed", the bubble is simply built the way it
    /// always was.
    private func bubbleSignature(for message: [String: Any?], at indexPath: IndexPath) -> String {
        let messageId = message["message_id"] as? String ?? ""
        var parts: [String] = ["\(indexPath.section).\(indexPath.row)"]
        for key in message.keys.sorted() {
            parts.append("\(key)=" + (message[key].map { String(describing: $0) } ?? "nil"))
        }
        // ...and the state of the screen around it, which the drawing reads just as much.
        parts.append("session=\(copySession)\(forwardSession)\(deleteSession)\(summarizeSession)")
        parts.append("search=\(isSearching)|\(textSearch)")
        parts.append("reference=\(referenceMessageId == messageId)")
        parts.append("marker=\(markerCounter == messageId)")
        parts.append("timer=\(listTimerCredential[messageId] ?? -1)")
        parts.append("font=\(offset())")
        // Width decides how wide a picture is drawn and where a bubble ends; appearance decides
        // half the colours. Neither is in the message, and both change under the reader.
        parts.append("width=\(Int(view.frame.size.width))")
        parts.append("appearance=\(traitCollection.userInterfaceStyle.rawValue)")
        parts.append("files=\(EditorGroup.transferTick)")
        if let group = groupImages[messageId] {
            // Fix: starring a picture inside a collage changed the member's row and nothing else,
            // and a signature that only carried the members' ids and transfer state read as
            // unchanged - so the bubble was never rebuilt and the star did not appear until the
            // conversation was opened again.
            parts.append("group=" + group.map {
                "\($0.messageId):\($0.status):\($0.dataMessage["is_stared"] as? String ?? "0")"
            }.joined(separator: ","))
        }
        return parts.joined(separator: ";")
    }

    /// What the cell in hand was last built for, or nil when it holds nothing built.
    private func builtSignature(of cell: UITableViewCell) -> String? {
        return objc_getAssociatedObject(cell, &EditorGroup.bubbleSignatureKey) as? String
    }

    private func setBuiltSignature(_ signature: String?, on cell: UITableViewCell) {
        objc_setAssociatedObject(cell, &EditorGroup.bubbleSignatureKey, signature, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    /// Takes a cell back to empty, ready to be built into.
    ///
    /// Fix: this used to ask every subview to remove its own constraints first. Taking a view
    /// out of the hierarchy already breaks the constraints that cross its edge, and the ones
    /// wholly inside it go when it does - so that pass built an array per subview to remove
    /// constraints that were about to be released anyway, on every row that scrolled past.
    private func emptyBubbleCell(_ cell: UITableViewCell) {
        setBuiltSignature(nil, on: cell)
        cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
    }

    // MARK: - Auto download

    /// Files this screen has started fetching on its own and is still waiting for.
    private var autoDownloadsInFlight: Set<String> = []
    private var autoDownloadTimer: Timer?
    /// How long the list has to settle before anything is fetched. Flinging past a hundred
    /// messages should not start a hundred transfers - only what the reader stops on counts.
    private static let autoDownloadSettleDelay: TimeInterval = 0.3
    /// How many at a time. Each one that finishes redraws its row, and redrawing rows is the
    /// expensive part; a few at a time keeps the list moving while they arrive.
    private static let maximumConcurrentAutoDownloads = 3

    /// Asks again once the list has settled. Cheap to call from anywhere that scrolls.
    private func scheduleAutoDownloadSweep() {
        guard !isPreview, Utils.isAutoDownloadOn else {
            return
        }
        autoDownloadTimer?.invalidate()
        autoDownloadTimer = Timer.scheduledTimer(withTimeInterval: EditorGroup.autoDownloadSettleDelay, repeats: false) { [weak self] _ in
            self?.autoDownloadTimer = nil
            self?.sweepVisibleRowsForAutoDownload()
        }
    }

    /// Fetches what is on screen and not here yet, nearest the middle of the view first.
    private func sweepVisibleRowsForAutoDownload() {
        guard Utils.isAutoDownloadOn,
              let visible = tableChatView.indexPathsForVisibleRows, !visible.isEmpty else {
            return
        }
        var slots = EditorGroup.maximumConcurrentAutoDownloads - autoDownloadsInFlight.count
        guard slots > 0 else {
            return
        }
        // Light things first, across every visible row, before anything heavy is started at
        // all: a document or a video can hold a place for a long time, and a thumbnail two rows
        // down should not be waiting behind it to appear.
        for keys in [EditorGroup.lightAttachmentKeys, EditorGroup.heavyAttachmentKeys] {
            for indexPath in visible {
                for filename in autoDownloadableFiles(at: indexPath, keys: keys) {
                    guard slots > 0 else {
                        return
                    }
                    guard !autoDownloadsInFlight.contains(filename),
                          !unreachableFiles.contains(filename),
                          !Download.isDownloading(forKey: filename) else {
                        continue
                    }
                    startAutoDownload(filename)
                    slots -= 1
                }
            }
        }
    }

    /// What the bubble draws: small, and worth having before anything else.
    private static let lightAttachmentKeys = ["thumb_id", "image_id", "gif_id", "audio_id"]
    /// What the bubble only offers to open. Fetched too, but never ahead of the above.
    private static let heavyAttachmentKeys = ["video_id", "file_id"]

    /// The attachments of one row that are not on this device yet.
    ///
    /// A collage row stands for several messages, so all of their pictures count - that is the
    /// row the reader is looking at.
    private func autoDownloadableFiles(at indexPath: IndexPath, keys: [String]) -> [String] {
        guard let row = message(at: indexPath) else {
            return []
        }
        var rows: [[String: Any?]] = [row]
        if let messageId = row["message_id"] as? String, let group = groupImages[messageId] {
            rows = group.map { $0.dataMessage }
        }
        var files: [String] = []
        for row in rows {
            for key in keys {
                let filename = (row[key] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !filename.isEmpty, !isFilePresent(filename) else {
                    continue
                }
                files.append(filename)
            }
        }
        return files
    }

    private func isFilePresent(_ filename: String) -> Bool {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let dirPath = paths.first else {
            return false
        }
        let url = URL(fileURLWithPath: dirPath).appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) || FileEncryption.shared.isSecureExists(filename: filename)
    }

    /// Files this screen has tried to fetch and could not. Left alone by the sweep from then on.
    private var unreachableFiles = Set<String>()

    /// Whether a file is one the sweep has already failed to fetch - what the bubble reads to
    /// decide between offering to download and saying it cannot.
    func isUnreachable(fileNamed filename: String) -> Bool {
        return unreachableFiles.contains(filename)
    }

    /// How long each video runs, read from the database once and kept for the drawing to use.
    ///
    /// A bubble is drawn many times a second while the reader scrolls; a query per bubble is out
    /// of the question. The column is written by whatever first has the file open, so this only
    /// has to be re-read when something new arrives.
    private var videoLengths: [String: Int]?

    private func videoLength(ofMessage row: [String: Any?]) -> Int {
        if videoLengths == nil {
            videoLengths = videoDurations()
        }
        return videoLengths?[row["message_id"] as? String ?? ""] ?? 0
    }

    private func startAutoDownload(_ filename: String) {
        autoDownloadsInFlight.insert(filename)
        // The same call a tap makes. Fetching a file is more than fetching a file - the row has
        // to stop offering to fetch it, and the ring has to appear while it is on its way - and
        // all of that lives in one place rather than being half-repeated here.
        let started = beginTransfer(ofFileNamed: filename) { [weak self] in
            guard let self = self else {
                return
            }
            self.autoDownloadsInFlight.remove(filename)
            // A place has come free; whatever else is on screen can have it.
            self.scheduleAutoDownloadSweep()
        }
        if !started {
            autoDownloadsInFlight.remove(filename)
        }
    }


    /// Whether a message can sit inside a collage at all: an image on its own, with no caption,
    /// no reply attached and nothing else that needs a bubble of its own.
    private func isCollageCandidate(_ row: [String: Any?]) -> Bool {
        return row["image_id"] != nil
            && !(row["image_id"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (row["message_text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (row["reff_id"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (row["read_receipts"] as? String ?? "") != "8"
    }

    private func imageGrouping(from row: [String: Any?]) -> ImageGrouping {
        return ImageGrouping(messageId: row["message_id"] as? String ?? "",
                             thumbId: row["thumb_id"] as? String ?? "",
                             imageId: row["image_id"] as? String ?? "",
                             status: row["status"] as? String ?? "",
                             time: row["server_date"] as? String ?? "",
                             lPin: row["l_pin"] as? String ?? "",
                             dataMessage: row,
                             dataPerson: [:],
                             dataGroup: dataGroup,
                             dataTopic: dataTopic)
    }

    /// Folds a message that has just arrived into the collage its sender is building at the
    /// bottom of the conversation.
    ///
    /// Fix: images were only ever gathered into collages while the conversation was being read
    /// from the database, so a run that arrived - or was sent - with this screen already open
    /// stayed as separate bubbles until the chat was opened again. The run is now continued as
    /// it happens, by the same rules the reading path uses: one sender, no more than eleven
    /// minutes apart, under the same date.
    ///
    /// Returns the row that draws the collage and therefore has to be redrawn, or nil when the
    /// message does not continue a run and belongs on a row of its own.
    private func foldIntoImageGroup(_ row: [String: Any?]) -> IndexPath? {
        guard isCollageCandidate(row), let lastIndex = dataMessages.indices.last else {
            return nil
        }
        let lastRow = dataMessages[lastIndex]
        let date = lastRow["chat_date"] as? String ?? ""
        // A collage cannot straddle a date header.
        guard date == (row["chat_date"] as? String ?? "") else {
            return nil
        }
        let parentId = lastRow["message_id"] as? String ?? ""
        var run: [ImageGrouping]
        if let existing = groupImages[parentId] {
            run = existing
        } else {
            // What is on screen is a lone image: it becomes the first of the run, and this
            // message its second.
            guard isCollageCandidate(lastRow) else {
                return nil
            }
            run = [imageGrouping(from: lastRow)]
        }
        guard let last = run.last,
              run.count < EditorGroup.maximumImagesInCollage,
              (last.dataMessage["f_pin"] as? String ?? "") == (row["f_pin"] as? String ?? "") else {
            return nil
        }
        let minutesApart = getSecondsDifferenceFromTwoDates(
            start: Date(milliseconds: Int64(last.time) ?? 0),
            end: Date(milliseconds: Int64(row["server_date"] as? String ?? "") ?? 0)) / 60
        guard minutesApart < 11 else {
            return nil
        }
        guard let section = dataDates.firstIndex(of: date),
              let rowIndex = messages(onDate: date).firstIndex(where: { $0["message_id"] as? String ?? "" == parentId }) else {
            return nil
        }
        run.append(imageGrouping(from: row))
        groupImages[parentId] = run
        return IndexPath(row: rowIndex, section: section)
    }


    /// How many images one person has to send in a row before they are drawn as one collage
    /// rather than as separate bubbles. Two, the way WhatsApp does it.
    static let minimumImagesForCollage = 2
    /// The most a single collage holds; images beyond this start another one.
    static let maximumImagesInCollage = 30

    /// Closes off the run of images collected so far, making a collage of it if there are
    /// enough. A collage keeps only its first message as a row of its own - the rest are drawn
    /// inside it - so the followers are taken back out of what was loaded.
    private func closeImageGroup(_ tempImages: inout [ImageGrouping], loaded: inout [[String: Any?]]) {
        defer { tempImages.removeAll() }
        guard tempImages.count >= EditorGroup.minimumImagesForCollage else {
            return
        }
        if tempImages.count > EditorGroup.maximumImagesInCollage {
            tempImages.removeSubrange(EditorGroup.maximumImagesInCollage..<tempImages.count)
        }
        groupImages[tempImages[0].messageId] = tempImages
        guard let idxTemp = loaded.firstIndex(where: { $0["message_id"] as? String ?? "" == tempImages[0].messageId }) else {
            return
        }
        for _ in 1..<tempImages.count {
            guard idxTemp + 1 < loaded.count else {
                break
            }
            loaded.remove(at: idxTemp + 1)
        }
    }

    var titleText: String!
    var lastY: CGFloat = 0
    var listTimerCredential: [String: Int] = [:]
    var timerCredential: [String: Timer] = [:]
    var editVC = UIViewController()
    var editTextView = CustomTextView()
    var isEditingMessage = false
    var constraintBottomeditTextView: NSLayoutConstraint!
    var constraintHeighteditTextView: NSLayoutConstraint!
    var constraintBottomSendEditTV: NSLayoutConstraint!
    let locationManager = CLLocationManager()
    var longitude = ""
    var latitude = ""
    var isBlackCancelButton = false
    let buttonSendEdit = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    
    var audioPlayers: [IndexPath: AVAudioPlayer] = [:]
    var timers: [IndexPath: Timer] = [:]
    var playingIndexPath: IndexPath?
    var timerSearch: Timer?
    
    var downloadList: [String: IndexPath] = [:]
    
    var transitioningDelegateRef: ZoomTransitioningDelegate?
    var buttonSpec = UIButton(type: .custom)
    var tableViewConfigFile: UITableView!
    var specFileString = ""
    
    var tableMentionEdit = UITableView()
    var heightTableEditMention: NSLayoutConstraint!
    
    private weak var lastContextMenuView: UIView?
    private var lastContextMenuInteraction: UIContextMenuInteraction?
    // Fix: title/icon are readable back off a UIAction, its handler is not - so the
    // handlers are kept here, keyed by the identifier chatMenuAction(...) stamps on each
    // action, for ChatBubbleContextMenu's hand-drawn rows to invoke.
    var contextMenuActionHandlers: [String: () -> Void] = [:]
    var contextMenuActionSeed = 0
    weak var longBubbleContextMenu: ChatBubbleContextMenu?
    // Fix: moved here from inside `extension EditorGroup: UIContextMenuInteractionDelegate`
    // - Swift does not allow stored properties inside extensions ("Extensions must
    // not contain stored properties"), only in the main class/struct body.
    // Fix: highlight is now potentially several small "chip" views (one per line the
    // link's range spans - see highlightRects(for:in:)), not a single view, so a
    // multi-line link gets one tightly-fitted highlight per line instead of one rect
    // stretched across all of them.
    private var currentLinkHighlightViews: [UIView] = []
    // Fix: a plain UITapGestureRecognizer only cares about touch-down + touch-up +
    // minimal movement - NOT duration - so it still recognizes (and fires
    // handleMessageTextTap) the moment the finger lifts after a long press, even
    // though containerMessage's UIContextMenuInteraction already recognized that same
    // touch as a long-press and is presenting LinkActionSheetViewController. The two
    // recognizers live on different views (messageText vs containerMessage), so
    // there's no reliable, guaranteed-by-default UIKit exclusivity between them to
    // lean on. This flag makes the "a long-press already handled this touch, don't
    // also treat the finger-lift as a tap" relationship explicit instead of relying
    // on gesture-arbitration timing that isn't guaranteed - set true the moment
    // configurationForMenuAtLocation recognizes a link long-press (which always fires
    // before the finger lifts), consumed (reset to false) by the very next tap.
    private var suppressNextLinkTap = false
    // Fix: dedicated token for the 5s safety-net reset that clears suppressNextLinkTap
    // if nothing else consumed it (see handleLinkTouchHighlight). Deliberately
    // separate from linkPressGeneration below - that one bumps on every touch
    // end/cancel, which would make a generation-gated reset here basically never
    // fire (defeating the point of a safety net). This token only changes when
    // suppressNextLinkTap is actually set true, so a stale reset from an earlier
    // press can tell it's stale (a newer press since changed the token) and skip,
    // without needing to fire on every unrelated touch.
    private var suppressLinkTapToken = 0
    // Fix: identifies which touch-down "generation" a pending long-press
    // timer belongs to (see handleLinkTouchHighlight) - incremented every time the
    // finger lifts/moves off a link/a new touch begins, so a timer scheduled for an
    // earlier touch that already ended can recognize it's stale and do nothing,
    // instead of firing the action sheet for a touch that's no longer happening.
    private var linkPressGeneration = 0
    
    private var readStatusTasks: [Task<Void, Never>] = []
    
    var lastScrollCheckTime: Date = Date()
    
    func offset() -> CGFloat{
        guard let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0") else { return 0 }
        return CGFloat(fontSize)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            removeAllObjectBeforeDismissVC()
        }
    }
    
    private func removeAllObjectBeforeDismissVC() {
        cancelAllReadStatusTasks()
        for timer in self.timerCredential.values {
            timer.invalidate()
        }
        SecureUserDefaults.shared.removeValue(forKey: "inEditorGroup")
        NotificationCenter.default.removeObserver(self)
        self.removeFromParent()
        var l_pin = self.dataGroup["group_id"]  as? String ?? ""
        if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
            l_pin = self.dataTopic["chat_id"]  as? String ?? ""
        }
        var data: [String: Any] = ["text": self.textFieldSend.textColor != UIColor.lightGray ? self.textFieldSend.text! : "", "reffId": self.reffId ?? ""]
        if listMentionInTextField.count > 0 {
            var dataMention: [[String: String]] = []
            for list in listMentionInTextField {
                var dataTemp: [String: String] = [:]
                dataTemp["f_pin_mention"] = list.pin
                dataTemp["upper"] = list.ex_block
                dataMention.append(dataTemp)
            }
            data["list_mention"] = dataMention
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            SecureUserDefaults.shared.set(jsonString, forKey: "new_saved_\(l_pin)")
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // The rows have real heights only once the table has laid out. Placing the chat at
        // its newest message here means it is drawn in the right place the first time, with
        // no visible jump - which is what the old fade from alpha 0 was covering up.
        if pendingInitialScrollToBottom, tableChatView.numberOfSections > 0 {
            pendingInitialScrollToBottom = false
            let lastSection = tableChatView.numberOfSections - 1
            let lastRow = tableChatView.numberOfRows(inSection: lastSection) - 1
            if lastRow >= 0 {
                tableChatView.safeScrollToRow(at: IndexPath(row: lastRow, section: lastSection), at: .bottom, animated: false)
            }
        }
        applyPendingUnreadMarkerScroll()
    }

    /// Puts the header in place: colours, the back button's tint, and the bar itself if the
    /// screen underneath had hidden it.
    private func prepareNavigationBar() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.overrideUserInterfaceStyle = .dark
        self.setNeedsStatusBarAppearanceUpdate()
        navigationController?.navigationBar.barStyle = .black
        if self.navigationController?.isNavigationBarHidden ?? false {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        }
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationItem.largeTitleDisplayMode = .never
    }

    /// Fix: all of the above used to run in viewDidAppear - after the push had finished and the
    /// conversation had already been laid out to the full height of the screen. The bar then
    /// arrived, took its space out of the top, and everything the reader was looking at slid.
    /// The chat list hides the bar for itself, so opening a chat from there showed this every
    /// single time. Done before the screen appears, the messages are laid out under a header
    /// that is already there, and nothing moves.
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareNavigationBar()
        addPreviewHeaderIfNeeded()
    }

    public override func viewDidAppear(_ animated: Bool) {
        prepareNavigationBar()
        updateProfile()
        // The first page only covers the screen; topping it up now means the reader's first
        // flick upwards does not immediately run out of messages.
        DispatchQueue.main.async { [weak self] in
            self?.prefetchOlderMessagesIfIdle()
        }
//        let indexPath = tableChatView.indexPathsForVisibleRows?.first
//        if indexPath != nil && currentIndexpath != nil {
//            let headerRect = tableChatView.rectForHeader(inSection: indexPath!.section)
//            let isPinned = headerRect.origin.y <= tableChatView.contentOffset.y
//            if listViewOnSection.count != 0 && listViewOnSection.count - 1 == indexPath!.section && isPinned {
//                let sect = listViewOnSection.count - 1 < currentIndexpath!.section ? listViewOnSection.count - 1 : currentIndexpath!.section
//                let headerView = listViewOnSection[sect]
//                headerView.isHidden = true
//            }
//        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
//        navigationController?.navigationBar.topItem?.title = ""
        Utils.addBackground(view: self.view)
        if let dataWall = UserDefaults.standard.data(forKey: "chatWallpaper") {
            wallpaperView.image = UIImage(data: UserDefaults.standard.data(forKey: "chatWallpaper")!)
        }
        else {
            wallpaperView.isHidden = true
        }
        if Nexilis.fromMAB {
            FloatingButton.setHidden(true)
        }
        
        viewButton.layer.shadowColor = self.traitCollection.userInterfaceStyle == .dark ? UIColor.white.cgColor : UIColor.gray.cgColor
        viewButton.layer.shadowOpacity = 1
        viewButton.layer.shadowOffset = .zero
        viewButton.layer.shadowRadius = 3
        viewButton.addTopBorder(with: UIColor.lightGray, andWidth: 1.0)
        
//        buttonVoice.setImage(resizeImage(image: UIImage(named: "Voice-Record", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)), for: .normal)
        viewAttachment.backgroundColor = .white
        buttonSendImage.setImage(resizeImage(image: UIImage(named: "Send-Image", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        buttonSendPhoto.setImage(resizeImage(image: UIImage(named: "Camera", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        buttonSendSticker.setImage(resizeImage(image: UIImage(named: "Sticker---Emoji", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        buttonSendFile.setImage(resizeImage(image: UIImage(named: "File---Documents", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor), for: .normal)
        
        buttonSendChat.setImage(resizeImage(image: self.traitCollection.userInterfaceStyle == .dark ? UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.blackDarkMode) : UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal), for: .normal)
        
        buttonSendChat.circle()
        buttonSendChat.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        buttonSendChat.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        buttonAckConfidential.circle()
        buttonAckConfidential.addTarget(self, action: #selector(showChooserACKConfidential), for: .touchUpInside)
        buttonAckConfidential.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        buttonAckConfidential.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        textFieldSend.backgroundColor = .white
        textFieldSend.layer.cornerRadius = textFieldSend.maxCornerRadius()
        textFieldSend.layer.borderWidth = 1.0
        textFieldSend.text = "Send message".localized()
        textFieldSend.textColor = UIColor.lightGray
        textFieldSend.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        textFieldSend.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 11, right: 40)
        textFieldSend.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        textFieldSend.font = UIFont.systemFont(ofSize: 12 + offset())
        textFieldSend.delegate = self
        textFieldSend.customDelegate = self
        textFieldSend.allowsEditingTextAttributes = true
        
        navigationItem.rightBarButtonItem?.tintColor = UIColor.secondaryColor
        
        imageVideoPicker = ImageVideoPicker(presentationController: self, delegate: self)
        documentPicker = DocumentPicker(presentationController: self, delegate: self)
        
        let fm = FileManager.default
        if Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") != nil {
            let path = Bundle.resourceBundle(for: Nexilis.self).resourcePath! //resourcesMediaBundle
            let items = try! fm.contentsOfDirectory(atPath: path)
            
            for item in items {
                if item.hasPrefix("sticker") {
                    stickers.append(item)
                }
            }
        } else {
            let path = Bundle.resourcesMediaBundle(for: Nexilis.self).resourcePath! //resourcesMediaBundle
            let items = try! fm.contentsOfDirectory(atPath: path)
            
            for item in items {
                if item.hasPrefix("sticker") {
                    stickers.append(item)
                }
            }
        }
        
        tableChatView.register(UITableViewCell.self, forCellReuseIdentifier: "cellEditorGroup")
        
        loadData()
        setRightButtonItem()
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil)
        center.addObserver(self, selector: #selector(onStatusChat(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusChat), object: nil)
        center.addObserver(self, selector: #selector(onUploadChat(notification:)), name: NSNotification.Name(rawValue: "onUploadChat"), object: nil)
        // Fix: downloads broadcast their progress now, the same way uploads always
        // have - so a transfer that was already running when this screen opened (or
        // was started from another screen entirely) still drives the progress ring.
        center.addObserver(self, selector: #selector(onDownloadChat(notification:)), name: Download.progressNotification, object: nil)
        center.addObserver(self, selector: #selector(onMemberTopic(notification:)), name: NSNotification.Name(rawValue: "onMember"), object: nil)
        center.addObserver(self, selector: #selector(onGroup(notification:)), name: NSNotification.Name(rawValue: "onGroup"), object: nil)
        center.addObserver(self, selector: #selector(onMemberTopic(notification:)), name: NSNotification.Name(rawValue: "onTopic"), object: nil)
        center.addObserver(self, selector: #selector(onFailedSendMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.failedSendMessage), object: nil)
        center.addObserver(self, selector: #selector(onUpdatedMessage(notification:)), name: NSNotification.Name(rawValue: "onUpdatedMessage"), object: nil)
        center.addObserver(self, selector: #selector(onCheckNewMessages(notification:)), name: NSNotification.Name(rawValue: "checkNewMessagesNexilis"), object: nil)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        
        if dataMessageForward != nil {
            for i in 0..<dataMessageForward!.count {
                let isForwarded = (dataMessageForward![i][TypeDataMessage.is_forwarded] as? Int) ?? 0
                sendChat(message_scope_id: MessageScope.GROUP, status: "2", message_text: dataMessageForward![i]["message_text"]  as? String ?? "", credential: "0", attachment_flag: dataMessageForward![i]["attachment_flag"]  as? String ?? "", ex_blog_id: "", message_large_text: "", ex_format: "", image_id: dataMessageForward![i]["image_id"]  as? String ?? "", audio_id: dataMessageForward![i]["audio_id"]  as? String ?? "", video_id: dataMessageForward![i]["video_id"]  as? String ?? "", file_id: dataMessageForward![i]["file_id"]  as? String ?? "", thumb_id: dataMessageForward![i]["thumb_id"]  as? String ?? "", reff_id: "", read_receipts: "", is_call_center: "0", call_center_id: "", viewController: self, gif_id: dataMessageForward![i][TypeDataMessage.gif_id]  as? String ?? "", is_forwarded: isForwarded + 1)
            }
            dataMessageForward = nil
        }
        tableMention.register(UITableViewCell.self, forCellReuseIdentifier: "cellMention")
        tableMention.dataSource = self
        tableMention.delegate = self
        tableMention.contentInset = UIEdgeInsets(top: -25, left: 0, bottom: 0, right: 0)
        
        tableChatView.rowHeight = UITableView.automaticDimension
        // A concrete estimate rather than automaticDimension: with the automatic one the
        // table measures rows to work out where it is, which is exactly the cost that made
        // scrolling to the bottom expensive. estimatedHeightForRowAt refines this per row
        // once a row has actually been on screen.
        tableChatView.estimatedRowHeight = 72
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Ini aman di main thread karena delegate dipanggil di main thread
            // dan startUpdatingLocation sendiri tidak blocking
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        latitude = "\(location.coordinate.latitude)"
        longitude = "\(location.coordinate.longitude)"
        manager.stopUpdatingLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    public func afterUnfriend() {
        DispatchQueue.main.async {
            SecureUserDefaults.shared.removeValue(forKey: "inEditorGroup")
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func updateProfile() {
        let idMe = User.getMyPin() as String?
        DispatchQueue.global().async {
            let message = CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: idMe!, last_update: 0)
            let _ = Nexilis.write(message: message)
        }
    }
    
    private func setRightButtonItem() {
        navigationItem.rightBarButtonItems = nil
        navigationItem.rightBarButtonItem = nil
        let menu = UIMenu(title: "", children: [
            UIAction(title: "Delete Conversation".localized(), handler: {(_) in
                let alert = LibAlertController(title: "", message: "Are you sure to delete all message in this conversation?".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: nil))
                alert.addAction(UIAlertAction(title: "Delete".localized(), style: .destructive, handler: {(_) in
                    var l_pin = self.dataGroup["group_id"]  as? String ?? ""
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
                                l_pin = self.dataTopic["chat_id"]  as? String ?? ""
                            }
                            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "(l_pin='\(self.dataGroup["group_id"]!!)' and chat_id='\(self.dataTopic["chat_id"]!!)') and message_scope_id='4'")
                            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(l_pin)'")
                            SecureUserDefaults.shared.removeValue(forKey: "new_saved_\(l_pin)")
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                            if self.fromNotification {
                                self.didTapExit()
                            } else {
                                self.navigationController?.popViewController(animated: true)
                            }
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }))
                self.present(alert, animated: true, completion: nil)
            }),
        ])
        if !isHistoryCC {
            let moreIcon = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), menu: menu)
            let buttonSearch = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(search(sender:)))
            navigationItem.rightBarButtonItems = [moreIcon,buttonSearch]
        } else {
            let buttonSearch = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(search(sender:)))
            navigationItem.rightBarButtonItem = buttonSearch
        }
    }
    
    @objc func search(sender: UIBarButtonItem) {
        self.isSearching = true
        if self.reffId != nil {
            self.deleteReplyView()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
            cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
            if !self.isHistoryCC {
                self.navigationItem.rightBarButtonItems = nil
            }
            self.navigationItem.rightBarButtonItem = cancelButton
            self.changeAppBar()
            self.addMultipleSelectSession()
        }
    }
    
    private func getOfficialGroup() {
        let query = "SELECT group_id, f_name, official, image_id FROM GROUPZ where group_type = 1 AND official = 1"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    if cursorData.next() {
                        dataGroup["group_id"] = cursorData.string(forColumnIndex: 0)
                        dataTopic["chat_id"] = ""
                        dataGroup["f_name"] = cursorData.string(forColumnIndex: 1)
                        dataGroup["image_id"] = cursorData.string(forColumnIndex: 3)
                        dataGroup["official"] = cursorData.string(forColumnIndex: 2)
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    func loadData() {
        if (unique_l_pin != "") {
            dataDates.removeAll()
            dataGroup.removeAll()
            dataTopic.removeAll()
            dataMessages.removeAll()
            // Nothing is loaded any more, so neither is any window over it.
            loadedOffset = 0
            loadedCount = 0
            measuredRowHeights.removeAll()
            tableChatView.reloadData()
            currentIndexpath = nil
            reffId = nil
            getDataGroup(unique_l_pin: unique_l_pin)
        }
        
        if removed {
            removed = false
            containerActionGroup.removeConstraints(containerActionGroup.constraints)
            containerActionGroup.removeFromSuperview()
            setRightButtonItem()
        }
        
        if !isHistoryCC {
            let groupId = dataGroup["group_id"]  as? String ?? ""
            let chatId = dataTopic["chat_id"]  as? String ?? ""
            let dataGT: [String] = [groupId, chatId]
            SecureUserDefaults.shared.set(dataGT, forKey: "inEditorGroup")
            
            if dataTopic["chat_id"]  as? String ?? "" == "" {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [groupId])
                sendTyping(l_pin: groupId)
            } else {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [chatId])
                sendTyping(l_pin: chatId)
            }
        } else {
            getOfficialGroup()
            disableEditor()
        }
        
        if fromNotification {
            let imageButton = UIImageView(frame: CGRect(x: -16, y: 0, width: 20, height: 44))
            imageButton.image = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default))?.withTintColor(.white)
            imageButton.contentMode = .left
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapExit))
            imageButton.isUserInteractionEnabled = true
            imageButton.addGestureRecognizer(tapGestureRecognizer)
            let leftItem = UIBarButtonItem(customView: imageButton)
            self.navigationItem.leftBarButtonItem = leftItem
        }
        
        changeAppBar()
        // The unread count decides how deep the first page has to go, so it is read before
        // the messages rather than after them.
        getCounter()
        loadInitialMessages()
        markerCounter = unreadMarkerMessageId(unread: counter)
        // A message swallowed by an image collage is not a row of its own, so the collage it
        // belongs to is the row that carries the marker.
        if let marker = markerCounter, !dataMessages.contains(where: { $0["message_id"] as? String == marker }),
           let parent = groupImages.first(where: { $0.value.contains(where: { $0.messageId == marker }) })?.key {
            markerCounter = parent
        }
        if counter > 0, !isPreview {
            counter = 0
            updateCounter(counter: counter)
        }

        tableChatView.delegate = self
        // Pull a row right to reply to it, left for its info - see ChatBubbleSwipe.
        bubbleSwipe = ChatBubbleSwipe(tableView: tableChatView, canPerform: { [weak self] indexPath, direction in
            return self?.canSwipeBubble(at: indexPath, direction: direction) ?? false
        }, perform: { [weak self] indexPath, direction in
            self?.performBubbleSwipe(at: indexPath, direction: direction)
        })
        // A leftward pull drags the info screen in from the right edge rather than opening it
        // once the pull is over - see InteractiveSidePush.
        bubbleSwipe?.infoDestination = { [weak self] indexPath in
            guard let self = self,
                  let navigation = self.navigationController,
                  let message = self.message(at: indexPath) else {
                return nil
            }
            let messageInfoVC = MessageInfo()
            messageInfoVC.data = message
            messageInfoVC.dataGroup = self.dataGroup
            messageInfoVC.isPersonal = false
            return (messageInfoVC, navigation)
        }
        tableChatView.dataSource = self
        tableChatView.reloadData()
        if !referenceMessageId.isEmpty {
            // The message being jumped to can be older than the page that was just read.
            ensureMessageLoaded(messageId: referenceMessageId)
            if dataMessages.firstIndex(where: {$0["message_id"] as? String == referenceMessageId} ) != nil {
                DispatchQueue.main.async {
                    if self.referenceChatDate.isEmpty {
                        self.referenceChatDate = self.chatDate(stringDate: self.dataMessages[self.dataMessages.firstIndex(where: {$0["message_id"] as? String == self.referenceMessageId} )!][TypeDataMessage.server_date] as! String)
                    }
                    let section = self.dataDates.firstIndex(of: self.referenceChatDate)
                    let row = self.messages(onDate: self.referenceChatDate).firstIndex(where: { $0["message_id"] as? String == self.referenceMessageId})
                    if row != nil && section != nil {
                        let indexPath = IndexPath(row: row!, section: section!)
                        self.tableChatView.safeScrollToRow(at: indexPath, at: .middle, animated: false)
                        self.tableChatView.cellForRow(at: indexPath)?.contentView.backgroundColor = .yellow
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            self.tableChatView.cellForRow(at: indexPath)?.contentView.backgroundColor = .clear
                        })
                    }
                }
            }
        } else if markerCounter != nil {
            let contentHeight = tableChatView.contentSize.height
            let visibleHeight = tableChatView.frame.height
            let fullOffset = contentHeight - visibleHeight
            let offsetY = tableChatView.contentOffset.y
            let isNearBottom = (fullOffset - offsetY < 50)
            if let marker = markerCounter, indexPath(forMessageId: marker) != nil {
                // Placed here and repeated from viewDidLayoutSubviews - see
                // applyPendingUnreadMarkerScroll() for why one scroll from here was never
                // going to land in the right place.
                pendingUnreadMarkerScroll = marker
                remainingUnreadMarkerScrollPasses = EditorGroup.unreadMarkerScrollPasses
                applyPendingUnreadMarkerScroll()
            } else {
                // The marker's message is not a row of its own after all (deleted, or hidden
                // inside a collage). Opening at the newest message beats opening at the top of
                // whatever happens to be loaded.
                pendingInitialScrollToBottom = true
                tableChatView.scrollToBottom(isAnimated: false, delay: 0)
            }
            if !isNearBottom && !buttonScrollToBottom.isDescendant(of: view) {
                DispatchQueue.main.async { [self] in
                    addButtonScrollToBottom()
                    addCounterAtButttonScrollToBottom()
                }
            }
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) { [self] in
                DispatchQueue.main.async { [self] in
                    let lastVisibleIndexPath = tableChatView.indexPathsForVisibleRows?.last
                    currentIndexpath = lastVisibleIndexPath
                }
                if markerCounter != nil {
                    let idMe = User.getMyPin() as String?
                    if let idx = dataMessages.firstIndex(where: { $0["message_id"] as? String == markerCounter}) {
                        var stringMessage: [String: String] = [:]
                        for i in idx..<dataMessages.count {
                            if dataMessages[i]["f_pin"] as? String != idMe && EditorGroup.conditionSendRead(scope: dataMessages[i][TypeDataMessage.message_scope_id] as! String, fPin: dataMessages[i][TypeDataMessage.f_pin] as! String, messageId: dataMessages[i][TypeDataMessage.message_id] as! String) {
                                let fpin = dataMessages[i]["f_pin"]  as? String ?? ""
                                let mId = dataMessages[i]["message_id"]  as? String ?? ""
                                if stringMessage[fpin] == nil {
                                    stringMessage[fpin] = mId
                                } else {
                                    var str1 = stringMessage[fpin]!
                                    str1 += ",\(mId)"
                                    stringMessage[fpin] = str1
                                }
                            }
                        }
                        if stringMessage.count > 0 {
                            for str in stringMessage {
                                sendReadMessageStatus(
                                    chat_id: self.dataTopic["chat_id"]  as? String ?? "",
                                    f_pin: str.key,
                                    message_scope_id: MessageScope.GROUP,
                                    message_id: str.value
                                )
                            }
                        }
                        if idx != 0 {
                            var stringMessage1: [String: String] = [:]
                            for i in 0..<idx {
                                let status = dataMessages[i][TypeDataMessage.status] as? String
                                if dataMessages[i]["f_pin"] as? String != idMe && status != "4" && status != "8" && EditorGroup.conditionSendRead(scope: dataMessages[i][TypeDataMessage.message_scope_id] as! String, fPin: dataMessages[i][TypeDataMessage.f_pin] as! String, messageId: dataMessages[i][TypeDataMessage.message_id] as! String) {
                                    let fpin = dataMessages[i]["f_pin"]  as? String ?? ""
                                    let mId = dataMessages[i]["message_id"]  as? String ?? ""
                                    if stringMessage1[fpin] == nil {
                                        stringMessage1[fpin] = mId
                                    } else {
                                        var str1 = stringMessage1[fpin]!
                                        str1 += ",\(mId)"
                                        stringMessage1[fpin] = str1
                                    }
                                }
                            }
                            if stringMessage1.count > 0 {
                                for str in stringMessage1 {
                                    sendReadMessageStatus(
                                        chat_id: self.dataTopic["chat_id"]  as? String ?? "",
                                        f_pin: str.key,
                                        message_scope_id: MessageScope.GROUP,
                                        message_id: str.value
                                    )
                                }
                            }
                        }
                    }
                }
            }
        } else {
            var l_pin = self.dataGroup["group_id"]  as? String ?? ""
            if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
                l_pin = self.dataTopic["chat_id"]  as? String ?? ""
            }
            if let dataSaved: String = SecureUserDefaults.shared.value(forKey: "new_saved_\(l_pin)") {
                let data = dataSaved
                if let jsonData = data.data(using: .utf8),
                   let dataJson = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    let last_m = dataJson["text"] as? String ?? ""
                    let last_r = dataJson["reffId"] as? String ?? ""
                    let list_m = dataJson["list_mention"] as? [[String: String]] ?? []
                    
                    if !last_m.isEmpty {
                        textFieldSend.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black
                    }
                    
                    if list_m.count > 0 {
                        for list in list_m {
                            let f_pin = list["f_pin_mention"] ?? ""
                            let upper = list["upper"] ?? ""
                            let userFromBuddy = User.getData(pin: f_pin, lPin: l_pin)
                            if userFromBuddy != nil {
                                userFromBuddy!.ex_block = upper
                                listMentionInTextField.append(userFromBuddy!)
                            }
                        }
                    }
                    
                    if !last_m.isEmpty {
                        textFieldSend.attributedText = last_m.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
                    }
                    
                    if !last_r.isEmpty {
                        handleReply(indexPath: IndexPath(row: 0, section: 0), reffId: last_r)
                    }
                }
            }
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                let idMe = User.getMyPin() as String?
                var stringMessage: [String: String] = [:]
                for i in 0..<dataMessages.count {
                    let status = dataMessages[i][TypeDataMessage.status] as? String
                    if dataMessages[i]["f_pin"] as? String != idMe && status != "4" && status != "8" && EditorGroup.conditionSendRead(scope: dataMessages[i][TypeDataMessage.message_scope_id] as! String, fPin: dataMessages[i][TypeDataMessage.f_pin] as! String, messageId: dataMessages[i][TypeDataMessage.message_id] as! String) {
                        let fpin = dataMessages[i]["f_pin"]  as? String ?? ""
                        let mId = dataMessages[i]["message_id"]  as? String ?? ""
                        if stringMessage[fpin] == nil {
                            stringMessage[fpin] = mId
                        } else {
                            var str1 = stringMessage[fpin]!
                            str1 += ",\(mId)"
                            stringMessage[fpin] = str1
                        }
                    }
                }
                if stringMessage.count > 0 {
                    for str in stringMessage {
                        sendReadMessageStatus(
                            chat_id: self.dataTopic["chat_id"]  as? String ?? "",
                            f_pin: str.key,
                            message_scope_id: MessageScope.GROUP,
                            message_id: str.value
                        )
                    }
                }
            }
            // No delay: with one page loaded there is nothing left to wait for. The same
            // scroll is repeated once the table has actually laid out (see
            // viewDidLayoutSubviews), so the very first frame the user sees is already at the
            // bottom of the conversation instead of arriving there afterwards.
            pendingInitialScrollToBottom = true
            tableChatView.scrollToBottom(isAnimated: false, delay: 0)
        }
        tableChatView.keyboardDismissMode = .interactive
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableChatView.addGestureRecognizer(tapGesture)
        // The table used to be faded in from alpha 0 after 0.6s + 0.5s of animation, which is
        // where the blank screen on opening a chat came from. It was there to hide the load;
        // there is no load left to hide.
        DispatchQueue.main.async { [weak self] in
            self?.isInitialLoading = false
            // A screen that has no conversation of its own - a profile, say - can ask for one of
            // this conversation's pictures to be opened. It has to wait until there is something
            // to open it from, which is here.
            if let wanted = self?.openMediaOnceLoaded, !wanted.isEmpty {
                self?.openMediaOnceLoaded = ""
                self?.openMedia(messageId: wanted)
            }
            if let wanted = self?.goToMessageOnceLoaded, !wanted.isEmpty {
                self?.goToMessageOnceLoaded = ""
                self?.highlightMessage(wanted)
            }
        }
        for data in listTimerCredential {
            if data.value > 0 {
                var second = data.value
                var timer = Timer()
                timerCredential[data.key] = timer
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                    second -= 1
                    self.listTimerCredential[data.key] = second
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == data.key })
                    if (idx != nil) {
                        let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                        let row = self.messages(onDate: self.dataMessages[idx!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                        if second == 0 {
                            timer.invalidate()
                            self.listTimerCredential.removeValue(forKey: data.key)
                            self.timerCredential.removeValue(forKey: data.key)
                            SecureUserDefaults.shared.removeValue(forKey: data.key)
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == data.key})
                            if idx != nil {
                                self.dataMessages[idx!]["lock"] = "2"
                                self.dataMessages[idx!]["reff_id"] = ""
                            }
                            DispatchQueue.global().async {
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                            "lock" : "2"
                                        ], _where: "message_id = '\(data.key)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                            }
                        }
                        if row != nil && section != nil  {
                            self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                        }
                    }
                })
            }
        }
        let dataMessagesPin = self.pinnedMessagesForBanner()
        pinAllMessages(dataMessages: dataMessagesPin)
    }
    
    static func conditionSendRead(scope: String, fPin: String, messageId: String) -> Bool {
        return scope != MessageScope.CALL && scope != MessageScope.MISSED_CALL && !messageId.contains("NTFPIN_") && fPin != "-999"
    }
    
    func getDataProfile(f_pin: String, message_id: String) -> [String: String]{
        var data: [String: String] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name, image_id from BUDDY where f_pin = '\(f_pin)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                data["image_id"] = c.string(forColumnIndex: 1) ?? ""
                c.close()
            }
            else if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name, thumb_id from GROUPZ_MEMBER where f_pin = '\(f_pin)' AND group_id = '\(dataGroup["group_id"]!!)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                data["image_id"] = c.string(forColumnIndex: 1) ?? ""
                c.close()
            } else if let c = Database().getRecords(fmdb: fmdb, query: "select f_display_name from MESSAGE where message_id = '\(message_id)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0) ?? ""
                data["image_id"] = ""
                c.close()
            } else if f_pin == "-997" {
                data["name"] = Utils.getGPTBotName()
                data["image_id"] = ""
            } else {
                data["name"] = "Unknown".localized()
            }
        })
        return data
    }
    
    private func getDataGroup(unique_l_pin: String) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorGroup = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id, f_name, image_id, official, parent FROM GROUPZ WHERE group_id='\(unique_l_pin)'"), cursorGroup.next() {
                    dataGroup["group_id"] = cursorGroup.string(forColumnIndex: 0)
                    dataGroup["f_name"] = cursorGroup.string(forColumnIndex: 1)
                    dataGroup["image_id"] = cursorGroup.string(forColumnIndex: 2)
                    dataGroup["official"] = cursorGroup.string(forColumnIndex: 3)
                    dataGroup["parent"] = cursorGroup.string(forColumnIndex: 4)
                    dataTopic["title"] = "Lounge".localized()
                    dataTopic["chat_id"] = ""
                    cursorGroup.close()
                } else if let cursorTopic = Database.shared.getRecords(fmdb: fmdb, query: "SELECT group_id, title FROM DISCUSSION_FORUM where chat_id = '\(unique_l_pin)'"), cursorTopic.next() {
                    dataGroup["group_id"] = cursorTopic.string(forColumnIndex: 0)
                    dataTopic["title"] = cursorTopic.string(forColumnIndex: 1)
                    dataTopic["chat_id"] = unique_l_pin
                    cursorTopic.close()
                    if let cursorGroup = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_name, image_id, official, parent FROM GROUPZ where group_id = '\(dataGroup["group_id"]  as? String ?? "")'"), cursorGroup.next() {
                        dataGroup["f_name"] = cursorGroup.string(forColumnIndex: 0)
                        dataGroup["image_id"] = cursorGroup.string(forColumnIndex: 1)
                        dataGroup["official"] = cursorGroup.string(forColumnIndex: 2)
                        dataGroup["parent"] = cursorGroup.string(forColumnIndex: 3)
                        cursorGroup.close()
                    }
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    /// What picks this conversation's messages out of MESSAGE. One place, so the row query,
    /// the counts and the "where does this message sit" lookups can never drift apart.
    private func messageWhereClause() -> String {
        if isHistoryCC {
            return "call_center_id='\(complaintId)'"
        }
        if (dataTopic["chat_id"] as? String ?? "") != "" {
            return "chat_id='\(dataTopic["chat_id"] as? String ?? "")'"
        }
        return "chat_id='' AND l_pin='\(dataGroup["group_id"] as? String ?? "")'"
    }

    /// How many messages this conversation has in the database.
    private func countMessages() -> Int64 {
        var total: Int64 = 0
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT COUNT(*) FROM MESSAGE where \(self.messageWhereClause())"), cursor.next() {
                total = cursor.longLongInt(forColumnIndex: 0)
                cursor.close()
            }
        })
        return total
    }

    /// Position of a message within this conversation, counting from the oldest, or nil when
    /// it is not in this conversation at all.
    private func messagePosition(messageId: String) -> Int64? {
        guard !messageId.isEmpty else {
            return nil
        }
        var position: Int64?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            // Read the date first: a message this conversation does not have must come back
            // as nil, not as position zero, or it would look like the oldest message there is.
            var serverDate = ""
            if let dateCursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT server_date FROM MESSAGE where message_id='\(messageId)'"), dateCursor.next() {
                serverDate = dateCursor.string(forColumnIndex: 0) ?? ""
                dateCursor.close()
            }
            guard !serverDate.isEmpty else {
                return
            }
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT COUNT(*) FROM MESSAGE where \(self.messageWhereClause()) AND server_date < \(serverDate)"), cursor.next() {
                position = cursor.longLongInt(forColumnIndex: 0)
                cursor.close()
            }
        })
        return position
    }

    /// Reads a slice of the conversation.
    ///
    /// - Parameters:
    ///   - limit: how many rows, or -1 for "everything from `offset` on".
    ///   - prepend: older messages go in front of what is already loaded; new ones behind it.
    ///   - marksFirstAsUnread: the first row read becomes the "unread from here" marker.
    private func getData(offset: Int64 = 0, limit: Int64 = -1, prepend: Bool = false, marksFirstAsUnread: Bool = false) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                let query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, last_edited, gif_id, is_forwarded_message, attachment_speciality, is_pinned FROM MESSAGE where \(self.messageWhereClause()) order by server_date asc LIMIT \(limit) OFFSET \(offset)"
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    var tempImages: [ImageGrouping] = []
                    var idxOff = 0
                    // Read into a slice of its own, then splice it in at the end: older
                    // messages have to go in front of what is on screen, and the image
                    // grouping below has to look at this batch rather than the whole chat.
                    var loaded: [[String: Any?]] = []
                    while cursorData.next() {
                        var row: [String: Any?] = [:]
                        row["message_id"] = cursorData.string(forColumnIndex: 0)
                        row["f_pin"] = cursorData.string(forColumnIndex: 1)
                        row["l_pin"] = cursorData.string(forColumnIndex: 2)
                        row["message_scope_id"] = cursorData.string(forColumnIndex: 3)
                        row["server_date"] = cursorData.string(forColumnIndex: 4)
                        row["status"] = cursorData.string(forColumnIndex: 5)
                        row["message_text"] = cursorData.string(forColumnIndex: 6)
                        row["audio_id"] = cursorData.string(forColumnIndex: 7)
                        row["video_id"] = cursorData.string(forColumnIndex: 8)
                        row["image_id"] = cursorData.string(forColumnIndex: 9)
                        row["thumb_id"] = cursorData.string(forColumnIndex: 10)
                        row["read_receipts"] = cursorData.string(forColumnIndex: 11)
                        row["chat_id"] = cursorData.string(forColumnIndex: 12)
                        row["file_id"] = cursorData.string(forColumnIndex: 13)
                        row["attachment_flag"] = cursorData.string(forColumnIndex: 14)
                        row["reff_id"] = cursorData.string(forColumnIndex: 15)
                        row["lock"] = cursorData.string(forColumnIndex: 16)
                        row["is_stared"] = cursorData.string(forColumnIndex: 17)
                        row["blog_id"] = cursorData.string(forColumnIndex: 18) ?? ""
                        row["credential"] = cursorData.string(forColumnIndex: 19) ?? ""
                        row[TypeDataMessage.last_edit] = cursorData.longLongInt(forColumnIndex: 20)
                        row[TypeDataMessage.gif_id] = cursorData.string(forColumnIndex: 21) ?? ""
                        row[TypeDataMessage.is_forwarded] = Int(cursorData.int(forColumnIndex: 22))
                        row[TypeDataMessage.spec_file] = cursorData.string(forColumnIndex: 23) ?? ""
                        row[TypeDataMessage.is_pinned] = cursorData.string(forColumnIndex: 24) ?? ""
                        row["isSelected"] = false
                        if row["credential"] != nil && row["credential"]  as? String ?? "" == "1" {
                            let idMe = User.getMyPin()!
                            if row["f_pin"]  as? String ?? "" == idMe {
                                let second = getSecondsDifferenceFromTwoDates(start: Date.init(milliseconds: Int64(row["server_date"]  as? String ?? "")!), end: Date())
                                if second > 60 {
                                    listTimerCredential[row["message_id"]  as? String ?? ""] = 0
                                    row["lock"] = "2"
                                    row["reff_id"] = ""
                                    DispatchQueue.global().async {
                                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                            do {
                                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                    "lock" : "2"
                                                ], _where: "message_id = '\(row["message_id"]  as? String ?? "")'")
                                            } catch {
                                                rollback.pointee = true
                                                print("Access database error: \(error.localizedDescription)")
                                            }
                                        })
                                    }
                                } else {
                                    let second = 60 - second
                                    listTimerCredential[row["message_id"]  as? String ?? ""] = second
                                }
                            } else {
                                let hasMessageId: String? = SecureUserDefaults.shared.value(forKey: row["message_id"]  as? String ?? "") ?? nil
                                if hasMessageId != nil {
                                    let second = getSecondsDifferenceFromTwoDates(start: Date.init(milliseconds: Int64(hasMessageId!)!), end: Date())
                                    if second > 60 {
                                        listTimerCredential[row["message_id"]  as? String ?? ""] = 0
                                        row["lock"] = "2"
                                        row["reff_id"] = ""
                                        DispatchQueue.global().async {
                                            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                                do {
                                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                                        "lock" : "2"
                                                    ], _where: "message_id = '\(row["message_id"]  as? String ?? "")'")
                                                } catch {
                                                    rollback.pointee = true
                                                    print("Access database error: \(error.localizedDescription)")
                                                }
                                            })
                                        }
                                    } else {
                                        let second = 60 - second
                                        listTimerCredential[row["message_id"]  as? String ?? ""] = second
                                    }
                                } else {
                                    SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: row["message_id"]  as? String ?? "")
                                    listTimerCredential[row["message_id"]  as? String ?? ""] = 60
                                }
                            }
                        }
                        row[TypeDataMessage.is_call_center] = cursorData.string(forColumnIndex: 20)
                        row[TypeDataMessage.call_center_id] = cursorData.string(forColumnIndex: 21)
                        row[TypeDataMessage.opposite_pin] = cursorData.string(forColumnIndex: 22)
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["video_id"]  as? String ?? "")
                            let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["file_id"]  as? String ?? "")
                            if ((row["video_id"]  as? String ?? "") != "") {
                                if FileManager.default.fileExists(atPath: videoURL.path) || FileEncryption.shared.isSecureExists(filename: row["video_id"]  as? String ?? ""){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            } else {
                                if FileManager.default.fileExists(atPath: fileURL.path) || FileEncryption.shared.isSecureExists(filename: row["file_id"]  as? String ?? ""){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            }
                        }
                        row["chat_date"] = chatDate(stringDate: row["server_date"]  as? String ?? "")
                        
                        let isCollageCandidate = row["image_id"] != nil
                            && !(row["image_id"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && (row["message_text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && (row["reff_id"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && (row["read_receipts"] as? String ?? "") != "8"
                        if isCollageCandidate {
                            // A collage is one person's unbroken run of images.
                            //
                            // Fix: this used to ask whether the row *before this one* came from
                            // the same person, whoever they were. A run beginning right after
                            // somebody else's message therefore failed on its own first image,
                            // which was left out and drawn on its own - five images sent
                            // together arrived as one loose image and a collage of four. What
                            // decides the group is the run itself, so the comparison is against
                            // the images already collected, and an empty collection starts a new
                            // run whatever came before it.
                            let breaksRun: Bool
                            if let last = tempImages.last {
                                let minutesApart = getSecondsDifferenceFromTwoDates(
                                    start: Date(milliseconds: Int64(last.time) ?? 0),
                                    end: Date(milliseconds: Int64(row["server_date"] as? String ?? "") ?? 0)) / 60
                                breaksRun = (last.dataMessage["f_pin"] as? String ?? "") != (row["f_pin"] as? String ?? "")
                                    || minutesApart >= 11
                                    || tempImages.count >= EditorGroup.maximumImagesInCollage
                            } else {
                                breaksRun = false
                            }
                            if breaksRun {
                                closeImageGroup(&tempImages, loaded: &loaded)
                            }
                            tempImages.append(ImageGrouping(messageId: row["message_id"]  as? String ?? "", thumbId: row["thumb_id"]  as? String ?? "", imageId: row["image_id"]  as? String ?? "", status: row["status"]  as? String ?? "", time: row["server_date"]  as? String ?? "", lPin: row["l_pin"]  as? String ?? "", dataMessage: row, dataPerson: [:], dataGroup: dataGroup, dataTopic: dataTopic))
                        } else {
                            closeImageGroup(&tempImages, loaded: &loaded)
                        }
                        if marksFirstAsUnread && idxOff == 0 {
                            self.markerCounter = row["message_id"] as? String
                        }
                        loaded.append(row)
                        idxOff+=1
                    }
    //                if isHistoryCC {
    //                    dataMessages.remove(at: 0)
    //                }
                    closeImageGroup(&tempImages, loaded: &loaded)
                    cursorData.close()
                    // A message deleted from the middle of the conversation shifts every
                    // offset after it, so a page read later can overlap what is already on
                    // screen. Cheap insurance against showing the same message twice.
                    if !self.dataMessages.isEmpty {
                        let known = Set(self.dataMessages.compactMap { $0["message_id"] as? String })
                        loaded.removeAll { known.contains($0["message_id"] as? String ?? "") }
                    }
                    if prepend {
                        self.dataMessages.insert(contentsOf: loaded, at: 0)
                        self.mergeImageRunAcrossSeam(at: loaded.count)
                    } else {
                        let seam = self.dataMessages.count
                        self.dataMessages.append(contentsOf: loaded)
                        self.mergeImageRunAcrossSeam(at: seam)
                    }
                    // chatDate() appends the day headers as it meets them, which is the right
                    // order only while messages arrive newest-last. Rebuilding from the list
                    // itself is correct whichever end the batch went on.
                    self.rebuildDataDates()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    /// The day headers, in the order the messages themselves are in.
    private func rebuildDataDates() {
        var seen = Set<String>()
        dataDates = dataMessages.compactMap { $0["chat_date"] as? String }.filter { seen.insert($0).inserted }
    }

    /// Reads the newest page of the conversation - enough to fill the screen, and never less
    /// than everything still unread, because the unread marker and the read receipts sent on
    /// open both need those messages in hand.
    private func loadInitialMessages() {
        let total = countMessages()
        let pageSize = max(EditorGroup.initialMessagePageSize, Int64(counter) + 10)
        loadedOffset = max(0, total - pageSize)
        loadedCount = total - loadedOffset
        isWindowAtNewest = true
        getData(offset: loadedOffset, limit: loadedCount)
    }

    /// The oldest message the reader has not seen yet: the one `unread` places from the
    /// newest.
    ///
    /// Read from the database rather than counted back through dataMessages. That list has
    /// grouped image collages taken out of it, so counting back through it lands on the wrong
    /// message - and when the unread block contains a collage the count comes up short and no
    /// marker is placed at all.
    private func unreadMarkerMessageId(unread: Int) -> String? {
        guard unread > 0 else {
            return nil
        }
        let position = countMessages() - Int64(unread)
        guard position >= 0 else {
            return nil
        }
        var messageId: String?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT message_id FROM MESSAGE where \(self.messageWhereClause()) order by server_date asc LIMIT 1 OFFSET \(position)"), cursor.next() {
                messageId = cursor.string(forColumnIndex: 0)
                cursor.close()
            }
        })
        return messageId
    }

    /// Whether there are older messages left in the database.
    private var hasOlderMessages: Bool {
        return loadedOffset > 0
    }

    /// Re-derives where the loaded window sits from the messages actually in hand.
    ///
    /// Offsets into the conversation move whenever a message is deleted, and the deletion can
    /// happen anywhere - from this screen, from another device. Asking the database where the
    /// oldest and newest loaded messages are now costs two counts and makes every page that
    /// follows line up, instead of tracking every place a message can disappear.
    private func refreshWindowBounds() {
        guard let oldest = dataMessages.first(where: { !(($0["message_id"] as? String) ?? "").isEmpty })?["message_id"] as? String,
              let newest = dataMessages.last(where: { !(($0["message_id"] as? String) ?? "").isEmpty })?["message_id"] as? String,
              let oldestPosition = messagePosition(messageId: oldest),
              let newestPosition = messagePosition(messageId: newest) else {
            return
        }
        // A window that is not contiguous in the database - a message sent while the reader
        // was looking at an older part sits at the end of the list but at the end of the
        // conversation in the database - would come back as a nonsense span. Better to keep
        // the bounds already held than to trust that.
        guard newestPosition + 1 - oldestPosition <= Int64(dataMessages.count) + 200 else {
            return
        }
        loadedOffset = oldestPosition
        loadedCount = max(0, newestPosition + 1 - oldestPosition)
    }

    /// Pulls in the next page of older messages and puts the reader back where they were.
    ///
    /// The rows are inserted above what is on screen, so without pinning the view to a known
    /// message the content would jump by the height of everything just added.
    private func loadOlderMessages() {
        guard hasOlderMessages, !isLoadingOlderMessages else {
            return
        }
        if let lastEmptyOlderPage = lastEmptyOlderPage, Date().timeIntervalSince(lastEmptyOlderPage) < 0.5 {
            return
        }
        isLoadingOlderMessages = true
        defer { isLoadingOlderMessages = false }
        refreshWindowBounds()
        guard hasOlderMessages else {
            return
        }
        let rowsBeforeLoad = dataMessages.count

        let anchorIndexPath = tableChatView.indexPathsForVisibleRows?.first
        var anchorMessageId: String?
        var anchorDistanceFromTop: CGFloat = 0
        if let anchorIndexPath = anchorIndexPath {
            anchorMessageId = message(at: anchorIndexPath)?["message_id"] as? String
            anchorDistanceFromTop = tableChatView.rectForRow(at: anchorIndexPath).minY - tableChatView.contentOffset.y
        }

        let newOffset = max(0, loadedOffset - EditorGroup.olderMessagePageSize)
        let batch = loadedOffset - newOffset
        getData(offset: newOffset, limit: batch, prepend: true)
        loadedOffset = newOffset
        loadedCount += batch

        lastEmptyOlderPage = dataMessages.count == rowsBeforeLoad ? Date() : nil

        UIView.performWithoutAnimation {
            tableChatView.reloadData()
            tableChatView.layoutIfNeeded()
        }
        if let anchorMessageId = anchorMessageId, let restored = indexPath(forMessageId: anchorMessageId) {
            let target = tableChatView.rectForRow(at: restored).minY - anchorDistanceFromTop
            tableChatView.setContentOffset(CGPoint(x: 0, y: target), animated: false)
        }
    }

    /// Throws away what is loaded and reads a page around a position instead. Used when a
    /// jump lands so far from the window that reading the gap would cost more than the whole
    /// screen is worth.
    private func replaceWindow(around position: Int64) {
        let total = countMessages()
        let newOffset = max(0, min(position - EditorGroup.jumpWindowSize / 2, max(0, total - EditorGroup.jumpWindowSize)))
        let limit = max(0, min(EditorGroup.jumpWindowSize, total - newOffset))
        dataMessages.removeAll()
        dataDates.removeAll()
        groupImages.removeAll()
        measuredRowHeights.removeAll()
        // Rows the reader was last on are gone with the window; anything still holding that
        // index would be reading into a list that no longer has it.
        currentIndexpath = nil
        loadedOffset = newOffset
        loadedCount = limit
        getData(offset: newOffset, limit: limit)
        isWindowAtNewest = newOffset + limit >= total
        tableChatView.reloadData()
    }

    /// Takes the reader back to the end of the conversation.
    private func jumpToNewestPage() {
        let total = countMessages()
        let newOffset = max(0, total - EditorGroup.initialMessagePageSize)
        dataMessages.removeAll()
        dataDates.removeAll()
        groupImages.removeAll()
        measuredRowHeights.removeAll()
        // Rows the reader was last on are gone with the window; anything still holding that
        // index would be reading into a list that no longer has it.
        currentIndexpath = nil
        loadedOffset = newOffset
        loadedCount = total - newOffset
        getData(offset: newOffset, limit: loadedCount)
        isWindowAtNewest = true
        tableChatView.reloadData()
        // Back at the end means everything counted while away has now been seen.
        if counter != 0 {
            counter = 0
            updateCounter(counter: counter)
        }
        removeScrollToBottomButton()
    }

    /// Reads the next page of newer messages onto the end of the window. Only ever needed
    /// after a jump has moved the window off the end of the conversation.
    ///
    /// Appending below does not move what is on screen, so unlike reading older messages
    /// there is no scroll position to put back - and no contentOffset to assign, which is
    /// what makes this direction smooth.
    private func loadNewerMessages() {
        guard !isWindowAtNewest, !isLoadingNewerMessages else {
            return
        }
        isLoadingNewerMessages = true
        defer { isLoadingNewerMessages = false }
        let total = countMessages()
        let nextOffset = loadedOffset + loadedCount
        guard nextOffset < total else {
            isWindowAtNewest = true
            return
        }
        let batch = min(EditorGroup.olderMessagePageSize, total - nextOffset)
        let rowsBefore = dataMessages.count
        getData(offset: nextOffset, limit: batch)
        loadedCount += batch
        isWindowAtNewest = loadedOffset + loadedCount >= total
        // A page that brought nothing back would leave the trigger below satisfied and ask
        // again immediately. Treating it as the end stops that dead; onCheckNewMessages puts
        // back anything that really was missing.
        if dataMessages.count == rowsBefore {
            isWindowAtNewest = true
        }
        tableChatView.reloadData()
    }

    /// The messages matching `text`, newest first.
    ///
    /// The filter mirrors what the list used to do in memory: notification rows and messages
    /// deleted for everyone are not results. Apostrophes are escaped - a search for "don't"
    /// used to be pasted straight into the SQL.
    private func searchMatches(for text: String) -> [String] {
        let needle = text.replacingOccurrences(of: "'", with: "''")
        guard !needle.isEmpty else {
            return []
        }
        var ids: [String] = []
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            let query = """
                        SELECT message_id FROM MESSAGE where \(self.messageWhereClause())
                        AND message_text LIKE '%\(needle)%'
                        AND message_id NOT LIKE '%NTFPIN\\_%' ESCAPE '\\'
                        AND ifnull(lock, '') <> '1'
                        order by server_date desc
                        """
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query) {
                while cursor.next() {
                    if let id = cursor.string(forColumnIndex: 0), !id.isEmpty {
                        ids.append(id)
                    }
                }
                cursor.close()
            }
        })
        return ids
    }

    /// Reads the next page of older messages while nothing is moving.
    ///
    /// This is where paging is supposed to happen. Reading them mid-scroll means assigning
    /// contentOffset to keep the reader in place, and UIScrollView treats that assignment as
    /// "someone else is driving now" and drops the deceleration - the scroll stops dead. While
    /// the list is standing still there is no deceleration to lose, so the same work is
    /// invisible. Called when a scroll settles, which keeps the buffer above the reader
    /// refilled between flings.
    private func prefetchOlderMessagesIfIdle() {
        guard !isInitialLoading, hasOlderMessages else {
            return
        }
        guard !tableChatView.isDragging, !tableChatView.isDecelerating else {
            return
        }
        // Only worth doing when the end of what is loaded is within a few screens; further
        // away there is nothing to gain by reading more.
        guard tableChatView.contentOffset.y < tableChatView.frame.height * 3 else {
            return
        }
        loadOlderMessages()
    }

    /// Makes sure a particular message is in memory, pulling in everything between it and
    /// what is already loaded. Jumping to a search hit, a reply or a pinned message all land
    /// here - before paging they could count on the whole chat being loaded.
    @discardableResult
    private func ensureMessageLoaded(messageId: String) -> Bool {
        if dataMessages.contains(where: { $0["message_id"] as? String == messageId }) {
            return true
        }
        guard let position = messagePosition(messageId: messageId) else {
            return false
        }
        if position >= loadedOffset, position < loadedOffset + loadedCount {
            // Inside the window but not a row of its own - an image swallowed by a collage.
            return false
        }
        if position < loadedOffset, loadedOffset - position <= EditorGroup.maxBridgedMessages {
            let newOffset = max(0, position - 10)
            let batch = loadedOffset - newOffset
            getData(offset: newOffset, limit: batch, prepend: true)
            loadedOffset = newOffset
            loadedCount += batch
            tableChatView.reloadData()
        } else {
            // Too far to bridge - and it can also be newer than the window, if an earlier
            // jump left the window off the end.
            replaceWindow(around: position)
        }
        return dataMessages.contains(where: { $0["message_id"] as? String == messageId })
    }

    /// The message a row is showing. Walks rather than filters: this is called for every row
    /// the table estimates, and building a throwaway array each time is the expensive part.
    private var bubbleSwipe: ChatBubbleSwipe?

    /// Whether this row can be pulled, in that direction, right now. Mirrors what the long-press
    /// menu offers: no replying to a message that failed, was deleted, or is a form or a
    /// confidential one, and info only for messages this device sent.
    private func canSwipeBubble(at indexPath: IndexPath, direction: ChatBubbleSwipe.Direction) -> Bool {
        guard !copySession, !forwardSession, !deleteSession, !summarizeSession, !isHistoryCC, !removed else {
            return false
        }
        guard let message = message(at: indexPath) else {
            return false
        }
        let status = message[TypeDataMessage.status] as? String ?? ""
        let lock = message["lock"] as? String ?? ""
        let scope = message[TypeDataMessage.message_scope_id] as? String ?? ""
        guard status != "0", lock != "1", lock != "2",
              scope != MessageScope.CALL, scope != MessageScope.MISSED_CALL else {
            return false
        }
        switch direction {
        case .reply:
            return scope != "18" && (message["credential"] as? String ?? "") != "1"
        case .info:
            return (message["f_pin"] as? String ?? "") == User.getMyPin()
        }
    }

    private func performBubbleSwipe(at indexPath: IndexPath, direction: ChatBubbleSwipe.Direction) {
        switch direction {
        case .reply:
            handleReply(indexPath: indexPath)
        case .info:
            guard let message = message(at: indexPath) else {
                return
            }
            let messageInfoVC = MessageInfo()
            messageInfoVC.data = message
            messageInfoVC.dataGroup = dataGroup
            messageInfoVC.isPersonal = false
            navigationController?.pushViewController(messageInfoVC, animated: true)
        }
    }

    private func message(at indexPath: IndexPath) -> [String: Any?]? {
        guard indexPath.section >= 0, indexPath.section < dataDates.count, indexPath.row >= 0 else {
            return nil
        }
        let date = dataDates[indexPath.section]
        var row = 0
        for message in dataMessages where message["chat_date"] as? String ?? "" == date {
            if row == indexPath.row {
                return message
            }
            row += 1
        }
        return nil
    }

    /// Where a message sits in the table right now.
    private func indexPath(forMessageId messageId: String) -> IndexPath? {
        // A message gathered into a collage is no longer a row of its own; the row that draws it
        // is the collage's. Without this, an anchor held across a page load - which is how the
        // scroll position is kept - would be lost the moment that message joined a collage.
        var messageId = messageId
        if !dataMessages.contains(where: { $0["message_id"] as? String == messageId }),
           let parent = groupImages.first(where: { _, images in
               images.contains(where: { $0.messageId == messageId })
           })?.key {
            messageId = parent
        }
        guard let message = dataMessages.first(where: { $0["message_id"] as? String == messageId }),
              let section = dataDates.firstIndex(of: message["chat_date"] as? String ?? ""),
              let row = messages(onDate: dataDates[section])
                  .firstIndex(where: { $0["message_id"] as? String == messageId }) else {
            return nil
        }
        return IndexPath(row: row, section: section)
    }

    /// Opens the chat at the "Unread Messages" marker: the marker sits at the top of the
    /// screen and the first message the reader has not seen starts directly under it.
    ///
    /// Fix: this used to be a single `scrollToRow(at: .bottom)` fired from a
    /// `DispatchQueue.main.async` right after `reloadData()`, and both halves of that were
    /// wrong. `.bottom` puts the marker row's *bottom* edge at the bottom of the screen, so a
    /// long first unread message was shown by its tail with the marker itself scrolled off
    /// above - the "lands in the middle of the message" case. And running before the table had
    /// laid out meant the offset was worked out from estimated row heights (72pt for every row
    /// never displayed), so where it actually ended up depended on how wrong those estimates
    /// happened to be - the "sometimes it is not there" case. Running again on every layout
    /// pass fixes both: by the time the rows around the marker have been built, their heights
    /// are measured ones, and each pass corrects what the previous pass got wrong until the
    /// row is exactly where it belongs.
    private func applyPendingUnreadMarkerScroll() {
        guard let marker = pendingUnreadMarkerScroll else {
            return
        }
        guard tableChatView.numberOfSections > 0, tableChatView.bounds.height > 0,
              let indexPath = indexPath(forMessageId: marker),
              indexPath.section < tableChatView.numberOfSections,
              indexPath.row < tableChatView.numberOfRows(inSection: indexPath.section) else {
            // Nothing to aim at yet - the table may not have any rows this pass. Keep the
            // request; the pass budget still runs down so this cannot hang around forever.
            remainingUnreadMarkerScrollPasses -= 1
            if remainingUnreadMarkerScrollPasses <= 0 {
                pendingUnreadMarkerScroll = nil
            }
            return
        }
        remainingUnreadMarkerScrollPasses -= 1
        let rowRect = tableChatView.rectForRow(at: indexPath)
        let topInset = tableChatView.adjustedContentInset.top
        // A plain table pins the date header over the top of the visible area, so the row has
        // to start below it - otherwise the header covers the marker it was scrolled to.
        let headerHeight = tableChatView.rectForHeader(inSection: indexPath.section).height
        let lowest = -topInset
        let highest = max(lowest, tableChatView.contentSize.height + tableChatView.adjustedContentInset.bottom - tableChatView.bounds.height)
        let desired = min(max(rowRect.minY - topInset - headerHeight, lowest), highest)
        if abs(tableChatView.contentOffset.y - desired) > 0.5 {
            tableChatView.setContentOffset(CGPoint(x: tableChatView.contentOffset.x, y: desired), animated: false)
        } else {
            // Already exactly there, and the heights it was worked out from are the measured
            // ones by now - nothing left to correct.
            remainingUnreadMarkerScrollPasses = 0
        }
        if remainingUnreadMarkerScrollPasses <= 0 {
            pendingUnreadMarkerScroll = nil
        }
    }

    /// Every pinned message, including ones older than the loaded window - the banner shows
    /// what the conversation has pinned, not what happens to be in memory.
    private func pinnedMessagesForBanner() -> [[String: Any?]] {
        var pinned = dataMessages.filter { $0[TypeDataMessage.is_pinned] as? String ?? "0" != "0" }
        guard hasOlderMessages else {
            return pinned
        }
        var known = Set(pinned.compactMap { $0[TypeDataMessage.message_id] as? String })
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            let query = "SELECT message_id, f_pin, message_text, server_date, is_pinned, file_id, image_id, video_id, audio_id, gif_id FROM MESSAGE where \(self.messageWhereClause()) AND is_pinned <> '0' AND is_pinned IS NOT NULL order by server_date asc"
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query) {
                while cursor.next() {
                    let messageId = cursor.string(forColumnIndex: 0) ?? ""
                    if messageId.isEmpty || known.contains(messageId) {
                        continue
                    }
                    known.insert(messageId)
                    var row: [String: Any?] = [:]
                    row["message_id"] = messageId
                    row["f_pin"] = cursor.string(forColumnIndex: 1)
                    row["message_text"] = cursor.string(forColumnIndex: 2)
                    row["server_date"] = cursor.string(forColumnIndex: 3)
                    row[TypeDataMessage.is_pinned] = cursor.string(forColumnIndex: 4)
                    row["file_id"] = cursor.string(forColumnIndex: 5)
                    row["image_id"] = cursor.string(forColumnIndex: 6)
                    row["video_id"] = cursor.string(forColumnIndex: 7)
                    row["audio_id"] = cursor.string(forColumnIndex: 8)
                    row[TypeDataMessage.gif_id] = cursor.string(forColumnIndex: 9)
                    row["isSelected"] = false
                    pinned.append(row)
                }
                cursor.close()
            }
        })
        return pinned
    }

    func getSecondsDifferenceFromTwoDates(start: Date, end: Date) -> Int {
        let diff = Int(end.timeIntervalSince1970 - start.timeIntervalSince1970)

        let hours = diff / 3600
        let seconds = (diff - hours * 3600)
        return seconds
    }
    
    private func getRealStatus(messageId: String) -> String {
        var status = "-1"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status, f_pin FROM MESSAGE_STATUS WHERE message_id='\(messageId)'") {
                    var listStatus: [Int] = []
                    while cursorStatus.next() {
                        listStatus.append(Int(cursorStatus.string(forColumnIndex: 0)!)!)
                    }
                    cursorStatus.close()
                    status = "\(listStatus.min() ?? -1)"
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return status
    }
    
    // Building a DateFormatter costs about as much as reading a message row, and this is
    // called once per message. One formatter per format, built when first needed.
    private static var dayNameFormatter: DateFormatter?
    private static var dayDateFormatter: DateFormatter?

    private static func chatDateFormatter(format: String, cached: inout DateFormatter?) -> DateFormatter {
        if let cached = cached, cached.dateFormat == format {
            return cached
        }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
        if lang == "id" {
            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
        }
        cached = formatter
        return formatter
    }

    private func chatDate(stringDate: String) -> String {
        let date = Date(milliseconds: Int64(stringDate) ?? 0)
        let calendar = Calendar.current
        if (calendar.isDateInToday(date)) {
            if !dataDates.contains("Today".localized()){
                dataDates.append("Today".localized())
            }
            return "Today".localized()
        } else {
            let startOfNow = calendar.startOfDay(for: Date())
            let startOfTimeStamp = calendar.startOfDay(for: date)
            let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
            let day = -(components.day!)
            if day == 1{
                if !dataDates.contains("Yesterday".localized()){
                    dataDates.append("Yesterday".localized())
                }
                return "Yesterday".localized()
            } else if day < 7 {
                let formatter = EditorGroup.chatDateFormatter(format: "EEEE", cached: &EditorGroup.dayNameFormatter)
                let stringFormat = formatter.string(from: date)
                if !dataDates.contains(stringFormat){
                    dataDates.append(stringFormat)
                }
                return stringFormat
            } else {
                let formatter = EditorGroup.chatDateFormatter(format: "EE, dd MMM", cached: &EditorGroup.dayDateFormatter)
                let stringFormat = formatter.string(from: date as Date)
                if !dataDates.contains(stringFormat){
                    dataDates.append(stringFormat)
                }
                return stringFormat
            }
        }
    }
    
    private func changeAppBar() {
        let viewAppBar = UIView()
        viewAppBar.frame.size = CGSize(width: self.view.frame.size.width, height: 44)
        
        if !isSearching {
            let imageProfile = UIImageView(frame: CGRect(x: 0, y: 7, width: 30, height: 30))
            imageProfile.circle()
            imageProfile.clipsToBounds = true
            viewAppBar.addSubview(imageProfile)
            let pictureImage = dataGroup["image_id"] ?? ""
            if (pictureImage  as? String ?? "" != "" && pictureImage != nil) {
                imageProfile.setImage(name: pictureImage!  as? String ?? "")
                imageProfile.contentMode = .scaleAspectFill
            } else {
                imageProfile.image = UIImage(systemName: "person.3")
                imageProfile.contentMode = .scaleAspectFit
                imageProfile.backgroundColor = .lightGray
            }
            var widthTitle = viewAppBar.frame.size.width - 180
            if isHistoryCC {
                widthTitle = viewAppBar.frame.size.width - 150
            }
            let titleNavigation = UILabel(frame: CGRect(x: 35, y: 0, width: widthTitle, height: 44))
            viewAppBar.addSubview(titleNavigation)
            if (dataGroup["official"]  as? String ?? "" == "1") {
                if !isHistoryCC {
                    titleNavigation.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(dataGroup["f_name"]!!) (\(dataTopic["title"]!!))", size: 15, y: -4)
                } else {
                    titleNavigation.text = (dataGroup["f_name"] as? String)! + " " + "Contact Center".localized()
                }
            } else {
                titleNavigation.text = (dataGroup["f_name"] as? String ?? "") + " (\(dataTopic["title"] as? String ?? ""))"
            }
            titleNavigation.textColor = .white
            titleNavigation.font = UIFont.systemFont(ofSize: 12 + offset()).bold
            
            navigationItem.titleView = viewAppBar
            titleText = titleNavigation.text
            previewHeaderLabel?.text = titleText
        } else {
            searchBar = UISearchBar()
            searchBar.autocapitalizationType = .none
            searchBar.delegate = self
            searchBar.searchTextField.tintColor = .mainColor
            searchBar.searchTextField.textColor = .black
//            searchBar.updateHeight(height: 36, radius: 18)
            searchBar.showsCancelButton = false
//            searchBar.setMagnifyingGlassColorTo(color: .white)
            searchBar.setImage(UIImage(), for: .search, state: .normal)
            searchBar.setPositionAdjustment(UIOffset(horizontal: 10, vertical: 0), for: .search)
            // 36pt is the height iOS gives a search field, and it lines the bottom of the
            // field up with the Cancel button next to it - the old 30pt bitmap left it sitting
            // noticeably short. The colour is the one that bitmap was painted with, so nothing
            // about the look changes; only its size and the shape of its corners.
            //
            // Both themes get the light fill on purpose: the text in this field is black, and
            // the dark asset this used to draw is very nearly transparent, which left black
            // text on a near-black bar.
            searchBar.setSearchFieldStyle(height: 36, backgroundColor: UIColor(red: 248.0 / 255.0, green: 252.0 / 255.0, blue: 254.0 / 255.0, alpha: 1.0))
            navigationItem.titleView = searchBar
            self.definesPresentationContext = true
        }
        
        if copySession || forwardSession || deleteSession || summarizeSession || isSearching {
            navigationItem.hidesBackButton = true
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            navigationItem.hidesBackButton = false
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
        
        viewAppBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(seeProfileTapped)))
    }
    
    // `useFakeProgress` - the upload path only hears from the server a couple of times
    // per file, so it pads what it shows to keep the ring moving. A download reports
    // real bytes continuously and must not be padded, or it would jump straight to
    // full on its second callback (maxFakeProgMultip is 2).
    func updateProgress(_ data: [AnyHashable: Any], useFakeProgress: Bool = true){
        var isImage = false
        var idx = dataMessages.lastIndex(where: { $0["video_id"] as? String == data["name"] as? String || $0["video_id"] as? String == data["video_id"] as? String })
        if (idx == nil) {
            idx = dataMessages.lastIndex(where: { $0["image_id"] as? String == data["name"] as? String || $0["image_id"] as? String == data["image_id"] as? String })
            isImage = true
        }
        if (idx != nil) {
            let section = dataDates.firstIndex(of: dataMessages[idx!]["chat_date"]  as? String ?? "")
            if section == nil {
                return
            }
            let row = messages(onDate: dataDates[section!]).firstIndex(where: { $0["message_id"] as? String == dataMessages[idx!]["message_id"] as? String})
            if row == nil {
                return
            }
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: row!, section: section!)
                if useFakeProgress, self.fakeProgMultip < self.maxFakeProgMultip {
                    self.fakeProgMultip = self.fakeProgMultip + 1
                }
                let fakeProgress = useFakeProgress ? Double(self.fakeProgMultip) * (100.0 / Double(self.maxFakeProgMultip)) : 0.0
                let progress = max(data["progress"] as? Double ?? 0.0, fakeProgress)
                if(data["progress"] as? Double ?? 0.0 == 100.0){
                    self.fakeProgMultip = 0
                }
                if let cell = self.tableChatView.cellForRow(at: indexPath) {
                    for view in cell.contentView.subviews {
                        if !(view is UITextView) && !(view is UIImageView) {
                            for viewInContainer in view.subviews {
                                if viewInContainer is UIImageView {
                                    if viewInContainer.subviews.count == 0 {
                                        return
                                    }
                                    var containerView : UIView?
                                    if (isImage) {
                                        if viewInContainer.subviews[0] is UIVisualEffectView  && viewInContainer.subviews.count > 1 {
                                            containerView = viewInContainer.subviews[1]
                                        } else {
                                            containerView = viewInContainer.subviews[0]
                                        }
                                    } else if viewInContainer.subviews.count > 1 {
                                        if viewInContainer.subviews[0] is UIVisualEffectView && viewInContainer.subviews.count > 2 {
                                            containerView = viewInContainer.subviews[2]
                                        } else {
                                            containerView = viewInContainer.subviews[1]
                                        }
                                    }
                                    // Fix: this read the second sublayer by position, and
                                    // `sublayers` is a bridged NSArray - so a container holding
                                    // only one raised NSRangeException rather than returning nil,
                                    // and the app went down. The ring is drawn as a track and a
                                    // progress shape on top of it, so the last shape layer is the
                                    // one to move, however many layers the view happens to carry.
                                    if let loading = containerView?.layer.sublayers?
                                        .compactMap({ $0 as? CAShapeLayer }).last {
                                        loading.strokeEnd = CGFloat(progress / 100)
                                        if (progress == 100.0) {
                                            self.dataMessages[idx!]["progress"] = progress
                                            self.tableChatView.reloadRows(at: [indexPath], with: .none)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            idx = dataMessages.lastIndex(where: { $0["file_id"] as? String == data["name"] as? String || $0["file_id"] as? String == data["file_id"] as? String })
            if (idx != nil) {
                let section = dataDates.firstIndex(of: dataMessages[idx!]["chat_date"]  as? String ?? "")
                if section == nil {
                    return
                }
                let row = messages(onDate: dataDates[section!]).firstIndex(where: { $0["message_id"] as? String == dataMessages[idx!]["message_id"] as? String})
                if row == nil {
                    return
                }
                DispatchQueue.main.async {
                    let indexPath = IndexPath(row: row!, section: section!)
                    if useFakeProgress, self.fakeProgMultip < self.maxFakeProgMultip {
                        self.fakeProgMultip = self.fakeProgMultip + 1
                    }
                    let fakeProgress = useFakeProgress ? Double(self.fakeProgMultip) * (100.0 / Double(self.maxFakeProgMultip)) : 0.0
                    let progress = max(data["progress"] as? Double ?? 0.0, fakeProgress)
                    if(data["progress"] as? Double ?? 0.0 == 100.0){
                        self.fakeProgMultip = 0
                    }
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        for view in cell.contentView.subviews {
                            if !(view is UITextView) && !(view is UIImageView) {
                                for viewSubviews in view.subviews {
                                    if !(viewSubviews is UITextView) {
                                        for viewInContainer in viewSubviews.subviews {
                                            if !(viewInContainer is UITextView) && !(viewInContainer is UIImageView) {
                                                if let cont = viewInContainer.layer.sublayers {
                                                    if cont.count < 2 {
                                                        return
                                                    }
                                                }
                                                if let layers = viewInContainer.layer.sublayers {
                                                    if let loading = layers [1] as? CAShapeLayer {
                                                        loading.strokeEnd = CGFloat(progress / 100)
                                                        if (progress == 100.0) {
                                                            self.dataMessages[idx!]["progress"] = progress
                                                            self.tableChatView.reloadRows(at: [indexPath], with: .none)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func onDownloadChat(notification: NSNotification) {
        guard let data = notification.userInfo,
              let progress = data["progress"] as? Double,
              progress >= 0 else {
            // Negative means the download failed; leave the ring where it stopped rather
            // than driving it backwards.
            return
        }
        if progress >= 100, let name = data["name"] as? String {
            // Covers every kind of attachment, including the ones that never draw a ring
            // (audio, thumbnails, gifs) - their cell just needs redrawing now the file is
            // on disk, whichever screen it was that fetched it.
            reloadMessageRow(withFileNamed: name)
            return
        }
        // The ring cellForRow draws carries a name, so it can be found on whatever cell is
        // showing the message right now - no guessing at subview positions, and nothing to
        // do at all when the message is scrolled out of view (cellForRow will draw it at the
        // right progress when it comes back).
        if let name = data["name"] as? String {
            updateTransferSize(forFileNamed: name)
            if let indexPath = indexPathForMessage(withFileNamed: name),
               let cell = tableChatView.cellForRow(at: indexPath),
               ChatTransferRing.setProgress(progress, in: cell) {
                return
            }
        }
        // Bubbles whose ring predates all this - file attachments - are still driven the way
        // uploads are.
        updateProgress(data, useFakeProgress: false)
    }

    @objc func onUploadChat(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        if let name = data["name"] as? String {
            updateTransferSize(forFileNamed: name)
        }
        updateProgress(data)
    }
    
    @objc func  onCheckNewMessages(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            // Fix: this used to compare dataMessages.count against `int(forColumnIndex: 0)` of
            // a query that selects message_id, not a count - so the number it compared against
            // was whatever that text parsed to. It now asks the database how many messages the
            // conversation has, and works out what is missing from the loaded window rather
            // than from the row count (image collages take rows out of that list).
            // Only meaningful while the window ends at the newest message; when a jump has
            // moved it away, new messages are picked up on the way back down.
            guard isWindowAtNewest else {
                return
            }
            let countMessagesNow = countMessages()
            refreshWindowBounds()
            let loadedThrough = loadedOffset + loadedCount
            if loadedThrough < countMessagesNow {
                let missing = countMessagesNow - loadedThrough
                self.counter = Int(missing)
                getData(offset: loadedThrough, limit: missing, marksFirstAsUnread: true)
                loadedCount += missing
                tableChatView.reloadData()
                if !self.indicatorCounterBSTB.isDescendant(of: self.view) && !self.buttonScrollToBottom.isDescendant(of: self.view) {
                    let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.markerCounter })
                    if indexMessage != nil {
                        let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "")
                        let row = self.messages(onDate: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                        self.tableChatView.safeScrollToRow(at: IndexPath(row: row!, section: section!), at: .top, animated: true)
                    }
                } else if self.buttonScrollToBottom.isDescendant(of: self.view) {
                    DispatchQueue.main.async { [self] in
                        if !self.indicatorCounterBSTB.isDescendant(of: self.view) {
                            addCounterAtButttonScrollToBottom()
                        } else {
                            self.labelCounter.text = "\(counter)"
                        }
                    }
                } else {
                    DispatchQueue.main.async { [self] in
                        addButtonScrollToBottom()
                        addCounterAtButttonScrollToBottom()
                    }
                }
            }
        }
    }
    
    @objc func onUpdatedMessage(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            let messageId = data["message_id"]  as? String ?? ""
            let messageIdNotif = data["message_id_notif"]  as? String ?? ""
            let isPinned = data["is_pinned"]  as? String ?? ""
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String ?? "" == messageId})
            if idx != nil{
                self.dataMessages[idx!][TypeDataMessage.is_pinned] = isPinned
                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                let row = self.messages(onDate: self.dataMessages[idx!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[idx!]["message_id"]  as? String ?? "" })
                if row != nil && section != nil  {
                    DispatchQueue.main.async {
                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                    }
                }
                let dataMessagesPin = self.pinnedMessagesForBanner()
                self.pinAllMessages(dataMessages: dataMessagesPin)
                
                if !messageIdNotif.isEmpty {
                    self.appendNewMessage(messageId: messageIdNotif)
                }
            }
        }
    }
    
    @objc func onReceiveMessage(notification: NSNotification) {
        DispatchQueue.main.async {
            // FIX 1: Guard userInfo
            guard let data = notification.userInfo,
                  let dataMessage = data["message"] as? TMessage else {
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: "reloadTabChats"),
                    object: nil,
                    userInfo: nil
                )
                return
            }
            
            let chatData = dataMessage.mBodies
            let group_id = self.dataGroup["group_id"] as? String ?? ""
            let chat_id = self.dataTopic["chat_id"] as? String ?? ""
            
            guard chatData[CoreMessage_TMessageKey.L_PIN] == group_id,
                  (chatData[CoreMessage_TMessageKey.CHAT_ID] ?? "") == chat_id else {
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: "reloadTabChats"),
                    object: nil,
                    userInfo: nil
                )
                return
            }
            
            // FIX 2: Guard required fields sebelum digunakan
            guard let fPin = chatData[CoreMessage_TMessageKey.F_PIN],
                  let messageScopeId = chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID],
                  let messageId = chatData[CoreMessage_TMessageKey.MESSAGE_ID] else {
                return
            }
            
            // Update existing message
            if let idx = self.dataMessages.firstIndex(where: {
                $0[TypeDataMessage.message_id] as? String == chatData[CoreMessage_TMessageKey.MESSAGE_ID]
            }) {
                self.dataMessages[idx][TypeDataMessage.message_text] = chatData[CoreMessage_TMessageKey.MESSAGE_TEXT]
                if let lastEdit = chatData[CoreMessage_TMessageKey.LAST_EDIT] {
                    self.dataMessages[idx][TypeDataMessage.last_edit] = Int64(lastEdit)
                }
                self.dataMessages[idx][TypeDataMessage.status] = chatData[CoreMessage_TMessageKey.STATUS]
                
                let chatDate = self.dataMessages[idx]["chat_date"] as? String ?? ""
                if let section = self.dataDates.firstIndex(of: chatDate),
                   let row = self.dataMessages.filter({
                       $0["chat_date"] as? String ?? "" == chatDate
                   }).firstIndex(where: {
                       $0["message_id"] as? String == self.dataMessages[idx]["message_id"] as? String
                   }) {
                    self.tableChatView.reloadRows(
                        at: [IndexPath(row: row, section: section)],
                        with: .none
                    )
                }
                return
            }
            
            // A message arriving while the reader is looking at an older part of the chat
            // must not be spliced onto the end of a window that does not reach the newest
            // message. It is in the database; the scroll-to-bottom button is the way to it.
            guard self.isWindowAtNewest else {
                self.counter += 1
                if !self.buttonScrollToBottom.isDescendant(of: self.view) {
                    self.addButtonScrollToBottom()
                }
                if !self.indicatorCounterBSTB.isDescendant(of: self.view) {
                    self.addCounterAtButttonScrollToBottom()
                } else {
                    self.labelCounter.text = "\(self.counter)"
                }
                return
            }

            // Build new row
            var row: [String: Any?] = [:]
            row["message_id"] = messageId
            row["f_pin"] = fPin
            row["l_pin"] = chatData[CoreMessage_TMessageKey.L_PIN]
            row["message_scope_id"] = messageScopeId
            row["server_date"] = chatData[CoreMessage_TMessageKey.SERVER_DATE]
            row["status"] = chatData[CoreMessage_TMessageKey.STATUS]
            row["message_text"] = chatData[CoreMessage_TMessageKey.MESSAGE_TEXT]
            row["audio_id"] = chatData[CoreMessage_TMessageKey.AUDIO_ID] ?? ""
            row["gif_id"] = chatData[CoreMessage_TMessageKey.GIF_ID] ?? ""
            row["video_id"] = chatData[CoreMessage_TMessageKey.VIDEO_ID] ?? ""
            row["image_id"] = chatData[CoreMessage_TMessageKey.IMAGE_ID] ?? ""
            row["thumb_id"] = chatData[CoreMessage_TMessageKey.THUMB_ID] ?? ""
            row["chat_id"] = chatData[CoreMessage_TMessageKey.CHAT_ID] ?? ""
            row["file_id"] = chatData[CoreMessage_TMessageKey.FILE_ID] ?? ""
            row["read_receipts"] = chatData[CoreMessage_TMessageKey.READ_RECEIPTS] ?? ""
            row["credential"] = chatData[CoreMessage_TMessageKey.CREDENTIAL] ?? ""
            row["progress"] = 0.0
            row["attachment_flag"] = chatData[CoreMessage_TMessageKey.ATTACHMENT_FLAG]
            row["reff_id"] = chatData[CoreMessage_TMessageKey.REF_ID] ?? ""
            row["lock"] = ""
            row["is_stared"] = "0"
            row[TypeDataMessage.is_forwarded] = Int(chatData[CoreMessage_TMessageKey.IS_FORWARDED_MESSAGE] ?? "0")
            row[TypeDataMessage.spec_file] = chatData[CoreMessage_TMessageKey.ATTACHMENT_SPECIALITY]
            row["isSelected"] = false
            row["chat_date"] = "Today".localized()
            row["blog_id"] = chatData[CoreMessage_TMessageKey.BLOG_ID]
            
            if !self.dataDates.contains("Today".localized()) {
                self.dataDates.append("Today".localized())
                self.tableChatView.insertSections(
                    IndexSet(integer: self.dataDates.count - 1),
                    with: .fade
                )
            }
            
            let isCredential = (row["credential"] as? String ?? "") == "1"
            if isCredential {
                self.listTimerCredential[messageId] = 60
            }
            
//            self.counter += 1
            self.counter = 0
            self.updateCounter(counter: self.counter)
            // One more of the conversation's messages is now in the loaded window.
            self.loadedCount += 1
            if let collageRow = self.foldIntoImageGroup(row) {
                // Part of the run above it: no new row goes in, the row that draws the collage
                // is redrawn to take it.
                self.tableChatView.reloadRows(at: [collageRow], with: .none)
                self.tableChatView.layoutIfNeeded()
            } else {
                self.dataMessages.append(row)

                let todayMessages = self.messages(onDate: "Today".localized())
                guard let lastSection = self.dataDates.firstIndex(of: "Today".localized()) else { return }

                self.tableChatView.insertRows(
                    at: [IndexPath(row: todayMessages.count - 1, section: lastSection)],
                    with: .fade
                )
                self.tableChatView.layoutIfNeeded()
            }
            
            // FIX 3: Timer credential dengan safe index
            if isCredential {
                var minute = 60
                SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: messageId)
                let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
                    guard let self = self else { t.invalidate(); return }
                    minute -= 1
                    self.listTimerCredential[messageId] = minute
                    
                    if minute == 0 {
                        t.invalidate()
                        self.listTimerCredential.removeValue(forKey: messageId)
                        self.timerCredential.removeValue(forKey: messageId)
                        SecureUserDefaults.shared.removeValue(forKey: messageId)
                        
                        if let idx = self.dataMessages.firstIndex(where: {
                            $0["message_id"] as? String == messageId
                        }) {
                            self.dataMessages[idx]["lock"] = "2"
                            self.dataMessages[idx]["reff_id"] = ""
                        }
                        
                        DispatchQueue.global().async {
                            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                do {
                                    _ = Database.shared.updateRecord(
                                        fmdb: fmdb, table: "MESSAGE",
                                        cvalues: ["lock": "2"],
                                        _where: "message_id = '\(messageId)'"
                                    )
                                } catch {
                                    rollback.pointee = true
                                }
                            })
                        }
                    }
                    
                    // FIX: nil check SEBELUM force unwrap
                    if let section = self.dataDates.indices.last,
                       let row = self.dataMessages.filter({
                           $0["chat_date"] as? String ?? "" == self.dataDates[section]
                       }).firstIndex(where: {
                           $0["message_id"] as? String == messageId
                       }) {
                        self.tableChatView.reloadRows(
                            at: [IndexPath(row: row, section: section)],
                            with: .none
                        )
                    }
                }
                self.timerCredential[messageId] = timer
            }
            
            // FIX 4: Safe currentIndexpath access
            if let currentIndexpath = self.currentIndexpath,
               currentIndexpath.row == (self.dataMessages.count - 2) {
                self.tableChatView.scrollToBottom()
            }
            if self.viewIfLoaded?.window != nil {
                self.sendReadMessageStatus(
                    chat_id: self.dataTopic["chat_id"] as? String ?? "",
                    f_pin: fPin,
                    message_scope_id: messageScopeId,
                    message_id: messageId
                )
            }
        }
    }
    
    @objc func onStatusChat(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let idMe = User.getMyPin() as String?
                let chatData = dataMessage.mBodies
                if (chatData[CoreMessage_TMessageKey.F_PIN] == idMe || chatData[CoreMessage_TMessageKey.L_PIN] == self.dataGroup["group_id"] as? String || chatData[CoreMessage_TMessageKey.F_PIN] == self.dataGroup["group_id"] as? String) && chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] == MessageScope.GROUP {
                    if (chatData.keys.contains(CoreMessage_TMessageKey.MESSAGE_ID) && !(chatData[CoreMessage_TMessageKey.MESSAGE_ID]!).contains("-2,")) {
                        var idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! })
                        if let idxMessageIdParent = self.groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! }) }) {
                            if let idxInImages = self.groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! }) {
                                self.groupImages[idxMessageIdParent].value[idxInImages].status = chatData[CoreMessage_TMessageKey.STATUS]!
                                self.groupImages[idxMessageIdParent].value[idxInImages].dataMessage["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                            }
                            idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.groupImages[idxMessageIdParent].key })
                        }
                        if (idx != nil) {
                            if (chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] == "1") {
                                self.updateStatusDelete(idx: idx, chatData: chatData)
                            } else {
                                self.updateStatusMessage(idx: idx, chatData: chatData)
                            }
                        }
                    }
                    else if (chatData.keys.contains("message_id")) {
                        var idMessage = dataMessage.getBody(key: "message_id")
                        if idMessage.contains("'") {
                            idMessage = idMessage.replacingOccurrences(of: "'", with: "")
                        }
                        var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == idMessage })
                        if let idxMessageIdParent = self.groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == idMessage }) }) {
                            if let idxInImages = self.groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == idMessage }) {
                                self.groupImages[idxMessageIdParent].value[idxInImages].status = chatData[CoreMessage_TMessageKey.STATUS]!
                                self.groupImages[idxMessageIdParent].value[idxInImages].dataMessage["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                            }
                            idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.groupImages[idxMessageIdParent].key })
                        }
                        if (idx != nil) {
                            if (chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] == "1") {
                                self.updateStatusDelete(idx: idx, chatData: chatData)
                            } else {
                                self.updateStatusMessage(idx: idx, chatData: chatData)
                            }
                        }
                    }
                    else {
                        let listMessageId = chatData[CoreMessage_TMessageKey.MESSAGE_ID]!.split(separator: ",")
                        for i in 1..<listMessageId.count {
                            var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String ?? "" == listMessageId[i] })
                            if let idxMessageIdParent = self.groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == listMessageId[i] }) }) {
                                if let idxInImages = self.groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == listMessageId[i] }) {
                                    self.groupImages[idxMessageIdParent].value[idxInImages].status = chatData[CoreMessage_TMessageKey.STATUS]!
                                    self.groupImages[idxMessageIdParent].value[idxInImages].dataMessage["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                                }
                                idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.groupImages[idxMessageIdParent].key })
                            }
                            if (idx != nil) {
                                self.updateStatusMessage(idx: idx, chatData: chatData)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func closeContextMenuIfNeeded() {
        DispatchQueue.main.async {
            // Fix: the WhatsApp-style overlay is not a system menu, so removing the
            // interaction below would leave it on screen - it has to be told to go.
            self.longBubbleContextMenu?.dismiss(animated: true)
            guard let view = self.lastContextMenuView else { return }

            // If we have the original interaction instance, remove it.
            if let interaction = self.lastContextMenuInteraction {
                view.removeInteraction(interaction)
            } else {
                // Fallback: remove all UIContextMenuInteraction instances from view
                view.interactions
                    .compactMap({ $0 as? UIContextMenuInteraction })
                    .forEach({ view.removeInteraction($0) })
            }
        }
    }
    
    @objc func onFailedSendMessage(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            let messageId = data["message_id"]  as? String ?? ""
            let status = data["status"]  as? String ?? ""
            
            var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String ?? "" == messageId })
            if let idxMessageIdParent = self.groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == messageId }) }) {
                if let idxInImages = self.groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == messageId }) {
                    self.groupImages[idxMessageIdParent].value[idxInImages].status = status
                    self.groupImages[idxMessageIdParent].value[idxInImages].dataMessage["status"] = status
                }
                idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.groupImages[idxMessageIdParent].key })
            }
            
            if (idx != nil) {
                do {
                    self.dataMessages[idx!]["status"] = status
                    let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                    let row = self.messages(onDate: self.dataMessages[idx!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                    if row != nil && section != nil  {
                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                    }
                } catch {
                }
            }
        }
    }
    
    private func updateStatusDelete(idx: Int?, chatData: [String: String]) {
        closeContextMenuIfNeeded()
        do {
            if self.dataMessages[idx!]["lock"] != nil && self.dataMessages[idx!]["lock"]  as? String ?? "" == "1" {
                return
            }
            self.dataMessages[idx!]["lock"] = "1"
            self.dataMessages[idx!]["reff_id"] = ""
            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
            let row = self.messages(onDate: self.dataMessages[idx!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[idx!]["message_id"]  as? String ?? "" })
            if row != nil && section != nil  {
                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
            }
            if self.listTimerCredential[self.dataMessages[idx!]["message_id"]  as? String ?? ""] != nil {
                self.listTimerCredential.removeValue(forKey: self.dataMessages[idx!]["message_id"]  as? String ?? "")
                self.timerCredential[self.dataMessages[idx!]["message_id"]  as? String ?? ""]?.invalidate()
                self.timerCredential.removeValue(forKey: self.dataMessages[idx!]["message_id"]  as? String ?? "")
                SecureUserDefaults.shared.removeValue(forKey: self.dataMessages[idx!]["message_id"]  as? String ?? "")
            }
            if self.reffId != nil && self.reffId == chatData["message_id"]! {
                self.deleteReplyView()
            }
        } catch {
        }
    }
    
    private func updateStatusMessage(idx: Int?, chatData: [String: String]) {
        do {
            if Int(self.dataMessages[idx!]["status"]  as? String ?? "")! > Int(chatData[CoreMessage_TMessageKey.STATUS]!)! {
                return
            }
            self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
            let row = self.messages(onDate: self.dataMessages[idx!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[idx!]["message_id"]  as? String ?? "" })
            if row != nil && section != nil  {
                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
            }
        } catch {
        }
    }
    
    @objc func onMemberTopic(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        DispatchQueue.main.async { [self] in
            if data["member"] == nil || data["code"]  as? String ?? "" == CoreMessage_TMessageCode.EXIT_GROUP && data["member"]  as? String ?? "" == User.getMyPin()! && data["groupId"]  as? String ?? "" == self.dataGroup["group_id"]  as? String ?? "" && !containerActionGroup.isDescendant(of: self.view) {
                dismissKeyboard()
                let labelKicked = UILabel()
                if data["member"] == nil && data["code"]  as? String ?? "" == CoreMessage_TMessageCode.DELETE_CHAT && data["topicId"]  as? String ?? "" == dataTopic["chat_id"]  as? String ?? "" {
                    labelKicked.text = "This topic has been deleted".localized()
                } else if data["member"] != nil && data["member"]  as? String ?? "" == data["f_pin"]  as? String ?? "" {
                    labelKicked.text = "You have left this group".localized()
                } else if data["member"] != nil {
                    labelKicked.text = "You have been removed from this group".localized()
                } else if data["code"]  as? String ?? "" == CoreMessage_TMessageCode.UPDATE_CHAT {
                    dataGroup.removeAll()
                    dataTopic.removeAll()
                    getDataGroup(unique_l_pin: unique_l_pin)
                    changeAppBar()
                    return
                } else {
                    return
                }
                removed = true
                cancelAction()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: { [self] in
                    navigationItem.rightBarButtonItem = nil
                    view.addSubview(containerActionGroup)
                    containerActionGroup.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        containerActionGroup.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        containerActionGroup.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        containerActionGroup.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                        containerActionGroup.heightAnchor.constraint(equalToConstant: 120)
                    ])
                    containerActionGroup.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
                    containerActionGroup.addSubview(labelKicked)
                    labelKicked.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        labelKicked.centerYAnchor.constraint(equalTo: containerActionGroup.centerYAnchor),
                        labelKicked.centerXAnchor.constraint(equalTo: containerActionGroup.centerXAnchor),
                    ])
                    labelKicked.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                    labelKicked.font = UIFont.systemFont(ofSize: 12 + offset()).bold
                    if contactChatNav.viewIfLoaded?.window != nil {
                        contactChatNav.dismiss(animated: true)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                        if self.fromNotification {
                            self.didTapExit()
                        } else {
                            self.navigationController?.popViewController(animated: true)
                        }
                    })
                })
            }
        }
    }
    
    @objc func onGroup(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        if data["code"]  as? String ?? "" == "A010" && data["groupId"]  as? String ?? "" == self.dataGroup["group_id"]  as? String ?? "" {
            DispatchQueue.main.async {
                Database.shared.database?.inTransaction({ fmdb, rollback in
                    if let c = Database().getRecords(fmdb: fmdb, query: "select f_name, image_id from GROUPZ where group_id = '\(self.dataGroup["group_id"]!!)'"), c.next() {
                        self.dataGroup["f_name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                        self.dataGroup["image_id"] = c.string(forColumnIndex: 1)!
                        c.close()
                    }
                })
                self.changeAppBar()
            }
        }
    }
    
    @IBAction func voiceTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
    }
    
    @IBAction func imageTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let action = self.actionImageVideo(for: "image", title: "Choose Photo".localized()) {
            alertController.addAction(action)
        }
        if let action = self.actionImageVideo(for: "video", title: "Choose Video".localized()) {
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        self.present(alertController, animated: true)
    }
    
    private func actionImageVideo(for type: String, title: String) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            switch type {
            case "image":
                var config = PHPickerConfiguration()
                config.filter = .images
                config.selectionLimit = 10
                config.preferredAssetRepresentationMode = .automatic
                let picker = PHPickerViewController(configuration: config)
                picker.delegate = self
                if UIBarButtonItem.appearance().titleTextAttributes(for: .normal) != nil {
                    isBlackCancelButton = UIBarButtonItem.appearance().titleTextAttributes(for: .normal)?.values.first as! NSObject == UIColor.black
                }
                if !isBlackCancelButton {
                    let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
                    UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
                }
                present(picker, animated: true, completion: nil)
            case "video":
                var config = PHPickerConfiguration()
                config.filter = .videos
                config.selectionLimit = 10
                config.preferredAssetRepresentationMode = .automatic
                let picker = PHPickerViewController(configuration: config)
                picker.delegate = self
                if UIBarButtonItem.appearance().titleTextAttributes(for: .normal) != nil {
                    isBlackCancelButton = UIBarButtonItem.appearance().titleTextAttributes(for: .normal)?.values.first as! NSObject == UIColor.black
                }
                if !isBlackCancelButton {
                    let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
                    UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
                }
                present(picker, animated: true, completion: nil)
            case "imageCamera":
                imageVideoPicker.present(source: .imageCamera)
            case "videoCamera":
                imageVideoPicker.present(source: .videoCamera)
            default:
                imageVideoPicker.present(source: .imageAlbum)
            }
        }
    }
    
    @IBAction func photoTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let action = self.actionImageVideo(for: "imageCamera", title: "Take Photo".localized()) {
            alertController.addAction(action)
        }
        if let action = self.actionImageVideo(for: "videoCamera", title: "Take Video".localized()) {
            alertController.addAction(action)
        }
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        self.present(alertController, animated: true)
    }
    
    @IBAction func stickerTapped(_ sender: UIButton) {
        if textFieldSend.isFirstResponder {
            dismissKeyboard()
        }
        DispatchQueue.main.async {
            if !self.viewSticker.isDescendant(of: self.view) {
                self.constraintBottomAttachment.constant = 200.0
                self.view.addSubview(self.viewSticker)
                self.viewSticker.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    self.viewSticker.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                    self.viewSticker.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    self.viewSticker.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    self.viewSticker.heightAnchor.constraint(equalToConstant: 200)
                ])
                
                let layout = UICollectionViewFlowLayout()
                layout.scrollDirection = .vertical
                let collectionSticker = UICollectionView(frame: .zero, collectionViewLayout: layout)
                collectionSticker.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cellSticker")
                collectionSticker.delegate = self
                collectionSticker.dataSource = self
                collectionSticker.backgroundColor = .clear
                self.viewSticker.addSubview(collectionSticker)
                collectionSticker.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    collectionSticker.topAnchor.constraint(equalTo: self.viewSticker.topAnchor, constant: 20),
                    collectionSticker.bottomAnchor.constraint(equalTo: self.viewSticker.bottomAnchor, constant: -20),
                    collectionSticker.leadingAnchor.constraint(equalTo: self.viewSticker.leadingAnchor, constant: 20),
                    collectionSticker.trailingAnchor.constraint(equalTo: self.viewSticker.trailingAnchor, constant: -20)
                ])
                if (self.currentIndexpath != nil) {
                    DispatchQueue.main.async {
                        self.tableChatView.safeScrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: false)
                    }
                } else {
                    self.tableChatView.scrollToBottom()
                }
            } else {
                self.constraintBottomAttachment.constant = 0.0
                self.viewSticker.removeConstraints(self.viewSticker.constraints)
                self.viewSticker.removeFromSuperview()
            }
        }
    }
    
    @IBAction func fileTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        documentPicker.present()
    }
    
    @objc func didTapExit() {
        self.dismiss(animated: true, completion: {
            self.removeAllObjectBeforeDismissVC()
        })
    }
    
    @objc func profilePersonTapped(_ sender: ObjectGesture) {
        if isHistoryCC {
            return
        }
        let idMe = User.getMyPin() as String?
        if sender.message_id == idMe {
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
            controller.data = sender.message_id
            controller.flag = .me
            navigationController?.show(controller, sender: nil)
        } else if sender.message_id != "-999" && sender.message_id != "-997"  {
            let data = User.getDataCanNil(pin: sender.message_id)
            if data != nil {
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                controller.flag = .friend
                controller.user = data
                controller.name = data!.fullName
                controller.data = sender.message_id
                controller.picture = data!.thumb
                self.navigationController?.show(controller, sender: nil)
            } else {
                let dataUser = getDataProfile(f_pin: sender.message_id, message_id: "")
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                controller.flag = .invite
                controller.user = nil
                controller.name = dataUser["name"]!
                controller.data = sender.message_id
                controller.picture = dataUser["image_id"]!
                self.navigationController?.show(controller, sender: nil)
            }
        }
    }
    
    @objc func seeProfileTapped() {
        if isHistoryCC || removed || copySession || forwardSession || deleteSession || summarizeSession || (dataGroup["official"] as? String == "1" && (dataGroup["parent"] as? String)!.isEmpty) {
            return
        }
        dismissKeyboard()
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "groupDetailView") as! GroupDetailViewController
        controller.data = dataGroup["group_id"]  as? String ?? ""
        controller.checkReadMessage = {
            if self.currentIndexpath == nil {
                var listData = self.dataMessages
                listData = listData.filter({$0["status"]  as? String ?? "" != "4" && $0["status"]  as? String ?? "" != "8"})
                if listData.count != 0 {
                    let idMe = User.getMyPin() as String?
                    for i in 0...listData.count - 1 {
                        if listData[i]["f_pin"] as? String != idMe && EditorGroup.conditionSendRead(scope: listData[i][TypeDataMessage.message_scope_id] as! String, fPin: listData[i][TypeDataMessage.f_pin] as! String, messageId: listData[i][TypeDataMessage.message_id] as! String) {
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: listData[i]["f_pin"]  as? String ?? "", message_scope_id: MessageScope.GROUP, message_id: listData[i]["message_id"]  as? String ?? "")
                        }
                    }
                }
            } else {
                let dataMessages = self.messages(onDate: self.dataDates[self.currentIndexpath!.section])
                var listData = dataMessages
                listData = listData.filter({$0["status"]  as? String ?? "" != "4" && $0["status"]  as? String ?? "" != "8"})
                if listData.count != 0 {
                    let idMe = User.getMyPin() as String?
                    for i in 0...listData.count - 1 {
                        if listData[i]["f_pin"] as? String != idMe && EditorGroup.conditionSendRead(scope: listData[i][TypeDataMessage.message_scope_id] as! String, fPin: listData[i][TypeDataMessage.f_pin] as! String, messageId: listData[i][TypeDataMessage.message_id] as! String) {
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: listData[i]["f_pin"]  as? String ?? "", message_scope_id: MessageScope.GROUP, message_id: listData[i]["message_id"]  as? String ?? "")
                        }
                    }
                }
            }
        }
        navigationController?.show(controller, sender: nil)
    }
    
    @objc func dismissKeyboard() {
        if isSearching {
            searchBar.resignFirstResponder()
        } else {
            textFieldSend.resignFirstResponder() // dismiss keyoard
            if (self.constraintBottomAttachment.constant != 0.0) {
                constraintBottomAttachment.constant = 0.0
                self.viewSticker.removeConstraints(self.viewSticker.constraints)
                self.viewSticker.removeFromSuperview()
            }
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil && !isEditingMessage {
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            let keyboardHeight: CGFloat = keyboardSize.height
            
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            let previousBottomAttachment = self.constraintBottomAttachment.constant
            if self.constraintBottomAttachment.constant != keyboardHeight || self.constraintViewTextField.constant != keyboardHeight - 60 {
                if self.viewSticker.isDescendant(of: self.view) {
                    self.constraintBottomAttachment.constant = 0.0
                    self.viewSticker.removeConstraints(self.viewSticker.constraints)
                    self.viewSticker.removeFromSuperview()
                }
//                self.constraintViewTextField.constant = keyboardHeight - 60
                self.constraintBottomAttachment.constant = keyboardHeight
                if self.contraintBottomMention.constant > 0 {
                    self.contraintBottomMention.constant = 25 + constraintBottomAttachment.constant + self.heightTextFieldSend.constant + self.viewTextfield.bounds.height
                }
                self.keyboardHeightForMention = keyboardHeight
                // How much of the list the keyboard is about to take that it was not taking
                // already - a keyboard that only changes height (a predictive bar appearing,
                // say) must not move the conversation by its whole height.
                let listShrinkage = keyboardHeight - previousBottomAttachment
                if isSearching {
                    self.constraintBottomContainerMultpileSelectSession.constant = -keyboardHeight
                }
                UIView.animate(withDuration: TimeInterval(duration), animations: {
                    self.view.layoutIfNeeded()
                    // Fix: this used to scroll to the last remembered row, or all the way to the
                    // newest message, every time the keyboard came up - so tapping the input
                    // while reading something further up threw the reader back to the bottom.
                    // Shifting the content by exactly what the keyboard took leaves them looking
                    // at what they were looking at.
                    self.keepScrollPosition(whenInputGrewBy: listShrinkage)
                })
            }
        }  else if isEditingMessage {
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            let keyboardHeight: CGFloat = keyboardSize.height
            
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            let constant: CGFloat = 0 - keyboardHeight - 15
            constraintBottomeditTextView.constant = constant
            constraintBottomSendEditTV.constant = constant
            UIView.animate(withDuration: TimeInterval(duration), animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil && !isEditingMessage {
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            let keyboardWasTaking = self.constraintBottomAttachment.constant
            self.constraintViewTextField.constant = 0
            self.constraintBottomAttachment.constant = 0
            self.constraintBottomContainerMultpileSelectSession.constant = 0
            if self.contraintBottomMention.constant > 0 {
                self.contraintBottomMention.constant = 25 + constraintBottomAttachment.constant + self.heightTextFieldSend.constant + self.viewTextfield.bounds.height
            }
            keyboardHeightForMention = nil
            UIView.animate(withDuration: TimeInterval(duration), animations: {
                self.view.layoutIfNeeded()
                self.keepScrollPosition(whenInputGrewBy: -keyboardWasTaking)
            })
        }
    }
    
    @objc func showChooserACKConfidential() {
//        dismissKeyboard()
        let alertController = LibAlertController(title: "Message Mode".localized(), message: "Select".localized() + " " + "Message Mode".localized(), preferredStyle: .actionSheet)
        let imageConfidential = resizeImage(image: UIImage(named: "pb_icon_conf_msg_on", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let imageAck = resizeImage(image: UIImage(named: "pb_icon_ack_msg_on", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let imageSticker = resizeImage(image: UIImage(named: "Sticker---Emoji", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let confidentialAction = UIAlertAction(title: "Confidential Message".localized(), style: .default, handler: { (UIAlertAction) in
            self.isConfidential = !self.isConfidential
            if self.isConfidential {
                self.buttonAckConfidential.setImage(imageConfidential, for: .normal)
            } else {
                self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
            }
            if self.isAck {
                self.isAck = false
            }
        })
        let ackAction = UIAlertAction(title: "Confirmation Message".localized(), style: .default, handler: { (UIAlertAction) in
            self.isAck = !self.isAck
            if self.isAck {
                self.buttonAckConfidential.setImage(imageAck, for: .normal)
            } else {
                self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
            }
            if self.isConfidential {
                self.isConfidential = false
            }
        })
        let stickerAction = UIAlertAction(title: "Open Sticker".localized(), style: .default, handler: { (UIAlertAction) in
            self.stickerTapped(UIButton())
        })
        confidentialAction.setValue(imageConfidential, forKey: "image")
        ackAction.setValue(imageAck, forKey: "image")
        stickerAction.setValue(imageSticker, forKey: "image")
        alertController.addAction(confidentialAction)
        alertController.addAction(ackAction)
//        alertController.addAction(stickerAction)
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (UIAlertAction) in
            self.isConfidential = false
            self.isAck = false
            self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func setAckConfidential(isAck: Bool, isConfidential: Bool) {
        self.isConfidential = isConfidential
        self.isAck = isAck
        let imageConfidential = resizeImage(image: UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let imageAck = resizeImage(image: UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        if isAck {
            buttonAckConfidential.setImage(imageAck, for: .normal)
        } else if isConfidential {
            buttonAckConfidential.setImage(imageConfidential, for: .normal)
        } else {
            self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    @objc func sendTapped() {
        sendChat(message_text: textFieldSend.text!, viewController: self)
    }
    
    private func sendChat(message_scope_id:String =  MessageScope.GROUP, status:String =  "1", message_text:String =  "", credential:String = "0", attachment_flag: String = "0", ex_blog_id: String = "", message_large_text: String = "", ex_format: String = "", image_id: String = "", audio_id: String = "", video_id: String = "", file_id: String = "", thumb_id: String = "", reff_id: String = "", read_receipts: String = "", is_call_center: String = "0", call_center_id: String = "", viewController: UIViewController, gif_id: String = "", is_forwarded: Int = 0) {
        if viewController is EditorGroup && file_id == "" && dataMessageForward == nil {
            if ((textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) == "Send message".localized() && textFieldSend.textColor == UIColor.lightGray && attachment_flag != "11") || textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ) {
                dismissKeyboard()
                viewController.view.makeToast("Write Messages".localized(), duration: 3)
                if (textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized()) {
                    textFieldSend.text = ""
                }
                if (self.heightTextFieldSend.constant != 40) {
                    self.heightTextFieldSend.constant = 40
                }
                return
            }
        }
        var reff_id = reff_id
        if (reffId != nil) {
            reff_id = reffId!
        }
        var message_text = message_text
        message_text = message_text.replacingOccurrences(of: "\n  •", with: "\n•")
        if message_text.hasPrefix("  •") {
            message_text = message_text.replacingOccurrences(of: "  •", with: "•")
        }
        let regex = try! NSRegularExpression(pattern: #"(?m)^\s{2}([0-9]+\.)"#)
        message_text = regex.stringByReplacingMatches(in: message_text,
                                                     options: [],
                                                     range: NSRange(location: 0, length: message_text.utf16.count),
                                                     withTemplate: "$1")
        

        // Check if text contains bullet points or numbered list using regex
        if !message_text.isEmpty {
            message_text = message_text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let idMe = User.getMyPin() as String?
        var opposite_pin = self.dataGroup["group_id"]  as? String ?? ""
        if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
            opposite_pin = self.dataTopic["chat_id"]  as? String ?? ""
        }
        var credential = credential
        if isConfidential {
            credential = "1"
        }
        var read_receipts = read_receipts
        if isAck {
            read_receipts = "8"
        }
        if message_text.contains("@") && listMentionInTextField.count > 0 {
            var diff: Int = 0
            for i in 0..<listMentionInTextField.count {
                let mention = listMentionInTextField[i]
                guard let exBlockStr = mention.ex_block, let exBlock = Int(exBlockStr) else {
                    continue // skip if ex_block is nil or not an integer
                }
                let nameWithMention = ("@" + mention.fullName).trimmingCharacters(in: .whitespaces)
                let pinString = "@\(mention.pin)"
                let upperBound = exBlock + diff
                let lowerBound = upperBound - nameWithMention.count + 1
                guard lowerBound >= 0, upperBound < message_text.count else {
                    continue // prevent index out-of-range
                }
                var afterMention = ""
                let nextCharIndex = message_text.index(message_text.startIndex, offsetBy: upperBound + 1, limitedBy: message_text.endIndex)
                if let index = nextCharIndex, index < message_text.endIndex {
                    let nextChar = message_text[index]
                    if nextChar != "\n" && nextChar != " " {
                        afterMention = " "
                    }
                }
                let startIndex = message_text.index(message_text.startIndex, offsetBy: lowerBound)
                let endIndex = message_text.index(message_text.startIndex, offsetBy: upperBound + 1)
                let range = startIndex..<endIndex
                if message_text[range] == nameWithMention {
                    message_text.replaceSubrange(range, with: pinString + afterMention)
                    diff += (pinString + afterMention).count - nameWithMention.count
                }
            }
        }
        if Nexilis.checkingAccess(key: "message_guard") {
            let guardLite = MessageGuardLite(limits: .defaults())
            var isSanitizedText = false
            var isSanitizedHtml = false
            let res = guardLite.sanitizeText(message_text.data(using: .utf8)!)
            if res.verdict == .sanitized {
                isSanitizedText = true
            }
            if let clean = res.data, let str = String(data: clean, encoding: .utf8) {
                if MessageGuardLite.containsHtmlTags(str) {
                    let res2 = guardLite.sanitizeHtml(res.data ?? Data())
                    if res2.verdict == .sanitized {
                        isSanitizedHtml = true
                    }
                    if let str2 = String(data: clean, encoding: .utf8), isSanitizedHtml {
                        message_text = str2
                    }
                } else if isSanitizedText {
                    message_text = str
                }
            }
            var protectionType = ""
            if isSanitizedText && isSanitizedHtml {
                protectionType = "text & html"
            } else if isSanitizedText {
                protectionType = "text"
            } else if isSanitizedHtml {
                protectionType = "html"
            }
            
            if !protectionType.isEmpty {
                DispatchQueue.main.async {
                    self.view.makeToast("Your message is protected with sanitized \(protectionType) (Message Guard)".localized(), duration: 3, position: .center)
                }
            }
        }
        let message = CoreMessage_TMessageBank.sendMessage(l_pin: dataGroup["group_id"]  as? String ?? "", message_scope_id: message_scope_id, status: status, message_text: message_text, credential: credential, attachment_flag: attachment_flag, ex_blog_id: ex_blog_id, message_large_text: message_large_text, ex_format: ex_format, image_id: image_id, audio_id: audio_id, video_id: video_id, file_id: file_id, thumb_id: thumb_id, reff_id: reff_id, read_receipts: read_receipts, chat_id: dataTopic["chat_id"]  as? String ?? "", is_call_center: is_call_center, call_center_id: call_center_id, opposite_pin: opposite_pin, gif_id: gif_id, isForwarded: "\(is_forwarded)", specFile: specFileString)
        Nexilis.addQueueMessage(message: message)
        let messageId = String(message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID]!)
        if credential == "1" {
            self.listTimerCredential[messageId] = 60
        }
        var row: [String: Any?] = [:]
        row["message_id"] = messageId
        row["f_pin"] = idMe
        row["l_pin"] = dataGroup["group_id"]!!
        row["message_scope_id"] = message_scope_id
        row["server_date"] = "\(Date().currentTimeMillis())"
        row["status"] = status
        row["message_text"] = message_text
        row["audio_id"] = audio_id
        row["video_id"] = video_id
        row["image_id"] = image_id
        row["thumb_id"] = thumb_id
        row["credential"] = credential
        row["read_receipts"] = read_receipts
        row["chat_id"] = dataTopic["chat_id"]!!
        row["file_id"] = file_id
        row["attachment_flag"] = attachment_flag
        row["reff_id"] = reff_id
        row["progress"] = 0.0
        row["lock"] = "0"
        row["is_stared"] = "0"
        row["isSelected"] = false
        row["gif_id"] = gif_id
        row[TypeDataMessage.is_forwarded] = is_forwarded
        row[TypeDataMessage.is_call_center] = is_call_center
        row[TypeDataMessage.call_center_id] = call_center_id
        row[TypeDataMessage.opposite_pin] = opposite_pin
        row[TypeDataMessage.spec_file] = specFileString
        specFileString = ""
        lastTextLength = 0
        if !dataDates.contains("Today".localized()){
            dataDates.append("Today".localized())
            tableChatView.insertSections(IndexSet(integer: dataDates.count - 1), with: .fade)
        }
        row["chat_date"] = "Today".localized()
        // One more of the conversation's messages is now in the loaded window.
        loadedCount += 1
        if let collageRow = foldIntoImageGroup(row) {
            // Part of the run above it: no new row goes in, the row that draws the
            // collage is redrawn to take it.
            tableChatView.reloadRows(at: [collageRow], with: .none)
        } else {
            dataMessages.append(row)
            tableChatView.insertRows(at: [IndexPath(row: messages(onDate: dataDates[dataDates.count - 1]).count - 1, section: dataDates.count - 1)], with: .fade)
        }
        tableChatView.layoutIfNeeded()
        if credential == "1" {
            var timer = Timer()
            var minute = 60
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                minute -= 1
                self.listTimerCredential[messageId] = minute
                if minute == 0 {
                    timer.invalidate()
                    self.listTimerCredential.removeValue(forKey: messageId)
                    self.timerCredential.removeValue(forKey: messageId)
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == messageId})
                    if idx != nil {
                        self.dataMessages[idx!]["lock"] = "2"
                        self.dataMessages[idx!]["reff_id"] = ""
                    }
                    DispatchQueue.global().async {
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                    "lock" : "2"
                                ], _where: "message_id = '\(messageId)'")
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                }
                let section = self.dataDates.firstIndex(of: self.dataDates[self.dataDates.count - 1])
                let row = self.messages(onDate: self.dataDates[self.dataDates.count - 1]).firstIndex(where: { $0["message_id"] as? String == messageId})
                if row != nil && section != nil{
                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                }
            })
            self.timerCredential[messageId] = timer
        }
        if textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized() && textFieldSend.textColor != UIColor.lightGray && constraintBottomAttachment.constant == 0 {
            textFieldSend.text = "Send message".localized()
            textFieldSend.textColor = UIColor.lightGray
        } else if constraintBottomAttachment.constant != 0 {
            textFieldSend.text = ""
            heightTextFieldSend.constant = 40
        }
        deleteReplyView()
        deleteLinkPreview()
        listMentionInTextField.removeAll()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        self.tableChatView.scrollToBottom()
        if self.markerCounter != nil {
            let lastMarkerCounter = self.markerCounter
            self.markerCounter = nil
            let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == lastMarkerCounter })
            if indexMessage != nil {
                let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "")
                let row = self.messages(onDate: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                if row != nil && section != nil  {
                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                }
            }
        }
    }
    
    private func getCounter() {
        Database.shared.database?.inTransaction({ fmdb, rollback in
            var l_pin = self.dataGroup["group_id"] as? String ?? ""
            if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
                l_pin = self.dataTopic["chat_id"]  as? String ?? ""
            }
            
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT counter FROM MESSAGE_SUMMARY where l_pin='\(l_pin)'"), c.next() {
                counter = Int(c.int(forColumnIndex: 0))
                c.close()
            }
        })
    }
    
    private func updateCounter(counter: Int) {
        guard !isPreview else {
            return
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                var l_pin = self.dataGroup["group_id"]!!
                if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
                    l_pin = self.dataTopic["chat_id"]  as? String ?? ""
                }
                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                    "counter" : "\(counter)"
                ], _where: "l_pin = '\(l_pin)'")
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        // This chat's unread just changed; the icon counts every chat's, so it changed too.
        APIS.refreshApplicationBadgeSoon()
    }
    
    private func disableEditor() {
        view.addSubview(containerAction)
        containerAction.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerAction.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerAction.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            containerAction.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            containerAction.heightAnchor.constraint(equalToConstant: 120)
        ])
        containerAction.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
        let labelDisable = UILabel()
        containerAction.addSubview(labelDisable)
        labelDisable.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelDisable.centerYAnchor.constraint(equalTo: containerAction.centerYAnchor),
            labelDisable.centerXAnchor.constraint(equalTo: containerAction.centerXAnchor),
        ])
        labelDisable.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        labelDisable.font = UIFont.systemFont(ofSize: 12 + offset()).bold
        labelDisable.text = "Call Center Session has ended".localized()
    }
    
    /// Keeps what is on screen exactly where it is when the input area grows or shrinks.
    ///
    /// Fix: the reply bar takes 50-odd points off the bottom of the list, and the list used to
    /// be scrolled somewhere else entirely to compensate - to the last remembered row, or all
    /// the way to the newest message. That is the jump: replying to something part-way up the
    /// conversation threw the reader back down to the bottom. A chat is read from the bottom, so
    /// moving the content up by exactly what the bar took leaves the same messages on screen -
    /// which is what WhatsApp does and what "tetap di state scroll terakhir" means.
    /// Call it once the new layout is in place - it reads the height the list ends up with.
    private func keepScrollPosition(whenInputGrewBy delta: CGFloat) {
        guard let scrollView = tableChatView, delta != 0, scrollView.bounds.height > 0 else {
            return
        }
        let lowest = -scrollView.adjustedContentInset.top
        let highest = max(lowest, scrollView.contentSize.height + scrollView.adjustedContentInset.bottom - scrollView.bounds.height)
        let target = min(max(scrollView.contentOffset.y + delta, lowest), highest)
        guard abs(target - scrollView.contentOffset.y) > 0.5 else {
            return
        }
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: target), animated: false)
    }

    private var scrollToBottomBottomConstraint: NSLayoutConstraint?

    private func addButtonScrollToBottom() {
        if isInitialLoading {
            return
        }
        self.view.addSubview(buttonScrollToBottom)
        buttonScrollToBottom.translatesAutoresizingMaskIntoConstraints = false
        // Called twice without a removal in between, the old one would still be active and the
        // two would fight over where the button goes.
        scrollToBottomBottomConstraint?.isActive = false
        let placement = scrollToBottomPlacement()
        let bottom = buttonScrollToBottom.bottomAnchor.constraint(equalTo: placement.anchor, constant: placement.spacing)
        scrollToBottomBottomConstraint = bottom
        NSLayoutConstraint.activate([
            bottom,
            buttonScrollToBottom.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -5),
            buttonScrollToBottom.widthAnchor.constraint(equalToConstant: 35.0),
            buttonScrollToBottom.heightAnchor.constraint(equalToConstant: 35.0)
        ])
        buttonScrollToBottom.backgroundColor = .mainColor
        buttonScrollToBottom.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        buttonScrollToBottom.imageView?.contentMode = .scaleAspectFit
        buttonScrollToBottom.imageView?.tintColor = .white
        buttonScrollToBottom.imageEdgeInsets.top = 2.0
        buttonScrollToBottom.layer.cornerRadius = 17.5
        buttonScrollToBottom.clipsToBounds = true
        buttonScrollToBottom.addTarget(self, action: #selector(scrollTobottomAction), for: .touchUpInside)
    }
    
    /// Whatever sits under the button at the moment, and how far above it the button goes.
    ///
    /// Searching swaps the input bar for the 50pt bar with the match arrows, and composing a
    /// reply puts the preview of the quoted message above the text field - the button has to
    /// hang off whichever one is actually on screen, or it ends up floating over the arrows or
    /// sitting on top of the reply preview.
    private func scrollToBottomPlacement(ignoringReplyPreview: Bool = false) -> (anchor: NSLayoutYAxisAnchor, spacing: CGFloat) {
        if containerMultpileSelectSession.isDescendant(of: self.view) {
            return (containerMultpileSelectSession.topAnchor, -10)
        }
        if !ignoringReplyPreview, containerPreviewReply.isDescendant(of: viewTextfield) {
            return (containerPreviewReply.topAnchor, -10)
        }
        return (buttonSendChat.topAnchor, -30)
    }

    /// Points the button at whatever is under it now.
    ///
    /// Fix: this used to take the button out of the view and put it back. A view that has just
    /// been added has no position until the next layout pass, so it appeared wherever it had
    /// been left and then flew to its place - the bounce from the bottom of the screen when the
    /// reply preview was closed. Swapping the one constraint that holds it moves it from where
    /// it already is. Left un-animated on purpose: called from inside the animation that is
    /// moving the bar underneath, it travels with that bar instead of racing it.
    private func refreshScrollToBottomButtonPlacement(animated: Bool = false, ignoringReplyPreview: Bool = false) {
        guard buttonScrollToBottom.isDescendant(of: self.view) else {
            return
        }
        let placement = scrollToBottomPlacement(ignoringReplyPreview: ignoringReplyPreview)
        scrollToBottomBottomConstraint?.isActive = false
        let bottom = buttonScrollToBottom.bottomAnchor.constraint(equalTo: placement.anchor, constant: placement.spacing)
        bottom.isActive = true
        scrollToBottomBottomConstraint = bottom
        guard animated else {
            return
        }
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        })
    }

    private func addCounterAtButttonScrollToBottom() {
        if isInitialLoading || counter == 0 {
            return
        }
        self.view.addSubview(indicatorCounterBSTB)
        indicatorCounterBSTB.translatesAutoresizingMaskIntoConstraints = false
        indicatorCounterBSTB.backgroundColor = .systemRed
        indicatorCounterBSTB.layer.cornerRadius = 7.5
        indicatorCounterBSTB.clipsToBounds = true
        indicatorCounterBSTB.layer.borderWidth = 0.5
        indicatorCounterBSTB.layer.borderColor = UIColor.secondaryColor.cgColor
        NSLayoutConstraint.activate([
            indicatorCounterBSTB.bottomAnchor.constraint(equalTo: buttonScrollToBottom.topAnchor, constant: 10),
            indicatorCounterBSTB.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -30),
            indicatorCounterBSTB.widthAnchor.constraint(greaterThanOrEqualToConstant: 15),
            indicatorCounterBSTB.heightAnchor.constraint(equalToConstant: 15)
        ])
        
        indicatorCounterBSTB.addSubview(labelCounter)
        labelCounter.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelCounter.leadingAnchor.constraint(equalTo: indicatorCounterBSTB.leadingAnchor, constant: 2),
            labelCounter.trailingAnchor.constraint(equalTo: indicatorCounterBSTB.trailingAnchor, constant: -2),
            labelCounter.centerXAnchor.constraint(equalTo: indicatorCounterBSTB.centerXAnchor),
        ])
        labelCounter.font = UIFont.systemFont(ofSize: 11 + offset())
        labelCounter.text = "\(counter)"
        labelCounter.textColor = .secondaryColor
        labelCounter.textAlignment = .center
    }
    
    @objc func scrollTobottomAction() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        // "Take me to the end" means the end of the conversation, not the end of whatever
        // happens to be loaded.
        if !isWindowAtNewest {
            jumpToNewestPage()
        }
        tableChatView.scrollToBottom()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            removeScrollToBottomButton()
        }
    }
    
    private func sendReadMessageStatus(
        chat_id: String,
        f_pin: String,
        message_scope_id: String,
        message_id: String
    ) {
        guard !f_pin.elementsEqual("-999"),
              !message_scope_id.elementsEqual("16"),
              !message_scope_id.elementsEqual("15") else { return }
        guard !isPreview else {
            // Looking at a preview is not reading it. Kept, and sent if it is really opened.
            deferredReadReceipts.append((chat_id, f_pin, message_scope_id, message_id))
            return
        }

        let task = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let message = CoreMessage_TMessageBank.getUpdateRead(
                p_chat_id: chat_id,
                p_f_pin: f_pin,
                p_scope_id: message_scope_id,
                qty: 1
            )

            let fPin = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
            message.mBodies[CoreMessage_TMessageKey.SERVER_DATE] = String(Date().currentTimeMillis())

            // Resolve message IDs with group images
            var resolvedMessageId = message_id
            if message_id.contains(",") {
                let lId = message_id.components(separatedBy: ",")
                for id in lId {
                    if let listGroupImages = await MainActor.run(resultType: [ImageGrouping]?.self, body: {
                        self.groupImages.first(where: { $0.key == id })?.value
                    }) {
                        let mId = listGroupImages.map { $0.messageId }.joined(separator: ",")
                        resolvedMessageId += "," + mId
                    }
                }
            }

            message.mStatus = CoreMessage_TMessageUtil.getTID()
            message.mBodies[CoreMessage_TMessageKey.L_PIN] = f_pin
            message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = "-2,\(resolvedMessageId)"
            print("SENDREADSTATUS: \(message.toLogString())")

            // Loop sampai tidak background, dengan cancel check
            while !Task.isCancelled {
                let isBackground = await MainActor.run {
                    API.nGetCLXConnState() == 0
                        || !API.bInetConnAvailable()
                        || APIS.checkAppStateisBackground()
                }

                guard !isBackground else {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 detik
                    continue
                }

                // Kirim request
                guard !Task.isCancelled else { return }

                if let resp = Nexilis.writeAndWait(message: message), resp.isOk() {
                    let ids = resolvedMessageId.contains(",")
                        ? resolvedMessageId.components(separatedBy: ",")
                        : [resolvedMessageId]

                    Database.shared.database?.inTransaction({ fmdb, rollback in
                        do {
                            for id in ids where !id.isEmpty {
                                _ = Database.shared.updateRecord(
                                    fmdb: fmdb,
                                    table: "MESSAGE",
                                    cvalues: ["status": "4"],
                                    _where: "message_id = '\(id)'"
                                )
                            }
                        } catch {
                            rollback.pointee = true
                        }
                    })
                } else {
                    // Retry sekali, lalu keluar agar tidak infinite
                    guard !Task.isCancelled else { return }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    continue
                }

                break // sukses, keluar loop
            }
        }

        // Simpan task agar bisa di-cancel
        Task { @MainActor in
            self.readStatusTasks.append(task)
        }
    }

    // Panggil saat keluar dari VC
    private func cancelAllReadStatusTasks() {
        readStatusTasks.forEach { $0.cancel() }
        readStatusTasks.removeAll()
    }
    
//    private func sendReadMessageStatus(chat_id: String, f_pin: String, message_scope_id: String, message_id: String) {
//        if (f_pin.elementsEqual("-999") || message_scope_id.elementsEqual("16") || message_scope_id.elementsEqual("15")){
//            return
//        }
//        DispatchQueue.global(qos: .userInitiated).async {
//            let message = CoreMessage_TMessageBank.getUpdateRead(p_chat_id: chat_id, p_f_pin: f_pin, p_scope_id: message_scope_id, qty: 1)
//            let fPin = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
//            let scope = message.getBody(key: CoreMessage_TMessageKey.SCOPE_ID)
//            message.mBodies[CoreMessage_TMessageKey.SERVER_DATE] = String(Date().currentTimeMillis())
//            var message_id = message_id
//            if message_id.contains(",") {
//                let lId = message_id.components(separatedBy: ",")
//                for id in lId {
//                    if let listGroupImages = self.groupImages.first(where: { $0.key == id }) {
//                        let valueListGroupImages = listGroupImages.value
//                        var mId = ""
//                        for i in 0..<valueListGroupImages.count {
//                            mId = mId + "," + valueListGroupImages[i].messageId
//                        }
//                        message_id += mId
//                    }
//                }
//            }
//            message.mStatus = CoreMessage_TMessageUtil.getTID()
//            message.mBodies[CoreMessage_TMessageKey.L_PIN] = f_pin
//            message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = "-2,\(message_id)"
//            var isBackground = true
//            while isBackground {
//                DispatchQueue.main.sync {
//                    isBackground = API.nGetCLXConnState() == 0 || !API.bInetConnAvailable() || APIS.checkAppStateisBackground()
//                }
//                if isBackground {
//                    Thread.sleep(forTimeInterval: 1.0)
//                } else {
//                    if let resp = Nexilis.writeAndWait(message: message) {
//                        if resp.isOk() {
//                            if message_id.contains(",") {
//                                let listStr = message_id.components(separatedBy: ",")
//                                for ls in listStr {
//                                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
//                                        do {
//                                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
//                                                "status" : "4"
//                                            ], _where: "message_id = '\(ls)'")
//                                        } catch {
//                                            rollback.pointee = true
//                                            print("Access database error: \(error.localizedDescription)")
//                                        }
//                                    })
//                                }
//                            } else {
//                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
//                                    do {
//                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
//                                            "status" : "4"
//                                        ], _where: "message_id = '\(message_id)'")
//                                    } catch {
//                                        rollback.pointee = true
//                                        print("Access database error: \(error.localizedDescription)")
//                                    }
//                                })
//                            }
//                        } else {
//                            DispatchQueue.main.sync {
//                                self.sendReadMessageStatus(chat_id: chat_id, f_pin: fPin, message_scope_id: message_scope_id, message_id: message_id)
//                            }
//                        }
//                    } else {
//                        DispatchQueue.main.sync {
//                            self.sendReadMessageStatus(chat_id: chat_id, f_pin: fPin, message_scope_id: message_scope_id, message_id: message_id)
//                        }
//                    }
//                }
//            }
//        }
////        if let index = dataMessages.firstIndex(where: {$0["message_id"] as? String == message_id}) {
////            dataMessages[index]["status"] = "4"
////            let auto: Bool = SecureUserDefaults.shared.value(forKey: "autoDownload") ?? false
////            if auto {
////                if dataMessages[index]["image_id"] as? String != nil && !((dataMessages[index]["image_id"] as? String)!.isEmpty) {
////                    if let listGroupImages = self.groupImages.first(where: { $0.key == message_id }) {
////                        let valueListGroupImages = listGroupImages.value
////                        for i in 0..<valueListGroupImages.count {
////                            Download().startHTTP(forKey:valueListGroupImages[i].imageId) { (name, progress) in
////                                guard progress == 100 else {
////                                    return
////                                }
////                                let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
////                                if save {
////                                    do {
////                                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
////                                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
////                                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
////                                        if let dirPath = paths.first {
////                                            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(valueListGroupImages[i].imageId)
////                                            if FileManager.default.fileExists(atPath: imageURL.path) {
////                                                let image    = UIImage(contentsOfFile: imageURL.path)
////                                                UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
////                                            }
////                                            else if FileEncryption.shared.isSecureExists(filename: valueListGroupImages[i].imageId) {
////                                                if var secureData = try FileEncryption.shared.readSecure(filename: valueListGroupImages[i].imageId) {
////                                                    let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
////                                                    if dataDecrypt != nil {
////                                                        secureData = dataDecrypt!
////                                                    }
////                                                    let image = UIImage(data: secureData)
////                                                    UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
////                                                }
////                                            }
////                                        }
////                                    }
////                                    catch {
////
////                                    }
////                                }
////                                DispatchQueue.main.async { [self] in
////                                    let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"]  as? String ?? "")
////                                    let row = messages(onDate: dataMessages[index]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == message_id})
////                                    if row != nil && section != nil{
////                                        tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
////                                    }
////                                }
////                            }
////                        }
////                    } else {
////                        Download().startHTTP(forKey:dataMessages[index]["image_id"]  as? String ?? "") { (name, progress) in
////                            guard progress == 100 else {
////                                return
////                            }
////                            let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
////                            if save {
////                                do {
////                                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
////                                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
////                                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
////                                    if let dirPath = paths.first {
////                                        let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(self.dataMessages[index]["image_id"]  as? String ?? "")
////                                        if FileManager.default.fileExists(atPath: imageURL.path) {
////                                            let image    = UIImage(contentsOfFile: imageURL.path)
////                                            UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
////                                        }
////                                        else if FileEncryption.shared.isSecureExists(filename: self.dataMessages[index]["image_id"]  as? String ?? "") {
////                                            if var secureData = try FileEncryption.shared.readSecure(filename: self.dataMessages[index]["image_id"]  as? String ?? "") {
////                                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
////                                                if dataDecrypt != nil {
////                                                    secureData = dataDecrypt!
////                                                }
////                                                let image = UIImage(data: secureData)
////                                                UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
////                                            }
////                                        }
////                                    }
////                                } catch {
////
////                                }
////                            }
////                            DispatchQueue.main.async { [self] in
////                                let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"]  as? String ?? "")
////                                let row = messages(onDate: dataMessages[index]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == message_id})
////                                if row != nil && section != nil{
////                                    tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
////                                }
////                            }
////                        }
////                    }
////                } else if dataMessages[index]["video_id"] as? String != nil && !((dataMessages[index]["video_id"] as? String)!.isEmpty){
////                    Download().startHTTP(forKey: dataMessages[index]["video_id"]  as? String ?? "") { (name, progress) in
////                        guard progress == 100 else {
////                            return
////                        }
////                        let save: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
////                        if save {
////                            do {
////                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
////                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
////                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
////                                if let dirPath = paths.first {
////                                    let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(self.dataMessages[index]["video_id"]  as? String ?? "")
////                                    if FileManager.default.fileExists(atPath: videoURL.path) {
////                                        PHPhotoLibrary.shared().performChanges({
////                                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
////                                        }) { saved, error in
////
////                                        }
////                                    }
////                                    else if FileEncryption.shared.isSecureExists(filename: self.dataMessages[index]["video_id"]  as? String ?? "") {
////                                        if var secureData = try FileEncryption.shared.readSecure(filename: self.dataMessages[index]["video_id"]  as? String ?? "") {
////                                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
////                                            if dataDecrypt != nil {
////                                                secureData = dataDecrypt!
////                                            }
////                                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
////                                            let tempPath = cachesDirectory.appendingPathComponent(name)
////                                            try secureData.write(to: tempPath)
////                                            PHPhotoLibrary.shared().performChanges({
////                                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempPath)
////                                            }) { saved, error in
////
////                                            }
////                                        }
////                                    }
////                                }
////                            } catch {
////
////                            }
////                        }
////                        DispatchQueue.main.async { [self] in
////                            let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"]  as? String ?? "")
////                            let row = messages(onDate: dataMessages[index]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == message_id})
////                            if row != nil && section != nil{
////                                tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
////                            }
////                        }
////                    }
////                }
////                else if dataMessages[index]["file_id"] as? String != nil && !((dataMessages[index]["file_id"] as? String)!.isEmpty) {
////                    Download().startHTTP(forKey: dataMessages[index]["file_id"]  as? String ?? "") { (name, progress) in
////                        guard progress == 100 else {
////                            return
////                        }
////                        DispatchQueue.main.async { [self] in
////                            let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"]  as? String ?? "")
////                            let row = messages(onDate: dataMessages[index]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == message_id})
////                            if row != nil && section != nil{
////                                tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
////                            }
////                        }
////                    }
////                }
////            }
////        }
//    }
    
    private func sendTyping(l_pin: String, isTyping: Bool = false) {
        DispatchQueue.global().async {
            let tmessage = CoreMessage_TMessageBank.getUpdateTypingStatus(p_opposite: l_pin, p_scope: MessageScope.GROUP, p_status: isTyping ? "3": "4")
            _ = Nexilis.write(message: tmessage)
        }
    }
    
    private func checkNewMessage(tableView: UITableView) {
        DispatchQueue.main.async { [self] in
            guard let firstIndex = tableView.indexPathsForVisibleRows?.first,
                  let lastIndex = tableView.indexPathsForVisibleRows?.last
            else { return }

            currentIndexpath = lastIndex

            // MARK: - Filter messages in this section
            let sectionDate = dataDates[lastIndex.section]
            let sectionMessages = dataMessages.filter {
                ($0["chat_date"] as? String ?? "") == sectionDate
            }

            guard !sectionMessages.isEmpty else { return }

            // MARK: - Scroll Position
            let contentHeight = tableView.contentSize.height
            let visibleHeight = tableView.frame.height
            let fullOffset = contentHeight - visibleHeight
            let offsetY = tableView.contentOffset.y

            let isLastSection = (lastIndex.section == dataDates.count - 1)
            let isNotLastRow = (firstIndex.row != sectionMessages.count - 1)
            let isFarFromBottom = (fullOffset - offsetY > 100)
            let isNearBottom = (fullOffset - offsetY < 50)

            // MARK: - Show "Scroll to bottom" button
            if ((!isLastSection && isFarFromBottom) ||
                (isLastSection && isNotLastRow && isFarFromBottom)) {

                if !buttonScrollToBottom.isDescendant(of: view) {
                    addButtonScrollToBottom()
                    addCounterAtButttonScrollToBottom()
                }
            }
            // MARK: - Hide button when at bottom
            else if isNearBottom {
                removeScrollToBottomButton()
            }
//            // MARK: - Ensure index exists
//            guard currentIndexpath!.row < sectionMessages.count else { return }
//
//            // MARK: - Messages up to visible row
//            let visibleMessages = Array(sectionMessages[0...currentIndexpath!.row])
//                .filter { $0["status"] as? String != "4" && $0["status"] as? String != "8" }
//
//            // MARK: - Send Read Status
//            if visibleMessages.count > 0 {
//                let myPin = User.getMyPin()
//                var stringMessage: [String: String] = [:]
//                for msg in visibleMessages {
//                    if msg["f_pin"] as? String != myPin  && EditorGroup.conditionSendRead(scope: msg[TypeDataMessage.message_scope_id] as! String, fPin: msg[TypeDataMessage.f_pin] as! String, messageId: msg[TypeDataMessage.message_id] as! String) {
//                        if stringMessage[msg["f_pin"]  as? String ?? ""] == nil {
//                            stringMessage[msg["f_pin"]  as? String ?? ""] = msg["message_id"]  as? String ?? ""
//                        } else {
//                            var str1 = stringMessage[msg["f_pin"]  as? String ?? ""]!
//                            str1 += ",\(msg["message_id"]  as? String ?? "")"
//                            stringMessage[msg["f_pin"]  as? String ?? ""] = str1
//                        }
//                    }
//                }
//                if stringMessage.count > 0 {
//                    for str in stringMessage {
//                        sendReadMessageStatus(
//                            chat_id: self.dataTopic["chat_id"]  as? String ?? "",
//                            f_pin: str.key,
//                            message_scope_id: MessageScope.GROUP,
//                            message_id: str.value
//                        )
//                    }
//                }
//            }
//
//            // MARK: - Update Counter
//            updateUnreadCounter()
        }
    }
    
    private func removeScrollToBottomButton() {
        if buttonScrollToBottom.isDescendant(of: view) {
            buttonScrollToBottom.removeConstraints(buttonScrollToBottom.constraints)
            buttonScrollToBottom.removeFromSuperview()

            if indicatorCounterBSTB.isDescendant(of: view) {
                indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
                indicatorCounterBSTB.removeFromSuperview()
            }
        }
    }

    private func updateUnreadCounter() {
        if counter == 0 {
            if indicatorCounterBSTB.isDescendant(of: view) {
                indicatorCounterBSTB.removeFromSuperview()
            }
            return
        }

        guard let current = currentIndexpath else { return }

        let sectionDate = dataDates[current.section]
        let filtered = dataMessages.filter {
            ($0["chat_date"] as? String ?? "") == sectionDate
        }
        guard !filtered.isEmpty else { return }

        guard let idx = dataMessages.firstIndex(where: {
            ($0["message_id"] as? String ?? "") ==
            (filtered[current.row]["message_id"] as? String ?? "")
        }) else { return }

        guard !isPreview else {
            return
        }
        if idx >= dataMessages.count - counter {
            let delta = idx - (dataMessages.count - counter)
            counter -= (delta + 1)
            labelCounter.text = "\(counter)"
            updateCounter(counter: counter)
        }
    }
    //sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: listData[i]["f_pin"]  as? String ?? "", message_scope_id: MessageScope.GROUP, message_id: listData[i]["message_id"]  as? String ?? "")
}

extension EditorGroup: ImageVideoPickerDelegate, PreviewAttachmentImageVideoDelegate, PHPickerViewControllerDelegate {
    public func didSelect(imagevideo: Any?) {
        if (imagevideo != nil) {
            let imageVideoData = imagevideo as! [UIImagePickerController.InfoKey: Any]
            let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
            if (textFieldSend.textColor != .lightGray) {
                previewImageVC.currentTextTextField = textFieldSend.text
            }
            var att: [AttachmentItem] = []
            if (imageVideoData[.mediaType] as! String == "public.movie") {
                if let url = imageVideoData[.mediaURL] as? URL {
                    att.append(AttachmentItem(type: .video, videoURL: url))
                }
            } else {
                att.append(AttachmentItem(type: .image, image: imageVideoData[.originalImage] as? UIImage))
            }
            previewImageVC.modalPresentationStyle = .custom
            previewImageVC.delegate = self
            previewImageVC.isGroup = true
            att[0].isAck = self.isAck
            att[0].isConfidential = self.isConfidential
            previewImageVC.attachments = att
            self.present(previewImageVC, animated: true, completion: nil)
        }
    }
    
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if !isBlackCancelButton {
            let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)
        }
        guard !results.isEmpty else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        picker.dismiss(animated: true, completion: { [weak self] in
            Nexilis.showLoader(text: "Preparing...".localized())
            // Fix: the loading itself moved to PickerAttachmentLoader - see the note there
            // for what was wrong with doing it here (items loaded one after another behind a
            // semaphore, failures that left the loader up for good, a full-size decode of
            // every camera photo).
            PickerAttachmentLoader.load(results: results, onProgress: { fraction in
                // Most of the wait on a camera photo or video is iCloud handing the original
                // back, so it is worth saying how far along that is.
                Nexilis.loadingAlert.message = "\("Preparing...".localized()) \(Int(fraction * 100))%"
            }, completion: { attachments in
                guard let self = self else {
                    Nexilis.hideLoader { }
                    return
                }
                var attachments = attachments
                guard !attachments.isEmpty else {
                    // Nothing came back at all - still take the loader down rather than
                    // leaving it on screen.
                    Nexilis.hideLoader { }
                    return
                }
                Nexilis.hideLoader {
                    let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                    if (self.textFieldSend.textColor != .lightGray) {
                        previewImageVC.currentTextTextField = self.textFieldSend.text
                        attachments[0].text = self.textFieldSend.text
                    }
                    attachments[0].isAck = self.isAck
                    attachments[0].isConfidential = self.isConfidential
                    previewImageVC.attachments = attachments
                    previewImageVC.modalPresentationStyle = .custom
                    previewImageVC.delegate = self
                    previewImageVC.isGroup = true
                    self.present(previewImageVC, animated: true, completion: nil)
                }
            })
        })
    }

    
    func sendChatFromPreviewImage(message_text: String, attachment_flag: String, image_id: String, video_id: String, thumb_id: String, gif_id: String, file_id: String, viewController: UIViewController, specFile: String) {
        specFileString = specFile
        sendChat(message_text: message_text, attachment_flag: attachment_flag, image_id: image_id, video_id: video_id, file_id: file_id, thumb_id: thumb_id, viewController: viewController, gif_id : gif_id)
    }
}

extension EditorGroup: UIDocumentPickerDelegate, DocumentPickerDelegate, QLPreviewControllerDataSource {
    public func didSelectDocument(document: Any?) {
        if (document != nil) {
            let listFile = document as! [URL]
            if listFile.count > 10 {
                APIS.showWarningMaxFile()
                return
            }
            Nexilis.showLoader(text: "Scanning File...".localized())
            DispatchQueue.global().async {
                var isContinue = true
                var att: [AttachmentItem] = []
                for file in listFile {
                    let semaphore = DispatchSemaphore(value: 0)
                    DispatchQueue.global().async {
                        if Nexilis.checkingAccess(key: "content_inspection") {
                            let result = file.validateFile()
                            DispatchQueue.main.async {
                                if result == 1 {
                                    sendIt()
                                } else {
                                    Nexilis.hideLoader {
                                        APIS.showWarningFile(type: result)
                                        isContinue = false
                                    }
                                }
                                semaphore.signal()
                            }
                        } else {
                            DispatchQueue.main.async {
                                sendIt()
                            }
                            semaphore.signal()
                        }
                        
                        func sendIt() {
                            att.append(AttachmentItem(type: .file, fileURL: file))
                            if att.count == listFile.count {
                                Nexilis.hideLoader {
                                    let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                                    if (self.textFieldSend.textColor != .lightGray) {
                                        previewImageVC.currentTextTextField = self.textFieldSend.text
                                    }
                                    previewImageVC.modalPresentationStyle = .custom
                                    att[0].isAck = self.isAck
                                    att[0].isConfidential = self.isConfidential
                                    previewImageVC.delegate = self
                                    previewImageVC.isGroup = true
                                    previewImageVC.attachments = att
                                    self.present(previewImageVC, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                    semaphore.wait()
                    if !isContinue {
                        break
                    }
                }
            }
//            self.previewItem = (document as! [URL])[0] as NSURL
//            specFileString = ""
//            let previewController = QLPreviewController()
//            previewController.dataSource = self
//            let vcHandleFile = UIViewController()
//            let nc = UINavigationController(rootViewController: vcHandleFile)
//            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
//            let navBarAppearance = UINavigationBarAppearance()
//            nc.defaultStyle()
//            nc.modalPresentationStyle = .pageSheet
//            navBarAppearance.configureWithOpaqueBackground()
//            navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
//            navBarAppearance.titleTextAttributes = attributes
//            nc.navigationBar.standardAppearance = navBarAppearance
//            nc.navigationBar.scrollEdgeAppearance = navBarAppearance
//            let backButton = navigationQLPreviewDocument(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancelDocumentPreview))
//            vcHandleFile.navigationItem.leftBarButtonItem = backButton
//            let sendButton = navigationQLPreviewDocument(title: "Send".localized(), style: .done, target: self, action: #selector(sendDocument))
//            buttonSpec.setImage(UIImage(named: "pb_ic_attach_spc_off", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 30, height: 30)), for: .normal)
//            buttonSpec.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//            buttonSpec.addTarget(self, action: #selector(showConfigurationFile), for: .touchUpInside)
//            let barButtonItemSpec = UIBarButtonItem(customView: buttonSpec)
//            vcHandleFile.navigationItem.rightBarButtonItems = [sendButton, barButtonItemSpec]
//            backButton.navigation = nc
//            sendButton.navigation = nc
//            if let viewVc = vcHandleFile.view {
//                vcHandleFile.title = self.previewItem?.lastPathComponent
//                vcHandleFile.addChild(previewController)
//                previewController.dataSource = self
//                previewController.view.frame = CGRect(x: 0, y: 0, width: viewVc.bounds.size.width, height: viewVc.bounds.size.height)
//                previewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//                viewVc.addSubview(previewController.view)
//                previewController.didMove(toParent: vcHandleFile)
//
//                self.present(nc, animated: true)
//            }
        }
    }
    
    @objc private func showConfigurationFile() {
        let modalVC = UIViewController()
        if let viewModal = modalVC.view {
            viewModal.backgroundColor = .whiteBubbleColor
            
            let closeButton = UIButton(type: .close)
            viewModal.addSubview(closeButton)
            closeButton.anchor(top: viewModal.topAnchor, right: viewModal.rightAnchor, paddingTop: 15, paddingRight: 15, width: 30, height: 30)
            closeButton.layer.cornerRadius = 15
            closeButton.clipsToBounds = true
            closeButton.backgroundColor = .lightGray.withAlphaComponent(0.1)
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
            closeButton.addAction(UIAction { _ in
                modalVC.dismiss(animated: true)
            }, for: .touchUpInside)
            
            let imageSpec = UIButton(type: .custom)
            viewModal.addSubview(imageSpec)
            imageSpec.anchor(top: viewModal.topAnchor, left: viewModal.leftAnchor, paddingTop: 25, paddingLeft: 15, width: 40, height: 40)
            imageSpec.layer.cornerRadius = 20
            imageSpec.clipsToBounds = true
            imageSpec.backgroundColor = .lightGray.withAlphaComponent(0.1)
            imageSpec.setImage(UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 35, height: 35)), for: .normal)
            
            let title = UILabel()
            title.text = "Option for Attachment".localized()
            viewModal.addSubview(title)
            title.anchor(top: viewModal.topAnchor, left: imageSpec.rightAnchor, paddingTop: 23, paddingLeft: 10)
            title.textColor = .label
            title.font = .boldSystemFont(ofSize: 16)
            
            let subtitle = UILabel()
            subtitle.text = "Select option :".localized()
            viewModal.addSubview(subtitle)
            subtitle.anchor(top: title.bottomAnchor, left: imageSpec.rightAnchor, paddingLeft: 10)
            subtitle.textColor = .gray
            subtitle.font = .systemFont(ofSize: 14)
            
            tableViewConfigFile = UITableView()
            viewModal.addSubview(tableViewConfigFile)
            tableViewConfigFile.backgroundColor = .white
            tableViewConfigFile.layer.cornerRadius = 8.0
            tableViewConfigFile.clipsToBounds = true
            tableViewConfigFile.anchor(top: imageSpec.bottomAnchor, left: viewModal.leftAnchor, bottom: viewModal.bottomAnchor, right: viewModal.rightAnchor, paddingTop: 15, paddingLeft: 15, paddingBottom: 80, paddingRight: 15)
            tableViewConfigFile.register(UITableViewCell.self, forCellReuseIdentifier: "cellConfigFile")
            tableViewConfigFile.dataSource = self
            tableViewConfigFile.delegate = self
            tableViewConfigFile.separatorStyle = .singleLine
            tableViewConfigFile.tableFooterView = UIView()
            if #available(iOS 15.0, *) {
                tableViewConfigFile.sectionHeaderTopPadding = 0
            }
            
            if #available(iOS 15.0, *) {
                if let sheet = modalVC.sheetPresentationController {
                    sheet.detents = [.medium()]
                }
            } else {
                // Fallback on earlier versions
            }
        }
        UIApplication.shared.visibleViewController?.present(modalVC, animated: true)
    }
    
    @objc private func cancelDocumentPreview(sender: navigationQLPreviewDocument) {
        sender.navigation.dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendDocument(sender: navigationQLPreviewDocument) {
        DispatchQueue.global().async {
            if Nexilis.checkingAccess(key: "content_inspection") {
                DispatchQueue.main.async {
                    Nexilis.showLoader(text: "Scanning File...".localized())
                }
                let result = (self.previewItem! as URL).validateFile()
                DispatchQueue.main.async {
                    Nexilis.hideLoader {
                        sender.navigation.dismiss(animated: true, completion: {
                            if result == 1 {
                                sendIt()
                            } else {
                                APIS.showWarningFile(type: result)
                            }
                        })
                    }
                }
            } else {
                DispatchQueue.main.async {
                    sendIt()
                }
            }
            
            func sendIt() {
                sender.navigation.dismiss(animated: true, completion: nil)

                guard let previewItem = self.previewItem else { return }
                guard var dataFile = try? Data(contentsOf: previewItem as URL) else { return }

                func sanitizeFile(mimeType: String, sanitizeAction: (Data) -> MessageGuardLite.Result) -> Data? {
                    DispatchQueue.main.async {
                        Nexilis.showLoader(text: "Sanitizing your \(mimeType.contains("pdf") ? "pdf file" : "image") (Message Guard)".localized())
                    }
                    let res = sanitizeAction(dataFile)
                    defer {
                        DispatchQueue.main.async { Nexilis.hideLoader {} }
                    }

                    if res.verdict == .block {
                        DispatchQueue.main.async {
                            Nexilis.hideLoader {
                                APIS.showMessageGuardFile(mime: res.mime)
                            }
                        }
                        return nil
                    }
                    return res.data ?? Data()
                }

                func processIt(with data: Data) {
                    guard let urlFile = self.previewItem?.absoluteString else { return }
                    let originalFileName = (urlFile as NSString).lastPathComponent.removingPercentEncoding ?? "file"
                    let renamedNameFile = "Nexilis_\(Date().currentTimeMillis())_\(originalFileName)"

                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let fileURL = documentsDirectory.appendingPathComponent(renamedNameFile)

                    if !FileManager.default.fileExists(atPath: fileURL.path) {
                        try? data.write(to: fileURL)
                    }

                    DispatchQueue.main.async {
                        self.sendChat(
                            message_text: "\(originalFileName)|",
                            attachment_flag: "6",
                            file_id: renamedNameFile,
                            viewController: self
                        )
                    }
                }

                if Nexilis.checkingAccess(key: "message_guard") {
                    DispatchQueue.global().async {
                        let guardLite = MessageGuardLite(limits: .defaults())
                        let mimeType = MessageGuardLite.sniffMime(dataFile)

                        if mimeType == "image/png" || mimeType == "image/jpeg" {
                            if let sanitized = sanitizeFile(mimeType: mimeType, sanitizeAction: guardLite.sanitizeImage) {
                                dataFile = sanitized
                            } else { return }
                        } else if mimeType == "application/pdf" {
                            if let sanitized = sanitizeFile(mimeType: mimeType, sanitizeAction: guardLite.sanitizePdf) {
                                dataFile = sanitized
                            } else { return }
                        }

                        processIt(with: dataFile)
                    }
                } else {
                    processIt(with: dataFile)
                }
            }
        }
    }
}

extension EditorGroup: UITextViewDelegate, CustomTextViewPasteDelegate {
    func customTextViewDidPasteText(image: UIImage?, dataGIF: Data?) {
        let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
        var att: [AttachmentItem] = []
        if dataGIF == nil {
            att.append(AttachmentItem(type: .image, image: image))
        } else {
            att.append(AttachmentItem(type: .gif, gif: dataGIF))
        }
        previewImageVC.fromCopy = true
        previewImageVC.currentTextTextField = textFieldSend.text
        previewImageVC.modalPresentationStyle = .custom
        previewImageVC.delegate = self
        previewImageVC.isGroup = true
        att[0].isAck = self.isAck
        att[0].isConfidential = self.isConfidential
        previewImageVC.attachments = att
        self.present(previewImageVC, animated: true, completion: nil)
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        lastPositionCursorMention = textView.selectedRange.location
        var isShowMention = false

        let fulltextForMention = textView.text.prefix(lastPositionCursorMention)
        
        let lines = fulltextForMention.split(separator: "\n")
        if let lastLineIndex = lines.lastIndex(where: { !$0.isEmpty }) {
            let words = lines[lastLineIndex].split(separator: " ")
            if let lastWordIndex = words.lastIndex(where: { !$0.isEmpty }) {
                let mentionText = words[lastWordIndex]
                let lastChar = fulltextForMention.last
                if lastChar != "\n" && lastChar != " " {
                    if mentionText.starts(with: "@") || (mentionText.count >= 2 && (self.textFieldSend.textColor != UIColor.lightGray || heightTableEditMention != nil) && extractFromAtIfSymbolsBefore(String(mentionText)) == nil) {
                        showMention(text: mentionText.starts(with: "@") ? String(mentionText.dropFirst()) : String(mentionText))
                        isShowMention = true
                    } else if let textM = extractFromAtIfSymbolsBefore(String(mentionText)) {
                        showMention(text: String(textM.dropFirst()))
                        isShowMention = true
                    }
                }
            }
        }
        
        if !isShowMention {
            hideMention()
        }

        if var nowTextFieldSend = self.textFieldSend {
            if isEditingMessage {
                nowTextFieldSend = editTextView
            }
            if let sr = nowTextFieldSend.selectedTextRange {
                if let fnt = nowTextFieldSend.font {
                    let cursorPosition = textView.caretRect(for: sr.start).origin
                    let doubleCurrentLine = cursorPosition.y / fnt.lineHeight
                    if doubleCurrentLine.isFinite {
                        let currentLine = Int(ceil(doubleCurrentLine))
                        UIView.animate(withDuration: 0.3) {
                            let layoutManager = textView.layoutManager
                            var numberOfLines = 0
                            var index = 0
                            let numberOfGlyphs = layoutManager.numberOfGlyphs

                            while index < numberOfGlyphs {
                                var lineRange = NSRange()
                                layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
                                index = NSMaxRange(lineRange)
                                numberOfLines += 1
                            }
                            if currentLine == 1 && (numberOfLines == 1 || numberOfLines == 0) {
                                if self.isEditingMessage {
                                    self.constraintHeighteditTextView.constant = 40
                                } else {
                                    self.heightTextFieldSend.constant = 40
                                }
                            } else if (self.heightTextFieldSend.constant < 95.0 || (self.constraintHeighteditTextView != nil && self.constraintHeighteditTextView.constant < 95.0)) && currentLine >= 4 {
                                if self.isEditingMessage {
                                    self.constraintHeighteditTextView.constant = 95.0
                                } else {
                                    self.heightTextFieldSend.constant = 95.0
                                }
                            } else if currentLine < 4 && numberOfLines < 5 {
                                if (nowTextFieldSend.text.count > 0 && self.heightTextFieldSend.constant != nowTextFieldSend.contentSize.height) {
                                    if self.isEditingMessage {
                                        self.constraintHeighteditTextView.constant = nowTextFieldSend.contentSize.height
                                    } else {
                                        self.heightTextFieldSend.constant = nowTextFieldSend.contentSize.height
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if self.isEditingMessage && textView == editTextView {
            if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                buttonSendEdit.isEnabled = false
            } else if !buttonSendEdit.isEnabled {
                buttonSendEdit.isEnabled = true
            }
        }
        
        //indention code:
        let text = textView.text ?? ""
        let cursorLocation = textView.selectedRange.location

        // Find current line range where cursor is
        if let lineRange = (text as NSString).lineRange(for: NSRange(location: cursorLocation, length: 0)) as NSRange? {
            let line = (text as NSString).substring(with: lineRange)

            // Detect bullet ("  •") or numbered ("  1.") list
            if line.hasPrefix("  •") || line.range(of: #"^\s{2}\d+\."#, options: .regularExpression) != nil {
                var bulletEnd = lineRange.location + 2
                if !line.hasPrefix("  •") {
                    bulletEnd = lineRange.location + 3
                }

                // Prevent cursor before bullet/number
                if cursorLocation < bulletEnd {
                    DispatchQueue.main.async {
                        textView.selectedRange = NSRange(location: bulletEnd, length: 0)
                    }
                }
            }
        }
    }
    
    func extractFromAtIfSymbolsBefore(_ text: String) -> String? {
        guard let atIndex = text.firstIndex(of: "@") else {
            return nil
        }
        
        let beforeAt = text[..<atIndex]
        let afterAt = text[atIndex...]

        // Define symbols as anything that's not a letter or digit
        let symbolSet = CharacterSet.letters.union(.decimalDigits).inverted
        let isAllSymbols = beforeAt.unicodeScalars.allSatisfy { symbolSet.contains($0) }

        return isAllSymbols ? String(afterAt) : nil
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        if textView.text.count == 0 {
            isAlwaysHideLinkPreview = false
        }
        if allowTyping {
            allowTyping = false
            if dataTopic["chat_id"]  as? String ?? "" == "" {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [dataGroup["group_id"]  as? String ?? ""])
                sendTyping(l_pin: dataGroup["group_id"]  as? String ?? "")
            } else {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [dataTopic["chat_id"]  as? String ?? ""])
                sendTyping(l_pin: dataTopic["chat_id"]  as? String ?? "")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
                self.allowTyping = true
            })
        }
        timerCheckLink?.invalidate()
        timerCheckLink = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {_ in
            self.checkLink(fullText: textView.text)
        })
        
        //indention code:
        let text = textView.text ?? ""
        let cursorPosition = textView.selectedRange.location
        
        let tempListMention = listMentionInTextField
        if listMentionInTextField.count > 0 {
            for j in 0..<listMentionInTextField.count {
                var index = j
                if tempListMention.count != listMentionInTextField.count {
                    index = j - (tempListMention.count - listMentionInTextField.count)
                }
                var upper = (Int(listMentionInTextField[index].ex_block ?? "0") ?? 0)
                if cursorPosition <= upper {
                    upper += text.count - lastTextLength
                    listMentionInTextField[index].ex_block = "\(upper)"
                }
                let lower = upper - listMentionInTextField[index].fullName.count
                let name = listMentionInTextField[index].fullName.trimmingCharacters(in: .whitespaces)
                if textView.text.substring(from: lower, to: upper) != "@\(name)" {
                    listMentionInTextField.remove(at: index)
                }
            }
        }
        
        // Handle Bullets (- [space] + letter → • )
        let bulletPattern = #"(?<=\n|^)- (\S)"#
        if let match = text.range(of: bulletPattern, options: .regularExpression) {
            let matchedText = text[match]

            if let spaceIndex = matchedText.firstIndex(of: " ") {
                let firstLetter = matchedText[matchedText.index(after: spaceIndex)...]
                let replacedText = text.replacingOccurrences(of: matchedText, with: "  • \(firstLetter)", range: match)

                let newCursorPosition = cursorPosition + 2  // Adjust cursor position
                textView.text = replacedText
                DispatchQueue.main.async {
                    textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
                }
            }
        }

        // Handle Numbered Lists (e.g., "1. " [space] + letter → " 1.")
        let numberPattern = #"(?<=\n|^)(\d+)\. (\S)"# // Matches "1. X"
        if let match = text.range(of: numberPattern, options: .regularExpression) {
            let matchedText = text[match]

            let replacedText = text.replacingOccurrences(of: matchedText, with: "  \(matchedText)", range: match)

            let newCursorPosition = cursorPosition + 2  // Adjust cursor
            textView.text = replacedText
            DispatchQueue.main.async {
                textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
            }
        }

        handleRichText(textView)
        lastTextLength = text.count
    }
    
    private func showMention(text: String) {
        if self.contraintBottomMention.constant < 0 {
            if !isEditingMessage {
                self.contraintBottomMention.constant = 25 + constraintBottomAttachment.constant + self.heightTextFieldSend.constant + self.viewTextfield.bounds.height
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
        listMentionWithText.removeAll()
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                let idMe = User.getMyPin()!
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name || ' ' || ifnull(last_name, '') name FROM GROUPZ_MEMBER where group_id='\(self.dataGroup["group_id"]  as? String ?? "")' AND f_pin <> '\(idMe)' AND name LIKE '%\(text)%'") {
                    while cursor.next() {
                        let user = User(pin: "")
                        user.pin = cursor.string(forColumnIndex: 0) ?? ""
                        user.firstName = cursor.string(forColumnIndex: 1) ?? ""
                        if !user.pin.isEmpty {
                            let userFromBuddy = User.getDataCanNil(pin: user.pin, fmdb: fmdb)
                            if userFromBuddy != nil {
                                listMentionWithText.append(userFromBuddy!)
                            } else {
                                listMentionWithText.append(user)
                            }
                        }
                    }
                    if Utils.getGPTBotName().lowercased().contains(text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let gptUser = User(pin: "-997",
                                        firstName: Utils.getGPTBotName(),
                                        lastName: "",
                                        thumb: "",
                                        userType: "0",
                                        official: "1")
                        listMentionWithText.insert(gptUser, at: 0)
                    }
                    cursor.close()
                }
                listMentionWithText.removeAll(where: { listMentionInTextField.contains($0) })
                var nowTableMention = tableMention!
                var nowHeightTableMention = heightTableMention!
                if isEditingMessage {
                    nowTableMention = tableMentionEdit
                    if heightTableEditMention != nil {
                        nowHeightTableMention = heightTableEditMention
                    } else {
                        return
                    }
                }
                if listMentionWithText.count > 0 {
                    if listMentionWithText.count < 5 {
                        nowHeightTableMention.constant = CGFloat(44 * listMentionWithText.count)
                    } else {
                        nowHeightTableMention.constant = 44 * 4
                    }
                    nowTableMention.reloadData()
                } else {
                    nowHeightTableMention.constant = 44
                    self.hideMention()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func hideMention() {
        if self.contraintBottomMention.constant > 0 {
            listMentionWithText.removeAll()
            tableMention.reloadData()
            self.contraintBottomMention.constant = 0 - self.heightTableMention.constant
            UIView.animate(withDuration: 0.5, animations: {
                self.view.layoutIfNeeded()
            })
        } else if self.heightTableEditMention != nil && self.heightTableEditMention.constant != 0 {
            listMentionWithText.removeAll()
            tableMentionEdit.reloadData()
            self.heightTableEditMention.constant = 0
        }
    }
    
    private func checkLink(fullText: String) {
        if !isAlwaysHideLinkPreview {
            var text = ""
            let listTextSplitBreak = fullText.components(separatedBy: "\n")
            let indexFirstLinkSplitBreak = listTextSplitBreak.firstIndex(where: { $0.contains("www.") || $0.contains("http://") || $0.contains("https://") })
            if indexFirstLinkSplitBreak != nil {
                let listTextSplitSpace = listTextSplitBreak[indexFirstLinkSplitBreak!].components(separatedBy: " ")
                let indexFirstLinkSplitSpace = listTextSplitSpace.firstIndex(where: { ($0.starts(with: "www.") && $0.components(separatedBy: ".").count > 2) || ($0.starts(with: "http://") && $0.components(separatedBy: ".").count > 1) || ($0.starts(with: "https://") && $0.components(separatedBy: ".").count > 1) })
                if indexFirstLinkSplitSpace != nil {
                    text = listTextSplitSpace[indexFirstLinkSplitSpace!]
                }
            }
            if !text.isEmpty {
                var stringURl = text
                if stringURl.starts(with: "www.") {
                    stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
                }
                var dataURL = ""
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select data_link from LINK_PREVIEW where link='\(text)'") {
                            while cursor.next() {
                                if let data = cursor.string(forColumnIndex: 0) {
                                    dataURL = data
                                }
                            }
                            cursor.close()
                        }
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
                if !dataURL.isEmpty {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let imageUrl = data["imageUrl"] as? String
                        let link = data["link"]  as? String ?? ""
                        if imageUrl == nil || (link.contains("youtube.com") && link.contains("watch?v=") && !imageUrl!.contains("img.youtube.com/vi/")) {
                            dataURL = ""
                        }
                    }
                }
                if !dataURL.isEmpty {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let title = data["title"]  as? String ?? ""
                        let description = data["description"]  as? String ?? ""
                        let imageUrl = data["imageUrl"] as? String
                        if self.showingLink != text {
                            self.showingLink = text
                            self.deleteLinkPreview()
                            if !textFieldSend.text.isEmpty || textFieldSend.text.contains(text){
                                self.buildPreviewLink(imageUrl: imageUrl, title: title, description: description, stringURl: text)
                            }
                        }
                    }
                } else {
                    let urlConfig = URLSessionConfiguration.default
                    let sessionDelegate = PinnedURLSessionNexilisDelegate()
                    let session = URLSession(configuration: urlConfig, delegate: sessionDelegate, delegateQueue: nil)
                    let slp = SwiftLinkPreview(session: session,
                                   workQueue: SwiftLinkPreview.defaultWorkQueue,
                                   responseQueue: DispatchQueue.main,
                                       cache: DisabledCache.instance)
                    let preview = slp.preview(stringURl,
                                              onSuccess: { result in
                        let title = result.title?.trimmingCharacters(in: .whitespacesAndNewlines)
                                    .nilIfEmpty ?? URL(string: text)?.host ?? "Untitled"
                        let description: String
                        if text.contains("google.com") {
                            description = "" // special rule for google
                        } else {
                            description = result.description?.trimmingCharacters(in: .whitespacesAndNewlines)
                                .nilIfEmpty ?? ""
                        }
                        let imageUrl = self.youtubeThumbnail(from: text)
                            ?? result.image
                            ?? result.icon
                            ?? ""
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                var dataJson: [String: Any] = [:]
                                dataJson["title"] = title
                                dataJson["description"] = description
                                dataJson["imageUrl"] = imageUrl
                                dataJson["link"] = text
                                guard let json = String(data: try! JSONSerialization.data(withJSONObject: dataJson, options: []), encoding: String.Encoding.utf8) else {
                                    return
                                }
                                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "LINK_PREVIEW", cvalues: [
                                    "id" : "\(Date().currentTimeMillis().toHex())",
                                    "link" : text,
                                    "data_link" : json,
                                    "retry": 0
                                ], replace: true)
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                        if self.showingLink != text {
                            self.showingLink = text
                            self.deleteLinkPreview()
                            if !self.textFieldSend.text.isEmpty || self.textFieldSend.text.contains(text){
                                self.buildPreviewLink(imageUrl: imageUrl, title: title, description: description, stringURl: text)
                            }
                        }
                    },
                    onError: { error in
                        self.deleteLinkPreview()
                    })
                }
            } else {
                deleteLinkPreview()
            }
        }
    }
    
    private func buildPreviewLink(imageUrl: String?, title: String, description: String?, stringURl: String) {
        if !self.viewTextfield.subviews.contains(self.containerLink){
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant + 80
                if self.contraintBottomMention.constant > 0 {
                    self.contraintBottomMention.constant = self.contraintBottomMention.constant + 80 + self.heightTextFieldSend.constant
                }
            }, completion: nil)
        }
        
        self.viewTextfield.addSubview(self.containerLink)
        self.containerLink.translatesAutoresizingMaskIntoConstraints = false
        self.containerLink.leadingAnchor.constraint(equalTo: self.viewTextfield.leadingAnchor).isActive = true
        self.containerLink.bottomAnchor.constraint(equalTo: self.textFieldSend.topAnchor).isActive = true
        self.containerLink.trailingAnchor.constraint(equalTo: self.viewTextfield.trailingAnchor).isActive = true
        self.containerLink.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
        self.containerLink.backgroundColor = .secondaryColor
        
        if self.reffId != nil {
            self.bottomAnchorPreviewReply.isActive = false
            self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.containerLink.topAnchor)
            self.bottomAnchorPreviewReply.isActive = true
        }
        
        let imagePreview = UIImageView()
        if imageUrl != nil {
            self.containerLink.addSubview(imagePreview)
            imagePreview.translatesAutoresizingMaskIntoConstraints = false
            imagePreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor).isActive = true
            imagePreview.bottomAnchor.constraint(equalTo: self.containerLink.bottomAnchor).isActive = true
            imagePreview.topAnchor.constraint(equalTo: self.containerLink.topAnchor).isActive = true
            imagePreview.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
            imagePreview.loadImageAsync(with: imageUrl)
            imagePreview.contentMode = .scaleAspectFit
        }
        
        let titlePreview = UILabel()
        self.containerLink.addSubview(titlePreview)
        titlePreview.translatesAutoresizingMaskIntoConstraints = false
        if imageUrl != nil {
            titlePreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
        } else {
            titlePreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor, constant: 5.0).isActive = true
        }
        titlePreview.topAnchor.constraint(equalTo: self.containerLink.topAnchor, constant: 25.0).isActive = true
        titlePreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -80.0).isActive = true
        titlePreview.text = title
        titlePreview.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        titlePreview.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        
        let descPreview = UILabel()
        self.containerLink.addSubview(descPreview)
        descPreview.translatesAutoresizingMaskIntoConstraints = false
        if imageUrl != nil {
            descPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
        } else {
            descPreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor, constant: 5.0).isActive = true
        }
        descPreview.topAnchor.constraint(equalTo: titlePreview.bottomAnchor).isActive = true
        descPreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -80.0).isActive = true
        descPreview.text = description
        descPreview.font = UIFont.systemFont(ofSize: 12.0 + offset())
        descPreview.textColor = .gray
        descPreview.numberOfLines = 1
        
        let linkPreview = UILabel()
        self.containerLink.addSubview(linkPreview)
        linkPreview.translatesAutoresizingMaskIntoConstraints = false
        if imageUrl != nil {
            linkPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
        } else {
            linkPreview.leadingAnchor.constraint(equalTo: self.containerLink.leadingAnchor, constant: 5.0).isActive = true
        }
        linkPreview.topAnchor.constraint(equalTo: descPreview.bottomAnchor).isActive = true
        linkPreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -80.0).isActive = true
        linkPreview.text = stringURl
        linkPreview.font = UIFont.systemFont(ofSize: 10.0 + offset())
        linkPreview.textColor = .gray
        linkPreview.numberOfLines = 1
        
        let cancelPreview = UIButton(type: .custom)
        self.containerLink.addSubview(cancelPreview)
        cancelPreview.translatesAutoresizingMaskIntoConstraints = false
        cancelPreview.trailingAnchor.constraint(equalTo: self.containerLink.trailingAnchor, constant: -10).isActive = true
        cancelPreview.centerYAnchor.constraint(equalTo: self.containerLink.centerYAnchor).isActive = true
        cancelPreview.setImage(UIImage(systemName: "xmark.circle" , withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)), for: .normal)
        cancelPreview.addTarget(nil, action: #selector(self.removeLinkPreviewUntilEmptyTextView), for: .touchUpInside)
        cancelPreview.backgroundColor = .clear
        cancelPreview.tintColor = .mainColor
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        // Anything the reader writes belongs at the end of the conversation, so the window has
        // to be back there before it is sent - otherwise the new message would be drawn at the
        // bottom of a window that stops months ago.
        if textView == textFieldSend, !isWindowAtNewest {
            jumpToNewestPage()
            tableChatView.scrollToBottom(isAnimated: false, delay: 0)
        }
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty && textView != editTextView {
            textView.textColor = UIColor.lightGray
            textView.text = "Send message".localized()
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty {
            if listMentionInTextField.count > 0 {
                for i in 0..<listMentionInTextField.count {
                    if lastPositionCursorMention == Int(listMentionInTextField[i].ex_block!)! + 1 {
                        let fulltextForMention = textView.text.substring(from: 0, to: lastPositionCursorMention - 1)
                        let diff = textView.text.count - fulltextForMention.count
                        var text = textView.text ?? ""
                        let nameMention = listMentionInTextField[i].fullName.trimmingCharacters(in: .whitespaces)
                        let rangeReplacement = NSRange(location: lastPositionCursorMention - nameMention.count - 1, length: nameMention.count + 1)
                        let replacementText = ""
                        
                        let copyAttributedText = text.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
                        copyAttributedText.removeAttribute(.foregroundColor, range: rangeReplacement)
                        
                        textView.attributedText = copyAttributedText

                        // Replace the old text with the new text using the replaceSubrange(_:with:) method
                        if let startIndex = text.index(text.startIndex, offsetBy: rangeReplacement.location, limitedBy: text.endIndex),
                           let endIndex = text.index(startIndex, offsetBy: rangeReplacement.length, limitedBy: text.endIndex) {
                            text.replaceSubrange(startIndex..<endIndex, with: replacementText)
                        }
                        listMentionInTextField.remove(at: i)
                        
                        textView.attributedText = text.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
                        
                        let newPosition = textView.position(from: textView.beginningOfDocument, offset: textView.text.count - diff)
                        textView.selectedTextRange = textView.textRange(from: newPosition!, to: newPosition!)
                        textViewDidChangeSelection(textView)
                        handleRichText(textView)
                        return false
                    }
                }
            }
        }
        let indent = handleIndent(textView, range, text)
        if !indent {
            textViewDidChangeSelection(textView)
            handleRichText(textView)
            return indent
        }
        if (textView.text.count == 0) {
            return text != "\n"
        }
        return true
    }
    
    private func handleIndent(_ textView: UITextView, _ range: NSRange, _ text: String) -> Bool {
        guard let nsText = textView.text as NSString? else { return true }

        // Ensure valid range
        guard range.location <= nsText.length else { return true }

        let newText = nsText.replacingCharacters(in: range, with: text)
        var lines = newText.components(separatedBy: "\n")

        guard let textRange = Range(range, in: textView.text) else { return true }
        let prefixText = textView.text[..<textRange.lowerBound]
        let affectedLineIndex = max(prefixText.components(separatedBy: "\n").count - 1, 0)
        guard affectedLineIndex < lines.count else { return true }

        let affectedLine = lines[affectedLineIndex]

        // ---- Auto-indent new lines ----
        if text == "\n" {
            let previousLine = lines[affectedLineIndex]

            // Handle bullet points
            if previousLine.hasPrefix("  •") {
                let newBullet = "\n  • "
                safeReplaceText(in: textView, range: range, with: newBullet)
                return false
            }

            // Handle numbered list continuation
            if let match = previousLine.range(of: #"^\s{2}(\d+)\."#, options: .regularExpression),
               let numberMatch = previousLine[match].components(separatedBy: ".").first,
               let number = Int(numberMatch.trimmingCharacters(in: .whitespaces)) {
                let newNumber = "\n  \(number + 1). "
                safeReplaceText(in: textView, range: range, with: newNumber)
                return false
            }
        }

        // ---- Handle backspace cases ----
        if text.isEmpty {
            // Empty bullet → "- "
            if affectedLine.trimmingCharacters(in: .whitespaces) == "•" {
                lines[affectedLineIndex] = "- "
                updateTextView(textView, with: lines.joined(separator: "\n"), cursorOffset: -1)
                return false
            }

            // Bullet or number deletion checks, safely bounded
            if range.location >= 2,
               let twoChars = textView.text.substring(with: NSRange(location: range.location - 2, length: 2)),
               twoChars == "  " {
                lines[affectedLineIndex] = affectedLine.trimmingCharacters(in: .whitespaces)
                updateTextView(textView, with: lines.joined(separator: "\n"), cursorOffset: -2)
                return false
            }
        }

        return true
    }
    
    private func safeReplaceText(in textView: UITextView, range: NSRange, with newText: String) {
        let nsText = textView.text as NSString
        textView.text = nsText.replacingCharacters(in: range, with: newText)
        DispatchQueue.main.async {
            textView.selectedRange = NSRange(location: range.location + newText.utf16.count, length: 0)
        }
    }

    private func updateTextView(_ textView: UITextView, with newText: String, cursorOffset: Int) {
        textView.text = newText
        DispatchQueue.main.async {
            let newLoc = max(textView.selectedRange.location + cursorOffset, 0)
            textView.selectedRange = NSRange(location: newLoc, length: 0)
        }
    }
    
    private func handleRichText(_ textView: UITextView) {
        // See UITextView.applyRichText - it is what keeps this from blinking and jumping to
        // the bottom of the box on every keystroke.
        textView.applyRichText(textView.text.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: self.listMentionInTextField))
    }
    
    // Fix: with messageText.isSelectable = false, UIKit no longer invokes this
    // delegate method at all for any interaction type - link tap handling in
    // UITextView is gated by isSelectable (same as text selection). It's left in
    // place, unreachable in practice, purely as a defensive fallback in case that
    // iOS behavior ever changes - the real logic now lives in
    // handleMessageTextTap(_:) (taps, via a plain UITapGestureRecognizer) and
    // contextMenuInteraction(_:configurationForMenuAtLocation:) (long-press, via
    // containerMessage's UIContextMenuInteraction, presenting LinkActionSheetViewController).
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL?, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        var urlString: String?

        if let url = URL {
            urlString = url.absoluteString
        } else {
            if let range = Range(characterRange, in: textView.text) {
                let tappedText = String(textView.text[range])
                urlString = tappedText
            }
        }
        
        guard let finalURL = urlString else {
            return false
        }

        switch interaction {
        case .invokeDefaultAction:
            showLinkHighlight(range: characterRange, in: textView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.hideLinkHighlight()
            }
            LinkOpener.open(urlString: finalURL)
            return false

        case .presentActions:
            return false

        case .preview:
            return false

        @unknown default:
            return true
        }
    }
}

extension EditorGroup: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        lastContextMenuView = nil
        lastContextMenuInteraction = nil
        // The menu is going away and its UIActions own their handlers anyway - keeping the
        // duplicates here would just be a strong reference back to self that outlives it.
        contextMenuActionHandlers.removeAll()
        if showMenuContext {
            showMenuContext = false
            interaction.view!.removeInteraction(interaction)
        }
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: (any UIContextMenuInteractionAnimating)?) {
        lastContextMenuView = interaction.view
        lastContextMenuInteraction = interaction
    }

    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        // Fix: this used to be where the "Open Link"/"Copy" sheet got triggered too
        // (containerMessage's UIContextMenuInteraction recognizes a stationary hold
        // reliably, at its own ~0.3-0.5s default threshold - not directly
        // configurable via public API). That's now too fast for the requested
        // "hold for a full second, like WhatsApp" behavior, so the actual timing +
        // sheet-triggering moved to handleLinkTouchHighlight's own timer (LinkHighlighting.longPressThreshold)
        // (tracked independently from the moment the finger touches down, via
        // LinkTouchHighlightGesture). This delegate method now ONLY suppresses the
        // bubble-wide Star/Reply/Forward/... menu when the touch is on a link -
        // still necessary, since containerMessage's interaction still recognizes
        // over links at its own faster threshold and would otherwise show that menu
        // on top of things well before the threshold is reached.
        if LinkHighlighting.linkHit(at: location, in: interaction.view) != nil {
            return nil
        }

        if textFieldSend.isFirstResponder {
            textFieldSend.resignFirstResponder()
        }
        // Fix: these closures capture self strongly (they always have - they're the very
        // same closures that used to go straight into UIAction), so the ones registered
        // by the previous long-press are dropped here rather than piling up on self.
        contextMenuActionHandlers.removeAll()
        let indexPath = self.tableChatView.indexPathForRow(at: interaction.view!.convert(location, to: self.tableChatView))
        let dataMessages = self.messages(onDate: dataDates[indexPath!.section])
        var star: UIAction
        if (dataMessages[indexPath!.row]["is_stared"]  as? String ?? "" == "0") {
            star = chatMenuAction(title: "Star".localized(), image: UIImage(systemName: "star"), handler: {(_) in
                if self.removed {
                    return
                }
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                "is_stared" : 1
                            ], _where: "message_id = '\(dataMessages[indexPath!.row]["message_id"]  as? String ?? "")'")
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == dataMessages[indexPath!.row]["message_id"]  as? String ?? ""})
                if idx != nil{
                    self.dataMessages[idx!]["is_stared"] = "1"
                }
                self.tableChatView.reloadRows(at: [indexPath!], with: .none)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "listenerStarMessage"), object: nil, userInfo: nil)
            })
        } else {
            star = chatMenuAction(title: "Unstar".localized(), image: UIImage(systemName: "star.slash"), handler: {(_) in
                if self.removed {
                    return
                }
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                "is_stared" : 0
                            ], _where: "message_id = '\(dataMessages[indexPath!.row]["message_id"]  as? String ?? "")'")
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == dataMessages[indexPath!.row]["message_id"]  as? String ?? ""})
                if idx != nil{
                    self.dataMessages[idx!]["is_stared"] = "0"
                }
                self.tableChatView.reloadRows(at: [indexPath!], with: .none)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "listenerStarMessage"), object: nil, userInfo: nil)
            })
        }
        
        let reply = chatMenuAction(title: "Reply".localized(), image: UIImage(systemName: "arrowshape.turn.up.left"), handler: {(_) in
            if self.removed {
                return
            }
            if self.isSearching {
                self.cancelAction()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                self.handleReply(indexPath: indexPath!)
            })
        })
        var pin: UIAction
        if (dataMessages[indexPath!.row][TypeDataMessage.is_pinned] as? String ?? "0" == "0") {
            pin = chatMenuAction(title: "Pin".localized(), image: UIImage(systemName: "pin"), handler: {(_) in
                if self.removed {
                    return
                }
                if self.isSearching {
                    self.cancelAction()
                }
                var checkDataPinned = self.pinnedMessagesForBanner()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                    if checkDataPinned.count == 3 {
                        let alert = UIAlertController(title: "Replace oldest pin?".localized(),
                                                      message: "Your pin will replace the oldest one.".localized(),
                                                      preferredStyle: .alert)

                        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
                            proceedPinned(replace: true)
                        })

                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        })
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        proceedPinned()
                    }
                })
                func proceedPinned(replace: Bool = false) {
                    if !CheckConnection.isConnectedToNetwork() || API.nGetCLXConnState() == 0 {
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                        return
                    }
                    if replace {
                        checkDataPinned.sort {
                            let firstPinned = Int64($0[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
                            let secondPinned = Int64($1[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
                            return firstPinned < secondPinned
                        }
                        self.proceedPinUnpinMessage(checkDataPinned: checkDataPinned[0], isPinned: false) { res1 in
                            if res1 {
                                self.proceedPinUnpinMessage(checkDataPinned: dataMessages[indexPath!.row], isPinned: true) { res2 in
                                    if res2 {
                                        let dataMessagesPin = self.pinnedMessagesForBanner()
                                        DispatchQueue.main.async {
                                            self.pinAllMessages(dataMessages: dataMessagesPin)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        self.proceedPinUnpinMessage(checkDataPinned: dataMessages[indexPath!.row], isPinned: true) { res in
                            if res {
                                let dataMessagesPin = self.pinnedMessagesForBanner()
                                DispatchQueue.main.async {
                                    self.pinAllMessages(dataMessages: dataMessagesPin)
                                }
                            }
                        }
                    }
                }
            })
        } else {
            pin = chatMenuAction(title: "Unpin".localized(), image: UIImage(systemName: "pin.slash"), handler: {(_) in
                if self.removed {
                    return
                }
                if self.isSearching {
                    self.cancelAction()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                    self.proceedPinUnpinMessage(checkDataPinned: dataMessages[indexPath!.row], isPinned: false) { res in
                        if res {
                            let dataMessagesPin = self.pinnedMessagesForBanner()
                            DispatchQueue.main.async {
                                self.pinAllMessages(dataMessages: dataMessagesPin)
                            }
                        }
                    }
                })
            })
        }
        let replyP = chatMenuAction(title: "Reply Privately".localized(), image: UIImage(systemName: "arrowshape.turn.up.left"), handler: {(_) in
            if self.removed {
                return
            }
            if self.isSearching {
                self.cancelAction()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                let f_pin = dataMessages[indexPath!.row]["f_pin"] as? String ?? ""
                let message_id = dataMessages[indexPath!.row][TypeDataMessage.message_id] as? String ?? ""
                if let dataSaved: String = SecureUserDefaults.shared.value(forKey: "new_saved_\(f_pin)") {
                    let data = dataSaved
                    if let jsonData = data.data(using: .utf8),
                       let dataJson = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] {
                        let last_m = dataJson["text"] ?? ""
                        let data: [String: String] = ["text": last_m, "reffId": message_id]
                        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
                           let jsonString = String(data: jsonData, encoding: .utf8) {
                            SecureUserDefaults.shared.set(jsonString, forKey: "new_saved_\(f_pin)")
                        }
                    }
                } else {
                    let data: [String: String] = ["text": "", "reffId": message_id]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        SecureUserDefaults.shared.set(jsonString, forKey: "new_saved_\(f_pin)")
                    }
                }
                let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                editorPersonalVC.hidesBottomBarWhenPushed = true
                editorPersonalVC.unique_l_pin = f_pin
                if let nav = self.navigationController {
                    nav.show(editorPersonalVC, sender: nil)
                    nav.viewControllers.remove(at: nav.viewControllers.count - 2)
                }
            })
        })
        let forward = chatMenuAction(title: "Forward".localized(), image: UIImage(systemName: "arrowshape.turn.up.right"), handler: {(_) in
            if self.removed {
                return
            }
            if self.isSearching {
                self.cancelAction()
            }
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.forwardSession = true
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if !self.isHistoryCC {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        let copy = chatMenuAction(title: "Copy".localized(), image: UIImage(systemName: "doc.on.doc"), handler: {(_) in
            if self.removed {
                return
            }
            if self.isSearching {
                self.cancelAction()
            }
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.copySession = true
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if !self.isHistoryCC {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        let edit = chatMenuAction(title: "Edit".localized(), image: UIImage(systemName: "pencil.tip.crop.circle"), handler: {(_) in
            self.isEditingMessage = true
            self.showEditMessageView(at: indexPath!)
        })
        let translate = chatMenuAction(title: "Translate".localized(), image: UIImage(systemName: "t.bubble"), handler: {(_) in
            self.view.makeToast("Translating...".localized(), duration: 3)
            var translation: String = "English"
            let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
            if lang == "id" {
                translation = "Indonesia"
            }
            let payload: [String : Any] = [
                "role": "user",
                "content": dataMessages[indexPath!.row][TypeDataMessage.message_text]!!
            ]
            let parameter: [String : Any] = [
                "use_video": "0",
                "translate": translation,
                "payload": [payload]
            ]
            DispatchQueue.global().async {
                Utils.postDataWithCookiesAndUserAgent(from: URL(string: Utils.getGPTBotUrl())!, parameter: parameter, completion: { data, response, error in
                    let response = response as? HTTPURLResponse
                    if response?.statusCode != 200 || error != nil {
                        DispatchQueue.main.async {
                            self.view.makeToast("There is an error occurred while translating your message. Please try again or check your network connection.".localized(), duration: 3)
                        }
                        return
                    }
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        if let json = try? JSONSerialization.jsonObject(with: responseString.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [String: String] {
                            let dataContent = json["content"]!
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                            if idx != nil{
                                self.dataMessages[idx!][TypeDataMessage.message_text] = (dataMessages[indexPath!.row][TypeDataMessage.message_text] as? String ?? "") + "\n\n" + "$\(dataContent)$"
                            }
                            DispatchQueue.main.async{
                                self.tableChatView.reloadRows(at: [indexPath!], with: .none)
                            }
                        }
                    }
                })
            }
        })
        let gcs = chatMenuAction(title: "Get Chat Suggestion".localized(), image: UIImage(systemName: "exclamationmark.bubble"), handler: {(_) in
            self.view.makeToast("Getting chat suggestion...".localized(), duration: 3)
            let payload: [String : Any] = [
                "role": "user",
                "content": dataMessages[indexPath!.row][TypeDataMessage.message_text]!!
            ]
            let parameter: [String : Any] = [
                "use_video": "0",
                "suggest": "1",
                "payload": [payload]
            ]
            DispatchQueue.global().async {
                Utils.postDataWithCookiesAndUserAgent(from: URL(string: Utils.getGPTBotUrl())!, parameter: parameter, completion: { data, response, error in
                    let response = response as? HTTPURLResponse
                    if response?.statusCode != 200 || error != nil {
                        DispatchQueue.main.async {
                            self.view.makeToast("There is an error occurred while getting chat suggestion for you. Please try again or check your network connection.".localized(), duration: 3)
                        }
                        return
                    }
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        if let json = try? JSONSerialization.jsonObject(with: responseString.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                            if let dataMessage = json["message"] as? [[String: Any]] {
                                if let dataContent = dataMessage[0]["content"] as? String {
                                    DispatchQueue.main.async{
                                        self.textFieldSend.text = dataContent
                                        self.textFieldSend.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black
                                    }
                                }
                            }
                            
                        }
                    }
                })
            }
        })
        let summarize = chatMenuAction(title: "Summarize Chat".localized(), image: UIImage(systemName: "doc.text.magnifyingglass"), handler: {(_) in
            if self.removed {
                return
            }
            if self.isSearching {
                self.cancelAction()
            }
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.summarizeSession = true
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if !self.isHistoryCC {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        let more = UIMenu(title: "More...".localized(), children: [translate, gcs, summarize])
        let info = chatMenuAction(title: "Info".localized(), image: UIImage(systemName: "info.circle"), handler: {(_) in
            if self.removed {
                return
            }
            let messageInfoVC = MessageInfo()
            messageInfoVC.data = dataMessages[indexPath!.row]
            messageInfoVC.dataGroup = self.dataGroup
            messageInfoVC.isPersonal = false
            self.navigationController?.pushViewController(messageInfoVC, animated: true)
        })
        let delete = chatMenuAction(title: "Delete".localized(), image: UIImage(systemName: "trash"), attributes: .destructive, handler: {(_) in
            if self.removed {
                return
            }
            if self.isSearching {
                self.cancelAction()
            }
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.deleteSession = true
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if !self.isHistoryCC {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.addMultipleSelectSession()
                self.tableChatView.reloadData()
            }
        })
        
        let resend = chatMenuAction(title: "Resend".localized(), image: UIImage(systemName: "arrow.clockwise"), handler: {(_) in
            let messageId = dataMessages[indexPath!.row][TypeDataMessage.message_id]  as? String ?? ""
            let status = dataMessages[indexPath!.row][TypeDataMessage.status]  as? String ?? ""
            
            var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String ?? "" == messageId })
            if let idxMessageIdParent = self.groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == messageId }) }) {
                if let idxInImages = self.groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == messageId }) {
                    self.groupImages[idxMessageIdParent].value[idxInImages].status = "1"
                    self.groupImages[idxMessageIdParent].value[idxInImages].dataMessage[TypeDataMessage.status] = "1"
                }
                idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.groupImages[idxMessageIdParent].key })
            }
            
            if (idx != nil) {
                do {
                    self.dataMessages[idx!][TypeDataMessage.status] = "1"
                    self.dataMessages[idx!][TypeDataMessage.progress] = 0.0
                    let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                    let row = self.messages(onDate: self.dataMessages[idx!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                    if row != nil && section != nil  {
                        self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                    }
                } catch {
                }
            }
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                        "status" : "1"
                    ], _where: "message_id = '\(messageId)'")
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS", cvalues: [
                        "status" : "1"
                    ], _where: "message_id = '\(messageId)'")
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            let message = CoreMessage_TMessageBank.sendMessage(message_id: messageId,
                                                               l_pin: dataMessages[indexPath!.row][TypeDataMessage.l_pin]  as? String ?? "",
                                                               message_scope_id: dataMessages[indexPath!.row][TypeDataMessage.message_scope_id]  as? String ?? "",
                                                               status: "1",
                                                               message_text: dataMessages[indexPath!.row][TypeDataMessage.message_text]  as? String ?? "",
                                                               credential: dataMessages[indexPath!.row][TypeDataMessage.credential]  as? String ?? "",
                                                               attachment_flag: dataMessages[indexPath!.row][TypeDataMessage.attachment_flag]  as? String ?? "",
                                                               ex_blog_id: dataMessages[indexPath!.row][TypeDataMessage.blog_id]  as? String ?? "",
                                                               message_large_text: "",
                                                               ex_format: "",
                                                               image_id: dataMessages[indexPath!.row][TypeDataMessage.image_id]  as? String ?? "",
                                                               audio_id: dataMessages[indexPath!.row][TypeDataMessage.audio_id]  as? String ?? "",
                                                               video_id: dataMessages[indexPath!.row][TypeDataMessage.video_id]  as? String ?? "",
                                                               file_id: dataMessages[indexPath!.row][TypeDataMessage.file_id]  as? String ?? "",
                                                               thumb_id: dataMessages[indexPath!.row][TypeDataMessage.thumb_id]  as? String ?? "",
                                                               reff_id: dataMessages[indexPath!.row][TypeDataMessage.reff_id]  as? String ?? "",
                                                               read_receipts: dataMessages[indexPath!.row][TypeDataMessage.read_receipts]  as? String ?? "",
                                                               chat_id: dataMessages[indexPath!.row][TypeDataMessage.chat_id]  as? String ?? "",
                                                               is_call_center: dataMessages[indexPath!.row][TypeDataMessage.is_call_center]  as? String ?? "",
                                                               call_center_id: dataMessages[indexPath!.row][TypeDataMessage.call_center_id]  as? String ?? "",
                                                               opposite_pin: dataMessages[indexPath!.row][TypeDataMessage.opposite_pin]  as? String ?? "", specFile: "")
            Nexilis.addQueueMessage(message: message)
        })
        
        var children: [UIMenuElement] = [star, reply, pin, copy, delete]
        var isMore = false
//        let copyOption = self.copyOption(indexPath: indexPath!)
        let idMe = User.getMyPin() as String?
        
        if !(dataMessages[indexPath!.row]["audio_id"]  as? String ?? "").isEmpty {
            children.remove(at: 3)
        }
        if dataMessages[indexPath!.row]["status"]  as? String ?? "" == "0" {
            children = [resend, delete]
        } else if (dataMessages[indexPath!.row]["lock"] != nil && dataMessages[indexPath!.row]["lock"]  as? String ?? "" == "1") || dataMessages[indexPath!.row]["message_scope_id"]  as? String ?? "" == "18" || dataMessages[indexPath!.row]["credential"]  as? String ?? "" == "1" {
            children = [delete]
        } else if (groupImages[dataMessages[indexPath!.row]["message_id"]  as? String ?? ""] != nil) {
            forward.title = "Forward All".localized()
            delete.title = "Delete All".localized()
            children = [delete]
            if (Nexilis.checkingAccess(key: "secure_folder_forward") || (dataMessages[indexPath!.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward")) && dataMessages[indexPath!.row]["read_receipts"] as? String != "8" {
                children.insert(forward, at: 0)
            }
        } else {
            if dataMessages[indexPath!.row]["f_pin"] as? String ?? "" == "-999" {
                children = [star, reply ,delete]
            }
            else if (!(dataMessages[indexPath!.row]["image_id"]  as? String ?? "").isEmpty || !(dataMessages[indexPath!.row]["video_id"]  as? String ?? "").isEmpty || !(dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty) {
                var isEmpty = true
                let messageText = dataMessages[indexPath!.row][TypeDataMessage.message_text]  as? String ?? ""
                if !(dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty && !messageText.component(1, separatedBy: "|").isEmpty {
                    isEmpty = false
                } else if (dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty && !messageText.isEmpty {
                    isEmpty = false
                }
                if isEmpty {
                    children = [star, reply , pin, delete]
                }
            } else if dataMessages[indexPath!.row]["attachment_flag"]  as? String ?? "" == "11" {
                children = [reply, pin, delete]
            }
            if (Nexilis.checkingAccess(key: "secure_folder_forward") || (!(dataMessages[indexPath!.row][TypeDataMessage.message_text]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["image_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["video_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["audio_id"]  as? String ?? "").isEmpty) || (dataMessages[indexPath!.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward")) && dataMessages[indexPath!.row]["read_receipts"] as? String != "8" && dataMessages[indexPath!.row]["attachment_flag"] as? String ?? "" != "11" {
                children.insert(forward, at: 2)
            }
            if dataMessages[indexPath!.row]["f_pin"] as? String ?? "" != "-999" && dataMessages[indexPath!.row]["f_pin"] as? String != User.getMyPin() && dataMessages[indexPath!.row]["attachment_flag"]  as? String ?? "" != "11" && dataMessages[indexPath!.row]["f_pin"] as? String ?? "" != "-997" {
                children.insert(replyP, at: 2)
            }
            if (dataMessages[indexPath!.row]["f_pin"]  as? String ?? "") == idMe {
                children.insert(info, at: children.count - 1)
            }
            if !(dataMessages[indexPath!.row][TypeDataMessage.message_text]  as? String ?? "").isEmpty {
                if (dataMessages[indexPath!.row]["f_pin"]  as? String ?? "") == idMe && ((dataMessages[indexPath!.row][TypeDataMessage.is_forwarded] as? Int) ?? 0) == 0 && (dataMessages[indexPath!.row][TypeDataMessage.attachment_flag] as? String ?? "") != "11" {
                    var textFile = dataMessages[indexPath!.row][TypeDataMessage.message_text] as? String ?? ""
                    if !(dataMessages[indexPath!.row][TypeDataMessage.file_id] as? String ?? "").isEmpty {
                        textFile = textFile.component(1, separatedBy: "|")
                    }
                    if !textFile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let valueDate = Date(milliseconds: Int64(dataMessages[indexPath!.row][TypeDataMessage.server_date] as? String ?? "") ?? 0)
                        let nowDate = Date()
                        let diffInSeconds = nowDate.timeIntervalSince(valueDate)
                        if diffInSeconds <= 15 * 60 {
                            children.insert(edit, at: children.count - 1)
                        }
                    }
                }
                if (dataMessages[indexPath!.row][TypeDataMessage.attachment_flag] as? String ?? "") != "11" && (dataMessages[indexPath!.row]["image_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["video_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["audio_id"]  as? String ?? "").isEmpty{
                    isMore = true
                }
            }
        }
        
        let mainMenu = UIMenu(title: "", options: [.displayInline],
                              children: children)
        var menuForShow = UIMenu(title: "", children: [mainMenu])
        if isMore {
            menuForShow = UIMenu(title: "", children: [mainMenu, more])
        }
        // Fix: the menu is ours, not UIKit's - see presentBubbleContextMenu(for:elements:).
        if let bubble = interaction.view,
           presentBubbleContextMenu(for: bubble, elements: menuForShow.children) {
            return nil
        }
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            return menuForShow
        }
    }
    
    func proceedPinUnpinMessage(checkDataPinned: [String: Any?], isPinned: Bool, completion: @escaping (Bool)-> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var jaData = [[String: Any]]()
            var jsonObject = [String: Any]()
            jsonObject[CoreMessage_TMessageKey.MESSAGE_ID] = checkDataPinned["message_id"]  as? String ?? ""
            jsonObject[CoreMessage_TMessageKey.IS_PINNED_MESSAGE] = isPinned ? "\(Date().currentTimeMillis())" : "0"
            jaData.append(jsonObject)
            if let jsonData = try? JSONSerialization.data(withJSONObject: jaData, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getPinMessage(f_pin: User.getMyPin() ?? "", data: jsonString, oppositePin: self.dataGroup["group_id"]  as? String ?? "", chatId: self.dataTopic["chat_id"] as? String ?? "", scopeId: MessageScope.GROUP)) {
                    if response.isOk() {
                        if isPinned {
                            let mId = Nexilis.saveMessageNotif(textMessage: "You".localized() + " " + "pinned a message".localized(), fPin: User.getMyPin() ?? "", lPin: self.unique_l_pin, chatId: self.dataTopic["chat_id"] as? String ?? "", scopeId: MessageScope.GROUP)
                            self.appendNewMessage(messageId: mId)
                        }
                        DispatchQueue.global().async {
                            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                do {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                        "is_pinned" : isPinned ? "\(Date().currentTimeMillis())" : "0"
                                    ], _where: "message_id = '\(checkDataPinned["message_id"]  as? String ?? "")'")
                                } catch {
                                    rollback.pointee = true
                                    print("Access database error: \(error.localizedDescription)")
                                }
                            })
                        }
                        let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == checkDataPinned["message_id"]  as? String ?? ""})
                        if idx != nil{
                            self.dataMessages[idx!][TypeDataMessage.is_pinned] = isPinned ? "\(Date().currentTimeMillis())" : "0"
                            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                            let row = self.messages(onDate: self.dataMessages[idx!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[idx!]["message_id"]  as? String ?? "" })
                            if row != nil && section != nil  {
                                DispatchQueue.main.async {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                        }
                        completion(true)
                    } else {
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Failed to pin or unpin message, make sure you are connected to internet".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                        completion(false)
                    }
                } else {
                    DispatchQueue.main.async {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                    completion(false)
                }
            }
        }
    }
    
    private func appendNewMessage(messageId: String) {
        // The window is not at the end of the conversation, so there is nothing to append to.
        guard isWindowAtNewest else {
            return
        }
        var row: [String: Any?] = [:]
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, is_call_center, call_center_id, opposite_pin, last_edited, gif_id, is_forwarded_message, attachment_speciality, is_pinned from MESSAGE where message_id = '\(messageId)'"), cursorData.next() {
                row["message_id"] = cursorData.string(forColumnIndex: 0)
                row["f_pin"] = cursorData.string(forColumnIndex: 1)
                row["l_pin"] = cursorData.string(forColumnIndex: 2)
                row["message_scope_id"] = cursorData.string(forColumnIndex: 3)
                row["server_date"] = cursorData.string(forColumnIndex: 4)
                row["status"] = cursorData.string(forColumnIndex: 5)
                row["message_text"] = cursorData.string(forColumnIndex: 6)
                row["audio_id"] = cursorData.string(forColumnIndex: 7)
                row["video_id"] = cursorData.string(forColumnIndex: 8)
                row["image_id"] = cursorData.string(forColumnIndex: 9)
                row["thumb_id"] = cursorData.string(forColumnIndex: 10)
                row["read_receipts"] = cursorData.string(forColumnIndex: 11)
                row["chat_id"] = cursorData.string(forColumnIndex: 12)
                row["file_id"] = cursorData.string(forColumnIndex: 13)
                row["attachment_flag"] = cursorData.string(forColumnIndex: 14)
                row["reff_id"] = cursorData.string(forColumnIndex: 15)
                row["lock"] = cursorData.string(forColumnIndex: 16)
                row["is_stared"] = cursorData.string(forColumnIndex: 17)
                row["blog_id"] = cursorData.string(forColumnIndex: 18)
                row["credential"] = cursorData.string(forColumnIndex: 19)
                row[TypeDataMessage.is_call_center] = cursorData.string(forColumnIndex: 20)
                row[TypeDataMessage.call_center_id] = cursorData.string(forColumnIndex: 21)
                row[TypeDataMessage.opposite_pin] = cursorData.string(forColumnIndex: 22)
                row[TypeDataMessage.last_edit] = cursorData.longLongInt(forColumnIndex: 23)
                row[TypeDataMessage.gif_id] = cursorData.string(forColumnIndex: 24)
                row[TypeDataMessage.is_forwarded] = Int(cursorData.int(forColumnIndex: 25))
                row[TypeDataMessage.spec_file] = cursorData.string(forColumnIndex: 26)
                row[TypeDataMessage.is_pinned] = cursorData.string(forColumnIndex: 27)
                row["progress"] = 0.0
                row["isSelected"] = false
                row["chat_date"] = "Today".localized()
                cursorData.close()
            }
        })
        DispatchQueue.main.async {
            if !self.dataDates.contains("Today".localized()) {
                self.dataDates.append("Today".localized())
                self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .none)
            }
            // The window now covers one more of the conversation's messages, which is what
            // keeps the offsets used for paging lined up with the database.
            self.loadedCount += 1
            if let collageRow = self.foldIntoImageGroup(row) {
                // Part of the run above it: no new row goes in, the row that draws the
                // collage is redrawn to take it.
                self.tableChatView.reloadRows(at: [collageRow], with: .none)
            } else {
                self.dataMessages.append(row)
                self.tableChatView.insertRows(at: [IndexPath(row: self.messages(onDate: self.dataDates[self.dataDates.count - 1]).count - 1, section: self.dataDates.count - 1)], with: .none)
            }
            self.tableChatView.layoutIfNeeded()
        }
    }
    
    func showEditMessageView(at indexPath: IndexPath) {
        tempListMentionWithText = listMentionWithText
        tempListMentionInTextField = listMentionInTextField
        listMentionWithText.removeAll()
        listMentionInTextField.removeAll()
        let dataMessages = self.messages(onDate: dataDates[indexPath.section])
        var oldText = dataMessages[indexPath.row][TypeDataMessage.message_text]  as? String ?? ""
        if !(dataMessages[indexPath.row][TypeDataMessage.file_id] as? String ?? "").isEmpty {
            oldText = oldText.component(1, separatedBy: "|")
        }
        var oldTextForTextview = oldText
        let pattern = "@[\\w]+"
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsrange = NSRange(oldText.startIndex..., in: oldText)
            let matches = regex.matches(in: oldText, range: nsrange)
            
            let results = matches.map {
                String(oldText[Range($0.range, in: oldText)!])
            }
            for result in results {
                let pinRes = result.component(1, separatedBy: "@")
                Database.shared.database?.inTransaction({ fmdb, rollback in
                    do {
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name || ' ' || ifnull(last_name, '') name FROM GROUPZ_MEMBER where f_pin = '\(pinRes)'"), cursor.next() {
                            let user = User(pin: "")
                            user.pin = cursor.string(forColumnIndex: 0) ?? ""
                            user.firstName = cursor.string(forColumnIndex: 1) ?? ""
                            if !user.pin.isEmpty {
                                var fixUser = User.getDataCanNil(pin: user.pin, fmdb: fmdb)
                                if fixUser == nil {
                                    fixUser = user
                                }
                                var indexAt = 0
                                if let range = oldTextForTextview.range(of: result) {
                                    indexAt = oldTextForTextview.distance(from: oldTextForTextview.startIndex, to: range.lowerBound)
                                }
                                fixUser?.ex_block = "\(indexAt + fixUser!.fullName.count)"
                                listMentionWithText.append(fixUser!)
                                listMentionInTextField.append(fixUser!)
                                oldTextForTextview = oldTextForTextview.replacingOccurrences(of: result, with: "@\(fixUser!.fullName)")
                                lastTextLength = oldTextForTextview.count
                            }
                            cursor.close()
                        } else if pinRes == "-997" {
                            let gptUser = User(pin: "-997",
                                            firstName: Utils.getGPTBotName(),
                                            lastName: "",
                                            thumb: "",
                                            userType: "0",
                                            official: "1")
                            var indexAt = 0
                            if let range = oldTextForTextview.range(of: result) {
                                indexAt = oldTextForTextview.distance(from: oldTextForTextview.startIndex, to: range.lowerBound)
                            }
                            gptUser.ex_block = "\(indexAt + gptUser.fullName.count)"
                            listMentionWithText.append(gptUser)
                            listMentionInTextField.append(gptUser)
                            oldTextForTextview = oldTextForTextview.replacingOccurrences(of: result, with: "@\(gptUser.fullName)")
                            lastTextLength = oldTextForTextview.count
                        }
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
            }
        } catch {
            print("Invalid regex pattern")
        }
        editVC = UIViewController()
        if let view = editVC.view {
//            let tapGesture = ObjectGesture(target: self, action: #selector(dismissEditVC))
//            tapGesture.message_id = oldTextForTextview
//            view.addGestureRecognizer(tapGesture)
            
            view.backgroundColor = .clear
            let blurView = UIView()
            let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = blurView.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            blurView.addSubview(blurEffectView)
            blurView.sendSubviewToBack(blurEffectView)
            view.addSubview(blurView)
            blurView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
            
            let tapGesture = ObjectGesture(target: self, action: #selector(dismissEditVC))
            tapGesture.message_id = oldTextForTextview
            blurView.addGestureRecognizer(tapGesture)
            
            editTextView = CustomTextView()
            editTextView.layer.cornerRadius = textFieldSend.maxCornerRadius()
            editTextView.layer.borderWidth = 1.0
            editTextView.textColor = UIColor.black
            editTextView.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
            editTextView.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 11, right: 40)
            editTextView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
            editTextView.font = UIFont.systemFont(ofSize: 12 + offset())
            editTextView.delegate = self
            editTextView.allowsEditingTextAttributes = true
            editTextView.backgroundColor = .clear
            view.addSubview(editTextView)
            editTextView.anchor(left: view.leftAnchor, right: view.rightAnchor, paddingLeft: 15, paddingRight: 15)
            constraintBottomeditTextView = editTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15)
            constraintHeighteditTextView = editTextView.heightAnchor.constraint(equalToConstant: 40)
            constraintBottomeditTextView.isActive = true
            constraintHeighteditTextView.isActive = true
            editTextView.attributedText = oldTextForTextview.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
            editTextView.becomeFirstResponder()
            
            buttonSendEdit.setImage(resizeImage(image: self.traitCollection.userInterfaceStyle == .dark ? UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.blackDarkMode) : UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal), for: .normal)
            buttonSendEdit.circle()
            buttonSendEdit.isEnabled = true
            buttonSendEdit.actionHandle(controlEvents: .touchUpInside,
             ForAction:{() -> Void in
                var newText = self.editTextView.text ?? ""
                if !(dataMessages[indexPath.row][TypeDataMessage.file_id] as? String ?? "").isEmpty {
                    let firstText = dataMessages[indexPath.row][TypeDataMessage.message_text] as? String ?? ""
                    newText = firstText.components(separatedBy: "|")[0] + "|" + newText
                }
                if newText.contains("@") && self.listMentionInTextField.count > 0 {
                    var diff: Int = 0
                    for i in 0..<self.listMentionInTextField.count {
                        let mention = self.listMentionInTextField[i]
                        guard let exBlockStr = mention.ex_block, let exBlock = Int(exBlockStr) else {
                            continue // skip if ex_block is nil or not an integer
                        }
                        let nameWithMention = ("@" + mention.firstName + " " + mention.lastName).trimmingCharacters(in: .whitespaces)
                        let pinString = "@\(mention.pin)"
                        let upperBound = exBlock + diff
                        let lowerBound = upperBound - nameWithMention.count + 1
                        guard lowerBound >= 0, upperBound < newText.count else {
                            continue // prevent index out-of-range
                        }
                        var afterMention = ""
                        let nextCharIndex = newText.index(newText.startIndex, offsetBy: upperBound + 1, limitedBy: newText.endIndex)
                        if let index = nextCharIndex, index < newText.endIndex {
                            let nextChar = newText[index]
                            if nextChar != "\n" && nextChar != " " {
                                afterMention = " "
                            }
                        }
                        let startIndex = newText.index(newText.startIndex, offsetBy: lowerBound)
                        let endIndex = newText.index(newText.startIndex, offsetBy: upperBound + 1)
                        let range = startIndex..<endIndex
                        if newText[range] == nameWithMention {
                            newText.replaceSubrange(range, with: pinString + afterMention)
                            diff += (pinString + afterMention).count - nameWithMention.count
                        }
                    }
                }
                if !newText.isEmpty && newText.trimmingCharacters(in: .whitespacesAndNewlines) != oldText {
                    if !(dataMessages[indexPath.row][TypeDataMessage.file_id] as? String ?? "").isEmpty {
                        let firstText = dataMessages[indexPath.row][TypeDataMessage.message_text] as? String ?? ""
                        if newText != firstText {
                            excEdit()
                        }
                    } else {
                        excEdit()
                    }
                    func excEdit() {
                        let lastEdited = Int64(Date().currentTimeMillis())
                        let message = CoreMessage_TMessageBank.editMessage(message_id: dataMessages[indexPath.row][TypeDataMessage.message_id]  as? String ?? "", l_pin: dataMessages[indexPath.row][TypeDataMessage.l_pin]  as? String ?? "", message_scope_id: dataMessages[indexPath.row][TypeDataMessage.message_scope_id]  as? String ?? "", status: dataMessages[indexPath.row][TypeDataMessage.status]  as? String ?? "", message_text: newText, credential: dataMessages[indexPath.row][TypeDataMessage.credential]  as? String ?? "", attachment_flag: dataMessages[indexPath.row][TypeDataMessage.attachment_flag]  as? String ?? "", ex_blog_id: dataMessages[indexPath.row][TypeDataMessage.blog_id]  as? String ?? "", message_large_text: "", ex_format: "", image_id: dataMessages[indexPath.row][TypeDataMessage.image_id]  as? String ?? "", audio_id: dataMessages[indexPath.row][TypeDataMessage.audio_id]  as? String ?? "", video_id: dataMessages[indexPath.row][TypeDataMessage.video_id]  as? String ?? "", file_id: dataMessages[indexPath.row][TypeDataMessage.file_id]  as? String ?? "", thumb_id: dataMessages[indexPath.row][TypeDataMessage.thumb_id]  as? String ?? "", reff_id: dataMessages[indexPath.row][TypeDataMessage.reff_id]  as? String ?? "", read_receipts: dataMessages[indexPath.row][TypeDataMessage.read_receipts]  as? String ?? "", chat_id: dataMessages[indexPath.row][TypeDataMessage.chat_id]  as? String ?? "", is_call_center: dataMessages[indexPath.row][TypeDataMessage.is_call_center]  as? String ?? "", call_center_id: dataMessages[indexPath.row][TypeDataMessage.call_center_id]  as? String ?? "", opposite_pin: dataMessages[indexPath.row][TypeDataMessage.opposite_pin]  as? String ?? "", server_date: dataMessages[indexPath.row][TypeDataMessage.server_date]  as? String ?? "", local_time_stamp: dataMessages[indexPath.row][TypeDataMessage.server_date]  as? String ?? "", last_edit: lastEdited)
                        Nexilis.addQueueMessage(message: message, isEditMessage: true)
                        DispatchQueue.global().async {
                            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                do {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                        "message_text" : newText,
                                        "last_edited" : lastEdited
                                    ], _where: "message_id = '\(dataMessages[indexPath.row]["message_id"]  as? String ?? "")'")
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                                } catch {
                                    rollback.pointee = true
                                    print("Access database error: \(error.localizedDescription)")
                                }
                            })
                        }
                        let idx = self.dataMessages.firstIndex(where: { $0[TypeDataMessage.message_id] as? String == dataMessages[indexPath.row][TypeDataMessage.message_id] as? String})
                        if idx != nil{
                            self.dataMessages[idx!][TypeDataMessage.message_text] = newText
                            self.dataMessages[idx!][TypeDataMessage.last_edit] = lastEdited
                            self.tableChatView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
                }
                self.isEditingMessage = false
                self.listMentionWithText = self.tempListMentionWithText
                self.listMentionInTextField = self.tempListMentionWithText
                self.lastTextLength = self.textFieldSend.text?.count ?? 0
                self.heightTableEditMention = nil
                self.editVC.dismiss(animated: true)
             })
            buttonSendEdit.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
            view.addSubview(buttonSendEdit)
            buttonSendEdit.anchor(right: view.rightAnchor, paddingRight: 15, width: 40, height: 40)
            constraintBottomSendEditTV = buttonSendEdit.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15)
            constraintBottomSendEditTV.isActive = true
            
            let viewMessage = UIView()
            view.addSubview(viewMessage)
            viewMessage.translatesAutoresizingMaskIntoConstraints = false
            if (dataMessages[indexPath.row][TypeDataMessage.f_pin] as? String == User.getMyPin()) {
                viewMessage.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor, constant: 60).isActive = true
                viewMessage.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -15).isActive = true
                viewMessage.backgroundColor = .blueBubbleColor
                viewMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            } else {
                viewMessage.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: 60).isActive = true
                viewMessage.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 15).isActive = true
                viewMessage.backgroundColor = .whiteBubbleColor
                viewMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            }
            viewMessage.bottomAnchor.constraint(equalTo: editTextView.topAnchor, constant: -15).isActive = true
            viewMessage.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            viewMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            viewMessage.layer.cornerRadius = 10.0
            viewMessage.clipsToBounds = true
            
            let messageText = UILabel()
            messageText.numberOfLines = 0
            messageText.lineBreakMode = .byWordWrapping
            viewMessage.addSubview(messageText)
            messageText.translatesAutoresizingMaskIntoConstraints = false
            messageText.topAnchor.constraint(equalTo: viewMessage.topAnchor, constant: 15).isActive = true
            messageText.leadingAnchor.constraint(equalTo: viewMessage.leadingAnchor, constant: 15).isActive = true
            messageText.bottomAnchor.constraint(equalTo: viewMessage.bottomAnchor, constant: -15).isActive = true
            messageText.trailingAnchor.constraint(equalTo: viewMessage.trailingAnchor, constant: -15).isActive = true
            messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
            messageText.font = .systemFont(ofSize: 12 + offset())
            messageText.attributedText = oldText.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
            
            tableMentionEdit = UITableView()
            tableMentionEdit.register(UITableViewCell.self, forCellReuseIdentifier: "cellEditMention")
            tableMentionEdit.dataSource = self
            tableMentionEdit.delegate = self
            tableMentionEdit.contentInset = UIEdgeInsets(top: -25, left: 0, bottom: 0, right: 0)
            tableMentionEdit.backgroundColor = .white
            view.addSubview(tableMentionEdit)
            tableMentionEdit.anchor(left: view.leftAnchor, bottom: editTextView.topAnchor, right: view.rightAnchor)
            heightTableEditMention = tableMentionEdit.heightAnchor.constraint(equalToConstant: 0)
            self.heightTableEditMention.isActive = true
        }
        editVC.modalTransitionStyle = .crossDissolve
        editVC.modalPresentationStyle = .overFullScreen
        self.present(editVC, animated: true, completion: {
            self.constraintHeighteditTextView.constant = self.editTextView.contentSize.height
            if self.constraintHeighteditTextView.constant > 95 {
                self.constraintHeighteditTextView.constant = 95.0
            }
        })
    }
    
    @objc func dismissEditVC(_ sender: ObjectGesture) {
        if editTextView.text == sender.message_id {
            isEditingMessage = false
            listMentionWithText = tempListMentionWithText
            listMentionInTextField = tempListMentionWithText
            lastTextLength = textFieldSend.text?.count ?? 0
            heightTableEditMention = nil
            editVC.dismiss(animated: true)
        } else if self.isEditingMessage {
            let alert = LibAlertController(title: "".localized(), message: "Discard edit?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Discard".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                self.isEditingMessage = false
                self.listMentionWithText = self.tempListMentionWithText
                self.listMentionInTextField = self.tempListMentionWithText
                self.lastTextLength = self.textFieldSend.text?.count ?? 0
                self.heightTableEditMention = nil
                self.editVC.dismiss(animated: true)
            }))
            editVC.present(alert, animated: true, completion: nil)
        } else {
            lastTextLength = self.textFieldSend.text?.count ?? 0
            editVC.dismiss(animated: true)
        }
    }
    
    @objc func cancelAction() {
        DispatchQueue.main.async {
            if self.copySession {
                self.copySession = false
            } else if self.forwardSession {
                self.forwardSession = false
            } else if self.deleteSession {
                self.deleteSession = false
            } else if self.summarizeSession {
                self.summarizeSession = false
            } else if self.isSearching {
                self.countMatchesSearch = 0
                self.searchMatchIds = []
                self.lastScrollIdxSearch = 0
                self.isSearching = false
            }
            if self.viewTextfield.isHidden {
                self.viewTextfield.isHidden = false
            }
            if self.viewAttachment.isHidden {
                self.viewAttachment.isHidden = false
            }
            if self.containerAction.isHidden {
                self.containerAction.isHidden = false
            }
            if self.viewButton.isHidden {
                self.viewButton.isHidden = false
            }
            if self.constraintBottomTableViewWithTextfield.constant == -60.0 {
                self.constraintBottomTableViewWithTextfield.constant = self.constraintBottomTableViewWithTextfield.constant + 70
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    if (self.currentIndexpath != nil) {
                        self.tableChatView.safeScrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: true)
                    } else {
                        self.tableChatView.scrollToBottom()
                    }
                })
            }
            let data = self.dataMessages.filter({ $0["isSelected"] as? Bool ?? false == true })
            for i in 0..<data.count {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == data[i]["message_id"]  as? String ?? ""})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = false
                }
            }
            self.tableChatView.reloadData()
            self.setRightButtonItem()
            self.changeAppBar()
            self.containerMultpileSelectSession.removeFromSuperview()
            self.refreshScrollToBottomButtonPlacement()
            self.checkNewMessage(tableView: self.tableChatView)
        }
    }
    
    private func addMultipleSelectSession() {
        viewTextfield.isHidden = true
        viewAttachment.isHidden = true
        containerAction.isHidden = true
        viewButton.isHidden = true
        constraintBottomTableViewWithTextfield.constant = constraintBottomTableViewWithTextfield.constant - 70
        view.addSubview(containerMultpileSelectSession)
        containerMultpileSelectSession.translatesAutoresizingMaskIntoConstraints = false
        constraintBottomContainerMultpileSelectSession = containerMultpileSelectSession.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
        NSLayoutConstraint.activate([
            containerMultpileSelectSession.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerMultpileSelectSession.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            constraintBottomContainerMultpileSelectSession,
            containerMultpileSelectSession.heightAnchor.constraint(equalToConstant: 50)
        ])
        containerMultpileSelectSession.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        addSubviewMultipleSession()
        refreshScrollToBottomButtonPlacement()
    }
    
    private func addSubviewMultipleSession() {
        let container = UIView()
        containerMultpileSelectSession.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: containerMultpileSelectSession.leadingAnchor),
            container.trailingAnchor.constraint(equalTo:containerMultpileSelectSession.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: containerMultpileSelectSession.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 50)
        ])
        container.layer.shadowOpacity = 0.7
        container.layer.shadowOffset = CGSize(width: 3, height: 3)
        container.layer.shadowRadius = 3.0
        container.layer.shadowColor = UIColor.black.cgColor
        container.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .secondaryColor
        
        if !isSearching {
            let title = UILabel()
            container.addSubview(title)
            title.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                title.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                title.centerYAnchor.constraint(equalTo:container.centerYAnchor),
            ])
            let countSelected = dataMessages.filter({ $0["isSelected"] as? Bool ?? false == true }).count
            title.text = "\(countSelected) " + "Selected".localized()
            title.textColor = .mainColor
            title.font = UIFont.systemFont(ofSize: 15).bold
            
            let button = UIImageView()
            container.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
                button.centerYAnchor.constraint(equalTo:container.centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: 30),
                button.heightAnchor.constraint(equalToConstant: 30),
            ])
            if copySession {
                button.image = UIImage(systemName: "doc.on.doc")
                if countSelected == 0{
                    button.tintColor = .gray
                } else {
                    button.tintColor = .mainColor
                }
            } else if forwardSession {
                button.image = UIImage(systemName: "arrowshape.turn.up.right")
                if countSelected == 0{
                    button.tintColor = .gray
                } else {
                    button.tintColor = .mainColor
                }
            } else if deleteSession {
                button.image = UIImage(systemName: "trash")
                if countSelected == 0{
                    button.tintColor = .gray
                } else {
                    button.tintColor = .red
                }
            } else if summarizeSession {
                button.image = UIImage(systemName: "doc.text.magnifyingglass")
                if countSelected == 0 {
                    button.tintColor = .gray
                } else {
                    button.tintColor = .mainColor
                }
            }
            let buttonGesture = UITapGestureRecognizer(target: self, action: #selector(sessionAction))
            button.isUserInteractionEnabled = true
            button.addGestureRecognizer(buttonGesture)
            
            let selectedMessage = dataMessages.filter({ $0["isSelected"] as? Bool ?? false == true })
            if selectedMessage.count > 0 {
                for i in 0..<selectedMessage.count {
                    if let isGroupingImages = groupImages[selectedMessage[i]["message_id"]  as? String ?? ""] {
                        title.text = "\(countSelected + (isGroupingImages.count - 1)) " + "Selected".localized()
                    }
                }
            }
        } else {
            buttonUp = UIButton()
            container.addSubview(buttonUp)
            buttonUp.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                buttonUp.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
                buttonUp.centerYAnchor.constraint(equalTo:container.centerYAnchor),
                buttonUp.widthAnchor.constraint(equalToConstant: 30),
                buttonUp.heightAnchor.constraint(equalToConstant: 30),
            ])
            buttonUp.addTarget(self, action: #selector(upSearchText), for: .touchUpInside)
            
            buttonDown = UIButton()
            container.addSubview(buttonDown)
            buttonDown.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                buttonDown.leadingAnchor.constraint(equalTo: buttonUp.trailingAnchor, constant: 15),
                buttonDown.centerYAnchor.constraint(equalTo:container.centerYAnchor),
                buttonDown.widthAnchor.constraint(equalToConstant: 30),
                buttonDown.heightAnchor.constraint(equalToConstant: 30),
            ])
            buttonDown.addTarget(self, action: #selector(downSearchText), for: .touchUpInside)
            
            buttonUp.setImage(UIImage(systemName: "chevron.up"), for: .normal)
            buttonUp.tintColor = .gray
            
            buttonDown.setImage(UIImage(systemName: "chevron.down"), for: .normal)
            buttonDown.tintColor = .gray
            
            titleSearchMatches = UILabel()
            container.addSubview(titleSearchMatches)
            titleSearchMatches.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleSearchMatches.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                titleSearchMatches.centerYAnchor.constraint(equalTo:container.centerYAnchor),
            ])
            titleSearchMatches.textColor = .mainColor
            titleSearchMatches.font = UIFont.systemFont(ofSize: 15.0).bold
            titleSearchMatches.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                self.searchBar.becomeFirstResponder()
            })
        }
    }
    
    @objc func upSearchText() {
        scrollToFirstSearchMessage(indexScroll: lastScrollIdxSearch + 1)
    }
    
    @objc func downSearchText() {
        scrollToFirstSearchMessage(indexScroll: lastScrollIdxSearch - 1)
    }
    
    @objc func sessionAction() {
        if copySession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as? Bool ?? false == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            var nameTopic = "Lounge".localized()
            if !dataTopic.isEmpty {
                nameTopic = dataTopic["title"]  as? String ?? ""
            }
            var text = "*^\(dataGroup["f_name"]!!) (\(nameTopic))^*"
            for i in 0..<countSelected {
                let stringDate = (dataMessages[i]["server_date"]  as? String ?? "")
                let date = Date(milliseconds: Int64(stringDate)!)
                let formatterDate = DateFormatter()
                let formatterTime = DateFormatter()
                formatterDate.dateFormat = "dd/MM/yy"
                formatterDate.locale = NSLocale(localeIdentifier: "id") as Locale?
                formatterTime.dateFormat = "HH:mm"
                formatterTime.locale = NSLocale(localeIdentifier: "id") as Locale?
                let dataProfile = getDataProfile(f_pin: dataMessages[i]["f_pin"]  as? String ?? "", message_id: dataMessages[i]["message_id"]  as? String ?? "")
                let textCopied = (dataMessages[i]["message_text"]  as? String ?? "").richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "")
                text = text + "\n\n*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(textCopied.string)"
            }
            text = text + "\n\n\nchat " + "Powered by Nexilis".localized()
            DispatchQueue.main.async {
                UIPasteboard.general.string = text
                self.view.makeToast("Text coppied to clipboard".localized(), duration: 3)
            }
            cancelAction()
        } else if forwardSession {
            presentForwardChooser(for: self.dataMessages.filter({ $0["isSelected"] as? Bool ?? false == true }))
        } else if deleteSession {
            presentDeleteOptions(for: self.dataMessages.filter({ $0["isSelected"] as? Bool ?? false == true }))
        } else if summarizeSession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as? Bool ?? false == true })
            var countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            for i in 0..<countSelected {
                if let isGroupingImages = groupImages[dataMessages[i]["message_id"]  as? String ?? ""] {
                    countSelected += (isGroupingImages.count - 1)
                }
            }
            var contentText = ""
            for message in dataMessages {
                if !(message[TypeDataMessage.message_text] as? String ?? "").isEmpty {
                    let dataUser = User.getData(pin: message[TypeDataMessage.f_pin] as? String ?? "", lPin: self.unique_l_pin)
                    contentText.append(dataUser?.fullName ?? "")
                    contentText.append(": ")
                    contentText.append(message[TypeDataMessage.message_text] as? String ?? "")
                    contentText.append("\n\n")
                } else {
                    self.view.makeToast("Cannot get messages to summarize".localized(), duration: 3)
                    return
                }
            }
            self.view.makeToast("Summarizing chat...".localized(), duration: 3)
            let payload: [String : Any] = [
                "role": "user",
                "content": contentText
            ]
            let parameter: [String : Any] = [
                "use_video": "0",
                "summarize": "1",
                "payload": [payload]
            ]
            DispatchQueue.global().async {
                Utils.postDataWithCookiesAndUserAgent(from: URL(string: Utils.getGPTBotUrl())!, parameter: parameter, completion: { data, response, error in
                    let response = response as? HTTPURLResponse
                    if response?.statusCode != 200 || error != nil {
                        DispatchQueue.main.async {
                            self.view.makeToast("There is an error occurred while getting chat suggestion for you. Please try again or check your network connection.".localized(), duration: 3)
                        }
                        return
                    }
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        if let json = try? JSONSerialization.jsonObject(with: responseString.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                            if let content = json["content"] as? String {
                                DispatchQueue.main.async {
                                    let alertController = LibAlertController(title: nil, message: content, preferredStyle: .alert)
                                    alertController.addAction(UIAlertAction(title: "Copy".localized(), style: .default, handler: { _ in
                                        DispatchQueue.main.async {
                                            UIPasteboard.general.string = content
                                            self.view.makeToast("Text coppied to clipboard".localized(), duration: 3)
                                        }
                                    }))
                                    alertController.addAction(UIAlertAction(title: "Close".localized(), style: .cancel, handler: nil))
                                    self.present(alertController, animated: true)
                                }
                            }
                        }
                    }
                })
            }
            
        }
    }
    
    private func deleteMessage(l_pin: String, message_id: String, scope: String, type: String, chat: String) {
        let tmessage = CoreMessage_TMessageBank.deleteMessage(l_pin: l_pin, messageId: message_id, scope: scope, type: type, chat: chat)
        Nexilis.deleteQueueMessage(message: tmessage)
    }
    
    private func queryMessageReply(message_id: String) -> [String: Any?] {
        var dataQuery: [String: Any] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT message_id, f_pin, message_text, attachment_flag, thumb_id, image_id, video_id, file_id FROM MESSAGE where message_id='\(message_id)'"), c.next() {
                dataQuery["message_id"] = c.string(forColumnIndex: 0)
                dataQuery["f_pin"] = c.string(forColumnIndex: 1)
                dataQuery["message_text"] = c.string(forColumnIndex: 2)
                dataQuery["attachment_flag"] = c.string(forColumnIndex: 3)
                dataQuery["thumb_id"] = c.string(forColumnIndex: 4)
                dataQuery["image_id"] = c.string(forColumnIndex: 5)
                dataQuery["video_id"] = c.string(forColumnIndex: 6)
                dataQuery["file_id"] = c.string(forColumnIndex: 7)
                c.close()
            }
        })
        return dataQuery
    }
    
    @objc func segmentedControlValueChanged(_ sender: segmentedControllerObject) {
        switch sender.selectedSegmentIndex {
        case 0:
            sender.navigation.viewControllers[0].children[1].view.isHidden = true
            break;
        case 1:
            sender.navigation.viewControllers[0].children[1].view.isHidden = false
            break;
        default:
            break;
        }
    }
    
    private func copyOption(indexPath: IndexPath) -> UIMenu {
        var ratingButtonTitles = ["Text".localized(), "Image".localized()]
        if (dataMessages[indexPath.row]["message_text"]  as? String ?? "").isEmpty {
            ratingButtonTitles = ["Image".localized()]
        }
        let dataMessages = self.messages(onDate: dataDates[indexPath.section])
        let copyActions = ratingButtonTitles
            .enumerated()
            .map { index, title in
                return UIAction(
                    title: title,
                    identifier: nil,
                    handler: {(_) in
                        if (dataMessages[indexPath.row]["message_text"]  as? String ?? "").isEmpty {
                            DispatchQueue.main.async {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"]  as? String ?? "")
                                    if FileManager.default.fileExists(atPath: imageURL.path) {
                                        let image    = UIImage(contentsOfFile: imageURL.path)
                                        UIPasteboard.general.image = image
                                        self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                    }
                                    else if FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                                        do {
                                            if var imageData = try FileEncryption.shared.readSecure(filename: imageURL.lastPathComponent) {
                                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: imageData)
                                                if dataDecrypt != nil {
                                                    imageData = dataDecrypt!
                                                }
                                                let image = UIImage(data: imageData)
                                                UIPasteboard.general.image = image
                                                self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                            }
                                        } catch {
                                            
                                        }
                                    }
                                }
                            }
                            return
                        }
                        if (index == 0) {
                            DispatchQueue.main.async {
                                UIPasteboard.general.string = dataMessages[indexPath.row]["message_text"] as? String
                                self.view.makeToast("Text coppied to clipboard".localized(), duration: 3)
                            }
                        } else {
                            DispatchQueue.main.async {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"]  as? String ?? "")
                                    if FileManager.default.fileExists(atPath: imageURL.path) {
                                        let image    = UIImage(contentsOfFile: imageURL.path)
                                        UIPasteboard.general.image = image
                                        self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                    } else if FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                                        do {
                                            if var imageData = try FileEncryption.shared.readSecure(filename: imageURL.lastPathComponent) {
                                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: imageData)
                                                if dataDecrypt != nil {
                                                    imageData = dataDecrypt!
                                                }
                                                let image = UIImage(data: imageData)
                                                UIPasteboard.general.image = image
                                                self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                            }
                                        } catch {
                                            
                                        }
                                    }
                                }
                            }
                        }
                        self.dismissKeyboard()
                        
                    })
            }
        return UIMenu(
            title: "Copy".localized(),
            image: UIImage(systemName: "doc.on.doc.fill"),
            children: copyActions)
    }
    
    /// Takes a run of messages back, either only from this phone or from everyone.
    ///
    /// This used to be the body of a `UIAlertAction`, which meant the only way to offer it was a
    /// system action sheet. It is a plain method now so the card that asks the question can be
    /// drawn to look like the rest of the app.
    private func performDelete(for type: String, dataMessages: [[String: Any?]], onDone: (() -> Void)? = nil) {
        for i in 0..<dataMessages.count {
            if (type == "me") {
                if let groupingImages = groupImages[dataMessages[i]["message_id"]  as? String ?? ""] {
                    for i in 0..<groupingImages.count {
                        self.deleteMessage(l_pin: dataGroup["group_id"]  as? String ?? "", message_id: groupingImages[i].messageId, scope: MessageScope.GROUP, type: "1", chat: dataTopic["chat_id"]  as? String ?? "")
                        let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == groupingImages[i].messageId })
                        if idx != nil {
                            self.dataMessages.remove(at: idx!)
                            if (idx == self.dataMessages.count - 1) {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                            }
                            for i in 0..<dataDates.count {
                                if self.messages(onDate: dataDates[i]).count == 0 {
                                    dataDates.remove(at: i)
                                }
                            }
                        }
                    }
                    self.groupImages.removeValue(forKey: groupingImages[0].messageId)
                } else {
                    if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    } else {
                        if let groupingImages = groupImages[dataMessages[i]["message_id"]  as? String ?? ""] {
                            for i in 0..<groupingImages.count {
                                self.deleteMessage(l_pin: dataGroup["group_id"]  as? String ?? "", message_id: groupingImages[i].messageId, scope: MessageScope.GROUP, type: "2", chat: dataTopic["chat_id"]  as? String ?? "")
                                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == groupingImages[i].messageId})
                                if idx != nil {
                                    self.dataMessages[idx!]["lock"] = "1"
                                    self.dataMessages[idx!]["attachment_flag"] = "0"
                                    self.dataMessages[idx!]["reff_id"] = ""
                                }
                            }
                            if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == groupingImages[0].messageId}) {
                                var dataMessageInGrouping = (groupImages[dataMessages[i]["message_id"]  as? String ?? ""]!).map({ $0.dataMessage })
                                dataMessageInGrouping.remove(at: 0)
                                self.dataMessages.insert(contentsOf: dataMessageInGrouping, at: idx+1)
                                self.groupImages.removeValue(forKey: groupingImages[0].messageId)
                            }
                        } else {
                            self.deleteMessage(l_pin: dataGroup["group_id"]  as? String ?? "", message_id: dataMessages[i]["message_id"]  as? String ?? "", scope: MessageScope.GROUP, type: "1", chat: dataTopic["chat_id"]  as? String ?? "")
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[i]["message_id"] as? String})
                            if idx != nil {
                                self.dataMessages.remove(at: idx!)
                                if (idx == self.dataMessages.count - 1) {
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                                }
                                for i in 0..<dataDates.count {
                                    if self.messages(onDate: dataDates[i]).count == 0 {
                                        dataDates.remove(at: i)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                self.deleteMessage(l_pin: dataGroup["group_id"]  as? String ?? "", message_id: dataMessages[i]["message_id"]  as? String ?? "", scope: MessageScope.GROUP, type: "2", chat: dataTopic["chat_id"]  as? String ?? "")
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == dataMessages[i]["message_id"]  as? String ?? ""})
                if idx != nil {
                    self.dataMessages[idx!]["lock"] = "1"
                    self.dataMessages[idx!]["attachment_flag"] = "0"
                    self.dataMessages[idx!]["reff_id"] = ""
                }
            }
            if self.listTimerCredential[dataMessages[i]["message_id"]  as? String ?? ""] != nil {
                self.listTimerCredential.removeValue(forKey: dataMessages[i]["message_id"]  as? String ?? "")
                self.timerCredential[dataMessages[i]["message_id"]  as? String ?? ""]?.invalidate()
                self.timerCredential.removeValue(forKey: dataMessages[i]["message_id"]  as? String ?? "")
            }
        }
        let dataMessagesPin = self.pinnedMessagesForBanner()
        self.pinAllMessages(dataMessages: dataMessagesPin)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        cancelAction()
        // Only reached when a message was really taken back, so a viewer still open over the
        // top of this - showing a picture that no longer exists - can be closed here.
        onDone?()
    }
    
    @objc func deleteReplyView() {
        if self.containerPreviewReply.isDescendant(of: self.viewTextfield) {
            // Off the preview before the preview goes. A constraint pointing at a view that has
            // left the hierarchy is simply dropped, and a button with nothing holding it
            // vertically lands wherever the layout puts it and then flies back - the bounce up
            // from the bottom of the screen.
            self.refreshScrollToBottomButtonPlacement(ignoringReplyPreview: true)
            self.containerPreviewReply.subviews.forEach { $0.removeFromSuperview() }
            self.containerPreviewReply.removeConstraints(self.containerPreviewReply.constraints)
            self.containerPreviewReply.removeFromSuperview()
            
            self.reffId = nil
            let replyBarHeight = 50 + (self.offset() * 3)
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant - replyBarHeight
                if self.contraintBottomMention.constant > 0 {
                    self.contraintBottomMention.constant = self.contraintBottomMention.constant - 50
                }
                self.view.layoutIfNeeded()
                self.keepScrollPosition(whenInputGrewBy: -replyBarHeight)
            }, completion: nil)
        }
    }
    
    @objc func removeLinkPreviewUntilEmptyTextView() {
        isAlwaysHideLinkPreview = true
        deleteLinkPreview()
    }
    
    @objc func deleteLinkPreview() {
        if self.containerLink.isDescendant(of: self.viewTextfield) {
            self.containerLink.subviews.forEach { $0.removeFromSuperview() }
            self.containerLink.removeConstraints(self.containerLink.constraints)
            self.containerLink.removeFromSuperview()
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant - 80
                if self.contraintBottomMention.constant > 0 {
                    self.contraintBottomMention.constant = self.contraintBottomMention.constant - 80
                }
            }, completion: nil)
            self.showingLink = ""
        }
        if self.reffId != nil {
            self.bottomAnchorPreviewReply.isActive = false
            self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.textFieldSend.topAnchor)
            self.bottomAnchorPreviewReply.isActive = true
        }
    }

    // Fix: linkHit/firstTextView/linkInfo/boundingRect moved to LinkHighlighting
    // (LinkOpener.swift) - shared, stateless helpers also used by EditorPersonal and
    // EditorStarMessages, so all three screens can't drift out of sync with each
    // other on how link hit-testing/highlighting is computed.

    // MARK: - Link long-press popup (WhatsApp-style: "Open Link" / "Copy")

    // Fix: WhatsApp-style bottom sheet via UISheetPresentationController (iOS 15+),
    // replacing the plain UIAlertController(style: .actionSheet). Called from
    // configurationForMenuAtLocation once containerMessage's existing
    // UIContextMenuInteraction reliably recognizes a long-press over a link (see the
    // note above that method for why this routing, rather than a separate gesture
    // recognizer on messageText, is what actually works consistently for a
    // stationary press-and-hold).
    private func presentLinkActionSheet(urlString: String, sourceView: UIView, sourceRect: CGRect) {
        let openAction: () -> Void = { [weak self] in
            let gesture = ObjectGesture()
            gesture.message_id = urlString
            self?.tapMessageText(gesture)
        }
        let copyAction: () -> Void = { [weak self] in
            UIPasteboard.general.string = urlString
            self?.view.makeToast("Link Copied".localized(), duration: 3)
        }
        // Fix: only offer "Open in Chrome" when Chrome is actually installed.
        // canOpenURL against a custom scheme silently returns false unless that
        // scheme is declared in Info.plist's LSApplicationQueriesSchemes - "googlechrome"
        // was added there for exactly this check.
        let chromeOpenURL = LinkHighlighting.chromeURL(for: urlString)
        let chromeInstalled = chromeOpenURL.map { UIApplication.shared.canOpenURL($0) } ?? false
        let openInChromeAction: (() -> Void)? = chromeInstalled ? { [weak self] in
            guard let chromeOpenURL = chromeOpenURL else { return }
            UIApplication.shared.open(chromeOpenURL, options: [:]) { success in
                if !success {
                    // Fix: fall back to the regular link-open flow if Chrome, despite
                    // passing the canOpenURL check, fails to actually handle the URL.
                    let gesture = ObjectGesture()
                    gesture.message_id = urlString
                    self?.tapMessageText(gesture)
                }
            }
        } : nil

        // Fix: UISheetPresentationController is iOS 15+ only (this project's
        // deployment target is iOS 14 - see Podfile) - fall back to the plain
        // UIAlertController action sheet on iOS 14 devices.
        if #available(iOS 15.0, *) {
            let sheetVC = LinkActionSheetViewController(urlString: urlString, onOpen: openAction, onCopy: copyAction, onOpenInChrome: openInChromeAction)
            // Fix: hides the highlight no matter how the sheet was dismissed (an
            // action tapped, or swiped away/tapped-outside with nothing chosen).
            sheetVC.onDismissed = { [weak self] in self?.hideLinkHighlight() }

            if let sheet = sheetVC.sheetPresentationController {
                if #available(iOS 16.0, *) {
                    let contentHeight = sheetVC.preferredContentHeight(forWidth: self.view.bounds.width)
                    sheet.detents = [.custom(resolver: { _ in contentHeight })]
                } else {
                    // Fix: iOS 15 doesn't support custom-height detents - .medium()
                    // is the closest available and will leave some empty space below
                    // the content; this is a known, acceptable trade-off on iOS 15
                    // only, resolved automatically once the device is on iOS 16+.
                    sheet.detents = [.medium()]
                }
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
            present(sheetVC, animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: urlString, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Open Link".localized(), style: .default) { [weak self] _ in
                self?.hideLinkHighlight()
                openAction()
            })
            if let openInChromeAction = openInChromeAction {
                alert.addAction(UIAlertAction(title: "Open in Chrome".localized(), style: .default) { [weak self] _ in
                    self?.hideLinkHighlight()
                    openInChromeAction()
                })
            }
            alert.addAction(UIAlertAction(title: "Copy".localized(), style: .default) { [weak self] _ in
                self?.hideLinkHighlight()
                copyAction()
            })
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel) { [weak self] _ in
                self?.hideLinkHighlight()
            })

            // Fix: required on iPad (actionSheet crashes there without a popover
            // anchor) - anchoring it to the link's own rect also means the popover
            // arrow points straight at the link that was pressed.
            if let popover = alert.popoverPresentationController {
                popover.sourceView = sourceView
                popover.sourceRect = sourceRect
            }
            present(alert, animated: true)
        }
    }

    // Fix: chromeURL(for:)/highlightRects(for:in:) moved to LinkHighlighting
    // (LinkOpener.swift) - see the note above linkHit/firstTextView/linkInfo/boundingRect.

    // MARK: - Link touch highlight (shown/hidden on touch-down, tap, and long-press)

    /// Shows the gray highlight over exactly `range`'s glyphs (per line, see
    /// `LinkHighlighting.highlightRects(for:in:)`) - hides any other highlight first,
    /// since only one link's popup/action can be active at a time anyway.
    private func showLinkHighlight(range: NSRange, in textView: UITextView) {
        hideLinkHighlight()
        for rect in LinkHighlighting.highlightRects(for: range, in: textView) {
            guard rect.width > 0, rect.height > 0 else { continue }
            let chip = UIView(frame: rect.insetBy(dx: -2, dy: -1))
            chip.backgroundColor = UIColor.systemGray.withAlphaComponent(0.35)
            chip.layer.cornerRadius = 4
            chip.isUserInteractionEnabled = false
            textView.addSubview(chip)
            currentLinkHighlightViews.append(chip)
        }
    }

    private func hideLinkHighlight() {
        for chip in currentLinkHighlightViews {
            chip.removeFromSuperview()
        }
        currentLinkHighlightViews.removeAll()
    }

    // MARK: - Link touch-down highlight (instant, purely cosmetic)

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Fix: LinkTouchHighlightGesture only ever draws/erases a highlight - it must
        // never block or compete with any other gesture (text taps, containerMessage's
        // UIContextMenuInteraction, table view scrolling) for the same touch. Scoped
        // to this one class so it doesn't change simultaneous-recognition behavior for
        // any other gesture recognizer that might use `self` as a delegate elsewhere.
        if gestureRecognizer is LinkTouchHighlightGesture || otherGestureRecognizer is LinkTouchHighlightGesture {
            return true
        }
        return false
    }

    // Fix: this is where the "hold for 0.3s -> show LinkActionSheetViewController,
    // otherwise it's a tap -> open link" decision is made - see the comment on
    // configurationForMenuAtLocation for why that delegate method (containerMessage's
    // UIContextMenuInteraction, whose own recognition threshold is a shorter,
    // non-configurable ~0.3-0.5s) is no longer where the sheet gets triggered from.
    // This gesture starts tracking from the very first instant of touch-down
    // (minimumPressDuration = 0 on LinkTouchHighlightGesture), which is what makes
    // timing an exact, deliberate duration from touch-down possible.
    @objc private func handleLinkTouchHighlight(_ sender: LinkTouchHighlightGesture) {
        guard let textView = sender.textView else { return }
        let point = sender.location(in: textView)

        switch sender.state {
        case .began:
            guard let info = LinkHighlighting.linkInfo(at: point, in: textView) else { return }
            showLinkHighlight(range: info.range, in: textView)

            linkPressGeneration += 1
            let thisGeneration = linkPressGeneration
            let urlString = info.urlString
            let range = info.range
            DispatchQueue.main.asyncAfter(deadline: .now() + LinkHighlighting.longPressThreshold) { [weak self, weak textView] in
                guard let self = self, let textView = textView else { return }
                // Fix: only proceed if nothing happened to this touch since it began
                // (finger lifted early = a tap, finger moved off the link, or a new
                // touch started) - a stale timer for a touch that's already over must
                // not fire the action sheet a second (or two) after the fact.
                guard self.linkPressGeneration == thisGeneration else { return }
                self.suppressNextLinkTap = true
                self.suppressLinkTapToken += 1
                let myToken = self.suppressLinkTapToken
                // Fix: safety net - if the eventual finger-lift after this point
                // never actually triggers handleMessageTextTap (can't be fully
                // guaranteed without on-device testing), this flag would stay stuck
                // true forever and silently swallow the NEXT unrelated tap on some
                // other link. Auto-clear it after a few seconds if nothing consumed
                // it by then (generous window since the user may keep holding/reading
                // the sheet for a while before dismissing it). Gated on
                // suppressLinkTapToken (NOT linkPressGeneration, which bumps on every
                // touch end/cancel and would make this basically never fire) - so a
                // stale reset here can't wrongly clear a flag that a SUBSEQUENT,
                // unrelated long-press has since legitimately set true again.
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    guard let self = self, self.suppressLinkTapToken == myToken else { return }
                    self.suppressNextLinkTap = false
                }
                self.presentLinkActionSheet(urlString: urlString, sourceView: textView, sourceRect: LinkHighlighting.boundingRect(for: range, in: textView))
            }

        case .changed:
            if let info = LinkHighlighting.linkInfo(at: point, in: textView) {
                showLinkHighlight(range: info.range, in: textView)
            } else {
                // Fix: finger dragged off the link before the threshold - this is no
                // longer a press on this link at all, invalidate the pending timer
                // (via the generation bump) so it doesn't fire late for a touch that
                // moved elsewhere, and hide the highlight instantly - it must not
                // linger on a spot the finger isn't over anymore.
                hideLinkHighlight()
                linkPressGeneration += 1
            }

        case .ended, .cancelled, .failed:
            // Fix: hide the highlight the INSTANT the finger leaves the screen, no
            // matter why (clean release, cancelled, failed) or what happens next
            // (a quick tap opening the link, or a long-press that already triggered
            // the action sheet) - matches WhatsApp, where the highlight tracks the
            // finger's actual on-screen presence, not some artificial delay tied to
            // what action follows. Unconditional now (previously deferred to
            // whichever downstream flow "owned" the touch, which added a visible lag
            // between finger-lift and the highlight actually disappearing).
            linkPressGeneration += 1
            hideLinkHighlight()

        default:
            break
        }
    }
}

extension EditorGroup: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 76
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellSticker", for: indexPath)
        if (cell.contentView.subviews.count > 0) {
            cell.contentView.subviews[0].removeFromSuperview()
        }
        let imageSticker = UIImageView()
        cell.contentView.addSubview(imageSticker)
        imageSticker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageSticker.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            imageSticker.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            imageSticker.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            imageSticker.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
        ])
        var imageStickerBundle = UIImage(named: stickers[indexPath.row], in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        if imageStickerBundle == nil {
            imageStickerBundle = UIImage(named: stickers[indexPath.row], in: Bundle.resourcesMediaBundle(for: Nexilis.self), with: nil)
        }
        imageSticker.image = imageStickerBundle //resourcesMediaBundle
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        sendChat(message_text: "sticker/\(stickers[indexPath.row])", attachment_flag: "11", viewController: self)
        constraintBottomAttachment.constant = 0.0
        self.viewSticker.removeConstraints(self.viewSticker.constraints)
        self.viewSticker.removeFromSuperview()
    }
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem!
    }
}

extension EditorGroup: UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate {
    //    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    //        checkNewMessage(tableView: tableView)
    //    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard tableView == tableChatView else {
            return
        }
        // Remember what each row actually measured, so the table estimates the rows it has
        // not built yet from real numbers. That is what keeps the content from shifting under
        // the reader when a page of older messages is inserted above.
        if let messageId = message(at: indexPath)?["message_id"] as? String, cell.frame.height > 0 {
            measuredRowHeights[messageId] = cell.frame.height
        }
        // Something new came into view; fetch whatever it needs once the list settles.
        scheduleAutoDownloadSweep()
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard tableView == tableChatView else {
            return UITableView.automaticDimension
        }
        if let messageId = message(at: indexPath)?["message_id"] as? String, let height = measuredRowHeights[messageId] {
            return height
        }
        return 72
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrolledSinceLastFrame = abs(scrollView.contentOffset.y - lastY)
        lastY = scrollView.contentOffset.y
        // The reader has taken the list over - a later layout pass must not pull it back to
        // the unread marker under their finger.
        if scrollView == tableChatView, scrollView.isDragging, pendingUnreadMarkerScroll != nil {
            pendingUnreadMarkerScroll = nil
        }
        // Last resort: the reader has run out of loaded messages mid-flight. Reading more here
        // costs the deceleration, but a list that stops dead at a false end costs more.
        if scrollView == tableChatView, !isInitialLoading, scrollView.contentOffset.y < 400, hasOlderMessages {
            loadOlderMessages()
        }
        // The tail of a fling, where the momentum left is too small for the eye to miss. Two
        // quick flicks in a row never let the scroll settle, so this is the only chance to
        // refill the buffer between them - and taking 3pt/frame away is not a stop anyone
        // sees.
        else if scrollView == tableChatView, !isInitialLoading, hasOlderMessages,
                scrollView.isDecelerating, !scrollView.isDragging,
                scrolledSinceLastFrame < 4,
                scrollView.contentOffset.y < scrollView.frame.height * 3 {
            loadOlderMessages()
        }
        // And the other end, for a window a jump has moved off the newest message.
        if scrollView == tableChatView, !isInitialLoading, !isWindowAtNewest {
            let distanceFromBottom = scrollView.contentSize.height - scrollView.frame.height - scrollView.contentOffset.y
            if distanceFromBottom < 400 {
                loadNewerMessages()
            }
        }
        let now = Date()
        guard now.timeIntervalSince(lastScrollCheckTime) > 0.3 else { return }
        lastScrollCheckTime = now

        DispatchQueue.main.async {
            if self.isInitialLoading {
                return
            }
            self.checkNewMessage(tableView: self.tableChatView)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == tableChatView else {
            return
        }
        prefetchOlderMessagesIfIdle()
        scheduleAutoDownloadSweep()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == tableChatView, !decelerate else {
            return
        }
        prefetchOlderMessagesIfIdle()
        scheduleAutoDownloadSweep()
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == tableMention || tableView == tableMentionEdit || tableView == tableViewConfigFile {
            return 1
        }
        return dataDates.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tableViewConfigFile {
            return 2
        }
        if tableView == tableMention || tableView == tableMentionEdit {
            return listMentionWithText.count
        }
        // The table asks about sections it was told about a moment ago; the list can already
        // have fewer. Answering for a section that is gone is a crash, answering zero is not.
        guard section >= 0, section < dataDates.count else {
            return 0
        }
        return messages(onDate: dataDates[section]).count
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == tableViewConfigFile {
            return nil
        }
        if tableView == tableMention || tableView == tableMentionEdit {
            return .none
        }
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let dateView = UIView()
        containerView.addSubview(dateView)
        dateView.translatesAutoresizingMaskIntoConstraints = false
        var topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor)
        topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10)
        NSLayoutConstraint.activate([
            topAnchor,
            dateView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dateView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dateView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        dateView.backgroundColor = .orangeColor
        dateView.layer.cornerRadius = 8.0
        dateView.clipsToBounds = true
        
        let labelDate = UILabel()
        dateView.addSubview(labelDate)
        labelDate.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelDate.centerYAnchor.constraint(equalTo: dateView.centerYAnchor),
            labelDate.centerXAnchor.constraint(equalTo: dateView.centerXAnchor),
            labelDate.leadingAnchor.constraint(equalTo: dateView.leadingAnchor, constant: 10),
            labelDate.trailingAnchor.constraint(equalTo: dateView.trailingAnchor, constant: -10),
        ])
        labelDate.textAlignment = .center
        labelDate.textColor = .secondaryColor
        labelDate.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
        labelDate.text = dataDates[section]
        return containerView
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == tableMention || tableView == tableMentionEdit || tableView == tableViewConfigFile {
            return 0
        }
        return 30
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == tableViewConfigFile {
            tableView.deselectRow(at: indexPath, animated: true)
            var type = ""
            if indexPath.row == 0 {
                type = "share,download"
            } else {
                type = "forward"
            }
            if !specFileString.contains(type) {
                if !specFileString.isEmpty {
                    specFileString += ","
                }
                specFileString += type
            } else {
                specFileString = specFileString.replacingOccurrences(of: type, with: "")
                if specFileString == "," {
                    specFileString = ""
                }
            }
            if specFileString.isEmpty {
                buttonSpec.setImage(UIImage(named: "pb_ic_attach_spc_off", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 30, height: 30)), for: .normal)
            } else {
                buttonSpec.setImage(UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal).resize(target: CGSize(width: 30, height: 30)), for: .normal)
            }
            tableView.reloadData()
            return
        }
        if tableView == tableMention || tableView == tableMentionEdit {
            tableView.deselectRow(at: indexPath, animated: true)
            var nowTextField = textFieldSend!
            if tableView == tableMentionEdit {
                nowTextField = editTextView
            }
            let fulltextForMention = nowTextField.text.substring(from: 0, to: lastPositionCursorMention - 1)
            let diff = nowTextField.text.count - fulltextForMention.count
            let lines = fulltextForMention.split(separator: "\n")
            if let lastLineIndex = lines.lastIndex(where: { !$0.isEmpty }) {
                let words = lines[lastLineIndex].split(separator: " ")
                if let lastWordIndex = words.lastIndex(where: { !$0.isEmpty }) {
                    var lastWord = words[lastWordIndex]
                    if let textM = extractFromAtIfSymbolsBefore(String(lastWord)) {
                        lastWord = textM[textM.startIndex..<textM.endIndex]
                    }
                    if let rangeLastWord = fulltextForMention.range(of: lastWord, options: .backwards) {
                        listMentionInTextField.append(listMentionWithText[indexPath.row])
                        
                        var addSpaceAfterReplacement = ""
                        if diff == 0 {
                            addSpaceAfterReplacement = " "
                        }
                        
                        var text = nowTextField.text ?? ""
                        let nameMention = listMentionWithText[indexPath.row].fullName.trimmingCharacters(in: .whitespaces)
                        listMentionInTextField.last?.ex_block = "\(fulltextForMention.distance(from: fulltextForMention.startIndex, to: rangeLastWord.lowerBound) + nameMention.count)" //upperbound
                        let replacementText = "@\(nameMention)"
                        
                        // Replace the old text with the new text using the replaceSubrange(_:with:) method
                        text.replaceSubrange(rangeLastWord, with: replacementText + addSpaceAfterReplacement)
                        
                        nowTextField.attributedText = text.richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "", listMentionInTextField: listMentionInTextField)
                        
                        let newPosition = nowTextField.position(from: nowTextField.beginningOfDocument, offset: nowTextField.text.count - diff)
                        nowTextField.selectedTextRange = nowTextField.textRange(from: newPosition!, to: newPosition!)
                        
                        hideMention()
                        lastTextLength = nowTextField.text.count
                        return
                    }
                }
            }
        }
        let dataMessages = self.messages(onDate: dataDates[indexPath.section])
        if copySession || forwardSession || deleteSession || summarizeSession {
            guard indexPath.row < dataMessages.count else {
                return
            }
            let imageChat = dataMessages[indexPath.row]["image_id"]  as? String ?? ""
            let videoChat = dataMessages[indexPath.row]["video_id"]  as? String ?? ""
            let fileChat = dataMessages[indexPath.row]["file_id"]  as? String ?? ""
            let audioChat = dataMessages[indexPath.row]["audio_id"]  as? String ?? ""
            let messageText = dataMessages[indexPath.row][TypeDataMessage.message_text]  as? String ?? ""
            if !imageChat.isEmpty || !videoChat.isEmpty || !fileChat.isEmpty || !audioChat.isEmpty {
                if summarizeSession || (copySession && messageText.isEmpty) {
                    return
                } else if forwardSession && (!Nexilis.checkingAccess(key: "secure_folder_forward") || (!(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty && !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward"))) {
                    return
                } else {
                    var file = imageChat
                    if file.isEmpty {
                        file = videoChat
                        if file.isEmpty {
                            file = fileChat
                            if file.isEmpty {
                                file = audioChat
                            }
                        }
                    }
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(file)
                        if !FileManager.default.fileExists(atPath: fileURL.path) && !FileEncryption.shared.isSecureExists(filename: fileURL.lastPathComponent) {
                            return
                        } else if !fileChat.isEmpty && messageText.component(1, separatedBy: "|").isEmpty {
                            return
                        }
                    }
                }
            }
            if (copySession || forwardSession || summarizeSession) && (dataMessages[indexPath.row]["lock"] as? String == "1" || (dataMessages[indexPath.row]["credential"] as? String) == "1" || (dataMessages[indexPath.row]["lock"] as? String) == "2" || dataMessages[indexPath.row]["f_pin"]  as? String ?? "" == "-999" || dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "11" || (dataMessages[indexPath.row]["message_id"] as? String ?? "").contains("NTFPIN_")) {
                return
            }
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == dataMessages[indexPath.row]["message_id"]  as? String ?? ""})
            if idx != nil {
                self.dataMessages[idx!]["isSelected"] = !(self.dataMessages[idx!]["isSelected"] as? Bool ?? false)
                self.tableChatView.reloadRows(at: [indexPath], with: .none)
            }
            containerMultpileSelectSession.subviews.forEach({ $0.removeFromSuperview() })
            addSubviewMultipleSession()
            return
        }
        let message = dataMessages[indexPath.row]
        if let attachmentFlag = message["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" || attachmentFlag == "26" {
                if attachmentFlag == "27" {
                    if APIS.blockedByCallInProgress() {
                        return
                    }
                    if !Nexilis.checkingAccess(key: "live_streaming") {
                        if Nexilis.checkingAccessAlert(key: "live_streaming") != "|" && !Nexilis.checkingAccessAlert(key: "live_streaming").isEmpty {
                            let title = Nexilis.checkingAccessAlert(key: "live_streaming").components(separatedBy: "|")[0]
                            let message = Nexilis.checkingAccessAlert(key: "live_streaming").component(1, separatedBy: "|")
                            APIS.nexilisShowAlertWithHTMLMessage(on: UIApplication.shared.visibleViewController ?? UIViewController(), title: title, message: message)
                        } else {
                            UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
                        }
                        return
                    }
                }
                let streamingController = (attachmentFlag == "27") ? QmeraCreateStreamingViewController() : CreateSeminarViewController()
                switch(attachmentFlag){
                case "27":
                    (streamingController as! QmeraCreateStreamingViewController).isJoin = true
                default:
                    (streamingController as! CreateSeminarViewController).isJoin = true
                }
                if let messageText = message["message_text"],
                   let messageText = messageText as? String,
                   var json = try! JSONSerialization.jsonObject(with: messageText.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    if json["blog"] == nil {
                        json["blog"] = message["blog_id"] ?? nil
                    }
                    switch(attachmentFlag){
                    case "27":
                        (streamingController as! QmeraCreateStreamingViewController).data = json
                    default:
                        (streamingController as! CreateSeminarViewController).data = json
                    }
                }
                let streamingNav = CustomNavigationController(rootViewController: streamingController)
                streamingNav.modalPresentationStyle = .custom
                streamingNav.navigationBar.tintColor = .white
                streamingNav.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
                streamingNav.navigationBar.isTranslucent = false
                streamingNav.navigationBar.overrideUserInterfaceStyle = .dark
                streamingNav.navigationBar.barStyle = .black
                let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
                UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                streamingNav.navigationBar.titleTextAttributes = textAttributes
                streamingNav.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
                streamingNav.navigationBar.isTranslucent = false
                navigationController?.present(streamingNav, animated: true, completion: nil)
            }
        }
    }
    
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tableViewConfigFile {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellConfigFile", for: indexPath as IndexPath)
            var content = cell.defaultContentConfiguration()
            content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            content.textProperties.color = .label
            content.secondaryTextProperties.font = .systemFont(ofSize: 14)
            content.secondaryTextProperties.color = .gray
            if indexPath.row == 0 {
                content.text = "Can Share and Download".localized()
                content.secondaryText = "The user, as the receiver, can share and download the attachment.".localized()
                cell.accessoryType = specFileString.contains("share,download") ? .checkmark : .none
            } else {
                content.text = "Can Forward".localized()
                content.secondaryText = "The user, as the receiver, can forward the attachment.".localized()
                cell.accessoryType = specFileString.contains("forward") ? .checkmark : .none
            }
            cell.contentConfiguration = content
            cell.tintColor = .black
            return cell
        }
        if tableView == tableMention || tableView == tableMentionEdit {
            let cellMention = tableView.dequeueReusableCell(withIdentifier: tableView == tableMention ? "cellMention" : "cellEditMention", for: indexPath as IndexPath)
            var content = cellMention.defaultContentConfiguration()
            content.textProperties.font = UIFont.systemFont(ofSize: 11 + offset())
            content.imageProperties.tintColor = .black
            content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
            if indexPath.row < listMentionWithText.count {
                if listMentionWithText[indexPath.row].pin == "-997" {
                    if let urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif"), let data = try? Data(contentsOf: urlGif), let source = CGImageSourceCreateWithData(data as CFData, nil), let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                        let staticImage = UIImage(cgImage: cgImage)
                        content.image = staticImage.circleMasked
                    } else if let urlGif = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif"), let data = try? Data(contentsOf: urlGif), let source = CGImageSourceCreateWithData(data as CFData, nil), let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                        let staticImage = UIImage(cgImage: cgImage)
                        content.image = staticImage.circleMasked
                    }
                } else {
                    getImage(name: listMentionWithText[indexPath.row].thumb, placeholderImage: UIImage(systemName: "person"), isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, image in
                        content.image = image
                    })
                }
                content.text = listMentionWithText[indexPath.row].firstName + " " + listMentionWithText[indexPath.row].lastName
            }
            cellMention.contentConfiguration = content
            return cellMention
        }
        let idMe = User.getMyPin() as String?
        let cellMessage = tableView.dequeueReusableCell(withIdentifier: "cellEditorGroup", for: indexPath as IndexPath)
        cellMessage.backgroundColor = .clear
        cellMessage.selectionStyle = .none
        // The table can ask for a row this section no longer has. It learns about a change a
        // moment after the list itself changes, and a transfer finishing redraws rows in
        // between - reading past the end there is a crash, where an empty cell for one frame is
        // not. Every read below is against these two lines being true.
        guard indexPath.section >= 0, indexPath.section < dataDates.count else {
            emptyBubbleCell(cellMessage)
            return cellMessage
        }
        let dataMessages = messages(onDate: dataDates[indexPath.section])
        guard indexPath.row >= 0, indexPath.row < dataMessages.count else {
            emptyBubbleCell(cellMessage)
            return cellMessage
        }
        // Fix: a bubble was emptied and built again from nothing every time this ran - forty-odd
        // views and two hundred constraints - and it runs for every row of every redraw, not
        // only for rows that are new to the screen. A message arriving, a status changing, a
        // file landing: each of those redraws rows whose bubbles are already correct and already
        // in front of the reader. When the cell in hand was built for this message in this state,
        // it is already the answer.
        let signature = bubbleSignature(for: dataMessages[indexPath.row], at: indexPath)
        if builtSignature(of: cellMessage) == signature {
            // A pull that was interrupted can leave a bubble sitting off to one side. Building
            // the cell again used to clear that as a side effect of throwing the views away, so
            // handing one back has to say it plainly.
            cellMessage.contentView.subviews.forEach { $0.transform = .identity }
            return cellMessage
        }
        emptyBubbleCell(cellMessage)
        setBuiltSignature(signature, on: cellMessage)
        
        let profileMessage = UIImageView()
        profileMessage.frame.size = CGSize(width: 35, height: 35)
        cellMessage.contentView.addSubview(profileMessage)
        profileMessage.translatesAutoresizingMaskIntoConstraints = false
        let tapGestureRecognizer = ObjectGesture(target: self, action: #selector(profilePersonTapped(_:)))
        tapGestureRecognizer.message_id = dataMessages[indexPath.row]["f_pin"]  as? String ?? ""
        profileMessage.isUserInteractionEnabled = true
        profileMessage.addGestureRecognizer(tapGestureRecognizer)
        
        var containerMessage = UIView()
        if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            containerMessage = SecureField().secureContainer!
        }
        let messageIdChat = (dataMessages[indexPath.row]["message_id"] as? String) ?? ""
        let thumbChat = dataMessages[indexPath.row]["thumb_id"]  as? String ?? ""
        let imageChat = dataMessages[indexPath.row]["image_id"]  as? String ?? ""
        let videoChat = dataMessages[indexPath.row]["video_id"]  as? String ?? ""
        let fileChat = dataMessages[indexPath.row]["file_id"]  as? String ?? ""
        let reffChat = dataMessages[indexPath.row]["reff_id"]  as? String ?? ""
        let audioChat = (dataMessages[indexPath.row]["audio_id"] as? String) ?? ""
        let gifChat = (dataMessages[indexPath.row]["gif_id"] as? String) ?? ""
        let dataTimer = listTimerCredential[(dataMessages[indexPath.row]["message_id"]  as? String ?? "")]
        var textChat = dataMessages[indexPath.row]["message_text"] as? String ?? ""
        
        cellMessage.contentView.addSubview(containerMessage)
        containerMessage.translatesAutoresizingMaskIntoConstraints = false
        
        if messageIdChat.contains("NTFPIN_") {
            containerMessage.backgroundColor = .orangeColor
            containerMessage.anchor(top: cellMessage.contentView.topAnchor, bottom: cellMessage.contentView.bottomAnchor, paddingTop: 5, paddingBottom: 5, centerX: cellMessage.contentView.centerXAnchor, minWidth: 40, maxWidth: UIScreen.main.bounds.width - 40)
            containerMessage.layer.cornerRadius = 8
            containerMessage.clipsToBounds = true
            
            let textMessage = UILabel()
            containerMessage.addSubview(textMessage)
            textMessage.textAlignment = .center
            textMessage.anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, right: containerMessage.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10)
            textMessage.font = .systemFont(ofSize: 14)
            textMessage.text = dataMessages[indexPath.row][TypeDataMessage.message_text]  as? String ?? ""
            textMessage.textColor = .white
            return cellMessage
        }
        
        let timeMessage = UILabel()
        timeMessage.numberOfLines = 0
        cellMessage.contentView.addSubview(timeMessage)
        timeMessage.translatesAutoresizingMaskIntoConstraints = false
        if ((dataMessages[indexPath.row]["read_receipts"] as? String) == "8" ||
            (dataMessages[indexPath.row]["credential"] as? String) == "1" ||
            !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty) &&
            (dataMessages[indexPath.row]["lock"] as? String) != "2" &&
            (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            timeMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -40).isActive = true
        } else {
            timeMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -5).isActive = true
        }
        
        let messageText = UITextView()
        messageText.isEditable = false
        // Fix: isSelectable = false (was true) - like WhatsApp, no drag-to-select or
        // system text-selection UI on message text. Important side effect: a
        // UITextView's OWN built-in link-tap handling (shouldInteractWith) is gated
        // by isSelectable too - with it false, that delegate method never fires
        // anymore, so link taps are now handled by the dedicated tapGesture below
        // instead, entirely independent of isSelectable.
        messageText.isSelectable = false
        messageText.dataDetectorTypes = [.link]
        messageText.backgroundColor = .clear
        messageText.isScrollEnabled = false
        messageText.textContainerInset = UIEdgeInsets.zero
        messageText.contentInset = UIEdgeInsets.zero
        messageText.textDragInteraction?.isEnabled = false
        // Fix: route long-press link handling through containerMessage's EXISTING
        // UIContextMenuInteraction instead of a separate gesture recognizer trying to
        // compete with it - see `contextMenuInteraction(_:configurationForMenuAtLocation:)`,
        // which presents LinkActionSheetViewController right when IT recognizes a
        // long-press over a link (reliable, since that's the interaction that
        // reliably wins), then returns nil so no actual context menu UI appears.
        //
        // Fix: with isSelectable = false, UITextView's own shouldInteractWith(...)
        // never fires for taps anymore - this plain tap recognizer replaces it,
        // entirely independent of isSelectable. Only acts when the tap actually lands
        // on a detected link (via LinkHighlighting.linkHit(at:in:), same helper the long-press flow
        // uses); taps elsewhere in the message text do nothing here.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMessageTextTap(_:)))
        messageText.addGestureRecognizer(tapGesture)

        // Fix: purely cosmetic - shows the highlight the instant a finger touches a
        // link (minimumPressDuration = 0), rather than waiting for the tap gesture to
        // recognize (finger-up) or the long-press threshold to be met. Never triggers
        // an action itself, so it's safe for it to lose any gesture-arbitration race:
        // if a competing recognizer wins and cancels it, the highlight it drew simply
        // gets cleared, nothing else is affected either way. See LinkOpener.swift's
        // LinkTouchHighlightGesture doc comment for more detail.
        let touchHighlightGesture = LinkTouchHighlightGesture(target: self, action: #selector(handleLinkTouchHighlight(_:)))
        touchHighlightGesture.minimumPressDuration = 0
        touchHighlightGesture.textView = messageText
        touchHighlightGesture.delegate = self
        touchHighlightGesture.cancelsTouchesInView = false
        touchHighlightGesture.delaysTouchesBegan = false
        messageText.addGestureRecognizer(touchHighlightGesture)

        containerMessage.addSubview(messageText)
        messageText.translatesAutoresizingMaskIntoConstraints = false
        var topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32)
        topMarginText.priority = .defaultHigh
        
        let dataProfile = getDataProfile(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "", message_id: dataMessages[indexPath.row]["message_id"]  as? String ?? "")
        
        let statusMessage = UIImageView()
        
        if (dataMessages[indexPath.row]["attachment_flag"] as? String == "0" && dataMessages[indexPath.row]["lock"] as? String != "1") || forwardSession || deleteSession || summarizeSession {
            var showSelectedImage = true
            if !imageChat.isEmpty || !videoChat.isEmpty || !fileChat.isEmpty || !audioChat.isEmpty {
                if summarizeSession || (copySession && textChat.isEmpty) {
                    showSelectedImage = false
                } else if forwardSession && (!Nexilis.checkingAccess(key: "secure_folder_forward") || (!(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty && !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward"))) {
                    showSelectedImage = false
                } else {
                    var file = imageChat
                    if file.isEmpty {
                        file = videoChat
                        if file.isEmpty {
                            file = fileChat
                            if file.isEmpty {
                                file = audioChat
                            }
                        }
                    }
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(file)
                        if !FileManager.default.fileExists(atPath: fileURL.path) && !FileEncryption.shared.isSecureExists(filename: fileURL.lastPathComponent) {
                            showSelectedImage = false
                        } else if !fileChat.isEmpty && textChat.component(1, separatedBy: "|").isEmpty {
                            showSelectedImage = false
                        }
                    }
                }
            }
            if (copySession || forwardSession || summarizeSession) && (dataMessages[indexPath.row]["lock"] as? String == "1" || (dataMessages[indexPath.row]["credential"] as? String) == "1" || (dataMessages[indexPath.row]["lock"] as? String) == "2" || dataMessages[indexPath.row]["f_pin"]  as? String ?? "" == "-999" || dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "11" || messageIdChat.contains("NTFPIN_")) {
                showSelectedImage = false
            }
            if showSelectedImage {
                let selectedImage = UIImageView()
                cellMessage.contentView.addSubview(selectedImage)
                selectedImage.translatesAutoresizingMaskIntoConstraints = false
                selectedImage.frame.size = CGSize(width: 20, height: 20)
                var leading = selectedImage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: -20)
                selectedImage.isHidden = true
                if copySession || forwardSession || deleteSession || summarizeSession {
                    leading = selectedImage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 15)
                    selectedImage.isHidden = false
                }
                NSLayoutConstraint.activate([
                    leading,
                    selectedImage.centerYAnchor.constraint(equalTo: cellMessage.contentView.centerYAnchor),
                    selectedImage.widthAnchor.constraint(equalToConstant: 20),
                    selectedImage.heightAnchor.constraint(equalToConstant: 20)
                ])
                selectedImage.circle()
                selectedImage.layer.borderWidth = 2
                selectedImage.layer.borderColor = UIColor.mainColor.cgColor
                if dataMessages[indexPath.row]["isSelected"] as? Bool ?? false {
                    selectedImage.image = UIImage(systemName: "checkmark.circle.fill")
                }
                selectedImage.tintColor = .mainColor
            }
        }
        
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            profileMessage.trailingAnchor.constraint(equalTo: cellMessage.contentView.trailingAnchor, constant: -15).isActive = true
            profileMessage.heightAnchor.constraint(equalToConstant: 37).isActive = true
            profileMessage.widthAnchor.constraint(equalToConstant: 35).isActive = true
            profileMessage.circle()
            profileMessage.clipsToBounds = true
            profileMessage.backgroundColor = .lightGray
            profileMessage.image = UIImage(systemName: "person")
            profileMessage.tintColor = .white
            profileMessage.contentMode = .scaleAspectFit
            
            let pictureImage = dataProfile["image_id"]
            if (pictureImage != "" && pictureImage != nil) {
                profileMessage.setImage(name: pictureImage!)
                profileMessage.contentMode = .scaleAspectFill
            }
            
            containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            containerMessage.leadingAnchor.constraint(greaterThanOrEqualTo: cellMessage.contentView.leadingAnchor, constant: 60).isActive = true
            containerMessage.trailingAnchor.constraint(equalTo: profileMessage.leadingAnchor, constant: -5).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            
            if (dataMessages[indexPath.row]["lock"] as? String == "0" || (dataMessages[indexPath.row]["lock"] as? String ?? "").isEmpty) {
                cellMessage.contentView.addSubview(statusMessage)
                statusMessage.translatesAutoresizingMaskIntoConstraints = false
                statusMessage.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                statusMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
                statusMessage.widthAnchor.constraint(equalToConstant: 15).isActive = true
                statusMessage.heightAnchor.constraint(equalToConstant: 15).isActive = true
                var status = getRealStatus(messageId: dataMessages[indexPath.row]["message_id"]  as? String ?? "")
                if status == "-1" {
                    status = dataMessages[indexPath.row]["status"]! as? String ?? ""
                }
                if status == "0" {
                    statusMessage.image = UIImage(systemName: "xmark.circle")!.withTintColor(UIColor.red, renderingMode: .alwaysOriginal)
                }
                // Still waiting for the server to answer with "2": the message is written here
                // but nowhere else yet, and the clock says so.
                else if status == "1" {
                    statusMessage.image = UIImage(systemName: "clock.arrow.circlepath")!.withTintColor(UIColor.lightGray, renderingMode: .alwaysOriginal)

                }
                else if status == "2" {
                    statusMessage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else if (status == "3") {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else if (status == "8") {
                    statusMessage.image = UIImage(named: "message_status_ack", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                } else {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                }
            }
            
            let nameSender = UILabel()
            containerMessage.addSubview(nameSender)
            nameSender.translatesAutoresizingMaskIntoConstraints = false
            nameSender.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
            nameSender.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            nameSender.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            nameSender.font = UIFont.systemFont(ofSize: 12 + offset()).bold
            nameSender.text = dataProfile["name"]
            nameSender.textAlignment = .right
            if (dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "") {
                containerMessage.backgroundColor = .clear
                nameSender.textColor = UIApplication.shared.visibleViewController?.traitCollection.userInterfaceStyle == .dark ? .lightGray : .mainColor
            } else {
                containerMessage.backgroundColor = .blueBubbleColor
                nameSender.textColor = UIApplication.shared.visibleViewController?.traitCollection.userInterfaceStyle == .dark ? .lightGray : .mainColor
            }
            
        } else {
            if copySession || forwardSession || deleteSession || summarizeSession {
                profileMessage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 50).isActive = true
            } else {
                profileMessage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 15).isActive = true
            }
            profileMessage.heightAnchor.constraint(equalToConstant: 37).isActive = true
            profileMessage.widthAnchor.constraint(equalToConstant: 35).isActive = true
            profileMessage.circle()
            profileMessage.clipsToBounds = true
            profileMessage.backgroundColor = .lightGray
            profileMessage.image = UIImage(systemName: "person")
            profileMessage.tintColor = .white
            profileMessage.contentMode = .scaleAspectFit
            
            let pictureImage = dataProfile["image_id"]
            if dataMessages[indexPath.row]["f_pin"] as? String == "-999" {
                if !Utils.getIconDock().isEmpty {
                    let dataImage = try? Data(contentsOf: URL(string: Utils.getUrlDock()!)!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                    if dataImage != nil {
                        profileMessage.image = UIImage(data: dataImage!)
                    }
                } else {
                    profileMessage.image = UIImage(named: "pb_button", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                }
                profileMessage.contentMode = .scaleAspectFill
            }
            else if dataMessages[indexPath.row]["f_pin"] as? String == "-997" {
                if let urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") {
                    profileMessage.sd_setImage(with: urlGif) { (image, error, cacheType, imageURL) in
                        if error == nil {
                            profileMessage.animationImages = image?.images
                            profileMessage.animationDuration = image?.duration ?? 0.0
                            profileMessage.animationRepeatCount = 0
                            profileMessage.startAnimating()
                        }
                    }
                } else if let urlGif = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") {
                    profileMessage.sd_setImage(with: urlGif) { (image, error, cacheType, imageURL) in
                        if error == nil {
                            profileMessage.animationImages = image?.images
                            profileMessage.animationDuration = image?.duration ?? 0.0
                            profileMessage.animationRepeatCount = 0
                            profileMessage.startAnimating()
                        }
                    }
                }
            }
            else if (pictureImage != "" && pictureImage != nil) {
                profileMessage.setImage(name: pictureImage!)
                profileMessage.contentMode = .scaleAspectFill
            }
            
            if markerCounter != nil && dataMessages[indexPath.row]["message_id"] as? String == markerCounter {
                profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 35).isActive = true
                containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 35).isActive = true
                
                let newMessagesView = UIView()
                cellMessage.contentView.addSubview(newMessagesView)
                newMessagesView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newMessagesView.topAnchor.constraint(equalTo: newMessagesView.topAnchor),
                    newMessagesView.bottomAnchor.constraint(equalTo: containerMessage.topAnchor),
                    newMessagesView.centerXAnchor.constraint(equalTo: cellMessage.contentView.centerXAnchor),
                    newMessagesView.heightAnchor.constraint(equalToConstant: 30),
                    newMessagesView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
                ])
                newMessagesView.backgroundColor = .greenColor
                newMessagesView.layer.cornerRadius = 15.0
                newMessagesView.clipsToBounds = true
                
                let labelNewMessages = UILabel()
                newMessagesView.addSubview(labelNewMessages)
                labelNewMessages.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    labelNewMessages.centerYAnchor.constraint(equalTo: newMessagesView.centerYAnchor),
                    labelNewMessages.centerXAnchor.constraint(equalTo: newMessagesView.centerXAnchor),
                    labelNewMessages.leadingAnchor.constraint(equalTo: newMessagesView.leadingAnchor, constant: 10),
                    labelNewMessages.trailingAnchor.constraint(equalTo: newMessagesView.trailingAnchor, constant: -10),
                ])
                labelNewMessages.textAlignment = .center
                labelNewMessages.textColor = .secondaryColor
                labelNewMessages.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
                labelNewMessages.text = "Unread Messages".localized()
                
            } else {
                profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
                containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            }
            
            containerMessage.leadingAnchor.constraint(equalTo: profileMessage.trailingAnchor, constant: 5).isActive = true
            containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cellMessage.contentView.trailingAnchor, constant: -60).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "" && dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1" && dataMessages[indexPath.row]["lock"] as? String != "2" {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .whiteBubbleColor
            }
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
            
            let nameSender = UILabel()
            containerMessage.addSubview(nameSender)
            nameSender.translatesAutoresizingMaskIntoConstraints = false
            nameSender.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
            nameSender.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            nameSender.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            nameSender.font = UIFont.systemFont(ofSize: 12 + offset()).bold
            if dataMessages[indexPath.row]["f_pin"] as? String == "-999" {
                nameSender.text = "Bot"
            }
            else if dataMessages[indexPath.row]["f_pin"] as? String == "-997" {
                nameSender.text = Utils.getGPTBotName()
            }
            else {
                nameSender.text = dataProfile["name"]
            }
            nameSender.textAlignment = .left
            nameSender.textColor = .mainColor
        }
        
        if ((dataMessages[indexPath.row]["read_receipts"] as? String) == "8" ||
            (dataMessages[indexPath.row]["credential"] as? String) == "1" ||
            !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty) &&
            (dataMessages[indexPath.row]["lock"] as? String) != "2" &&
            (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            let containerBottomConstraint = containerMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -40)
            containerBottomConstraint.priority = .defaultHigh
            containerBottomConstraint.isActive = true
        } else {
            let containerBottomConstraint = containerMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -5)
            containerBottomConstraint.priority = .defaultHigh
            containerBottomConstraint.isActive = true
        }
        
        let imageStared = UIImageView()
        let imageAckView = UIImageView()
        let imageCredentialView = UIImageView()
        let imagePinView = UIImageView()
        // Fix: the guard here is meant to keep the star off a message that is locked or opens
        // only once. It used to read `["lock"] == nil`, which in a dictionary of optional values
        // is only true when the key is absent - a key that is present carrying a database NULL is
        // `.some(nil)`, so it fell through to the string test, came out as "" rather than "0", and
        // the star was withheld from a message that was never locked at all. Absent and NULL both
        // mean unlocked, so both are read that way now. The star drawn inside a collage tile never
        // had this test, which is why a starred picture in a group could show there and nowhere
        // else.
        let lockFlag = dataMessages[indexPath.row]["lock"] as? String ?? "0"
        if dataMessages[indexPath.row]["is_stared"] as? String == "1" && (lockFlag.isEmpty || lockFlag == "0") {
            cellMessage.contentView.addSubview(imageStared)
            imageStared.translatesAutoresizingMaskIntoConstraints = false
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageStared.bottomAnchor.constraint(equalTo: statusMessage.topAnchor).isActive = true
                imageStared.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            } else {
                imageStared.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                imageStared.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
            }
            imageStared.widthAnchor.constraint(equalToConstant: 15).isActive = true
            imageStared.heightAnchor.constraint(equalToConstant: 15).isActive = true
            imageStared.image = UIImage(systemName: "star.fill")
            imageStared.backgroundColor = .clear
            imageStared.tintColor = .systemYellow
        }
        
        if dataMessages[indexPath.row][TypeDataMessage.is_pinned] as? String != nil && dataMessages[indexPath.row][TypeDataMessage.is_pinned] as? String != "0" {
            cellMessage.contentView.addSubview(imagePinView)
            imagePinView.translatesAutoresizingMaskIntoConstraints = false
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                if imageStared.isDescendant(of: cellMessage.contentView){
                    imagePinView.bottomAnchor.constraint(equalTo: imageStared.topAnchor).isActive = true
                } else {
                    imagePinView.bottomAnchor.constraint(equalTo: statusMessage.topAnchor).isActive = true
                }
                imagePinView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            } else {
                if imageStared.isDescendant(of: cellMessage.contentView){
                    imagePinView.bottomAnchor.constraint(equalTo: imageStared.topAnchor).isActive = true
                } else {
                    imagePinView.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                }
                imagePinView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
            }
            imagePinView.widthAnchor.constraint(equalToConstant: 15).isActive = true
            imagePinView.heightAnchor.constraint(equalToConstant: 15).isActive = true
            imagePinView.image = UIImage(systemName: "pin.fill")
            imagePinView.backgroundColor = .clear
            imagePinView.tintColor = .lightGray
        }
        
        if dataMessages[indexPath.row]["read_receipts"] as? String == "8" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            var imageAck = UIImage(named: "ack_icon_gray", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            cellMessage.contentView.addSubview(imageAckView)
            imageAckView.translatesAutoresizingMaskIntoConstraints = false
            imageAckView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageAckView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                let status = getRealStatus(messageId: dataMessages[indexPath.row]["message_id"]  as? String ?? "")
                if status == "8" {
                    imageAck = UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                }
                imageAckView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageAckView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            } else {
                let status = dataMessages[indexPath.row]["status"] as? String
                if status == "8" {
                    imageAck = UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                }
                imageAckView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageAckView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
                let tap = ObjectGesture(target: self, action: #selector(tapAck(_:)))
                tap.indexPath = indexPath
                imageAckView.addGestureRecognizer(tap)
                imageAckView.isUserInteractionEnabled = true
            }
            imageAckView.image = imageAck
        }
        
        if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            let imageCredential = UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            imageCredentialView.image = imageCredential
            cellMessage.contentView.addSubview(imageCredentialView)
            imageCredentialView.translatesAutoresizingMaskIntoConstraints = false
            imageCredentialView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageCredentialView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageCredentialView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageCredentialView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            } else {
                imageCredentialView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
                imageCredentialView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
            }
        }
        
        if !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            let imageSpecFileView = UIImageView()
            let imageSpecFile = UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            imageSpecFileView.image = imageSpecFile
            cellMessage.contentView.addSubview(imageSpecFileView)
            imageSpecFileView.translatesAutoresizingMaskIntoConstraints = false
            imageSpecFileView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageSpecFileView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            imageSpecFileView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                if imageAckView.isDescendant(of: cellMessage.contentView) {
                    imageSpecFileView.leadingAnchor.constraint(equalTo: imageAckView.trailingAnchor, constant: 5).isActive = true
                } else if imageCredentialView.isDescendant(of: cellMessage.contentView) {
                    imageSpecFileView.leadingAnchor.constraint(equalTo: imageCredentialView.trailingAnchor, constant: 5).isActive = true
                } else {
                    imageSpecFileView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
                }
            } else {
                if imageAckView.isDescendant(of: cellMessage.contentView) {
                    imageSpecFileView.trailingAnchor.constraint(equalTo: imageAckView.leadingAnchor, constant: -5).isActive = true
                } else if imageCredentialView.isDescendant(of: cellMessage.contentView) {
                    imageSpecFileView.trailingAnchor.constraint(equalTo: imageCredentialView.leadingAnchor, constant: -5).isActive = true
                } else {
                    imageSpecFileView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
                }
            }
        }
        
        if dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "27" || dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "26" {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 85).isActive = true
            let imageLS = UIImageView()
            containerMessage.addSubview(imageLS)
            imageLS.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageLS.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15.0),
                imageLS.trailingAnchor.constraint(equalTo: messageText.leadingAnchor, constant: -10.0),
                imageLS.centerYAnchor.constraint(equalTo: containerMessage.centerYAnchor),
                imageLS.heightAnchor.constraint(equalToConstant: 60.0)
            ])
            if dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "26" {
                imageLS.image = UIImage(named: "pb_seminar_wpr", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            } else if dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "27" {
                imageLS.image = UIImage(named: "pb_live_tv", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            }
        } else if !audioChat.isEmpty {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 60).isActive = true
        } else {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
        }
        let bottomConstraint = messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -15)
        bottomConstraint.priority = .defaultHigh
        bottomConstraint.isActive = true
        messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
        
        messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        messageText.font = .systemFont(ofSize: 12 + offset())
        
        let originalMessageText = textChat
        if (dataMessages[indexPath.row]["lock"] != nil && (dataMessages[indexPath.row]["lock"])! as? String == "1") {
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                textChat = "🚫 _"+"You were deleted this message".localized()+"_"
            } else {
                textChat = "🚫 _"+"This message was deleted".localized()+"_"
            }
        }
        
        if dataMessages[indexPath.row]["lock"] as? String == "2" {
            textChat = "🚫 _"+"Message has expired".localized()+"_"
        }
        
        if !audioChat.isEmpty {
            textChat = textChat.components(separatedBy: "|")[0]
        }
        
        let imageSticker = UIImageView()
        
        if let attachmentFlag = dataMessages[indexPath.row]["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" || attachmentFlag == "26" { // live streaming
                if let textData = textChat.data(using: .utf8),
                   let json = (try? JSONSerialization.jsonObject(with: textData, options: [])) as? [String: Any] {
                    Database.shared.database?.inTransaction({ fmdb, rollback in
                        let title = json["title"]  as? String ?? ""
                        let description = json["description"]  as? String ?? ""
                        let start = json["time"] as? Int64 ?? 0
                        let by = json["by"]  as? String ?? ""
                        let textLS = "Live Streaming".localized()
                        var type = "*\(textLS)*"
                        if attachmentFlag == "26" {
                            let textSeminar = "Seminar".localized()
                            type = "*\(textSeminar)*"
                        }
                        if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name from BUDDY where f_pin = '\(by)'"), c.next() {
                            let name = c.string(forColumnIndex: 0)!
                            messageText.attributedText = "\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm")) \nBroadcaster: \(name)".richText()
                            c.close()
                        } else {
                            messageText.attributedText = ("\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm")) \nBroadcaster: " + "Unknown".localized()).richText()
                        }
                    })
                }
            }
            else if attachmentFlag == "11" && dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1" && dataMessages[indexPath.row]["lock"] as? String != "2" {
                messageText.text = ""
                topMarginText.constant = topMarginText.constant + 100
                containerMessage.addSubview(imageSticker)
                imageSticker.translatesAutoresizingMaskIntoConstraints = false
                let data = queryMessageReply(message_id: reffChat)
                if reffChat.isEmpty || data.count == 0 {
                    imageSticker.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
                    imageSticker.widthAnchor.constraint(equalToConstant: 80).isActive = true
                } else {
                    imageSticker.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
                }
                imageSticker.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                imageSticker.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                imageSticker.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                var imageStickerBundle = UIImage(named: (textChat.component(1, separatedBy: "/")), in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                if imageStickerBundle == nil {
                    imageStickerBundle = UIImage(named: (textChat.component(1, separatedBy: "/")), in: Bundle.resourcesMediaBundle(for: Nexilis.self), with: nil)
                }
                imageSticker.image = imageStickerBundle //resourcesMediaBundle
                imageSticker.contentMode = .scaleAspectFit
            }
            else {
                messageText.attributedText = textChat.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
                modifyText(at: indexPath)
            }
        } else {
            messageText.attributedText = textChat.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
            modifyText(at: indexPath)
        }
        
        func modifyText(at indexPath: IndexPath) {
            guard !textChat.isEmpty else { return }
            guard indexPath.row >= 0, indexPath.row < dataMessages.count else {
                print("⚠️ modifyText: Invalid index \(indexPath.row), total: \(dataMessages.count)")
                return
            }

            var text = textChat
            let messageData = dataMessages[indexPath.row]

            // Remove segment after separator
            if let separatorRange = text.range(of: "■") {
                text = String(text[..<separatorRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Optional pipe-split logic
            if !fileChat.isEmpty {
                let lock = messageData["lock"] as? String ?? ""
                if lock != "1", lock != "2" {
                    let parts = text.components(separatedBy: "|")
                    if parts.count > 1 { text = parts[1] }
                }
            }

            // Must be mutable!
            let finalAttributed = NSMutableAttributedString(attributedString: text.richText(group_id: self.dataGroup["group_id"]  as? String ?? ""))

            let fullString = finalAttributed.string
            let fullLength = (fullString as NSString).length

            // Fix: shared with the formatting rules in richText() (String.urlRanges), so the
            // text that gets made tappable is exactly the text those rules were told to leave
            // alone - and so trailing sentence punctuation stays out of the opened URL.
            for range in String.urlRanges(in: fullString) {
                // Skip invalid ranges safely
                if range.location == NSNotFound ||
                   range.location + range.length > fullLength ||
                   range.length == 0 {
                    continue
                }

                let linkText = (fullString as NSString).substring(with: range)

                finalAttributed.addAttributes([
                    .link: linkText,
                    .foregroundColor: UIColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: range)
            }

            messageText.attributedText = finalAttributed
            messageText.delegate = self
        }
        
        if !copySession && !forwardSession && !deleteSession && !summarizeSession && !isHistoryCC && !removed {
            let interaction = UIContextMenuInteraction(delegate: self)
            containerMessage.addInteraction(interaction)
            containerMessage.isUserInteractionEnabled = true
        }
        
        if isSearching && textSearch.count > 1 && dataMessages[indexPath.row][TypeDataMessage.attachment_flag] as? String != "11"  && !(dataMessages[indexPath.row][TypeDataMessage.message_id] as? String ?? "").contains("NTFPIN_") {
            messageText.attributedText = textChat.richText(isSearching: true, textSearch: textSearch, group_id: self.dataGroup["group_id"]  as? String ?? "")
        }
        
        let stringDate = (dataMessages[indexPath.row]["server_date"]  as? String ?? "")
        if !stringDate.isEmpty {
            if (dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2"  && dataMessages[indexPath.row]["lock"] as? String != "1" {
                if dataTimer! >= 10 {
                    timeMessage.text = "00:\(dataTimer!)"
                } else {
                    timeMessage.text = "00:0\(dataTimer!)"
                }
                timeMessage.textColor = .systemRed
            } else {
                let date = Date(milliseconds: Int64(stringDate) ?? 100)
                timeMessage.text = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                timeMessage.textColor = .lightGray
            }
            timeMessage.font = UIFont.systemFont(ofSize: 10 + offset(), weight: .medium)
            if dataMessages[indexPath.row][TypeDataMessage.last_edit] != nil && dataMessages[indexPath.row][TypeDataMessage.last_edit] as? Int64 ?? 0 != 0 {
                timeMessage.text = (timeMessage.text ?? "") + "\n" + "Edited".localized()
                if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                    timeMessage.textAlignment = .right
                }
            }
        }
        
        let imageThumb = UIImageView()
        let containerViewFile = UIView()
        let imageGif = SDAnimatedImageView()
        
        if !audioChat.isEmpty {
            messageText.isHidden = true
            var padTop: CGFloat = 32
            if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as? Int ?? 0 != 0 {
                padTop = 52
            }
            
            let contAudio = UIView()
            contAudio.backgroundColor = .clear
            containerMessage.addSubview(contAudio)
            contAudio.anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, right: containerMessage.rightAnchor, paddingTop: padTop, paddingLeft: 15, paddingBottom: 15, paddingRight: 15)
            
            let imageAudio = UIImageView()
            imageAudio.image = UIImage(systemName: "music.note", withConfiguration: UIImage.SymbolConfiguration(pointSize: 35))
            contAudio.addSubview(imageAudio)
            imageAudio.anchor(top: contAudio.topAnchor, left: contAudio.leftAnchor, bottom: contAudio.bottomAnchor, centerY: contAudio.centerYAnchor)
            imageAudio.tintColor = .mainColor
            
            let playButtonAudio = UIButton(type: .system)
            playButtonAudio.setImage(UIImage(systemName: "play.fill"), for: .normal)
            playButtonAudio.tintColor = .gray
            contAudio.addSubview(playButtonAudio)
            playButtonAudio.anchor(left: contAudio.leftAnchor, paddingLeft: 45, centerY: contAudio.centerYAnchor, width: 20, height: 20)
            
            let progressSliderAudio = UISlider()
            progressSliderAudio.minimumValue = 0
            progressSliderAudio.maximumValue = 1
            let thumbImage = UIImage(systemName: "circle.fill")?.withTintColor(UIColor.mainColor)
                .resize(target: CGSize(width: 15, height: 15))
            progressSliderAudio.setThumbImage(thumbImage, for: .normal)
            contAudio.addSubview(progressSliderAudio)
            progressSliderAudio.anchor(left: playButtonAudio.rightAnchor, right: contAudio.rightAnchor, paddingLeft: 10, centerY: contAudio.centerYAnchor, height: 15)
            
            let timeLabelAudio = UILabel()
            timeLabelAudio.text = "0:00"
            timeLabelAudio.font = .systemFont(ofSize: 10 + offset())
            timeLabelAudio.textColor = .gray
            contAudio.addSubview(timeLabelAudio)
            timeLabelAudio.anchor(top: playButtonAudio.bottomAnchor, left: playButtonAudio.rightAnchor, paddingLeft: 10, width: 100, height: 12)
            
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let audioURL = URL(fileURLWithPath: dirPath).appendingPathComponent(audioChat)
                var url = audioURL
                if !FileManager.default.fileExists(atPath: audioURL.path) && !FileEncryption.shared.isSecureExists(filename: audioChat) {
                    let activityIndicator = UIActivityIndicatorView(style: .medium)
                    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
                    activityIndicator.startAnimating()
                    playButtonAudio.setImage(nil, for: .normal)
                    playButtonAudio.addSubview(activityIndicator)
                    NSLayoutConstraint.activate([
                        activityIndicator.centerXAnchor.constraint(equalTo: playButtonAudio.centerXAnchor),
                        activityIndicator.centerYAnchor.constraint(equalTo: playButtonAudio.centerYAnchor)
                    ])
                    // Fix: cellForRow runs again on every scroll pass, and each pass used to hand the
                    // same file another completion to call - dozens of them by the time a transfer
                    // finished, every one of them reloading the same row. The transfer that is already
                    // running keeps the row up to date by itself now (see onDownloadChat).
                    if !Download.isDownloading(forKey: audioChat) {
                        Download().startHTTP(forKey: audioChat) { [weak self] (name, progress) in
                            guard progress == 100 else {
                                return
                            }
                            // Fix: was reloadRows(at: [indexPath]) against the table captured while the
                            // cell was being built - by the time a download finishes, that index path may
                            // belong to another message, or to no row at all.
                            DispatchQueue.main.async {
                                self?.reloadMessageRow(withFileNamed: name)
                            }
                        }
                    }
                } else {
                    if !FileManager.default.fileExists(atPath: audioURL.path) {
                        do {
                            if var audioData = try FileEncryption.shared.readSecure(filename: audioChat) {
                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: audioData)
                                if dataDecrypt != nil {
                                    audioData = dataDecrypt!
                                }
                                let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                                let tempPath = cachesDirectory.appendingPathComponent(audioChat.contains(".aac") ? "\(audioChat.components(separatedBy: ".")[0]).m4a" : audioChat)
                                try audioData.write(to: tempPath)
                                url = tempPath
                            }
                        } catch {
                            
                        }
                    }
                    if audioPlayers[indexPath] == nil {
                        do {
                            let audioPlayer = try AVAudioPlayer(contentsOf: url)
                            audioPlayers[indexPath] = audioPlayer
                            audioPlayer.delegate = self
                            progressSliderAudio.maximumValue = Float(audioPlayer.duration)
                            timeLabelAudio.text = formatTime(audioPlayer.duration)
                        } catch {
                            print("Error loading audio: \(error)")
                        }
                    }
                    let audioPlayer = audioPlayers[indexPath]
                    if playingIndexPath == indexPath, let player = audioPlayer, player.isPlaying {
                        playButtonAudio.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                    } else {
                        playButtonAudio.setImage(UIImage(systemName: "play.fill"), for: .normal)
                    }

                    // Play/Pause Button Action
                    playButtonAudio.addAction(UIAction { _ in
                        self.playPauseAudio(indexPath: indexPath, playButton: playButtonAudio, progressSlider: progressSliderAudio, timeLabel: timeLabelAudio)
                    }, for: .touchUpInside)
                    
                    progressSliderAudio.addAction(UIAction { _ in
                        self.sliderChanged(indexPath: indexPath, progressSlider: progressSliderAudio, timeLabel: timeLabelAudio)
                    }, for: .valueChanged)
                }
            }
        }
        
        if (!thumbChat.isEmpty && dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
            if let listImages = groupImages[messageIdChat] {
                timeMessage.isHidden = true
                statusMessage.isHidden = true
                imageStared.isHidden = true
                topMarginText.constant = topMarginText.constant + 220
                var constTop = 35.0
                if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as? Int ?? 0 != 0 {
                    topMarginText.constant = topMarginText.constant + 20
                    constTop = 55.0
                }
                // WhatsApp's arrangement, and the reason it changes with the count: two
                // images are two tall halves side by side, three are one tall half beside two
                // stacked quarters, four or more are a square of quarters. The whole collage
                // occupies the same box either way, so nothing else about the bubble moves.
                let tileCount = min(listImages.count, 4)
                let listImageThumb: [UIImageView] = (0..<tileCount).map { _ in UIImageView() }
                for i in 0..<tileCount {
                    containerMessage.addSubview(listImageThumb[i])
                    listImageThumb[i].layer.cornerRadius = 5.0
                    listImageThumb[i].clipsToBounds = true
                    listImageThumb[i].contentMode = .scaleAspectFill
                    let widthHeightImage: CGFloat = 120
                    // The collage is a square of the same tiles however many there are:
                    // 120 + 5 + 120 on a side. Sizes are written out rather than left to the
                    // edges of the bubble, because an image view with no height of its own takes
                    // its height from the picture inside it - a loaded thumbnail was pushing the
                    // whole bubble open to hundreds of points tall.
                    let collageSide = widthHeightImage * 2 + 5
                    listImageThumb[i].setContentHuggingPriority(.defaultLow, for: .vertical)
                    listImageThumb[i].setContentHuggingPriority(.defaultLow, for: .horizontal)
                    listImageThumb[i].setContentCompressionResistancePriority(.defaultLow, for: .vertical)
                    listImageThumb[i].setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                    switch (tileCount, i) {
                        case (2, 0), (3, 0):
                            // The tall half down the left: full height of the square, half its
                            // width. Pinned to the bottom of the bubble as well as the top - the
                            // same way the four-image arrangement has always been - so the bubble
                            // is exactly as tall as the collage rather than as tall as whatever
                            // margin happens to be set for the text below it.
                            listImageThumb[i].anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, paddingTop: constTop, paddingLeft: 5, paddingBottom: 5, width: widthHeightImage, height: collageSide)
                        case (2, 1):
                            // The other half, level with it. This one also reaches the right edge
                            // of the bubble: the bubble is only as wide as what is pinned to both
                            // of its sides, and without that it stayed narrow enough to cut this
                            // tile off entirely - the collage looked like a single tall sliver.
                            listImageThumb[i].anchor(top: listImageThumb[0].topAnchor, left: listImageThumb[0].rightAnchor, right: containerMessage.rightAnchor, paddingLeft: 5, paddingRight: 5, width: widthHeightImage, height: collageSide)
                        case (3, 1):
                            // Reaches the right edge for the same reason; the quarter below it
                            // then only needs to line up under this one.
                            listImageThumb[i].anchor(top: listImageThumb[0].topAnchor, left: listImageThumb[0].rightAnchor, right: containerMessage.rightAnchor, paddingLeft: 5, paddingRight: 5, width: widthHeightImage, height: widthHeightImage)
                        case (3, 2):
                            listImageThumb[i].anchor(top: listImageThumb[1].bottomAnchor, left: listImageThumb[0].rightAnchor, paddingTop: 5, paddingLeft: 5, width: widthHeightImage, height: widthHeightImage)
                        case (_, 0):
                            listImageThumb[i].anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, paddingTop: constTop, paddingLeft: 5, width: widthHeightImage, height: widthHeightImage)
                        case (_, 1):
                            listImageThumb[i].anchor(top: containerMessage.topAnchor, left: listImageThumb[0].rightAnchor, right: containerMessage.rightAnchor, paddingTop: constTop, paddingLeft: 5, paddingRight: 5, width: widthHeightImage, height: widthHeightImage)
                        case (_, 2):
                            listImageThumb[i].anchor(left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, paddingLeft: 5, paddingBottom: 5, width: widthHeightImage, height: widthHeightImage)
                        default:
                            listImageThumb[i].anchor(left: listImageThumb[2].rightAnchor, bottom: containerMessage.bottomAnchor, right: containerMessage.rightAnchor, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, width: widthHeightImage, height: widthHeightImage)
                    }
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(listImages[i].thumbId)
                        if FileManager.default.fileExists(atPath: thumbURL.path) {
                            DispatchQueue.main.async {
                                let image : UIImage? =  {
                                    if let img = Nexilis.imageCache.object(forKey: listImages[i].thumbId as NSString) {
                                        return img
                                    }
                                    else if let img = UIImage(contentsOfFile: thumbURL.path)?.resize(target: CGSize(width: 500, height: 500)) {
                                            Nexilis.imageCache.setObject(img, forKey: listImages[i].thumbId as NSString)
                                            return img
                                    }
                                    return nil
                                }()
                                listImageThumb[i].image = image
                            }
                        } else if FileEncryption.shared.isSecureExists(filename: listImages[i].thumbId) {
                            do {
                                if var data = try FileEncryption.shared.readSecure(filename: listImages[i].thumbId) {
                                    let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                    if dataDecrypt != nil {
                                        data = dataDecrypt!
                                    }
                                    DispatchQueue.main.async {
                                        let image : UIImage? =  {
                                            if let img = Nexilis.imageCache.object(forKey: listImages[i].thumbId as NSString) {
                                                return img
                                            }
                                            else if let img = UIImage(data: data)?.resize(target: CGSize(width: 500, height: 500)) {
                                                Nexilis.imageCache.setObject(img, forKey: listImages[i].thumbId as NSString)
                                                return img
                                            }
                                            return nil
                                        }()
                                        listImageThumb[i].image = image
                                    }
                                }
                            } catch {
                                
                            }
                        } else {
                            // Fix: cellForRow runs again on every scroll pass, and each pass used to hand the
                            // same file another completion to call - dozens of them by the time a transfer
                            // finished, every one of them reloading the same row. The transfer that is already
                            // running keeps the row up to date by itself now (see onDownloadChat).
                            if !Download.isDownloading(forKey: listImages[i].thumbId) {
                                Download().startHTTP(forKey: listImages[i].thumbId) { [weak self] (name, progress) in
                                    guard progress == 100 else {
                                        return
                                    }
                                    // Fix: was reloadRows(at: [indexPath]) against the table captured while the
                                    // cell was being built - by the time a download finishes, that index path may
                                    // belong to another message, or to no row at all.
                                    DispatchQueue.main.async {
                                        self?.reloadMessageRow(withFileNamed: name)
                                    }
                                }
                            }
                        }
                        
                        let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(listImages[i].imageId)
                        if !FileManager.default.fileExists(atPath: imageURL.path) && !FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
                            let blurEffectView = UIVisualEffectView(effect: blurEffect)
                            blurEffectView.frame = CGRect(x: 0, y: 0, width: listImageThumb[i].frame.size.width, height: listImageThumb[i].frame.size.height)
                            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                            listImageThumb[i].addSubview(blurEffectView)
                        } else if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
                            let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
                            let blurEffectView = UIVisualEffectView(effect: blurEffect)
                            blurEffectView.frame = CGRect(x: 0, y: 0, width: imageThumb.frame.size.width, height: imageThumb.frame.size.height)
                            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                            listImageThumb[i].addSubview(blurEffectView)
                        }
                        
                    }
                    let containerTimeStatus = UIView()
                    listImageThumb[i].addSubview(containerTimeStatus)
                    containerTimeStatus.anchor(bottom: listImageThumb[i].bottomAnchor, right: listImageThumb[i].rightAnchor, height: 15)
                    let widthcontainerTimeStatus = containerTimeStatus.widthAnchor.constraint(equalToConstant: 50)
                    widthcontainerTimeStatus.isActive = true
                    containerTimeStatus.layer.cornerRadius = 5.0
                    containerTimeStatus.layer.masksToBounds = true
                    containerTimeStatus.backgroundColor = .black.withAlphaComponent(0.15)
                    
                    let timeInImage = UILabel()
                    containerTimeStatus.addSubview(timeInImage)
                    let date = Date(milliseconds: Int64(listImages[i].time) ?? 100)
                    timeInImage.text = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                    timeInImage.textColor = .white
                    timeInImage.font = UIFont.systemFont(ofSize: 10 + offset(), weight: .medium)
                    
                    if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                        let statusInImage = UIImageView()
                        containerTimeStatus.addSubview(statusInImage)
                        statusInImage.anchor(right: containerTimeStatus.rightAnchor, centerY: containerTimeStatus.centerYAnchor, width: 15, height: 15)
                        if listImages[i].status == "0" {
                            // Fix: this used to write to statusMessage - the parent row's own
                            // icon - so a failed image inside a collage marked the wrong thing.
                            statusInImage.image = UIImage(systemName: "xmark.circle")!.withTintColor(UIColor.red, renderingMode: .alwaysOriginal)
                        }
                        else if listImages[i].status == "1" {
                            statusInImage.image = UIImage(systemName: "clock.arrow.circlepath")!.withTintColor(UIColor.white, renderingMode: .alwaysOriginal)

                        }
                        else if listImages[i].status == "2"  {
                            statusInImage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.white)
                        } else if listImages[i].status == "3" {
                            statusInImage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.white)
                        } else {
                            statusInImage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                        }
                        timeInImage.anchor(right: statusInImage.leftAnchor, centerY: containerTimeStatus.centerYAnchor, height: 15)
                    } else {
                        timeInImage.anchor(right: containerTimeStatus.rightAnchor, paddingRight: 5, centerY: containerTimeStatus.centerYAnchor, height: 15)
                        widthcontainerTimeStatus.constant = widthcontainerTimeStatus.constant - 10
                    }
                    
                    if listImages[i].dataMessage["is_stared"] as? String == "1" {
                        let iconStar = UIImageView()
                        containerTimeStatus.addSubview(iconStar)
                        iconStar.anchor(right: timeInImage.leftAnchor, paddingRight: 2, centerY: containerTimeStatus.centerYAnchor, width: 15, height: 15)
                        widthcontainerTimeStatus.constant = widthcontainerTimeStatus.constant + 15
                        iconStar.image = UIImage(systemName: "star.fill")
                        iconStar.tintColor = .white
                    }
                    
                    if !copySession && !forwardSession && !deleteSession && !summarizeSession {
                        let objectTap = ObjectGesture(target: self, action: #selector(imageGroupingTapped(_:)))
                        listImageThumb[i].isUserInteractionEnabled = true
                        listImageThumb[i].addGestureRecognizer(objectTap)
                        objectTap.indexImageTapped = i
                        objectTap.listImageFromGrouping = listImages
                        objectTap.isInitiator = dataMessages[indexPath.row]["f_pin"] as? String == idMe
                    }
                }
                if listImages.count > 4, listImageThumb.count == 4 {
                    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
                    let blurEffectView = UIVisualEffectView(effect: blurEffect)
                    blurEffectView.frame = CGRect(x: 0, y: 0, width: listImageThumb[3].frame.size.width, height: listImageThumb[3].frame.size.height)
                    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    listImageThumb[3].addSubview(blurEffectView)
                    
                    let countRestImages = UILabel()
                    listImageThumb[3].addSubview(countRestImages)
                    countRestImages.anchor(centerX: listImageThumb[3].centerXAnchor, centerY: listImageThumb[3].centerYAnchor)
                    countRestImages.font = UIFont.systemFont(ofSize: 30, weight: .medium)
                    countRestImages.text = "+\(listImages.count - 3)"
                    countRestImages.textColor = .white
                }
            } else {
                // One measurement, not two: the width and the height come from the same look
                // at the file.
                let thumbSize = imageBubbleSize(messageId: messageIdChat, thumb: thumbChat)
                let getHeightImage: CGFloat = thumbSize.height
                let getWidthImage: CGFloat = thumbSize.width
                topMarginText.constant = topMarginText.constant + (getHeightImage < 40 ? 40 : getHeightImage)
                
                containerMessage.addSubview(imageThumb)
                imageThumb.translatesAutoresizingMaskIntoConstraints = false
                imageThumb.frame = CGRect(x: 0, y: 0, width: getWidthImage, height: getHeightImage)
                let data = queryMessageReply(message_id: reffChat)
                if (reffChat.isEmpty || data.count == 0) && (dataMessages[indexPath.row][TypeDataMessage.is_forwarded] == nil || dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as? Int ?? 0 == 0) {
                    imageThumb.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 37).isActive = true
                }
                imageThumb.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                imageThumb.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                imageThumb.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                let imgWidthConstraint = imageThumb.widthAnchor.constraint(equalToConstant: getWidthImage)
                imgWidthConstraint.priority = .defaultHigh
                imgWidthConstraint.isActive = true
                let imgMaxWidthConstraint = imageThumb.widthAnchor.constraint(lessThanOrEqualTo: containerMessage.widthAnchor, constant: -30)
                imgMaxWidthConstraint.priority = .required
                imgMaxWidthConstraint.isActive = true
                imageThumb.layer.cornerRadius = 5.0
                imageThumb.clipsToBounds = true
                imageThumb.contentMode = .scaleAspectFill
                // Fix: an image view carries the size of the picture inside it, and this one is
                // held between the top of the bubble and the text below rather than by a height
                // of its own. When a thumbnail arrived, its own size pushed against the margin
                // that sets the bubble's height - which is only defaultHigh - and the bubble
                // opened up under the reader. What is inside no longer has a say in the layout.
                imageThumb.setContentHuggingPriority(.defaultLow, for: .vertical)
                imageThumb.setContentHuggingPriority(.defaultLow, for: .horizontal)
                imageThumb.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
                imageThumb.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                
                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                if let dirPath = paths.first {
                    let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumbChat)
                    if FileManager.default.fileExists(atPath: thumbURL.path) {
                        DispatchQueue.main.async {
                            let image : UIImage? =  {
                                if let img = Nexilis.imageCache.object(forKey: thumbChat as NSString) {
                                    return img
                                }
                                else if let img = UIImage(contentsOfFile: thumbURL.path)?.resize(target: CGSize(width: 500, height: 500)) {
                                        Nexilis.imageCache.setObject(img, forKey: thumbChat as NSString)
                                        return img
                                }
                                return nil
                            }()
                            imageThumb.image = image
                        }
                    } else if FileEncryption.shared.isSecureExists(filename: thumbChat) {
                        do {
                            if var data = try FileEncryption.shared.readSecure(filename: thumbChat) {
                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                if dataDecrypt != nil {
                                    data = dataDecrypt!
                                }
                                DispatchQueue.main.async {
                                    let image : UIImage? =  {
                                        if let img = Nexilis.imageCache.object(forKey: thumbChat as NSString) {
                                            return img
                                        }
                                        else if let img = UIImage(data: data)?.resize(target: CGSize(width: 500, height: 500)) {
                                            Nexilis.imageCache.setObject(img, forKey: thumbChat as NSString)
                                            return img
                                        }
                                        return nil
                                    }()
                                    imageThumb.image = image
                                }
                            }
                        } catch {
                            
                        }
                    } else {
                        // Nothing to draw yet. A spinner in the middle of the space being held for
                        // the picture says so - the reader sees that it is coming rather than a
                        // blank grey block that looks like nothing is happening.
                        let ringIsShowing = Download.isDownloading(forKey: videoChat.isEmpty ? imageChat : videoChat)
                        let waiting = UIActivityIndicatorView(style: .medium)
                        waiting.isHidden = ringIsShowing
                        imageThumb.addSubview(waiting)
                        waiting.translatesAutoresizingMaskIntoConstraints = false
                        waiting.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                        waiting.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                        waiting.color = .white
                        waiting.startAnimating()
                        // Fix: cellForRow runs again on every scroll pass, and each pass used to hand the
                        // same file another completion to call - dozens of them by the time a transfer
                        // finished, every one of them reloading the same row. The transfer that is already
                        // running keeps the row up to date by itself now (see onDownloadChat).
                        if !Download.isDownloading(forKey: thumbChat) {
                            Download().startHTTP(forKey: thumbChat) { [weak self] (name, progress) in
                                guard progress == 100 else {
                                    return
                                }
                                // Fix: was reloadRows(at: [indexPath]) against the table captured while the
                                // cell was being built - by the time a download finishes, that index path may
                                // belong to another message, or to no row at all.
                                DispatchQueue.main.async {
                                    self?.reloadMessageRow(withFileNamed: name)
                                }
                            }
                        }
                    }
                    
                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imageChat)
                    if !FileManager.default.fileExists(atPath: imageURL.path) && !FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
                        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
                        let blurEffectView = UIVisualEffectView(effect: blurEffect)
                        blurEffectView.frame = CGRect(x: 0, y: 0, width: imageThumb.frame.size.width, height: imageThumb.frame.size.height)
                        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        imageThumb.addSubview(blurEffectView)
                        // Fix: while the image is actually downloading the progress ring stands in for
                        // this button - they are both centred on the thumbnail and would overlap.
                        // Fix: the arrow used to show whenever the full picture was not here,
                        // even while the thumbnail it stands on had not arrived either - an
                        // invitation to tap a blank square, next to a spinner saying the opposite.
                        // Nothing can be asked for before there is a picture to ask about.
                        let hasThumb = FileManager.default.fileExists(atPath: thumbURL.path) || FileEncryption.shared.isSecureExists(filename: thumbChat)
                        if hasThumb, !imageChat.isEmpty, !Download.isDownloading(forKey: imageChat) {
                            let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .default)))
                            imageThumb.addSubview(blurEffectView)
                            imageThumb.addSubview(imageDownload)
                            imageDownload.tintColor = .black.withAlphaComponent(0.3)
                            imageDownload.translatesAutoresizingMaskIntoConstraints = false
                            imageDownload.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                            imageDownload.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                        }
                    } else if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
                        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
                        let blurEffectView = UIVisualEffectView(effect: blurEffect)
                        blurEffectView.frame = CGRect(x: 0, y: 0, width: imageThumb.frame.size.width, height: imageThumb.frame.size.height)
                        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        imageThumb.addSubview(blurEffectView)
                    }
                    
                }
                
                // Fix: same for the play button - the ring replaces it for as long as the video
                // is being fetched.
                if videoChat != "" && gifChat.isEmpty && !Download.isDownloading(forKey: videoChat) {
                    let imagePlay = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default))?.imageWithInsets(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))?.withTintColor(.white))
                    imagePlay.circle()
                    imageThumb.addSubview(imagePlay)
                    imagePlay.backgroundColor = .black.withAlphaComponent(0.3)
                    imagePlay.translatesAutoresizingMaskIntoConstraints = false
                    imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                    imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                } else if !gifChat.isEmpty {
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let gifURL = URL(fileURLWithPath: dirPath).appendingPathComponent(gifChat)
                        if !FileManager.default.fileExists(atPath: gifURL.path) && !FileEncryption.shared.isSecureExists(filename: gifChat) {
                            // Fix: cellForRow runs again on every scroll pass, and each pass used to hand the
                            // same file another completion to call - dozens of them by the time a transfer
                            // finished, every one of them reloading the same row. The transfer that is already
                            // running keeps the row up to date by itself now (see onDownloadChat).
                            if !Download.isDownloading(forKey: gifChat) {
                                Download().startHTTP(forKey: gifChat) { [weak self] (name, progress) in
                                    guard progress == 100 else {
                                        return
                                    }
                                    // Fix: was reloadRows(at: [indexPath]) against the table captured while the
                                    // cell was being built - by the time a download finishes, that index path may
                                    // belong to another message, or to no row at all.
                                    DispatchQueue.main.async {
                                        self?.reloadMessageRow(withFileNamed: name)
                                    }
                                }
                            }
                        } else {
                            imageThumb.addSubview(imageGif)
                            imageGif.translatesAutoresizingMaskIntoConstraints = false
                            imageGif.anchor(top: imageThumb.topAnchor, left: imageThumb.leftAnchor, bottom: imageThumb.bottomAnchor, right: imageThumb.rightAnchor)
                            if FileManager.default.fileExists(atPath: gifURL.path) {
                                imageGif.image = SDAnimatedImage(contentsOfFile: gifURL.path)
//                                imageGif.shouldCustomLoopCount = true
//                                imageGif.animationRepeatCount = 4
                            } else if FileEncryption.shared.isSecureExists(filename: gifChat){
                                do {
                                    if var data = try FileEncryption.shared.readSecure(filename: gifChat) {
                                        let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                        if dataDecrypt != nil {
                                            data = dataDecrypt!
                                        }
                                        if let imageData = SDAnimatedImage(data: data) {
                                            imageGif.image = imageData
    //                                        imageGif.shouldCustomLoopCount = true
    //                                        imageGif.animationRepeatCount = 4
                                        }
                                    }
                                }
                                catch {
                                    print("Error reading secure file")
                                }
                            }
                        }
                    }
                }
                
                // Fix: this asked only whether `progress` had reached 100, and a row read back
                // from the database starts at 0 - so every video this phone had ever sent wore an
                // upload ring for ever. What settles it is the message's own status: still being
                // sent (1) means a transfer really is running; anything above that has arrived.
                let sendingNow = (dataMessages[indexPath.row]["status"] as? String ?? "") == "1"
                if (sendingNow && dataMessages[indexPath.row]["progress"] as? Double ?? 0.0 != 100.0 && dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                    let container = UIView()
                    imageThumb.addSubview(container)
                    container.translatesAutoresizingMaskIntoConstraints = false
                    container.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                    container.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                    container.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    container.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    container.backgroundColor = .white.withAlphaComponent(0.1)
                    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 10, y: 20), radius: 15, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                    let trackShape = CAShapeLayer()
                    trackShape.path = circlePath.cgPath
                    trackShape.fillColor = UIColor.black.withAlphaComponent(0.3).cgColor
                    trackShape.lineWidth = 3
                    trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                    container.backgroundColor = .clear
                    container.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 3
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                    container.layer.addSublayer(shapeLoading)
                    let imageupload = UIImageView(image: UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    imageupload.tintColor = .white
                    container.addSubview(imageupload)
                    imageupload.translatesAutoresizingMaskIntoConstraints = false
                    imageupload.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
                    imageupload.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
                    imageupload.widthAnchor.constraint(equalToConstant: 20).isActive = true
                    imageupload.heightAnchor.constraint(equalToConstant: 20).isActive = true
                    // Fix: the same caption as the download ring - how much of the file has gone up
                    // so far, out of how much there is (TransferBytes, filled in by Network).
                    let uploadingChat = !videoChat.isEmpty ? videoChat : imageChat
                    let uploadChip = ChatTransferRing.addSizeLabel(to: imageThumb, fileName: uploadingChat)
                    NSLayoutConstraint.activate([
                        uploadChip.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                        uploadChip.leadingAnchor.constraint(equalTo: container.trailingAnchor, constant: 6)
                    ])
                }
                
                // Fix: the download ring is drawn from here now, not built by hand in
                // contentMessageTapped - so it survives the cell being recycled, and shows up
                // by itself on a transfer that was already running when this screen opened.
                let downloadingChat = !videoChat.isEmpty ? videoChat : imageChat
                if !downloadingChat.isEmpty, Download.isDownloading(forKey: downloadingChat) {
                    ChatTransferRing.add(to: imageThumb, fileName: downloadingChat, progress: Download.progress(forKey: downloadingChat) ?? 0)
                } else if !videoChat.isEmpty, !sendingNow, isUnreachable(fileNamed: videoChat) {
                    // Here, and the file is not: tried, could not be had. An offer to fetch it
                    // rather than a ring that would never fill.
                    VideoBubbleChrome.addUnavailable(to: imageThumb, sizeText: ChatTransferRing.sizeText(forFileNamed: videoChat))
                }
                if !videoChat.isEmpty {
                    VideoBubbleChrome.addFooter(to: imageThumb, seconds: videoLength(ofMessage: dataMessages[indexPath.row]))
                }
                
                if !copySession && !forwardSession && !deleteSession && !summarizeSession {
                    let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                    let sfs = (dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String) ?? ""
                    imageThumb.isUserInteractionEnabled = true
                    imageThumb.addGestureRecognizer(objectTap)
                    objectTap.image_id = imageChat
                    objectTap.video_id = videoChat
                    objectTap.gif_id = gifChat
                    objectTap.specFile = sfs
                    objectTap.imageView = imageThumb
                    objectTap.indexPath = indexPath
                }
            }
        }
        
        if (!fileChat.isEmpty && dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
            topMarginText.constant = topMarginText.constant + 55
            
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            let arrExtFile = (originalMessageText.components(separatedBy: "|")[0]).split(separator: ".")
            let finalExtFile = arrExtFile[arrExtFile.count - 1]
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(fileChat)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    if let dataFile = try? Data(contentsOf: fileURL), textChat.isEmpty {
                        var sizeOfFile = Int(dataFile.count / 1000000)
                        if (sizeOfFile < 1) {
                            sizeOfFile = Int(dataFile.count / 1000)
                            if (finalExtFile.count > 4) {
                                messageText.text = "\(sizeOfFile) kB \u{2022} TXT"
                            }else {
                                messageText.text = "\(sizeOfFile) kB \u{2022} \(finalExtFile.uppercased())"
                            }
                        } else {
                            if (finalExtFile.count > 4) {
                                messageText.text = "\(sizeOfFile) MB \u{2022} TXT"
                            }else {
                                messageText.text = "\(sizeOfFile) MB \u{2022} \(finalExtFile.uppercased())"
                            }
                        }
                    }
                }
                else if FileEncryption.shared.isSecureExists(filename: fileChat) {
                    do {
                        if var dataFile = try FileEncryption.shared.readSecure(filename: fileChat), textChat.isEmpty {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: dataFile)
                            if dataDecrypt != nil {
                                dataFile = dataDecrypt!
                            }
                            var sizeOfFile = Int(dataFile.count / 1000000)
                            if (sizeOfFile < 1) {
                                sizeOfFile = Int(dataFile.count / 1000)
                                if (finalExtFile.count > 4) {
                                    messageText.text = "\(sizeOfFile) kB \u{2022} TXT"
                                }else {
                                    messageText.text = "\(sizeOfFile) kB \u{2022} \(finalExtFile.uppercased())"
                                }
                            } else {
                                if (finalExtFile.count > 4) {
                                    messageText.text = "\(sizeOfFile) MB \u{2022} TXT"
                                }else {
                                    messageText.text = "\(sizeOfFile) MB \u{2022} \(finalExtFile.uppercased())"
                                }
                            }
                        }
                    } catch {
                        
                    }
                }
            }
            
            containerMessage.addSubview(containerViewFile)
            containerViewFile.translatesAutoresizingMaskIntoConstraints = false
            let data = queryMessageReply(message_id: reffChat)
            if (reffChat.isEmpty || data.count == 0) && (dataMessages[indexPath.row][TypeDataMessage.is_forwarded] == nil || dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as? Int ?? 0 == 0) {
                containerViewFile.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 37).isActive = true
            } else {
                containerViewFile.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
            }
            containerViewFile.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            containerViewFile.bottomAnchor.constraint(equalTo:messageText.topAnchor, constant: -5).isActive = true
            containerViewFile.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
//            containerViewFile.heightAnchor.constraint(equalToConstant: 50).isActive = true
            containerViewFile.backgroundColor = .black.withAlphaComponent(0.2)
            containerViewFile.layer.cornerRadius = 5.0
            containerViewFile.clipsToBounds = true
            
            let imageFile = UIImageView(image: UIImage(systemName: "doc.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold, scale: .default)))
            containerViewFile.addSubview(imageFile)
            let nameFile = UILabel()
            containerViewFile.addSubview(nameFile)
            
            imageFile.translatesAutoresizingMaskIntoConstraints = false
            imageFile.leadingAnchor.constraint(equalTo: containerViewFile.leadingAnchor, constant: 5).isActive = true
            imageFile.trailingAnchor.constraint(equalTo: nameFile.leadingAnchor, constant: -5).isActive = true
            imageFile.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
            imageFile.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageFile.heightAnchor.constraint(equalToConstant: 30).isActive = true
            imageFile.tintColor = .docColor
            
            nameFile.translatesAutoresizingMaskIntoConstraints = false
            nameFile.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
            nameFile.widthAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true
            nameFile.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
            nameFile.textColor = .white
            nameFile.text = originalMessageText.components(separatedBy: "|")[0]
            
            if (dataMessages[indexPath.row]["progress"] as? Double ?? 0.0 != 100.0) {
                let containerLoading = UIView()
                containerViewFile.addSubview(containerLoading)
                containerLoading.translatesAutoresizingMaskIntoConstraints = false
                containerLoading.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor).isActive = true
                containerLoading.leadingAnchor.constraint(equalTo: nameFile.trailingAnchor, constant: 5).isActive = true
                containerLoading.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5).isActive = true
                containerLoading.widthAnchor.constraint(equalToConstant: 30).isActive = true
                containerLoading.heightAnchor.constraint(equalToConstant: 30).isActive = true
                let circlePath = UIBezierPath(arcCenter: CGPoint(x: 15, y: 15), radius: 10, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                let trackShape = CAShapeLayer()
                trackShape.path = circlePath.cgPath
                trackShape.fillColor = UIColor.clear.cgColor
                trackShape.lineWidth = 5
                trackShape.strokeColor = UIColor.blueBubbleColor.withAlphaComponent(0.3).cgColor
                containerLoading.layer.addSublayer(trackShape)
                let shapeLoading = CAShapeLayer()
                shapeLoading.path = circlePath.cgPath
                shapeLoading.fillColor = UIColor.clear.cgColor
                shapeLoading.lineWidth = 3
                shapeLoading.strokeEnd = 0
                shapeLoading.strokeColor = UIColor.secondaryColor.cgColor
                containerLoading.layer.addSublayer(shapeLoading)
                var imageupload = UIImageView(image: UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                if dataMessages[indexPath.row]["f_pin"] as? String != idMe {
                    imageupload = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    shapeLoading.strokeColor = UIColor.blueBubbleColor.cgColor
                }
                imageupload.tintColor = .white
                containerLoading.addSubview(imageupload)
                imageupload.translatesAutoresizingMaskIntoConstraints = false
                imageupload.centerYAnchor.constraint(equalTo: containerLoading.centerYAnchor).isActive = true
                imageupload.centerXAnchor.constraint(equalTo: containerLoading.centerXAnchor).isActive = true
                // Fix: the ring on a file bubble says how far along it is in bytes now, the
                // same as the one on photos and videos. It hangs under the file name, which
                // stays put - so a file that is merely not downloaded yet looks exactly as it
                // always did, and the caption only takes up room once there is a size to show.
                let transferSizeChip = ChatTransferRing.addSizeLabel(to: containerViewFile, fileName: fileChat, chromeless: true)
                NSLayoutConstraint.activate([
                    transferSizeChip.topAnchor.constraint(equalTo: nameFile.bottomAnchor, constant: 2),
                    transferSizeChip.leadingAnchor.constraint(equalTo: nameFile.leadingAnchor)
                ])
            } else {
                nameFile.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5).isActive = true
            }
            
            if !copySession && !forwardSession && !deleteSession && !summarizeSession {
                let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                let sfs = (dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String) ?? ""
                containerViewFile.addGestureRecognizer(objectTap)
                objectTap.containerFile = containerViewFile
                objectTap.labelFile = nameFile
                objectTap.file_id = fileChat
                objectTap.specFile = sfs
                objectTap.indexPath = indexPath
            }
        }
        
        let containerLinkMessage = UIView()
        var isLoadingShowLink = false
        if thumbChat.isEmpty && fileChat.isEmpty && !textChat.isEmpty {
            var text = ""
            let listTextSplitBreak = textChat.components(separatedBy: "\n")
            let indexFirstLinkSplitBreak = listTextSplitBreak.firstIndex(where: { $0.contains("www.") || $0.contains("http://") || $0.contains("https://") })
            if indexFirstLinkSplitBreak != nil {
                let listTextSplitSpace = listTextSplitBreak[indexFirstLinkSplitBreak!].components(separatedBy: " ")
                let indexFirstLinkSplitSpace = listTextSplitSpace.firstIndex(where: { ($0.starts(with: "www.") && $0.components(separatedBy: ".").count > 2) || ($0.starts(with: "http://") && $0.components(separatedBy: ".").count > 1) || ($0.starts(with: "https://") && $0.components(separatedBy: ".").count > 1) })
                if indexFirstLinkSplitSpace != nil {
                    text = listTextSplitSpace[indexFirstLinkSplitSpace!]
                }
            }
            if !text.isEmpty {
                isLoadingShowLink = true
                var dataURL = ""
                func showLink() {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let title = data["title"] as? String
                        let description = data["description"] as? String
                        let imageUrl = data["imageUrl"] as? String
                        let link = data["link"] as? String
                        
                        topMarginText.constant = topMarginText.constant + 85
                        
                        containerMessage.addSubview(containerLinkMessage)
                        containerLinkMessage.translatesAutoresizingMaskIntoConstraints = false
                        containerLinkMessage.leadingAnchor.constraint(equalTo:containerMessage.leadingAnchor, constant: 15).isActive = true
                        if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" {
                            containerLinkMessage.bottomAnchor.constraint(equalTo: imageSticker.topAnchor, constant: -5).isActive = true
                        } else {
                            containerLinkMessage.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                        }
                        containerLinkMessage.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                        containerLinkMessage.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
                        containerLinkMessage.backgroundColor = .gray.withAlphaComponent(0.2)
                        
                        let imagePreview = UIImageView()
                        if imageUrl != nil {
                            containerLinkMessage.addSubview(imagePreview)
                            imagePreview.translatesAutoresizingMaskIntoConstraints = false
                            imagePreview.leadingAnchor.constraint(equalTo: containerLinkMessage.leadingAnchor).isActive = true
                            imagePreview.bottomAnchor.constraint(equalTo: containerLinkMessage.bottomAnchor).isActive = true
                            imagePreview.topAnchor.constraint(equalTo: containerLinkMessage.topAnchor).isActive = true
                            imagePreview.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
                            imagePreview.loadImageAsync(with: imageUrl)
                            imagePreview.contentMode = .scaleAspectFill
                            imagePreview.clipsToBounds = true
                        }
                        
                        let titlePreview = UILabel()
                        containerLinkMessage.addSubview(titlePreview)
                        titlePreview.translatesAutoresizingMaskIntoConstraints = false
                        if imageUrl != nil {
                            titlePreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
                        } else {
                            titlePreview.leadingAnchor.constraint(equalTo: containerLinkMessage.leadingAnchor, constant: 5.0).isActive = true
                        }
                        titlePreview.topAnchor.constraint(equalTo: containerLinkMessage.topAnchor, constant: 10.0).isActive = true
                        titlePreview.trailingAnchor.constraint(equalTo: containerLinkMessage.trailingAnchor, constant: -5.0).isActive = true
                        titlePreview.text = title
                        titlePreview.font = UIFont.systemFont(ofSize: 12.0 + offset(), weight: .bold)
                        titlePreview.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                        
                        let descPreview = UILabel()
                        containerLinkMessage.addSubview(descPreview)
                        descPreview.translatesAutoresizingMaskIntoConstraints = false
                        if imageUrl != nil {
                            descPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
                        } else {
                            descPreview.leadingAnchor.constraint(equalTo: containerLinkMessage.leadingAnchor, constant: 5.0).isActive = true
                        }
                        descPreview.topAnchor.constraint(equalTo: titlePreview.bottomAnchor).isActive = true
                        descPreview.trailingAnchor.constraint(equalTo: containerLinkMessage.trailingAnchor, constant: -5.0).isActive = true
                        descPreview.text = description
                        descPreview.font = UIFont.systemFont(ofSize: 12.0 + offset())
                        descPreview.textColor = .gray
                        descPreview.numberOfLines = 1
                        
                        let linkPreview = UILabel()
                        containerLinkMessage.addSubview(linkPreview)
                        linkPreview.translatesAutoresizingMaskIntoConstraints = false
                        if imageUrl != nil {
                            linkPreview.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 5.0).isActive = true
                        } else {
                            linkPreview.leadingAnchor.constraint(equalTo: containerLinkMessage.leadingAnchor, constant: 5.0).isActive = true
                        }
                        linkPreview.topAnchor.constraint(equalTo: descPreview.bottomAnchor, constant: 8.0).isActive = true
                        linkPreview.trailingAnchor.constraint(equalTo: containerLinkMessage.trailingAnchor, constant: -5.0).isActive = true
                        linkPreview.text = link
                        linkPreview.font = UIFont.systemFont(ofSize: 10.0 + offset())
                        linkPreview.textColor = .gray
                        linkPreview.numberOfLines = 1
                        
                        if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as? Int ?? 0 != 0 {
                            showForwardedSign()
                        }
                        
                        if !copySession && !forwardSession && !deleteSession && !summarizeSession {
                            let objectTap = ObjectGesture(target: self, action: #selector(tapMessageText(_:)))
                            objectTap.message_id = text
                            containerLinkMessage.addGestureRecognizer(objectTap)
                        }
                    }
                }
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select data_link from LINK_PREVIEW where link='\(text)'"), cursor.next() {
                            if let data = cursor.string(forColumnIndex: 0) {
                                dataURL = data
                            }
                            cursor.close()
                        }
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
                if !dataURL.isEmpty {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let imageUrl = data["imageUrl"] as? String
                        let link = data["link"]  as? String ?? ""
                        if imageUrl == nil || (link.contains("youtube.com") && link.contains("watch?v=") && !imageUrl!.contains("img.youtube.com/vi/")) {
                            dataURL = ""
                        }
                    }
                }
                if !dataURL.isEmpty {
                    if let data = try! JSONSerialization.jsonObject(with: dataURL.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                        let imageUrl = data["imageUrl"] as? String
                        let link = data["link"]  as? String ?? ""
                        if imageUrl == nil || (link.contains("youtube.com") && link.contains("watch?v=") && !imageUrl!.contains("img.youtube.com/vi/")) {
                            dataURL = ""
                        }
                    }
                }
                if dataURL.isEmpty {
                    let urlConfig = URLSessionConfiguration.default
                    let sessionDelegate = PinnedURLSessionNexilisDelegate()
                    let session = URLSession(configuration: urlConfig, delegate: sessionDelegate, delegateQueue: nil)
                    let slp = SwiftLinkPreview(session: session,
                                               workQueue: SwiftLinkPreview.defaultWorkQueue,
                                               responseQueue: DispatchQueue.main,
                                               cache: DisabledCache.instance)
                    let preview = slp.preview(text,
                                              onSuccess: { result in
                        let title = result.title?.trimmingCharacters(in: .whitespacesAndNewlines)
                                    .nilIfEmpty ?? URL(string: text)?.host ?? "Untitled"
                        let description: String
                        if text.contains("google.com") {
                            description = "" // special rule for google
                        } else {
                            description = result.description?.trimmingCharacters(in: .whitespacesAndNewlines)
                                .nilIfEmpty ?? ""
                        }
                        let imageUrl = self.youtubeThumbnail(from: text)
                            ?? result.image
                            ?? result.icon
                            ?? ""
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                var dataJson: [String: Any] = [:]
                                dataJson["title"] = title
                                dataJson["description"] = description
                                dataJson["imageUrl"] = imageUrl
                                dataJson["link"] = text
                                guard let json = String(data: try! JSONSerialization.data(withJSONObject: dataJson, options: []), encoding: String.Encoding.utf8) else {
                                    return
                                }
                                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "LINK_PREVIEW", cvalues: [
                                    "id" : "\(Date().currentTimeMillis().toHex())",
                                    "link" : text,
                                    "data_link" : json,
                                    "retry": 0
                                ], replace: true)
                                dataURL = json
                                showLink()
                                DispatchQueue.main.async {
                                    tableView.reloadRows(at: [indexPath], with: .none)
                                }
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }, onError: { error in
                    })
                } else {
                    showLink()
                }
            }
        }
        
        if (!reffChat.isEmpty) {
            let data = queryMessageReply(message_id: reffChat)
            if data.count != 0 {
                
                let containerReply = UIView()
                containerMessage.addSubview(containerReply)
                containerReply.translatesAutoresizingMaskIntoConstraints = false
                containerReply.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                containerReply.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
                if thumbChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: imageThumb.topAnchor, constant: -5).isActive = true
                } else if fileChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: containerViewFile.topAnchor, constant: -5).isActive = true
                } else if containerMessage.subviews.contains(containerLinkMessage) {
                    containerReply.bottomAnchor.constraint(equalTo: containerLinkMessage.topAnchor, constant: -5).isActive = true
                } else if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                    containerReply.bottomAnchor.constraint(equalTo: imageSticker.topAnchor, constant: -5).isActive = true
                } else {
                    containerReply.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                }
                containerReply.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                let minHeightConstraint = containerReply.heightAnchor.constraint(greaterThanOrEqualToConstant: 50 + (self.offset()*3))
                minHeightConstraint.priority = .defaultHigh
                minHeightConstraint.isActive = true
                containerReply.backgroundColor = .black.withAlphaComponent(0.2)
                containerReply.layer.cornerRadius = 5
                containerReply.clipsToBounds = true
                
                if (thumbChat != "" || fileChat != "") && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                    topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: topMarginText.constant + 50 + (self.offset()*3))
                }
                
                let leftReply = UIView()
                containerReply.addSubview(leftReply)
                leftReply.translatesAutoresizingMaskIntoConstraints = false
                leftReply.leadingAnchor.constraint(equalTo: containerReply.leadingAnchor).isActive = true
                leftReply.topAnchor.constraint(equalTo: containerReply.topAnchor).isActive = true
                leftReply.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor).isActive = true
                leftReply.widthAnchor.constraint(equalToConstant: 3).isActive = true
                leftReply.layer.cornerRadius = 5
                leftReply.clipsToBounds = true
                leftReply.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
                
                let titleReply = UILabel()
                containerReply.addSubview(titleReply)
                titleReply.translatesAutoresizingMaskIntoConstraints = false
                titleReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
                titleReply.topAnchor.constraint(equalTo: containerReply.topAnchor, constant: 10).isActive = true
                titleReply.trailingAnchor.constraint(lessThanOrEqualTo: containerReply.trailingAnchor, constant: -20).isActive = true
                titleReply.font = UIFont.systemFont(ofSize: 12 + offset()).bold
                if (data["f_pin"] as? String == idMe) {
                    titleReply.text = "You".localized()
                    if dataMessages[indexPath.row]["f_pin"] as? String == idMe {
                        titleReply.textColor = .white
                        leftReply.backgroundColor = .white
                    } else {
                        titleReply.textColor = .mainColor
                        leftReply.backgroundColor = .mainColor
                    }
                } else {
                    if data["f_pin"] as? String != "-999" {
                        let dataProfile = getDataProfile(f_pin: data["f_pin"]  as? String ?? "", message_id: data["message_id"]  as? String ?? "")
                        titleReply.text = dataProfile["name"]
                    } else {
                        titleReply.text = "Bot"
                    }
                    if dataMessages[indexPath.row]["f_pin"] as? String == idMe {
                        titleReply.textColor = .white
                        leftReply.backgroundColor = .white
                    } else {
                        titleReply.textColor = .mainColor
                        leftReply.backgroundColor = .mainColor
                    }
                }
                
                let contentReply = UILabel()
                contentReply.numberOfLines = 2
                containerReply.addSubview(contentReply)
                contentReply.translatesAutoresizingMaskIntoConstraints = false
                contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
                contentReply.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor, constant: -10).isActive = true
                let topConstraintContent = contentReply.topAnchor.constraint(equalTo: titleReply.bottomAnchor)
                topConstraintContent.priority = .defaultHigh
                topConstraintContent.isActive = true
                contentReply.font = UIFont.systemFont(ofSize: 10 + offset())
                let message_text = data["message_text"] as? String ?? ""
                let attachment_flag = data["attachment_flag"] as? String  ?? ""
                let thumb_chat = data["thumb_id"] as? String ?? ""
                let image_chat = data["image_id"] as? String ?? ""
                let video_chat = data["video_id"] as? String ?? ""
                let file_chat = data["file_id"] as? String ?? ""
                if (attachment_flag == "0" && thumb_chat == "") {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
                } else if (attachment_flag == "1" || image_chat != "") {
                    if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                        contentReply.text = "📷 Photo".localized()
                    } else {
                        contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
                    }
                } else if (attachment_flag == "2" || video_chat != "") {
                    if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                        contentReply.text = "📹 Video".localized()
                    } else {
                        contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
                    }
                } else if (attachment_flag == "6" || file_chat != ""){
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
                } else if (attachment_flag == "11") {
                    contentReply.text = "❤️ Sticker"
                } else if attachment_flag == "27" {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.text = "📄 " + "Live Streaming".localized()
                } else if attachment_flag == "26" {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.text = "📄 " + "Seminar".localized()
                }
                contentReply.textColor = .white.withAlphaComponent(0.8)
                
                if (attachment_flag == "1" || attachment_flag == "2" || image_chat != "" || video_chat != "") {
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumb_chat)
                        let image : UIImage? =  {
                            if let img = Nexilis.imageCache.object(forKey: thumb_chat as NSString) {
                                return img
                            }
                            else if let img = UIImage(contentsOfFile: thumbURL.path)?.resize(target: CGSize(width: 500, height: 500)) {
                                Nexilis.imageCache.setObject(img, forKey: thumb_chat as NSString)
                                return img
                            }
                            return nil
                        }()
                        //                        let image = UIGraphicsRenderer.renderImageAt(url: thumbURL as NSURL, size: CGSize(width: 250, height: 250))
                        let imageThumb = UIImageView(image: image)
                        containerReply.addSubview(imageThumb)
                        imageThumb.layer.cornerRadius = 2.0
                        imageThumb.clipsToBounds = true
                        imageThumb.contentMode = .scaleAspectFill
                        imageThumb.translatesAutoresizingMaskIntoConstraints = false
                        imageThumb.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -10).isActive = true
                        imageThumb.centerYAnchor.constraint(equalTo: containerReply.centerYAnchor).isActive = true
                        imageThumb.widthAnchor.constraint(equalToConstant: 30).isActive = true
                        imageThumb.heightAnchor.constraint(equalToConstant: 30).isActive = true
                        
                        if (attachment_flag == "2") {
                            let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                            imageThumb.addSubview(imagePlay)
                            imagePlay.clipsToBounds = true
                            imagePlay.translatesAutoresizingMaskIntoConstraints = false
                            imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                            imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                            imagePlay.widthAnchor.constraint(equalToConstant: 10).isActive = true
                            imagePlay.heightAnchor.constraint(equalToConstant: 10).isActive = true
                            imagePlay.tintColor = .white
                        }
                        titleReply.trailingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: -20).isActive = true
                        contentReply.trailingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: -20).isActive = true
                    }
                }
                if (attachment_flag == "11") {
                    let imageSticker = UIImageView(image: UIImage(named: (message_text.component(1, separatedBy: "/")), in: Bundle.resourceBundle(for: Nexilis.self), with: nil))
                    containerReply.addSubview(imageSticker)
                    imageSticker.layer.cornerRadius = 2.0
                    imageSticker.clipsToBounds = true
                    imageSticker.translatesAutoresizingMaskIntoConstraints = false
                    imageSticker.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -10).isActive = true
                    imageSticker.centerYAnchor.constraint(equalTo: containerReply.centerYAnchor).isActive = true
                    imageSticker.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    imageSticker.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    titleReply.trailingAnchor.constraint(equalTo: imageSticker.leadingAnchor, constant: -20).isActive = true
                    contentReply.trailingAnchor.constraint(equalTo: imageSticker.leadingAnchor, constant: -20).isActive = true
                }
                
                if !copySession && !forwardSession && !deleteSession && !summarizeSession {
                    let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                    containerReply.addGestureRecognizer(objectTap)
                    objectTap.indexPath = indexPath
                    objectTap.message_id = data["message_id"]  as? String ?? ""
                }
            }
        }
        
        if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as? Int ?? 0 != 0 && !isLoadingShowLink {
            showForwardedSign()
        }
        
        func showForwardedSign() {
            topMarginText.constant = topMarginText.constant + 20
            
            let containerForwarded = UIView()
            containerMessage.addSubview(containerForwarded)
            containerForwarded.translatesAutoresizingMaskIntoConstraints = false
            containerForwarded.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            containerForwarded.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 32).isActive = true
            containerForwarded.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            containerForwarded.heightAnchor.constraint(equalToConstant: 20).isActive = true
            if thumbChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                if groupImages[messageIdChat] == nil {
                    containerForwarded.bottomAnchor.constraint(equalTo: imageThumb.topAnchor, constant: -5).isActive = true
                }
            } else if fileChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                containerForwarded.bottomAnchor.constraint(equalTo: containerViewFile.topAnchor, constant: -5).isActive = true
            } else if containerMessage.subviews.contains(containerLinkMessage) {
                containerForwarded.bottomAnchor.constraint(equalTo: containerLinkMessage.topAnchor, constant: -5).isActive = true
            } else if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                containerForwarded.bottomAnchor.constraint(equalTo: imageSticker.topAnchor, constant: -5).isActive = true
            }
            
            let imageForwarded = UIImageView()
            containerForwarded.addSubview(imageForwarded)
            imageForwarded.anchor(top: containerForwarded.topAnchor, left: containerForwarded.leftAnchor, width: 15, height: 15)
            imageForwarded.image = UIImage(systemName: "arrowshape.turn.up.right.fill")
            imageForwarded.tintColor = .gray
            
            let titleForwarded = UILabel()
            containerForwarded.addSubview(titleForwarded)
            titleForwarded.anchor(top: containerForwarded.topAnchor, left: imageForwarded.rightAnchor, right: containerForwarded.rightAnchor, height: 15)
            titleForwarded.font = .systemFont(ofSize: 15)
            let textForwarded = "Forwarded".localized()
            titleForwarded.attributedText = " $\(textForwarded)$".richText()
        }
        
        if messageText.isDescendant(of: containerMessage) {
            var addTopMargin = true
            if !reffChat.isEmpty && dataMessages[indexPath.row]["message_scope_id"]  as? String ?? "" != MessageScope.FORM {
                let data = queryMessageReply(message_id: reffChat)
                if data.count != 0 && (topMarginText.constant == 32.0 || topMarginText.constant == 100.0) {
                    addTopMargin = false
                }
            }
            if addTopMargin{
                topMarginText.isActive = true
            }
        }
        
        return cellMessage
    }
    
    func youtubeThumbnail(from url: String) -> String? {
        guard let url = URL(string: url) else { return nil }
        let host = url.host ?? ""
        
        if host.contains("youtube.com"),
           let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let videoId = queryItems.first(where: { $0.name == "v" })?.value {
            return "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
        }
        
        if host.contains("youtu.be") {
            let videoId = url.lastPathComponent
            return "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
        }
        
        return nil
    }
    
    func playPauseAudio(indexPath: IndexPath, playButton: UIButton, progressSlider: UISlider, timeLabel: UILabel) {
        guard let audioPlayer = audioPlayers[indexPath] else { return }

        if audioPlayer.isPlaying {
            // Pause Audio
            audioPlayer.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            timers[indexPath]?.invalidate()
        } else {
            // Stop other players if one is already playing
            if let currentPlayingIndexPath = playingIndexPath, let currentAudioPlayer = audioPlayers[currentPlayingIndexPath] {
                if currentPlayingIndexPath != indexPath {
                    currentAudioPlayer.pause()
                    timers[currentPlayingIndexPath]?.invalidate()
                    timers[currentPlayingIndexPath] = nil
                    audioPlayers[currentPlayingIndexPath] = nil
                    tableChatView.reloadRows(at: [currentPlayingIndexPath], with: .none)
                }
            }
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                
            }

            // Play new audio
            audioPlayer.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            playingIndexPath = indexPath

            // Start timer to update progress
            timers[indexPath] = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                progressSlider.value = Float(audioPlayer.currentTime)
                timeLabel.text = self.formatTime(audioPlayer.currentTime)
            }
        }
    }
    
    func sliderChanged(indexPath: IndexPath, progressSlider: UISlider, timeLabel: UILabel) {
        guard let audioPlayer = audioPlayers[indexPath] else { return }
        audioPlayer.currentTime = TimeInterval(progressSlider.value)
        timeLabel.text = formatTime(audioPlayer.currentTime)
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let roundedTime = time.rounded(.up)
        let minutes = Int(roundedTime) / 60
        let seconds = Int(roundedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let finishedIndexPath = audioPlayers.first(where: { $0.value == player })?.key {
           DispatchQueue.main.async {
               self.timers[finishedIndexPath]?.invalidate()
               self.timers[finishedIndexPath] = nil
               self.playingIndexPath = nil
               self.audioPlayers[finishedIndexPath] = nil
               self.tableChatView.reloadRows(at: [finishedIndexPath], with: .none)
           }
        }
    }
    
    @objc func imageGroupingTapped(_ sender: ObjectGesture) {
        let listGroupingImages = ListGroupImages()
        // Opened by the conversation itself, so a picture reached through a collage lands on the
        // same viewer, with the same strip and the same menu, as one tapped in a bubble.
        listGroupingImages.openSingle = { [weak self] messageId, presenter, origin in
            self?.openMedia(messageId: messageId, from: presenter, origin: origin)
        }
        listGroupingImages.imageTapped = sender.indexImageTapped
        listGroupingImages.listGroupingImages = sender.listImageFromGrouping
        listGroupingImages.titleName = titleText
        listGroupingImages.isInitiator = sender.isInitiator
        listGroupingImages.isPersonal = false
        listGroupingImages.updateEditor = { [self] updatedData, replyData, isUpdateDelete in
            if replyData.count == 0 {
                if updatedData.count != 0 && !isUpdateDelete {
                    groupImages[sender.listImageFromGrouping[0].messageId] = updatedData
                } else if updatedData.count > 0 {
                    let deletedForEveryoneData = updatedData.filter({ $0.dataMessage["lock"] as? String == "1" })
                    if deletedForEveryoneData.count != 0 {
                        if groupImages[sender.listImageFromGrouping[0].messageId] != nil {
                            var dataWillEmpty = updatedData
                            while dataWillEmpty.count > 0 {
                                if let lastIdx = dataWillEmpty.lastIndex(where: { $0.dataMessage["lock"] as? String == "1" }) {
                                    if let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.listImageFromGrouping[0].messageId }) {
                                        if dataWillEmpty[lastIdx].messageId == sender.listImageFromGrouping[0].messageId {
                                            self.dataMessages.remove(at: idx)
                                            self.dataMessages.insert(dataWillEmpty[lastIdx].dataMessage, at: idx)
                                        } else {
                                            self.dataMessages.insert(dataWillEmpty[lastIdx].dataMessage, at: idx + 1)
                                        }
                                        let subData = Array(updatedData[lastIdx+1..<dataWillEmpty.count])
                                        if subData.count >= 4 {
                                            groupImages[subData[0].messageId] = subData
                                            self.dataMessages.insert(subData[0].dataMessage, at: lastIdx + 1)
                                        } else {
                                            if subData.count > 0 {
                                                self.dataMessages.insert(contentsOf: subData.map({ $0.dataMessage }), at: idx + (dataWillEmpty[lastIdx].messageId == sender.listImageFromGrouping[0].messageId ? 1 : 2))
                                            }
                                        }
                                    }
                                    dataWillEmpty.removeSubrange(lastIdx..<dataWillEmpty.count)
                                } else if dataWillEmpty.count >= 4 {
                                    groupImages[dataWillEmpty[0].messageId] = dataWillEmpty
                                    dataWillEmpty.removeAll()
                                } else {
                                    if let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.listImageFromGrouping[0].messageId }) {
                                        self.dataMessages.remove(at: idx)
                                        self.dataMessages.insert(contentsOf: dataWillEmpty.map({ $0.dataMessage }), at: idx)
                                        groupImages.removeValue(forKey: sender.listImageFromGrouping[0].messageId)
                                    }
                                    dataWillEmpty.removeAll()
                                }
                            }
                        } else {
                            
                        }
                    } else {
                        if updatedData.count >= 4 {
                            if updatedData[0].messageId == sender.listImageFromGrouping[0].messageId {
                                groupImages[sender.listImageFromGrouping[0].messageId] = updatedData
                            } else {
                                if let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.listImageFromGrouping[0].messageId }) {
                                    self.dataMessages.remove(at: idx)
                                    self.dataMessages.insert(updatedData[0].dataMessage, at: idx)
                                    groupImages.removeValue(forKey: sender.listImageFromGrouping[0].messageId)
                                    groupImages[updatedData[0].messageId] = updatedData
                                }
                            }
                        } else {
                            if let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.listImageFromGrouping[0].messageId }) {
                                groupImages.removeValue(forKey: sender.listImageFromGrouping[0].messageId)
                                self.dataMessages.remove(at: idx)
                                let dataMessageInGrouping = updatedData.map({ $0.dataMessage })
                                self.dataMessages.insert(contentsOf: dataMessageInGrouping, at: idx)
                            }
                        }
                    }
                } else {
                    groupImages.removeValue(forKey: sender.listImageFromGrouping[0].messageId)
                    if let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.listImageFromGrouping[0].messageId }) {
                        self.dataMessages.remove(at: idx)
                    }
                }
                DispatchQueue.main.async { [self] in
                    tableChatView.reloadData()
                }
            } else if replyData.count != 0 {
                handleReply(indexPath: IndexPath(row: 0, section: 0), dataMessagesImage: replyData)
            }
        }
        self.navigationController?.pushViewController(listGroupingImages, animated: true)
    }
    
    @objc func tapAck(_ sender: ObjectGesture) {
        let indexPath = sender.indexPath
        let dataMessages = self.messages(onDate: dataDates[indexPath.section])
        if dataMessages[indexPath.row]["status"]  as? String ?? "" == "8" {
            return
        }
        if !CheckConnection.isConnectedToNetwork() || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        DispatchQueue.global().async {
            var opposite_pin = self.dataGroup["group_id"]  as? String ?? ""
            if (self.dataTopic["chat_id"]  as? String ?? "" != "") {
                opposite_pin = self.dataTopic["chat_id"]  as? String ?? ""
            }
            let result = Nexilis.write(message: CoreMessage_TMessageBank.getAckLocationMessage(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "", message_id: dataMessages[indexPath.row]["message_id"]  as? String ?? "", l_pin: opposite_pin, server_date: "\(Date().currentTimeMillis())", message_scope_id: dataMessages[indexPath.row]["message_scope_id"]  as? String ?? "", longitude: self.longitude, latitude: self.latitude, description: ""))
            if result != nil {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                            "status" : "8"
                        ], _where: "message_id = '\(dataMessages[indexPath.row]["message_id"]  as? String ?? "")'")
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
                DispatchQueue.main.async {
                    if let index = self.dataMessages.firstIndex(where: {$0["message_id"] as? String == dataMessages[indexPath.row]["message_id"] as? String}) {
                        self.dataMessages[index]["status"] = "8"
                        let section = self.dataDates.firstIndex(of: self.dataMessages[index]["chat_date"]  as? String ?? "")
                        let row = self.messages(onDate: self.dataDates[section!]).firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[index]["message_id"]  as? String ?? ""})
                        if row != nil && section != nil {
                            self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                        }
                        self.view.makeToast("Confirmation Success.".localized(), duration: 3)
                    }
                }
            }
        }
    }
    
    @objc func contentMessageTapped(_ sender: ObjectGesture) {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        var indexPath = sender.indexPath
        if indexPath.count == 0 {
            if let index = self.dataMessages.firstIndex(where: {$0["message_id"] as? String == sender.message_id}) {
                let section = self.dataDates.firstIndex(of: self.dataMessages[index]["chat_date"]  as? String ?? "")
                let row = self.messages(onDate: self.dataDates[section!]).firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[index]["message_id"]  as? String ?? ""})
                if row != nil && section != nil {
                    indexPath = IndexPath(row: row!, section: section!)
                }
            }
        }
        let dataMessages = self.messages(onDate: dataDates[indexPath.section])
        func showMedia(data: Data? = nil, url: URL? = nil, type: Int = 0) {
            let image = UIImage(data: data ?? Data())
            let imageViewer = MediaViewerViewController()
            if type == 0 {
                imageViewer.media = .image(image ?? UIImage())
            } else if type == 1 {
                imageViewer.media = .video(url ?? URL(string: "")!)
                // Opened straight onto a video from the conversation, so it starts playing.
                imageViewer.autoPlaysOnOpen = true
            } else if type == 2 {
                imageViewer.media = .gif(data ?? Data())
            }
            
            let navigationController = UINavigationController(rootViewController: imageViewer)
            navigationController.defaultStyle()
            navigationController.view.backgroundColor = .clear
            navigationController.modalPresentationCapturesStatusBarAppearance = true
            navigationController.modalPresentationStyle = .overFullScreen
            
            let backAction = UIAction { _ in
                navigationController.dismiss(animated: true)
            }
            let backButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "chevron.backward"), primaryAction: backAction, menu: nil)
            imageViewer.navigationItem.leftBarButtonItem = backButton
            // What was written with the picture, and every other picture of the conversation.
            //
            // Fix: this took the row's own message, and a collage is one row standing for several
            // - so its id is the first picture of the group whichever one was tapped. Tapping the
            // third opened the first. The gesture names the picture when it knows it, which is
            // what a tap from the collage screen sets.
            let rowMessageId = dataMessages[indexPath.row]["message_id"] as? String ?? ""
            let messageId = messageForMedia(messageId: sender.message_id) != nil ? sender.message_id : rowMessageId
            let opened = messageForMedia(messageId: messageId) ?? dataMessages[indexPath.row]
            imageViewer.caption = opened["message_text"] as? String ?? ""
            // Only hand over the strip when the picture being opened is in it. A one-time
            // picture is left out of the run on purpose, and a strip that does not contain what
            // was tapped would open the viewer on somebody else's picture.
            let strip = self.conversationMediaStrip()
            if let opened = strip.firstIndex(where: { $0.messageId == messageId }) {
                imageViewer.stripItems = strip
                imageViewer.currentStripIndex = opened
            }
            imageViewer.isStarred = (opened["is_stared"] as? String ?? "0") == "1"

            if (Nexilis.checkingAccess(key: "secure_folder_share") || sender.specFile.contains("download") || sender.specFile.contains("share")) && dataMessages[indexPath.row]["credential"] as? String != "1" {
                imageViewer.onShare = { [weak imageViewer] _ in
                    guard let imageViewer = imageViewer else {
                        return
                    }
                    var activityViewController = UIActivityViewController(activityItems: [""], applicationActivities: nil)
                    if type == 1 {
                        activityViewController = UIActivityViewController(activityItems: [url ?? URL(string: "")!], applicationActivities: nil)
                    } else {
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ImageSharedNexilis-\(Date().currentTimeMillis())" + ".jpeg")
                        try? data?.write(to: tempURL)
                        activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    }
                    activityViewController.popoverPresentationController?.sourceView = imageViewer.view
                    imageViewer.present(activityViewController, animated: true, completion: nil)
                }
            }

            // Everything below closes the viewer first: what it does happens back in the
            // conversation, and leaving the picture over the top of it would hide the result.
            // Each of these is about whichever picture is on screen, which is not necessarily
            // the one that was tapped - the viewer moves between them on its own now.
            imageViewer.onAllMedia = { [weak self] shownId in
                // Fix: this used to close the viewer and push the browser on the conversation, so
                // Back out of the browser landed in the conversation rather than on the picture
                // the reader had opened the browser from. It is pushed on the viewer's own stack.
                self?.showAllMedia(startingAt: shownId.isEmpty ? messageId : shownId,
                                   in: navigationController,
                                   returningTo: imageViewer)
            }
            imageViewer.onGoToMessage = { [weak self] shownId in
                let wanted = shownId.isEmpty ? messageId : shownId
                // Fix: this scrolled this conversation and stopped there. Opened from a media
                // browser that is itself on top of this screen - or from a profile, where this
                // conversation is only kept behind the browser and never shown - scrolling it did
                // nothing the reader could see. Whatever the case, the conversation is brought to
                // the front first.
                (sender.presenter ?? self)?.dismiss(animated: true) {
                    self?.reveal(messageId: wanted, from: sender.presenter)
                }
            }
            imageViewer.onStar = { [weak self] shownId in
                self?.toggleStar(messageId: shownId.isEmpty ? messageId : shownId)
            }
            // Fix: these used to open the selection session with the picture already ticked, which
            // meant closing the viewer only to be handed the conversation with a tick on it and a
            // second press still to make. Pressed from a picture the message is already chosen, so
            // the chooser and the delete offer are put up directly.
            imageViewer.onForward = { [weak self] shownId in
                guard let self = self,
                      let row = self.messageForMedia(messageId: shownId.isEmpty ? messageId : shownId) else {
                    return
                }
                self.presentForwardChooser(for: [row], from: imageViewer)
            }
            imageViewer.onDelete = { [weak self] shownId in
                guard let self = self,
                      let row = self.messageForMedia(messageId: shownId.isEmpty ? messageId : shownId) else {
                    return
                }
                self.presentDeleteOptions(for: [row], from: imageViewer)
            }
            // The conversation follows along while the viewer is open, so by the time it is
            // closed the reader is already where they expect to be - and the picture shrinks
            // back towards the message it belongs to rather than towards wherever the list
            // happened to be left.
            imageViewer.onMediaChanged = { [weak self] shownId in
                guard let self = self, !shownId.isEmpty else {
                    return
                }
                // Moved past what the collage holds. The collage has nothing to say about this
                // picture, so it steps out of the way behind the viewer - and closing then lands
                // on the conversation, at the message being looked at, rather than back on a
                // screen that no longer shows it.
                if let collage = sender.presenter as? ListGroupImages, !collage.holds(messageId: shownId) {
                    self.navigationController?.popToViewController(self, animated: false)
                    sender.presenter = nil
                }
                self.goToMessage(messageId: shownId)
                if let indexPath = self.indexPath(forMessageId: shownId),
                   let cell = self.tableChatView.cellForRow(at: indexPath),
                   let thumbnail = EditorGroup.firstImageView(in: cell.contentView) {
                    self.transitioningDelegateRef?.originImageView = thumbnail
                }
            }
            imageViewer.onDismiss = { [weak self] shownId in
                guard !shownId.isEmpty, shownId != messageId else {
                    return
                }
                self?.goToMessage(messageId: shownId)
            }
            imageViewer.navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: nil,
                image: UIImage(systemName: "ellipsis"),
                primaryAction: nil,
                menu: imageViewer.makeOverflowMenu())
            
            let dataProfile = getDataProfile(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "", message_id: dataMessages[indexPath.row]["message_id"]  as? String ?? "")
            let name = dataProfile["name"]
            imageViewer.titleCustom = name ?? ""
            if let timestamp = Double(dataMessages[indexPath.row][TypeDataMessage.server_date] as? String ?? "") {
                let date = Date(timeIntervalSince1970: timestamp / 1000)
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yy HH:mm"
                imageViewer.subtitleCustom = formatter.string(from: date)
            }
            imageViewer.isSecure = dataMessages[indexPath.row][TypeDataMessage.credential] as? String == "1"
            
            let transitionDelegate = ZoomTransitioningDelegate()
            transitionDelegate.originImageView = sender.imageView
            // Answered when a transition starts, not stored up front: the viewer moves between
            // pictures on its own, and the bubble to shrink back into is whichever one holds the
            // picture being shown at that moment. Reading it fresh also means it is never a cell
            // the table has since handed to another message.
            transitionDelegate.originProvider = { [weak self, weak imageViewer] in
                guard let self = self, let viewer = imageViewer else {
                    return nil
                }
                // Still on one of the collage's own pictures, so it is the collage's row that the
                // viewer came out of and should go back into. Once the reader has moved past what
                // the collage holds, `presenter` has been let go and the conversation answers.
                if let collage = sender.presenter as? ListGroupImages, collage.holds(messageId: viewer.currentMessageId) {
                    return sender.imageView
                }
                let shown = viewer.currentMessageId
                guard !shown.isEmpty,
                      let indexPath = self.indexPath(forMessageId: shown),
                      let cell = self.tableChatView.cellForRow(at: indexPath) else {
                    return nil
                }
                return EditorGroup.firstImageView(in: cell.contentView)
            }
            navigationController.transitioningDelegate = transitionDelegate
            self.transitioningDelegateRef = transitionDelegate
            
            (sender.presenter ?? self).present(navigationController, animated: true) {
                imageViewer.animateBackgroundIn()
            }
        }
        if (sender.image_id != "") {
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.image_id)
                if FileManager.default.fileExists(atPath: imageURL.path) {
                    do {
                        showMedia(data: try Data(contentsOf: imageURL))
                    } catch {
                        
                    }
                } else if FileEncryption.shared.isSecureExists(filename: sender.image_id) {
                    do {
                        if var data = try FileEncryption.shared.readSecure(filename: sender.image_id) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                            if dataDecrypt != nil {
                                data = dataDecrypt!
                            }
                            showMedia(data: data)
                        }
                    }
                    catch {
                        print("Error reading secure file")
                    }
                } else {
                    beginTransfer(ofFileNamed: sender.image_id, from: sender.indexPath)
                }
            }
        } else if (sender.gif_id != "") {
            if let dirPath = paths.first {
                let gifURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.gif_id)
                if FileManager.default.fileExists(atPath: gifURL.path) {
                    do {
                        let data = try Data(contentsOf: gifURL)
                        showMedia(data: data, type: 2)
                    } catch {
                        
                    }
                } else if FileEncryption.shared.isSecureExists(filename: sender.gif_id) {
                    do {
                        if var secureData = try FileEncryption.shared.readSecure(filename: sender.gif_id) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
                            if dataDecrypt != nil {
                                secureData = dataDecrypt!
                            }
                            showMedia(data: secureData, type: 2)
                        }
                    } catch {
                        
                    }
                }
            }
        } else if (sender.video_id != "") {
            if let dirPath = paths.first {
                let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.video_id)
                if FileManager.default.fileExists(atPath: videoURL.path) {
                    showMedia(url: videoURL, type: 1)
                } else if FileEncryption.shared.isSecureExists(filename: sender.video_id) {
                    do {
                        if var secureData = try FileEncryption.shared.readSecure(filename: sender.video_id) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
                            if dataDecrypt != nil {
                                secureData = dataDecrypt!
                            }
                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                            let tempPath = cachesDirectory.appendingPathComponent(sender.video_id)
                            try secureData.write(to: tempPath)
                            showMedia(url: tempPath, type: 1)
                        }
                    } catch {
                        
                    }
                } else {
                    beginTransfer(ofFileNamed: sender.video_id, from: sender.indexPath)
                }
            }
        } else if (sender.file_id != "") {
            func showFile(urlFile: URL) {
                let previewController = QLPreviewController()
                previewController.dataSource = self
                let vcHandleFile = UIViewController()
                let nc = UINavigationController(rootViewController: vcHandleFile)
                let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                let navBarAppearance = UINavigationBarAppearance()
                nc.defaultStyle()
                navBarAppearance.configureWithOpaqueBackground()
                navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
                navBarAppearance.titleTextAttributes = attributes
                nc.navigationBar.standardAppearance = navBarAppearance
                nc.navigationBar.scrollEdgeAppearance = navBarAppearance
                let backAction = UIAction { _ in
                    nc.dismiss(animated: true)
                }
                let backButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "chevron.backward"), primaryAction: backAction, menu: nil)
                vcHandleFile.navigationItem.leftBarButtonItem = backButton
                if (Nexilis.checkingAccess(key: "secure_folder_share") || sender.specFile.contains("download") || sender.specFile.contains("share")) && dataMessages[indexPath.row]["credential"] as? String != "1" {
                    let shareAction = UIAction { _ in
                        let fileManager = FileManager.default
                        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(urlFile.lastPathComponent)
                        do {
                            if !fileManager.fileExists(atPath: tempURL.path) {
                                try fileManager.copyItem(at: urlFile, to: tempURL)
                            }
                            let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                            activityViewController.popoverPresentationController?.sourceView = vcHandleFile.view
                            vcHandleFile.present(activityViewController, animated: true, completion: nil)
                        } catch {
                            
                        }
                    }
                    let shareButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "square.and.arrow.up"), primaryAction: shareAction, menu: nil)
                    vcHandleFile.navigationItem.rightBarButtonItem = shareButton
                }
                if let viewVc = vcHandleFile.view {
                    let isSecure = dataMessages[indexPath.row][TypeDataMessage.credential] as? String == "1"
                    vcHandleFile.title = sender.labelFile.text
                    var secureView: UIView!
                    if isSecure {
                        secureView = SecureField().secureContainer
                        
                        let privacyOverlay: UIView = {
                            let view = UIView()
                            view.backgroundColor = .black
                            return view
                        }()
                        
                        viewVc.addSubview(privacyOverlay)
                        privacyOverlay.translatesAutoresizingMaskIntoConstraints = false
                        NSLayoutConstraint.activate([
                            privacyOverlay.topAnchor.constraint(equalTo: viewVc.topAnchor),
                            privacyOverlay.bottomAnchor.constraint(equalTo: viewVc.bottomAnchor),
                            privacyOverlay.leadingAnchor.constraint(equalTo: viewVc.leadingAnchor),
                            privacyOverlay.trailingAnchor.constraint(equalTo: viewVc.trailingAnchor)
                        ])

                        // Add WhatsApp-style message
                        let icon = UIImageView(image: UIImage(systemName: "camera.fill"))
                        icon.tintColor = .mainColor
                        icon.contentMode = .scaleAspectFit

                        let label = UILabel()
                        label.text = "Screen capture/recording blocked".localized()
                        label.font = .systemFont(ofSize: 22, weight: .semibold)
                        label.textColor = .white

                        let desc = UILabel()
                        desc.text = "You tried to take a screenshot.\nFor added privacy, credential messages don’t allow this.".localized()
                        desc.font = .systemFont(ofSize: 16)
                        desc.textColor = .lightGray
                        desc.numberOfLines = 0
                        desc.textAlignment = .center

                        let stack = UIStackView(arrangedSubviews: [icon, label, desc])
                        stack.axis = .vertical
                        stack.alignment = .center
                        stack.spacing = 18

                        privacyOverlay.addSubview(stack)
                        stack.translatesAutoresizingMaskIntoConstraints = false

                        NSLayoutConstraint.activate([
                            stack.centerXAnchor.constraint(equalTo: privacyOverlay.centerXAnchor),
                            stack.centerYAnchor.constraint(equalTo: privacyOverlay.centerYAnchor),
                            stack.leftAnchor.constraint(equalTo: viewVc.leftAnchor),
                            stack.rightAnchor.constraint(equalTo: viewVc.rightAnchor),
                            icon.widthAnchor.constraint(equalToConstant: 80),
                            icon.heightAnchor.constraint(equalToConstant: 80)
                        ])
                        
                        viewVc.addSubview(secureView)
                        secureView.frame = CGRect(x: 0, y: 0, width: viewVc.bounds.size.width, height: viewVc.bounds.size.height)
                    }
                    vcHandleFile.addChild(previewController)
                    previewController.dataSource = self
                    previewController.view.frame = CGRect(x: 0, y: 0, width: isSecure ? secureView.bounds.size.width : viewVc.bounds.size.width, height: isSecure ? secureView.bounds.size.height : viewVc.bounds.size.height)
                    previewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    if isSecure {
                        secureView.addSubview(previewController.view)
                    } else {
                        viewVc.addSubview(previewController.view)
                    }
                    previewController.didMove(toParent: vcHandleFile)
                    
                    self.present(nc, animated: true)
                }
            }
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.file_id)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    self.previewItem = fileURL as NSURL
                    showFile(urlFile: fileURL)
                } else if FileEncryption.shared.isSecureExists(filename: sender.file_id) {
                    do {
                        if var docData = try FileEncryption.shared.readSecure(filename: sender.file_id) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: docData)
                            if dataDecrypt != nil {
                                docData = dataDecrypt!
                            }
                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                            let tempPath = cachesDirectory.appendingPathComponent(sender.file_id)
                            try docData.write(to: tempPath)
                            self.previewItem = tempPath as NSURL
                            showFile(urlFile: tempPath)
                        }
                    }
                    catch {
                        
                    }
                } else {
                    beginTransfer(ofFileNamed: sender.file_id, from: sender.indexPath)
                }
            }
        } else {
            DispatchQueue.main.async {
                // This is the jump to a quoted or pinned message. The message being jumped to
                // is by nature an older one and may sit above the loaded window - without
                // this the lookup below simply finds nothing and the tap does nothing at all.
                self.ensureMessageLoaded(messageId: sender.message_id)
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == sender.message_id})
                if idx == nil {
                    return
                }
                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                if section == nil {
                    return
                }
                let row = self.messages(onDate: self.dataDates[section!]).firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[idx!]["message_id"]  as? String ?? ""})
                if row == nil {
                    return
                }
                let indexPath = IndexPath(row: row!, section: section!)
                self.tableChatView.safeScrollToRow(at: indexPath, at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        let containerMessage = cell.contentView.subviews[1]
                        let idMe = User.getMyPin() as String?
                        if (self.dataMessages[idx!]["f_pin"] as? String == idMe) {
                            containerMessage.backgroundColor = .blueBubbleColor.withAlphaComponent(0.3)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if (self.dataMessages[idx!]["attachment_flag"] as? String == "11") {
                                    containerMessage.backgroundColor = .clear
                                } else {
                                    containerMessage.backgroundColor = .blueBubbleColor
                                }
                            }
                        } else {
                            containerMessage.backgroundColor = .whiteBubbleColor.withAlphaComponent(0.3)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if (self.dataMessages[idx!]["attachment_flag"] as? String == "11") {
                                    containerMessage.backgroundColor = .clear
                                } else {
                                    containerMessage.backgroundColor = .whiteBubbleColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }
        
    func highlightedText(for text: String, in range: Range<String.Index>, textView: UITextView) -> NSAttributedString {
        let mutableAttributedString = textView.attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.addAttribute(.backgroundColor, value: UIColor.lightGray.withAlphaComponent(0.5), range: NSRange(range, in: text))
        return mutableAttributedString
    }
    
    func removeHighlightedText(for text: String, in range: Range<String.Index>, textView: UITextView) -> NSAttributedString {
        let mutableAttributedString = textView.attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.removeAttribute(.backgroundColor, range: NSRange(range, in: text))
        return mutableAttributedString
    }
        
    // Fix: delegates to LinkOpener.swift - the single shared, corrected
    // implementation also used by EditorPersonal, EditorStarMessages, ChatGPTBotView,
    // and MessageInfo. See LinkOpener.swift for the full list of bugs fixed.
    @objc func tapMessageText(_ sender: ObjectGesture) {
        LinkOpener.open(urlString: sender.message_id)
    }

    // Fix: replaces UITextView's own shouldInteractWith(...) tap handling, which
    // stopped firing once messageText.isSelectable was set to false (link tap
    // handling in UITextView is gated by isSelectable, same as text selection) -
    // this plain tap gesture is independent of that setting. Long-press is handled
    // separately, timed by handleLinkTouchHighlight (see its doc comment), which
    // presents LinkActionSheetViewController if held past the threshold.
    //
    // Fix: no longer touches the highlight at all - that's now owned entirely by
    // handleLinkTouchHighlight, tied 1:1 to the finger's actual on-screen state
    // (visible while touching a link, gone the instant it isn't), matching WhatsApp.
    // This method's only job is deciding whether to open the link.
    @objc private func handleMessageTextTap(_ sender: UITapGestureRecognizer) {
        // Fix: a long-press that turned into LinkActionSheetViewController already
        // set this flag before the finger lifted - this same finger-lift also
        // satisfies a plain UITapGestureRecognizer's (very loose, duration-agnostic)
        // recognition criteria, so without this check the link would open a second
        // time right on top of the action sheet appearing. Consume-and-return: this
        // tap is "spent" on the long-press that already happened, not a new one.
        if suppressNextLinkTap {
            suppressNextLinkTap = false
            return
        }

        guard let textView = sender.view as? UITextView else { return }
        let point = sender.location(in: textView)
        guard let info = LinkHighlighting.linkInfo(at: point, in: textView) else { return }

        LinkOpener.open(urlString: info.urlString)
    }
    
    //    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    //        if copySession || forwardSession || deleteSession || summarizeSession {
    //            return nil
    //        }
    //        let idMe = User.getMyPin() as String?
    //        if (dataMessages[indexPath.row]["f_pin"] as? String != idMe) {
    //            return nil
    //        }
    //        let messageInfoVC = MessageInfo()
    //        self.navigationController?.show(messageInfoVC, sender: nil)
    //        return UISwipeActionsConfiguration()
    //    }
    //
    //    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    //        if copySession || forwardSession || deleteSession || summarizeSession {
    //            return nil
    //        }
    //        let action = UIContextualAction(style: .normal,
    //                                        title: "") { [weak self] (action, view, completionHandler) in
    //                                            self?.handleReply(indexPath: indexPath)
    //                                            completionHandler(true)
    //        }
    //        action.backgroundColor = .white
    //        action.image = UIImage(systemName: "arrowshape.turn.up.left.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal)
    //        return UISwipeActionsConfiguration(actions: [action])
    //    }
    
    private func pinAllMessages(dataMessages: [[String: Any?]], isPinned: Int = -1) {
        var dataMessages = dataMessages
        dataMessages.sort {
            let firstPinned = Int64($0[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
            let secondPinned = Int64($1[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
            return firstPinned < secondPinned
        }
        if dataMessages.count != 0 {
            if !self.containerPin.isDescendant(of: self.view) && dataMessages.count != 0 {
                self.tableChatView.contentInset.top = 50
                
                self.view.addSubview(self.containerPin)
                self.containerPin.isUserInteractionEnabled = true
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewPinTapped))
                self.containerPin.addGestureRecognizer(tapGesture)
                self.containerPin.anchor(top: self.view.safeAreaLayoutGuide.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, height: 50)
                self.containerPin.backgroundColor = .mainColor
                
                if dataMessages.count > 1 {
                    self.containerPin.addSubview(self.signSelectedPin)
                    self.signSelectedPin.anchor(left: self.containerPin.leftAnchor, paddingLeft: 8, centerY: self.containerPin.centerYAnchor, width: 2, height: 30)
                    self.signSelectedPin.layer.cornerRadius = 1
                    self.signSelectedPin.clipsToBounds = true
                    self.signSelectedPin.alignment = .fill
                    self.signSelectedPin.axis = .vertical
                    self.signSelectedPin.distribution = .fill
                    self.signSelectedPin.spacing = dataMessages.count == 3 ? 1.5 : 2
                    
                    let heightSign: CGFloat = CGFloat((30 / dataMessages.count) - 1)
                    let widthSign: CGFloat = 2

                    for i in 0..<dataMessages.count {
                        let viewSign = UIView()
                        viewSign.backgroundColor = (i == (dataMessages.count - 1)) ? .white : .gray
                        viewSign.anchor(width: widthSign, height: heightSign)
                        viewSign.layer.cornerRadius = 1
                        viewSign.clipsToBounds = true
                        self.signSelectedPin.addArrangedSubview(viewSign)
                    }
                    self.nextPinShowed = dataMessages.count - 1
                }
                
                let contIconPin = UIImageView()
                self.containerPin.addSubview(contIconPin)
                contIconPin.anchor(left: self.containerPin.leftAnchor, paddingLeft: 15, centerY: self.containerPin.centerYAnchor, width: 30, height: 30)
                contIconPin.layer.cornerRadius = 8
                contIconPin.clipsToBounds = true
                contIconPin.backgroundColor = .gray
                contIconPin.image = UIImage(systemName: "pin.fill")?.imageWithInsets(insets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))?.withTintColor(.waGrayLight)
                
                self.containerPin.addSubview(textPin)
                self.textPin.anchor(left: contIconPin.rightAnchor, right: self.containerPin.rightAnchor, paddingLeft: 10, paddingRight: 10, centerY: self.containerPin.centerYAnchor)
                let chat = Chat.getMessageFromId(message_id: dataMessages[dataMessages.count - 1][TypeDataMessage.message_id] as? String ?? "")
                if chat.count > 0 {
                    let text = Utils.previewMessageText(chat: chat[0])
                    if let attributeText = text as? NSMutableAttributedString {
                        self.textPin.attributedText = attributeText
                    }
                }
                self.textPin.numberOfLines = 1
                self.textPin.textColor = .white
            } else {
                self.signSelectedPin.subviews.forEach({ $0.removeFromSuperview() })
                self.signSelectedPin.removeFromSuperview()
                var same = false
                if dataMessages.count > 1 {
                    self.containerPin.addSubview(self.signSelectedPin)
                    self.signSelectedPin.anchor(left: self.containerPin.leftAnchor, paddingLeft: 8, centerY: self.containerPin.centerYAnchor, width: 2, height: 30)
                    self.signSelectedPin.layer.cornerRadius = 1
                    self.signSelectedPin.clipsToBounds = true
                    self.signSelectedPin.alignment = .fill
                    self.signSelectedPin.axis = .vertical
                    self.signSelectedPin.distribution = .fill
                    self.signSelectedPin.spacing = dataMessages.count == 3 ? 1.5 : 2
                    
                    let heightSign: CGFloat = CGFloat((30 / dataMessages.count) - 1)
                    let widthSign: CGFloat = 2

                    for i in 0..<dataMessages.count {
                        let viewSign = UIView()
                        viewSign.backgroundColor = (i == (dataMessages.count - 1)) ? .white : .gray
                        viewSign.anchor(width: widthSign, height: heightSign)
                        viewSign.layer.cornerRadius = 1
                        viewSign.clipsToBounds = true
                        self.signSelectedPin.addArrangedSubview(viewSign)
                    }
                    if isPinned == -1 {
                        self.nextPinShowed = dataMessages.count - 1
                    } else if self.nextPinShowed != 0 {
                        if (self.nextPinShowed > isPinned) {
                            self.nextPinShowed-=1
                            same = true
                        } else if self.nextPinShowed == isPinned && dataMessages.count == 3 {
                            self.nextPinShowed-=2
                        }
                    } else if self.nextPinShowed != isPinned {
                        same = true
                    }
                } else if self.nextPinShowed != isPinned {
                    same = true
                }
                if !same{
                    let chat = Chat.getMessageFromId(message_id: dataMessages[dataMessages.count - 1][TypeDataMessage.message_id] as? String ?? "")
                    if chat.count > 0 {
                        let text = Utils.previewMessageText(chat: chat[0])
                        if let attributeText = text as? NSMutableAttributedString {
                            animateLabelTextChange(label: self.textPin, newText: attributeText.string)
                        }
                    }
                }
            }
        } else if self.containerPin.isDescendant(of: self.view) {
            self.containerPin.subviews.forEach({ $0.removeFromSuperview() })
            self.containerPin.removeFromSuperview()
            self.tableChatView.contentInset.top = 0
        }
    }
    
    @objc func viewPinTapped() {
        var dataMessagesPin = self.pinnedMessagesForBanner()
        dataMessagesPin.sort {
            let firstPinned = Int64($0[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
            let secondPinned = Int64($1[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
            return firstPinned < secondPinned
        }
        guard nextPinShowed < dataMessagesPin.count else {
            return
        }
        let obj = ObjectGesture()
        obj.message_id = dataMessagesPin[nextPinShowed][TypeDataMessage.message_id] as? String ?? ""
        // The pinned message can be older than what is loaded; contentMessageTapped works out
        // its row from dataMessages, so it has to be in there first.
        ensureMessageLoaded(messageId: obj.message_id)
        contentMessageTapped(obj)
        
        if dataMessagesPin.count > 0 {
            if nextPinShowed < dataMessagesPin.count - 1 {
                nextPinShowed+=1
            } else {
                nextPinShowed = 0
            }
            
            DispatchQueue.main.async {
                self.signSelectedPin.subviews.forEach({ $0.removeFromSuperview() })
                self.signSelectedPin.removeFromSuperview()
                self.containerPin.addSubview(self.signSelectedPin)
                self.signSelectedPin.anchor(left: self.containerPin.leftAnchor, paddingLeft: 8, centerY: self.containerPin.centerYAnchor, width: 2, height: 30)
                self.signSelectedPin.layer.cornerRadius = 1
                self.signSelectedPin.clipsToBounds = true
                self.signSelectedPin.alignment = .fill
                self.signSelectedPin.axis = .vertical
                self.signSelectedPin.distribution = .fill
                self.signSelectedPin.spacing = dataMessagesPin.count == 3 ? 1.5 : 2
                
                let heightSign: CGFloat = CGFloat((30 / dataMessagesPin.count) - 1)
                let widthSign: CGFloat = 2

                for i in 0..<dataMessagesPin.count {
                    let viewSign = UIView()
                    viewSign.backgroundColor = (i == self.nextPinShowed) ? .white : .gray
                    viewSign.anchor(width: widthSign, height: heightSign)
                    viewSign.layer.cornerRadius = 1
                    viewSign.clipsToBounds = true
                    self.signSelectedPin.addArrangedSubview(viewSign)
                }
                let chat = Chat.getMessageFromId(message_id: dataMessagesPin[dataMessagesPin.count - 1][TypeDataMessage.message_id] as? String ?? "")
                if chat.count > 0 {
                    let text = Utils.previewMessageText(chat: chat[0])
                    if let attributeText = text as? NSMutableAttributedString {
                        self.animateLabelTextChange(label: self.textPin, newText: attributeText.string)
                    }
                }
            }
        }
    }
    
    func animateLabelTextChange(label: UILabel, newText: String) {
        let animationDuration = 0.1
        UIView.animate(withDuration: animationDuration, animations: {
            label.transform = CGAffineTransform(translationX: 0, y: -10)
            label.alpha = 0
        }) { _ in
            // Change text after fade out
            label.attributedText = newText.richText(fontSize: 14, group_id: self.dataGroup["group_id"]  as? String ?? "")
            label.transform = CGAffineTransform(translationX: 0, y: 10)
            
            // Animate back to original position and fade in
            UIView.animate(withDuration: animationDuration) {
                label.transform = .identity
                label.alpha = 1
            }
        }
    }
    
    private func handleReply(indexPath: IndexPath, dataMessagesImage: [String: Any?] = [:], reffId: String = "") {
        // Guarded because the draft-restore path calls this with section 0 whether or not the
        // conversation has any messages to show.
        var dataMessages: [[String: Any?]] = []
        if indexPath.section < dataDates.count {
            dataMessages = self.messages(onDate: dataDates[indexPath.section])
        }
        if reffId.isEmpty {
            self.deleteReplyView()
            if dataMessagesImage.count != 0 {
                dataMessages = [dataMessagesImage]
            } else {
                self.textFieldSend.becomeFirstResponder()
            }
            self.reffId = dataMessages[indexPath.row]["message_id"] as? String
        } else {
            // Restoring a saved draft that was replying to something: the message being
            // quoted can be older than the page that is loaded, and without it the reply
            // preview would quietly disappear from the draft.
            ensureMessageLoaded(messageId: reffId)
            dataMessages = self.dataMessages.filter({ $0["message_id"]  as? String ?? "" == reffId })
            self.reffId = reffId
        }
        if dataMessages.count == 0  {
            self.deleteReplyView()
            return
        }
        let replyBarHeight = 50 + (self.offset() * 3)
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.constraintTopTextField.constant = self.constraintTopTextField.constant + replyBarHeight
            if self.contraintBottomMention.constant > 0 {
                self.contraintBottomMention.constant = self.contraintBottomMention.constant + self.heightTextFieldSend.constant
            }
            // Laid out first so the list already has its new height, then held in place - both
            // inside the same animation, so the content and the bar move together rather than
            // the list snapping first.
            self.view.layoutIfNeeded()
            self.keepScrollPosition(whenInputGrewBy: replyBarHeight)
        }, completion: nil)
        
        self.viewTextfield.addSubview(self.containerPreviewReply)
        self.containerPreviewReply.translatesAutoresizingMaskIntoConstraints = false
        self.containerPreviewReply.leadingAnchor.constraint(equalTo: self.viewTextfield.leadingAnchor).isActive = true
        self.containerPreviewReply.topAnchor.constraint(equalTo: self.viewTextfield.topAnchor).isActive = true
        if !self.containerLink.isDescendant(of: self.viewTextfield) {
            self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.textFieldSend.topAnchor)
        } else {
            self.bottomAnchorPreviewReply = self.containerPreviewReply.bottomAnchor.constraint(equalTo: self.containerLink.topAnchor)
        }
        self.bottomAnchorPreviewReply.isActive = true
        self.containerPreviewReply.trailingAnchor.constraint(equalTo: self.viewTextfield.trailingAnchor).isActive = true
        self.containerPreviewReply.backgroundColor = .secondaryColor
        // The preview is now the bottom-most thing the button must clear.
        self.refreshScrollToBottomButtonPlacement(animated: true)
        
        let leftReply = UIView()
        self.containerPreviewReply.addSubview(leftReply)
        leftReply.translatesAutoresizingMaskIntoConstraints = false
        leftReply.leadingAnchor.constraint(equalTo: self.viewTextfield.leadingAnchor).isActive = true
        leftReply.topAnchor.constraint(equalTo: self.containerPreviewReply.topAnchor).isActive = true
        leftReply.bottomAnchor.constraint(equalTo: self.containerPreviewReply.bottomAnchor).isActive = true
        leftReply.widthAnchor.constraint(equalToConstant: 3).isActive = true
        leftReply.backgroundColor = .orangeColor
        
        let titleReply = UILabel()
        self.containerPreviewReply.addSubview(titleReply)
        titleReply.translatesAutoresizingMaskIntoConstraints = false
        titleReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
        titleReply.topAnchor.constraint(equalTo: self.containerPreviewReply.topAnchor, constant: 10).isActive = true
        titleReply.font = UIFont.systemFont(ofSize: 12 + offset()).bold
        let idMe = User.getMyPin() as String?
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            titleReply.text = "You".localized()
        } else {
            if dataMessages[indexPath.row]["f_pin"] as? String != "-999" {
                let dataPerson = self.getDataProfile(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "", message_id: dataMessages[indexPath.row]["message_id"]  as? String ?? "")
                titleReply.text = dataPerson["name"]
            } else {
                titleReply.text = "Bot"
            }
        }
        titleReply.textColor = .orangeColor
        
        let contentReply = UILabel()
        self.containerPreviewReply.addSubview(contentReply)
        contentReply.translatesAutoresizingMaskIntoConstraints = false
        contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
        contentReply.topAnchor.constraint(equalTo: titleReply.bottomAnchor).isActive = true
        contentReply.trailingAnchor.constraint(equalTo: containerPreviewReply.trailingAnchor, constant: -20).isActive = true
        contentReply.font = UIFont.systemFont(ofSize: 10 + offset())
        let message_text = dataMessages[indexPath.row]["message_text"]  as? String ?? ""
        let attachment_flag = dataMessages[indexPath.row]["attachment_flag"]  as? String ?? ""
        let thumb_chat = dataMessages[indexPath.row]["thumb_id"]  as? String ?? ""
        let image_chat = dataMessages[indexPath.row]["image_id"]  as? String ?? ""
        let video_chat = dataMessages[indexPath.row]["video_id"]  as? String ?? ""
        let file_chat = dataMessages[indexPath.row]["file_id"]  as? String ?? ""
        if (attachment_flag == "0" && thumb_chat == "") {
            contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
        } else if (attachment_flag == "1" || image_chat != "") {
            if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                contentReply.text = "📷 Photo".localized()
            } else {
                contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
            }
        } else if (attachment_flag == "2" || video_chat != "") {
            if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                contentReply.text = "📹 Video".localized()
            } else {
                contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
            }
        } else if (attachment_flag == "6" || file_chat != ""){
            contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
        } else if (attachment_flag == "11") {
            contentReply.text = "❤️ Sticker"
        } else if attachment_flag == "27" {
            contentReply.text = "📄 " + "Live Streaming".localized()
        } else if attachment_flag == "26" {
            contentReply.text = "📄 " + "Seminar".localized()
        }
        contentReply.textColor = .gray
        
        let buttonCancelReply = UIButton(type: .custom)
        self.containerPreviewReply.addSubview(buttonCancelReply)
        buttonCancelReply.translatesAutoresizingMaskIntoConstraints = false
        buttonCancelReply.trailingAnchor.constraint(equalTo: self.containerPreviewReply.trailingAnchor, constant: -10).isActive = true
        buttonCancelReply.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor).isActive = true
        buttonCancelReply.setImage(UIImage(systemName: "xmark.circle" , withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)), for: .normal)
        buttonCancelReply.addTarget(nil, action: #selector(self.deleteReplyView), for: .touchUpInside)
        buttonCancelReply.backgroundColor = .clear
        buttonCancelReply.tintColor = .mainColor
        
        if (attachment_flag == "1" || attachment_flag == "2" || image_chat != "" || video_chat != "") {
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumb_chat)
                let image : UIImage? =  {
                    if let img = Nexilis.imageCache.object(forKey: thumb_chat as NSString) {
                        return img
                    }
                    else if let img = UIImage(contentsOfFile: thumbURL.path)?.resize(target: CGSize(width: 500, height: 500)) {
                        Nexilis.imageCache.setObject(img, forKey: thumb_chat as NSString)
                        return img
                    }
                    return nil
                }()
                //                let image = UIGraphicsRenderer.renderImageAt(url: thumbURL as NSURL, size: CGSize(width: 250, height: 250))
                let imageThumb = UIImageView(image: image)
                self.containerPreviewReply.addSubview(imageThumb)
                imageThumb.layer.cornerRadius = 2.0
                imageThumb.clipsToBounds = true
                imageThumb.translatesAutoresizingMaskIntoConstraints = false
                imageThumb.trailingAnchor.constraint(equalTo: buttonCancelReply.leadingAnchor, constant: -10).isActive = true
                imageThumb.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor).isActive = true
                imageThumb.widthAnchor.constraint(equalToConstant: 30).isActive = true
                imageThumb.heightAnchor.constraint(equalToConstant: 30).isActive = true
                
                if (attachment_flag == "2") {
                    let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                    imageThumb.addSubview(imagePlay)
                    imagePlay.clipsToBounds = true
                    imagePlay.translatesAutoresizingMaskIntoConstraints = false
                    imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                    imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                    imagePlay.widthAnchor.constraint(equalToConstant: 10).isActive = true
                    imagePlay.heightAnchor.constraint(equalToConstant: 10).isActive = true
                    imagePlay.tintColor = .white
                }
            }
        }
        if (attachment_flag == "11") {
            let imageSticker = UIImageView(image: UIImage(named: (message_text.component(1, separatedBy: "/")), in: Bundle.resourceBundle(for: Nexilis.self), with: nil))
            self.containerPreviewReply.addSubview(imageSticker)
            imageSticker.layer.cornerRadius = 2.0
            imageSticker.clipsToBounds = true
            imageSticker.translatesAutoresizingMaskIntoConstraints = false
            imageSticker.trailingAnchor.constraint(equalTo: buttonCancelReply.leadingAnchor, constant: -10).isActive = true
            imageSticker.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor).isActive = true
            imageSticker.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageSticker.heightAnchor.constraint(equalToConstant: 30).isActive = true
        }
    }
    
    func scrollToFirstSearchMessage(indexScroll: Int = 1) {
        if textSearch.count < 2 {
            return
        }
        titleSearchMatches.isHidden = false
        guard indexScroll >= 1, indexScroll <= searchMatchIds.count else {
            if searchMatchIds.isEmpty {
                titleSearchMatches.text = "Not found".localized()
                buttonUp.isEnabled = false
                buttonUp.tintColor = .gray
                buttonDown.isEnabled = false
                buttonDown.tintColor = .gray
            }
            return
        }
        let messageId = searchMatchIds[indexScroll - 1]
        // A hit outside the loaded window is fetched the same way a quoted message is. When it
        // had to be fetched the list underneath has just been rebuilt, so the jump is made
        // without animation - animating from a position that no longer means anything is what
        // looked like the screen jumping about.
        let wasLoaded = dataMessages.contains(where: { $0["message_id"] as? String == messageId })
        if !wasLoaded {
            ensureMessageLoaded(messageId: messageId)
        }
        guard let indexPath = indexPath(forMessageId: messageId),
              let message = dataMessages.first(where: { $0["message_id"] as? String == messageId }) else {
            return
        }
        lastScrollIdxSearch = indexScroll
        tableChatView.safeScrollToRow(at: indexPath, at: .middle, animated: wasLoaded)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let cell = self.tableChatView.cellForRow(at: indexPath), cell.contentView.subviews.count > 1 {
                let containerMessage = cell.contentView.subviews[1]
                let idMe = User.getMyPin() as String?
                if (message["f_pin"] as? String == idMe) {
                    containerMessage.backgroundColor = .blueBubbleColor.withAlphaComponent(0.3)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if (message["attachment_flag"] as? String == "11") {
                            containerMessage.backgroundColor = .clear
                        } else {
                            containerMessage.backgroundColor = .blueBubbleColor
                        }
                    }
                } else {
                    containerMessage.backgroundColor = .whiteBubbleColor.withAlphaComponent(0.3)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if (message["attachment_flag"] as? String == "11") {
                            containerMessage.backgroundColor = .clear
                        } else {
                            containerMessage.backgroundColor = .whiteBubbleColor
                        }
                    }
                }
            }
        }
        if countMatchesSearch != 0 {
            if countMatchesSearch > 1 {
                titleSearchMatches.text = "\(lastScrollIdxSearch) " + "of".localized() + " \(countMatchesSearch) " + "matches".localized()
            } else {
                titleSearchMatches.text = "\(countMatchesSearch) " + "matches".localized()
            }
        } else {
            titleSearchMatches.text = "Not found".localized()
        }
        if lastScrollIdxSearch == countMatchesSearch || countMatchesSearch == 0 {
            buttonUp.isEnabled = false
            buttonUp.tintColor = .gray
        } else {
            buttonUp.isEnabled = true
            buttonUp.tintColor = .mainColor
        }
        if countMatchesSearch == 0 || lastScrollIdxSearch == 1 || countMatchesSearch == 1 {
            buttonDown.isEnabled = false
            buttonDown.tintColor = .gray
        } else {
            buttonDown.isEnabled = true
            buttonDown.tintColor = .mainColor
        }
    }
    
//    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let indexPath = tableChatView.indexPathsForVisibleRows?.first
//        if indexPath != nil {
//            let headerRect = tableChatView.rectForHeader(inSection: indexPath!.section)
//            let isPinned = headerRect.origin.y <= scrollView.contentOffset.y
//            if listViewOnSection.count != 0 && listViewOnSection.count - 1 == indexPath!.section && indexPath!.row > 0 {
//                let sect = listViewOnSection.count - 1 < currentIndexpath!.section ? listViewOnSection.count - 1 : currentIndexpath!.section
//                let headerView = listViewOnSection[sect]
//                headerView.isHidden = true
//            }
//        }
//    }
//
//    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if !decelerate {
//            let indexPath = tableChatView.indexPathsForVisibleRows?.first
//            if indexPath != nil {
//                let headerRect = tableChatView.rectForHeader(inSection: indexPath!.section)
//                let isPinned = headerRect.origin.y <= scrollView.contentOffset.y
//                if listViewOnSection.count != 0 && listViewOnSection.count - 1 == indexPath!.section && isPinned {
//                    let sect = listViewOnSection.count - 1 < currentIndexpath!.section ? listViewOnSection.count - 1 : currentIndexpath!.section
//                    let headerView = listViewOnSection[sect]
//                    headerView.isHidden = true
//                }
//            }
//        }
//    }
}
    
extension EditorGroup: UISearchBarDelegate {
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timerSearch?.invalidate()
        if searchText.count > 1 {
            timerSearch = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {[self] _ in
                textSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                titleSearchMatches.isHidden = true
                // The hits come from the database, so nothing has to be loaded to search and
                // the reader stays exactly where they were reading. The count is the length of
                // that list, which means the "x of N" can never disagree with what the arrows
                // can actually reach.
                searchMatchIds = searchMatches(for: textSearch)
                countMatchesSearch = searchMatchIds.count
                lastScrollIdxSearch = 0
                tableChatView.reloadData()
                scrollToFirstSearchMessage()
            })
        }
    }
}
    

// MARK: - WhatsApp-style context menu for very long message bubbles

// Fix: EditorGroup, EditorPersonal and EditorStarMessages each build their own bubble menu
// but need the very same plumbing around it - hand the handlers out of UIAction, work out
// whether the bubble is too long for the system menu, and put up ChatBubbleContextMenu when
// it is. That plumbing lives here once; the three screens only have to hold the state it
// works on.
protocol ChatBubbleContextMenuPresenting: UIViewController {
    // Handlers of the actions in the menu currently being built, keyed by the identifier
    // chatMenuAction(...) stamps on each one. Cleared whenever the menu goes away - these
    // closures capture the view controller strongly.
    var contextMenuActionHandlers: [String: () -> Void] { get set }
    var contextMenuActionSeed: Int { get set }
    var longBubbleContextMenu: ChatBubbleContextMenu? { get set }
}

extension ChatBubbleContextMenuPresenting {
    // Fix: every UIAction in the bubble menu is now built through this instead of
    // UIAction(...) directly, purely so the handler stays reachable afterwards: UIAction
    // exposes no way to read (let alone invoke) the closure it was created with, and the
    // WhatsApp-style menu in ChatBubbleContextMenu draws its own rows and therefore needs
    // to be able to run the very same handlers. The action gets an explicit identifier
    // and that identifier is what maps back to the closure here. Cleared on every new
    // long-press (see configurationForMenuAtLocation) - these closures capture self
    // strongly, exactly like they always have as UIAction handlers, so they must not be
    // kept around any longer than the menu they belong to.
    func chatMenuAction(title: String, image: UIImage? = nil, attributes: UIMenuElement.Attributes = [], handler: @escaping UIActionHandler) -> UIAction {
        contextMenuActionSeed += 1
        let identifier = UIAction.Identifier("nexilis.chat.menu.\(contextMenuActionSeed)")
        let action = UIAction(title: title, image: image, identifier: identifier, attributes: attributes, handler: handler)
        contextMenuActionHandlers[identifier.rawValue] = { handler(action) }
        return action
    }

    // Fix: flattens the UIMenu tree that gets handed to UIKit into the plain model
    // ChatBubbleContextMenu renders. Inline sections (mainMenu) are spliced in place, the
    // way UIKit itself displays them; a real submenu ("More...") stays a submenu.
    func chatContextMenuItems(from elements: [UIMenuElement]) -> [ChatContextMenuItem] {
        var items: [ChatContextMenuItem] = []
        for element in elements {
            if let action = element as? UIAction {
                items.append(ChatContextMenuItem(title: action.title,
                                                 image: action.image,
                                                 isDestructive: action.attributes.contains(.destructive),
                                                 children: [],
                                                 handler: contextMenuActionHandlers[action.identifier.rawValue]))
            } else if let menu = element as? UIMenu {
                let children = chatContextMenuItems(from: menu.children)
                if menu.options.contains(.displayInline) {
                    items.append(contentsOf: children)
                } else {
                    // A UIMenu carries no image of its own, so the submenu row would come
                    // out bare - it gets the ellipsis the system menu uses for one.
                    items.append(ChatContextMenuItem(title: menu.title,
                                                     image: menu.image ?? UIImage(systemName: "ellipsis.circle"),
                                                     isDestructive: false,
                                                     children: children,
                                                     handler: nil))
                }
            }
        }
        return items
    }

    // Fix: the bubble menu, for every message - the delegate returns nil so no system menu
    // appears (the same trick the link long-press already uses) and this goes up instead.
    //
    // It started out as the long-message case only: UIKit always lays its menu out BELOW
    // the preview and shrinks the preview to whatever room is left, which turns a wall of
    // text into an unreadable sliver, so those needed a menu that floats over the message
    // instead. Short bubbles now come here too, for the submenu: UIKit gives no control
    // whatsoever over how it presents one ("More..." gets a back-button header nobody
    // asked for), and the only way for "More..." to behave the same everywhere is for the
    // menu to be the same everywhere. ChatBubbleContextMenu lays itself out to match -
    // menu under the bubble when both fit, floating over it when they do not.
    func presentBubbleContextMenu(for bubble: UIView, elements: [UIMenuElement]) -> Bool {
        guard let host = bubble.window else {
            return false
        }
        let bubbleSize = bubble.bounds.size
        guard bubbleSize.width > 1, bubbleSize.height > 1 else {
            return false
        }
        // Secure-folder bubbles live inside UITextField's secure canvas view (see
        // SecureField.secureContainer), which UIKit deliberately keeps out of every kind
        // of snapshot - rendering one would yield a blank sheet, so those keep the system
        // menu no matter how long they are.
        if type(of: bubble).description().contains("CanvasView") {
            return false
        }
        let items = chatContextMenuItems(from: elements)
        guard !items.isEmpty else {
            return false
        }
        longBubbleContextMenu?.dismiss(animated: false)
        guard let overlay = ChatBubbleContextMenu(bubble: bubble, items: items) else {
            return false
        }
        overlay.onDismiss = { [weak self] in
            self?.longBubbleContextMenu = nil
            // These capture self strongly; the overlay is gone, so nothing should still be
            // holding them (the row that was tapped keeps its own copy until it has run).
            self?.contextMenuActionHandlers.removeAll()
        }
        longBubbleContextMenu = overlay
        // Fix: the touch that summoned this menu is still live on the bubble underneath, and
        // its tap recognizers are still tracking it. UIKit used to cancel them for us when it
        // put its own menu up - now that the menu is ours, lifting the finger was reaching
        // the thumbnail's tap recognizer and opening the photo (or playing the video) behind
        // the menu. Cancelling them here is what the system menu did on our behalf before.
        cancelPendingTouches(in: bubble)
        overlay.present(in: host)
        return true
    }

    // Toggling isEnabled cancels whatever a recognizer is currently tracking and makes it
    // ignore the rest of that touch sequence, while leaving it armed for the next one. Only
    // taps: the long-press recognizers are what put the menu up in the first place, and they
    // finish on their own when the finger lifts. Buttons inside the bubble - the audio play
    // button - track touches themselves rather than through a recognizer, and would fire on
    // touch-up for the same reason, so their tracking is ended too.
    private func cancelPendingTouches(in view: UIView) {
        for recognizer in view.gestureRecognizers ?? [] where recognizer is UITapGestureRecognizer && recognizer.isEnabled {
            recognizer.isEnabled = false
            recognizer.isEnabled = true
        }
        if let control = view as? UIControl, control.isTracking {
            control.cancelTracking(with: nil)
        }
        for subview in view.subviews {
            cancelPendingTouches(in: subview)
        }
    }

}


// Fix: the plain model behind ChatBubbleContextMenu's hand-drawn rows. It exists because
// UIAction keeps the closure it was built with private - there is no way to read it back,
// so EditorGroup.chatMenuAction(...) registers each handler as it creates the action and
// EditorGroup.chatContextMenuItems(from:) pairs the two up again into these.
struct ChatContextMenuItem {
    let title: String
    let image: UIImage?
    let isDestructive: Bool
    // Non-empty only for a real submenu ("More..."); tapping such a row swaps the panel
    // contents for its children instead of running anything.
    let children: [ChatContextMenuItem]
    let handler: (() -> Void)?
}

// Fix: the bubble menu for every message, replacing UIKit's own - see
// ChatBubbleContextMenuPresenting.presentBubbleContextMenu(for:elements:) for why UIKit's
// could not be kept. It matches the system menu it stands in for down to the measured
// point (metrics below), and lays itself out the same way for an ordinary message: menu
// under the bubble, bubble left where it is. For a message too long to fit alongside its
// menu it does what UIKit cannot - the bubble stays at natural, readable size and the menu
// floats over it, WhatsApp-style, instead of the whole message being scaled into a sliver.
final class ChatBubbleContextMenu: UIView, UIGestureRecognizerDelegate, UIScrollViewDelegate {

    // Fix: every number below was measured off a screenshot of the real system menu in
    // this same chat, so this reads as the same control it replaced: 250pt wide, 42pt rows, 10pt of padding at each end of the platter, a
    // section separator inset 24pt sitting in a 10 + 1 + 10 gap, titles at 65pt when the
    // row has an icon and 30pt when it does not.
    private enum Metrics {
        static let bubbleTopMargin: CGFloat = 12
        static let panelWidth: CGFloat = 250
        static let panelCornerRadius: CGFloat = 26
        static let rowHeight: CGFloat = 42
        static let panelVerticalPadding: CGFloat = 10
        static let sectionSpacing: CGFloat = 10
        static let separatorHeight: CGFloat = 1
        static let separatorInset: CGFloat = 24
        static let screenMargin: CGFloat = 16
        // Gap the system context menu leaves between its preview and the menu itself.
        static let bubbleMenuSpacing: CGFloat = 8
        static let iconLeading: CGFloat = 29
        static let iconSize: CGFloat = 22
        static let iconPointSize: CGFloat = 19
        static let titleLeading: CGFloat = 65
        static let titleLeadingWithoutIcon: CGFloat = 30
        // Fix: the two offsets the menu hides/comes back at are deliberately different -
        // with a single one, a finger resting right on the boundary would flicker the menu
        // in and out. Coming back only at the very top also makes the rule easy to feel:
        // the menu belongs to the top of the message, scroll away from it and it gets out
        // of the way of the text it was covering.
        static let panelHideOffset: CGFloat = 24
        static let panelShowOffset: CGFloat = 2
    }

    // Measured off the system menu: its rim is not a dark hairline at all, it is a bright
    // one - the highlight along the edge of the glass. On a light theme it reads as almost
    // pure white against whatever is behind the platter.
    private static let panelBorderColor = UIColor { traits in
        return traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.18)
            : UIColor.white.withAlphaComponent(0.90)
    }

    // Also measured: ~8% black over the platter, i.e. far lighter than UIColor.separator.
    private static let separatorColor = UIColor { traits in
        return traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.black.withAlphaComponent(0.09)
    }

    private enum RowAction {
        case back
        case submenu(Int)
        case run(() -> Void)
        case none
    }

    var onDismiss: (() -> Void)?

    private let backdrop = UIVisualEffectView(effect: nil)
    private let bubbleScrollView = UIScrollView()
    private let bubbleView = UIImageView()
    // Fix: the blur has to be clipped to the rounded corners, a drop shadow must NOT be
    // clipped - so they cannot live on the same view. The container carries the shadow
    // (and, being the outer view, the frame/alpha/transform everything else animates).
    private let panelContainer = UIView()
    private let panel = UIVisualEffectView(effect: nil)
    private let panelTint = UIView()
    private let panelScrollView = UIScrollView()
    private let rowsContainer = UIView()

    private let bubbleSize: CGSize
    private let bubbleOriginFrame: CGRect
    private let alignRight: Bool
    private let rootItems: [ChatContextMenuItem]
    private var displayedItems: [ChatContextMenuItem]
    // Fix: the submenu is left by tapping the very same row that opened it, drawn again at
    // the bottom of the submenu - so this keeps hold of that row rather than a plain
    // "is a submenu showing" flag.
    private var submenuParent: ChatContextMenuItem?
    private var rowActions: [RowAction] = []
    private var rowsHeight: CGFloat = 0
    private var isDismissing = false
    private var isPanelHidden = false
    // Set in layoutSubviews - see the placement comment there.
    private var placesPanelBelowBubble = false

    init?(bubble: UIView, items: [ChatContextMenuItem]) {
        guard let window = bubble.window,
              let snapshot = ChatBubbleContextMenu.snapshotImage(of: bubble) else {
            return nil
        }
        bubbleSize = bubble.bounds.size
        bubbleOriginFrame = bubble.convert(bubble.bounds, to: window)
        // Which side the menu hangs off is just which side of the screen the bubble is on
        // - outgoing messages sit right, incoming sit left, same as WhatsApp.
        alignRight = bubbleOriginFrame.midX > window.bounds.midX
        rootItems = items
        displayedItems = items
        super.init(frame: window.bounds)

        bubbleView.image = snapshot
        setUp()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setUp() {
        backgroundColor = .clear

        addSubview(backdrop)

        bubbleScrollView.showsVerticalScrollIndicator = false
        bubbleScrollView.showsHorizontalScrollIndicator = false
        bubbleScrollView.contentInsetAdjustmentBehavior = .never
        bubbleScrollView.backgroundColor = .clear
        bubbleScrollView.delegate = self
        bubbleScrollView.addSubview(bubbleView)
        addSubview(bubbleScrollView)

        // Fix: the thinnest material there is - the menu sits directly on top of the bubble,
        // and anything thicker came out looking like just more white bubble. This is what
        // gives the system context menu its glass: the content underneath stays visible
        // through the blur instead of being painted over.
        panel.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        panel.layer.cornerRadius = Metrics.panelCornerRadius
        panel.layer.cornerCurve = .continuous
        panel.clipsToBounds = true
        // ...and on top of it a wash in the direction the system platter goes: frosted
        // WHITE on a light theme (bright, not grey - the menu should read lighter than the
        // bubble it covers), a dark wash on a dark theme so the rows stay legible. Partial
        // alpha on purpose - it tints the glass rather than replacing it. 0.38 is what
        // lands on the brightness the system menu measured at over the same chat; this is
        // the one number to touch if the platter ever wants to be lighter or darker.
        panelTint.backgroundColor = UIColor { traits in
            return traits.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.18)
                : UIColor.white.withAlphaComponent(0.38)
        }
        panelTint.isUserInteractionEnabled = false
        panel.contentView.addSubview(panelTint)

        panelContainer.backgroundColor = .clear
        // The shadow does most of the work of separating menu from bubble - without it a
        // translucent panel on top of a light bubble has no edge at all.
        panelContainer.layer.shadowColor = UIColor.black.cgColor
        panelContainer.layer.shadowOpacity = 0.14
        panelContainer.layer.shadowRadius = 18
        panelContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        // Plus the bright rim along the edge of the glass, which is what actually draws the
        // platter's outline in the system menu - 2px, so it stays a rim and not a frame.
        // Resolved for real in present(in:): a CGColor cannot be dynamic, and up here there
        // is no window to resolve it against yet.
        panel.layer.borderWidth = 2.0 / UIScreen.main.scale
        panelScrollView.showsVerticalScrollIndicator = false
        panelScrollView.contentInsetAdjustmentBehavior = .never
        panelScrollView.addSubview(rowsContainer)
        panel.contentView.addSubview(panelScrollView)
        panelContainer.addSubview(panel)
        addSubview(panelContainer)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tap.delegate = self
        addGestureRecognizer(tap)

        buildRows()
    }

    // MARK: - Rows

    private func buildRows() {
        rowsContainer.subviews.forEach({ $0.removeFromSuperview() })
        rowActions.removeAll()

        var rows: [(ChatContextMenuItem, RowAction, Bool)] = []
        for (index, item) in displayedItems.enumerated() {
            // A submenu row ("More...") is its own section in the system menu too, so it
            // keeps the hairline that separated it there.
            let startsSection = !item.children.isEmpty
            let action: RowAction
            if !item.children.isEmpty {
                action = .submenu(index)
            } else if let handler = item.handler {
                action = .run(handler)
            } else {
                action = .none
            }
            rows.append((item, action, startsSection))
        }
        // Fix: no "Back" row - the way out of a submenu is the identical "More..." row it
        // was opened from, in the identical place (own section, bottom of the platter), so
        // every level of the menu looks the same and the row just toggles.
        if let parent = submenuParent {
            rows.append((parent, .back, true))
        }

        // The platter breathes at both ends - the system menu leaves 10pt above its first
        // row and below its last one, and without that the rows look crammed against the
        // rounded corners.
        var y: CGFloat = Metrics.panelVerticalPadding
        let width = panelWidthForCurrentBounds()
        for (item, action, startsSection) in rows {
            if startsSection && y > Metrics.panelVerticalPadding {
                // 10pt - hairline - 10pt, and inset from both edges, exactly like the
                // section separator in the system menu.
                y += Metrics.sectionSpacing
                let separator = UIView(frame: CGRect(x: Metrics.separatorInset,
                                                     y: y,
                                                     width: max(0, width - Metrics.separatorInset * 2),
                                                     height: Metrics.separatorHeight))
                separator.backgroundColor = ChatBubbleContextMenu.separatorColor
                separator.autoresizingMask = [.flexibleWidth]
                rowsContainer.addSubview(separator)
                y += Metrics.separatorHeight + Metrics.sectionSpacing
            }
            let row = makeRow(item)
            row.frame = CGRect(x: 0, y: y, width: width, height: Metrics.rowHeight)
            row.autoresizingMask = [.flexibleWidth]
            row.tag = rowActions.count
            row.addTarget(self, action: #selector(handleRowTap(_:)), for: .touchUpInside)
            rowsContainer.addSubview(row)
            rowActions.append(action)
            y += Metrics.rowHeight
        }
        rowsHeight = y + Metrics.panelVerticalPadding
        setNeedsLayout()
    }

    private func makeRow(_ item: ChatContextMenuItem) -> UIControl {
        let row = MenuRow(frame: .zero)
        row.titleLabel.text = item.title
        row.iconView.image = item.image
        row.hasIcon = item.image != nil
        let tint: UIColor = item.isDestructive ? .systemRed : .label
        row.titleLabel.textColor = tint
        row.iconView.tintColor = tint
        return row
    }

    private func panelWidthForCurrentBounds() -> CGFloat {
        return min(Metrics.panelWidth, bounds.width - Metrics.screenMargin * 2)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        backdrop.frame = bounds

        let safeTop = safeAreaInsets.top > 0 ? safeAreaInsets.top : 20
        let safeBottom = safeAreaInsets.bottom
        let topLimit = safeTop + Metrics.bubbleTopMargin
        let bottomLimit = bounds.height - max(safeBottom, Metrics.screenMargin)

        let panelWidth = panelWidthForCurrentBounds()
        let maxPanelHeight = max(Metrics.rowHeight * 3, bottomLimit - topLimit - 80)
        let panelHeight = min(rowsHeight, maxPanelHeight)

        // Fix: two placements, picked by whether the whole bubble and the whole menu fit on
        // screen together.
        //
        // They do (an ordinary short message): the menu goes directly UNDER the bubble and
        // the bubble stays where it is in the chat, exactly like the system context menu -
        // it only gets pushed up if the menu would not otherwise fit below it.
        //
        // They do not (a wall of text): the bubble goes to the top at full size and the
        // menu floats over its lower half, anchored to the bottom of the screen - the
        // WhatsApp behaviour. Scrolling the message then slides the menu out of the way,
        // see scrollViewDidScroll(_:).
        let fitsTogether = bubbleSize.height + Metrics.bubbleMenuSpacing + panelHeight <= bottomLimit - topLimit
        placesPanelBelowBubble = fitsTogether

        let bubbleTop: CGFloat
        let bubbleViewportHeight: CGFloat
        let panelY: CGFloat
        if fitsTogether {
            let highestTop = bottomLimit - panelHeight - Metrics.bubbleMenuSpacing - bubbleSize.height
            bubbleTop = min(max(bubbleOriginFrame.minY, topLimit), highestTop)
            bubbleViewportHeight = bubbleSize.height
            panelY = bubbleTop + bubbleSize.height + Metrics.bubbleMenuSpacing
        } else {
            bubbleTop = topLimit
            bubbleViewportHeight = max(0, bounds.height - bubbleTop)
            panelY = bottomLimit - panelHeight
        }

        // Frames have to be assigned with the entrance/exit transform temporarily undone -
        // UIView.frame is meaningless while a transform is applied.
        withoutTransform(bubbleScrollView) {
            bubbleScrollView.frame = CGRect(x: bubbleOriginFrame.minX,
                                            y: bubbleTop,
                                            width: bubbleSize.width,
                                            height: bubbleViewportHeight)
        }
        bubbleView.frame = CGRect(origin: .zero, size: bubbleSize)
        bubbleScrollView.contentSize = bubbleSize
        bubbleScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: fitsTogether ? 0 : safeBottom, right: 0)
        bubbleScrollView.isScrollEnabled = bubbleSize.height > bubbleScrollView.bounds.height

        // The menu grows out of the corner nearest the bubble - its top corner when it
        // hangs below the bubble, its bottom corner when it sits over one.
        let anchorPoint = CGPoint(x: alignRight ? 1.0 : 0.0, y: fitsTogether ? 0.0 : 1.0)
        if panelContainer.layer.anchorPoint != anchorPoint {
            panelContainer.layer.anchorPoint = anchorPoint
        }
        var panelX = alignRight ? bubbleOriginFrame.maxX - panelWidth : bubbleOriginFrame.minX
        panelX = min(max(panelX, Metrics.screenMargin), bounds.width - Metrics.screenMargin - panelWidth)
        withoutTransform(panelContainer) {
            panelContainer.frame = CGRect(x: panelX,
                                          y: panelY,
                                          width: panelWidth,
                                          height: panelHeight)
        }
        panel.frame = panelContainer.bounds
        panelContainer.layer.shadowPath = UIBezierPath(roundedRect: panelContainer.bounds,
                                                       cornerRadius: Metrics.panelCornerRadius).cgPath
        panelTint.frame = panel.contentView.bounds
        panelScrollView.frame = panel.contentView.bounds
        rowsContainer.frame = CGRect(x: 0, y: 0, width: panelWidth, height: rowsHeight)
        panelScrollView.contentSize = CGSize(width: panelWidth, height: rowsHeight)
        panelScrollView.isScrollEnabled = rowsHeight > panelHeight
    }

    private func withoutTransform(_ view: UIView, _ body: () -> Void) {
        let transform = view.transform
        view.transform = .identity
        body()
        view.transform = transform
    }

    // MARK: - Present / dismiss

    func present(in host: UIView) {
        frame = host.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(self)
        // Now that there is a window to inherit traits from, the hairline can be resolved
        // for the appearance actually in use.
        panel.layer.borderColor = ChatBubbleContextMenu.panelBorderColor.resolvedColor(with: traitCollection).cgColor
        layoutIfNeeded()

        // The bubble starts exactly where the real one is in the chat and slides into
        // place, so the message never appears to jump to somewhere it never was.
        bubbleScrollView.transform = CGAffineTransform(translationX: 0,
                                                       y: bubbleOriginFrame.minY - bubbleScrollView.frame.minY)
        panelContainer.alpha = 0
        panelContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: [.allowUserInteraction], animations: {
            self.backdrop.effect = UIBlurEffect(style: .systemThinMaterial)
            self.bubbleScrollView.transform = .identity
        })
        UIView.animate(withDuration: 0.22, delay: 0.06, options: [.allowUserInteraction, .curveEaseOut], animations: {
            self.panelContainer.alpha = 1
            self.panelContainer.transform = .identity
        })
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        guard !isDismissing else {
            return
        }
        isDismissing = true
        let finish: () -> Void = { [weak self] in
            self?.removeFromSuperview()
            self?.onDismiss?()
            completion?()
        }
        guard animated else {
            finish()
            return
        }
        // Sliding back to where the bubble came from only makes sense while the preview is
        // still at the top of the message; once it has been scrolled, that position no
        // longer corresponds to anything on screen, so it just fades.
        let returnsHome = bubbleScrollView.contentOffset.y <= 0.5
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
            self.backdrop.effect = nil
            self.panelContainer.alpha = 0
            self.panelContainer.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.bubbleScrollView.alpha = 0
            if returnsHome {
                self.bubbleScrollView.transform = CGAffineTransform(translationX: 0,
                                                                    y: self.bubbleOriginFrame.minY - self.bubbleScrollView.frame.minY)
            }
        }, completion: { _ in
            finish()
        })
    }

    // MARK: - Actions

    @objc private func handleBackgroundTap() {
        dismiss(animated: true)
    }

    @objc private func handleRowTap(_ sender: UIControl) {
        guard sender.tag >= 0, sender.tag < rowActions.count else {
            return
        }
        switch rowActions[sender.tag] {
        case .back:
            submenuParent = nil
            displayedItems = rootItems
            swapRows()
        case .submenu(let index):
            guard index < displayedItems.count else {
                return
            }
            submenuParent = displayedItems[index]
            displayedItems = displayedItems[index].children
            swapRows()
        case .run(let handler):
            // The handler runs only once the overlay is gone: several of them push view
            // controllers or start a selection session, and neither should happen while a
            // full-screen overlay is still sitting on top of the chat.
            dismiss(animated: true, completion: handler)
        case .none:
            dismiss(animated: true)
        }
    }

    private func swapRows() {
        UIView.transition(with: panel, duration: 0.2, options: [.transitionCrossDissolve], animations: {
            self.buildRows()
            self.layoutIfNeeded()
        })
    }

    // MARK: - Reading the message underneath the menu

    // Fix: the menu deliberately covers the lower part of the bubble, which is fine for
    // picking an action but in the way the moment you actually want to read the message.
    // So it steps aside as soon as the preview is scrolled down, and comes back once the
    // message is scrolled all the way back to the top - the position it was anchored to
    // in the first place.
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === bubbleScrollView, !isDismissing else {
            return
        }
        // Only when the menu is actually covering the message. Below a short bubble it
        // covers nothing, and there is nothing to scroll away from either.
        guard !placesPanelBelowBubble else {
            return
        }
        let offset = scrollView.contentOffset.y
        if !isPanelHidden && offset > Metrics.panelHideOffset {
            setPanelHidden(true)
        } else if isPanelHidden && offset <= Metrics.panelShowOffset {
            setPanelHidden(false)
        }
    }

    private func setPanelHidden(_ hidden: Bool) {
        guard hidden != isPanelHidden else {
            return
        }
        isPanelHidden = hidden
        // While it is out of the way it must not swallow taps either - see
        // gestureRecognizer(_:shouldReceive:), which lets a tap in that area dismiss.
        panelContainer.isUserInteractionEnabled = !hidden
        // beginFromCurrentState so flicking up and straight back down picks up wherever
        // the previous animation had got to instead of snapping.
        UIView.animate(withDuration: hidden ? 0.18 : 0.22,
                       delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState, hidden ? .curveEaseIn : .curveEaseOut],
                       animations: {
            self.panelContainer.alpha = hidden ? 0 : 1
            // Shrinks towards the corner it grew out of, same as the entrance.
            self.panelContainer.transform = hidden ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity
        })
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Tapping the bubble (or the dimmed chat behind it) dismisses; tapping the menu
        // itself must reach the rows - unless it has stepped aside for scrolling, in which
        // case that area is just more bubble.
        if isPanelHidden {
            return true
        }
        return !panelContainer.frame.contains(touch.location(in: self))
    }

    // MARK: - Snapshot

    private static func snapshotImage(of view: UIView) -> UIImage? {
        let size = view.bounds.size
        guard size.width > 1, size.height > 1 else {
            return nil
        }
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        // A wall of text is easily a few thousand points tall, and at 3x that turns into a
        // 100MB+ bitmap - so past a sane pixel budget the scale gets dialled back. Only the
        // extreme messages ever hit this, and they are the ones being skimmed anyway.
        let maxPixels: CGFloat = 12_000_000
        let pixels = size.width * size.height * format.scale * format.scale
        if pixels > maxPixels {
            format.scale = max(1.0, format.scale * sqrt(maxPixels / pixels))
        }
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            // layer.render, not drawHierarchy: most of a long bubble is scrolled off screen
            // and drawHierarchy(afterScreenUpdates: false) can come back blank for parts the
            // render server never had to draw. Walking the layer tree by hand always draws
            // everything, which is exactly what a full-length snapshot needs.
            view.layer.render(in: context.cgContext)
        }
    }

    // MARK: - Row

    private final class MenuRow: UIControl {
        let titleLabel = UILabel()
        let iconView = UIImageView()
        // A row with no icon pulls its title over to where the icon would have started -
        // that is what the system menu does with an icon-less row.
        var hasIcon = true

        private let highlightView = UIView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            highlightView.backgroundColor = UIColor.label.withAlphaComponent(0.1)
            highlightView.alpha = 0
            highlightView.isUserInteractionEnabled = false
            addSubview(highlightView)

            titleLabel.font = .systemFont(ofSize: 17)
            titleLabel.isUserInteractionEnabled = false
            addSubview(titleLabel)

            // .center with an explicit symbol configuration, not .scaleAspectFit: the icons
            // must all be drawn at one size (like a font), not stretched to whatever box
            // each one happens to be given.
            iconView.contentMode = .center
            iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: Metrics.iconPointSize, weight: .regular)
            iconView.isUserInteractionEnabled = false
            addSubview(iconView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isHighlighted: Bool {
            didSet {
                highlightView.alpha = isHighlighted ? 1 : 0
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            highlightView.frame = bounds
            iconView.frame = CGRect(x: Metrics.iconLeading,
                                    y: (bounds.height - Metrics.iconSize) / 2.0,
                                    width: Metrics.iconSize,
                                    height: Metrics.iconSize)
            let titleX = hasIcon ? Metrics.titleLeading : Metrics.titleLeadingWithoutIcon
            titleLabel.frame = CGRect(x: titleX,
                                      y: 0,
                                      width: max(0, bounds.width - titleX - 12),
                                      height: bounds.height)
        }
    }
}

// MARK: - Transfers

extension EditorGroup {
    // Fix: a transfer reports back long after it was started, and the index path it was
    // started from is only good at that one moment - a message arriving or being deleted
    // shifts it, and leaving and re-entering the chat rebuilds the table from scratch. So
    // the row is looked up again, by the file the transfer is for, every time it reports.
    func indexPathForMessage(withFileNamed name: String) -> IndexPath? {
        guard !name.isEmpty else {
            return nil
        }
        let fileKeys = ["image_id", "video_id", "file_id", "audio_id", "thumb_id", "gif_id"]
        var messageId: String?
        if let index = dataMessages.lastIndex(where: { message in
            return fileKeys.contains(where: { (message[$0] as? String ?? "") == name })
        }) {
            messageId = dataMessages[index]["message_id"] as? String
        } else {
            // Fix: a collage stands for several messages and only its first one is still a row -
            // the others were taken out of the list when they were gathered into it. A picture
            // arriving for any of the others found no row to redraw, so it stayed behind its
            // blur until the chat was opened again. The row to redraw is the collage's own.
            messageId = groupImages.first(where: { _, images in
                images.contains(where: { image in
                    fileKeys.contains(where: { (image.dataMessage[$0] as? String ?? "") == name })
                })
            })?.key
        }
        guard let messageId = messageId,
              let index = dataMessages.lastIndex(where: { ($0["message_id"] as? String) == messageId }),
              let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"] as? String ?? ""),
              let row = messages(onDate: dataDates[section]).firstIndex(where: { ($0["message_id"] as? String) == messageId }) else {
            return nil
        }
        return IndexPath(row: row, section: section)
    }

    // Keeps the "3,4 MB / 12 MB" caption beside a progress ring current. Does nothing when
    // the message is not on screen - cellForRow fills the caption in when it comes back.
    func updateTransferSize(forFileNamed name: String) {
        guard let indexPath = indexPathForMessage(withFileNamed: name),
              let cell = tableChatView.cellForRow(at: indexPath) else {
            return
        }
        ChatTransferRing.updateSizeText(forFileNamed: name, in: cell)
    }

    // Reloads the row a transfer belongs to, if it is still on screen at all. Safe to call
    // from a download that outlived the screen which started it.
    func reloadMessageRow(withFileNamed name: String) {
        EditorGroup.transferTick += 1
        guard Thread.isMainThread else {
            // Transfers finish on whatever thread carried them; the table is the main thread's.
            DispatchQueue.main.async { [weak self] in
                self?.reloadMessageRow(withFileNamed: name)
            }
            return
        }
        guard let indexPath = indexPathForMessage(withFileNamed: name),
              indexPath.section < tableChatView.numberOfSections,
              indexPath.row < tableChatView.numberOfRows(inSection: indexPath.section) else {
            return
        }
        // The row has to exist on both sides. The table is told about changes a moment after the
        // list itself changes, so between the two it can hold a row the list no longer has -
        // asking it to redraw that one draws a blank.
        guard indexPath.section < dataDates.count,
              indexPath.row < messages(onDate: dataDates[indexPath.section]).count else {
            return
        }
        tableChatView.reloadRows(at: [indexPath], with: .none)
    }
}

// MARK: - Download progress ring

// Fix: this ring used to be built by hand inside contentMessageTapped, which meant it only
// ever existed on the one cell instance that had been tapped: scroll it out of view and the
// recycled cell came back without it, leave the chat and come back and it was gone for good
// - while the transfer itself carried on. Drawing it from cellForRow instead makes it a
// function of the transfer's state, so whatever cell is showing that message draws the ring,
// at the progress the transfer has actually reached.
public enum ChatTransferRing {

    // The progress layer is named so it can be found again on whatever cell is showing the
    // message when an update arrives, without having to guess at subview indexes.
    static let layerName = "nexilis.transfer.progress"

    // The size caption is looked up by tag for the same reason the layer is looked up by
    // name: whichever cell happens to be showing the message has to be updatable without
    // anyone holding on to the view.
    static let sizeLabelTag = 748_213

    private static let size: CGFloat = 50
    private static let lineWidth: CGFloat = 10

    /// "3,4 MB / 12 MB" for a transfer in flight, or nil when its size is not known yet.
    static func sizeText(forFileNamed name: String) -> String? {
        guard let bytes = TransferBytes.get(name: name), bytes.total > 0 else {
            return nil
        }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        // Both halves in the same unit, so the two numbers can be compared at a glance.
        formatter.allowedUnits = bytes.total >= 1_000_000 ? [.useMB] : [.useKB]
        let done = formatter.string(fromByteCount: max(0, min(bytes.completed, bytes.total)))
        let total = formatter.string(fromByteCount: bytes.total)
        return "\(done) / \(total)"
    }

    /// The caption itself: a dark chip, because it sits over photo thumbnails of any colour.
    /// `chromeless` drops the chip background, for a surface that is already dark enough on
    /// its own - the file bubble's strip.
    @discardableResult
    static func addSizeLabel(to container: UIView, fileName: String, chromeless: Bool = false) -> UIView {
        let chip = UIView()
        chip.backgroundColor = chromeless ? .clear : .black.withAlphaComponent(0.45)
        chip.layer.cornerRadius = 8
        chip.clipsToBounds = true
        container.addSubview(chip)
        chip.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: chromeless ? .regular : .semibold)
        label.textColor = chromeless ? .white.withAlphaComponent(0.75) : .white
        label.textAlignment = .center
        label.tag = sizeLabelTag
        label.text = sizeText(forFileNamed: fileName)
        chip.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        let inset: CGFloat = chromeless ? 0 : 6
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: chip.topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: chip.bottomAnchor, constant: -2),
            label.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: inset),
            label.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -inset)
        ])
        // Nothing to show yet - it stays out of the way until the first byte count arrives,
        // and updateSizeText will bring it back.
        chip.isHidden = label.text == nil
        return chip
    }

    public static func add(to container: UIView, fileName: String, progress: Double) {
        let ring = UIView()
        ring.backgroundColor = .clear
        container.addSubview(ring)
        ring.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ring.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            ring.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ring.widthAnchor.constraint(equalToConstant: size),
            ring.heightAnchor.constraint(equalToConstant: size)
        ])

        let circlePath = UIBezierPath(arcCenter: CGPoint(x: size / 2, y: size / 2),
                                      radius: size / 2 - 5,
                                      startAngle: -(.pi / 2),
                                      endAngle: .pi * 2,
                                      clockwise: true)
        let track = CAShapeLayer()
        track.path = circlePath.cgPath
        track.fillColor = UIColor.clear.cgColor
        track.lineWidth = lineWidth
        track.strokeColor = UIColor.mentionColor.withAlphaComponent(0.3).cgColor
        ring.layer.addSublayer(track)

        let loading = CAShapeLayer()
        loading.path = circlePath.cgPath
        loading.fillColor = UIColor.clear.cgColor
        loading.lineWidth = lineWidth
        loading.strokeEnd = CGFloat(min(max(progress, 0), 100) / 100)
        loading.strokeColor = UIColor.mentionColor.cgColor
        loading.name = layerName
        ring.layer.addSublayer(loading)

        let arrow = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
        arrow.tintColor = .white
        ring.addSubview(arrow)
        arrow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            arrow.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            arrow.centerYAnchor.constraint(equalTo: ring.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 30),
            arrow.heightAnchor.constraint(equalToConstant: 30)
        ])

        let chip = addSizeLabel(to: container, fileName: fileName)
        NSLayoutConstraint.activate([
            chip.topAnchor.constraint(equalTo: ring.bottomAnchor, constant: 6),
            chip.centerXAnchor.constraint(equalTo: ring.centerXAnchor)
        ])
    }

    /// Updates the size caption on whichever cell is showing the transfer. Harmless when
    /// that cell has no caption, or is not on screen at all.
    public static func updateSizeText(forFileNamed name: String, in cell: UITableViewCell) {
        updateSizeText(forFileNamed: name, in: cell.contentView)
    }

    /// The same, for anything that is not a table cell - a collection view cell, or the box
    /// inside a row.
    public static func updateSizeText(forFileNamed name: String, in view: UIView) {
        guard let label = view.viewWithTag(sizeLabelTag) as? UILabel else {
            return
        }
        label.text = sizeText(forFileNamed: name)
        label.superview?.isHidden = label.text == nil
    }

    // Moves the ring drawn into `cell`, if that cell has one. Returns false when it has not,
    // so the caller can fall back to whatever else knows how to draw progress there.
    @discardableResult
    public static func setProgress(_ progress: Double, in cell: UITableViewCell) -> Bool {
        return setProgress(progress, in: cell.contentView)
    }

    /// The same, for anything that is not a table cell.
    @discardableResult
    public static func setProgress(_ progress: Double, in view: UIView) -> Bool {
        guard let loading = progressLayer(in: view.layer) else {
            return false
        }
        // No implicit animation: these arrive about once per percent and the default
        // quarter-second fade would just smear one into the next.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        loading.strokeEnd = CGFloat(min(max(progress, 0), 100) / 100)
        CATransaction.commit()
        return true
    }

    private static func progressLayer(in layer: CALayer) -> CAShapeLayer? {
        if let shape = layer as? CAShapeLayer, shape.name == layerName {
            return shape
        }
        for sublayer in layer.sublayers ?? [] {
            if let found = progressLayer(in: sublayer) {
                return found
            }
        }
        return nil
    }
}

/// WhatsApp-style horizontal drag on a chat row: pull it right to reply to that message, pull
/// it left to open its info. The row follows the finger, springs back when it is let go, and
/// the action only fires if the pull went far enough.
///
/// Driven by one pan gesture on the table rather than a recogniser per cell: these editors
/// rebuild their cells from scratch on every reload, so anything attached to a cell has to be
/// re-attached constantly and can be left behind on a recycled one. It also stays out of the
/// table's way - it only begins for a clearly horizontal drag, so vertical scrolling is
/// untouched.
public final class ChatBubbleSwipe: NSObject, UIGestureRecognizerDelegate {

    public enum Direction {
        /// Pulled to the right.
        case reply
        /// Pulled to the left.
        case info
    }

    private weak var tableView: UITableView?
    private let canPerform: (IndexPath, Direction) -> Bool
    private let perform: (IndexPath, Direction) -> Void

    private weak var activeCell: UITableViewCell?
    private var activeIndexPath: IndexPath?
    private var activeDirection: Direction = .reply
    private var iconView: UIImageView?
    private var didPassThreshold = false
    /// Where the finger was when the pan was recognised. A pan only recognises after about ten
    /// points of movement, so measuring from the touch's origin makes the row jump that far the
    /// instant it starts moving; measuring from here it starts exactly under the finger.
    private var beganTranslation: CGFloat = 0
    private var feedback: UIImpactFeedbackGenerator?
    private let push = InteractiveSidePush()

    /// Where a leftward pull leads. Given one, the pull opens that screen the way WhatsApp does
    /// - dragging it in from the right edge, and letting it fall back if the pull is abandoned -
    /// rather than moving the row and pushing at the end.
    public var infoDestination: ((IndexPath) -> (viewController: UIViewController, navigation: UINavigationController)?)?

    /// How far the row can be pulled, and how far it has to be pulled for the action to fire.
    private static let maxPull: CGFloat = 78
    private static let threshold: CGFloat = 56
    /// How much of the left edge is left to the system's back-swipe.
    private static let backSwipeEdge: CGFloat = 40
    /// Measured off WhatsApp's own badge.
    private static let badgeSize: CGFloat = 29
    /// How far across the screen the info drag has to get - or how fast it has to be flicked -
    /// before letting go opens the screen rather than putting it back.
    private static let pushCommitProgress: CGFloat = 0.33
    private static let pushCommitVelocity: CGFloat = 700

    public init(tableView: UITableView,
                canPerform: @escaping (IndexPath, Direction) -> Bool,
                perform: @escaping (IndexPath, Direction) -> Void) {
        self.tableView = tableView
        self.canPerform = canPerform
        self.perform = perform
        super.init()
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        tableView.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let tableView = tableView else {
            return
        }
        switch sender.state {
        case .began:
            let point = sender.location(in: tableView)
            guard let indexPath = tableView.indexPathForRow(at: point),
                  let cell = tableView.cellForRow(at: indexPath) else {
                return
            }
            // The direction is decided once, from the way the drag started, and held for the
            // rest of it - a row that follows the finger back and forth between two different
            // actions is not something anyone can aim.
            let direction: Direction = sender.velocity(in: tableView).x >= 0 ? .reply : .info
            guard canPerform(indexPath, direction) else {
                return
            }
            activeIndexPath = indexPath
            activeCell = cell
            activeDirection = direction
            didPassThreshold = false
            beganTranslation = sender.translation(in: direction == .info ? (tableView.window ?? tableView) : tableView).x
            // Warmed up here so the tap of confirmation lands with the threshold, not after it.
            feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback?.prepare()
            // The row is being pulled sideways now; letting the list scroll underneath at the
            // same time is what makes this feel loose rather than deliberate.
            tableView.isScrollEnabled = false
            if direction == .info,
               let destination = infoDestination?(indexPath) {
                // The screen starts coming in with the first movement, not at the end of it.
                push.begin(pushing: destination.viewController, in: destination.navigation)
                return
            }
            addIcon(to: cell, direction: direction)

        case .changed:
            guard let cell = activeCell else {
                return
            }
            if push.isRunning {
                // Measured against the window: the table is inside the screen being pushed
                // aside, so a translation read in its own coordinates would be measured against
                // a moving ruler.
                let space = tableView.window ?? tableView
                let travelled = max(0, beganTranslation - sender.translation(in: space).x)
                push.update(travelled / max(space.bounds.width, 1))
                return
            }
            let raw = sender.translation(in: tableView).x - beganTranslation
            // Only the direction this drag started in counts; pulling back the other way just
            // returns the row to where it was.
            let travelled = activeDirection == .reply ? max(0, raw) : max(0, -raw)
            // Past the limit the row keeps moving, but barely - the same resistance a scroll
            // view gives at its edge, so the pull feels bounded without feeling stuck.
            let pulled = travelled <= ChatBubbleSwipe.maxPull
                ? travelled
                : ChatBubbleSwipe.maxPull + (travelled - ChatBubbleSwipe.maxPull) * 0.15
            offset(cell: cell, by: activeDirection == .reply ? pulled : -pulled)
            updateIcon(progress: min(pulled / ChatBubbleSwipe.threshold, 1))
            if pulled >= ChatBubbleSwipe.threshold {
                if !didPassThreshold {
                    didPassThreshold = true
                    // The same confirmation WhatsApp gives: by the time the finger lifts the
                    // reader already knows the action took.
                    feedback?.impactOccurred()
                    feedback?.prepare()
                }
            } else {
                didPassThreshold = false
            }

        case .ended:
            if push.isRunning {
                let space = tableView.window ?? tableView
                let travelled = max(0, beganTranslation - sender.translation(in: space).x)
                let progress = travelled / max(space.bounds.width, 1)
                // Far enough across, or thrown hard enough that stopping short would be a
                // surprise - the same two ways the system's own back-swipe commits.
                if progress >= ChatBubbleSwipe.pushCommitProgress || -sender.velocity(in: space).x >= ChatBubbleSwipe.pushCommitVelocity {
                    push.finish()
                } else {
                    push.cancel()
                }
                finish()
                return
            }
            let shouldPerform = didPassThreshold
            let indexPath = activeIndexPath
            let direction = activeDirection
            finish()
            if shouldPerform, let indexPath = indexPath {
                perform(indexPath, direction)
            }

        default:
            if push.isRunning {
                push.cancel()
            }
            finish()
        }
    }

    /// Moves what the row draws, sideways.
    ///
    /// Fix: this used to transform `cell.contentView`. A table view sets that view's *frame* on
    /// every layout pass, and setting a frame on a view that carries a transform recomputes its
    /// bounds and centre to satisfy that frame - which quietly cancels the translation, so the
    /// bubble never appeared to move. Auto Layout positions ordinary subviews by their centre
    /// and bounds instead, and leaves a transform alone, so moving them is what actually shows.
    private func offset(cell: UITableViewCell, by dx: CGFloat) {
        let transform = dx == 0 ? CGAffineTransform.identity : CGAffineTransform(translationX: dx, y: 0)
        for view in cell.contentView.subviews {
            view.transform = transform
        }
    }

    /// The round badge WhatsApp shows behind the row while it is being pulled: a filled circle
    /// with a white arrow in it, not a bare glyph.
    private func addIcon(to cell: UITableViewCell, direction: Direction) {
        iconView?.removeFromSuperview()
        let isDark = cell.traitCollection.userInterfaceStyle == .dark
        let badge = UIImageView()
        badge.backgroundColor = UIColor(white: isDark ? 0.26 : 0.60, alpha: 0.95)
        badge.layer.cornerRadius = ChatBubbleSwipe.badgeSize / 2
        badge.clipsToBounds = true
        badge.contentMode = .center
        badge.image = UIImage(systemName: direction == .reply ? "arrowshape.turn.up.left.fill" : "info.circle.fill",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        badge.alpha = 0
        // On the cell rather than its content view: the content view's subviews are what move,
        // and they are transparent around the bubble, so the badge sits in the space the bubble
        // leaves behind as it is pulled across.
        cell.insertSubview(badge, at: 0)
        badge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badge.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: ChatBubbleSwipe.badgeSize),
            badge.heightAnchor.constraint(equalToConstant: ChatBubbleSwipe.badgeSize),
            direction == .reply
                ? badge.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 14)
                : badge.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -14)
        ])
        iconView = badge
    }

    private func updateIcon(progress: CGFloat) {
        guard let icon = iconView else {
            return
        }
        icon.alpha = progress
        let scale = 0.6 + 0.4 * progress
        // Drifts in behind the row rather than sitting still, so the two move together.
        let drift = (activeDirection == .reply ? -1 : 1) * 10 * (1 - progress)
        icon.transform = CGAffineTransform(translationX: drift, y: 0).scaledBy(x: scale, y: scale)
    }

    private func finish() {
        tableView?.isScrollEnabled = true
        feedback = nil
        let cell = activeCell
        let icon = iconView
        activeCell = nil
        activeIndexPath = nil
        iconView = nil
        didPassThreshold = false
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.allowUserInteraction], animations: {
            if let cell = cell {
                self.offset(cell: cell, by: 0)
            }
            icon?.alpha = 0
        }, completion: { _ in
            icon?.removeFromSuperview()
        })
        // Insurance: a cell recycled mid-drag would otherwise be reused still holding the
        // translation of the row that was being pulled - a row sitting visibly off to one side.
        for visible in tableView?.visibleCells ?? [] {
            offset(cell: visible, by: 0)
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let tableView = tableView else {
            return false
        }
        let velocity = pan.velocity(in: tableView)
        // Sideways, or this is a scroll and none of our business.
        guard abs(velocity.x) > abs(velocity.y) else {
            return false
        }
        let location = pan.location(in: tableView)
        let direction: Direction = velocity.x >= 0 ? .reply : .info
        // Fix: the left edge belongs to the navigation controller's back-swipe. Incoming
        // bubbles sit close to that edge, so a pull on one used to start the pop transition
        // instead of a reply - two gestures reading the same drag. Starting further in is a
        // reply; starting on the edge is still "go back", the way it is everywhere else.
        if direction == .reply, location.x < ChatBubbleSwipe.backSwipeEdge {
            return false
        }
        guard let indexPath = tableView.indexPathForRow(at: location) else {
            return false
        }
        return canPerform(indexPath, direction)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only the table's own scrolling. Sharing the drag with anything else - the back-swipe
        // above all - is how one gesture ends up doing two things at once.
        return otherGestureRecognizer === tableView?.panGestureRecognizer
    }
}


/// A push that follows the finger, the way WhatsApp opens message info from a chat: the next
/// screen slides in from the right as the row is pulled left, and slides back out again if the
/// pull is abandoned before it commits.
///
/// The navigation controller's own delegate is borrowed only while a drag is in flight and put
/// back afterwards, so nothing else in the app has to know this exists.
public final class InteractiveSidePush: NSObject, UINavigationControllerDelegate, UIViewControllerAnimatedTransitioning {

    private weak var navigation: UINavigationController?
    private var interaction: UIPercentDrivenInteractiveTransition?
    private weak var previousDelegate: UINavigationControllerDelegate?

    public var isRunning: Bool {
        return interaction != nil
    }

    public func begin(pushing viewController: UIViewController, in navigationController: UINavigationController) {
        guard interaction == nil else {
            return
        }
        navigation = navigationController
        previousDelegate = navigationController.delegate
        navigationController.delegate = self
        let driver = UIPercentDrivenInteractiveTransition()
        driver.completionCurve = .easeOut
        interaction = driver
        navigationController.pushViewController(viewController, animated: true)
    }

    public func update(_ progress: CGFloat) {
        interaction?.update(min(max(progress, 0), 1))
    }

    public func finish() {
        interaction?.finish()
        release()
    }

    public func cancel() {
        interaction?.cancel()
        release()
    }

    private func release() {
        interaction = nil
        navigation?.delegate = previousDelegate
        previousDelegate = nil
    }

    // MARK: - UINavigationControllerDelegate

    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // Only the push this object started; everything else keeps the system's own animation.
        return operation == .push && interaction != nil ? self : nil
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interaction
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.32
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) ?? transitionContext.viewController(forKey: .from)?.view,
              let toView = transitionContext.view(forKey: .to) ?? transitionContext.viewController(forKey: .to)?.view else {
            transitionContext.completeTransition(false)
            return
        }
        let container = transitionContext.containerView
        let width = container.bounds.width
        toView.frame = container.bounds
        toView.transform = CGAffineTransform(translationX: width, y: 0)
        container.addSubview(toView)

        // The same parallax the system's push uses: the screen being left behind drifts a third
        // of the way, under a slight dim, so the two read as a stack rather than a swap.
        let dim = UIView(frame: container.bounds)
        dim.backgroundColor = .black
        dim.alpha = 0
        container.insertSubview(dim, belowSubview: toView)

        // Linear: an interactive transition is scrubbed by the finger, and any other curve makes
        // the screen lag behind or run ahead of it.
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveLinear], animations: {
            toView.transform = .identity
            fromView.transform = CGAffineTransform(translationX: -width / 3, y: 0)
            dim.alpha = 0.1
        }, completion: { _ in
            let cancelled = transitionContext.transitionWasCancelled
            fromView.transform = .identity
            dim.removeFromSuperview()
            if cancelled {
                toView.removeFromSuperview()
            }
            transitionContext.completeTransition(!cancelled)
        })
    }
}
