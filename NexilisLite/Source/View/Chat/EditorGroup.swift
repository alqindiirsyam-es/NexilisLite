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
@_implementationOnly import NotificationBannerSwift
import nuSDKService
@_implementationOnly import SwiftLinkPreview
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

    /// The conversation participant colours are dealt for.
    ///
    /// A topic is its own conversation with its own member list, so it takes the chat id rather
    /// than the group's - which is the same thing a message carries in l_pin when it is sent
    /// into a topic.
    func conversationScope() -> String {
        let topic = self.dataTopic["chat_id"] as? String ?? ""
        return topic.isEmpty ? (self.dataGroup["group_id"] as? String ?? "") : topic
    }
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
        guard let indexes = messageIndexes(onDate: date) else {
            return []
        }
        return indexes.compactMap { $0 < dataMessages.count ? dataMessages[$0] : nil }
    }

    /// One section's positions, without gathering the messages themselves.
    ///
    /// Asking for a section's messages builds an array of them, and the table asks about one
    /// row at a time - so a single row's question used to gather its whole day.
    private func messageIndexes(onDate date: String) -> [Int]? {
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
        return messageIndexesByDate?[date]
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
    /// How many messages the band above the marker says are waiting. Kept beside
    /// `markerCounter` because `counter` is cleared as soon as the chat opens.
    var markerCount = 0

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
    /// How far ahead of the top of the loaded conversation a page is read, in screens.
    ///
    /// Two screens: near the top, but not at it. Eight screens was tried and it reads a page at
    /// the start of almost every flick, which is a page read the reader had no need of - and
    /// every page read is work done on the main thread while they are scrolling. Four hundred
    /// points was the other extreme, and at the speed of a flick that is two or three frames'
    /// warning, which is no warning at all. Two screens is close enough that a page is read only
    /// when the reader is genuinely heading for the end of what is loaded, and far enough that
    /// the read is over well before they get there.
    private static let olderMessageLead: CGFloat = 2
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
    /// How long that placement may keep correcting itself, and how tall the content was on the
    /// previous pass.
    ///
    /// Fix: placing the chat at its newest message was a single scroll on the first layout pass.
    /// The rows above the screen have never been drawn at that point, so the table is still
    /// guessing their heights from an estimate; when the real ones arrive the content grows
    /// underneath and the chat quietly scrolls up by a message, which is exactly the shift seen
    /// on opening one. The bottom is held now until the content height stops changing between
    /// passes - the same rule the unread marker's placement already follows.
    private var initialBottomDeadline: Date?
    private var initialBottomLastContentHeight: CGFloat = -1
    /// When the hold started, so it can be kept up for a moment after the rows first look
    /// settled.
    ///
    /// Fix: some rows change height a beat after the chat is drawn - a picture's own size
    /// arriving, a name resolving, a page of older messages landing - and the hold had already
    /// let go by then, so that late change pushed the newest message off the bottom. It now
    /// keeps its place for a short while whatever the heights say, which is also what a reader
    /// who has not scrolled expects: the chat stays at its newest message.
    private var initialBottomStartedAt: Date?
    /// How long the opening placement stays in charge once the rows look settled, and the hard
    /// stop for the whole thing.
    private static let initialBottomGrace: TimeInterval = 1.0
    /// The first unread message, while the chat is still being placed at it.
    private var pendingUnreadMarkerScroll: String?
    private var remainingUnreadMarkerScrollPasses = 0
    /// When to give up on placing the marker, whatever has or has not settled by then.
    ///
    /// Fix: the budget was a count of layout passes, and a pass spent waiting for the table to
    /// have any rows at all cost as much as a pass that actually aimed. A conversation that took
    /// a few passes to get going spent the whole budget waiting and never scrolled. Time is what
    /// the giving-up should be measured in; the passes are only the opportunities to try.
    private var pendingUnreadMarkerDeadline: Date?
    /// How tall the content was on the previous pass, so "the heights have stopped moving" can be
    /// told apart from "this pass happened to agree with the estimates".
    private var unreadMarkerLastContentHeight: CGFloat = -1
    /// Enough layout passes for the estimated row heights above the marker to be replaced by
    /// measured ones, and few enough that a conversation that will not settle gives up rather
    /// than re-scrolling under the reader's finger.
    private static let unreadMarkerScrollPasses = 8
    /// Measured row heights, keyed by message id, so the table estimates with real numbers
    /// instead of guessing - which is what keeps the scroll position steady when older
    /// messages are inserted above.
    private var measuredRowHeights: [String: CGFloat] = [:]
    /// What each message's own text measures, kept so a row costs that measurement once.
    private var textBubbleHeights: [String: CGFloat] = [:]
    /// The width the text is really laid out at, learned from a bubble that has been built - one
    /// for the reader's own bubbles, one for everybody else's. See learnTextWidth.
    private var textWidths: [Bool: CGFloat] = [:]
    /// What each row was reckoned at before its kind's learned difference was added.
    private var rawRowGuesses: [String: CGFloat] = [:]
    /// What this conversation's reckonings are out by, per kind of bubble and per side of the
    /// conversation. See learnRowHeight.
    private var corrections: [String: HeightCorrection] = [:]
    /// How much of each row's reckoning was its text, so the proportional half of the learned
    /// difference has something to work on.
    private var rawTextParts: [String: CGFloat] = [:]
    /// Held while a collage's list of pictures is being raised from the bottom edge: a navigation
    /// controller does not keep its delegate.
    private var risingCollageTransition: AnyObject?
    /// The measurements above, added up, so a row never built can be guessed at from what this
    /// conversation's rows really come to rather than from a fixed number.
    private var measuredHeightTotal: CGFloat = 0
    private var measuredHeightSamples = 0
    /// Settled once enough rows have been measured, and not moved again.
    ///
    /// Fix: this was the running average itself, recomputed on every read. A guess that keeps
    /// changing is worse than a guess that is merely wrong: the table asks it again for every row
    /// it has not built whenever the rows are reloaded, so a moving average moves the height of
    /// hundreds of rows at once, and with them the whole content and everything worked out from
    /// it. That is why the list was unsteady exactly when messages first came on screen - opening
    /// a chat, and reading a page of older ones - because that is when rows are measured and the
    /// average moves. Forty rows is a good enough sample; after that the answer stops moving.
    private var settledRowHeightEstimate: CGFloat?
    private static let rowHeightSampleSize = 40
    private var averageMeasuredRowHeight: CGFloat {
        if let settled = settledRowHeightEstimate {
            return settled
        }
        guard measuredHeightSamples > 0, !measuredRowHeights.isEmpty else {
            return 72
        }
        let average = measuredHeightTotal / CGFloat(measuredHeightSamples)
        if measuredHeightSamples >= Self.rowHeightSampleSize {
            settledRowHeightEstimate = average
        }
        return average
    }
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
    /// The two views that trade places when a selection session opens: the sender's picture goes
    /// and the circle takes the same spot. Found by tag because the fade runs over `visibleCells`
    /// after the table has already built them.
    static let selectionMarkTag = 77_311
    static let selectionAvatarTag = 77_312
    /// Where the circle starts and ends up when it is not shown - small enough to read as growing
    /// out of the picture it replaces, not so small that it looks like it fell out of the row.
    static let selectionMarkHidden = CGAffineTransform(scaleX: 0.4, y: 0.4)
    /// The bubble that still owes an arrival animation: which message, which side it grows from,
    /// and when the growing started.
    ///
    /// Fix: the animation used to be played from the completion of the insert. That completion
    /// runs only once the table has finished animating the insertion in - by which point the
    /// bubble has been on screen at full size for about a tenth of a second, so what the reader
    /// saw was a finished bubble that then collapsed and grew again. The debt is written down
    /// before the row is inserted now and paid by willDisplay, which fires while the row is
    /// being created: the first frame the bubble is drawn at all, it is already small.
    ///
    /// It is kept until the growing has actually finished, not merely started, because a row
    /// rebuilt in the middle - a tick arriving a moment after the message does exactly that -
    /// throws its bubble away, and the new one has to pick the animation up where the old one
    /// left off rather than snapping to full size.
    private var pendingBubbleArrival: (messageId: String, outgoing: Bool, startedAt: Date?, pushesList: Bool)?

    /// The bubble growing right now, so a redraw does not wipe the transform out from under it.
    private weak var arrivingBubble: UIView?

    /// The row that bubble is in - held back while the conversation slides up behind it, so a
    /// redraw must leave everything in it alone, not only the bubble.
    private weak var arrivingCell: UITableViewCell?

    /// How long a bubble takes to grow, measured off the reference.
    static let bubbleArrivalDuration: TimeInterval = 0.18

    /// Whether the circles are on screen. Every cell is built in whichever of the two states this
    /// names, so a row scrolled into view mid-session arrives already showing its circle.
    private var selectionChromeShown = false
    /// What held the table's bottom before the selection bar took the input bar's place.
    private var bottomTableConstantBeforeSelection: CGFloat?
    /// Counts the bars this screen has put up. `cancelAction` does its work a run loop later, and
    /// a session opened in between - searching, then forwarding - would otherwise be taken down
    /// by the cancel that belonged to the one before it.
    private var selectionSessionToken = 0
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

    /// What is already known about each link in this conversation.
    ///
    /// Fix: every bubble carrying a link read the LINK_PREVIEW table as it was built, and a row
    /// is built again every time it comes back into view - so a conversation full of links did a
    /// SQLite transaction per link on every pass of the scroll, on the main thread. What a link
    /// says only changes when this screen changes it, and where it does the entry is dropped.
    private var linkAnswers: [String: LinkPreviewStore.Answer] = [:]
    /// Links seen on screen whose page has not been read yet, against the message each sits on.
    private var linksToRead: [String: String] = [:]
    private var linkReadPassScheduled = false

    private func linkAnswer(for link: String) -> LinkPreviewStore.Answer {
        if let held = linkAnswers[link] {
            return held
        }
        let answer = LinkPreviewStore.answer(link: link)
        // A conversation scrolled long enough would otherwise hold every link it ever passed.
        if linkAnswers.count > 300 {
            linkAnswers.removeAll()
        }
        linkAnswers[link] = answer
        return answer
    }

    /// Fix: the page behind a link was asked for from inside the row that carried it. Scrolling
    /// past twenty links therefore started twenty page fetches and twenty pictures behind them,
    /// each one a URLSession and a delegate built on the main thread while the finger was still
    /// moving, and each answer rebuilt a row. A link seen on screen is only noted here; the
    /// reading happens once the list is still, two at a time, and only for the links still on
    /// screen by then.
    private func noteLinkToRead(_ link: String, messageId: String) {
        guard !link.isEmpty, !messageId.isEmpty else {
            return
        }
        linksToRead[link] = messageId
        scheduleLinkReadPass()
    }

    private func scheduleLinkReadPass() {
        guard !linkReadPassScheduled, !linksToRead.isEmpty else {
            return
        }
        linkReadPassScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.linkReadPassScheduled = false
            self?.readLinksNowOnScreen()
        }
    }

    private func readLinksNowOnScreen() {
        guard let table = tableChatView, !linksToRead.isEmpty else {
            return
        }
        guard !table.isDragging, !table.isDecelerating else {
            scheduleLinkReadPass()
            return
        }
        let onScreen = Set((table.indexPathsForVisibleRows ?? []).compactMap {
            message(at: $0)?["message_id"] as? String
        })
        // What has scrolled away is forgotten rather than fetched; it is noted again if it comes
        // back. What is left over waits for the next pass instead of going out all at once.
        linksToRead = linksToRead.filter { onScreen.contains($0.value) }
        for (link, messageId) in linksToRead.prefix(2) {
            linksToRead.removeValue(forKey: link)
            readLink(link, messageId: messageId)
        }
        scheduleLinkReadPass()
    }

    private func readLink(_ link: String, messageId: String) {
        LinkPreviewFetcher.fetch(link: link) { [weak self] gained in
            // Nothing was learned - a restricted Drive link, an address that is not one, a site
            // that answered with nothing - so there is nothing to draw and no row is touched.
            guard gained, let self = self, let table = self.tableChatView else {
                return
            }
            self.linkAnswers.removeValue(forKey: link)
            guard !table.isDragging, !table.isDecelerating,
                  let indexPath = self.indexPath(forMessageId: messageId),
                  table.indexPathsForVisibleRows?.contains(indexPath) == true else {
                return
            }
            // A card appearing makes its row taller, and a row above the reader getting taller
            // pushes what they are reading down the screen. The message they were looking at is
            // put back where it was, the same way it is when the keyboard changes the room.
            let anchor = self.listAnchor
            table.reloadRows(at: [indexPath], with: .none)
            table.layoutIfNeeded()
            self.restore(anchor)
        }
    }
    var timerCheckLink: Timer?
    var lastPositionCursorMention = 0
    var lastTextLength = 0
    var timerFakeProgress: Timer?
    var showMenuContext = false
    var touchedSubview = UIView()
    /// Shows and hides the floating date over the conversation. See DateHeaderVisibility.
    let dateHeaders = DateHeaderVisibility()
    /// Whether the list has just moved, which is what keeps a long press during a scroll from
    /// opening the bubble menu or the link sheet. See ListMotion.
    let listMotion = ListMotion()
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
    /// The name a collage's tiles answer to, so the one picture a quote was about can be found
    /// again inside the row that stands for all of them.
    private static let collageTileName = "collageTile-"

    /// Takes the reader to a quoted or pinned message and flashes it.
    ///
    /// Fix: the row was found by walking the loaded list for the message's own id, and a picture
    /// gathered into a collage has no row of its own - the collage's row stands for all of them,
    /// and the members are taken out of the list when they join it. So a quote of a picture that
    /// ended up in a collage found nothing, returned, and the tap did nothing at all.
    /// indexPath(forMessageId:) already knows to answer with the collage's row, and once there
    /// the one picture the quote was about is flashed inside it - so the tap points at the
    /// picture, not merely at the group it ended up in.
    ///
    /// The jump itself is not animated. A quote can be thousands of points away, and an animated
    /// scroll over that distance is a long blur of other people's messages; the reference arrives
    /// at once, in a single frame, and the flash is what says where.
    private func jumpToQuotedMessage(messageId: String) {
        guard !messageId.isEmpty else {
            return
        }
        ensureMessageLoaded(messageId: messageId)
        guard let indexPath = indexPath(forMessageId: messageId), let row = message(at: indexPath) else {
            return
        }
        tableChatView.safeScrollToRow(at: indexPath, at: .middle, animated: false)
        // A row that has just been scrolled to has no cell until the table has laid itself out,
        // and there is nothing to flash without one.
        tableChatView.layoutIfNeeded()
        // A quote of a picture that ended up in a collage: what the reader asked for is that one
        // picture, so the collage's own list of pictures is raised over the conversation and put
        // at the one they named. The conversation underneath has already been taken to the collage,
        // so closing the list lands on the bubble the quote was about rather than wherever they
        // were reading before.
        // Not when there is nowhere to raise it: a conversation loaded behind another screen
        // purely to answer for it has no stack of its own, and there the flash below is all there
        // is to give.
        if navigationController != nil, let rowId = row["message_id"] as? String, rowId != messageId,
           let members = groupImages[rowId],
           let member = members.firstIndex(where: { $0.messageId == messageId }) {
            let opening = ObjectGesture()
            opening.listImageFromGrouping = members
            opening.indexImageTapped = member
            opening.isInitiator = (row["f_pin"] as? String) == User.getMyPin()
            opening.risesFromBottom = true
            imageGroupingTapped(opening)
            return
        }
        flashBubble(at: indexPath, row: row, quoted: messageId)
    }

    /// Marks the bubble that was jumped to, and the picture inside it when the bubble is a
    /// collage: the bubble lightens for half a second the way the reference does, and the one
    /// picture the quote named brightens and fades.
    private func flashBubble(at indexPath: IndexPath, row: [String: Any?], quoted: String) {
        guard let cell = tableChatView.cellForRow(at: indexPath) else {
            return
        }
        // By the tag every editor puts on the bubble - its position among the row's subviews
        // differs between a plain chat and one with an avatar, and by position this could land on
        // the avatar. The collage tiles below live inside the same view.
        guard let containerMessage = cell.contentView.viewWithTag(EditorGroup.bubbleTag) else {
            return
        }
        // One highlight, the same everywhere - see BubbleHighlight for what it is and why.
        BubbleHighlight.flash(containerMessage)
        guard (row["message_id"] as? String) != quoted,
              let members = groupImages[row["message_id"] as? String ?? ""],
              let member = members.firstIndex(where: { $0.messageId == quoted }) else {
            return
        }
        var tiles: [Int: UIView] = [:]
        for tile in containerMessage.subviews {
            guard let name = tile.accessibilityIdentifier, name.hasPrefix(EditorGroup.collageTileName),
                  let index = Int(name.dropFirst(EditorGroup.collageTileName.count)) else {
                continue
            }
            tiles[index] = tile
        }
        // Past the fourth there are no tiles of their own: the rest of the run is behind the last
        // one, and that is where the reader is pointed.
        guard let target = tiles[min(member, tiles.count - 1)] else {
            return
        }
        let glow = UIView()
        glow.backgroundColor = UIColor.white.withAlphaComponent(0.55)
        glow.isUserInteractionEnabled = false
        glow.layer.cornerRadius = target.layer.cornerRadius
        target.addSubview(glow)
        glow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            glow.topAnchor.constraint(equalTo: target.topAnchor),
            glow.bottomAnchor.constraint(equalTo: target.bottomAnchor),
            glow.leadingAnchor.constraint(equalTo: target.leadingAnchor),
            glow.trailingAnchor.constraint(equalTo: target.trailingAnchor)
        ])
        UIView.animate(withDuration: 0.35, delay: 0.35, options: [.curveEaseOut], animations: {
            glow.alpha = 0
        }, completion: { _ in
            glow.removeFromSuperview()
        })
    }

    func highlightMessage(_ messageId: String) {
        // Fix: this painted the whole row yellow for a second, which is neither what a quote tap
        // does two screens over nor what the reference does. One flash, in one place, whichever
        // way the reader arrived.
        jumpToQuotedMessage(messageId: messageId)
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
        jumpToQuotedMessage(messageId: messageId)
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
        let cancelButton = selectionCancelBarButton()
        if !isHistoryCC {
            navigationItem.rightBarButtonItems = nil
        }
        navigationItem.rightBarButtonItem = cancelButton
        changeAppBar()
        if let idx = dataMessages.firstIndex(where: { ($0["message_id"] as? String) == messageId }) {
            dataMessages[idx]["isSelected"] = true
        }
        startMultipleSelectSession()
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
    /// WhatsApp's rule, and the one thing this was missing: a message can be taken back from
    /// everybody for two days and twelve hours after it was sent, and no longer. Past that the
    /// choice is simply not offered - it used to be offered on a message of any age, which is not
    /// something the other side would honour anyway.
    private static let deleteForEveryoneWindow: TimeInterval = 60 * 3600

    private func withinDeleteForEveryoneWindow(_ message: [String: Any?]) -> Bool {
        // No timestamp is no evidence that it is recent enough.
        guard let stamp = message[TypeDataMessage.server_date] as? String,
              let millis = Int64(stamp) else {
            return false
        }
        let age = Date().timeIntervalSince1970 - TimeInterval(millis) / 1000
        return age <= Self.deleteForEveryoneWindow
    }

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
        let allRecentEnough = dataMessages.allSatisfy({ withinDeleteForEveryoneWindow($0) })
        if dataFilterFpin.count == 0 && dataFilterLock.count == 0 && statusFailed.count == 0 && allRecentEnough {
            options.append(BottomChoiceSheet.Option(title: "Delete".localized() + " \(countSelected) " + "For Everyone".localized(), isDestructive: true) { [weak self] in
                self?.performDelete(for: "everyone", dataMessages: dataMessages, onDone: onDeleted)
            })
        }
        // There is no Cancel among the answers: the card carries a close button and shuts on a tap
        // outside, the way the design asks for.
        let sheet = BottomChoiceSheet(question: "Delete messages?".localized(),
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
        // It is a conversation being read now, so it stops announcing its own messages. Done
        // here as well as in viewWillAppear: a preview that is opened is already on screen, and
        // viewWillAppear will not come round again for it.
        registerAsOpenConversation()
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
                    //
                    // Being stopped is not being unreachable, though - both are reported the same
                    // way, and marking a file the reader called off as one the server would not
                    // give up turned a video's bubble into "could not be had" the moment its
                    // download was cancelled.
                    if Download.wasCalledOff(forKey: name) {
                        self.unreachableFiles.remove(name)
                    } else {
                        self.unreachableFiles.insert(name)
                    }
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

    /// Thumbnails being read and decoded right now.
    ///
    /// Fix: every thumbnail that finished downloading redrew every visible row - that is what the
    /// transfer tick above does - and each redraw threw away the bubble that had asked for a
    /// picture and started the same read again from a new one. With a screenful arriving, each
    /// arrival orphaned all the reads in flight, which restarted, and were orphaned by the next.
    /// The work never finished because it was never allowed to. One read per file, and whoever is
    /// on screen when it lands gets the picture.
    private static var thumbnailsBeingRead = Set<String>()

    /// Where thumbnails are read and decoded.
    ///
    /// Fix: this work went to `DispatchQueue.global`, and a global queue is one shared line that
    /// every part of the app joins. Measured on the device, reading and decrypting a thumbnail took
    /// a millisecond and decoding it thirty-five - and the work waited **four and a half seconds**
    /// to be given a thread at all, because it was behind everything else already in that line.
    /// Four rounds of making the work itself faster could never have helped: the work was never
    /// the slow part. This line is ours alone. Serial on purpose - thirty-five milliseconds each
    /// means a screenful costs a fifth of a second, and one thread cannot flood the pool.
    private static let thumbnailQueue = DispatchQueue(label: "nexilis.thumbnails.decode",
                                                      qos: .userInitiated)

    private static var bubbleSignatureKey: UInt8 = 0

    /// How many times this screen has changed a message in place.
    ///
    /// Fix: a bubble is cached against a signature made of the message's own fields, and a
    /// message can return to a state it has already been drawn in - sent, stopped, sent again.
    /// A cell left in the reuse pool from the first time round then matches the new signature
    /// exactly, so the table hands that cell straight back and the row is never built: no stop
    /// control, and the badge belonging to the wrong round. The count makes every local change
    /// a state the row has never been in before.
    private var localEdits: [String: Int] = [:]


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
        parts.append("edit=\(localEdits[messageId] ?? 0)")
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
        guard !isPreview else {
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
        guard let visible = tableChatView.indexPathsForVisibleRows, !visible.isEmpty else {
            return
        }
        var slots = EditorGroup.maximumConcurrentAutoDownloads - autoDownloadsInFlight.count
        guard slots > 0 else {
            return
        }
        // Light things first, across every visible row, before anything heavy is started at
        // all: a document or a video can hold a place for a long time, and a thumbnail two rows
        // down should not be waiting behind it to appear.
        // A thumbnail is fetched whether or not the reader has auto download on. It is not a copy
        // of the attachment - it is what the bubble is: the picture behind the blur, and the still
        // a video or a note is offered by. Held back, the bubble is a blank square with an arrow
        // on it, and the reader is asked to fetch something they have not been shown.
        var passes = [EditorGroup.thumbnailKeys]
        if Utils.isAutoDownloadOn {
            passes.append(EditorGroup.lightAttachmentKeys)
            passes.append(EditorGroup.heavyAttachmentKeys)
        }
        for keys in passes {
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
    /// Always fetched, setting or no setting - see the sweep.
    private static let thumbnailKeys = ["thumb_id"]
    private static let lightAttachmentKeys = ["image_id", "gif_id", "audio_id"]
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

    /// The documents directory, asked for once rather than once per row.
    ///
    /// Fix: every caller of this asked NSSearchPathForDirectoriesInDomains for itself, and a page
    /// of a hundred messages asked it several hundred times. It does not change while the app is
    /// running.
    private static let documentsPath: String = {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
    }()

    /// Whether a file is on this device.
    ///
    /// Fix: two filesystem questions per call, and the collage grouping asks it twice for every
    /// pair of pictures in a run - so one page of images went through the filesystem hundreds of
    /// times over, on the main thread, while the reader was scrolling. The answer is remembered
    /// for the life of the screen: a file that has arrived does not leave again, and one that has
    /// not is asked for again when its download reports in, which redraws the row anyway.
    private func isFilePresent(_ filename: String) -> Bool {
        guard !filename.isEmpty else {
            return false
        }
        if let known = filePresence[filename] {
            return known
        }
        let path = Self.documentsPath
        guard !path.isEmpty else {
            return false
        }
        let url = URL(fileURLWithPath: path).appendingPathComponent(filename)
        let here = FileManager.default.fileExists(atPath: url.path)
            || FileEncryption.shared.isSecureExists(filename: filename)
        // Only a yes is worth keeping. A no can become a yes the moment a download lands, and
        // remembering that would leave the bubble offering to fetch a file it already has.
        if here {
            filePresence[filename] = true
        }
        return here
    }

    /// Files already found on this device, so the filesystem is asked once each.
    private var filePresence: [String: Bool] = [:]

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
        if let measured = videoLengths?[row["message_id"] as? String ?? ""], measured > 0 {
            return measured
        }
        // Fix: this only ever read `video_duration`, which is filled in by opening the file and
        // measuring it - so a video that had just finished downloading showed no length at all
        // until that measurement came back, a beat later and only if the file could be read. The
        // sender already said how long it runs, and that travelled with the message: it is known
        // the moment the video is.
        let name = row["video_id"] as? String ?? ""
        let claimed = VideoNote.Facts.of(attachmentNamed: name).duration
        return claimed > 0 ? Int(claimed) : 0
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
    
    var audioPlayers: [String: AVAudioPlayer] = [:]
    /// The line drawn for each audio bubble on screen, so whatever moves the slider can move it
    /// too. Weakly held: a row scrolled away takes its own views with it.
    var audioWaves: [String: AudioWaveformView] = [:]
    /// Sender pictures already looked up, by pin. A bubble is drawn many times a second while the
    /// conversation scrolls, and this is a query.
    private var senderThumbs: [String: String] = [:]

    /// Where a sender's picture is kept, for the bubble that shows who is speaking.
    private func profileThumb(forPin pin: String, messageId: String) -> String {
        return getDataProfile(f_pin: pin, message_id: messageId)["image_id"] ?? ""
    }

    func senderThumb(forPin pin: String, messageId: String) -> String? {
        guard !pin.isEmpty else {
            return nil
        }
        if let known = senderThumbs[pin] {
            return known
        }
        let found = profileThumb(forPin: pin, messageId: messageId)
        senderThumbs[pin] = found
        return found
    }
    /// The rest of each audio bubble's controls, alongside audioWaves. Kept for the same reason:
    /// something that happens to the audio - it finishing, chiefly - has to be able to show on the
    /// bubble without rebuilding the row underneath whoever is touching it.
    var audioSliders: [String: UISlider] = [:]
    var audioPlayButtons: [String: UIButton] = [:]
    var audioTimeLabels: [String: UILabel] = [:]
    /// The picture and the speed button that trade places in the left of the bubble.
    var audioSpeedPills: [String: UIButton] = [:]
    var audioAvatars: [String: UIView] = [:]
    /// The reading speed chosen for each note, which notes are far enough into being listened to
    /// that the speed button is showing instead of the picture, and the wait before the picture
    /// comes back once the audio has run out.
    var audioRates: [String: Float] = [:]
    var audioSessions: Set<String> = []
    var audioRestTimers: [String: Timer] = [:]
    /// Notes whose audio ran out while the slider was still being held: the wait before the picture
    /// returns cannot start until the finger comes off, or the button would go while it is in use.
    var audioAwaitingRest: Set<String> = []
    var timers: [String: Timer] = [:]
    /// Fix: the players, their timers and the row that is playing were all keyed by index path.
    /// A message arriving shifts every row below it, and the keys then point at bubbles they have
    /// nothing to do with - audio carrying on under the wrong one, a pause that pauses somebody
    /// else. A message does not move.
    var playingAudioId: String?
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
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Off screen is off screen, whether that is the reader going back, opening another
        // conversation over this one, or stepping into this one's own members list.
        unregisterAsOpenConversation()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        // Nothing left playing, and no timer left running, behind a conversation that has
        // been left - a repeating timer outlives the screen that made it.
        stopAllAudio()
        if self.isMovingFromParent {
            removeAllObjectBeforeDismissVC()
        }
    }
    
    private func removeAllObjectBeforeDismissVC() {
        cancelAllReadStatusTasks()
        for timer in self.timerCredential.values {
            timer.invalidate()
        }
        // Fix: this cleared the key whoever it belonged to, from viewDidDisappear - which lands
        // after the screen underneath has already registered itself.
        self.unregisterAsOpenConversation()
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
        applyPendingInitialBottomScroll()
        applyPendingUnreadMarkerScroll()
    }

    /// Fix: the room the table is given while a selection bar is up is measured off the safe
    /// area, and that is not known until the screen is in a window - a session opened before
    /// then, or a device turned on its side under one, would leave the table's bottom sitting
    /// behind the bar. The measurement is taken again whenever the inset settles.
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        guard bottomTableConstantBeforeSelection != nil else { return }
        constraintBottomTableViewWithTextfield.constant = view.safeAreaInsets.bottom - 60
    }

    /// Makes the opening placement converge now instead of over the next few layout passes.
    ///
    /// Fix: a row the table has never drawn is guessed at, so the first placement is worked out
    /// from guesses and lands short of the newest message; the passes that follow correct it,
    /// and that correction is the drift seen as a chat opens. Only measuring replaces a guess,
    /// so the measuring is asked for here - a handful of layout passes, each costing the visible
    /// rows - at a moment when the screen is still sliding in and nothing of this is visible.
    private func settleInitialBottomNow() {
        guard pendingInitialScrollToBottom, pendingUnreadMarkerScroll == nil,
              tableChatView.numberOfSections > 0 else {
            return
        }
        // Whatever this settles, the per-pass hold keeps watching afterwards: the bars around
        // the table can still change its height once more before the screen is done arriving.
        let held = pendingInitialScrollToBottom
        view.layoutIfNeeded()
        for _ in 0..<6 {
            let before = tableChatView.contentSize.height
            applyPendingInitialBottomScroll()
            tableChatView.layoutIfNeeded()
            if tableChatView.contentSize.height == before {
                break
            }
        }
        pendingInitialScrollToBottom = held
    }

    /// Keeps the chat at its newest message while the rows above it settle.
    ///
    /// Gives up on its deadline, whatever the table has got itself into, and the moment the
    /// reader takes the list over - see scrollViewDidScroll.
    private func applyPendingInitialBottomScroll() {
        // The unread marker's placement aims somewhere else entirely; the two never run for the
        // same opening, and this makes sure of it.
        guard pendingInitialScrollToBottom, pendingUnreadMarkerScroll == nil else {
            return
        }
        if initialBottomDeadline == nil {
            initialBottomDeadline = Date().addingTimeInterval(2.5)
            initialBottomStartedAt = Date()
        }
        if let deadline = initialBottomDeadline, Date() > deadline {
            pendingInitialScrollToBottom = false
            initialBottomDeadline = nil
            initialBottomStartedAt = nil
            return
        }
        guard tableChatView.numberOfSections > 0, tableChatView.bounds.height > 0 else {
            // Nothing to aim at yet. Waiting is not an attempt, and the deadline is what stops
            // this going on for ever.
            return
        }
        let lowest = -tableChatView.adjustedContentInset.top
        let bottom = max(lowest, tableChatView.contentSize.height
                         + tableChatView.adjustedContentInset.bottom - tableChatView.bounds.height)
        let contentHeight = tableChatView.contentSize.height
        let heightsSettled = contentHeight == initialBottomLastContentHeight
        initialBottomLastContentHeight = contentHeight
        if abs(tableChatView.contentOffset.y - bottom) > 0.5 {
            tableChatView.setContentOffset(CGPoint(x: tableChatView.contentOffset.x, y: bottom), animated: false)
        } else if heightsSettled, let started = initialBottomStartedAt,
                  Date().timeIntervalSince(started) > Self.initialBottomGrace {
            // At the bottom, the rows have stopped changing size, and the grace period is up:
            // this is the place, and the reader has the list from here.
            pendingInitialScrollToBottom = false
            initialBottomDeadline = nil
            initialBottomStartedAt = nil
        }
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

    // MARK: - Which conversation is open

    /// What this screen writes into "inEditorGroup": the group, and the topic within it.
    private var openConversationValue: [String] {
        return [dataGroup["group_id"] as? String ?? "", dataTopic["chat_id"] as? String ?? ""]
    }

    /// Says that this conversation is the one on screen, so nothing raises a card about it.
    ///
    /// Fix: see the same pair in EditorPersonal. Written once at load and deleted only on a pop,
    /// the registration was wrong in every case where a chat was left by any other means - and it
    /// never displaced the personal chat registered before it, so a message from the person whose
    /// chat you had opened earlier stayed silent while you read a group.
    private func registerAsOpenConversation() {
        SecureUserDefaults.shared.set(openConversationValue, forKey: "inEditorGroup")
        // One conversation is on screen at a time.
        SecureUserDefaults.shared.removeValue(forKey: "inEditorPersonal")
    }

    /// Takes back the registration, and only ever this screen's own.
    private func unregisterAsOpenConversation() {
        let stored: [String]? = SecureUserDefaults.shared.value(forKey: "inEditorGroup") ?? nil
        guard stored == openConversationValue else {
            return
        }
        SecureUserDefaults.shared.removeValue(forKey: "inEditorGroup")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareNavigationBar()
        addPreviewHeaderIfNeeded()
        // A preview is not a conversation being read - see isPreview.
        if !isPreview {
            registerAsOpenConversation()
        }
        // The placement is settled here, while the push animation still covers the screen,
        // rather than over the layout passes that follow it - see settleInitialBottomNow.
        settleInitialBottomNow()
        // Members are added and removed on the group's own screen, which is the screen this one
        // comes back from. The list is read again here and the bar redrawn only if it has really
        // changed - a bar rebuilt on every appearance for nothing would be worse than the query.
        let shown = groupMembersLine
        invalidateGroupMembersLine()
        if let shown = shown, !isSearching, membersOfThisGroup() != shown {
            changeAppBar()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        prepareNavigationBar()
        updateProfile()
        // Anything that arrived while this screen was being built gets its chance now.
        applyPendingStatusUpdates()
        // The conversation is open and its collages are built by now: anything inside one that has
        // not been reported as seen is reported here.
        sweepCollageReadReceipts()
        // A recording carried in on the strip belongs to a bubble here again. Asked for now, and
        // once more a moment later: the conversation being left tears its players down after this
        // one has already drawn, so the strip may not have been handed anything yet.
        reclaimPlayingAudioIfMine()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.reclaimPlayingAudioIfMine()
        }
        // The first page only covers the screen; topping it up now means the reader's first
        // flick upwards does not immediately run out of messages.
        DispatchQueue.main.async { [weak self] in
            self?.prefetchOlderMessagesIfIdle()
        }
        // A row that changes height a beat later - a picture reporting its own size, a page of
        // older messages landing - changes it inside the table, and that does not always ask
        // this screen to lay out again. So the opening placement is looked at by the clock too,
        // for as long as it is still in charge of where the list sits.
        for delay in [0.1, 0.25, 0.5, 0.8] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.applyPendingInitialBottomScroll()
            }
        }
        // Fix: a chat with unread messages opens parked at the first of them, which is not the
        // bottom - so the button that takes the reader to the end belongs on screen from the
        // start, and it never was. The one place that asked for it ran inside the load, before
        // the table had laid out: it measured a content height of nothing, concluded the list
        // was already at its end, and asked for nothing. And had it asked, addButtonScrollToBottom
        // returns early during the load by design. It is asked again once the placement has
        // settled, by the same test that decides it while scrolling.
        for delay in [0.35, 0.9, 1.6] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, !self.isInitialLoading, !self.isPreview else {
                    return
                }
                self.checkNewMessage(tableView: self.tableChatView)
            }
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
        // After the colour, not before: the camera takes the microphone's own background to make
        // one capsule of the two, and there is nothing to take until it has been set.
        installVideoNoteButton()
        refreshSendOrRecordButton()
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
        // Coming back to the app is reading whatever is on screen - see
        // markVisibleMessagesRead.
        center.addObserver(self, selector: #selector(onAppBecameActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
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
        // Fix: the list carried a top inset of -25, which pulls its rows up by 25 points inside
        // a frame that is exactly as tall as the rows are - so the last 25 points of the last
        // row sat below the bottom edge and could only be reached by scrolling a list nobody
        // thinks to scroll. There is no header to make room for; there never was.
        tableMention.contentInset = .zero
        // The height of the list is worked out as 44 points a row, so say so rather than leaving
        // it to whatever the storyboard's estimate happens to be.
        tableMention.rowHeight = ChatMentionList.rowHeight
        tableMention.estimatedRowHeight = ChatMentionList.rowHeight
        tableMention.separatorInset = UIEdgeInsets(top: 0, left: 52, bottom: 0, right: 0)
        tableMention.keyboardDismissMode = .none
        tableMention.showsVerticalScrollIndicator = false
        // A card, the way the rest of the input area is drawn, rather than a bare table sitting
        // against the wallpaper.
        tableMention.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        tableMention.layer.cornerRadius = 12
        tableMention.layer.cornerCurve = .continuous
        tableMention.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tableMention.clipsToBounds = true
        // Fix: where this list sat was worked out by hand, in eight different places, from the
        // keyboard's height plus the text field's height plus a hand-picked 25 - and then nudged
        // by another number every time the input area grew or shrank: +40 when a reply preview
        // opened, -50 when it closed, +120 when a link preview opened, -80 when it closed. The
        // numbers did not agree with each other or with the bars they were standing in for, so
        // the error accumulated: with a reply preview and a link preview both up, the bottom of
        // the list ended up underneath them. It is pinned to the top of the input area now.
        // Whatever that area happens to contain - a reply preview, a link preview, both, or a
        // keyboard under it - the list sits on top of it and nothing has to be calculated.
        contraintBottomMention.isActive = false
        tableMention.bottomAnchor.constraint(equalTo: viewTextfield.topAnchor).isActive = true
        // The storyboard leaves it 150 tall so it can be seen while the screen is being laid
        // out. Hiding it used to be a matter of pushing it off the bottom of the screen; now it
        // is away when it has no height, so it has to start with none.
        heightTableMention.constant = 0
        
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
            self.unregisterAsOpenConversation()
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
            // Fix: a cancel button was put in the navigation bar here, beside a search field laid
            // out by the search bar - two layouts, and they disagreed by 5pt. The search bar
            // carries its own now, so the row is left empty for it to fill.
            self.navigationItem.rightBarButtonItems = nil
            self.navigationItem.rightBarButtonItem = nil
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
        markerCount = counter
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

        // Kept whatever the table's scrollability, so switching scrolling off - which some
        // gestures do to hold the list still - cannot drop the inset the content is laid out
        // against and shift the whole conversation by it.
        tableChatView.contentInsetAdjustmentBehavior = .always
        tableChatView.delegate = self
        // Fix: a scroll view holds a touch back from whatever is under it for about 150ms while
        // it decides whether the finger is going to drag - and a tap is over before that. So the
        // quote a message replies to, a mention, a link: none of them showed a pressed look on
        // a plain tap, only on a held one. Measured off a recording, our own reply container
        // showed zero pressed frames at 60fps before the jump it led to; the reference shows it
        // pressed from the first frame. Touches go straight through now. Dragging still works
        // the same way it does in the reference: canCancelContentTouches, on by default, takes
        // the touch back the moment the finger moves, and the pressed look is lifted with it.
        tableChatView.delaysContentTouches = false
        tableChatView.panGestureRecognizer.delaysTouchesBegan = false
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
                        // Fix: this painted the whole row yellow for a second - the second of two
                        // highlights this screen had. The same one as a quote tap now, on the
                        // bubble: see BubbleHighlight.
                        if let cell = self.tableChatView.cellForRow(at: indexPath) {
                            BubbleHighlight.flash(in: cell, tag: EditorGroup.bubbleTag)
                        }
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
                pendingUnreadMarkerDeadline = Date().addingTimeInterval(2.5)
                unreadMarkerLastContentHeight = -1
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
                                let mId = readReceiptIds(for: dataMessages[i])
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
                                    let mId = readReceiptIds(for: dataMessages[i])
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
                        // The restored text kept the placeholder's grey, which is also what the
                        // bar reads as "nothing written" - so it is given the colour typed text
                        // has, and the bar is told, the same as the personal editor.
                        textFieldSend.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black
                        refreshSendOrRecordButton()
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
                        let mId = readReceiptIds(for: dataMessages[i])
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
                            self.tableChatView.reloadRowsKeepingPlace(at: [IndexPath(row: row!, section: section!)])
                        }
                    }
                })
            }
        }
        trimPinnedMessages()
        let dataMessagesPin = self.pinnedMessagesForBanner()
        pinAllMessages(dataMessages: dataMessagesPin)
    }
    
    static func conditionSendRead(scope: String, fPin: String, messageId: String) -> Bool {
        return scope != MessageScope.CALL && scope != MessageScope.MISSED_CALL && !messageId.contains("NTFPIN_") && fPin != "-999"
    }
    
    /// Whether this person is someone the reader can open a private conversation with.
    ///
    /// A group carries people the reader has never added - that is what a group is - and their
    /// names come from GROUPZ_MEMBER, not from the contact list. BUDDY is the contact list, so
    /// being in it is the first question, and it is asked of the same table every other screen
    /// asks. The second is whether either of them has blocked the other: `ex_block` is "1" when
    /// the reader blocked this person and "-1" when this person blocked the reader, the same two
    /// values the profile screen refuses a call on, and neither leads anywhere worth offering.
    private func canOpenPrivateChat(with f_pin: String) -> Bool {
        guard !f_pin.isEmpty, f_pin != User.getMyPin() else {
            return false
        }
        var reachable = false
        Database.shared.database?.inTransaction({ (fmdb, _) in
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT ifnull(ex_block, '0') FROM BUDDY where f_pin = '\(f_pin)'"), cursor.next() {
                let blocked = cursor.string(forColumnIndex: 0) ?? "0"
                reachable = blocked != "1" && blocked != "-1"
                cursor.close()
            }
        })
        return reachable
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
    ///
    /// `olderThan` and `newerOrEqual` are the second way in, and the reason for it: paging by
    /// position means `ORDER BY server_date LIMIT n OFFSET m`, and SQLite answers that by walking
    /// and discarding m rows every single time. The deeper the reader has scrolled, the longer
    /// that takes - a conversation of a few thousand messages spends the better part of a second
    /// in there, on the main thread, which is the freeze in the middle of a fling. Given a date
    /// range instead, the same read is an index range: a hundred rows touched, and the same cost
    /// however deep it is.
    private func getData(offset: Int64 = 0, limit: Int64 = -1, prepend: Bool = false, marksFirstAsUnread: Bool = false,
                         olderThan: String? = nil, newerOrEqual: String? = nil) {
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                // Either a date range - an index range, cheap at any depth - or the old position
                // window. See the note on getData for why the second one is worth avoiding.
                var window = "order by server_date asc LIMIT \(limit) OFFSET \(offset)"
                if let olderThan = olderThan {
                    var bounds = "AND server_date < \(olderThan)"
                    if let newerOrEqual = newerOrEqual {
                        bounds += " AND server_date >= \(newerOrEqual)"
                    }
                    window = "\(bounds) order by server_date asc"
                }
                let query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, last_edited, gif_id, is_forwarded_message, attachment_speciality, is_pinned FROM MESSAGE where \(self.messageWhereClause()) \(window)"
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
                        // Fix: this asked the filesystem where the documents directory is, and
                        // then whether two files exist, for every single row of every page - and
                        // the second of those two was asked even for a message carrying no file
                        // at all, which is a stat on the documents directory itself, a hundred
                        // times a page, for an answer that means nothing. A page read while the
                        // reader was flinging the list therefore spent its time in the
                        // filesystem, on the main thread, and that is the stall that stopped the
                        // scroll. The directory is looked up once for the whole app and the
                        // question is only asked of rows that actually carry something.
                        let carriedVideo = row["video_id"] as? String ?? ""
                        let carriedFile = row["file_id"] as? String ?? ""
                        if !carriedVideo.isEmpty {
                            row["progress"] = isFilePresent(carriedVideo) ? 100.0 : 0.0
                        } else if !carriedFile.isEmpty {
                            row["progress"] = isFilePresent(carriedFile) ? 100.0 : 0.0
                        } else {
                            row["progress"] = 0.0
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
                                // A run is also broken where the pictures stop being in the same
                                // state. A collage is offered, fetched and opened as one thing -
                                // one blur over all of it, one size, one tap - and none of that
                                // means anything for a group of pictures where some are here and
                                // some are not. So pictures already on this device gather with
                                // each other, pictures still to be fetched gather with each other,
                                // and where the two meet the run ends.
                                let lastIsHere = isFilePresent(last.imageId)
                                let thisIsHere = isFilePresent(row["image_id"] as? String ?? "")
                                breaksRun = (last.dataMessage["f_pin"] as? String ?? "") != (row["f_pin"] as? String ?? "")
                                    || lastIsHere != thisIsHere
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
                            self.markerCount = self.counter
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
        reachedOldestMessage = false
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
        var messageId: String?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            var total: Int64 = 0
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT COUNT(*) FROM MESSAGE where \(self.readableMessageWhereClause())"), cursor.next() {
                total = cursor.longLongInt(forColumnIndex: 0)
                cursor.close()
            }
            let position = total - Int64(unread)
            guard position >= 0 else {
                return
            }
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT message_id FROM MESSAGE where \(self.readableMessageWhereClause()) order by server_date asc LIMIT 1 OFFSET \(position)"), cursor.next() {
                messageId = cursor.string(forColumnIndex: 0)
                cursor.close()
            }
        })
        return messageId
    }

    /// The same conversation, but only the messages that can be unread.
    ///
    /// Fix: counting back `unread` places from the total used the total of *everything* the
    /// conversation holds, and not everything in it is a message somebody reads. A group keeps
    /// its own notices in the same table - "pinned a message" is written here as an NTFPIN row,
    /// by this screen and by IncomingThread - and they never count towards the unread number,
    /// which is the same reason no read receipt is ever sent for them (conditionSendRead). One
    /// of those among the newest messages pushed the count a place too far and the marker landed
    /// past the first unread message, leaving it above the top of the screen.
    private func readableMessageWhereClause() -> String {
        return "\(messageWhereClause()) AND message_id NOT LIKE 'NTFPIN%'"
    }

    /// Whether there are older messages left in the database.
    /// Set once a page of older messages comes back short: there is nothing further back.
    ///
    /// Fix: whether there was more to read was answered by `loadedOffset > 0`, a number kept in
    /// step by counting rows in the database. The counting is what this is here to avoid - see
    /// loadOlderMessages - so the end of the conversation is recognised by reaching it instead.
    private var reachedOldestMessage = false

    private var hasOlderMessages: Bool {
        return !reachedOldestMessage && loadedOffset > 0
    }

    /// The date of the oldest message this screen is holding, which is where the next page back
    /// begins. Read from what is in hand, so it costs nothing.
    private var oldestLoadedDate: String? {
        // Checked for being a number, not merely non-empty: it is written straight into the
        // query, and anything else there would make a nonsense of it rather than an error.
        guard let date = dataMessages.first(where: {
            Int64((($0["server_date"] as? String) ?? "").trimmingCharacters(in: .whitespaces)) != nil
        })?["server_date"] as? String else {
            return nil
        }
        return date.trimmingCharacters(in: .whitespaces)
    }

    /// The date one page further back, found by walking at most a page of index entries.
    ///
    /// This is the whole trick. Asking for "a hundred rows, skipping the two thousand before
    /// them" makes SQLite walk two thousand rows to throw them away. Asking for "the hundredth
    /// row back from here" walks a hundred index entries and stops. The page itself is then read
    /// as a date range, which is another index range.
    private func dateOnePageBack(before date: String, pageSize: Int64) -> String? {
        var found: String?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            let query = "SELECT server_date FROM MESSAGE where \(self.messageWhereClause())"
                + " AND server_date < \(date) order by server_date desc LIMIT 1 OFFSET \(pageSize - 1)"
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query), cursor.next() {
                found = cursor.string(forColumnIndex: 0)
                cursor.close()
            }
        })
        return found
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
        // Never under momentum. The read itself is cheap; what is not cheap is putting the list
        // back afterwards, because writing the scroll position from outside ends a fling where
        // it stands. Every caller is either finger-down or at rest, and this is what makes that
        // a guarantee rather than an arrangement.
        if tableChatView.isDecelerating, !tableChatView.isDragging {
            return
        }
        isLoadingOlderMessages = true
        defer { isLoadingOlderMessages = false }
        // Fix: refreshWindowBounds() used to run here, and it asks the database to count the
        // conversation twice - once for the oldest message on screen and once for the newest.
        // Those two counts, plus the page read's own OFFSET walk, meant three passes over the
        // whole conversation for every page turn, all of them on the main thread while the
        // reader was scrolling. That is the second the list stood still for. Nothing here needs
        // an exact position any more: the page is read by date. The bounds are still corrected
        // whenever a message arrives, which is the only thing that moves them.
        guard let upperBound = oldestLoadedDate else {
            return
        }
        let rowsBeforeLoad = dataMessages.count

        // Sitting at the newest message is a place of its own, and it is where a chat that has
        // just been opened sits. It has to be remembered as that, because the rows above have
        // never been on screen and are still being guessed at: anchoring the list on the top
        // row hands the bottom over to whatever those guesses turn out to be, and the chat
        // scrolls itself up by a message the moment they are corrected.
        let bottomOffset = tableChatView.contentSize.height - tableChatView.bounds.height
            + tableChatView.adjustedContentInset.bottom
        // The opening placement outranks the measurement: while it is still in charge the list
        // belongs at the newest message, whatever the offset happens to read mid-settle.
        let wasAtBottom = pendingInitialScrollToBottom || bottomOffset - tableChatView.contentOffset.y <= 24

        let anchorIndexPath = tableChatView.indexPathsForVisibleRows?.first
        var anchorMessageId: String?
        var anchorDistanceFromTop: CGFloat = 0
        if let anchorIndexPath = anchorIndexPath {
            anchorMessageId = message(at: anchorIndexPath)?["message_id"] as? String
            anchorDistanceFromTop = tableChatView.rectForRow(at: anchorIndexPath).minY - tableChatView.contentOffset.y
        }

        // The lower edge of the page, or nothing when fewer than a page remains - in which
        // case the range is open-ended and this is the last page there is.
        let lowerBound = dateOnePageBack(before: upperBound, pageSize: EditorGroup.olderMessagePageSize)
        if lowerBound == nil {
            reachedOldestMessage = true
        }
        getData(prepend: true, olderThan: upperBound, newerOrEqual: lowerBound)
        let added = Int64(dataMessages.count - rowsBeforeLoad)
        // Kept arithmetically rather than counted. It is used for the other direction and for
        // bridging a jump, both of which re-derive what they need.
        loadedOffset = max(0, loadedOffset - added)
        loadedCount += added

        lastEmptyOlderPage = added == 0 ? Date() : nil

        // Fix: the rows were handed to the table as a list of insertions and deletions rather
        // than a reload, to save rebuilding the cells on screen - and it left blank bubbles
        // behind. A batch update settles over the turn of the run loop that follows it, and the
        // scroll position is put back inside the same turn: the table was asked for rows it had
        // not finished re-numbering, answered that those rows did not exist, and drew them
        // empty - and an empty cell it believes in stays empty until something reloads it. The
        // saving was small in any case. A reload discards the cells on screen but only builds
        // the handful that are visible, and the ones it takes out of the reuse pool are the same
        // cells it just put there, so their bubbles are recognised and kept. What made a reload
        // expensive here was being asked for an estimated height for every row of the whole
        // conversation while each of those answers walked the whole conversation - and that is
        // what message(at:) no longer does.
        UIView.performWithoutAnimation {
            tableChatView.reloadData()
            tableChatView.layoutIfNeeded()
        }
        // Fix: put back where the reader was, and then check the answer and put it back again
        // until it stops moving - all before this returns, so no frame is ever drawn in the
        // wrong place. One pass was not enough: moving the list brings different rows on
        // screen, measuring them changes what the rows above add up to, and the place worked
        // out from the old numbers is then a row's worth out. That was the drop-and-recover
        // seen when a page landed just after a chat opened.
        for _ in 0..<4 {
            var target: CGFloat?
            if wasAtBottom {
                let lowest = -tableChatView.adjustedContentInset.top
                target = max(lowest, tableChatView.contentSize.height
                             + tableChatView.adjustedContentInset.bottom - tableChatView.bounds.height)
            } else if let anchorMessageId = anchorMessageId,
                      let restored = indexPath(forMessageId: anchorMessageId) {
                target = tableChatView.rectForRow(at: restored).minY - anchorDistanceFromTop
            }
            guard let target = target, abs(tableChatView.contentOffset.y - target) > 0.5 else {
                break
            }
            tableChatView.setContentOffset(CGPoint(x: tableChatView.contentOffset.x, y: target), animated: false)
            UIView.performWithoutAnimation {
                tableChatView.layoutIfNeeded()
            }
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
        // The window is being replaced, so whether the oldest message had been reached is a
        // fact about a window that no longer exists.
        reachedOldestMessage = false
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
        // The window is being replaced, so whether the oldest message had been reached is a
        // fact about a window that no longer exists.
        reachedOldestMessage = false
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
        // Fix: not while the chat is still being placed at its newest message. A page landing
        // above the screen moves the very ground that placement is standing on, and the two
        // corrections one after the other are the bounce seen on opening a chat: the list drops
        // by a row as the page lands, then is pulled back. Nobody can flick a chat they have not
        // been shown yet, so this loses nothing by waiting for the placement to finish.
        guard !pendingInitialScrollToBottom else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.prefetchOlderMessagesIfIdle()
            }
            return
        }
        guard !tableChatView.isDragging, !tableChatView.isDecelerating else {
            return
        }
        // Only worth doing when the end of what is loaded is within reach of a flick; further
        // away there is nothing to gain by reading more. This is also where a fling that outran
        // its loaded conversation is caught: it rubber-bands at the top of what is loaded, and
        // the page is read here, once it has come to rest.
        guard tableChatView.contentOffset.y < tableChatView.frame.height * EditorGroup.olderMessageLead else {
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
        // Fix: this walked the whole loaded conversation, comparing every message's date as it
        // went, to answer where one row was - and the table asks it for every row it has
        // whenever the rows change. Reading a page therefore cost a scan of the entire chat per
        // row of the entire chat. The positions kept for the day sections lead straight to it.
        let date = dataDates[indexPath.section]
        guard Thread.isMainThread else {
            let rows = dataMessages.filter({ $0["chat_date"] as? String ?? "" == date })
            return indexPath.row < rows.count ? rows[indexPath.row] : nil
        }
        guard let indexes = messageIndexes(onDate: date), indexPath.row < indexes.count else {
            return nil
        }
        let index = indexes[indexPath.row]
        return index < dataMessages.count ? dataMessages[index] : nil
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
    /// The reader has taken the conversation over, so the placement it opened with is no longer
    /// in force.
    ///
    /// Fix: that placement - at the newest message, or at the first unread one - is not a single
    /// scroll but a hold. It is re-applied on every layout pass for up to two and a half seconds,
    /// because a row's real height is only known once it has been drawn, and each pass corrects
    /// what the last one guessed. The only thing that dropped it early was a finger dragging the
    /// list. Starting a reply is not that: pulling a bubble across is its own gesture, and the
    /// reply bar it opens lays the screen out again - so a reply begun inside those two and a half
    /// seconds hit the hold on that very layout pass and threw the reader back to where the chat
    /// had opened. Everything the reader does to a conversation is taking it over, not only
    /// dragging it.
    private func endOpeningPlacement() {
        pendingUnreadMarkerScroll = nil
        pendingUnreadMarkerDeadline = nil
        pendingInitialScrollToBottom = false
        initialBottomDeadline = nil
        initialBottomStartedAt = nil
    }

    private func applyPendingUnreadMarkerScroll() {
        guard let marker = pendingUnreadMarkerScroll else {
            return
        }
        // Long enough is long enough, whatever state the table has got itself into.
        if let deadline = pendingUnreadMarkerDeadline, Date() > deadline {
            pendingUnreadMarkerScroll = nil
            return
        }
        guard tableChatView.numberOfSections > 0, tableChatView.bounds.height > 0,
              let indexPath = indexPath(forMessageId: marker),
              indexPath.section < tableChatView.numberOfSections,
              indexPath.row < tableChatView.numberOfRows(inSection: indexPath.section) else {
            // Nothing to aim at yet - the table may not have any rows this pass. Costs nothing:
            // waiting is not an attempt, and the deadline above is what stops this going on.
            return
        }
        let rowRect = tableChatView.rectForRow(at: indexPath)
        let topInset = tableChatView.adjustedContentInset.top
        // A plain table pins the date header over the top of the visible area, so the row has
        // to start below it - otherwise the header covers the marker it was scrolled to.
        let headerHeight = tableChatView.rectForHeader(inSection: indexPath.section).height
        let lowest = -topInset
        let highest = max(lowest, tableChatView.contentSize.height + tableChatView.adjustedContentInset.bottom - tableChatView.bounds.height)
        let desired = min(max(rowRect.minY - topInset - headerHeight, lowest), highest)
        // Fix: this used to stop the moment a pass found the offset already right. But `desired`
        // is worked out from the row heights the table holds *now*, and early on those are
        // estimates - so a pass could agree with a guess, stop correcting, and then have the
        // content shift underneath it as the real heights arrived. It is only finished when the
        // offset is right *and* the content stopped changing height between two passes, which is
        // what "the heights have settled" actually means.
        let contentHeight = tableChatView.contentSize.height
        let heightsSettled = contentHeight == unreadMarkerLastContentHeight
        unreadMarkerLastContentHeight = contentHeight
        if abs(tableChatView.contentOffset.y - desired) > 0.5 {
            tableChatView.setContentOffset(CGPoint(x: tableChatView.contentOffset.x, y: desired), animated: false)
        } else if heightsSettled {
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
            let query = "SELECT message_id, f_pin, message_text, server_date, is_pinned, file_id, image_id, video_id, audio_id, gif_id FROM MESSAGE where \(self.messageWhereClause()) AND is_pinned <> '0' AND is_pinned IS NOT NULL order by CAST(is_pinned AS INTEGER) desc LIMIT \(PinnedMessages.maximum)"
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
        return PinnedMessages.newest(pinned)
    }

    /// Brings this conversation back to at most three pins in the database, and forgets in
    /// memory the ones it let go.
    ///
    /// A conversation can be holding more than three before this screen ever opens - pins arrive
    /// from other participants and other devices - and nothing else takes one away.
    private func trimPinnedMessages() {
        let removed = PinnedMessages.trim(conversation: messageWhereClause())
        guard !removed.isEmpty else {
            return
        }
        for messageId in removed {
            if let idx = dataMessages.firstIndex(where: { $0["message_id"] as? String == messageId }) {
                dataMessages[idx][TypeDataMessage.is_pinned] = "0"
            }
        }
    }

    /// Unpins these, in the order given, and says whether every one of them went.
    ///
    /// Fix: replacing a pin unpinned exactly one message, which is right only when there are
    /// exactly three to begin with. A conversation that arrived holding four or more kept the
    /// extra ones for good, since nothing else ever took a pin away.
    private func unpinInOrder(_ messages: [[String: Any?]], completion: @escaping (Bool) -> Void) {
        guard let first = messages.first else {
            completion(true)
            return
        }
        proceedPinUnpinMessage(checkDataPinned: first, isPinned: false) { removed in
            guard removed else {
                completion(false)
                return
            }
            self.unpinInOrder(Array(messages.dropFirst()), completion: completion)
        }
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
                let formatter = EditorGroup.chatDateFormatter(format: ChatDayLabel.format(for: date), cached: &EditorGroup.dayDateFormatter)
                let stringFormat = formatter.string(from: date as Date)
                if !dataDates.contains(stringFormat){
                    dataDates.append(stringFormat)
                }
                return stringFormat
            }
        }
    }
    
    /// The names of everybody in this group, in the order the bar lists them, or nil while the
    /// list has not been read yet.
    private var groupMembersLine: String?

    /// Reads that list. Ordered by name, with the reader last and called "You" - the way the
    /// reference lists a group's members under its name.
    ///
    /// Read once and kept: `changeAppBar` runs on every session opening and closing, and the
    /// membership does not change between them. `invalidateGroupMembersLine` is what says it has.
    private func membersOfThisGroup() -> String {
        if let cached = groupMembersLine {
            return cached
        }
        let groupId = dataGroup["group_id"] as? String ?? ""
        guard !groupId.isEmpty else {
            return ""
        }
        let idMe = User.getMyPin() ?? ""
        var names: [String] = []
        var meIsMember = false
        Database.shared.database?.inTransaction({ (fmdb, _) in
            // Thirty is well past what the bar can show - it is here so a group of hundreds does
            // not build a string nobody will ever read to the end of.
            let query = "SELECT trim(first_name || ' ' || ifnull(last_name, '')) AS nm, f_pin "
                + "FROM GROUPZ_MEMBER WHERE group_id = '\(groupId)' "
                + "ORDER BY nm COLLATE NOCASE ASC LIMIT 30"
            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query) {
                while cursor.next() {
                    let name = cursor.string(forColumnIndex: 0) ?? ""
                    let pin = cursor.string(forColumnIndex: 1) ?? ""
                    if pin == idMe {
                        meIsMember = true
                    } else if !name.isEmpty {
                        names.append(name)
                    }
                }
                cursor.close()
            }
        })
        if meIsMember {
            names.append("You".localized())
        }
        let line = names.joined(separator: ", ")
        groupMembersLine = line
        return line
    }

    /// Says the membership has changed, so the bar reads it again next time it is drawn.
    private func invalidateGroupMembersLine() {
        groupMembersLine = nil
    }

    private func changeAppBar() {
        let viewAppBar = UIView()
        viewAppBar.frame.size = CGSize(width: self.view.frame.size.width, height: 44)
        
        if !isSearching {
            let imageProfile = UIImageView(frame: ChatHeaderMetrics.pictureFrame())
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
            // The bar sizes itself to whatever is free between the buttons - see
            // `ChatHeaderMetrics.layoutTitleView`, called once everything is in it.
            let titleNavigation = MarqueeLabel()
            viewAppBar.addSubview(titleNavigation)
            // Fix: the font was set after the text, and an official name is not text but an
            // attributed string built here with a flag in front of it - assigning `font`
            // afterwards does not reach inside one of those. So every official group's name was
            // drawn in the label's default 17pt regular while every other name used this, which
            // is what made an official chat's header look like a different screen. Settled first,
            // the attributed string is built with it.
            titleNavigation.textColor = .white
            titleNavigation.font = UIFont.systemFont(ofSize: ChatHeaderMetrics.titleFontSize + offset()).bold
            if (dataGroup["official"]  as? String ?? "" == "1") {
                if !isHistoryCC {
                    titleNavigation.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(dataGroup["f_name"]!!) (\(dataTopic["title"]!!))", size: ChatHeaderMetrics.flagSize, y: ChatHeaderMetrics.flagBaseline)
                } else {
                    titleNavigation.text = (dataGroup["f_name"] as? String)! + " " + "Contact Center".localized()
                }
            } else {
                titleNavigation.text = (dataGroup["f_name"] as? String ?? "") + " (\(dataTopic["title"] as? String ?? ""))"
            }

            // Who is in the group, under its name - what the reference puts there, and the one
            // thing this bar has that a personal chat's has not: a personal chat's second line
            // would only ever repeat the name above it.
            //
            // Not on a contact-centre history, where the people in the conversation are not a
            // membership and the line would be meaningless.
            var membersNavigation: UILabel?
            if !isHistoryCC {
                let members = membersOfThisGroup()
                if !members.isEmpty {
                    let subtitle = UILabel()
                    viewAppBar.addSubview(subtitle)
                    subtitle.text = members
                    subtitle.font = UIFont.systemFont(ofSize: ChatHeaderMetrics.subtitleFontSize + offset())
                    subtitle.textColor = .white.withAlphaComponent(0.7)
                    membersNavigation = subtitle
                }
            }

            ChatHeaderMetrics.layoutTitleView(viewAppBar, title: titleNavigation, subtitle: membersNavigation)
            navigationItem.titleView = viewAppBar
            titleText = titleNavigation.text
            previewHeaderLabel?.text = titleText
        } else {
            searchBar = ChatSearchBar()
            searchBar.autocapitalizationType = .none
            searchBar.delegate = self
            searchBar.searchTextField.tintColor = .mainColor
            searchBar.searchTextField.textColor = .black
//            searchBar.updateHeight(height: 36, radius: 18)
            searchBar.showsCancelButton = false
//            searchBar.setMagnifyingGlassColorTo(color: .white)
            // The same height as the button beside it, the magnifying glass and the word the
            // reference has in it - see ChatHeaderMetrics.dressSearchBar.
            //
            // Both themes get the light fill on purpose: the text in this field is black, and the
            // dark asset this used to draw is very nearly transparent, which left black text on a
            // near-black bar.
            ChatHeaderMetrics.dressSearchBar(searchBar, fill: UIColor(red: 248.0 / 255.0, green: 252.0 / 255.0, blue: 254.0 / 255.0, alpha: 1.0))
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
        // A round video note draws its own transfer, in its own control, from this same
        // notification. What follows walks the cell's views looking for an image view with a shape
        // layer in it and moves whatever it finds - which on a note is not the ring it thinks it
        // is. Left alone, it drew the old media machinery over a bubble that had already answered
        // for itself, which is the second appearance that turned up after Send again.
        if idx != nil, VideoNote.isNote(dataMessages[idx!]["video_id"] as? String) {
            return
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
                                            self.tableChatView.reloadRowsKeepingPlace(at: [indexPath])
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
                                                            self.tableChatView.reloadRowsKeepingPlace(at: [indexPath])
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
                // Fix: messages that landed while the app was away were spliced in and counted,
                // and that was all - so coming back to a conversation that was already open,
                // with the new message right there on screen, still left the chat list showing
                // it as unread and the senders with no read mark. Once the list has settled,
                // what is actually on screen is read.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                    self?.markVisibleMessagesRead()
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
                        self.tableChatView.reloadRowsKeepingPlace(at: [IndexPath(row: row!, section: section!)])
                    }
                }
                if !messageIdNotif.isEmpty {
                    self.appendNewMessage(messageId: messageIdNotif)
                }
            }
            // Fix: the banner was only rebuilt when the message was in the loaded window. A pin
            // can be on a message far older than that - the banner reads the database for exactly
            // that reason - so pinning or unpinning one from another device left the banner
            // showing what it had.
            let dataMessagesPin = self.pinnedMessagesForBanner()
            self.pinAllMessages(dataMessages: dataMessagesPin)
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
            
            // Fix: the unread count was cleared for every message that arrived, whether or
            // not the reader could see it land. A message that arrives while the conversation
            // is scrolled up - or while the app is in the background with this screen still
            // open behind it - has not been read, and saying it had left the sender without a
            // read mark and the chat list without its badge.
            //
            // The list follows the conversation down whenever it was already at the bottom,
            // app in the background or not - what arrived while the reader was away is then the
            // first thing in front of them when they come back, and the sweep on becoming
            // active is what reports it as read.
            let listWasAtBottom = self.isReaderAtBottomOfList
            let readerSawItArrive = self.isReaderPresent && listWasAtBottom
            if readerSawItArrive {
                self.counter = 0
                self.updateCounter(counter: self.counter)
            } else {
                self.counter += 1
            }
            // One more of the conversation's messages is now in the loaded window.
            self.loadedCount += 1
            if let collageRow = self.foldIntoImageGroup(row) {
                // Part of the run above it: no new row goes in, the row that draws the collage
                // is redrawn to take it.
                self.tableChatView.reloadRowsKeepingPlace(at: [collageRow])
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
            
            // Fix: whether the list followed the message down used to be decided by comparing
            // the last visible row's position inside its own section against a count of every
            // loaded message - two different things - and the read mark went out whenever this
            // screen was in a window at all, background included. Both follow the one question
            // that matters: did the reader watch it arrive.
            if listWasAtBottom {
                self.tableChatView.scrollToBottom()
                if readerSawItArrive {
                    self.reportedReadMessageIds.insert(messageId)
                    self.sendReadMessageStatus(
                        chat_id: self.dataTopic["chat_id"] as? String ?? "",
                        f_pin: fPin,
                        message_scope_id: messageScopeId,
                        message_id: messageId
                    )
                }
            } else {
                // It landed below the fold: the button carries the count until the reader
                // goes down to it.
                if !self.buttonScrollToBottom.isDescendant(of: self.view) {
                    self.addButtonScrollToBottom()
                }
                if !self.indicatorCounterBSTB.isDescendant(of: self.view) {
                    self.addCounterAtButttonScrollToBottom()
                } else {
                    self.labelCounter.text = "\(self.counter)"
                }
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
                        } else if chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] != "1" {
                            // The row is not here yet - keep the answer until it is.
                            self.parkStatusUpdate(messageId: chatData[CoreMessage_TMessageKey.MESSAGE_ID] ?? "",
                                                  status: chatData[CoreMessage_TMessageKey.STATUS] ?? "")
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
                        } else if chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] != "1" {
                            self.parkStatusUpdate(messageId: idMessage,
                                                  status: chatData[CoreMessage_TMessageKey.STATUS] ?? "")
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
                            } else {
                                self.parkStatusUpdate(messageId: String(listMessageId[i]),
                                                      status: chatData[CoreMessage_TMessageKey.STATUS] ?? "")
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
            
            // Same as the acknowledgement path: an answer that beats its row is kept, not lost,
            // and an index the table does not have yet is never handed to reloadRows.
            if let idx = idx, self.applyStatus(status, at: idx) {
                return
            }
            self.parkStatusUpdate(messageId: messageId, status: status)
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
                self.tableChatView.reloadRowsKeepingPlace(at: [IndexPath(row: row!, section: section!)])
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
    

    /// Statuses that arrived before the row they belong to. Sending writes the message to the
    /// database and puts it on screen, and the server's acknowledgement comes back on its own
    /// schedule - on an older device (an X or an XR, where the main thread has more to do and less
    /// to do it with) that answer regularly lands before the row has finished being inserted. Every
    /// path below used to be written as `if idx != nil { ... }` with no else, so an acknowledgement
    /// that arrived a moment early was dropped on the floor: the database said sent, the bubble
    /// kept its clock, and the only cure was killing the app so the list was read from the database
    /// again. Parked here instead, and applied the moment the row exists.
    private var pendingStatusUpdates: [String: String] = [:]

    private func parkStatusUpdate(messageId: String, status: String) {
        guard !messageId.isEmpty, !status.isEmpty else { return }
        // Status only ever moves forward, so a late arrival never displaces a later one.
        if let parked = pendingStatusUpdates[messageId], (Int(parked) ?? -1) >= (Int(status) ?? -1) {
            return
        }
        pendingStatusUpdates[messageId] = status
        scheduleParkedStatusSweep()
    }

    /// Whether a sweep is already booked, so a burst of acknowledgements books one, not twenty.
    private var parkedStatusSweepScheduled = false
    /// When to look again. A parked update is waiting for a row that is being inserted right now,
    /// so the first look is almost always the last; the later ones cover a device that is busy
    /// enough to still be laying out. It ends - a row that never arrives is a row this screen is
    /// not showing, and the database keeps the truth for the next time it is opened.
    private static let parkedStatusSweepDelays: [TimeInterval] = [0.2, 0.5, 1.0, 2.0, 4.0]

    private func scheduleParkedStatusSweep(from step: Int = 0) {
        guard !pendingStatusUpdates.isEmpty else { return }
        guard step < Self.parkedStatusSweepDelays.count else { return }
        if step == 0 {
            guard !parkedStatusSweepScheduled else { return }
            parkedStatusSweepScheduled = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.parkedStatusSweepDelays[step]) { [weak self] in
            guard let self = self else { return }
            self.applyPendingStatusUpdates()
            if self.pendingStatusUpdates.isEmpty {
                self.parkedStatusSweepScheduled = false
            } else {
                self.scheduleParkedStatusSweep(from: step + 1)
                if step + 1 >= Self.parkedStatusSweepDelays.count {
                    self.parkedStatusSweepScheduled = false
                }
            }
        }
    }

    /// Called wherever the table has just gained rows, so anything parked gets its chance.
    func applyPendingStatusUpdates() {
        guard !pendingStatusUpdates.isEmpty else { return }
        for (messageId, status) in pendingStatusUpdates {
            if let idxMessageIdParent = groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == messageId }) }),
               let idxInImages = groupImages[idxMessageIdParent].value.firstIndex(where: { $0.messageId == messageId }) {
                groupImages[idxMessageIdParent].value[idxInImages].status = status
                groupImages[idxMessageIdParent].value[idxInImages].dataMessage["status"] = status
                let collageId = groupImages[idxMessageIdParent].key
                if let idx = dataMessages.firstIndex(where: { $0["message_id"] as? String == collageId }),
                   applyStatus(status, at: idx) {
                    pendingStatusUpdates.removeValue(forKey: messageId)
                }
                continue
            }
            guard let idx = dataMessages.firstIndex(where: { $0["message_id"] as? String == messageId }) else {
                continue
            }
            if applyStatus(status, at: idx) {
                pendingStatusUpdates.removeValue(forKey: messageId)
            }
        }
    }

    /// Writes the new status into the row and redraws it. Returns false when the row is not yet
    /// something the table can be asked to reload, so the caller can park the update rather than
    /// lose it - and so that an index the table does not have yet is never handed to reloadRows,
    /// which would take the app down rather than miss a tick.
    @discardableResult
    private func applyStatus(_ status: String, at idx: Int) -> Bool {
        guard idx >= 0, idx < dataMessages.count else { return false }
        // Status only ever moves forward: a late "sent" must not undo a "read".
        let current = Int(dataMessages[idx]["status"] as? String ?? "") ?? -1
        let incoming = Int(status) ?? -1
        if current > incoming { return true }
        dataMessages[idx]["status"] = status
        let date = dataMessages[idx]["chat_date"] as? String ?? ""
        let messageId = dataMessages[idx]["message_id"] as? String ?? ""
        guard let section = dataDates.firstIndex(of: date),
              let row = messages(onDate: date).firstIndex(where: { $0["message_id"] as? String == messageId }) else {
            return false
        }
        guard section < tableChatView.numberOfSections,
              row < tableChatView.numberOfRows(inSection: section) else {
            return false
        }
        tableChatView.reloadRowsKeepingPlace(at: [IndexPath(row: row, section: section)])
        return true
    }

    private func updateStatusMessage(idx: Int?, chatData: [String: String]) {
        guard let idx = idx, idx >= 0, idx < dataMessages.count,
              let status = chatData[CoreMessage_TMessageKey.STATUS] else {
            return
        }
        // The two Int(...)! here used to be force unwraps inside a do/catch that could never have
        // caught them - a status that was empty or not a number took the app down.
        if !applyStatus(status, at: idx) {
            parkStatusUpdate(messageId: dataMessages[idx]["message_id"] as? String ?? "", status: status)
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
                    // The group itself was updated - that may have been its membership.
                    invalidateGroupMembersLine()
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
                // Whatever changed about the group may have been its membership.
                self.invalidateGroupMembersLine()
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
        showProfile(pin: sender.message_id)
    }

    /// Opens the profile of the person a pin belongs to.
    ///
    /// The picture beside a message has always led here; a coloured @mention inside one leads
    /// here now as well, so both go through the same implementation rather than a second copy
    /// of it. "-999" and "-997" are nobody in particular (a system message, and @All), and stay
    /// where they are.
    func showProfile(pin: String) {
        if isHistoryCC {
            return
        }
        let idMe = User.getMyPin() as String?
        if pin == idMe {
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
            controller.data = pin
            controller.flag = .me
            navigationController?.show(controller, sender: nil)
        } else if pin != "-999" && pin != "-997"  {
            let data = User.getDataCanNil(pin: pin)
            if data != nil {
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                controller.flag = .friend
                controller.user = data
                controller.name = data!.fullName
                controller.data = pin
                controller.picture = data!.thumb
                self.navigationController?.show(controller, sender: nil)
            } else {
                let dataUser = getDataProfile(f_pin: pin, message_id: "")
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                controller.flag = .invite
                controller.user = nil
                controller.name = dataUser["name"]!
                controller.data = pin
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
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: listData[i]["f_pin"]  as? String ?? "", message_scope_id: MessageScope.GROUP, message_id: self.readReceiptIds(for: listData[i]))
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
                            self.sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: listData[i]["f_pin"]  as? String ?? "", message_scope_id: MessageScope.GROUP, message_id: self.readReceiptIds(for: listData[i]))
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
    
    /// How long the conversation should take to follow the keyboard, and along what curve.
    ///
    /// Fix: the duration was taken from the notification and used as it came. The first keyboard
    /// of a session is announced with a duration of zero - the keyboard itself still slides up, a
    /// beat later, but the announcement says there is nothing to animate. Taken at its word, the
    /// conversation was moved up by a whole keyboard's height in a single frame and then sat there
    /// waiting for the keyboard to arrive and fill the gap it had left. That is the leap on the
    /// first reply after a chat is opened, and only the first: every reply after it finds the
    /// keyboard already on screen, so there is no keyboard movement left to announce. A floor
    /// under the duration costs nothing when the announcement is honest, and the curve is the
    /// keyboard's own so the two travel together rather than merely for the same length of time.
    private func keyboardTravel(_ info: NSDictionary) -> (duration: TimeInterval, options: UIView.AnimationOptions) {
        let announced = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let curve = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue
        let options: UIView.AnimationOptions = curve.map { UIView.AnimationOptions(rawValue: $0 << 16) } ?? .curveEaseInOut
        return (max(announced, 0.2), [options, .beginFromCurrentState])
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil && !isEditingMessage {
            // Nothing raises the keyboard while a chat is opening; a keyboard on screen is the
            // reader's own doing, and it lays the list out again just as the reply bar does.
            endOpeningPlacement()
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            let keyboardHeight: CGFloat = keyboardSize.height
            
            if self.constraintBottomAttachment.constant != keyboardHeight || self.constraintViewTextField.constant != keyboardHeight - 60 {
                if self.viewSticker.isDescendant(of: self.view) {
                    self.constraintBottomAttachment.constant = 0.0
                    self.viewSticker.removeConstraints(self.viewSticker.constraints)
                    self.viewSticker.removeFromSuperview()
                }
//                self.constraintViewTextField.constant = keyboardHeight - 60
                self.constraintBottomAttachment.constant = keyboardHeight
                self.keyboardHeightForMention = keyboardHeight
                // Measured before the layout changes, exactly as on the way out. This used to
                // work out how much of the list the keyboard was about to take that it was not
                // taking already; holding the distance from the end of the list covers that case
                // too, and a keyboard that merely changes height along with it.
                let wasShowing = self.listAnchor
                if isSearching {
                    self.constraintBottomContainerMultpileSelectSession.constant = -keyboardHeight
                }
                let travel = keyboardTravel(info)
                UIView.animate(withDuration: travel.duration, delay: 0, options: travel.options, animations: {
                    self.view.layoutIfNeeded()
                    // Fix: this used to scroll to the last remembered row, or all the way to the
                    // newest message, every time the keyboard came up - so tapping the input
                    // while reading something further up threw the reader back to the bottom.
                    // Shifting the content by exactly what the keyboard took leaves them looking
                    // at what they were looking at. Held against the end of the list rather than
                    // by that shift, so a reader already at the newest message stays there
                    // instead of being carried a keyboard's height past it.
                    self.restore(wasShowing)
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
            
            // Measured before anything moves, and put back after - see
            // restore(_:) for why this is not done by subtracting the
            // keyboard's height.
            let wasShowing = self.listAnchor
            self.constraintViewTextField.constant = 0
            self.constraintBottomAttachment.constant = 0
            self.constraintBottomContainerMultpileSelectSession.constant = 0
            keyboardHeightForMention = nil
            let travel = keyboardTravel(info)
            UIView.animate(withDuration: travel.duration, delay: 0, options: travel.options, animations: {
                self.view.layoutIfNeeded()
                self.restore(wasShowing)
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
    
    /// The button at the end of the input bar: a paper plane when there is something to send, a
    /// microphone when there is not - which is how the reference decides between the two.
    func refreshSendOrRecordButton() {
        let hasText = !(textFieldSend.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && textFieldSend.textColor != .lightGray
        wantsVoiceNote = !hasText
        // The camera belongs to an empty bar. Once there is something written the bar is about
        // sending that, and a second way to start a recording only gets in the way.
        videoNoteEntry?.setHidden(hasText)
        // Read off the microphone itself, every refresh, so the joined capsule follows it through
        // a theme change instead of holding whatever colour it was built with.
        videoNoteEntry?.matchAppearance(
            background: buttonSendChat.backgroundColor,
            tint: self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white)
        guard !hasText else {
            buttonSendChat.setImage(resizeImage(image: self.traitCollection.userInterfaceStyle == .dark ? UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.blackDarkMode) : UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal), for: .normal)
            return
        }
        let mic = UIImage(systemName: "mic.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold))
        buttonSendChat.setImage(mic?.withTintColor(self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white, renderingMode: .alwaysOriginal), for: .normal)
    }


    /// The camera beside the microphone, and the round-video screen it opens. Kept on the
    /// conversation so the button survives every refresh of the input bar.
    var videoNoteEntry: VideoNoteEntryPoint? {
        get { return objc_getAssociatedObject(self, &EditorVoiceNoteKeys.videoNote) as? VideoNoteEntryPoint }
        set { objc_setAssociatedObject(self, &EditorVoiceNoteKeys.videoNote, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Puts the camera in beside the microphone. Safe to call more than once.
    func installVideoNoteButton() {
        guard videoNoteEntry == nil, buttonSendChat != nil else {
            return
        }
        let entry = VideoNoteEntryPoint(owner: self, anchor: buttonSendChat)
        entry.onHint = { [weak self] text in
            self?.view.makeToast(text, duration: 2)
        }
        entry.onWillPresent = { [weak self] in
            guard let self = self else { return }
            // Nothing else is being written or picked while a video note is being taken.
            self.textFieldSend.resignFirstResponder()
            if self.viewSticker.isDescendant(of: self.view) {
                self.constraintBottomAttachment.constant = 0.0
                self.viewSticker.removeConstraints(self.viewSticker.constraints)
                self.viewSticker.removeFromSuperview()
                self.view.layoutIfNeeded()
            }
        }
        entry.onFinish = { [weak self] url, _ in
            self?.sendVideoNote(at: url)
        }
        entry.install()
        videoNoteEntry = entry
    }

    /// True while the button is offering to record rather than to send.
    var wantsVoiceNote: Bool {
        get { return objc_getAssociatedObject(self, &EditorVoiceNoteKeys.wants) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &EditorVoiceNoteKeys.wants, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var voiceNoteBar: VoiceNoteBar? {
        get { return objc_getAssociatedObject(self, &EditorVoiceNoteKeys.bar) as? VoiceNoteBar }
        set { objc_setAssociatedObject(self, &EditorVoiceNoteKeys.bar, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Puts the recording bar over the input bar and starts listening.
    func beginVoiceNote() {
        guard voiceNoteBar == nil else {
            return
        }
        // Turned away here rather than at the recorder, so the recording bar never appears for
        // a recording that cannot happen.
        if APIS.blockedByCallInProgress() {
            return
        }
        let bar = VoiceNoteBar()
        // Fix: this took the input bar's own colour, which is clear - so the field, its
        // placeholder and the buttons behind carried on showing through the recording bar. It is
        // meant to cover them, so it is given a colour of its own and put in front.
        bar.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        // Reaching below the safe area as well, so nothing of the input bar shows under it.
        bar.clipsToBounds = false
        bar.translatesAutoresizingMaskIntoConstraints = false
        // Nothing else is being written or picked while a voice note is being recorded, so the
        // keyboard is put away and the sticker sheet closed - otherwise the reader is left with
        // two things asking for the same attention, and the bar covering neither.
        textFieldSend.resignFirstResponder()
        if viewSticker.isDescendant(of: view) {
            // Fix: the sheet was taken away but the room made for it was not. Opening the stickers
            // raises the input area by the height of the panel (constraintBottomAttachment = 200),
            // and every other way of closing it puts that back - this one did not, so the bar was
            // left floating 200pt off the bottom with nothing under it.
            constraintBottomAttachment.constant = 0.0
            viewSticker.removeConstraints(viewSticker.constraints)
            viewSticker.removeFromSuperview()
            view.layoutIfNeeded()
        }

        // Over the whole input area rather than inside the field: the bar is two rows tall, the
        // field is one, and the row of attachment buttons below has to be covered as well.
        view.addSubview(bar)
        view.bringSubviewToFront(bar)
        let foot = (viewButton.isDescendant(of: view) && !viewButton.isHidden)
            ? viewButton.bottomAnchor
            : viewTextfield.bottomAnchor
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: foot)
        ])
        voiceNoteBar = bar
        bar.onCancel = { [weak self] in
            self?.endVoiceNote()
        }
        bar.onSend = { [weak self] url, seconds in
            self?.endVoiceNote()
            self?.sendVoiceNote(at: url, seconds: seconds)
        }
        bar.begin { [weak self] failure in
            guard let self = self, let failure = failure else {
                return
            }
            self.endVoiceNote()
            switch failure {
            case .busy:
                // blockedByCallInProgress has already put its own alert up.
                break
            case .denied:
                APIS.showMicrophoneRefused()
            case .heldByAnotherApp:
                APIS.showMicrophoneBusyElsewhere()
            case .audioSessionRefused:
                self.view.makeToast("Could not start recording. Try again.".localized(), duration: 3)
            }
        }
    }

    func endVoiceNote() {
        voiceNoteBar?.finish()
        voiceNoteBar?.removeFromSuperview()
        voiceNoteBar = nil
    }

    /// Sends what was recorded, as an audio message like any other.
    ///
    /// The shape is the one the rest of the app already speaks: the file copied into Documents
    /// under a `Nexilis_` name and the original name ahead of the caption in the text, which is
    /// what the bubble reads back when it draws the player. The flag is 60 rather than the 5 an
    /// audio attachment normally travels under: 5 says only "there is audio here", and a client
    /// reading it draws the plain file bubble - a music note on a disc - which is wrong for
    /// somebody's voice. 60 says which of the two this is, on every client that receives it.
    func sendVoiceNote(at url: URL, seconds: Int) {
        let originalName = url.lastPathComponent
        let renamed = "Nexilis_\(Date().currentTimeMillis())_\(originalName)"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = documents.appendingPathComponent(renamed)
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: url, to: destination)
        } catch {
            view.makeToast("Failed to save the recording".localized(), duration: 3)
            return
        }
        sendChat(message_text: "\(originalName)|",
                 attachment_flag: "60",
                 audio_id: renamed,
                 viewController: self)
    }

    /// Sends a round video note. It travels as an ordinary video - same attachment flag, same
    /// video and thumbnail slots - and what marks it out as a note is the name of the file.
    func sendVideoNote(at url: URL) {
        VideoNote.package(recording: url) { [weak self] videoId, thumbId in
            guard let self = self else { return }
            guard let videoId = videoId, let thumbId = thumbId else {
                self.view.makeToast("Failed to save the recording".localized(), duration: 3)
                return
            }
            // The first send gets the same mark as a resend, so the control does not depend on
            // the row being redrawn while the status still reads "1".
            VideoNote.markSending(videoId: videoId)
            self.sendChat(attachment_flag: "0",
                          video_id: videoId,
                          thumb_id: thumbId,
                          viewController: self)
        }
    }

    @objc func sendTapped() {
        // Nothing written means the button is a microphone, not a paper plane.
        if wantsVoiceNote {
            beginVoiceNote()
            return
        }
        // The last word on the length, and the only one that is certain: typing is capped as it
        // happens, but a draft kept from a previous visit is put back into the field whole,
        // without ever passing the field's own test.
        let limit = MessageLimits.textCharacters
        if limit > 0, (textFieldSend.text ?? "").count > limit {
            APIS.showMessageTooLong()
            return
        }
        sendChat(message_text: textFieldSend.text!, viewController: self)
    }
    
    private func sendChat(message_scope_id:String =  MessageScope.GROUP, status:String =  "1", message_text:String =  "", credential:String = "0", attachment_flag: String = "0", ex_blog_id: String = "", message_large_text: String = "", ex_format: String = "", image_id: String = "", audio_id: String = "", video_id: String = "", file_id: String = "", thumb_id: String = "", reff_id: String = "", read_receipts: String = "", is_call_center: String = "0", call_center_id: String = "", viewController: UIViewController, gif_id: String = "", is_forwarded: Int = 0) {
        // Fix: this refused an empty message unless it carried a file, and a file meant `file_id`
        // and nothing else - so a voice note, which travels as `audio_id`, was turned away with
        // "Write Messages" even though there was plainly something to send. What the guard is for
        // is not sending nothing; anything attached is something.
        let carriesAttachment = !file_id.isEmpty || !audio_id.isEmpty || !image_id.isEmpty
            || !video_id.isEmpty || !gif_id.isEmpty
        if viewController is EditorGroup && !carriesAttachment && dataMessageForward == nil {
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
        // Fix: the section, the row and a forced layout used to be three separate transactions,
        // so the table animated twice and was measured in between - and on a long history that
        // measurement moves the offset under the reader, which is the jump. One update, one
        // settling, and the slide to the newest message starts only once it is over.
        let opensNewDay = !dataDates.contains("Today".localized())
        if opensNewDay {
            dataDates.append("Today".localized())
        }
        row["chat_date"] = "Today".localized()
        // One more of the conversation's messages is now in the loaded window.
        loadedCount += 1
        let newRow = row
        // Written down before the insert, so willDisplay can play it while the row is still being
        // created - see pendingBubbleArrival.
        expectBubbleArrival(messageId: newRow[TypeDataMessage.message_id] as? String ?? "", outgoing: true)
        tableChatView.performBatchUpdates({
            if opensNewDay {
                self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .none)
            }
            if let collageRow = self.foldIntoImageGroup(newRow) {
                // Part of the run above it: no new row goes in, the row that draws the
                // collage is redrawn to take it. Plainly, not through the place-keeping
                // reload: this is inside a batch update, where the table is mid-way through
                // rearranging itself and must not be asked to lay out or to move.
                // No row of its own goes in, so no bubble arrives.
                self.cancelExpectedBubbleArrival()
                self.tableChatView.reloadRows(at: [collageRow], with: .none)
            } else {
                self.dataMessages.append(newRow)
                self.tableChatView.insertRows(at: [IndexPath(row: self.messages(onDate: self.dataDates[self.dataDates.count - 1]).count - 1, section: self.dataDates.count - 1)], with: .none)
            }
        }, completion: { [weak self] _ in
            guard let self = self else {
                return
            }
            let lastSection = self.tableChatView.numberOfSections - 1
            if lastSection >= 0 {
                let lastRow = self.tableChatView.numberOfRows(inSection: lastSection) - 1
                if lastRow >= 0 {
                    // willDisplay has almost certainly played it by now; this is only for the
                    // case where the cell had not been measured when it fired.
                    self.retryPendingBubbleArrival(at: IndexPath(row: lastRow, section: lastSection))
                }
            }
            self.slideToNewestMessage()
        })
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
                    self.tableChatView.reloadRowsKeepingPlace(at: [IndexPath(row: row!, section: section!)])
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
        // The slide happens when the insert has settled - see the batch update above. Chasing the
        // row with a second, animated scroll from here was the other half of the bouncing.
        if self.markerCounter != nil {
            let lastMarkerCounter = self.markerCounter
            self.markerCounter = nil
            let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == lastMarkerCounter })
            if indexMessage != nil {
                let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "")
                let row = self.messages(onDate: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                if row != nil && section != nil  {
                    self.tableChatView.reloadRowsKeepingPlace(at: [IndexPath(row: row!, section: section!)])
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
    /// Where the reader is in the conversation: the last message showing, and how far its foot
    /// sits from the foot of the visible area.
    ///
    /// This is what has to be preserved when the input area grows or shrinks. Holding the bottom
    /// of the visible area is what makes the content rise by exactly what the bar took, which is
    /// what leaves the same messages in front of the reader.
    struct ListAnchor {
        let messageId: String
        /// The row's head, less the head of the visible area. Negative while the row begins above it.
        let headBelowViewport: CGFloat
        /// How tall the visible area was, so the content can be moved by exactly what the input
        /// area took from it.
        let viewportHeight: CGFloat
        /// True when the list was already at its end.
        ///
        /// Fix: measured off a recording, opening a reply moved the content up by 380 points and
        /// closing it moved the content back down by only 333 - a drift of about fifty points, the
        /// height of the reply bar, on every open-and-cancel. That is what the reader sees as the
        /// jumping, and it is exactly why it stops after the third or fourth time: the drift
        /// carries them far enough from the end that it cannot happen again. The cause is the end
        /// of the list itself. Coming back, the visible area grows by the keyboard and the bar, and
        /// "put the same messages back in front of the reader" then asks for content below the
        /// last message that does not exist - so that correction is cut short at the end while the
        /// one going the other way is not. A list at its end belongs at its end; asking for
        /// anything else there is asking for something the conversation does not have.
        let wasAtEnd: Bool
    }

    /// Fix: this used to be one number, the distance from the *end of the list*, and that number
    /// is only worth anything while the end of the list stays where it is. It does not. A row the
    /// table has never drawn is a guess, and laying the list out again is what replaces those
    /// guesses with measurements - so the content's total height moves between the moment the
    /// distance is read and the moment it is put back, by as much as the guesses were wrong. In a
    /// conversation of tall screenshots that is hundreds or thousands of points, and every one of
    /// them was handed straight to the scroll position. That is the jump on opening a reply: not
    /// the bar, but the arithmetic, measuring from an end that had moved.
    ///
    /// A row is a fixed thing. Its own position is re-read after the layout, so whatever the
    /// heights did in between corrects itself.
    ///
    /// Fix: it was the *foot* of the last row showing, and a row's foot is its head plus its
    /// height - so anchoring there anchors to a number the row does not know yet. A picture
    /// arrives after the bubble that holds it, and the row is re-measured when it does; the foot
    /// moves by the whole difference, and the content was moved to follow it. That is why a reply
    /// to a picture still jumped when everything else had gone quiet, and why it was worst on a
    /// chat just opened, where none of the pictures have landed. The head of the first row showing
    /// moves only when the rows *above* it change, which is the one thing that does have to be
    /// followed.
    private var listAnchor: ListAnchor? {
        guard let scrollView = tableChatView, scrollView.bounds.height > 0,
              let indexPath = scrollView.indexPathsForVisibleRows?.first,
              let messageId = message(at: indexPath)?["message_id"] as? String, !messageId.isEmpty else {
            return nil
        }
        let viewportHead = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let lowest = -scrollView.adjustedContentInset.top
        let highest = max(lowest, scrollView.contentSize.height
                          + scrollView.adjustedContentInset.bottom - scrollView.bounds.height)
        return ListAnchor(messageId: messageId,
                          headBelowViewport: scrollView.rectForRow(at: indexPath).minY - viewportHead,
                          viewportHeight: scrollView.bounds.height
                            - scrollView.adjustedContentInset.top - scrollView.adjustedContentInset.bottom,
                          wasAtEnd: highest - scrollView.contentOffset.y <= 4)
    }

    /// Fix: for a while this was a *held* place, re-applied on every layout pass for a second
    /// after the input area changed, because the rows were still settling and one correction was
    /// not enough. That is no longer true - the reckoning the rows are guessed at is accurate now
    /// and it stops moving - and a held place became the problem instead of the cure. Measured off
    /// a recording: a hundred and seventy-seven points, in one frame, once per open-and-close of a
    /// reply, always in the moment the reply's own layout pass ran. That is a hold left over from
    /// the keyboard closing a moment earlier, still alive, yanking the list back to where the
    /// reader had been before they moved. Corrected once, inside the animation that moves the
    /// layout, and never again afterwards.
    /// Puts the message the reader was looking at back where it was, once the layout has changed.
    ///
    /// Both directions come out right and nothing is applied twice: the visible area gets shorter
    /// when the keyboard or the reply bar arrives and taller when they go, and the content is
    /// moved by exactly what was taken from it or given back - so the messages in front of the
    /// reader are the same messages, and the bar never lands on top of them.
    private func restore(_ anchor: ListAnchor?) {
        guard let anchor = anchor, let scrollView = tableChatView, scrollView.bounds.height > 0,
              let indexPath = indexPath(forMessageId: anchor.messageId),
              indexPath.section < scrollView.numberOfSections,
              indexPath.row < scrollView.numberOfRows(inSection: indexPath.section) else {
            return
        }
        let lowest = -scrollView.adjustedContentInset.top
        let highest = max(lowest, scrollView.contentSize.height
                          + scrollView.adjustedContentInset.bottom - scrollView.bounds.height)
        let target: CGFloat
        if anchor.wasAtEnd {
            // At the end, and the end is where it stays. Nothing else can be honoured there.
            target = highest
        } else {
            let viewportHeight = scrollView.bounds.height
                - scrollView.adjustedContentInset.top - scrollView.adjustedContentInset.bottom
            // What the input area took from the visible area, which is what the content rises by.
            let taken = anchor.viewportHeight - viewportHeight
            let viewportHead = scrollView.rectForRow(at: indexPath).minY
                - anchor.headBelowViewport + taken
            target = min(max(viewportHead - scrollView.adjustedContentInset.top, lowest), highest)
        }
        guard abs(target - scrollView.contentOffset.y) > 0.5 else {
            return
        }
        // Assigned rather than set through setContentOffset(_:animated: false): inside an
        // animation block the assignment travels with it, where the explicit "not animated" is
        // taken to mean not animated at all, and the content arrives a keyboard's height away
        // from where it started in a single frame.
        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: target)
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
        // Armed before the scroll starts, not after: the animation itself passes the top of
        // the loaded window on the way down, and that is when the unwanted page would land.
        isDashingToBottom = true
        tableChatView.scrollToBottom()
        // Fix: one animated scroll to the last row was the whole of it, and a chat is exactly
        // the list where that lands short. The rows between here and the end have never been
        // drawn, so the table is aiming at a total worked out from estimates; and the scroll
        // itself drives scrollViewDidScroll, which loads another page whenever it passes near
        // either end - so the content grows underneath the animation and the end moves away
        // from it. What is asked for instead, once the animation has had its moment, is the
        // same hold that puts a chat at its newest message when it opens: it keeps aiming at
        // the bottom until the heights stop changing, lets go the instant the reader touches
        // the list, and gives up on a deadline.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else {
                return
            }
            self.holdAtNewestMessage()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            // Fix: the button took the reader to the newest message and then only took itself
            // away. Nothing said the messages it had been counting were read, so the senders got
            // no read mark and the chat list kept its badge for a conversation the reader was
            // looking at the bottom of.
            markVisibleMessagesRead()
            removeScrollToBottomButton()
        }
    }

    /// Set while the list is deliberately on its way to the newest message, so the loads that
    /// serve a reader browsing upwards do not fire during the journey down and move the end of
    /// it. Dropped the moment the reader puts a finger on the list.
    private var isDashingToBottom = false

    /// Aims at the newest message and keeps aiming until the rows stop changing size.
    ///
    /// The opening placement's own machinery, asked for after the fact - see
    /// applyPendingInitialBottomScroll, which is driven from every layout pass and drops the
    /// hold the moment the reader takes the list over. The timed passes are for the case where
    /// no layout pass happens to follow.
    private func holdAtNewestMessage() {
        guard !isPreview else {
            return
        }
        pendingUnreadMarkerScroll = nil
        pendingInitialScrollToBottom = true
        initialBottomDeadline = nil
        initialBottomStartedAt = nil
        initialBottomLastContentHeight = -1
        applyPendingInitialBottomScroll()
        for delay in [0.1, 0.25, 0.45, 0.7, 1.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.applyPendingInitialBottomScroll()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.isDashingToBottom = false
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
        // Whatever goes out is remembered here, so the sweep that reports what is on screen
        // does not report the same messages a second time. The rows in memory keep the status
        // they were loaded with, so they cannot answer this on their own.
        let reported = message_id.components(separatedBy: ",").filter { !$0.isEmpty }
        DispatchQueue.main.async { [weak self] in
            self?.reportedReadMessageIds.formUnion(reported)
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
            guard let lastIndex = tableView.indexPathsForVisibleRows?.last,
                  lastIndex.section < dataDates.count else {
                return
            }

            currentIndexpath = lastIndex

            // Fix: whether the button appeared was decided by comparing the position of the
            // FIRST visible row inside its own section against the number of rows in the LAST
            // section - two unrelated numbers that happen to be equal often enough that the
            // button simply did not appear while the reader was well away from the end. Only
            // one thing matters: how far the list is from its own bottom. Measured the way the
            // opening placement measures it, insets included, so the keyboard or the input bar
            // cannot skew it.
            let maxOffset = max(-tableView.adjustedContentInset.top,
                                tableView.contentSize.height
                                + tableView.adjustedContentInset.bottom
                                - tableView.bounds.height)
            let distanceFromBottom = maxOffset - tableView.contentOffset.y

            if distanceFromBottom > 100 {
                if !buttonScrollToBottom.isDescendant(of: view) {
                    addButtonScrollToBottom()
                    addCounterAtButttonScrollToBottom()
                }
            } else if distanceFromBottom < 50 {
                removeScrollToBottomButton()
            }

            // Whatever the reader has scrolled onto has been read: the marks go out, and the
            // unread count follows whatever is still below them.
            markVisibleMessagesRead()
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

    // MARK: - Read marks for what is on screen

    /// Message ids this screen has already reported as read.
    ///
    /// A read mark is written to the database, not back into `dataMessages` - the rows in memory
    /// keep whatever status they were loaded with. Without this, every scroll would report the
    /// same messages all over again.
    private var reportedReadMessageIds: Set<String> = []

    /// Whether the newest loaded message is on screen.
    private var isReaderAtBottomOfList: Bool {
        let fullOffset = tableChatView.contentSize.height - tableChatView.bounds.height
        guard fullOffset > 0 else {
            // Fewer messages than fit the screen: all of them are in front of the reader.
            return true
        }
        return fullOffset - tableChatView.contentOffset.y < 80
    }

    /// Whether the reader is actually in front of this conversation - not a preview, not a
    /// screen left behind under another one, and not the app sitting in the background.
    ///
    /// A conversation pushed under another screen keeps its window, so being in one proves
    /// nothing on its own; what settles it is being the screen its navigation stack is showing.
    /// Anything merely presented over it - the picture viewer, a sheet - leaves it the top of
    /// that stack, which is right: reading carries on underneath.
    private var isReaderPresent: Bool {
        guard !isPreview, viewIfLoaded?.window != nil,
              UIApplication.shared.applicationState == .active else {
            return false
        }
        if let navigation = navigationController, navigation.topViewController !== self {
            return false
        }
        return true
    }

    @objc func onAppBecameActive(notification: NSNotification) {
        // Whatever landed while the app was away is on screen by now, or about to be. The
        // layout is given a moment to settle before what is visible is counted.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.markVisibleMessagesRead()
        }
    }

    /// Reports everything down to the last row on screen as read, and brings the unread count
    /// in line with it.
    ///
    /// Fix: read marks were only ever sent when the conversation was opened, or when a message
    /// arrived with the list already at the bottom. That left two ways in uncovered. A message
    /// landing while the app is in the background is spliced into a conversation that is still
    /// open - tapping the notification comes back to it with the message already there, and
    /// nothing ever said it had been read, so the chat list kept its badge. And a message that
    /// arrives while the reader is further up is only ever seen by scrolling down to it, which
    /// reported nothing either. Both go through here now.
    func markVisibleMessagesRead() {
        guard isReaderPresent, !isInitialLoading,
              let lastVisible = tableChatView.indexPathsForVisibleRows?.last,
              let seen = message(at: lastVisible)?[TypeDataMessage.message_id] as? String,
              let index = dataMessages.firstIndex(where: { $0[TypeDataMessage.message_id] as? String == seen }) else {
            return
        }
        sendReadReceipts(through: index)
        reconcileUnreadCounter(seenThrough: index)
    }

    /// One read mark for everything the reader has now seen, gathered per sender: a group's
    /// read marks are addressed to whoever wrote the messages, not to the group.
    private func sendReadReceipts(through index: Int) {
        guard index >= 0, index < dataMessages.count, let idMe = User.getMyPin() else {
            return
        }
        var outstanding: [String: [String]] = [:]
        for i in 0...index {
            let row = dataMessages[i]
            let messageId = row[TypeDataMessage.message_id] as? String ?? ""
            let status = row[TypeDataMessage.status] as? String ?? ""
            let sender = row[TypeDataMessage.f_pin] as? String ?? ""
            // 4 and 8 are the states that already mean seen; anything else has not been
            // reported yet.
            guard !messageId.isEmpty, !sender.isEmpty, !reportedReadMessageIds.contains(messageId),
                  sender != idMe, status != "4", status != "8",
                  EditorGroup.conditionSendRead(scope: row[TypeDataMessage.message_scope_id] as? String ?? "",
                                                fPin: sender,
                                                messageId: messageId) else {
                continue
            }
            reportedReadMessageIds.insert(messageId)
            outstanding[sender, default: []].append(readReceiptIds(for: row))
        }
        for (sender, ids) in outstanding {
            sendReadMessageStatus(chat_id: dataTopic["chat_id"] as? String ?? "",
                                  f_pin: sender,
                                  message_scope_id: MessageScope.GROUP,
                                  message_id: ids.joined(separator: ","))
        }
    }

    /// What is left unread is what is still below the reader.
    private func reconcileUnreadCounter(seenThrough index: Int) {
        guard !isPreview, counter > 0, isWindowAtNewest else {
            return
        }
        // The unread ones are the last `counter` rows of the window, so nothing changes until
        // the reader has actually reached the first of them.
        guard index >= dataMessages.count - counter else {
            return
        }
        counter = max(0, dataMessages.count - 1 - index)
        if counter == 0 {
            if indicatorCounterBSTB.isDescendant(of: view) {
                indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
                indicatorCounterBSTB.removeFromSuperview()
            }
        } else if indicatorCounterBSTB.isDescendant(of: view) {
            labelCounter.text = "\(counter)"
        }
        updateCounter(counter: counter)
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
    //sendReadMessageStatus(chat_id: self.dataTopic["chat_id"]  as? String ?? "", f_pin: listData[i]["f_pin"]  as? String ?? "", message_scope_id: MessageScope.GROUP, message_id: self.readReceiptIds(for: listData[i]))
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
            // A spinner with a percentage in its text said how far along it was but gave no way
            // out of it, and most of this wait is iCloud handing originals back - which on a slow
            // link is a long time to be held. The same card the share sheet uses: how far along,
            // and a way to stop.
            var loading: Progress?
            let heading = results.count > 1
                ? "\("Preparing...".localized()) (\(results.count))"
                : "Preparing...".localized()
            PreparingOverlay.show(title: heading) {
                loading?.cancel()
            }
            // Fix: the loading itself moved to PickerAttachmentLoader - see the note there
            // for what was wrong with doing it here (items loaded one after another behind a
            // semaphore, failures that left the loader up for good, a full-size decode of
            // every camera photo).
            loading = PickerAttachmentLoader.load(results: results, onProgress: { fraction in
                PreparingOverlay.update(fraction: fraction)
            }, completion: { attachments in
                guard let self = self, loading?.isCancelled != true else {
                    PreparingOverlay.hide()
                    return
                }
                var attachments = attachments
                guard !attachments.isEmpty else {
                    // Nothing came back at all - still take the card down rather than leaving it
                    // on screen.
                    PreparingOverlay.hide()
                    return
                }
                PreparingOverlay.hide {
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
            // A document is sent as it is - there is nothing to compress - so one over the
            // server's size is refused here, before the reader has written a caption for it.
            // The whole pick goes back, the way the Android build does it, rather than some of
            // the files quietly going missing.
            if listFile.contains(where: { MessageLimits.exceedsDocumentLimit($0) }) {
                APIS.showDocumentTooLarge()
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
        refreshSendOrRecordButton()
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
    
    /// How much height the list of names has to work with: what is left between the top of the
    /// input area and the header above the conversation, less a margin so it never looks wedged
    /// against either.
    private var roomForMentionList: CGFloat {
        let inputTop = viewTextfield.frame.minY
        let headerBottom = view.safeAreaInsets.top
        let room = inputTop - headerBottom - 12
        // A single row, if it comes to that: a list of names with nothing visible in it is worse
        // than a cramped one.
        return max(room, ChatMentionList.rowHeight)
    }

    /// Whether the list of names is on screen.
    ///
    /// Its own height answers this now: zero is away, anything else is showing. It used to be
    /// read off the sign of the bottom constraint, which is why that constraint had to be driven
    /// to a negative number to hide the list instead of simply being given no height.
    private var isMentionShowing: Bool {
        return heightTableMention != nil && heightTableMention.constant > 0
    }

    private func showMention(text: String) {
        listMentionWithText.removeAll()
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                let idMe = User.getMyPin()!
                // Fix: what the reader types after the "@" went into the query as it was. An
                // apostrophe in it - and names have apostrophes - closed the string early and
                // the search returned nothing at all from that keystroke on; a "%" or a "_"
                // was read as a wildcard and matched everybody. Quoted for the string, and
                // escaped for LIKE, which needs its own escape character named.
                let typed = text.replacingOccurrences(of: "'", with: "''")
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "%", with: "\\%")
                    .replacingOccurrences(of: "_", with: "\\_")
                let groupId = (self.dataGroup["group_id"] as? String ?? "").replacingOccurrences(of: "'", with: "''")
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_pin, first_name || ' ' || ifnull(last_name, '') name FROM GROUPZ_MEMBER where group_id='\(groupId)' AND f_pin <> '\(idMe)' AND name LIKE '%\(typed)%' ESCAPE '\\' ORDER BY name COLLATE NOCASE LIMIT 50") {
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
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        // Fix: everything below used to run inside the transaction above - and a transaction runs
        // synchronously on the database's own serial queue. Laying the view out from there reaches
        // the chat table, which builds its rows, and a row reads the sender's profile through a
        // transaction of its own: a dispatch_sync onto the very queue this was already on, which
        // libdispatch stops with a trap (__DISPATCH_WAIT_FOR_QUEUE__, EXC_BREAKPOINT). The app
        // went down the moment the mention list opened over a row that had a profile to read. It
        // also put every bit of this UI work on a background thread. The transaction only reads
        // now; what is drawn is drawn after it has returned, on the thread this was called on.
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
            // Four and a half rows when there are more than four, so the half row showing
            // at the bottom says there is more to scroll to - the old four exactly looked
            // like the whole list however many names were behind it.
            let rows = min(CGFloat(listMentionWithText.count), 4.5)
            let wasShowing = nowHeightTableMention.constant > 0
            // And never taller than the room actually left above the input area. On a
            // 4.7" screen with the keyboard up, a reply preview and a link preview open,
            // four and a half rows do not fit between the input area and the header -
            // the list would run up under the navigation bar.
            nowHeightTableMention.constant = min(rows * ChatMentionList.rowHeight, roomForMentionList)
            nowTableMention.reloadData()
            // Opening is worth animating; growing by a row as the reader types is not -
            // that would have the list breathing under every keystroke.
            if !wasShowing, !isEditingMessage {
                nowTableMention.setContentOffset(.zero, animated: false)
                UIView.animate(withDuration: 0.2) {
                    self.view.layoutIfNeeded()
                }
            } else {
                self.view.layoutIfNeeded()
            }
        } else {
            self.hideMention()
        }
    }
    private func hideMention() {
        // Fix: this took away whichever of the two lists it found first. The one for editing a
        // message is built over the top of the conversation's own, so both can be up at once -
        // and the one left behind stayed on screen with nothing to do.
        let wasShowing = isMentionShowing
        if wasShowing || (heightTableEditMention != nil && heightTableEditMention.constant != 0) {
            listMentionWithText.removeAll()
            tableMention.reloadData()
            heightTableMention.constant = 0
            if heightTableEditMention != nil {
                tableMentionEdit.reloadData()
                heightTableEditMention.constant = 0
            }
            // Half a second was long enough to see the list still sitting there after the name
            // had been picked, which read as a stutter rather than an animation.
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    /// The card above the field while a link is being written, read from the page the same way the
    /// bubble reads it - so what is shown before sending is what will be sent.
    private func checkLink(fullText: String) {
        guard !isAlwaysHideLinkPreview else {
            return
        }
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
        guard !text.isEmpty else {
            deleteLinkPreview()
            return
        }
        let show: (LinkPreviewFacts) -> Void = { [weak self] facts in
            guard let self = self, self.showingLink != text else {
                return
            }
            self.showingLink = text
            self.deleteLinkPreview()
            guard !self.textFieldSend.text.isEmpty || self.textFieldSend.text.contains(text) else {
                return
            }
            self.buildPreviewLink(imageUrl: facts.imageUrl.isEmpty ? nil : facts.imageUrl,
                                  title: facts.title,
                                  description: facts.blurb,
                                  stringURl: text)
        }
        switch linkAnswer(for: text) {
        case .read(let facts):
            show(facts)
            return
        case .nothingOnIt:
            return
        case .notAsked:
            break
        }
        // Fix: this asked the internet again on every keystroke, and asked again from the top
        // whenever a page came back without a title - which for the sites that answer only a
        // crawler was every time. It is asked once, and nothing more happens if the page turns
        // out to have nothing on it.
        LinkPreviewFetcher.fetch(link: text) { [weak self] gained in
            guard let self = self else {
                return
            }
            if gained {
                // What the bubbles hold about this link is now out of date.
                self.linkAnswers.removeValue(forKey: text)
            }
            guard let facts = LinkPreviewStore.stored(link: text),
                  self.textFieldSend.text.contains(text) else {
                return
            }
            show(facts)
        }
    }
    
    private func buildPreviewLink(imageUrl: String?, title: String, description: String?, stringURl: String) {
        if !self.viewTextfield.subviews.contains(self.containerLink){
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant + 80
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
            // Fix: pictures came down the app's own pinned session, which refuses any host it
            // holds no pin for - and nobody pins the site a link points at, so the picture was
            // cancelled before it arrived. See PublicWebTrustDelegate.
            LinkPreviewImage.load(imageUrl!, into: imagePreview, stillWanted: { return true })
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
        // The server says how long a message may be - see MessageLimits, pulled by
        // Nexilis.pullInstantMessaging. What would carry the field past it is refused whole,
        // rather than the first N characters of a paste being kept silently, and the reader is
        // told once instead of on every keystroke.
        if textView == textFieldSend,
           !MessageLimits.textFits(current: textView.text ?? "", range: range, replacement: text) {
            APIS.showMessageTooLong()
            return false
        }
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
        // A finger put down on a list that is still moving is a finger stopping the list. It
        // gets no menu, however long it then rests there - see ListMotion.
        if listMotion.isMoving(tableChatView) {
            return nil
        }
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

        // An attachment still on its way has nothing this menu can offer: it cannot be starred,
        // replied to, forwarded or pinned before it exists anywhere but here. And the menu opens
        // over the bubble, which is exactly where the stop control sits - on a note at the foot of
        // its circle, on a picture in the middle - so a hold meant to stop the send put a menu on
        // top of the button instead. Nothing is lost with it: once a send has failed the message
        // says so, and the menu comes back with Send again in it.
        if let path = tableChatView.indexPathForRow(at: interaction.view!.convert(location, to: tableChatView)),
           path.section < dataDates.count {
            let rows = messages(onDate: dataDates[path.section])
            if path.row < rows.count {
                let videoId = rows[path.row][TypeDataMessage.video_id] as? String
                let imageId = rows[path.row][TypeDataMessage.image_id] as? String ?? ""
                let mine = rows[path.row][TypeDataMessage.f_pin] as? String == User.getMyPin()
                let carriesAFile = !(videoId ?? "").isEmpty || !imageId.isEmpty
                let onItsWay = rows[path.row][TypeDataMessage.status] as? String == "1"
                    || VideoNote.isSending(videoId: videoId ?? "")
                if onItsWay, mine, carriesAFile {
                    return nil
                }
            }
        }

        if textFieldSend.isFirstResponder {
            textFieldSend.resignFirstResponder()
        }
        // Fix: these closures capture self strongly (they always have - they're the very
        // same closures that used to go straight into UIAction), so the ones registered
        // by the previous long-press are dropped here rather than piling up on self.
        // The menu is about to lift the bubble into a preview, snapshotting it with the finger
        // still on it. Everything pressed under that finger lets go first - the quote, the link
        // preview, and the chip over a mention - or the preview would show them pressed for as
        // long as the menu stayed open. See PressableView.liftAll.
        PressableView.liftAll(in: interaction.view)
        hideLinkHighlight()
        linkPressGeneration += 1
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
                self.tableChatView.reloadRowsKeepingPlace(at: [indexPath!])
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
                self.tableChatView.reloadRowsKeepingPlace(at: [indexPath!])
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
                    if checkDataPinned.count >= PinnedMessages.maximum {
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
                        // Every pin over the limit, oldest first - one of them in the ordinary
                        // case, more when the conversation arrived holding too many.
                        self.unpinInOrder(PinnedMessages.toReplace(checkDataPinned)) { res1 in
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
                let cancelButton = self.selectionCancelBarButton()
                if !self.isHistoryCC {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                // The message the menu was opened on is only marked if it can be picked at all -
                // see `canPickMessage`. It used to be marked whatever it was, so a file still
                // waiting to be downloaded opened a session reading "1 Selected" over a row that
                // showed no circle and answered no tap.
                if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String}),
                   self.canPickMessage(self.dataMessages[idx], for: .forward) {
                    self.dataMessages[idx]["isSelected"] = true
                }
                self.startMultipleSelectSession()
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
                let cancelButton = self.selectionCancelBarButton()
                if !self.isHistoryCC {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                // The message the menu was opened on is only marked if it can be picked at all -
                // see `canPickMessage`. It used to be marked whatever it was, so a file still
                // waiting to be downloaded opened a session reading "1 Selected" over a row that
                // showed no circle and answered no tap.
                if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String}),
                   self.canPickMessage(self.dataMessages[idx], for: .copy) {
                    self.dataMessages[idx]["isSelected"] = true
                }
                self.startMultipleSelectSession()
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
                "content": ChatMessageText.spoken(of: dataMessages[indexPath!.row])
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
                                self.tableChatView.reloadRowsKeepingPlace(at: [indexPath!])
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
                "content": ChatMessageText.spoken(of: dataMessages[indexPath!.row])
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
                let cancelButton = self.selectionCancelBarButton()
                if !self.isHistoryCC {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                // The message the menu was opened on is only marked if it can be picked at all -
                // see `canPickMessage`. It used to be marked whatever it was, so a file still
                // waiting to be downloaded opened a session reading "1 Selected" over a row that
                // showed no circle and answered no tap.
                if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String}),
                   self.canPickMessage(self.dataMessages[idx], for: .summarize) {
                    self.dataMessages[idx]["isSelected"] = true
                }
                self.startMultipleSelectSession()
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
                let cancelButton = self.selectionCancelBarButton()
                if !self.isHistoryCC {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                // The message the menu was opened on is only marked if it can be picked at all -
                // see `canPickMessage`. It used to be marked whatever it was, so a file still
                // waiting to be downloaded opened a session reading "1 Selected" over a row that
                // showed no circle and answered no tap.
                if let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String}),
                   self.canPickMessage(self.dataMessages[idx], for: .delete) {
                    self.dataMessages[idx]["isSelected"] = true
                }
                self.startMultipleSelectSession()
            }
        })
        
        let resend = chatMenuAction(title: "Send again".localized(), image: UIImage(systemName: "arrow.clockwise"), handler: { [weak self] (_) in
            guard let self = self, let indexPath = indexPath else { return }
            let messageId = self.dataMessages[indexPath.row][TypeDataMessage.message_id] as? String ?? ""
            self.sendAgain(messageId: messageId)
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
                // Fix: whether the file is on this device was never asked here, so Forward was
                // offered on a document that is still only a name and a size - and a message the
                // session cannot pick was marked all the same. See `canPickMessage`.
                if canPickMessage(dataMessages[indexPath!.row], for: .forward) {
                    children.insert(forward, at: 0)
                }
            }
        } else {
            if dataMessages[indexPath!.row]["f_pin"] as? String ?? "" == "-999" {
                children = [star, reply ,delete]
            }
            else if (!(dataMessages[indexPath!.row]["image_id"]  as? String ?? "").isEmpty || !(dataMessages[indexPath!.row]["video_id"]  as? String ?? "").isEmpty || !(dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty) {
                // Whether anything was written alongside what this message carries - the same
                // reading `canPickMessage` goes by, so the Copy offered here and the Copy a
                // session will accept cannot disagree. See `ChatMessageText`.
                if ChatMessageText.spoken(of: dataMessages[indexPath!.row]).isEmpty {
                    children = [star, reply , pin, delete]
                }
            } else if dataMessages[indexPath!.row]["attachment_flag"]  as? String ?? "" == "11" {
                children = [reply, pin, delete]
            }
            if (Nexilis.checkingAccess(key: "secure_folder_forward") || (!(dataMessages[indexPath!.row][TypeDataMessage.message_text]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["image_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["video_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["audio_id"]  as? String ?? "").isEmpty) || (dataMessages[indexPath!.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward")) && dataMessages[indexPath!.row]["read_receipts"] as? String != "8" && dataMessages[indexPath!.row]["attachment_flag"] as? String ?? "" != "11" {
                // Fix: whether the file is on this device was never asked here, so Forward was
                // offered on a document that is still only a name and a size - and a message the
                // session cannot pick was marked all the same. See `canPickMessage`.
                if canPickMessage(dataMessages[indexPath!.row], for: .forward) {
                    children.insert(forward, at: 2)
                }
            }
            // Fix: replying privately opens a personal chat with whoever sent the message, and
            // it was offered for anybody in the group. Most of a group is people the reader has
            // never added - their names come from the group's own member list, not from the
            // contact list - so the offer led to a conversation with someone who is not a contact
            // at all, and it was offered for a blocked one just the same. It is only offered now
            // for a contact neither side has blocked.
            if dataMessages[indexPath!.row]["f_pin"] as? String ?? "" != "-999",
               dataMessages[indexPath!.row]["f_pin"] as? String != User.getMyPin(),
               dataMessages[indexPath!.row]["attachment_flag"] as? String ?? "" != "11",
               dataMessages[indexPath!.row]["f_pin"] as? String ?? "" != "-997",
               canOpenPrivateChat(with: dataMessages[indexPath!.row]["f_pin"] as? String ?? "") {
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
                // Fix: More - and with it Translate and Summarize - was held back from every
                // message carrying a file, picture, video or recording, so a document sent with
                // something written under it could be neither translated nor summarised, though
                // that writing is text like any other. What decides it is whether the message
                // says anything, not what it is carrying alongside.
                if (dataMessages[indexPath!.row][TypeDataMessage.attachment_flag] as? String ?? "") != "11",
                   !ChatMessageText.spoken(of: dataMessages[indexPath!.row]).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
            // Fix: the moment of the pin was read from the clock three separate times - once for
            // the server, once for the database, once for the row on screen - so the three could
            // differ by a few milliseconds. That number is what decides which pin is the oldest,
            // and so which one a fourth pin replaces. Read once, used everywhere.
            let pinnedAt = isPinned ? "\(Date().currentTimeMillis())" : "0"
            var jaData = [[String: Any]]()
            var jsonObject = [String: Any]()
            jsonObject[CoreMessage_TMessageKey.MESSAGE_ID] = checkDataPinned["message_id"]  as? String ?? ""
            jsonObject[CoreMessage_TMessageKey.IS_PINNED_MESSAGE] = pinnedAt
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
                                        "is_pinned" : pinnedAt
                                    ], _where: "message_id = '\(checkDataPinned["message_id"]  as? String ?? "")'")
                                } catch {
                                    rollback.pointee = true
                                    print("Access database error: \(error.localizedDescription)")
                                }
                            })
                        }
                        let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == checkDataPinned["message_id"]  as? String ?? ""})
                        if idx != nil{
                            self.dataMessages[idx!][TypeDataMessage.is_pinned] = pinnedAt
                            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                            let row = self.messages(onDate: self.dataMessages[idx!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[idx!]["message_id"]  as? String ?? "" })
                            if row != nil && section != nil  {
                                DispatchQueue.main.async {
                                    self.tableChatView.reloadRowsKeepingPlace(at: [IndexPath(row: row!, section: section!)])
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
                self.tableChatView.reloadRowsKeepingPlace(at: [collageRow])
            } else {
                self.dataMessages.append(row)
                let arrived = IndexPath(row: self.messages(onDate: self.dataDates[self.dataDates.count - 1]).count - 1, section: self.dataDates.count - 1)
                // A message that arrives grows out of the side it came from, the way one that is
                // sent grows out of ours. Written down before the insert so the bubble is small
                // the first time it is drawn.
                self.expectBubbleArrival(messageId: row[TypeDataMessage.message_id] as? String ?? "",
                                         outgoing: false)
                self.tableChatView.insertRows(at: [arrived], with: .none)
                self.tableChatView.layoutIfNeeded()
                self.retryPendingBubbleArrival(at: arrived)
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
                            self.tableChatView.reloadRowsKeepingPlace(at: [indexPath])
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
            // The same list, and the same corrections - see the setup of tableMention.
            tableMentionEdit.contentInset = .zero
            tableMentionEdit.rowHeight = ChatMentionList.rowHeight
            tableMentionEdit.estimatedRowHeight = ChatMentionList.rowHeight
            tableMentionEdit.separatorInset = UIEdgeInsets(top: 0, left: 52, bottom: 0, right: 0)
            tableMentionEdit.showsVerticalScrollIndicator = false
            tableMentionEdit.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
            tableMentionEdit.layer.cornerRadius = 12
            tableMentionEdit.layer.cornerCurve = .continuous
            tableMentionEdit.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            tableMentionEdit.clipsToBounds = true
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
        let token = selectionSessionToken
        DispatchQueue.main.async {
            guard token == self.selectionSessionToken else { return }
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
            if let restored = self.bottomTableConstantBeforeSelection {
                let readingPlace = self.distanceFromNewestMessage()
                self.constraintBottomTableViewWithTextfield.constant = restored
                self.bottomTableConstantBeforeSelection = nil
                self.view.layoutIfNeeded()
                self.restoreDistanceFromNewestMessage(readingPlace)
            }
            let data = self.dataMessages.filter({ $0["isSelected"] as? Bool ?? false == true })
            for i in 0..<data.count {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == data[i]["message_id"]  as? String ?? ""})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = false
                }
            }
            self.setRightButtonItem()
            self.changeAppBar()
            // The circles leave the way they arrived, each fading back into the picture it stood
            // on, and the table is only built again once that has finished - a rebuild in the
            // middle of the fade would cut it short.
            self.setSelectionChrome(shown: false, animated: true) {
                self.tableChatView.reloadDataKeepingPlace()
                self.checkNewMessage(tableView: self.tableChatView)
            }
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn, .allowUserInteraction], animations: {
                self.containerMultpileSelectSession.alpha = 0
            }, completion: { _ in
                // A session opened again while this was running owns the bar now; taking it out
                // from under that would leave the screen with no bar at all.
                guard !self.copySession, !self.forwardSession, !self.deleteSession,
                      !self.summarizeSession, !self.isSearching else { return }
                self.containerMultpileSelectSession.removeFromSuperview()
                self.containerMultpileSelectSession.alpha = 1
                self.refreshScrollToBottomButtonPlacement()
            })
        }
    }
    
    private func addMultipleSelectSession() {
        selectionSessionToken += 1
        viewTextfield.isHidden = true
        viewAttachment.isHidden = true
        containerAction.isHidden = true
        viewButton.isHidden = true
        // Fix: the bar hung off the bottom of the window, so on a device with a home indicator
        // the forward button sat underneath it - the 50pt the bar is given ran out below the
        // point a finger can reach. It stands on the safe area now, in the place the input bar
        // had, and the table is given back exactly the room that leaves: the gap over the bar
        // comes out the same 10pt on a device with an indicator and on one without.
        let readingPlace = distanceFromNewestMessage()
        bottomTableConstantBeforeSelection = constraintBottomTableViewWithTextfield.constant
        constraintBottomTableViewWithTextfield.constant = view.safeAreaInsets.bottom - 60
        view.addSubview(containerMultpileSelectSession)
        containerMultpileSelectSession.translatesAutoresizingMaskIntoConstraints = false
        constraintBottomContainerMultpileSelectSession = containerMultpileSelectSession.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        NSLayoutConstraint.activate([
            containerMultpileSelectSession.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerMultpileSelectSession.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            constraintBottomContainerMultpileSelectSession,
            containerMultpileSelectSession.heightAnchor.constraint(equalToConstant: 50)
        ])
        // Nothing is painted behind the capsule on iOS 26 - it floats over the chat, the way
        // the bar it replaces does on that release.
        if #available(iOS 26.0, *) {
            containerMultpileSelectSession.backgroundColor = .clear
        } else {
            containerMultpileSelectSession.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        }
        addSubviewMultipleSession()
        refreshScrollToBottomButtonPlacement()
        // The bar arrives over the input bar rather than in place of it: the table is resized in
        // this pass, un-animated as it always was, and only the bar itself fades in.
        containerMultpileSelectSession.alpha = 0
        view.layoutIfNeeded()
        restoreDistanceFromNewestMessage(readingPlace)
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            self.containerMultpileSelectSession.alpha = 1
        })
    }

    /// Opens a selection session on screen: the bar at the bottom, every row built again with its
    /// circle still hidden, and then the fade that trades each sender's picture for its circle.
    ///
    /// The rebuild has to happen with the circles hidden and the pictures showing - the state the
    /// screen is already in - or the fade has nothing to travel from and the circles simply appear.
    private func startMultipleSelectSession() {
        selectionChromeShown = false
        addMultipleSelectSession()
        // Every row changes at once here, so the rebuild lays them all out again - and it lays
        // them out now rather than at the next pass, because `visibleCells` is empty until it
        // has and there would be nothing to animate.
        tableChatView.reloadDataKeepingPlace()
        setSelectionChrome(shown: true, animated: true)
    }

    /// Fades the selection circles in or out over the rows that are on screen.
    ///
    /// Each circle stands on the picture it replaces, so the two cross-fade in place and no row
    /// moves. `selectionChromeShown` is left behind for `cellForRowAt` to read, so a row built
    /// after this has run comes back in the state the rest of the screen is in.
    private func setSelectionChrome(shown: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        selectionChromeShown = shown
        let apply = { self.tableChatView.visibleCells.forEach { self.applySelectionChrome(to: $0) } }
        guard animated else {
            apply()
            completion?()
            return
        }
        UIView.animate(withDuration: shown ? 0.3 : 0.2,
                       delay: 0,
                       usingSpringWithDamping: shown ? 0.75 : 1.0,
                       initialSpringVelocity: 0.3,
                       options: [.allowUserInteraction, .beginFromCurrentState],
                       animations: apply,
                       completion: { _ in completion?() })
    }

    /// How far the reader is from the newest message, in points - 0 when sitting at the bottom.
    private func distanceFromNewestMessage() -> CGFloat {
        return max(0, tableChatView.contentSize.height + tableChatView.adjustedContentInset.bottom
                      - tableChatView.bounds.height - tableChatView.contentOffset.y)
    }

    /// Puts the reader back that far from the newest message once the table has been resized.
    ///
    /// Fix: opening and closing a session changes the table's height by whatever the bar takes,
    /// and a `contentOffset` carried unchanged through that slides the conversation by the same
    /// amount. Closing used to cover for it by scrolling to the last row it had seen, which threw
    /// away wherever the reader had actually scrolled to - the jump on Cancel.
    private func restoreDistanceFromNewestMessage(_ distance: CGFloat) {
        let maximum = tableChatView.contentSize.height + tableChatView.adjustedContentInset.bottom
            - tableChatView.bounds.height
        let minimum = -tableChatView.adjustedContentInset.top
        tableChatView.contentOffset.y = min(max(maximum - distance, minimum), max(maximum, minimum))
    }

    /// Which kind of picking a selection session is for.
    ///
    /// The rule about which messages can be picked differs between them, and the menu has to ask
    /// before the session it is about to open exists - so the kind is passed rather than read off
    /// the flags.
    enum SelectionKind {
        case copy, forward, delete, summarize
    }

    /// The session that is open right now, if one is.
    private var openSelectionKind: SelectionKind? {
        if copySession { return .copy }
        if forwardSession { return .forward }
        if deleteSession { return .delete }
        if summarizeSession { return .summarize }
        return nil
    }

    /// Whether one message can be picked out, for a session of this kind. `nil` asks the same of
    /// a screen with no session open, which is what decides whether a row is built with a circle
    /// at all.
    ///
    /// Fix: this rule was written out twice - once to decide whether to draw a circle beside a
    /// row, once to decide whether a tap on that row counts - and nowhere at all where the menu
    /// opens the session. A file still waiting to be downloaded fails the rule, so its row was
    /// given no circle and answered no tap, and yet Forward had already marked it: the bar read
    /// "1 Selected" for a message that could be neither seen to be selected nor unselected, and
    /// forwarding it sent a file that is not on this device. One answer now, asked everywhere.
    private func canPickMessage(_ message: [String: Any?], for kind: SelectionKind?) -> Bool {
        let imageChat = message["image_id"] as? String ?? ""
        let videoChat = message["video_id"] as? String ?? ""
        let fileChat = message["file_id"] as? String ?? ""
        let audioChat = message["audio_id"] as? String ?? ""
        // What the message actually says, with a document's file name and a link's preview
        // details taken off - see `ChatMessageText`.
        let spoken = ChatMessageText.spoken(of: message).trimmingCharacters(in: .whitespacesAndNewlines)
        if !imageChat.isEmpty || !videoChat.isEmpty || !fileChat.isEmpty || !audioChat.isEmpty {
            let specFile = message[TypeDataMessage.spec_file] as? String ?? ""
            // Summarising reads what is written under the attachment and nothing else, so it
            // asks only whether anything is written there - not whether the file has been
            // downloaded, which is what the branches below go on to check.
            if kind == .summarize {
                if spoken.isEmpty {
                    return false
                }
            } else if kind == .copy && spoken.isEmpty {
                // Fix: this asked the raw field, which for a document is its file name and a bar
                // even when nothing was written with it - so a document with no caption could be
                // ticked in a copy session and copied out as an empty line.
                return false
            } else if kind == .forward && (!Nexilis.checkingAccess(key: "secure_folder_forward") || (!specFile.isEmpty && !specFile.contains("forward"))) {
                return false
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
                    // Nothing has been downloaded yet, so there is nothing here to forward, copy
                    // or hand on - only a name and a size. This is the line the whole rule is for.
                    if !FileManager.default.fileExists(atPath: fileURL.path) && !FileEncryption.shared.isSecureExists(filename: fileURL.lastPathComponent) {
                        return false
                    } else if !fileChat.isEmpty && spoken.isEmpty {
                        return false
                    }
                }
            }
        }
        if let kind = kind, kind != .delete,
           message["lock"] as? String == "1"
            || (message["credential"] as? String) == "1"
            || (message["lock"] as? String) == "2"
            || message["f_pin"] as? String ?? "" == "-999"
            || message["attachment_flag"] as? String ?? "" == "11"
            || (message["message_id"] as? String ?? "").contains("NTFPIN_") {
            return false
        }
        return true
    }

    /// Whether messages are being picked out right now, whatever the picking is for.
    private var isSelectionSessionActive: Bool {
        copySession || forwardSession || deleteSession || summarizeSession
    }

    /// Puts one cell into whichever of the two states the screen is in.
    ///
    /// Called on a cell handed back from the bubble cache as well, which is built once and then
    /// returned unchanged - without this it would come back carrying the state it was built in.
    private func applySelectionChrome(to cell: UITableViewCell) {
        if let mark = cell.contentView.viewWithTag(EditorGroup.selectionMarkTag) {
            mark.alpha = selectionChromeShown ? 1 : 0
            mark.transform = selectionChromeShown ? .identity : EditorGroup.selectionMarkHidden
        }
        if let picture = cell.contentView.viewWithTag(EditorGroup.selectionAvatarTag) {
            picture.alpha = selectionChromeShown ? 0 : 1
        }
        // Fix: a link, a mention, a picture, the sender's own picture - each answered a tap of
        // its own while a session was open, so a tap meant to tick a message opened a browser or
        // a profile instead. Nothing inside a bubble answers while messages are being picked;
        // the tap falls through to the row, which is the one thing the session is for.
        cell.contentView.isUserInteractionEnabled = !isSelectionSessionActive
    }
    

    /// The button that closes a selection session.
    ///
    /// Fix: iOS 26 closes a mode with a round button of glass carrying an x, and the word sitting
    /// where that button belongs is the one thing on this bar that still reads as the release
    /// before. Older releases keep the word, which is what they draw everywhere else.
    private func selectionCancelBarButton() -> UIBarButtonItem {
        if #available(iOS 26.0, *) {
            // Fix: this used to be a button carrying a glass background of its own, which the bar
            // then drew its own glass circle around - the pill outlined inside the circle. The
            // bar dresses whatever item it is given on this release, so the item is left plain
            // and the circle is the bar's.
            let item = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain,
                                       target: self, action: #selector(cancelAction))
            item.tintColor = .label
            return item
        }
        let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancelAction))
        cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white,
                                             NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
        return cancelButton
    }

    private func addSubviewMultipleSession() {
        let container = UIView()
        containerMultpileSelectSession.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        // iOS 26 floats a bar like this clear of the edges as a capsule of glass, which is what
        // that release does with every other bar; before it, the bar stays the full-width block
        // with the shadow, which is what those releases do.
        var sideInset: CGFloat = 0
        if #available(iOS 26.0, *) {
            sideInset = 16
        }
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: containerMultpileSelectSession.leadingAnchor, constant: sideInset),
            container.trailingAnchor.constraint(equalTo:containerMultpileSelectSession.trailingAnchor, constant: -sideInset),
            container.bottomAnchor.constraint(equalTo: containerMultpileSelectSession.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 50)
        ])
        if #available(iOS 26.0, *) {
            container.backgroundColor = .clear
            container.cornerConfiguration = .capsule()
            // The glass goes behind everything else the bar carries, so the count and the buttons
            // added below sit on it rather than under it.
            let glass = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
            container.insertSubview(glass, at: 0)
            glass.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                glass.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                glass.topAnchor.constraint(equalTo: container.topAnchor),
                glass.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            glass.cornerConfiguration = .capsule()
        } else {
            container.layer.shadowOpacity = 0.7
            container.layer.shadowOffset = CGSize(width: 3, height: 3)
            container.layer.shadowRadius = 3.0
            container.layer.shadowColor = UIColor.black.cgColor
            container.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .secondaryColor
        }
        
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
                // Fix: the raw field was copied, so a document handed over its file name with a
                // bar in front of the caption, and a link handed over the preview's own details
                // after the "■". What is copied is what the bubble shows - see `ChatMessageText`.
                let textCopied = ChatMessageText.spoken(of: dataMessages[i]).richText(isEditing: true, group_id: self.dataGroup["group_id"]  as? String ?? "")
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
                let spoken = ChatMessageText.spoken(of: message)
                if !spoken.isEmpty {
                    let dataUser = User.getData(pin: message[TypeDataMessage.f_pin] as? String ?? "", lPin: self.unique_l_pin)
                    contentText.append(dataUser?.fullName ?? "")
                    contentText.append(": ")
                    contentText.append(spoken)
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
    

    /// Puts a message that never left back on the queue.
    ///
    /// Audited on the way out of the context menu, and it was losing things. The rebuilt message
    /// dropped `gif_id` entirely - so a gif sent again came back as a video with no animation -
    /// and blanked `specFile`, `message_large_text` and `ex_format`, and never carried
    /// `is_forwarded` or `is_secret`. A message sent again should be the same message, not a
    /// plainer copy of it. Everything the row holds is passed through.
    ///
    /// One place, so the context menu and the "not sent" sheet cannot drift apart.
    func sendAgain(messageId: String) {
        guard !messageId.isEmpty,
              let idx = dataMessages.firstIndex(where: { $0[TypeDataMessage.message_id] as? String == messageId }) else {
            return
        }
        // A message is only stopped until it is asked for again - on the queue, and for the
        // note's own control.
        localEdits[messageId, default: 0] += 1
        OutgoingThread.default.clearCancelled(messageId: messageId)
        // Whatever is still queued for this message goes before a new copy is added. Two copies of
        // one message upload the same file, and the first to finish takes that file away from the
        // second.
        OutgoingThread.default.removeOutgoing(messageId: messageId)
        VideoNote.clearStopped(videoId: dataMessages[idx][TypeDataMessage.video_id] as? String ?? "")
        VideoNote.markSending(videoId: dataMessages[idx][TypeDataMessage.video_id] as? String ?? "")
        let row = dataMessages[idx]

        // Back to "on its way" wherever the state is kept: the collage, the list, and the database.
        if let parent = groupImages.firstIndex(where: { $0.value.contains(where: { $0.messageId == messageId }) }),
           let inImages = groupImages[parent].value.firstIndex(where: { $0.messageId == messageId }) {
            groupImages[parent].value[inImages].status = "1"
            groupImages[parent].value[inImages].dataMessage[TypeDataMessage.status] = "1"
        }
        dataMessages[idx][TypeDataMessage.status] = "1"
        dataMessages[idx][TypeDataMessage.progress] = 0.0
        let date = dataMessages[idx][TypeDataMessage.chat_date] as? String ?? ""
        if let section = dataDates.firstIndex(of: date),
           let rowIndex = messages(onDate: date).firstIndex(where: { $0[TypeDataMessage.message_id] as? String == messageId }),
           section < tableChatView.numberOfSections,
           rowIndex < tableChatView.numberOfRows(inSection: section) {
            tableChatView.reloadRowsKeepingPlace(at: [IndexPath(row: rowIndex, section: section)])
        }
        Database.shared.database?.inTransaction({ (fmdb, _) in
            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE",
                                             cvalues: ["status": "1"], _where: "message_id = '\(messageId)'")
            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS",
                                             cvalues: ["status": "1"], _where: "message_id = '\(messageId)'")
        })

        let message = CoreMessage_TMessageBank.sendMessage(
            message_id: messageId,
            l_pin: row[TypeDataMessage.l_pin] as? String ?? "",
            message_scope_id: row[TypeDataMessage.message_scope_id] as? String ?? "",
            status: "1",
            message_text: row[TypeDataMessage.message_text] as? String ?? "",
            credential: row[TypeDataMessage.credential] as? String ?? "",
            attachment_flag: row[TypeDataMessage.attachment_flag] as? String ?? "",
            ex_blog_id: row[TypeDataMessage.blog_id] as? String ?? "",
            message_large_text: "",
            ex_format: "",
            image_id: row[TypeDataMessage.image_id] as? String ?? "",
            audio_id: row[TypeDataMessage.audio_id] as? String ?? "",
            video_id: row[TypeDataMessage.video_id] as? String ?? "",
            file_id: row[TypeDataMessage.file_id] as? String ?? "",
            thumb_id: row[TypeDataMessage.thumb_id] as? String ?? "",
            reff_id: row[TypeDataMessage.reff_id] as? String ?? "",
            read_receipts: row[TypeDataMessage.read_receipts] as? String ?? "",
            chat_id: row[TypeDataMessage.chat_id] as? String ?? "",
            is_call_center: row[TypeDataMessage.is_call_center] as? String ?? "",
            call_center_id: row[TypeDataMessage.call_center_id] as? String ?? "",
            opposite_pin: row[TypeDataMessage.opposite_pin] as? String ?? "",
            gif_id: row[TypeDataMessage.gif_id] as? String ?? "",
            isForwarded: (row[TypeDataMessage.is_forwarded] as? Int).map(String.init) ?? "",
            isSecret: (row[TypeDataMessage.is_secret] as? Int).map(String.init) ?? "",
            specFile: row[TypeDataMessage.spec_file] as? String ?? "")
        Nexilis.addQueueMessage(message: message)
    }

    /// A send the reader stopped. The bytes are already halted; this is what it means for the
    /// message - it becomes one that never left, which is exactly what a failure looks like, and
    /// the red mark and its sheet follow from that.
    func markSendCancelled(messageId: String) {
        guard !messageId.isEmpty,
              let idx = dataMessages.firstIndex(where: { $0[TypeDataMessage.message_id] as? String == messageId }) else {
            return
        }
        // Off the queue first: cancelling the transfer only fails one attempt, and the outgoing
        // thread retries five times before giving up - which is how a stopped note sent itself
        // anyway a minute later.
        localEdits[messageId, default: 0] += 1
        OutgoingThread.default.cancelSend(messageId: messageId)
        // Every part of it, not just the part that happens to be moving. A picture goes up as a
        // thumbnail first and then the picture itself, so stopping one of them left the other to
        // finish and the message to go out after all.
        for name in [dataMessages[idx][TypeDataMessage.image_id] as? String,
                     dataMessages[idx][TypeDataMessage.video_id] as? String,
                     dataMessages[idx][TypeDataMessage.thumb_id] as? String] {
            Network.cancelUpload(name: name ?? "")
        }
        VideoNote.markStopped(videoId: dataMessages[idx][TypeDataMessage.video_id] as? String ?? "")
        VideoNote.clearSending(videoId: dataMessages[idx][TypeDataMessage.video_id] as? String ?? "")
        dataMessages[idx][TypeDataMessage.status] = "0"
        dataMessages[idx][TypeDataMessage.progress] = 0.0
        Database.shared.database?.inTransaction({ (fmdb, _) in
            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE",
                                             cvalues: ["status": "0"], _where: "message_id = '\(messageId)'")
            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS",
                                             cvalues: ["status": "0"], _where: "message_id = '\(messageId)'")
        })
        let date = dataMessages[idx][TypeDataMessage.chat_date] as? String ?? ""
        if let section = dataDates.firstIndex(of: date),
           let rowIndex = messages(onDate: date).firstIndex(where: { $0[TypeDataMessage.message_id] as? String == messageId }),
           section < tableChatView.numberOfSections,
           rowIndex < tableChatView.numberOfRows(inSection: section) {
            tableChatView.reloadRowsKeepingPlace(at: [IndexPath(row: rowIndex, section: section)])
        }
    }

    /// The message a reply is quoting, as much of it as the quote has to draw.
    ///
    /// Fix: audio_id and gif_id were not among the columns read. The quote's drawing turns on
    /// both - so replying to a voice note drew a quote with no line in it at all, and replying to
    /// an animated picture was quoted as "Video", since a gif travels in the video slot and only
    /// its own field tells the two apart.
    private func queryMessageReply(message_id: String) -> [String: Any?] {
        var dataQuery: [String: Any] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT message_id, f_pin, message_text, attachment_flag, thumb_id, image_id, video_id, file_id, audio_id, gif_id FROM MESSAGE where message_id='\(message_id)'"), c.next() {
                dataQuery["message_id"] = c.string(forColumnIndex: 0)
                dataQuery["f_pin"] = c.string(forColumnIndex: 1)
                dataQuery["message_text"] = c.string(forColumnIndex: 2)
                dataQuery["attachment_flag"] = c.string(forColumnIndex: 3)
                dataQuery["thumb_id"] = c.string(forColumnIndex: 4)
                dataQuery["image_id"] = c.string(forColumnIndex: 5)
                dataQuery["video_id"] = c.string(forColumnIndex: 6)
                dataQuery["file_id"] = c.string(forColumnIndex: 7)
                dataQuery["audio_id"] = c.string(forColumnIndex: 8)
                dataQuery["gif_id"] = c.string(forColumnIndex: 9)
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
                                UIPasteboard.general.string = ChatMessageText.spoken(of: dataMessages[indexPath.row])
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
            // Measured before the bar goes, and put back after: the list grows when it goes, so
            // shifting the content by the bar's height corrected on top of the correction a
            // scroll view already makes for itself - the smaller cousin of the jump the keyboard
            // used to cause. See restore(_:).
            let wasShowing = self.listAnchor
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                self.constraintTopTextField.constant = self.constraintTopTextField.constant - replyBarHeight
                self.view.layoutIfNeeded()
                self.restore(wasShowing)
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
    private func presentLinkActionSheet(urlString: String) {
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

        let sheetVC = LinkActionSheetViewController(urlString: urlString, onOpen: openAction, onCopy: copyAction, onOpenInChrome: openInChromeAction)
        // Fix: hides the highlight no matter how the sheet was dismissed (an action
        // tapped, or swiped away/tapped-outside with nothing chosen).
        sheetVC.onDismissed = { [weak self] in self?.hideLinkHighlight() }
        // Fix: one presentation path for every iOS version (see presentAsBottomSheet)
        // - the old iOS 14 UIAlertController fallback and the iOS 15 half-screen
        // `.medium()` sheet are both gone, so an iPhone 7 gets the same content-height
        // sheet as an iPhone 15.
        sheetVC.presentAsBottomSheet(from: self)
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
        // Nothing here needs to run alongside another recognizer any more: the link and
        // mention highlight is drawn from the text view's own touches - see PressableTextView.
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
    private func handleLinkTouch(_ phase: PressableTextView.Phase, at point: CGPoint, in textView: UITextView) {
        switch phase {
        case .began:
            // The same rule as the bubble menu: nothing is offered on a press that landed on a
            // list still in motion.
            guard !listMotion.isMoving(tableChatView) else {
                return
            }
            guard let info = LinkHighlighting.linkInfo(at: point, in: textView) else {
                // A mention is tappable too, so it gets the same highlight under the finger.
                // Nothing is offered on a long press over one, so no timer is started for it -
                // holding a mention leaves the bubble's own menu to appear as it always has.
                if let mention = LinkHighlighting.mentionInfo(at: point, in: textView) {
                    showLinkHighlight(range: mention.range, in: textView)
                }
                return
            }
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
                self.presentLinkActionSheet(urlString: urlString)
            }

        case .moved:
            if let info = LinkHighlighting.linkInfo(at: point, in: textView) {
                showLinkHighlight(range: info.range, in: textView)
            } else if let mention = LinkHighlighting.mentionInfo(at: point, in: textView) {
                // Dragged from a link onto a mention: the highlight follows the finger, and the
                // pending sheet for the link it left is invalidated by the generation bump.
                showLinkHighlight(range: mention.range, in: textView)
                linkPressGeneration += 1
            } else {
                // Fix: finger dragged off the link before the threshold - this is no
                // longer a press on this link at all, invalidate the pending timer
                // (via the generation bump) so it doesn't fire late for a touch that
                // moved elsewhere, and hide the highlight instantly - it must not
                // linger on a spot the finger isn't over anymore.
                hideLinkHighlight()
                linkPressGeneration += 1
            }

        case .ended, .cancelled:
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
        // A bubble that has just been sent or has just arrived grows into place as its row comes
        // on screen - see pendingBubbleArrival.
        playPendingBubbleArrivalIfNeeded(for: cell, at: indexPath)
        // Remember what each row actually measured, so the table estimates the rows it has
        // not built yet from real numbers. That is what keeps the content from shifting under
        // the reader when a page of older messages is inserted above.
        if let messageId = message(at: indexPath)?["message_id"] as? String, cell.frame.height > 0 {
            // The running total follows the dictionary rather than being reset wherever the
            // dictionary is emptied: an empty dictionary is a window that has been thrown away.
            if measuredRowHeights.isEmpty {
                measuredHeightTotal = 0
                measuredHeightSamples = 0
                settledRowHeightEstimate = nil
            }
            let built = message(at: indexPath) ?? [:]
            learnTextWidth(from: cell, isOwn: (built["f_pin"] as? String) == User.getMyPin())
            if measuredRowHeights[messageId] == nil {
                learnRowHeight(cell.frame.height, of: built, messageId: messageId)
            }
            let previouslyMeasured = measuredRowHeights[messageId]
            measuredRowHeights[messageId] = cell.frame.height
            // Fix: every row fed the average, pictures included - so the number used to guess at
            // a *text* row was pulled up by every picture in the conversation, and the guess for a
            // text bubble was several times what a text bubble comes to. The average is now only
            // asked of, and only answered for, the rows whose height nothing else can predict.
            if carriedHeight(of: message(at: indexPath) ?? [:], messageId: messageId) == nil {
                if let previouslyMeasured = previouslyMeasured {
                    measuredHeightTotal += cell.frame.height - previouslyMeasured
                } else {
                    measuredHeightTotal += cell.frame.height
                    measuredHeightSamples += 1
                }
            }
        }
        // Something new came into view; fetch whatever it needs once the list settles.
        scheduleAutoDownloadSweep()
    }

    /// What a row is expected to come to, before it has ever been built.
    ///
    /// Fix: an unbuilt row was guessed at with the average of every row measured so far, and for a
    /// bubble carrying a picture that guess is wrong by hundreds of points. Nothing corrects it
    /// until the row is really built, and a row is built when it comes into view - so any change
    /// that brought a picture into view moved the whole content by the difference, and the
    /// correction that keeps the reader in place brought further pictures into view, which moved
    /// it again. That is the jumping on a reply to a picture, and it is exactly why it showed
    /// itself only where the pictures were new to the screen: a chat just opened, and a page of
    /// older messages just read in. A text bubble never did it because the average is close enough
    /// for text.
    ///
    /// A picture's size is already known here without building anything - imageBubbleSize reads
    /// the thumbnail's header, not its pixels, and remembers the answer - so it is used, along
    /// with the fixed heights the other kinds of bubble are laid out at. These are the same
    /// numbers cellForRowAt lays them out from.
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard tableView == tableChatView else {
            return UITableView.automaticDimension
        }
        guard let row = message(at: indexPath), let messageId = row["message_id"] as? String else {
            return averageMeasuredRowHeight
        }
        if let height = measuredRowHeights[messageId] {
            return height
        }
        let carried = carriedHeight(of: row, messageId: messageId)
        // A bubble whose height still cannot be reckoned from the message alone - a link
        // preview's card, a form, a call - keeps the average. Those are the ones left.
        if carried == nil, !isPlainTextBubble(row) {
            rawRowGuesses[messageId] = averageMeasuredRowHeight
            rawTextParts[messageId] = 0
            return averageMeasuredRowHeight
        }
        // Fix: the pieces below and around the picture were left out of this sum, and left out
        // they come to some thirty points a row - the cell's own padding above and below the
        // bubble, and the line the caption view takes even when there is no caption in it. Thirty
        // points is small enough to look plausible and large enough to move the list every time
        // another row is measured for the first time, which is exactly why the first few replies
        // still jumped and the ones after them did not: by then every row within reach had been
        // measured, and there was nothing left to correct. Every piece cellForRowAt lays out is
        // counted here now.
        //
        // The cell's padding above and below the bubble.
        var height: CGFloat = 10
        // The room above whatever the bubble carries - the sender's name, where there is one.
        height += ((row["f_pin"] as? String) == User.getMyPin() ? 15 : 32)
        height += carried ?? 0
        // The text itself - the message where the bubble carries nothing else, the caption where
        // it does. Measured, not guessed: see textBubbleHeight. Kept apart from the rest of the
        // sum, because it is the part the proportional half of the learned difference works on.
        let textPart = textBubbleHeight(of: (row["message_text"] as? String) ?? "",
                                        messageId: messageId,
                                        isOwn: (row["f_pin"] as? String) == User.getMyPin())
        height += textPart
        // The margin under it.
        height += 15
        // A quote sits in the same room the sender's name does, and asks for at least fifty.
        if !((row["reff_id"] as? String) ?? "").isEmpty {
            height += 55
        }
        if (row[TypeDataMessage.is_forwarded] as? Int ?? 0) != 0 {
            height += 20
        }
        // A message carrying an acknowledgement, a confidential one, or one with sharing rules
        // keeps a taller foot for the mark that goes there.
        if (row["read_receipts"] as? String) == "8" || (row["credential"] as? String) == "1"
            || !(((row[TypeDataMessage.spec_file] as? String) ?? "").isEmpty) {
            height += 35
        }
        // And the row the unread marker sits above carries the marker as well.
        if let marker = markerCounter, marker == messageId {
            height += UnreadMarker.totalTopInset - 5
        }
        rawRowGuesses[messageId] = height
        rawTextParts[messageId] = textPart
        let answer = corrected(raw: height, text: textPart,
                               by: corrections[biasKey(
                                    kind: kindTag(of: row, messageId: messageId),
                                    isOwn: (row["f_pin"] as? String) == User.getMyPin())] ?? HeightCorrection())
        return answer
    }

    /// One word for what a bubble carries, for the on-screen trace.
    private func kindTag(of row: [String: Any?], messageId: String) -> String {
        if groupImages[messageId] != nil {
            return "collage"
        }
        if (row["attachment_flag"] as? String) == "11" {
            return "sticker"
        }
        if !(((row["thumb_id"] as? String) ?? "").isEmpty)
            || !(((row["image_id"] as? String) ?? "").isEmpty)
            || !(((row["video_id"] as? String) ?? "").isEmpty)
            || !(((row[TypeDataMessage.gif_id] as? String) ?? "").isEmpty) {
            return "picture"
        }
        if !(((row["file_id"] as? String) ?? "").isEmpty) {
            return "doc"
        }
        if !(((row["audio_id"] as? String) ?? "").isEmpty) {
            return "audio"
        }
        return isPlainTextBubble(row) ? "text" : "other"
    }

    /// Whether a bubble is nothing but its own text - which is the one case the arithmetic above
    /// can finish on its own.
    ///
    /// A link preview, a form, a call record, a contact-centre card and the rest all put something
    /// else in the bubble whose size is not in the message, so they are left to the average.
    private func isPlainTextBubble(_ row: [String: Any?]) -> Bool {
        let flag = (row["attachment_flag"] as? String) ?? ""
        guard flag.isEmpty || flag == "0" else {
            return false
        }
        let scope = (row[TypeDataMessage.message_scope_id] as? String) ?? ""
        guard scope != MessageScope.CALL, scope != MessageScope.MISSED_CALL, scope != "18" else {
            return false
        }
        guard ((row["blog_id"] as? String) ?? "").isEmpty else {
            return false
        }
        // A message carrying a link is drawn with the link's card under it when one was fetched,
        // and how tall that card is is not in the message.
        let text = ((row["message_text"] as? String) ?? "").lowercased()
        guard !text.contains("http://"), !text.contains("https://"), !text.contains("www.") else {
            return false
        }
        return true
    }

    /// The width the text is really laid out at, learned from a bubble that has been built - one
    /// for the reader's own bubbles, one for everybody else's.
    ///
    /// Fix: the width was reckoned as the screen less a hundred and five points, read off the
    /// bubble's constraints. The trace says that is a little narrow: a document with a long
    /// caption was reckoned at 1300 points and drawn at 1156, and another at 1353 against 1227 -
    /// twelve per cent too tall, which is what a few points of missing width does to forty lines
    /// of wrapping. The width a bubble wraps at is not worth deriving when a bubble that has
    /// already been drawn can simply be asked.
    /// How far this conversation's rows really come out from what the arithmetic below reckons,
    /// learned per kind of bubble and per side of the conversation.
    ///
    /// Fix: three constants have been fitted to this by now - eighteen points for the room a
    /// sender's name takes, a width for the text to wrap at, the fold at fifty lines - and each
    /// one was right about the samples it was fitted to and wrong about the next lot. The
    /// arithmetic can only ever be as good as the constants that can be read out of cellForRowAt,
    /// and some of what a bubble takes is not among them.
    ///
    /// So what is left over is not guessed at any more, it is measured. Every row that gets built
    /// reports how far the reckoning was out for its kind, and the reckoning for the rows after it
    /// carries that difference. It settles within a handful of rows, it cannot be wrong about this
    /// conversation because this conversation is what it learns from, and it needs no constant
    /// from me at all.
    private func biasKey(kind: String, isOwn: Bool) -> String {
        return isOwn ? kind + "-own" : kind
    }

    /// What the reckoning for one kind of bubble is out by, in two parts.
    ///
    /// Fix: it was one number, and one number cannot describe what the trace showed. A short text
    /// bubble came out eighteen points *shorter* than reckoned while a long one came out seventy
    /// points *taller* - both tagged the same kind, so a single average was pulled between them
    /// and neither ever settled. They are two different errors: something fixed that every bubble
    /// of that kind carries, and something proportional to how much text it holds, which is what a
    /// few points of wrapping width comes to over forty lines. So both are learned, and each from
    /// the rows that can see it - the fixed part from bubbles with little text in them, the
    /// proportional part from the ones with a lot.
    private struct HeightCorrection {
        var offset: CGFloat = 0
        var scale: CGFloat = 1
        var offsetSamples = 0
        var scaleSamples = 0
        /// How many rows are enough. Six is plenty to average out one odd bubble, and few enough
        /// that the settling is over within the first screenful.
        static let enough = 6
    }

    /// One row has been built: what it came to is what its kind is worth.
    ///
    /// Fix: this went on learning for ever, and a reckoning that never stops moving is the same
    /// trap the running average was - the one this replaced. Every row measured moved the
    /// reckoning, which moved the height of every row of that kind not yet built, which moved the
    /// content and everything worked out from it. Measured off a recording, the conversation crept
    /// a hundred and seventy points down the list on every open-and-close of a reply, in clean
    /// hundred-and-fifteen-point steps - one step for each time the reckoning shifted under it.
    ///
    /// So it learns and then it stops. Six rows of a kind settle it, as a plain average rather
    /// than a decaying one so those six count equally, and after that the answer is fixed for the
    /// life of the window. A number that does not move cannot move anything else.
    private func learnRowHeight(_ real: CGFloat, of row: [String: Any?], messageId: String) {
        guard real > 0, let raw = rawRowGuesses[messageId] else {
            return
        }
        let text = rawTextParts[messageId] ?? 0
        let key = biasKey(kind: kindTag(of: row, messageId: messageId),
                          isOwn: (row["f_pin"] as? String) == User.getMyPin())
        var correction = corrections[key] ?? HeightCorrection()
        let error = real - corrected(raw: raw, text: text, by: correction)
        // The fixed part is only visible on a bubble with little text in it, and the proportional
        // part only on one with a lot - so each is learned from the rows that can see it, and each
        // settles on its own count.
        if text < 40 {
            guard correction.offsetSamples < HeightCorrection.enough else {
                return
            }
            correction.offsetSamples += 1
            correction.offset = min(max(correction.offset + error / CGFloat(correction.offsetSamples), -120), 120)
        } else {
            guard correction.scaleSamples < HeightCorrection.enough else {
                return
            }
            correction.scaleSamples += 1
            correction.scale = min(max(correction.scale + (error / text) / CGFloat(correction.scaleSamples), 0.6), 1.6)
        }
        corrections[key] = correction
    }

    /// The reckoning with this kind's learned difference in it.
    private func corrected(raw: CGFloat, text: CGFloat, by correction: HeightCorrection) -> CGFloat {
        return max(28, (raw - text) + text * correction.scale + correction.offset)
    }

    /// Takes the real width out of a bubble the table has just built.
    private func learnTextWidth(from cell: UITableViewCell, isOwn: Bool) {
        guard let width = cell.contentView.subviews
            .flatMap({ $0.subviews })
            .compactMap({ $0 as? UITextView })
            .map({ $0.bounds.width })
            .max(), width > 40 else {
            return
        }
        // The widest one seen, not the latest. A bubble is only as wide as its own message
        // needs, so a short message would teach a width narrower than the one a long message
        // wraps at - and a width too narrow is what makes a long message reckoned too tall in the
        // first place. The widest bubble drawn so far is the one that tells the truth about where
        // the wrapping happens.
        guard width > (textWidths[isOwn] ?? 0) + 0.5 else {
            return
        }
        textWidths[isOwn] = width
        // What was measured at the old width is no longer an answer to anything.
        textBubbleHeights.removeAll()
    }

    /// What a message's own text comes to, measured once and remembered.
    ///
    /// Fix: text was the one thing left on the average, on the reasoning that a text bubble is
    /// only tens of points off. The on-screen trace says otherwise: guessed at 123, drawn at 289 -
    /// a hundred and sixty-six points on a single row, and two such rows moved the whole
    /// conversation by three hundred and fifty in the same breath as the reply bar opened. A long
    /// message is simply tall, and no average over a conversation of short ones can know that.
    ///
    /// It is measured the way it is drawn - the same font, the same width the bubble gives it -
    /// and kept, so a row costs this once and never again.
    private func textBubbleHeight(of text: String, messageId: String, isOwn: Bool) -> CGFloat {
        if let known = textBubbleHeights[messageId] {
            return known
        }
        let font = UIFont.systemFont(ofSize: 12 + offset())
        // The width a bubble that has been drawn actually wraps at, and until one has been drawn
        // the bubble's constraints read off cellForRowAt: sixty points clear on one side and
        // fifteen on the other, with the text fifteen inside the bubble at each edge.
        let screen = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        let width = textWidths[isOwn] ?? max(40, screen - 105)
        // Fix: the whole message was measured, and a long one is not drawn whole. It is folded at
        // fifty lines with a "Read more" under it until the reader opens it - so the trace had a
        // message reckoned at 2001 points and drawn at 1065, nearly twice over, and a second at
        // 1289 against 1029. Measured here the way it is drawn there: the folded text, through the
        // same folding the bubble itself uses, and a line for the "Read more" that closes it.
        let shown = foldIfLong(text, messageId: messageId)
        var measured = ceil((shown as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil).height)
        if isFolded(messageId, text: text) {
            measured += ceil(font.lineHeight)
        }
        // Never less than the line the empty view still takes.
        let height = max(measured, ceil(font.lineHeight))
        if !messageId.isEmpty {
            textBubbleHeights[messageId] = height
        }
        return height
    }

    /// How much room what a bubble carries asks for, or nil when that cannot be known from the
    /// message alone - which is the case for plain text and for a link preview, whose height
    /// comes from text that has to be laid out.
    ///
    /// The audit behind the numbers, each one taken from where cellForRowAt adds it: a collage is
    /// a fixed square of tiles; a sticker is a fixed square; a picture, a video or an animated
    /// picture is the size its own thumbnail says, with a floor for the ones too small to see; a
    /// document is the fixed card; a voice note is the fixed bar. A message taken back or expired
    /// draws none of it and falls through to the average, because what is left is a line of text.
    private func carriedHeight(of row: [String: Any?], messageId: String) -> CGFloat? {
        let lock = (row["lock"] as? String) ?? ""
        guard lock != "1", lock != "2" else {
            return nil
        }
        if let members = groupImages[messageId], !members.isEmpty {
            return 220
        }
        if (row["attachment_flag"] as? String) == "11" {
            return 100
        }
        let thumb = (row["thumb_id"] as? String) ?? ""
        let carriesPicture = !thumb.isEmpty
            || !(((row["image_id"] as? String) ?? "").isEmpty)
            || !(((row["video_id"] as? String) ?? "").isEmpty)
            || !(((row[TypeDataMessage.gif_id] as? String) ?? "").isEmpty)
        if carriesPicture {
            return max(imageBubbleSize(messageId: messageId, thumb: thumb).height, 40)
        }
        if !(((row["file_id"] as? String) ?? "").isEmpty) {
            return 55
        }
        if !(((row["audio_id"] as? String) ?? "").isEmpty) {
            return 40
        }
        return nil
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        lastY = scrollView.contentOffset.y
        if scrollView == tableChatView {
            dateHeaders.listDidMove(isDragging: scrollView.isDragging, in: tableChatView)
            listMotion.didMove()
        }
        // The reader has taken the list over - a later layout pass must not pull it back to
        // the unread marker under their finger.
        if scrollView == tableChatView, scrollView.isDragging, pendingUnreadMarkerScroll != nil {
            pendingUnreadMarkerScroll = nil
        }
        // And the same for the opening placement: a finger on the list outranks it.
        if scrollView == tableChatView, scrollView.isDragging, pendingInitialScrollToBottom {
            pendingInitialScrollToBottom = false
            initialBottomDeadline = nil
            initialBottomStartedAt = nil
        }
        if scrollView == tableChatView, scrollView.isDragging, isDashingToBottom {
            isDashingToBottom = false
        }
        // Every page is read where the reader has no momentum: with the finger on the glass, or
        // with the list at rest. Never mid-fling.
        //
        // Fix: there were two more triggers here, one for a fling that had nearly run out and
        // one last resort for a fling that reached the top of what was loaded. Both read a page
        // while the list was still moving under its own weight, and reading a page ends with the
        // list being put back where the reader was - which writes the scroll position from
        // outside, and that ends a fling on the spot. Measured off a recording, the scroll slowed
        // smoothly from about six and a half thousand points a second down to four and a half,
        // exactly as a fling should, and then went to nothing in two frames. That is not a fling
        // ending, that is a fling being cut, and it happened once for every page read - which is
        // the stop with no slowing down before it.
        //
        // So they are gone. What is left reads the page as the finger lands, and only once the
        // reader is within olderMessageLead of the end of what is loaded. A fling that outruns
        // that now reaches the top of what is loaded and rubber-bands there, the way the top of
        // any list does, and the page is read the moment it settles - a soft stop at a false
        // beginning, where there used to be a dead one mid-screen.
        //
        // Not while the list is being taken to its newest message, though. That journey passes
        // the top of the loaded window on its way down, and a page inserted above the reader
        // moves the end they are travelling towards - which is how a tap on the button used to
        // stop short of the bottom.
        if scrollView == tableChatView, !isInitialLoading, !pendingInitialScrollToBottom,
           !isDashingToBottom, hasOlderMessages, scrollView.isDragging,
           scrollView.contentOffset.y < scrollView.frame.height * EditorGroup.olderMessageLead {
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

    /// The finger has just landed. If the reader is anywhere near the end of what is loaded, the
    /// next page is read now.
    ///
    /// This is the earliest warning there is, and the best moment to take it: the content is held
    /// under the finger, so putting the list back where it was is invisible, and there is no
    /// momentum to interrupt. Every page read from here is a page not read mid-fling.
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == tableChatView, !isInitialLoading, !pendingInitialScrollToBottom,
              !isDashingToBottom, hasOlderMessages else {
            return
        }
        guard scrollView.contentOffset.y < scrollView.frame.height * EditorGroup.olderMessageLead else {
            return
        }
        loadOlderMessages()
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == tableChatView else {
            return
        }
        dateHeaders.listDidSettle(in: tableChatView)
        prefetchOlderMessagesIfIdle()
        scheduleAutoDownloadSweep()
        // Where the list comes to rest is the last word on what has been seen: the checks made
        // while it was moving are throttled, so the final position can be missed.
        markVisibleMessagesRead()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == tableChatView, !decelerate else {
            return
        }
        // The finger has left and nothing is left moving, which is exactly when the date goes.
        dateHeaders.listDidSettle(in: tableChatView)
        prefetchOlderMessagesIfIdle()
        scheduleAutoDownloadSweep()
        markVisibleMessagesRead()
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
        // Counted from the same list the rows are drawn from, and no other: a count that says
        // one more row than that list can hand over is a row drawn as an empty bubble.
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
        dateView.backgroundColor = DateHeaderVisibility.pillBackground
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
        labelDate.textColor = DateHeaderVisibility.pillText
        labelDate.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
        labelDate.text = dataDates[section]
        dateHeaders.track(containerView, section: section, in: tableView)
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
            // One rule for whether a message can be picked - see `canPickMessage`. A row that
            // fails it draws no circle, so a tap on it must not quietly change the count either.
            guard canPickMessage(dataMessages[indexPath.row], for: openSelectionKind) else {
                return
            }
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"]  as? String ?? "" == dataMessages[indexPath.row]["message_id"]  as? String ?? ""})
            if idx != nil {
                self.dataMessages[idx!]["isSelected"] = !(self.dataMessages[idx!]["isSelected"] as? Bool ?? false)
                self.tableChatView.reloadRowsKeepingPlace(at: [indexPath])
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
            cellMention.backgroundColor = .clear
            // Fix: a row could be asked for after the list behind it had already been emptied -
            // showMention clears it and reloads on every keystroke - and the row was then drawn
            // with no name and no picture, which is what left blank lines in the list.
            guard indexPath.row < listMentionWithText.count else {
                cellMention.contentConfiguration = nil
                return cellMention
            }
            let mentioned = listMentionWithText[indexPath.row]
            var content = cellMention.defaultContentConfiguration()
            // 15 rather than 11: this is a name being picked out of a list, at arm's length,
            // and 11 point is smaller than anything else in the conversation.
            content.textProperties.font = UIFont.systemFont(ofSize: 15 + offset())
            content.textProperties.color = .label
            content.textProperties.numberOfLines = 1
            content.textProperties.lineBreakMode = .byTruncatingTail
            content.imageProperties.tintColor = .secondaryLabel
            content.imageProperties.maximumSize = CGSize(width: ChatMentionList.avatarSize, height: ChatMentionList.avatarSize)
            content.imageProperties.cornerRadius = ChatMentionList.avatarSize / 2
            content.imageToTextPadding = 12
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
            if mentioned.pin == "-997" {
                // Decoded once and held - see ChatMentionList.botAvatar.
                content.image = ChatMentionList.botAvatar
            } else {
                // The completion runs straight away when the picture is on disk or already
                // decoded, which is the case that matters here; when it is not, getImage draws
                // this one row again once it has been fetched.
                getImage(name: mentioned.thumb,
                         placeholderImage: UIImage(systemName: "person.crop.circle"),
                         isCircle: true,
                         tableView: tableView,
                         indexPath: indexPath,
                         targetSize: CGSize(width: ChatMentionList.avatarSize, height: ChatMentionList.avatarSize),
                         completion: { _, _, image in
                    content.image = image
                })
            }
            // Fix: the two names were joined with a space whether or not there was a second one,
            // so anybody without a last name was listed with a space hanging off the end - and
            // somebody with neither was listed as nothing at all.
            let name = mentioned.fullName
            content.text = name.isEmpty ? mentioned.pin : name
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
            // Fix: this clears a bubble left off to one side by an interrupted pull - but it
            // used to clear the one that is growing into place as well, which killed the arrival
            // animation two frames after it started. A row in the middle of arriving is left
            // entirely alone: everything in it is being held back on purpose.
            if cellMessage !== arrivingCell {
                cellMessage.contentView.subviews.forEach { $0.transform = .identity }
            }
            applySelectionChrome(to: cellMessage)
            return cellMessage
        }
        emptyBubbleCell(cellMessage)
        setBuiltSignature(signature, on: cellMessage)
        // See `applySelectionChrome`: while messages are being picked, a tap belongs to the row
        // and to nothing the row is carrying.
        cellMessage.contentView.isUserInteractionEnabled = !isSelectionSessionActive
        
        let profileMessage = UIImageView()
        profileMessage.frame.size = CGSize(width: 35, height: 35)
        cellMessage.contentView.addSubview(profileMessage)
        profileMessage.translatesAutoresizingMaskIntoConstraints = false
        let tapGestureRecognizer = ObjectGesture(target: self, action: #selector(profilePersonTapped(_:)))
        tapGestureRecognizer.message_id = dataMessages[indexPath.row]["f_pin"]  as? String ?? ""
        profileMessage.isUserInteractionEnabled = true
        profileMessage.addGestureRecognizer(tapGestureRecognizer)
        
        var containerMessage: UIView = BubbleView()
        containerMessage.tag = EditorGroup.bubbleTag
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
            (containerMessage as? BubbleView)?.lift()
            
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
        
        let messageText = PressableTextView()
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
        // The view's own touches, not a recognizer - see PressableTextView for why.
        messageText.onTouch = { [weak self, weak messageText] phase, point in
            guard let self = self, let messageText = messageText else { return }
            self.handleLinkTouch(phase, at: point, in: messageText)
        }

        containerMessage.addSubview(messageText)
        messageText.translatesAutoresizingMaskIntoConstraints = false
        // Your own messages carry neither your picture nor your name - you know who you are, and
        // WhatsApp leaves both off for the same reason. The name is what the 32 points at the top
        // of a bubble were held for, so without it the content starts at 15 like a personal chat.
        let isOwnMessage = dataMessages[indexPath.row]["f_pin"] as? String == idMe
        // Own messages carry no name inside the bubble, so their text starts higher. The check
        // further down has to recognise whichever of the two applies, which is why this is a
        // variable rather than the literal 32 that check used to compare against.
        let baseTopMarginText: CGFloat = isOwnMessage ? 15 : 32
        var topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: baseTopMarginText)
        topMarginText.priority = .defaultHigh
        
        let dataProfile = getDataProfile(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "", message_id: dataMessages[indexPath.row]["message_id"]  as? String ?? "")
        
        let statusMessage = UIImageView()
        
        if (dataMessages[indexPath.row]["attachment_flag"] as? String == "0" && dataMessages[indexPath.row]["lock"] as? String != "1") || forwardSession || deleteSession || summarizeSession {
            let showSelectedImage = canPickMessage(dataMessages[indexPath.row], for: openSelectionKind)
            if showSelectedImage {
                let selectedImage = UIImageView()
                cellMessage.contentView.addSubview(selectedImage)
                selectedImage.tag = EditorGroup.selectionMarkTag
                selectedImage.translatesAutoresizingMaskIntoConstraints = false
                selectedImage.frame.size = CGSize(width: 20, height: 20)
                // Fix: the circle used to be given a column of its own at the left edge, and the
                // picture and the bubble beside it were pushed 35pt over to clear it - the whole
                // row jumped sideways the moment a session opened. It takes the picture's column
                // now, so the two cross-fade in place and nothing else moves. An own message has
                // no picture, so there the circle keeps the column one would have taken.
                //
                // Its height is read off the bubble rather than off the row: the row carries the
                // time and the acknowledgement under the bubble, so the middle of the row sits
                // below the middle of what is being chosen.
                let column: NSLayoutConstraint = (dataMessages[indexPath.row]["f_pin"] as? String == idMe)
                    ? selectedImage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 22.5)
                    : selectedImage.centerXAnchor.constraint(equalTo: profileMessage.centerXAnchor)
                NSLayoutConstraint.activate([
                    column,
                    selectedImage.centerYAnchor.constraint(equalTo: containerMessage.centerYAnchor),
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
                // Built in whichever state the screen is in, so a row that scrolls in during a
                // session is not caught halfway through a fade it never took part in.
                selectedImage.alpha = selectionChromeShown ? 1 : 0
                selectedImage.transform = selectionChromeShown ? .identity : EditorGroup.selectionMarkHidden
            }
        }
        
        // Who sent this, when the bubble says so at all - only incoming messages in a group
        // carry a name, and only some of what follows has to make room for it.
        var senderNameLabel: UILabel?
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            // No picture on your own messages, so the bubble takes the room it used to leave.
            profileMessage.removeFromSuperview()

            containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 5).isActive = true
            containerMessage.leadingAnchor.constraint(greaterThanOrEqualTo: cellMessage.contentView.leadingAnchor, constant: 60).isActive = true
            containerMessage.trailingAnchor.constraint(equalTo: cellMessage.contentView.trailingAnchor, constant: -15).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            containerMessage.clipsToBounds = true
            (containerMessage as? BubbleView)?.lift()
            
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
            
            // Your own name is not shown here; only the bubble colour is still needed.
            if (dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "") {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .blueBubbleColor
            }
            
        } else {
            // The picture no longer moves aside for the circle - the circle is drawn on top of
            // it and the two cross-fade, so this is the one leading it has ever needed.
            profileMessage.tag = EditorGroup.selectionAvatarTag
            profileMessage.alpha = selectionChromeShown ? 0 : 1
            profileMessage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 15).isActive = true
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
                    profileMessage.loadImageAsync(with: Utils.getUrlDock())
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
                profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: UnreadMarker.totalTopInset).isActive = true
                containerMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: UnreadMarker.totalTopInset).isActive = true
                
                UnreadMarker.install(in: cellMessage.contentView, count: markerCount, fontSize: 14 + offset())
                
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
            (containerMessage as? BubbleView)?.lift()
            
            timeMessage.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
            
            let nameSender = UILabel()
            // Kept, because a round video note has to be laid out below it rather than over it -
            // see the video-note branch further down.
            senderNameLabel = nameSender
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
            nameSender.textColor = UIColor.participant(
                pin: dataMessages[indexPath.row]["f_pin"] as? String ?? "",
                conversation: self.conversationScope(),
                on: containerMessage.backgroundColor ?? .whiteBubbleColor)
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
                    imageSticker.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: isOwnMessage ? 15 : 32).isActive = true
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
                applyReadMore(to: messageText, text: textChat, messageId: messageIdChat) {
                    $0.richText(group_id: self.dataGroup["group_id"] as? String ?? "")
                }
                modifyText(at: indexPath)
            }
        } else {
            applyReadMore(to: messageText, text: textChat, messageId: messageIdChat) {
                $0.richText(group_id: self.dataGroup["group_id"] as? String ?? "")
            }
            modifyText(at: indexPath)
        }
        
        func modifyText(at indexPath: IndexPath) {
            guard !textChat.isEmpty else { return }
            guard indexPath.row >= 0, indexPath.row < dataMessages.count else {
                print("⚠️ modifyText: Invalid index \(indexPath.row), total: \(dataMessages.count)")
                return
            }

            // Fix: this rebuilt the whole attributed string from the full message text to add
            // link attributes, and then assigned it - so a message that had just been folded was
            // handed its full text back one line later and the "Read more" went with it. It works
            // on what is actually being shown now, and puts the "Read more" back afterwards.
            var text = foldIfLong(textChat, messageId: messageIdChat)
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

            if isFolded(messageIdChat, text: textChat) {
                finalAttributed.append(readMoreSuffix())
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
            // Fix: a search re-renders the bubble from the raw message text to add the
            // highlight, and the raw text of a message with a link still carries the link
            // preview after the "■" - which the ordinary render strips before drawing. So
            // the moment a search was typed, every bubble with a link grew its "■" tail back.
            // The same rule the bubble, reply and copy use: see ChatMessageText.
            applyReadMore(to: messageText, text: ChatMessageText.withoutLinkPreview(textChat), messageId: messageIdChat) {
                $0.richText(isSearching: true, textSearch: self.textSearch, group_id: self.dataGroup["group_id"] as? String ?? "")
            }
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
            // Fix: hidden or not, the label is still laid out, and with a long file name behind it
            // it demanded a width the audio row never asked for - which is how the same note came
            // out at two different widths on two screens. It yields instead: the row has a width of
            // its own now, and the bubble takes that.
            messageText.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            messageText.setContentHuggingPriority(.defaultLow, for: .horizontal)
            // Fix: 32 is the room the sender's name takes at the top of a bubble, and an own
            // bubble does not show one - so it was holding a gap open for something that is not
            // there. Own bubbles take the same 15 a personal chat does; the extra 20 a
            // "forwarded" line needs is the same either way.
            var padTop: CGFloat = isOwnMessage ? 15 : 32
            if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as? Int ?? 0 != 0 {
                padTop += 20
            }
            
            let incomingAudio = (dataMessages[indexPath.row]["f_pin"] as? String) != idMe
            // A voice note and an ordinary audio file are two different things, and the flag they
            // travel under is what tells them apart - which is why a recording is sent as 60.
            let isVoiceNoteAudio = (dataMessages[indexPath.row][TypeDataMessage.attachment_flag] as? String) == "60"
            // Fix: this row used to be built by hand here and by hand again in the message info
            // screen, and the two had drifted into drawing the same voice note as two different
            // things. It is one view now, and both places get whatever it says.
            let contAudio = AudioBubbleContent(incoming: incomingAudio,
                                               isVoiceNote: isVoiceNoteAudio,
                                               bubbleColour: containerMessage.backgroundColor ?? .white,
                                               traits: traitCollection,
                                               fontOffset: offset())
            containerMessage.addSubview(contAudio)
            // Fix: the top was whatever the rest of the bubble needed and the bottom a flat 15,
            // so the row never sat level in its own bubble. Measured off the reference instead:
            // the picture is 44pt with 10pt clear above and below it.
            contAudio.anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, right: containerMessage.rightAnchor, paddingTop: max(padTop, 10), paddingLeft: 10, paddingBottom: 10, paddingRight: 12)
            contAudio.setPicture(named: senderThumb(forPin: dataMessages[indexPath.row]["f_pin"] as? String ?? "",
                                                    messageId: messageIdChat) ?? "")

            let avatarBoxAudio = contAudio.avatarBox
            let imageAudio = contAudio.picture
            let speedPillAudio = contAudio.speedPill
            let playButtonAudio = contAudio.playButton
            let progressSliderAudio = contAudio.slider
            let waveAudio = contAudio.wave
            let timeLabelAudio = contAudio.timeLabel

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
                    // One player per recording, kept by the service - never opened here. A
                    // bubble that opened its own would be a second player for a recording that
                    // may already be playing somewhere else, which is what left this row silent
                    // and showing a play button while the sound carried on.
                    let audioPlayer = AudioMiniPlayer.shared.player(for: messageIdChat,
                                                                    openingFrom: url,
                                                                    rate: audioRates[messageIdChat] ?? 1)
                    if let audioPlayer = audioPlayer, audioPlayers[messageIdChat] !== audioPlayer {
                        audioPlayers[messageIdChat] = audioPlayer
                        audioPlayer.delegate = self
                        if audioPlayer.isPlaying {
                            // Still running from before this screen was opened - the strip comes
                            // down and this bubble shows it from here on.
                            _ = AudioMiniPlayer.shared.reclaim(messageId: messageIdChat)
                            playingAudioId = messageIdChat
                            beginAudioSession(messageIdChat)
                        }
                    }
                    // Fix: the length and the reading under the line were written only on the pass
                    // that first opened the file. A player now outlives its audio finishing (so a
                    // drag in progress is not cut short), so a bubble scrolled back to would have
                    // shown a bare 0:00 - they are taken from the player on every pass instead.
                    if let player = audioPlayer {
                        progressSliderAudio.maximumValue = Float(player.duration)
                        progressSliderAudio.value = Float(player.currentTime)
                        timeLabelAudio.text = formatTime(player.currentTime > 0 ? player.currentTime : player.duration)
                    }
                    // Fix: this also asked whether this screen thought it was the one playing,
                    // which it does not think while the strip still holds the recording - so a
                    // bubble drawn at that moment showed a play button over audible sound. What
                    // the player is doing is the only thing that decides.
                    if let player = audioPlayer, player.isPlaying {
                        playButtonAudio.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                    } else {
                        playButtonAudio.setImage(UIImage(systemName: "play.fill"), for: .normal)
                    }

                    // Drawn from what is already known about this file, so a bubble scrolled back
                    // to shows its line at once rather than reading the file again.
                    // Held so that audio running out on its own can put the bubble back to rest
                    // where it stands, instead of rebuilding the row - see audioPlayerDidFinishPlaying.
                    audioSliders[messageIdChat] = progressSliderAudio
                    audioPlayButtons[messageIdChat] = playButtonAudio
                    audioTimeLabels[messageIdChat] = timeLabelAudio
                    // Already playing when the bubble was built - taken back from the strip, or
                    // scrolled away from and returned to - so the row needs its own ticker or the
                    // line would sit still while the recording ran.
                    if let running = audioPlayer, running.isPlaying, timers[messageIdChat] == nil {
                        startAudioTicker(messageId: messageIdChat,
                                         progressSlider: progressSliderAudio,
                                         timeLabel: timeLabelAudio,
                                         wave: isVoiceNoteAudio ? waveAudio : nil)
                    }
                    if isVoiceNoteAudio {
                        if let known = AudioWaveformStore.levels(for: audioChat) {
                            waveAudio.levels = known
                        } else {
                            // Fix: the file was read only on the pass that first opened it, and the
                            // answer went to whichever view happened to be on screen at the time. A
                            // row rebuilt before the read landed - a checkmark arriving on a note
                            // just sent, a push refreshing the bubble on the other side - was left
                            // with an empty line, and nothing ever asked again; only closing the
                            // conversation and coming back drew it. Asked for on any pass that has
                            // no line yet, and answered to whichever view stands for the message by
                            // the time the answer comes.
                            AudioWaveformStore.read(url: url, key: audioChat) { [weak self] levels in
                                guard let self = self, self.audioViewsAlive(messageIdChat) else {
                                    return
                                }
                                self.audioWaves[messageIdChat]?.levels = levels
                            }
                        }
                        waveAudio.progress = progressSliderAudio.maximumValue > 0
                            ? CGFloat(progressSliderAudio.value / progressSliderAudio.maximumValue)
                            : 0
                        audioWaves[messageIdChat] = waveAudio
                        audioSpeedPills[messageIdChat] = speedPillAudio
                        audioAvatars[messageIdChat] = avatarBoxAudio

                        // A bubble scrolled away and back comes back the way it was left: still
                        // being listened to, and still at the speed that was chosen for it.
                        let listeningAudio = audioSessions.contains(messageIdChat)
                        speedPillAudio.setTitle(audioRateLabel(audioRates[messageIdChat] ?? 1), for: .normal)
                        speedPillAudio.isHidden = !listeningAudio
                        avatarBoxAudio.isHidden = listeningAudio

                        speedPillAudio.addAction(UIAction { [weak self] _ in
                            self?.cycleAudioRate(messageId: messageIdChat)
                        }, for: .touchUpInside)
                    } else {
                        // Nothing trades places with the disc on a file, so neither the speed
                        // button nor the drawn line is registered and showAudioSpeed, asked to
                        // swap them, finds nothing to swap.
                        audioWaves[messageIdChat] = nil
                        audioSpeedPills[messageIdChat] = nil
                        audioAvatars[messageIdChat] = nil
                    }

                    // Play/Pause Button Action
                    playButtonAudio.addAction(UIAction { _ in
                        self.playPauseAudio(messageId: messageIdChat, playButton: playButtonAudio, progressSlider: progressSliderAudio, timeLabel: timeLabelAudio)
                    }, for: .touchUpInside)
                    
                    // Fix: every twitch of the finger asked the player to seek, and seeking is
                    // not free - a drag became a queue of seeks the player was still working
                    // through, which is the lag. While the finger is down only the writing moves;
                    // the player is sent to the new place once, when the finger lifts.
                    progressSliderAudio.addAction(UIAction { [weak waveAudio] _ in
                        timeLabelAudio.text = self.formatTime(TimeInterval(progressSliderAudio.value))
                        if progressSliderAudio.maximumValue > 0 {
                            waveAudio?.progress = CGFloat(progressSliderAudio.value / progressSliderAudio.maximumValue)
                        }
                    }, for: .valueChanged)
                    let seek = UIAction { _ in
                        self.sliderChanged(messageId: messageIdChat, progressSlider: progressSliderAudio, timeLabel: timeLabelAudio)
                    }
                    progressSliderAudio.addAction(seek, for: .touchUpInside)
                    progressSliderAudio.addAction(seek, for: .touchUpOutside)
                    progressSliderAudio.addAction(seek, for: .touchCancel)
                }
            }
        }
        
        // A round video note is not a bubble with a picture inside it - it is a circle sitting on
        // the wallpaper, with the time and the ticks beside it as usual. It has no caption, no
        // quote and no collage, so none of the media layout below applies and the cell is finished
        // here. What marks one out is the name of its file; see VideoNote.
        if VideoNote.isNote(videoChat) {
            containerMessage.backgroundColor = .clear
            // lift() has already been run with a colour, and a shadow under a transparent square
            // behind a circle is a shadow cast by nothing.
            containerMessage.layer.shadowOpacity = 0
            messageText.isHidden = true

            let note = VideoNoteBubbleView()
            containerMessage.addSubview(note)
            note.translatesAutoresizingMaskIntoConstraints = false
            // Fix: the circle was pinned to the top of the bubble, and in a group the sender's
            // name is drawn there too - so the circle was laid straight over the name and covered
            // all but its first letters. The container behind a video note is transparent, so the
            // name has the wallpaper to sit on; the circle starts below it, which is where the
            // name belongs above a round video anyway.
            if let name = senderNameLabel {
                note.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 4).isActive = true
            } else {
                note.topAnchor.constraint(equalTo: containerMessage.topAnchor).isActive = true
            }
            NSLayoutConstraint.activate([
                note.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor),
                note.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor),
                note.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor)
            ])

            // Fix: this read the row's `progress`, which for a video note is never driven up to
            // 100 - so a note that had plainly been sent, ticked and all, sat at "0%" for good and
            // never began to play. The status is what actually says where the message has got to:
            // "1" is still on its way, anything past that has left.
            let status = dataMessages[indexPath.row]["status"] as? String ?? ""
            let mine = dataMessages[indexPath.row]["f_pin"] as? String == idMe
            let progress = dataMessages[indexPath.row]["progress"] as? Double ?? 0.0
            let state: VideoNoteBubbleView.State = (mine && (status == "1" || VideoNote.isSending(videoId: videoChat)))
                ? .sending(progress / 100.0)
                : .delivered
            // Wired before it is configured, not after. Configuring is what puts the stop
            // control on screen, and a control on screen can be pressed - a handler assigned a
            // line later is a handler that is nil for the one press that matters.
            let noteMessageId = dataMessages[indexPath.row][TypeDataMessage.message_id] as? String ?? ""
            note.onCancelSend = { [weak self] in
                self?.markSendCancelled(messageId: noteMessageId)
            }
            note.configure(videoId: videoChat, thumbId: thumbChat, state: state)

            // A note that never left says so: a red mark beside the bubble, and a tap on it offers
            // the only two things left to do with it.
            if mine, status == "0" {
                let badge = MessageNotSentBadge()
                cellMessage.contentView.addSubview(badge)
                NSLayoutConstraint.activate([
                    badge.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8),
                    badge.centerYAnchor.constraint(equalTo: containerMessage.centerYAnchor)
                ])
                let messageId = dataMessages[indexPath.row]["message_id"] as? String ?? ""
                let failedRow = dataMessages[indexPath.row]
                badge.addAction(UIAction { [weak self] _ in
                    guard let self = self else { return }
                    // The app's own sheet, with icons - rather than a second sheet class that
                    // would be a second look to keep in step.
                    let sheet = BottomChoiceSheet(
                        question: "Your message was not sent.".localized(),
                        options: [
                            BottomChoiceSheet.Option(title: "Send again".localized(),
                                                     icon: "arrow.clockwise") { [weak self] in
                                self?.sendAgain(messageId: messageId)
                            },
                            BottomChoiceSheet.Option(title: "Delete".localized(),
                                                     icon: "trash",
                                                     isDestructive: true) { [weak self] in
                                // The app already asks this question properly, and for a message
                                // that never left it offers the only answer there is: delete it
                                // here. "For everyone" is filtered out for a failed message
                                // already, because there is no everyone to delete it from.
                                self?.presentDeleteOptions(for: [failedRow])
                            }
                        ])
                    self.present(sheet, animated: true)
                }, for: .touchUpInside)
            }
            // Opening a note changes how tall its row is, and the table owns that.
            note.onToggleSize = { [weak self] _ in
                guard let self = self else { return }
                self.tableChatView.beginUpdates()
                self.tableChatView.endUpdates()
            }
            // Opening one changes how tall its row is, and the table owns that.
            return cellMessage
        }
        if (!thumbChat.isEmpty && dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
            if let listImages = groupImages[messageIdChat] {
                timeMessage.isHidden = true
                statusMessage.isHidden = true
                imageStared.isHidden = true
                topMarginText.constant = topMarginText.constant + 220
                // Fix: 35 is 5 plus the 30 the sender's name takes; an own bubble shows no name,
                // so it sits at the same 5 a personal chat uses.
                var constTop = isOwnMessage ? 5.0 : 35.0
                if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as? Int ?? 0 != 0 {
                    topMarginText.constant = topMarginText.constant + 20
                    // Same 30 for the name, still only on a bubble that shows one.
                    constTop = isOwnMessage ? 35.0 : 55.0
                }
                // WhatsApp's arrangement, and the reason it changes with the count: two
                // images are two tall halves side by side, three are one tall half beside two
                // stacked quarters, four or more are a square of quarters. The whole collage
                // occupies the same box either way, so nothing else about the bubble moves.
                let tileCount = min(listImages.count, 4)
                let listImageThumb: [UIImageView] = (0..<tileCount).map { _ in UIImageView() }
                for i in 0..<tileCount {
                    containerMessage.addSubview(listImageThumb[i])
                    // Which picture of the run this tile is, so a quote of one of them can be
                    // pointed at after the jump lands on the collage they share.
                    listImageThumb[i].accessibilityIdentifier = "\(EditorGroup.collageTileName)\(i)"
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
                        // Fix: the square of quarters was pinned from both ends and joined in the
                        // middle by nothing. The top row hung from the top of the bubble, the
                        // bottom row from its bottom, and no constraint said the two rows were five
                        // points apart - so the gap between them was whatever height the bubble
                        // happened to have left over, and the tiles were squeezed or stretched to
                        // absorb it, differently on each side. The right edge was pinned twice as
                        // well, once by the top-right tile and again by the bottom-right, which is
                        // a second answer to a question already answered.
                        //
                        // Now the grid is one chain: the second row hangs off the first, each tile
                        // is the same square, and the bubble takes its width from the top-right
                        // tile and its height from the bottom-left. Every edge is settled once.
                        case (_, 0):
                            listImageThumb[i].anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, paddingTop: constTop, paddingLeft: 5, width: widthHeightImage, height: widthHeightImage)
                        case (_, 1):
                            listImageThumb[i].anchor(top: listImageThumb[0].topAnchor, left: listImageThumb[0].rightAnchor, right: containerMessage.rightAnchor, paddingLeft: 5, paddingRight: 5, width: widthHeightImage, height: widthHeightImage)
                        case (_, 2):
                            listImageThumb[i].anchor(top: listImageThumb[0].bottomAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, width: widthHeightImage, height: widthHeightImage)
                        default:
                            listImageThumb[i].anchor(top: listImageThumb[1].bottomAnchor, left: listImageThumb[2].rightAnchor, paddingTop: 5, paddingLeft: 5, width: widthHeightImage, height: widthHeightImage)
                    }
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(listImages[i].thumbId)
                        // The same treatment the single picture gets: a thumbnail already in hand goes
                        // up at once, and anything that has to be read, decrypted and decoded is
                        // done away from the main thread. A collage is four of these at a time, so
                        // it is four times the reason not to do that work while drawing a cell.
                        let tileId = listImages[i].thumbId
                        let tile = listImageThumb[i]
                        // Each tile of a collage is a message of its own, so each answers for
                        // itself: softened while its own picture is not here, sharp once it is -
                        // the same rule, and the same look, as a picture on its own.
                        let tileImageId = listImages[i].imageId
                        let tileFull = URL(fileURLWithPath: dirPath).appendingPathComponent(tileImageId)
                        let softenTile = !tileImageId.isEmpty
                            && !FileManager.default.fileExists(atPath: tileFull.path)
                            && !FileEncryption.shared.isSecureExists(filename: tileImageId)
                        let drawTile: (UIImage) -> UIImage = { image in
                            // Twice the radius, for the same softness. The blur is baked into the
                            // picture at a fixed working size, so how soft it *looks* depends on
                            // how far that picture is then stretched: a full bubble is around two
                            // hundred and fifty points wide, a collage tile a hundred and twenty.
                            // The same radius on a tile is stretched half as far and reads as half
                            // as blurred, which is exactly the difference you can see between them.
                            softenTile ? image.softened(radius: 14, key: tileId) : image
                        }
                        if let ready = Nexilis.imageCache.object(forKey: tileId as NSString) {
                            tile.image = drawTile(ready)
                        } else if !tileId.isEmpty,
                                  FileManager.default.fileExists(atPath: thumbURL.path)
                                    || FileEncryption.shared.isSecureExists(filename: tileId) {
                            let tilePath = thumbURL.path
                            if !EditorGroup.thumbnailsBeingRead.contains(tileId) {
                                EditorGroup.thumbnailsBeingRead.insert(tileId)
                                EditorGroup.thumbnailQueue.async { [weak tile, weak self] in
                                    var bytes: Data?
                                    if FileManager.default.fileExists(atPath: tilePath) {
                                        bytes = try? Data(contentsOf: URL(fileURLWithPath: tilePath))
                                    } else if var stored = try? FileEncryption.shared.readSecure(filename: tileId, withoutBiometric: true) {
                                        if let plain = FileEncryption.shared.decryptFileFromServer(data: stored) {
                                            stored = plain
                                        }
                                        bytes = stored
                                    }
                                    var made: UIImage?
                                    if let bytes = bytes, let picture = UIImage.thumbnail(from: bytes) {
                                        Nexilis.imageCache.setObject(picture, forKey: tileId as NSString)
                                        made = drawTile(picture)
                                    }
                                    let finishedTile = made
                                    DispatchQueue.main.async {
                                        EditorGroup.thumbnailsBeingRead.remove(tileId)
                                        guard let finishedTile = finishedTile else { return }
                                        // On screen, not merely alive - see the single picture.
                                        if let showing = tile, showing.window != nil {
                                            showing.image = finishedTile
                                        } else {
                                            self?.reloadMessageRow(withFileNamed: tileId)
                                        }
                                    }
                                }
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
                        
                        // Fix: a full-strength light blur *view* was laid over every tile whose
                        // picture was not here yet - and a blur view is a veil, translucent white,
                        // which drains whatever colour is under it. Over a small tile it left an
                        // almost empty white square, which is the "blank collage": the thumbnail
                        // was there and loading correctly all along, painted out by this. The same
                        // veil was taken off the single picture several changes ago and replaced by
                        // softening the picture itself; the tile does that too, in drawTile above,
                        // and this had simply been left behind.
                        if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
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
                // What the reference puts over the middle of a grid that has not been fetched:
                // one offer for the lot of them. A collage stands for several messages, so there
                // is no single corner to put a size in and no single picture to offer - and when
                // the thumbnails have not arrived either, this is the only thing on the bubble
                // that says what it is.
                let collageDocuments = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                var missingNames: [String] = []
                for member in listImages {
                    let name = member.imageId
                    guard !name.isEmpty else { continue }
                    let alreadyHere = FileManager.default.fileExists(atPath: collageDocuments.appendingPathComponent(name).path)
                        || FileEncryption.shared.isSecureExists(filename: name)
                    guard !alreadyHere else { continue }
                    missingNames.append(name)
                }
                // Going out, not coming in. A collage is sent as one thing, so it reports as one:
                // a single stop over the middle of the grid, its arc measuring all of the pictures
                // between them, and a red mark beside the bubble if they never left.
                let collageIsMine = dataMessages[indexPath.row]["f_pin"] as? String == idMe
                let collageSending = listImages.filter { $0.status == "1" && !$0.imageId.isEmpty }
                let collageFailed = listImages.filter { $0.status == "0" && !$0.imageId.isEmpty }
                if collageIsMine, !collageSending.isEmpty {
                    let stop = TransferStopControl()
                    containerMessage.addSubview(stop)
                    NSLayoutConstraint.activate([
                        stop.centerXAnchor.constraint(equalTo: containerMessage.centerXAnchor),
                        stop.centerYAnchor.constraint(equalTo: containerMessage.centerYAnchor)
                    ])
                    let goingOut = collageSending
                    stop.onStop = { [weak self] in
                        self?.markCollageSendCancelled(goingOut)
                    }
                    let sent = goingOut.reduce(0.0) { running, member in
                        guard let moved = TransferBytes.get(name: member.imageId), moved.total > 0 else {
                            return running
                        }
                        return running + Double(moved.completed) / Double(moved.total) * 100
                    }
                    stop.begin(all: goingOut.map { $0.imageId },
                               progress: sent / Double(goingOut.count))
                }
                if collageIsMine, !collageFailed.isEmpty, collageSending.isEmpty {
                    let badge = MessageNotSentBadge()
                    cellMessage.contentView.addSubview(badge)
                    NSLayoutConstraint.activate([
                        badge.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8),
                        badge.centerYAnchor.constraint(equalTo: containerMessage.centerYAnchor)
                    ])
                    let neverLeft = collageFailed
                    badge.addAction(UIAction { [weak self] _ in
                        guard let self = self else { return }
                        let sheet = BottomChoiceSheet(
                            question: "Your message was not sent.".localized(),
                            options: [
                                BottomChoiceSheet.Option(title: "Send again".localized(),
                                                         icon: "arrow.clockwise") { [weak self] in
                                    self?.sendCollageAgain(neverLeft)
                                },
                                BottomChoiceSheet.Option(title: "Delete".localized(),
                                                         icon: "trash",
                                                         isDestructive: true) { [weak self] in
                                    self?.presentDeleteOptions(for: neverLeft.map { $0.dataMessage })
                                }
                            ])
                        self.present(sheet, animated: true)
                    }, for: .touchUpInside)
                }
                if !missingNames.isEmpty, !collageIsMine {
                    let fetching = missingNames.filter { Download.isDownloading(forKey: $0) }
                    if fetching.isEmpty {
                        // The offer. A tap on it - or on any picture still behind its blur - asks
                        // for the lot of them.
                        let offerPill = VideoBubbleChrome.addCollageOffer(to: containerMessage,
                                                                          files: missingNames)
                        offerPill.isUserInteractionEnabled = true
                        let askFor = missingNames
                        let pillTap = ObjectGesture(target: self, action: #selector(collageOfferTapped(_:)))
                        pillTap.collageFiles = askFor
                        offerPill.addGestureRecognizer(pillTap)
                    } else {
                        // On their way: one stop with one arc, standing for all of them together.
                        // When the last lands the row is drawn again, and by then there is nothing
                        // missing - no blur, no stop, no ring.
                        let stop = TransferStopControl()
                        containerMessage.addSubview(stop)
                        NSLayoutConstraint.activate([
                            stop.centerXAnchor.constraint(equalTo: containerMessage.centerXAnchor),
                            stop.centerYAnchor.constraint(equalTo: containerMessage.centerYAnchor)
                        ])
                        let running = missingNames
                        stop.onStop = { [weak self] in
                            for name in running {
                                Download.cancel(forKey: name)
                            }
                            self?.reloadMessageRow(withFileNamed: running.first ?? "")
                        }
                        let sum = running.reduce(0.0) { $0 + (Download.progress(forKey: $1) ?? 0) }
                        stop.beginDownload(all: running, progress: sum / Double(running.count))
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
                    // Fix: 37 leaves room for the sender's name, which an own bubble does not
                    // show. Personal chats use 15 here and so does an own bubble now.
                    imageThumb.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: isOwnMessage ? 15 : 37).isActive = true
                } else {
                    // Fix: with a quote (or a "Forwarded" line) above it, the picture is given no
                    // top edge of its own - it hangs between whatever is above and the text below.
                    // Nothing said how tall it should be, and the quote box above it had no ceiling
                    // either, so the room meant for the picture was free for the layout to hand to
                    // the quote instead: a reply carrying a video drew a tall empty quote with a
                    // squeezed still under it, the camcorder mark stranded away from the picture.
                    // The picture keeps the size it was measured at; the quote takes what its own
                    // two lines need and no more.
                    let imgHeightConstraint = imageThumb.heightAnchor.constraint(equalToConstant: max(getHeightImage, 40))
                    imgHeightConstraint.priority = UILayoutPriority(751)
                    imgHeightConstraint.isActive = true
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
                    // While the picture itself is not here, the thumbnail standing in for it is
                    // softened - the same state the blur view used to mark, decided in one place
                    // and applied to the picture rather than laid over it.
                    let fullPicture = URL(fileURLWithPath: dirPath).appendingPathComponent(imageChat)
                    let softenThumb = !imageChat.isEmpty
                        && !FileManager.default.fileExists(atPath: fullPicture.path)
                        && !FileEncryption.shared.isSecureExists(filename: imageChat)
                    // Fix: the thumbnail was decrypted on the main thread, then decoded, resized
                    // and softened on it as well - inside a block deferred to the next turn of the
                    // run loop, so the first frame of the row never had a picture in it at all. On
                    // a warm screen nothing was cheap enough to notice; on a cold start, with every
                    // cache empty, that work does not fit between the frames of the push animation
                    // and the bubble sits there grey until it finishes. A picture already in hand
                    // goes up at once, and everything else is done away from the main thread with
                    // only the finished image coming back to it.
                    let drawThumb: (UIImage) -> UIImage = { image in
                        softenThumb ? image.softened(key: thumbChat) : image
                    }
                    if let ready = Nexilis.imageCache.object(forKey: thumbChat as NSString) {
                        imageThumb.image = drawThumb(ready)
                    } else if !thumbChat.isEmpty,
                              FileManager.default.fileExists(atPath: thumbURL.path)
                                || FileEncryption.shared.isSecureExists(filename: thumbChat) {
                        // The picture is here, it has simply not been read yet. The same spinner
                        // the missing case uses stands in for it meanwhile: reading, decrypting and
                        // decoding cannot be done while the cell is being built, and an empty
                        // square says nothing is happening when something is.
                        let preparing = UIActivityIndicatorView(style: .medium)
                        preparing.color = .white
                        imageThumb.addSubview(preparing)
                        preparing.translatesAutoresizingMaskIntoConstraints = false
                        preparing.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor).isActive = true
                        preparing.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor).isActive = true
                        preparing.startAnimating()
                        let thumbPath = thumbURL.path
                        if !EditorGroup.thumbnailsBeingRead.contains(thumbChat) {
                            EditorGroup.thumbnailsBeingRead.insert(thumbChat)
                            EditorGroup.thumbnailQueue.async { [weak imageThumb, weak preparing, weak self] in
                                var bytes: Data?
                                if FileManager.default.fileExists(atPath: thumbPath) {
                                    bytes = try? Data(contentsOf: URL(fileURLWithPath: thumbPath))
                                } else if var stored = try? FileEncryption.shared.readSecure(filename: thumbChat, withoutBiometric: true) {
                                    if let plain = FileEncryption.shared.decryptFileFromServer(data: stored) {
                                        stored = plain
                                    }
                                    bytes = stored
                                }
                                var drawn: UIImage?
                                if let bytes = bytes, let picture = UIImage.thumbnail(from: bytes) {
                                    Nexilis.imageCache.setObject(picture, forKey: thumbChat as NSString)
                                    drawn = drawThumb(picture)
                                }
                                let finished = drawn
                                DispatchQueue.main.async {
                                    EditorGroup.thumbnailsBeingRead.remove(thumbChat)
                                    preparing?.removeFromSuperview()
                                    guard let finished = finished else { return }
                                    // Fix: this asked whether the view still existed, and a view
                                    // taken out of a rebuilt cell goes on existing for a while yet -
                                    // so the picture was handed to something nobody could see, and
                                    // no redraw was asked for. The bubble in front of the reader
                                    // meanwhile refused to start its own read, because this one was
                                    // already running, and simply waited: "busy", for ever, until
                                    // some unrelated redraw happened along. What matters is not
                                    // whether the view is alive but whether it is on screen.
                                    if let showing = imageThumb, showing.window != nil {
                                        showing.image = finished
                                    } else {
                                        // The picture is in the cache now; the row only has to be
                                        // drawn again to pick it up, and it will find it waiting.
                                        self?.reloadMessageRow(withFileNamed: thumbChat)
                                    }
                                }
                            }
                        }
                        // Another bubble may already be reading this very file: nothing to start,
                        // and the spinner stays until it lands and the row is drawn again.
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
                        // Fix: what stood here was a blur view laid over the thumbnail. A blur
                        // view is a veil - translucent white or grey - and it drains the colour
                        // out of whatever is under it, so the bubble read as a pale rectangle
                        // rather than a photograph waiting to be fetched, however thin the
                        // material was made. The picture itself is softened where it is loaded
                        // instead: every colour it had, only the detail gone.
                        // Fix: while the image is actually downloading the progress ring stands in for
                        // this button - they are both centred on the thumbnail and would overlap.
                        // Fix: the arrow used to show whenever the full picture was not here,
                        // even while the thumbnail it stands on had not arrived either - an
                        // invitation to tap a blank square, next to a spinner saying the opposite.
                        // Nothing can be asked for before there is a picture to ask about.
                        // Fix: an empty thumb id makes `thumbURL` the documents folder itself, and
                        // a folder exists - so every one of these checks answered "the thumbnail is
                        // already here" for a message that has no thumbnail at all. Nothing was
                        // ever fetched, nothing could ever be decoded, and the bubble stayed an
                        // empty rectangle with an offer to download the picture drawn over it, for
                        // good. The name has to be a name before any of this means anything.
                        let hasThumb = !thumbChat.isEmpty
                            && (FileManager.default.fileExists(atPath: thumbURL.path)
                                || FileEncryption.shared.isSecureExists(filename: thumbChat))
                        if hasThumb, !imageChat.isEmpty, !Download.isDownloading(forKey: imageChat) {
                            // The same disc the stop wears, showing its other face. Accepting the
                            // offer changes the mark inside it and nothing else - the ring does not
                            // arrive somewhere else, at some other size. It takes no touches of its
                            // own: the thumbnail already carries the tap that starts a download.
                            // (The blur was added a second time here, over itself.)
                            let offer = TransferStopControl()
                            offer.showOffer()
                            imageThumb.addSubview(offer)
                            NSLayoutConstraint.activate([
                                offer.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor),
                                offer.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor)
                            ])
                            // ...and how big it would be, in the corner. It belongs to the offer,
                            // so it is drawn only where the offer is: a transfer that has started
                            // has the disc in the middle to speak for it, and the row is built
                            // again either way - when the fetch begins, and when it is called off.
                            VideoBubbleChrome.addPendingSize(to: imageThumb, fileName: imageChat)
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
                // What is actually going up. A gif is not uploaded at all - its id names something
                // the server already holds - so a gif on its way out has no transfer to draw and
                // nothing a stop could stop; the control would simply turn for ever.
                let uploadingChat = !videoChat.isEmpty ? videoChat : imageChat
                if (sendingNow && !uploadingChat.isEmpty && dataMessages[indexPath.row]["progress"] as? Double ?? 0.0 != 100.0 && dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                    // Fix: what stood here was a thirty-point disc with an up arrow in it, drawn
                    // from a path whose centre was (10, 20) inside a thirty-point box - five points
                    // off the middle in both directions - and whose progress layer was never given
                    // a name, so nothing ever found it and its arc sat at zero for the whole
                    // transfer. There was also no way to stop a send once it had begun. This is the
                    // control the video note wears: in the middle of the picture, as the reference
                    // has it, and large enough to be pressed.
                    let stop = TransferStopControl()
                    // On the bubble rather than on the thumbnail. The thumbnail carries the tap
                    // that opens the picture, and a button inside it would have both fire at once -
                    // a stop that also opened what it was stopping.
                    containerMessage.addSubview(stop)
                    NSLayoutConstraint.activate([
                        stop.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor),
                        stop.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor)
                    ])
                    // The same caption as the download ring - how much of the file has gone up so
                    // far, out of how much there is (TransferBytes, filled in by Network) - and
                    // under the control, where the download ring already puts it.
                    let uploadChip = ChatTransferRing.addSizeLabel(to: imageThumb, fileName: uploadingChat)
                    NSLayoutConstraint.activate([
                        uploadChip.topAnchor.constraint(equalTo: stop.bottomAnchor, constant: 6),
                        uploadChip.centerXAnchor.constraint(equalTo: stop.centerXAnchor)
                    ])
                    let uploadingMessageId = dataMessages[indexPath.row][TypeDataMessage.message_id] as? String ?? ""
                    stop.onStop = { [weak self] in
                        _ = Network.cancelUpload(name: uploadingChat)
                        self?.markSendCancelled(messageId: uploadingMessageId)
                    }
                    stop.onFinished = { [weak uploadChip] in
                        uploadChip?.isHidden = true
                    }
                    // Picked up where the transfer already is, not started from nothing: this row
                    // is built again every time the message moves on, and a ring that goes back to
                    // the beginning at each rebuild says less than no ring at all.
                    let sent = TransferBytes.get(name: uploadingChat)
                    let alreadySent = (sent?.total ?? 0) > 0
                        ? Double(sent!.completed) / Double(sent!.total) * 100
                        : 0
                    stop.begin(transferNamed: uploadingChat, progress: alreadySent)
                }
                
                // A picture that never left says so the same way a note does: a red mark beside
                // the bubble, and a tap on it offering the only two things there are left to do.
                // The tick beside the time already says "not sent", but it says it in the corner
                // of a bubble, and Send again was reachable only by holding the picture down.
                if dataMessages[indexPath.row]["f_pin"] as? String == idMe,
                   (dataMessages[indexPath.row]["status"] as? String ?? "") == "0" {
                    let badge = MessageNotSentBadge()
                    cellMessage.contentView.addSubview(badge)
                    NSLayoutConstraint.activate([
                        badge.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8),
                        badge.centerYAnchor.constraint(equalTo: containerMessage.centerYAnchor)
                    ])
                    let failedMessageId = dataMessages[indexPath.row]["message_id"] as? String ?? ""
                    let failedRow = dataMessages[indexPath.row]
                    badge.addAction(UIAction { [weak self] _ in
                        guard let self = self else { return }
                        let sheet = BottomChoiceSheet(
                            question: "Your message was not sent.".localized(),
                            options: [
                                BottomChoiceSheet.Option(title: "Send again".localized(),
                                                         icon: "arrow.clockwise") { [weak self] in
                                    self?.sendAgain(messageId: failedMessageId)
                                },
                                BottomChoiceSheet.Option(title: "Delete".localized(),
                                                         icon: "trash",
                                                         isDestructive: true) { [weak self] in
                                    self?.presentDeleteOptions(for: [failedRow])
                                }
                            ])
                        self.present(sheet, animated: true)
                    }, for: .touchUpInside)
                }

                // Fix: the download ring is drawn from here now, not built by hand in
                // contentMessageTapped - so it survives the cell being recycled, and shows up
                // by itself on a transfer that was already running when this screen opened.
                let downloadingChat = !videoChat.isEmpty ? videoChat : imageChat
                if !downloadingChat.isEmpty, Download.isDownloading(forKey: downloadingChat) {
                    // The offer's disc, now wearing the stop and its turning arc - and it can be
                    // pressed to call the fetch off. On the bubble rather than on the thumbnail:
                    // the thumbnail carries the tap that opens the picture, and a button inside it
                    // would have both fire at once.
                    let stop = TransferStopControl()
                    containerMessage.addSubview(stop)
                    NSLayoutConstraint.activate([
                        stop.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor),
                        stop.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor)
                    ])
                    stop.onStop = { [weak self] in
                        Download.cancel(forKey: downloadingChat)
                        // A cancel is reported as a failure, and the screen leaves failures alone
                        // rather than driving a ring backwards - so the row is asked for again here,
                        // which is what puts the offer back.
                        self?.reloadMessageRow(withFileNamed: downloadingChat)
                    }
                    stop.beginDownload(transferNamed: downloadingChat,
                                       progress: Download.progress(forKey: downloadingChat) ?? 0)
                } else if !videoChat.isEmpty, !sendingNow, isUnreachable(fileNamed: videoChat) {
                    // Here, and the file is not: tried, could not be had. An offer to fetch it
                    // rather than a ring that would never fill.
                    VideoBubbleChrome.addUnavailable(to: imageThumb, sizeText: ChatTransferRing.sizeText(forFileNamed: videoChat))
                }
                // What the corner says about a video depends on whether it is here. Once it is, the
                // useful fact is how long it runs; before it is, the useful fact is how big it
                // would be to fetch - the same offer a picture makes. And while it is on its way,
                // neither: the disc in the middle speaks for it, and nothing else should.
                let videoIsHere = !videoChat.isEmpty
                    && (FileManager.default.fileExists(atPath: FileManager.default
                            .urls(for: .documentDirectory, in: .userDomainMask)[0]
                            .appendingPathComponent(videoChat).path)
                        || FileEncryption.shared.isSecureExists(filename: videoChat))
                if !videoChat.isEmpty, !videoIsHere, !Download.isDownloading(forKey: videoChat) {
                    VideoBubbleChrome.addPendingSize(to: imageThumb, fileName: videoChat)
                }
                if !videoChat.isEmpty, videoIsHere {
                    let knownLength = videoLength(ofMessage: dataMessages[indexPath.row])
                    let lengthLabel = VideoBubbleChrome.addFooter(to: imageThumb, seconds: knownLength)
                    if knownLength == 0 {
                        // Nothing has opened this one yet, so the database has no length for it -
                        // which is every video arriving from the share sheet, among others. The
                        // file is here, so it is asked directly and the answer kept.
                        VideoDurationStore.read(fileNamed: videoChat, messageId: messageIdChat) { [weak self, weak lengthLabel] seconds in
                            guard let self = self, self.audioViewsAlive(messageIdChat) else {
                                return
                            }
                            self.videoLengths?[messageIdChat] = seconds
                            lengthLabel?.text = String(format: "%d:%02d", seconds / 60, seconds % 60)
                        }
                    }
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
            
            // Fix: the name was read straight off the front of message_text, and the type by
            // splitting that on a dot and indexing the last piece - which is a crash for a
            // document that arrived without a name, because splitting nothing gives nothing to
            // index. Both now go through one place that knows where else to look.
            let documentName = Utils.documentName(messageText: originalMessageText, file: fileChat)
            // What kind it is: what the name says, and where the name says nothing, what the file
            // itself says. See Utils.documentKind.
            let documentKind = Utils.documentKind(named: documentName, file: fileChat)
            let finalExtFile = Utils.documentType(of: documentKind)
            containerMessage.addSubview(containerViewFile)
            containerViewFile.translatesAutoresizingMaskIntoConstraints = false
            let data = queryMessageReply(message_id: reffChat)
            if (reffChat.isEmpty || data.count == 0) && (dataMessages[indexPath.row][TypeDataMessage.is_forwarded] == nil || dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as? Int ?? 0 == 0) {
                // Fix: 37 leaves room for the sender's name, which an own bubble does not show.
                containerViewFile.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: isOwnMessage ? 15 : 37).isActive = true
            } else {
                containerViewFile.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
            }
            containerViewFile.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            containerViewFile.bottomAnchor.constraint(equalTo:messageText.topAnchor, constant: -5).isActive = true
            containerViewFile.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
//            containerViewFile.heightAnchor.constraint(equalToConstant: 50).isActive = true
            // Fix: the card sat on a flat twenty per cent black, which on a light bubble is a
            // slab of grey and on a dark one is nearly invisible. It is the same kind of thing a
            // quote is - a panel tucked inside a bubble - so it sits on the same panel, and the
            // writing on it uses the same two weights. See BubblePanel.
            let onDarkBubble = self.traitCollection.userInterfaceStyle == .dark
            containerViewFile.backgroundColor = BubblePanel.ground(dark: onDarkBubble)
            containerViewFile.layer.cornerRadius = 5.0
            containerViewFile.clipsToBounds = true
            // Fix: the card took its width from the name label, so a document with a short name -
            // or none at all - left it barely wider than its own icon, a grey square with a
            // document glyph and a download arrow crammed into it. A floor under the width keeps
            // it a card whatever the name turns out to be, and it gives way on a narrow screen
            // rather than pushing the bubble past the edge.
            let fileCardWidth = containerViewFile.widthAnchor.constraint(greaterThanOrEqualToConstant: 190)
            fileCardWidth.priority = .defaultHigh
            fileCardWidth.isActive = true
            
            // Fix: every document wore the same grey page, whatever it was - a column of
            // attachments was a column of identical marks and only the file name told them
            // apart. Each kind now has its own colour with its extension written on the page.
            // See DocumentBadge.
            let imageFile = UIImageView(image: DocumentBadge.image(of: documentKind,
                                                                   size: CGSize(width: 26, height: 30)))
            imageFile.contentMode = .scaleAspectFit
            containerViewFile.addSubview(imageFile)
            imageFile.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageFile.leadingAnchor.constraint(equalTo: containerViewFile.leadingAnchor, constant: 5),
                imageFile.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor),
                imageFile.widthAnchor.constraint(equalToConstant: 30),
                imageFile.heightAnchor.constraint(equalToConstant: 30)
            ])

            let nameFile = UILabel()
            nameFile.numberOfLines = 2
            nameFile.lineBreakMode = .byTruncatingTail
            nameFile.setContentCompressionResistancePriority(.required, for: .vertical)
            // Fix: this asked the name not to resist being squeezed, which took away the one thing
            // that made the card wide - the label's own width was what pushed the strip, and the
            // bubble with it. Without it the card shrank to almost nothing and every name was
            // three characters and an ellipsis. The name asks for room again, and the cap below
            // decides how much it may ask for.
            let nameFileWidth = nameFile.widthAnchor.constraint(lessThanOrEqualToConstant: 200)
            nameFileWidth.priority = .defaultHigh
            nameFileWidth.isActive = true
            nameFile.font = UIFont.systemFont(ofSize: 12 + offset(), weight: .medium)
            nameFile.textColor = BubblePanel.text(dark: onDarkBubble)
            nameFile.text = documentName

            // How big it is and what it is, on the line the name's third used to have. The size is
            // the sender's own figure where they sent one and what landed here otherwise; the type
            // is the extension, which is all this line ever said about it.
            let fileFacts = UILabel()
            fileFacts.numberOfLines = 1
            fileFacts.font = .systemFont(ofSize: 11)
            fileFacts.textColor = BubblePanel.secondaryText(dark: onDarkBubble)
            fileFacts.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            var fileBytes = VideoNote.Facts.of(attachmentNamed: fileChat).bytes
            if fileBytes == 0 {
                fileBytes = VideoNote.Facts.measuredSize(ofAttachmentNamed: fileChat)
            }
            let fileType = finalExtFile
            fileFacts.text = fileBytes > 0
                ? "\(VideoNote.Facts.humanSize(fileBytes)) \u{2022} \(fileType)"
                : fileType
            if fileBytes == 0 {
                // Neither the sender nor a plain copy on disk could say. The one place left to
                // look is the secure store, and looking there means opening the whole file - so it
                // is done away from the main thread and the line fills itself in.
                VideoNote.Facts.measureSize(ofAttachmentNamed: fileChat) { [weak fileFacts] bytes in
                    fileFacts?.text = "\(VideoNote.Facts.humanSize(bytes)) \u{2022} \(fileType)"
                }
            }

            // Fix: the name used to carry its own vertical constraints, and every branch below had
            // to remember to give it a trailing edge - the one branch that forgot collapsed the
            // whole bubble into a sliver. A stack owns the arrangement, and there is one trailing
            // edge to settle rather than one per state.
            let fileText = UIStackView(arrangedSubviews: [nameFile, fileFacts])
            fileText.axis = .vertical
            fileText.spacing = 1
            fileText.alignment = .fill
            containerViewFile.addSubview(fileText)
            fileText.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                fileText.leadingAnchor.constraint(equalTo: imageFile.trailingAnchor, constant: 8),
                fileText.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor),
                // Fix, twice over. First the stack was held between "no higher than the top" and
                // "no lower than the bottom" - two constraints that only limit and never drive, so
                // nothing ever asked the strip to be taller and the second line was clipped away.
                // Then the strip was told to be as tall as the stack, which failed for a subtler
                // reason: a label only knows how many lines it needs once it knows how wide it is,
                // and its width is settled a layout pass after its height is first asked for. The
                // strip measured one line of a name that then drew two.
                //
                // So the card is given the height it is drawn at, worked out from the fonts rather
                // than guessed: two lines of name, the gap, one line of size and type, and the
                // margins. Nothing has to be measured, nothing settles a pass later, and it is the
                // fixed-height card the reference has - a short name simply leaves its second line
                // empty.
                containerViewFile.heightAnchor.constraint(
                    equalToConstant: ceil(nameFile.font.lineHeight) * 2 + 1 + ceil(fileFacts.font.lineHeight) + 12)
            ])

            let mineFile = dataMessages[indexPath.row]["f_pin"] as? String == idMe
            let sendingFile = (dataMessages[indexPath.row]["status"] as? String ?? "") == "1"
            let fetchingFile = !fileChat.isEmpty && Download.isDownloading(forKey: fileChat)
            let fileIsHere = !fileChat.isEmpty
                && (FileManager.default.fileExists(atPath: FileManager.default
                        .urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent(fileChat).path)
                    || FileEncryption.shared.isSecureExists(filename: fileChat))

            if mineFile, sendingFile, !fileChat.isEmpty {
                // Beside the name, in the same place a file coming in wears its arrow and its
                // stop. The document icon stays where it is: it says what the message is, and what
                // the transfer is doing is a different thing that belongs in a different place -
                // taking turns with the icon made the bubble read as two unrelated states.
                let stop = TransferStopControl(side: 30)
                // On the bubble rather than inside the strip. The strip carries the tap that opens
                // the file, and a button inside it would have both fire at once.
                containerMessage.addSubview(stop)
                NSLayoutConstraint.activate([
                    stop.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor),
                    stop.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5),
                    fileText.trailingAnchor.constraint(equalTo: stop.leadingAnchor, constant: -8)
                ])
                let uploadingMessageId = dataMessages[indexPath.row][TypeDataMessage.message_id] as? String ?? ""
                stop.onStop = { [weak self] in
                    Network.cancelUpload(name: fileChat)
                    self?.markSendCancelled(messageId: uploadingMessageId)
                }
                let sentSoFar = TransferBytes.get(name: fileChat)
                let alreadySent = (sentSoFar?.total ?? 0) > 0
                    ? Double(sentSoFar!.completed) / Double(sentSoFar!.total) * 100
                    : 0
                stop.begin(transferNamed: fileChat, progress: alreadySent)
            } else if fetchingFile {
                // Coming in and on its way: the same disc, in the same place and at the same size,
                // now wearing the stop and its turning arc. Accepting the offer changes what is
                // inside the circle and nothing else.
                let stop = TransferStopControl(side: 30)
                containerMessage.addSubview(stop)
                NSLayoutConstraint.activate([
                    stop.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor),
                    stop.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5),
                    fileText.trailingAnchor.constraint(equalTo: stop.leadingAnchor, constant: -8)
                ])
                stop.onStop = { [weak self] in
                    Download.cancel(forKey: fileChat)
                    // A cancel is reported as a failure, and the screen leaves failures alone
                    // rather than driving a ring backwards - so the row is asked for again here,
                    // which is what puts the arrow back.
                    self?.reloadMessageRow(withFileNamed: fileChat)
                }
                stop.beginDownload(transferNamed: fileChat,
                                   progress: Download.progress(forKey: fileChat) ?? 0)
            } else if !mineFile, !fileIsHere, !fileChat.isEmpty {
                // Not here yet: a disc with an arrow in it and nothing more. There is no progress
                // to draw before there is a transfer, and a ring that does not move reads as one
                // that is stuck - which is what the track and its arc used to say here, always.
                let offer = UIView()
                offer.backgroundColor = .blueBubbleColor
                offer.layer.cornerRadius = 15
                offer.isUserInteractionEnabled = false
                containerViewFile.addSubview(offer)
                offer.translatesAutoresizingMaskIntoConstraints = false
                let arrow = UIImageView(image: UIImage(systemName: "arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
                arrow.tintColor = .white
                arrow.contentMode = .scaleAspectFit
                offer.addSubview(arrow)
                arrow.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    offer.centerYAnchor.constraint(equalTo: containerViewFile.centerYAnchor),
                    offer.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5),
                    offer.widthAnchor.constraint(equalToConstant: 30),
                    offer.heightAnchor.constraint(equalToConstant: 30),
                    arrow.centerXAnchor.constraint(equalTo: offer.centerXAnchor),
                    arrow.centerYAnchor.constraint(equalTo: offer.centerYAnchor),
                    fileText.trailingAnchor.constraint(equalTo: offer.leadingAnchor, constant: -8)
                ])
            } else {
                fileText.trailingAnchor.constraint(equalTo: containerViewFile.trailingAnchor, constant: -5).isActive = true
            }

            // A file that never left says so the same way a picture does: a red mark beside the
            // bubble, and a tap on it offering the only two things there are left to do.
            if dataMessages[indexPath.row]["f_pin"] as? String == idMe,
               (dataMessages[indexPath.row]["status"] as? String ?? "") == "0" {
                let badge = MessageNotSentBadge()
                cellMessage.contentView.addSubview(badge)
                NSLayoutConstraint.activate([
                    badge.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8),
                    badge.centerYAnchor.constraint(equalTo: containerMessage.centerYAnchor)
                ])
                let failedFileMessageId = dataMessages[indexPath.row]["message_id"] as? String ?? ""
                let failedFileRow = dataMessages[indexPath.row]
                badge.addAction(UIAction { [weak self] _ in
                    guard let self = self else { return }
                    let sheet = BottomChoiceSheet(
                        question: "Your message was not sent.".localized(),
                        options: [
                            BottomChoiceSheet.Option(title: "Send again".localized(),
                                                     icon: "arrow.clockwise") { [weak self] in
                                self?.sendAgain(messageId: failedFileMessageId)
                            },
                            BottomChoiceSheet.Option(title: "Delete".localized(),
                                                     icon: "trash",
                                                     isDestructive: true) { [weak self] in
                                self?.presentDeleteOptions(for: [failedFileRow])
                            }
                        ])
                    self.present(sheet, animated: true)
                }, for: .touchUpInside)
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
            // The one place that says where a link is in a message, rather than a fourth copy
            // of the same walk over it.
            let text = LinkPreviewFetcher.firstLink(in: textChat)
            if !text.isEmpty {
                isLoadingShowLink = true
                // Fix: whatever the link was, the card under it was an eighty-point strip with a
                // small square picture at the left - and most of the time no picture at all, for
                // the two reasons written down beside LinkPreviewFacts. The card now follows the
                // page: the picture across the top at the shape the picture is, the title, what
                // the page says about itself, and the site on the last line; and a link to a
                // video says so, which kind of video it is and how long it runs. It measures
                // itself first, because the message text below it has to be placed under it.
                func showLink(_ facts: LinkPreviewFacts) {
                    let cardWidth = LinkPreviewCard.width(inViewOfWidth: self.view.frame.width)
                    let cardHeight = LinkPreviewCard.height(for: facts, width: cardWidth)
                    topMarginText.constant = topMarginText.constant + cardHeight + 5

                    containerMessage.addSubview(containerLinkMessage)
                    containerLinkMessage.translatesAutoresizingMaskIntoConstraints = false
                    containerLinkMessage.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                    if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" {
                        containerLinkMessage.bottomAnchor.constraint(equalTo: imageSticker.topAnchor, constant: -5).isActive = true
                    } else {
                        containerLinkMessage.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                    }
                    containerLinkMessage.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                    containerLinkMessage.heightAnchor.constraint(equalToConstant: cardHeight).isActive = true
                    // The card is what makes a bubble carrying a link as wide as it is: a bubble
                    // is otherwise only as wide as its text, and a picture in a narrow bubble is
                    // not worth showing. It gives way where there is not the room, the way a
                    // picture bubble does.
                    let cardIsWide = containerLinkMessage.widthAnchor.constraint(equalToConstant: cardWidth)
                    cardIsWide.priority = .defaultHigh
                    cardIsWide.isActive = true

                    let card = LinkPreviewCard()
                    containerLinkMessage.addSubview(card)
                    card.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        card.leadingAnchor.constraint(equalTo: containerLinkMessage.leadingAnchor),
                        card.trailingAnchor.constraint(equalTo: containerLinkMessage.trailingAnchor),
                        card.topAnchor.constraint(equalTo: containerLinkMessage.topAnchor),
                        card.bottomAnchor.constraint(equalTo: containerLinkMessage.bottomAnchor)
                    ])
                    card.show(facts, dark: self.traitCollection.userInterfaceStyle == .dark)

                    if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as? Int ?? 0 != 0 {
                        showForwardedSign()
                    }

                    if !copySession && !forwardSession && !deleteSession && !summarizeSession {
                        let objectTap = ObjectGesture(target: self, action: #selector(tapMessageText(_:)))
                        objectTap.message_id = text
                        containerLinkMessage.addGestureRecognizer(objectTap)
                    }
                }
                switch linkAnswer(for: text) {
                case .read(let facts):
                    showLink(facts)
                case .nothingOnIt:
                    // The page was read and had no title and no picture on it. WhatsApp draws
                    // nothing in that case, and so does this - and it is not asked for again.
                    break
                case .notAsked:
                    // Noted, not fetched: nothing goes out to the internet from inside a row.
                    // See noteLinkToRead.
                    noteLinkToRead(text, messageId: messageIdChat)
                }
            }
        }
        
        if (!reffChat.isEmpty) {
            let data = queryMessageReply(message_id: reffChat)
            if data.count != 0 {
                
                // Measured off a WhatsApp bubble: the bubble is #D6E8FC and the quote inside it is
                // #D3E1F2 - the bubble lifted toward grey, not darkened with black, which is a
                // light grey at 22%. Taken as an overlay it holds on any bubble colour, and the
                // text on it is the foreground held back rather than a colour of its own: that
                // #303237 quote is black at 77%.
                //
                // Dark mode turns the overlay over. WhatsApp's dark bubble is a deep green, so
                // lifting it still leaves somewhere dark to write on; ours is a bright blue
                // (#367dd9), and lifting that leaves white text at 2.2:1 - unreadable. Darkening
                // instead moves the quote away from the bubble the same way, and the text goes to
                // 87% for the same reason WhatsApp can afford 60% and we cannot.
                let isDarkQuote = self.traitCollection.userInterfaceStyle == .dark
                // The one place these two live, so the quote and the document card - which are the
                // same panel by design - cannot drift apart. See BubblePanel.
                let quoteOverlay = BubblePanel.ground(dark: isDarkQuote)
                let quotedTextColour = BubblePanel.text(dark: isDarkQuote)

                // Looks pressed under the finger, the way a link does - see PressableView.
                let containerReply = PressableView()
                containerMessage.addSubview(containerReply)
                containerReply.translatesAutoresizingMaskIntoConstraints = false
                containerReply.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                containerReply.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: isOwnMessage ? 15 : 32).isActive = true
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
                // Just under the margin that sets the bubble's height, so the two are never left
                // tied on the same priority with the layout free to pick either. What actually
                // keeps a quote from being squeezed is its own two labels, which refuse to be
                // compressed; this is only the look of an empty one.
                minHeightConstraint.priority = UILayoutPriority(749)
                minHeightConstraint.isActive = true
                containerReply.backgroundColor = quoteOverlay
                containerReply.layer.cornerRadius = 5
                containerReply.clipsToBounds = true
                
                if (thumbChat != "" || fileChat != "") && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                    // Fix: this replaced the constraint that holds the message text with a fresh
                    // one, and a fresh constraint is required - the original was deliberately
                    // defaultHigh so that it would give way when the quote needed more room. So
                    // the quote above a document was pinned to a fixed 50-odd points by a chain
                    // of required constraints, and a quote that wanted three lines could not
                    // have them: the layout resolved it by dropping the sender's name. The
                    // priority is carried over, and the chain quote-file-text drives the height.
                    topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: topMarginText.constant + 50 + (self.offset()*3))
                    topMarginText.priority = .defaultHigh
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
                } else {
                    if data["f_pin"] as? String != "-999" {
                        let dataProfile = getDataProfile(f_pin: data["f_pin"]  as? String ?? "", message_id: data["message_id"]  as? String ?? "")
                        titleReply.text = dataProfile["name"]
                    } else {
                        titleReply.text = "Bot"
                    }
                }
                // The name and the bar take the colour of whoever is being quoted, the way
                // WhatsApp gives everyone in a group one of their own. White only worked here
                // while the quote sat on a black overlay; on the bubble's own colour it went.
                let quoteGround = UIColor.composite(quoteOverlay, over: containerMessage.backgroundColor ?? .white)
                let quoteAccent = UIColor.participant(pin: data["f_pin"] as? String ?? "", conversation: self.conversationScope(), on: quoteGround)
                titleReply.textColor = quoteAccent
                leftReply.backgroundColor = quoteAccent
                
                let contentReply = UILabel()
                contentReply.numberOfLines = 3
                // The box has to be allowed to grow for the extra lines: the constraint holding the
                // message text below it sits at defaultHigh, the same as a label's default resistance
                // to being squeezed, and a tie there is settled either way.
                contentReply.setContentCompressionResistancePriority(.required, for: .vertical)
                titleReply.setContentCompressionResistancePriority(.required, for: .vertical)
                containerReply.addSubview(contentReply)
                contentReply.translatesAutoresizingMaskIntoConstraints = false
                contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
                contentReply.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor, constant: -10).isActive = true
                // Required, and a minimum rather than an equality. At defaultHigh this was the
                // cheapest constraint in the box to break, so a quote too tall for the space left
                // for it was resolved by dropping the text on top of the name instead of making
                // the box taller. Required, the box has to grow and the constraint holding the
                // message text below it - which is the one meant to give way - does.
                let topConstraintContent = contentReply.topAnchor.constraint(greaterThanOrEqualTo: titleReply.bottomAnchor)
                topConstraintContent.isActive = true
                // Fix: with the name held to the top of the box and the text to the bottom, and only a
                // minimum between them, nothing said how tall the box should actually be - it had a
                // floor and no ceiling. So the thumbnail's own picture size, even given the lowest say
                // there is, was still the only thing with an opinion, and it inflated the box until the
                // width cap stopped it: a hundred-point quote holding two lines of text, with the label
                // stranded at the bottom. This says the box hugs its two lines, and says it firmly
                // enough to beat a picture while still giving way to the minimum above it.
                let hugContent = contentReply.topAnchor.constraint(equalTo: titleReply.bottomAnchor)
                hugContent.priority = UILayoutPriority(500)
                hugContent.isActive = true
                contentReply.font = UIFont.systemFont(ofSize: 11 + offset())
                let message_text = ChatMessageText.withoutLinkPreview(data["message_text"] as? String ?? "")
                let attachment_flag = data["attachment_flag"] as? String  ?? ""
                let thumb_chat = data["thumb_id"] as? String ?? ""
                let image_chat = data["image_id"] as? String ?? ""
                let video_chat = data["video_id"] as? String ?? ""
                let file_chat = data["file_id"] as? String ?? ""
                let audio_chat = data["audio_id"] as? String ?? ""
                let gif_chat = data["gif_id"] as? String ?? ""
                // Fix: this chain began with "no flag and no thumbnail, so it is plain text", and that test
                // is looser than it reads - an attachment whose flag is 0 or blank was answered with its own
                // message text, which for a document is a filename and a caption joined by a bar, or nothing
                // at all. A reply to a document therefore drew a quote with nothing in it. What a message
                // carries is decided from its slots now, in one place shared by all six quotes - see
                // Utils.quotedAttachmentLine - and nil comes back only for a message that really is text,
                // which is rendered here because each of the six draws mentions its own way.
                // Held rather than activated and forgotten: a thumbnail claims the right-hand end of the
                // quote further down, and this has to come off before it does or the two fight over the
                // same edge.
                let contentTrailingToContainer = contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20)
                contentTrailingToContainer.isActive = true
                if let carried = Utils.quotedAttachmentLine(attachmentFlag: attachment_flag,
                                                            thumb: thumb_chat,
                                                            image: image_chat,
                                                            video: video_chat,
                                                            file: file_chat,
                                                            audio: audio_chat,
                                                            gif: gif_chat,
                                                            messageText: message_text,
                                                            font: contentReply.font,
                                                            colour: quotedTextColour) {
                    contentReply.attributedText = carried
                } else {
                    contentReply.attributedText = message_text.richText(fontSize: 11 + offset(), group_id: self.dataGroup["group_id"]  as? String ?? "")
                }
// WhatsApp writes the quote in the foreground colour held back a little, not in a
                // colour of its own: #303237 on that #D3E1F2 quote is black at 77%. Its dark
                // theme does the same the other way round, white at 60%.
                contentReply.textColor = quotedTextColour
                
                // The still fills the right-hand end of the quote, full height and flush to the edge, the
                // way the reference draws one. It is scaled to that box and cropped to it, so a picture
                // is never drawn at whatever size it happens to be.
                //
                // Fix: it was a 30-point square floating ten points in from the edge, vertically centred -
                // a stamp beside the text rather than part of the quote. The picture it was given was
                // only ever the thumbnail, so a message whose thumbnail never arrived showed nothing at
                // all - which is the quote that "sometimes has no picture"; the full image is the
                // fallback now. And only a quote of a picture or a video has a still to show at all: the
                // test that said so was lost when this block was first rewritten, so every quote grew
                // one, and a quote of a document or of plain text grew an empty one - the grey rectangle
                // on the right.
                let carriesStill = attachment_flag == "1" || attachment_flag == "2"
                    || !image_chat.isEmpty || !video_chat.isEmpty
                if carriesStill, !VideoNote.isNote(video_chat) {
                    let imageThumb = UIImageView()
                    VideoNote.loadQuotedStill(named: thumb_chat.isEmpty ? image_chat : thumb_chat, into: imageThumb)
                    containerReply.addSubview(imageThumb)
                    imageThumb.clipsToBounds = true
                    imageThumb.contentMode = .scaleAspectFill
                    imageThumb.translatesAutoresizingMaskIntoConstraints = false
                    // Fix: a picture in an image view carries its own size, and with the view pinned to the
                    // top and the bottom of the quote that size became the quote's height - a five-hundred
                    // point still made a four-hundred point quote, which is the tall grey box with the name
                    // at the top and the label stranded at the bottom. Its own size is given the lowest say
                    // there is, so the height comes from the two labels and the picture fills whatever that
                    // turns out to be.
                    imageThumb.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
                    imageThumb.setContentHuggingPriority(UILayoutPriority(1), for: .horizontal)
                    imageThumb.setContentCompressionResistancePriority(UILayoutPriority(1), for: .vertical)
                    imageThumb.setContentCompressionResistancePriority(UILayoutPriority(1), for: .horizontal)
                    // Flush to three edges, so the quote's own rounded corner is what shapes it - no radius
                    // of its own, and nothing to keep in step with the container's.
                    NSLayoutConstraint.activate([
                        imageThumb.topAnchor.constraint(equalTo: containerReply.topAnchor),
                        imageThumb.bottomAnchor.constraint(equalTo: containerReply.bottomAnchor),
                        imageThumb.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor),
                        // Square, so it fills the height it was given rather than stretching into a
                        // letterbox - the quote is only as tall as its two lines of text, and a picture
                        // three times wider than tall is not what the reference shows. Capped as a share
                        // of the width so it can never crowd the text out on a narrow bubble.
                        imageThumb.widthAnchor.constraint(equalTo: imageThumb.heightAnchor),
                        imageThumb.widthAnchor.constraint(lessThanOrEqualTo: containerReply.widthAnchor, multiplier: 0.45)
                    ])

                    // A gif travels in the video slot too, and a play badge on an animated
                    // picture is a promise it does not keep.
                    if (attachment_flag == "2" || !video_chat.isEmpty), gif_chat.isEmpty {
                        let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                        imageThumb.addSubview(imagePlay)
                        imagePlay.translatesAutoresizingMaskIntoConstraints = false
                        NSLayoutConstraint.activate([
                            imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor),
                            imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor),
                            imagePlay.widthAnchor.constraint(equalToConstant: 22),
                            imagePlay.heightAnchor.constraint(equalToConstant: 22)
                        ])
                        imagePlay.tintColor = .white
                    }
                    // The text gives the picture its room. The constraint that held it to the container's own
                    // edge is taken off first: two required constraints on one edge is a conflict, and the
                    // layout resolves those by breaking whichever it likes.
                    contentTrailingToContainer.isActive = false
                    titleReply.trailingAnchor.constraint(lessThanOrEqualTo: imageThumb.leadingAnchor, constant: -10).isActive = true
                    contentReply.trailingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: -10).isActive = true
                } else if carriesStill {
                    // A video note is round wherever it is shown, a quote included, so it stays a small
                    // still beside the text rather than filling the corner.
                    let imageThumb = UIImageView()
                    VideoNote.loadQuotedStill(named: thumb_chat, into: imageThumb)
                    containerReply.addSubview(imageThumb)
                    imageThumb.layer.cornerRadius = 15.0
                    imageThumb.clipsToBounds = true
                    imageThumb.contentMode = .scaleAspectFill
                    imageThumb.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        imageThumb.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -10),
                        imageThumb.centerYAnchor.constraint(equalTo: containerReply.centerYAnchor),
                        imageThumb.widthAnchor.constraint(equalToConstant: 30),
                        imageThumb.heightAnchor.constraint(equalToConstant: 30)
                    ])
                    contentTrailingToContainer.isActive = false
                    titleReply.trailingAnchor.constraint(lessThanOrEqualTo: imageThumb.leadingAnchor, constant: -10).isActive = true
                    contentReply.trailingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: -10).isActive = true
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
            containerForwarded.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: isOwnMessage ? 15 : 32).isActive = true
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
                if data.count != 0 && (topMarginText.constant == baseTopMarginText || topMarginText.constant == 100.0) {
                    addTopMargin = false
                }
            }
            if addTopMargin{
                topMarginText.isActive = true
            }
        }
        
        // Fix: an empty message text is not an empty view. `messageText` is a UITextView, and an
        // empty one still keeps a line's worth of height for a caret that will never appear - a
        // height that follows whatever font the branch above happened to give it. Every kind of
        // attachment therefore ended up with a different gap beneath it whenever nothing had been
        // written, which is the uneven padding. Nothing to show, no height, and one bottom margin
        // for all of them.
        if messageText.superview != nil,
           (messageText.attributedText?.string ?? messageText.text ?? "")
               .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messageText.heightAnchor.constraint(equalToConstant: 0).isActive = true
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
    
    func playPauseAudio(messageId: String, playButton: UIButton, progressSlider: UISlider, timeLabel: UILabel) {
        // Pressing the button is this screen saying the recording is its own now, so it takes it
        // off the strip before doing anything with it.
        guard let audioPlayer = adoptFromMiniPlayerIfNeeded(messageId) else { return }

        if audioPlayer.isPlaying {
            // Pause Audio
            audioPlayer.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            timers[messageId]?.invalidate()
            timers[messageId] = nil
            playingAudioId = nil
        } else {
            // One recording at a time. This used to reach only for what this screen thought it was
            // playing, which misses a recording still running on the strip from a conversation
            // that was left - starting a second one then left two of them talking over each other.
            // The service knows about every one of them and stops the rest.
            for stopped in AudioMiniPlayer.shared.pauseAllExcept(messageId) {
                timers[stopped]?.invalidate()
                timers[stopped] = nil
                if playingAudioId == stopped {
                    playingAudioId = nil
                }
                // Another note taking over ends the first one's turn, so its picture comes back.
                endAudioSession(stopped)
                // Fix: the row was reloaded by the index path this had been holding, which by then
                // may belong to another message or to no row at all. Looked up from the message.
                if let at = indexPath(forMessageId: stopped) {
                    tableChatView.reloadRowsKeepingPlace(at: [at])
                }
            }
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                
            }

            // Play new audio
            audioPlayer.enableRate = true
            audioPlayer.rate = audioRates[messageId] ?? 1
            audioPlayer.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            playingAudioId = messageId
            beginAudioSession(messageId)

            // Fix: half a second apart, the head jumped rather than travelled, and the line drawn
            // behind it never moved at all - the timer only knew about the slider. Also `[weak
            // self]`: a repeating timer holding the conversation keeps it alive after it is closed,
            // and keeps firing.
            startAudioTicker(messageId: messageId, progressSlider: progressSlider, timeLabel: timeLabel)
        }
    }

    /// Keeps a bubble's line, head and reading moving while its recording plays.
    ///
    /// Its own function because more than one thing starts a recording moving now: the play
    /// button, and a bubble coming back on screen with the recording already playing - taken back
    /// from the strip at the top, or simply scrolled away from and returned to.
    func startAudioTicker(messageId: String,
                          progressSlider: UISlider,
                          timeLabel: UILabel,
                          wave: AudioWaveformView? = nil) {
        timers[messageId]?.invalidate()
        timers[messageId] = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self, weak progressSlider, weak timeLabel, weak wave] _ in
            guard let self = self, let audioPlayer = self.livePlayer(for: messageId) else {
                return
            }
            // Where it has got to is kept as it goes, so leaving the conversation at any moment
            // leaves the bubble knowing where it was.
            AudioPositionStore.remember(audioPlayer.currentTime, for: messageId)
            // Fix: this wrote the thumb back into place ten times a second, including while
            // the reader was dragging it - so the finger and the timer pulled against each
            // other and the thumb stuttered. While it is being held, it is theirs.
            guard progressSlider?.isTracking != true else {
                return
            }
            // Fix: the bubble these belong to may have scrolled away and had its cell handed to
            // another message by now, in which case this was drawing one note's progress across
            // somebody else's bubble.
            guard self.audioViewsAlive(messageId) else {
                return
            }
            progressSlider?.value = Float(audioPlayer.currentTime)
            timeLabel?.text = self.formatTime(audioPlayer.currentTime)
            if audioPlayer.duration > 0 {
                // Fix: the thumb and the reading are held straight, as references; only the drawn
                // line was fetched from the dictionary each tick. Whenever the two disagreed about
                // which views belong to this bubble, the line was the one left behind - which is
                // why a note could finish with its thumb back at the start, its reading at 0:00,
                // and half its line still blue. Held the same way the other two are.
                let line = wave ?? self.audioWaves[messageId]
                line?.progress = CGFloat(audioPlayer.currentTime / audioPlayer.duration)
            }
        }
    }
    
    func sliderChanged(messageId: String, progressSlider: UISlider, timeLabel: UILabel) {
        guard let audioPlayer = adoptFromMiniPlayerIfNeeded(messageId) else { return }
        audioPlayer.currentTime = TimeInterval(progressSlider.value)
        timeLabel.text = formatTime(audioPlayer.currentTime)
        // The audio had already run out while this drag was going on, so the wait for the picture
        // to come back was held off until now.
        if audioAwaitingRest.remove(messageId) != nil {
            endAudioSession(messageId, after: 2.5)
        }
    }

    /// The views held for a message are only good while its bubble is on screen: the cell is handed
    /// to a different message the moment it scrolls away, and writing through a stale handle draws
    /// one note's progress onto another note's bubble. Anything reaching for them asks first.
    func audioViewsAlive(_ messageId: String) -> Bool {
        guard let at = indexPath(forMessageId: messageId) else {
            return false
        }
        return tableChatView.indexPathsForVisibleRows?.contains(at) == true
    }

    func audioRateLabel(_ rate: Float) -> String {
        return rate == rate.rounded() ? "\(Int(rate))\u{00D7}" : "\(rate)\u{00D7}"
    }

    /// While a note is being listened to, the sender's picture gives way to the speed button - the
    /// reference does the same, and it is the only place in the bubble with room for one.
    func beginAudioSession(_ messageId: String) {
        audioRestTimers[messageId]?.invalidate()
        audioRestTimers[messageId] = nil
        audioAwaitingRest.remove(messageId)
        audioSessions.insert(messageId)
        showAudioSpeed(true, for: messageId)
    }

    /// The picture comes back, after a pause when one is asked for: the reference leaves the speed
    /// button up for a moment once the audio has run out, in case they want to hear it again.
    func endAudioSession(_ messageId: String, after delay: TimeInterval = 0) {
        audioRestTimers[messageId]?.invalidate()
        audioRestTimers[messageId] = nil
        guard delay > 0 else {
            audioSessions.remove(messageId)
            showAudioSpeed(false, for: messageId)
            return
        }
        audioRestTimers[messageId] = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.audioRestTimers[messageId] = nil
            self.audioSessions.remove(messageId)
            self.showAudioSpeed(false, for: messageId)
        }
    }

    func showAudioSpeed(_ shown: Bool, for messageId: String) {
        guard audioViewsAlive(messageId),
              let pill = audioSpeedPills[messageId],
              let avatar = audioAvatars[messageId] else {
            return
        }
        pill.setTitle(audioRateLabel(audioRates[messageId] ?? 1), for: .normal)
        guard pill.isHidden == shown else {
            return
        }
        let appearing: UIView = shown ? pill : avatar
        let leaving: UIView = shown ? avatar : pill
        appearing.alpha = 0
        appearing.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            appearing.alpha = 1
            leaving.alpha = 0
        }, completion: { _ in
            leaving.isHidden = true
            leaving.alpha = 1
        })
    }

    /// The speeds the reference offers, in the order it offers them.
    func cycleAudioRate(messageId: String) {
        let next: Float
        switch audioRates[messageId] ?? 1 {
        case 1: next = 1.5
        case 1.5: next = 2
        default: next = 1
        }
        audioRates[messageId] = next
        audioPlayers[messageId]?.rate = next
        audioSpeedPills[messageId]?.setTitle(audioRateLabel(next), for: .normal)
    }

    /// Everything playing, stopped. Called when the conversation goes away, so no timer is left
    /// running and no player left holding the audio session.
    /// Gives a recording that is still playing to the strip at the top of the screen, so leaving
    /// the conversation carries on listening instead of cutting it off. Returns the message that
    /// was handed over; its player is the one that must not be stopped with the rest.
    @discardableResult
    func handOverPlayingAudio() -> String? {
        guard let id = playingAudioId,
              let player = audioPlayers[id],
              player.isPlaying else {
            return nil
        }
        let message = dataMessages.first { ($0["message_id"] as? String) == id }
        let isVoiceNote = (message?["attachment_flag"] as? String) == "60"
        let sender = (message?["f_pin"] as? String) ?? ""
        let name: String
        if sender == User.getMyPin() {
            name = "You".localized()
        } else {
            name = getDataProfile(f_pin: sender, message_id: id)["name"] ?? ""
        }
        // The picture the bubble itself is showing, so the strip carries on with the same face.
        let avatar = audioAvatars[id]?.subviews.compactMap { $0 as? UIImageView }.first?.image
        AudioMiniPlayer.shared.takeOver(player: player,
                                        messageId: id,
                                        name: name,
                                        avatar: isVoiceNote ? avatar : nil,
                                        isVoiceNote: isVoiceNote)
        return id
    }

    /// Takes back a recording that is still playing on the strip, now that this conversation is
    /// on screen.
    ///
    /// The bubble asks for it too as it is built, but that can be too early or too late: UIKit
    /// builds the screen being opened before it tears down the screen being left, and the bubble
    /// may not even be on screen yet when the conversation opens. Asked again here, where the
    /// answer has settled, so the row cannot be left showing a play button over a recording that
    /// is audibly running.
    func reclaimPlayingAudioIfMine() {
        guard let id = AudioMiniPlayer.shared.currentMessageId,
              let at = indexPath(forMessageId: id),
              adoptFromMiniPlayerIfNeeded(id) != nil else {
            return
        }
        tableChatView.reloadRowsKeepingPlace(at: [at])
    }

    /// The player behind a recording, wherever it currently lives.
    ///
    /// A recording that carried on playing after the conversation was left is held by the strip,
    /// not by this screen, and it may still be held there when a bubble is drawn: ownership moves
    /// back on its own schedule, and the row must not sit showing a play button in the meantime.
    /// Everything that draws or reads asks here, so what is on screen always follows the player
    /// that is actually running.
    func livePlayer(for messageId: String) -> AVAudioPlayer? {
        // One place keeps the players, so there is only ever one answer here.
        return AudioMiniPlayer.shared.player(for: messageId)
    }

    /// Takes ownership of a recording still held by the strip, so this screen drives it from now
    /// on. Does nothing when the recording is already this screen's.
    @discardableResult
    func adoptFromMiniPlayerIfNeeded(_ messageId: String) -> AVAudioPlayer? {
        guard let player = AudioMiniPlayer.shared.reclaim(messageId: messageId) else {
            return audioPlayers[messageId]
        }
        // Fix: this gave up the moment it found something already in audioPlayers, and what it
        // found was usually the idle stand-in built while the strip still had the recording. The
        // stand-in is thrown away; the one that is actually playing takes its place.
        if let standIn = audioPlayers[messageId], standIn !== player {
            standIn.stop()
        }
        player.delegate = self
        audioPlayers[messageId] = player
        playingAudioId = messageId
        beginAudioSession(messageId)
        return player
    }

    /// Slides the conversation up to the newest message.
    ///
    /// Not scrollToRow: with a long history the rows above are estimated heights, so the place it
    /// is aiming for is a guess that UIKit keeps correcting while the animation is already
    /// running - which is the bouncing. The bottom is measured from the content that has actually
    /// been laid out, and the offset is set once.
    func slideToNewestMessage(animated: Bool = true, over duration: TimeInterval = 0.25) {
        guard let table = tableChatView, table.numberOfSections > 0 else {
            return
        }
        let lowest = -table.adjustedContentInset.top
        let bottom = table.contentSize.height + table.adjustedContentInset.bottom - table.bounds.height
        let target = max(lowest, bottom)
        guard abs(table.contentOffset.y - target) > 0.5 else {
            return
        }
        let settle = { table.contentOffset = CGPoint(x: table.contentOffset.x, y: target) }
        guard animated else {
            settle()
            return
        }
        // The same ease the bubble grows to, and by default the same length of time - so when the
        // two are started together the conversation moves up exactly as the bubble fills out.
        UIView.animate(withDuration: duration, delay: 0,
                       options: [.curveEaseOut, .beginFromCurrentState],
                       animations: settle,
                       completion: { _ in
            // Fix: the offset alone was not enough to land on. contentSize is built from rows
            // measured only as they are needed, so the bottom it names is an estimate - the
            // animation stopped short of the real end and stayed there. scrollToRow knows where
            // the last row actually is; asked without animation, it closes the gap silently.
            let lastSection = table.numberOfSections - 1
            guard lastSection >= 0 else {
                return
            }
            let lastRow = table.numberOfRows(inSection: lastSection) - 1
            guard lastRow >= 0 else {
                return
            }
            table.safeScrollToRow(at: IndexPath(row: lastRow, section: lastSection), at: .bottom, animated: false)
        })
    }

    /// The tag the bubble carries so an arrival animation can find it again in a built cell.
    static let bubbleTag = 77_301

    /// Written down before the row goes in, so the bubble is small the first time it is drawn.
    ///
    /// Whether the conversation moves up to meet it is decided here too, while it still can be:
    /// a message of ours always takes the reader to it, and one that arrives only does so if the
    /// reader was already at the end. Once the row is in, the list is no longer at its bottom and
    /// the question can no longer be asked.
    func expectBubbleArrival(messageId: String, outgoing: Bool) {
        guard !messageId.isEmpty else {
            return
        }
        pendingBubbleArrival = (messageId, outgoing, nil, outgoing || isAtNewestMessage())
    }

    /// How far the list is about to travel to bring its newest message into view.
    func distanceToNewestMessage() -> CGFloat {
        guard let table = tableChatView, table.numberOfSections > 0 else {
            return 0
        }
        let lowest = -table.adjustedContentInset.top
        let bottom = table.contentSize.height + table.adjustedContentInset.bottom - table.bounds.height
        return max(0, max(lowest, bottom) - table.contentOffset.y)
    }

    /// Whether the reader is sitting at the end of the conversation.
    private func isAtNewestMessage() -> Bool {
        guard let table = tableChatView else {
            return false
        }
        let bottom = table.contentSize.height + table.adjustedContentInset.bottom - table.bounds.height
        return bottom - table.contentOffset.y <= 40
    }

    /// Nothing is arriving after all - a picture folded into a collage adds no row of its own.
    func cancelExpectedBubbleArrival() {
        pendingBubbleArrival = nil
    }

    /// Last chance, from the completion of the insert: the row is in place and nothing has played
    /// it. A short conversation does not scroll to make room for a new message, so willDisplay may
    /// have fired before the cell had been measured and found a bubble with no size to grow from.
    func retryPendingBubbleArrival(at indexPath: IndexPath) {
        guard pendingBubbleArrival?.startedAt == nil else {
            return
        }
        tableChatView.layoutIfNeeded()
        if let cell = tableChatView.cellForRow(at: indexPath) {
            playPendingBubbleArrivalIfNeeded(for: cell, at: indexPath)
        }
    }

    /// Plays whatever arrival this row owes - from the beginning, or from wherever a rebuild
    /// interrupted it.
    func playPendingBubbleArrivalIfNeeded(for cell: UITableViewCell, at indexPath: IndexPath) {
        guard let pending = pendingBubbleArrival,
              (message(at: indexPath)?["message_id"] as? String) == pending.messageId else {
            return
        }
        let started = pending.startedAt ?? Date()
        let elapsed = Date().timeIntervalSince(started)
        let remaining = Self.bubbleArrivalDuration - elapsed
        guard remaining > 0.02 else {
            pendingBubbleArrival = nil
            return
        }
        let progress = CGFloat(max(0, elapsed) / Self.bubbleArrivalDuration)
        guard playBubbleArrival(on: cell, outgoing: pending.outgoing,
                                from: progress, over: remaining,
                                of: pending.messageId,
                                pushingList: pending.pushesList && pending.startedAt == nil) else {
            return
        }
        pendingBubbleArrival = (pending.messageId, pending.outgoing, started, pending.pushesList)
    }

    /// The pop a new bubble arrives with: it grows out of the corner it belongs to.
    ///
    /// Over 0.18s the bubble goes from nothing to its full size, decelerating, with its top edge
    /// and the edge it belongs to held still the whole way - so it unfolds downwards out of the
    /// corner it came from rather than swelling in place. It does not fade: the first frame it can
    /// be seen at all, less than a point tall, is already solid. A message of ours grows out of
    /// its top-right corner, one that arrives out of its top-left.
    ///
    /// Fix: the corner used to be the bottom one, and the first message of a conversation grew
    /// from the top while every message after it grew from the bottom. Both come from the same
    /// arithmetic below - `dy` moved the bubble down by half of what the scaling took off its
    /// height, which holds the bottom edge still. It only actually held it when the height being
    /// measured was the real one, and for the first message in a conversation it is not: that row
    /// is still being laid out when this runs, so the height read here was short and the bubble
    /// ended up anchored nearer its top. The measurement is settled first now, and the corner is
    /// the top one on purpose, which is where the two happened to agree.
    ///
    /// Done with a transform rather than by moving the layer's anchor point: a transform sits on
    /// top of Auto Layout and undoes itself cleanly, where a moved anchor point is put back by
    /// the next layout pass and leaves the bubble somewhere it should not be.
    @discardableResult
    func playBubbleArrival(on cell: UITableViewCell, outgoing: Bool,
                           from progress: CGFloat, over duration: TimeInterval,
                           of messageId: String, pushingList: Bool) -> Bool {
        guard let bubble = cell.contentView.viewWithTag(Self.bubbleTag) else {
            return false
        }
        // The size this is all worked out from has to be the settled one. willDisplay can run
        // while the row is still being measured, and a height read too early is what made the
        // first message of a conversation grow from a different corner than the rest. Asked for
        // before the size is read, and before the guard below decides there is nothing to grow.
        UIView.performWithoutAnimation {
            bubble.transform = .identity
            cell.contentView.layoutIfNeeded()
        }
        guard bubble.bounds.width > 0, bubble.bounds.height > 0 else {
            return false
        }
        // Measured off the reference frame by frame: it starts from nothing, not from a bubble
        // that is merely small. `progress` is only ever above zero when a rebuild has interrupted
        // the growing and this is picking it back up.
        let smallest: CGFloat = 0.05
        let scale = smallest + (1 - smallest) * max(0, min(1, progress))
        let shrink = (1 - scale) / 2
        // Keeps the corner it grows from where it already is: scaling about the centre pulls that
        // corner inwards, so it is pushed back out by the same amount. Up rather than down, so it
        // is the top edge that stays put and the bubble unfolds downwards.
        let dx = bubble.bounds.width * shrink * (outgoing ? 1 : -1)
        let dy = -bubble.bounds.height * shrink
        let start = CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scale, y: scale)
        // The starting state is set outside any animation that happens to be running - this is
        // called from willDisplay, which the table is in the middle of animating an insertion in.
        UIView.performWithoutAnimation {
            bubble.transform = start
            bubble.alpha = 1
        }
        arrivingBubble = bubble
        arrivingCell = cell
        // Fix: with the conversation already at its end, the new row is added below what can be
        // seen and only the list moving up brings it in - so the bubble did all its growing off
        // the bottom of the screen and the reader saw nothing but a finished bubble sliding into
        // place. The reference does not let that happen: the new row sits where it will end up
        // from the very first frame, and it is everything above that travels.
        //
        // That is what the counter-travel below is. The row is held back by exactly as far as the
        // list is about to move, and released on the same curve, so the two cancel: on screen the
        // row does not move at all while the conversation slides up behind it, and the bubble
        // grows in full view for the whole of it.
        //
        // Both are asked for on the next turn of the run loop, together. This is called from
        // willDisplay, in the middle of the table laying itself out, and the scroll position is
        // not something to change from inside that; doing the two in the same turn also means the
        // row is never held back in a frame where the list has not yet moved.
        DispatchQueue.main.async { [weak self, weak cell, weak bubble] in
            guard let self = self, let cell = cell, let bubble = bubble else {
                return
            }
            let lift = pushingList ? self.distanceToNewestMessage() : 0
            let held = CGAffineTransform(translationX: 0, y: -lift)
            let travellers = cell.contentView.subviews.filter { $0 !== bubble }
            if lift > 0 {
                UIView.performWithoutAnimation {
                    bubble.transform = start.concatenating(held)
                    travellers.forEach { $0.transform = held }
                }
                self.slideToNewestMessage(over: duration)
            }
            UIView.animate(withDuration: duration, delay: 0,
                           options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
                           animations: {
                bubble.transform = .identity
                travellers.forEach { $0.transform = .identity }
            }, completion: { [weak self] finished in
                guard let self = self, finished else {
                    return
                }
                if self.arrivingBubble === bubble {
                    self.arrivingBubble = nil
                }
                if self.arrivingCell === cell {
                    self.arrivingCell = nil
                }
                if self.pendingBubbleArrival?.messageId == messageId {
                    self.pendingBubbleArrival = nil
                }
            })
        }
        return true
    }

    // MARK: - Long messages
    //
    // The rule itself lives in LongMessage, shared with starred messages and message info; these
    // are the handful of lines that put it into this screen's bubbles.

    static var collapsedLineLimit: Int { return LongMessage.lineLimit }

    /// Whether this message is being shown folded at the moment.
    func isFolded(_ messageId: String, text: String) -> Bool {
        return LongMessage.isFolded(messageId, text: text)
    }

    /// The "Read more" that closes a folded message.
    func readMoreSuffix() -> NSAttributedString {
        return LongMessage.suffix(fontSize: 12 + offset())
    }

    /// Folds a long message down, or leaves it whole once the reader has opened it.
    func foldIfLong(_ text: String, messageId: String) -> String {
        return LongMessage.visibleText(text, messageId: messageId)
    }

    @discardableResult
    private func applyReadMore(to view: UIView,
                               text: String,
                               messageId: String,
                               attributed: (String) -> NSMutableAttributedString) -> String {
        // The two conversations draw their message text with different views - a label in one, a
        // text view in the other - so the folding is told where to put its answer rather than
        // being written twice.
        func show(_ body: NSAttributedString) {
            if let label = view as? UILabel {
                label.numberOfLines = 0
                label.attributedText = body
            } else if let textView = view as? UITextView {
                textView.attributedText = body
            }
        }
        guard isFolded(messageId, text: text) else {
            show(attributed(text))
            return text
        }
        let shown = LongMessage.folded(text)
        let body = attributed(shown)
        body.append(readMoreSuffix())
        show(body)
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(ReadMoreTap(messageId: messageId, target: self, action: #selector(readMoreTapped(_:))))
        return shown
    }

    @objc private func readMoreTapped(_ sender: UITapGestureRecognizer) {
        guard let tap = sender as? ReadMoreTap else {
            return
        }
        LongMessage.expand(tap.messageId)
        // It is a different height now, so what was measured of it folded is no longer an answer.
        textBubbleHeights.removeValue(forKey: tap.messageId)
        guard let at = indexPath(forMessageId: tap.messageId) else {
            tableChatView.reloadData()
            return
        }
        tableChatView.reloadRowsKeepingPlace(at: [at])
    }

    func stopAllAudio() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
        audioRestTimers.values.forEach { $0.invalidate() }
        audioRestTimers.removeAll()
        // Where each recording was left is kept, so walking back into the conversation picks it
        // up there instead of starting it over. The one still playing is handed to the strip at
        // the top of the screen rather than stopped - see handOverPlayingAudio.
        for (id, player) in audioPlayers {
            AudioPositionStore.remember(player.currentTime, for: id)
        }
        handOverPlayingAudio()
        // Only this screen's references go. The players themselves belong to the service, and a
        // paused one is where the reader left it - stopping it would throw that away.
        audioPlayers.removeAll()
        audioWaves.removeAll()
        audioSliders.removeAll()
        audioPlayButtons.removeAll()
        audioTimeLabels.removeAll()
        audioSpeedPills.removeAll()
        audioAvatars.removeAll()
        audioSessions.removeAll()
        audioAwaitingRest.removeAll()
        playingAudioId = nil
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let roundedTime = time.rounded(.up)
        let minutes = Int(roundedTime) / 60
        let seconds = Int(roundedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let finished = audioPlayers.first(where: { $0.value === player })?.key else {
            return
        }
        DispatchQueue.main.async {
            self.timers[finished]?.invalidate()
            self.timers[finished] = nil
            self.playingAudioId = nil
            // Played to the end, so there is no part-way point to come back to: the next listen
            // starts at the beginning rather than at a line already full.
            AudioPositionStore.forget(finished)
            AudioMiniPlayer.shared.player(for: finished)?.currentTime = 0
            // Fix: this rebuilt the row. Audio reaching its end while the reader still had hold of
            // the slider therefore tore the control out from under their finger, and threw the
            // player away with it, so the drag died where it was. The bubble is put back to rest
            // in place instead, and the player is kept: letting go still seeks, and playing again
            // carries on from wherever they left it.
            let alive = self.audioViewsAlive(finished)
            if alive {
                self.audioPlayButtons[finished]?.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
            // Rewound only if nobody is holding it - a finger on the slider outranks the end of
            // the file, and the seek it is heading for is the one that should win.
            if self.audioSliders[finished]?.isTracking == true {
                self.audioAwaitingRest.insert(finished)
            } else {
                player.currentTime = 0
                if alive {
                    self.audioSliders[finished]?.value = 0
                    self.audioWaves[finished]?.progress = 0
                    self.audioTimeLabels[finished]?.text = self.formatTime(player.duration)
                }
                self.endAudioSession(finished, after: 2.5)
            }
        }
    }
    
    /// Puts the collage's list of pictures on screen, either alongside the conversation or raised
    /// over it.
    private func pushCollageList(_ list: ListGroupImages, rising: Bool) {
        guard let stack = navigationController else {
            return
        }
        // Fix: this raised a new list every time it was asked, and it is asked far more often than
        // the reader asks for one. Moving between pictures inside the viewer reports each new
        // picture back here, and answering that goes through the same jump a quote does - which,
        // for a picture that lives in a collage, is "raise the collage". So every swipe stacked
        // another copy of the same screen behind the viewer, and closing it left the reader
        // pressing Back through a pile of identical pages. There is only ever one list per
        // collage: if it is already in the stack it is pointed at the picture and returned to,
        // and a stack with something over it is rearranged in silence, since an animation nobody
        // can see only turns up later as a slide out of nowhere.
        let quietly = stack.presentedViewController != nil
        if let already = stack.viewControllers.reversed().first(where: {
            ($0 as? ListGroupImages)?.holdsSameAs(list) == true
        }) as? ListGroupImages {
            if let opened = list.imageTapped, opened >= 0, opened < list.listGroupingImages.count {
                already.show(messageId: list.listGroupingImages[opened].messageId)
            }
            if stack.topViewController !== already {
                stack.popToViewController(already, animated: !quietly)
            }
            return
        }
        if rising, !quietly {
            let transition = RisingPushTransition(rising: list, previous: stack.delegate)
            transition.onFinished = { [weak self] in
                self?.risingCollageTransition = nil
            }
            risingCollageTransition = transition
            stack.delegate = transition
        }
        stack.pushViewController(list, animated: !quietly)
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
        pushCollageList(listGroupingImages, rising: sender.risesFromBottom)
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
                            self.tableChatView.reloadRowsKeepingPlace(at: [IndexPath(row: row!, section: section!)])
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
        // A collage whose pictures have not been fetched: the tap is a request for them, not a
        // request to look at them. Only when they are all here does it open the gallery.
        if let members = sender.listImageFromGrouping, !members.isEmpty {
            let wanted = members.map { $0.imageId }.filter { !$0.isEmpty && !isFilePresent($0) }
            if !wanted.isEmpty {
                fetchCollage(wanted)
                return
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
                    // Fix: this handed back the row that was tapped to open the viewer, whichever
                    // picture the reader had since moved to - so closing on the second picture
                    // shrank it into the first one's row. The row is asked for by the picture on
                    // screen, and the list is brought to it first if it is not already there,
                    // because a row nobody can see is nothing to shrink into.
                    collage.show(messageId: viewer.currentMessageId)
                    return collage.tileView(for: viewer.currentMessageId) ?? sender.imageView
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
                // The tap on a quote, or on a pinned message: go to what it names and say so.
                self.jumpToQuotedMessage(messageId: sender.message_id)
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

        // The finger that stops a moving list is not opening what it landed on - the same rule
        // the bubble menu and the link sheet follow.
        guard !listMotion.isMoving(tableChatView) else { return }
        guard let textView = sender.view as? UITextView else { return }
        let point = sender.location(in: textView)
        guard let info = LinkHighlighting.linkInfo(at: point, in: textView) else {
            handleMentionTap(at: point, in: textView)
            return
        }

        LinkOpener.open(urlString: info.urlString)
    }

    /// A tap on a coloured @mention opens that person's profile.
    ///
    /// Only mentions carry the pin (see `NSAttributedString.Key.mentionPin`), so a tap on any
    /// other part of the message text falls through here doing nothing, exactly as before.
    private func handleMentionTap(at point: CGPoint, in textView: UITextView) {
        // While messages are being picked - to copy, forward, delete or summarise - a tap
        // belongs to that selection, and must not navigate away from it.
        guard !copySession, !forwardSession, !deleteSession, !summarizeSession else { return }
        // A long press over a mention still opens the bubble's own menu, and the finger-lift
        // that opens it also satisfies this tap recognizer. With the menu already up, this
        // touch has been spent.
        guard presentedViewController == nil else { return }
        guard let mention = LinkHighlighting.mentionInfo(at: point, in: textView) else { return }

        hideLinkHighlight()
        showProfile(pin: mention.pin)
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
        guard !dataMessagesPin.isEmpty else {
            return
        }
        // Fix: the step counter is kept between taps, and the list it steps through can shrink -
        // a pin taken away here or on another device, or three shown where four had been. A
        // counter left past the end used to make the banner do nothing at all when tapped, for
        // good, since nothing ever put it back. Out of range starts again from the first pin.
        if nextPinShowed >= dataMessagesPin.count {
            nextPinShowed = 0
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
            // Not the draft-restore path below, which runs while the chat is still opening and
            // has no business cancelling the placement it is opening with.
            self.endOpeningPlacement()
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
        let wasShowing = self.listAnchor
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.constraintTopTextField.constant = self.constraintTopTextField.constant + replyBarHeight
            // Laid out first so the list already has its new height, then held in place - both
            // inside the same animation, so the content and the bar move together rather than
            // the list snapping first.
            self.view.layoutIfNeeded()
            self.restore(wasShowing)
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

        let quotedTextColour: UIColor = self.traitCollection.userInterfaceStyle == .dark
            ? .white.withAlphaComponent(0.6)
            : .black.withAlphaComponent(0.6)

        let contentReply = UILabel()
        self.containerPreviewReply.addSubview(contentReply)
        contentReply.translatesAutoresizingMaskIntoConstraints = false
        contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
        contentReply.topAnchor.constraint(equalTo: titleReply.bottomAnchor).isActive = true
        contentReply.trailingAnchor.constraint(equalTo: containerPreviewReply.trailingAnchor, constant: -20).isActive = true
        contentReply.font = UIFont.systemFont(ofSize: 10 + offset())
        let message_text = ChatMessageText.withoutLinkPreview(dataMessages[indexPath.row]["message_text"] as? String ?? "")
        let attachment_flag = dataMessages[indexPath.row]["attachment_flag"]  as? String ?? ""
        let thumb_chat = dataMessages[indexPath.row]["thumb_id"]  as? String ?? ""
        let image_chat = dataMessages[indexPath.row]["image_id"]  as? String ?? ""
        let video_chat = dataMessages[indexPath.row]["video_id"]  as? String ?? ""
        let file_chat = dataMessages[indexPath.row]["file_id"]  as? String ?? ""
        let audio_chat = dataMessages[indexPath.row]["audio_id"]  as? String ?? ""
        let gif_chat = dataMessages[indexPath.row]["gif_id"]  as? String ?? ""
        // Fix: this chain began with "no flag and no thumbnail, so it is plain text", and that test
        // is looser than it reads - an attachment whose flag is 0 or blank was answered with its own
        // message text, which for a document is a filename and a caption joined by a bar, or nothing
        // at all. A reply to a document therefore drew a quote with nothing in it. What a message
        // carries is decided from its slots now, in one place shared by all six quotes - see
        // Utils.quotedAttachmentLine - and nil comes back only for a message that really is text,
        // which is rendered here because each of the six draws mentions its own way.
        if let carried = Utils.quotedAttachmentLine(attachmentFlag: attachment_flag,
                                                    thumb: thumb_chat,
                                                    image: image_chat,
                                                    video: video_chat,
                                                    file: file_chat,
                                                    audio: audio_chat,
                                                    gif: gif_chat,
                                                    messageText: message_text,
                                                    font: contentReply.font,
                                                    colour: quotedTextColour) {
            contentReply.attributedText = carried
        } else {
            contentReply.attributedText = message_text.richText(group_id: self.dataGroup["group_id"]  as? String ?? "")
        }
        // Same treatment as the quote inside a bubble - 60% of the text colour, which is what
        // WhatsApp uses (--quoted-message-text). Fix: this was a flat .gray, so in dark mode it
        // was grey on near-black.
        contentReply.textColor = quotedTextColour
        
        let buttonCancelReply = UIButton(type: .custom)
        self.containerPreviewReply.addSubview(buttonCancelReply)
        buttonCancelReply.translatesAutoresizingMaskIntoConstraints = false
        buttonCancelReply.trailingAnchor.constraint(equalTo: self.containerPreviewReply.trailingAnchor, constant: -10).isActive = true
        buttonCancelReply.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor).isActive = true
        buttonCancelReply.setImage(UIImage(systemName: "xmark.circle" , withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)), for: .normal)
        buttonCancelReply.addTarget(nil, action: #selector(self.deleteReplyView), for: .touchUpInside)
        buttonCancelReply.backgroundColor = .clear
        buttonCancelReply.tintColor = .mainColor
        
        // Fix: this had its own copy of "find the picture" and it was the weakest of the four -
        // the memory cache and the plain file on disk, and nothing else. A picture held only in
        // secure storage was not found, one that had not been downloaded yet was never asked for,
        // and one that arrived a moment later never appeared, because nothing was watching. The
        // bar showed an empty square for all three. It uses the one loader now, the same as the
        // quote inside a bubble - see VideoNote.loadQuotedStill.
        if attachment_flag == "1" || attachment_flag == "2" || !image_chat.isEmpty || !video_chat.isEmpty {
            let imageThumb = UIImageView()
            VideoNote.loadQuotedStill(named: thumb_chat.isEmpty ? image_chat : thumb_chat, into: imageThumb)
            self.containerPreviewReply.addSubview(imageThumb)
            // A video note is round wherever it is shown, a quote included; the square corner is
            // what every other kind of attachment keeps.
            imageThumb.layer.cornerRadius = VideoNote.isNote(video_chat) ? 15.0 : 4.0
            imageThumb.clipsToBounds = true
            imageThumb.contentMode = .scaleAspectFill
            imageThumb.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageThumb.trailingAnchor.constraint(equalTo: buttonCancelReply.leadingAnchor, constant: -10),
                imageThumb.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor),
                imageThumb.widthAnchor.constraint(equalToConstant: 30),
                imageThumb.heightAnchor.constraint(equalToConstant: 30)
            ])

            // A gif travels in the video slot too, and a play badge on an animated picture is a
            // promise it does not keep.
            if (attachment_flag == "2" || !video_chat.isEmpty), gif_chat.isEmpty {
                let imagePlay = UIImageView(image: UIImage(systemName: "play.circle.fill"))
                imageThumb.addSubview(imagePlay)
                imagePlay.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imagePlay.centerYAnchor.constraint(equalTo: imageThumb.centerYAnchor),
                    imagePlay.centerXAnchor.constraint(equalTo: imageThumb.centerXAnchor),
                    imagePlay.widthAnchor.constraint(equalToConstant: 14),
                    imagePlay.heightAnchor.constraint(equalToConstant: 14)
                ])
                imagePlay.tintColor = .white
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
        guard let indexPath = indexPath(forMessageId: messageId) else {
            return
        }
        lastScrollIdxSearch = indexScroll
        tableChatView.safeScrollToRow(at: indexPath, at: .middle, animated: wasLoaded)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // One highlight, the same everywhere - see BubbleHighlight for what it is and why.
            if let cell = self.tableChatView.cellForRow(at: indexPath) {
                BubbleHighlight.flash(in: cell, tag: EditorGroup.bubbleTag)
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
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        cancelAction()
    }

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timerSearch?.invalidate()
        // Fix: nothing at all happened below two characters, so emptying the field - the clear
        // button, or backspacing down to one letter - left everything the last search had put on
        // screen exactly where it was: the old word still lit up in every bubble, the "x of N"
        // still counting its hits, the arrows still stepping through them. What is on screen has
        // to follow what is in the field, and a search too short to run is a search that is over.
        guard searchText.count > 1 else {
            guard !textSearch.isEmpty || countMatchesSearch > 0 else {
                // Already nothing to clear - typing the first letter of a search must not cost a
                // reload of the whole conversation.
                return
            }
            textSearch = ""
            searchMatchIds = []
            countMatchesSearch = 0
            lastScrollIdxSearch = 0
            titleSearchMatches?.isHidden = true
            // Nothing to step through, which is the same state the arrows are put in for a search
            // that found nothing.
            buttonUp?.isEnabled = false
            buttonUp?.tintColor = .gray
            buttonDown?.isEnabled = false
            buttonDown?.tintColor = .gray
            // Only the highlight and the count go; the list stays exactly where it is. Clearing
            // used to put the reader back where they were before the search, or at the newest
            // message - both of which moved a list they had just been reading. Where they are is
            // where they want to be. A new word, on the other hand, starts from the newest bubble
            // again: the matches are read newest-first and lastScrollIdxSearch is reset to 0
            // below, so the first hit shown is always the one nearest the bottom.
            tableChatView.reloadDataKeepingPlace()
            return
        }
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

    /// Fetches every picture of a collage that is not on this device yet.
    ///
    /// A collage is one bubble and reads as one thing, so it is fetched as one thing: the offer in
    /// the middle asks for all of them, and so does a tap on any picture still behind its blur.
    func fetchCollage(_ names: [String]) {
        var asked = false
        for name in names where !name.isEmpty {
            guard !isFilePresent(name), !Download.isDownloading(forKey: name) else { continue }
            if beginTransfer(ofFileNamed: name) {
                asked = true
            }
        }
        if !asked, let first = names.first {
            // Already on their way; the row still has to be drawn to show that.
            reloadMessageRow(withFileNamed: first)
        }
    }

    @objc func collageOfferTapped(_ sender: ObjectGesture) {
        fetchCollage(sender.collageFiles)
    }


    /// Sends every picture of a collage that never left.
    ///
    /// A collage is one bubble, so it is asked for again as one thing. Only the first of its
    /// messages is still a row of the list - the rest live in the grouping - so each is put back on
    /// the queue by whichever route it can be reached.
    func sendCollageAgain(_ members: [ImageGrouping]) {
        for member in members where member.status == "0" {
            if dataMessages.contains(where: { $0[TypeDataMessage.message_id] as? String == member.messageId }) {
                sendAgain(messageId: member.messageId)
            } else {
                resendGrouped(member)
            }
        }
    }

    /// One picture of a collage that is not a row of its own.
    private func resendGrouped(_ member: ImageGrouping) {
        let messageId = member.messageId
        guard !messageId.isEmpty else { return }
        OutgoingThread.default.clearCancelled(messageId: messageId)
        OutgoingThread.default.removeOutgoing(messageId: messageId)
        member.status = "1"
        member.dataMessage[TypeDataMessage.status] = "1"
        Database.shared.database?.inTransaction({ (fmdb, _) in
            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE",
                                             cvalues: ["status": "1"], _where: "message_id = '\(messageId)'")
            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS",
                                             cvalues: ["status": "1"], _where: "message_id = '\(messageId)'")
        })
        let row = member.dataMessage
        let message = CoreMessage_TMessageBank.sendMessage(
            message_id: messageId,
            l_pin: row[TypeDataMessage.l_pin] as? String ?? "",
            message_scope_id: row[TypeDataMessage.message_scope_id] as? String ?? "",
            status: "1",
            message_text: row[TypeDataMessage.message_text] as? String ?? "",
            credential: row[TypeDataMessage.credential] as? String ?? "",
            attachment_flag: row[TypeDataMessage.attachment_flag] as? String ?? "",
            ex_blog_id: row[TypeDataMessage.blog_id] as? String ?? "",
            message_large_text: "",
            ex_format: "",
            image_id: row[TypeDataMessage.image_id] as? String ?? "",
            audio_id: row[TypeDataMessage.audio_id] as? String ?? "",
            video_id: row[TypeDataMessage.video_id] as? String ?? "",
            file_id: row[TypeDataMessage.file_id] as? String ?? "",
            thumb_id: row[TypeDataMessage.thumb_id] as? String ?? "",
            reff_id: row[TypeDataMessage.reff_id] as? String ?? "",
            read_receipts: row[TypeDataMessage.read_receipts] as? String ?? "",
            chat_id: row[TypeDataMessage.chat_id] as? String ?? "",
            is_call_center: row[TypeDataMessage.is_call_center] as? String ?? "",
            call_center_id: row[TypeDataMessage.call_center_id] as? String ?? "",
            opposite_pin: row[TypeDataMessage.opposite_pin] as? String ?? "",
            gif_id: row[TypeDataMessage.gif_id] as? String ?? "",
            isForwarded: (row[TypeDataMessage.is_forwarded] as? Int).map(String.init) ?? "",
            specFile: row[TypeDataMessage.spec_file] as? String ?? "")
        Nexilis.addQueueMessage(message: message)
    }

    /// Stops the sending of every picture of a collage, and says so of each of them.
    func markCollageSendCancelled(_ members: [ImageGrouping]) {
        for member in members where member.status == "1" {
            if dataMessages.contains(where: { $0[TypeDataMessage.message_id] as? String == member.messageId }) {
                markSendCancelled(messageId: member.messageId)
            } else {
                OutgoingThread.default.cancelSend(messageId: member.messageId)
                Network.cancelUpload(name: member.imageId)
                Network.cancelUpload(name: member.thumbId)
                member.status = "0"
                member.dataMessage[TypeDataMessage.status] = "0"
                let messageId = member.messageId
                Database.shared.database?.inTransaction({ (fmdb, _) in
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE",
                                                     cvalues: ["status": "0"], _where: "message_id = '\(messageId)'")
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_STATUS",
                                                     cvalues: ["status": "0"], _where: "message_id = '\(messageId)'")
                })
            }
        }
        if let anchor = members.first?.imageId, !anchor.isEmpty {
            reloadMessageRow(withFileNamed: anchor)
        }
    }


    /// The message ids a row stands for, ready to be reported as one.
    ///
    /// A collage is one row of the list but several messages: the rest were taken out of the list
    /// when they were gathered into it. Anything that says what the reader has seen has to say it
    /// of all of them - a read mark sent for the first picture alone leaves every other picture in
    /// the collage looking unread to whoever sent it, for good.

    /// Every picture of every collage, checked once the conversation is open.
    ///
    /// The workaround to a shape this list cannot easily change: read marks are gathered by walking
    /// the rows, and a collage is one row standing for several messages - so a collage whose row
    /// has already been reported leaves its other pictures unreported, and they stay unread to
    /// whoever sent them. The gathering itself now expands a row into its members, but that only
    /// helps the messages it happens to walk past. This walks the collages themselves, on opening,
    /// and reports whatever is still outstanding - grouped by sender, because in a group each of
    /// them is told separately.
    func sweepCollageReadReceipts() {
        guard !isPreview, !groupImages.isEmpty, let idMe = User.getMyPin() else {
            return
        }
        var outstanding: [String: [String]] = [:]
        for (_, members) in groupImages {
            for member in members {
                let row = member.dataMessage
                let status = row[TypeDataMessage.status] as? String ?? ""
                let fPin = row["f_pin"] as? String ?? ""
                // 4 and 8 are the states that already mean "seen"; anything else has not been
                // reported yet.
                guard status != "4", status != "8", fPin != idMe, !fPin.isEmpty,
                      !member.messageId.isEmpty,
                      EditorGroup.conditionSendRead(scope: row[TypeDataMessage.message_scope_id] as? String ?? "",
                                                    fPin: fPin,
                                                    messageId: member.messageId) else {
                    continue
                }
                outstanding[fPin, default: []].append(member.messageId)
            }
        }
        for (fPin, ids) in outstanding {
            sendReadMessageStatus(chat_id: dataTopic["chat_id"] as? String ?? "",
                                  f_pin: fPin,
                                  message_scope_id: MessageScope.GROUP,
                                  message_id: ids.joined(separator: ","))
        }
    }

    func readReceiptIds(for row: [String: Any?]) -> String {
        let id = row[TypeDataMessage.message_id] as? String ?? ""
        guard let members = groupImages[id], !members.isEmpty else { return id }
        let all = members.map { $0.messageId }.filter { !$0.isEmpty }
        return all.isEmpty ? id : all.joined(separator: ",")
    }

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
        tableChatView.reloadRowsKeepingPlace(at: [indexPath])
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

    /// Where a leftward pull leads. Given one, the pull moves the bubble first and then drags
    /// that screen in from the right edge the way WhatsApp does, letting it fall back if the
    /// pull is abandoned. A shorter pull, released before the screen takes over, still opens it
    /// - with the ordinary push.
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
    /// How far the bubble is pulled before the info screen starts coming in behind it.
    ///
    /// Fix: the screen began arriving with the very first movement of the finger, so a pull that
    /// was meant to be a pull was already a page turn. The bubble travels a real distance first
    /// and the screen takes over from there, carrying on from exactly where the pull stopped so
    /// there is no jump between the two. The same distance as the threshold, so the tap of
    /// confirmation and the screen taking over are one moment rather than two.
    private static let infoHandoff: CGFloat = threshold

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
            //
            // Fix: this used to be isScrollEnabled = false. That reads as "hold the list still",
            // and it does far more than that. A scroll view only takes the safe area into its
            // adjusted inset on the axes it can actually scroll on - the default behaviour - so
            // switching scrolling off drops the inset the content is laid out against, and the
            // whole conversation shifts by it on the spot. Switching it back on shifts it back.
            // That is the jumping around a bubble pull: a hundred-odd points, instantly, in and
            // out again, and nothing in the name of the property to suggest it. Taking the
            // table's own pan away holds the list just as still and touches nothing else.
            tableView.panGestureRecognizer.isEnabled = false
            // A pan that is taken away mid-coast leaves the coast running, which the old way
            // stopped as a side effect. Asked for the offset it already has, a scroll view stops
            // where it is without moving.
            if tableView.isDecelerating {
                tableView.setContentOffset(tableView.contentOffset, animated: false)
            }
            addIcon(to: cell, direction: direction)

        case .changed:
            guard let cell = activeCell else {
                return
            }
            if push.isRunning {
                push.update(pushProgress(of: sender))
                return
            }
            let raw = sender.translation(in: activeDirection == .info ? (tableView.window ?? tableView) : tableView).x - beganTranslation
            // Only the direction this drag started in counts; pulling back the other way just
            // returns the row to where it was.
            let travelled = activeDirection == .reply ? max(0, raw) : max(0, -raw)
            // Past the limit the row keeps moving, but barely - the same resistance a scroll
            // view gives at its edge, so the pull feels bounded without feeling stuck.
            let pulled = travelled <= ChatBubbleSwipe.maxPull
                ? travelled
                : ChatBubbleSwipe.maxPull + (travelled - ChatBubbleSwipe.maxPull) * 0.15
            // Far enough: the bubble has been pulled its whole length, and from here the drag
            // belongs to the screen coming in behind it. The bubble stays where the pull left
            // it - putting it back at this moment would be a jump backwards under the finger -
            // and the list travels the rest of the way as one.
            if activeDirection == .info, travelled >= ChatBubbleSwipe.infoHandoff, !push.isRunning,
               let indexPath = activeIndexPath,
               let destination = infoDestination?(indexPath) {
                offset(cell: cell, by: -ChatBubbleSwipe.infoHandoff)
                // The same tap of confirmation a reply pull gives at its threshold - here it
                // marks the moment the screen takes the drag over.
                feedback?.impactOccurred()
                push.begin(pushing: destination.viewController, in: destination.navigation)
                push.update(pushProgress(of: sender))
                return
            }
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
                let progress = pushProgress(of: sender)
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

    /// How far the screen coming in has travelled, as a fraction of the screen.
    ///
    /// Measured against the window: the table is inside the screen being pushed aside, so a
    /// translation read in its own coordinates would be measured against a moving ruler. The
    /// distance the bubble was pulled before the handover is taken off, so the screen starts
    /// from nothing at the moment it takes over rather than jumping in already part way.
    private func pushProgress(of sender: UIPanGestureRecognizer) -> CGFloat {
        guard let tableView = tableView else {
            return 0
        }
        let space = tableView.window ?? tableView
        let travelled = max(0, beganTranslation - sender.translation(in: space).x - ChatBubbleSwipe.infoHandoff)
        return travelled / max(space.bounds.width, 1)
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
    ///
    /// A leftward pull has none. What it leads to is a screen arriving behind the bubble, which
    /// says what is happening on its own; a badge in the space the bubble leaves is one thing
    /// too many to look at.
    private func addIcon(to cell: UITableViewCell, direction: Direction) {
        iconView?.removeFromSuperview()
        guard direction == .reply else {
            iconView = nil
            return
        }
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
        tableView?.panGestureRecognizer.isEnabled = true
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
        // Fix: the arriving screen was given the whole container to fill, which is the navigation
        // controller's entire area - bar included. A screen that does not extend under the bar is
        // meant to start below it, and until the transition finished and the navigation controller
        // laid it out properly it was sitting about a bar's height too high. Anything at the very
        // top of it - a date across the top of a message, say - was hidden behind the bar for the
        // length of the transition and appeared to arrive late. The context knows the frame the
        // screen is going to end up in; it is given that one from the start.
        let finalFrame: CGRect
        if let toController = transitionContext.viewController(forKey: .to) {
            let frame = transitionContext.finalFrame(for: toController)
            finalFrame = frame.isEmpty ? container.bounds : frame
        } else {
            finalFrame = container.bounds
        }
        toView.frame = finalFrame

        // Fix: the travel used to be a transform on the arriving screen itself. Setting a frame
        // on a view that carries a transform recomputes its bounds and centre to satisfy that
        // frame, which cancels the translation - and laying that screen out is exactly what the
        // navigation controller does, repeatedly, while the transition is in flight. So after the
        // first layout pass the screen stopped travelling and simply sat where it was going to
        // end up, gradually uncovered as the conversation slid off it. What that looks like is
        // what the recording shows: nothing arriving, a dark empty panel widening from the right,
        // and the contents of the screen appearing to land all at once at the end.
        //
        // The travel is carried by a wrapper now. Nothing lays the wrapper out, so its transform
        // survives, and the screen inside it comes in with the finger, already drawn.
        let slider = UIView(frame: container.bounds)
        slider.backgroundColor = .clear
        slider.addSubview(toView)
        slider.transform = CGAffineTransform(translationX: width, y: 0)
        container.addSubview(slider)

        // The same parallax the system's push uses: the screen being left behind drifts a third
        // of the way, under a slight dim, so the two read as a stack rather than a swap.
        let dim = UIView(frame: container.bounds)
        dim.backgroundColor = .black
        dim.alpha = 0
        container.insertSubview(dim, belowSubview: slider)

        // Linear: an interactive transition is scrubbed by the finger, and any other curve makes
        // the screen lag behind or run ahead of it.
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveLinear], animations: {
            slider.transform = .identity
            fromView.transform = CGAffineTransform(translationX: -width / 3, y: 0)
            dim.alpha = 0.1
        }, completion: { _ in
            let cancelled = transitionContext.transitionWasCancelled
            fromView.transform = .identity
            dim.removeFromSuperview()
            if cancelled {
                toView.removeFromSuperview()
            } else {
                // Handed back to the container the navigation controller knows about, at the
                // frame it was going to have anyway, before the wrapper goes.
                toView.frame = finalFrame
                container.addSubview(toView)
            }
            slider.removeFromSuperview()
            transitionContext.completeTransition(!cancelled)
        })
    }
}

/// Keys for the few things the voice-note bar needs to remember on a conversation.
enum EditorVoiceNoteKeys {
    static var wants: UInt8 = 0
    static var bar: UInt8 = 0
    static var videoNote: UInt8 = 0
}
