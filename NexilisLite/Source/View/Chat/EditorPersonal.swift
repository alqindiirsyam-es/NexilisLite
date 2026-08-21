//
//  EditorPersonal.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 31/08/21.
//

import UIKit
import AVKit
import AVFoundation
import QuickLook
import NotificationBannerSwift
import Photos
import nuSDKService
import SwiftLinkPreview
import SDWebImage
import PhotosUI
import ObjectiveC
import UniformTypeIdentifiers

public class EditorPersonal: UIViewController, ImageVideoPickerDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate, ChatBubbleContextMenuPresenting {
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
    @IBOutlet weak var constraintLeftTextField: NSLayoutConstraint!
    @IBOutlet weak var constraintBottomTableViewWithTextfield: NSLayoutConstraint!
    @IBOutlet weak var viewAttachment: UIStackView!
    @IBOutlet weak var tableMention: UITableView!
    @IBOutlet weak var heightTableMention: NSLayoutConstraint!
    @IBOutlet weak var contraintBottomMention: NSLayoutConstraint!
    public var dataPerson: [String: String?] = [:]
    var dataMessages: [[String: Any?]] = [] {
        didSet {
            groupMessagesByDate()
        }
    }
    var messagesByDate: [String: [[String: Any?]]] = [:]
    var dataDates: [String] = []

    /// The messages of one date section.
    ///
    /// Fix: this screen already groups its messages by date - cellForRow and numberOfRows read
    /// that grouping - but every other table-view callback still filtered the whole loaded
    /// conversation to find the same rows, once per row. With a few hundred messages loaded
    /// that is thousands of dictionary lookups and string comparisons that the grouping had
    /// already done, and it is a good part of why scrolling dragged on an older phone.
    func messages(onDate date: String) -> [[String: Any?]] {
        return messagesByDate[date] ?? []
    }

    var users: [User] = []
    public var dataMessageForward: [[String: Any?]]?
    var imageVideoPicker: ImageVideoPicker!
    var documentPicker: DocumentPicker!
    var currentIndexpath: IndexPath?
    var previewItem: NSURL?
    var reffId: String?
    var stickers = [String]()
    public var unique_l_pin = ""
    public var isContactCenter = false
    public var isRequestContactCenter = true
    public var fromNotification = false
    public var onGoingCC = false
    public var fPinContacCenter = ""
    public var complaintId = ""
    public var referenceMessageId = ""
    public var referenceChatDate = ""
    var channelContactCenter = ""
    var counter = 0
    var dateStartCC = ""
    var markerCounter: String?

    // MARK: - Paging
    //
    // Same story as EditorGroup: the chat used to read its whole history (LIMIT -1) on the
    // main thread before it could draw anything, and hid the wait behind a table faded in
    // from alpha 0. Only the newest slice is read now; older messages follow when the reader
    // scrolls up to them.
    private static let initialMessagePageSize: Int64 = 50
    // Deliberately generous. Putting older messages in costs a contentOffset assignment, and
    // that assignment ends whatever deceleration the scroll is running on - so the cure is to
    // reach the end of the loaded messages as rarely as possible, not to make the trip there
    // cheaper.
    private static let olderMessagePageSize: Int64 = 100
    /// Database offset of the oldest message currently loaded.
    private var loadedOffset: Int64 = 0
    /// How many database rows the loaded window covers - not dataMessages.count, which has
    /// grouped image collages taken out of it.
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
    /// True while the first page is being put on screen; what the old `alpha != 1` checks
    /// were really asking.
    private var isInitialLoading = true
    /// Makes sure the first frame the table lays out is already at the newest message.
    private var pendingInitialScrollToBottom = false
    /// The first unread message, while the chat is still being placed at it.
    private var pendingUnreadMarkerScroll: String?
    private var remainingUnreadMarkerScrollPasses = 0
    /// Enough layout passes for the estimated row heights above the marker to be replaced by
    /// measured ones, and few enough that a conversation that will not settle gives up rather
    /// than re-scrolling under the reader's finger.
    private static let unreadMarkerScrollPasses = 8
    /// Measured row heights by message id, so rows that have not been built yet are estimated
    /// from real numbers - that is what keeps the position steady when older messages are
    /// inserted above.
    private var measuredRowHeights: [String: CGFloat] = [:]
    var buttonScrollToBottom = UIButton()
    let indicatorCounterBSTB = UIView()
    let labelCounter = UILabel()
    var copySession = false
    var forwardSession = false
    var deleteSession = false
    var summarizeSession = false
    var isSearching = false
    let containerMultpileSelectSession = UIView()
    let containerAction = UIView()
    var removed = false
    var isConfidential = false
    var isAck = false
    var isSecret = false
    let viewSticker = UIView()
    let containerLink = UIView()
    let containerPreviewReply = UIView()
    let containerPin = UIView()
    let textPin = UILabel()
    let signSelectedPin = UIStackView()
    var bottomAnchorPreviewReply = NSLayoutConstraint()
    var blocking = ""
    var timeoutCC = Timer()
    var nowSelectedCategoryCC = ""
    var showToastTwiceClick = false
    var showToast30s = false
    var allowTyping = true
    var hapticSwipeLeft = false
    var listTimerCredential: [String: Int] = [:]
    var timerCredential: [String: Timer] = [:]
    let contactChatNav = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
    var searchBar: UISearchBar!
    var constraintBottomContainerMultpileSelectSession = NSLayoutConstraint()
    var titleSearchMatches: UILabel!
    var textSearch = ""
    var nextPinShowed = 0
    var countMatchesSearch = 0
    var lastScrollIdxSearch = 0
    var buttonUp: UIButton!
    var buttonDown: UIButton!
    var multipleOffsetUp = 1
    var lastOffsetDown = 1
    var gettingDataMessage = true
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
    var fromVCAC = false
    var serviceIdCC = ""
    var isDirectCC = false
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
              aboveRun.count + belowRun.count <= EditorPersonal.maximumImagesInCollage else {
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


    // MARK: - Preview

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
        autoDownloadTimer = Timer.scheduledTimer(withTimeInterval: EditorPersonal.autoDownloadSettleDelay, repeats: false) { [weak self] _ in
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
        var slots = EditorPersonal.maximumConcurrentAutoDownloads - autoDownloadsInFlight.count
        guard slots > 0 else {
            return
        }
        // Light things first, across every visible row, before anything heavy is started at
        // all: a document or a video can hold a place for a long time, and a thumbnail two rows
        // down should not be waiting behind it to appear.
        for keys in [EditorPersonal.lightAttachmentKeys, EditorPersonal.heavyAttachmentKeys] {
            for indexPath in visible {
                for filename in autoDownloadableFiles(at: indexPath, keys: keys) {
                    guard slots > 0 else {
                        return
                    }
                    guard !autoDownloadsInFlight.contains(filename),
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

    private func startAutoDownload(_ filename: String) {
        autoDownloadsInFlight.insert(filename)
        Download().startHTTP(forKey: filename) { [weak self] name, progress in
            guard progress >= 100 || progress < 0 else {
                return
            }
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                self.autoDownloadsInFlight.remove(name)
                if progress >= 100 {
                    // Straight away, scrolling or not: the bubble was already given its size, so
                    // the picture appearing moves nothing.
                    self.reloadMessageRow(withFileNamed: name)
                }
                // A place has come free; whatever else is on screen can have it.
                self.scheduleAutoDownloadSweep()
            }
        }
    }


    /// Whether a message can sit inside a collage at all: an image on its own, with no caption,
    /// no reply attached and nothing else that needs a bubble of its own.
    private func isCollageCandidate(_ row: [String: Any?]) -> Bool {
        return row["image_id"] != nil
            && !(row["image_id"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (row["message_text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (row["reff_id"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (row["credential"] as? String ?? "") != "1"
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
                             dataPerson: dataPerson,
                             dataGroup: [:],
                             dataTopic: [:])
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
              run.count < EditorPersonal.maximumImagesInCollage,
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
        guard tempImages.count >= EditorPersonal.minimumImagesForCollage else {
            return
        }
        if tempImages.count > EditorPersonal.maximumImagesInCollage {
            tempImages.removeSubrange(EditorPersonal.maximumImagesInCollage..<tempImages.count)
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
    var contextCC = ""
    
    var tableMentionEdit = UITableView()
    var heightTableEditMention: NSLayoutConstraint!
    private weak var lastContextMenuView: UIView?
    private var lastContextMenuInteraction: UIContextMenuInteraction?
    // Fix: state behind ChatBubbleContextMenuPresenting - the WhatsApp-style menu very long
    // bubbles get instead of the system one. Same as EditorGroup.swift.
    var contextMenuActionHandlers: [String: () -> Void] = [:]
    var contextMenuActionSeed = 0
    weak var longBubbleContextMenu: ChatBubbleContextMenu?
    // Fix: mirrors EditorGroup.swift's link-handling state (see its CHANGELOG entries
    // for the full history of why each of these exists).
    private var currentLinkHighlightViews: [UIView] = []
    private var suppressNextLinkTap = false
    private var suppressLinkTapToken = 0
    private var linkPressGeneration = 0
    
    private var readStatusTasks: [Task<Void, Never>] = []
    
    var lastScrollCheckTime: Date = Date()
    
    func offset() -> CGFloat{
        guard let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0") else { return 0 }
        return CGFloat(fontSize)
    }
    
    private func groupMessagesByDate() {
        messagesByDate = Dictionary(
            grouping: dataMessages.compactMap { (msg: [String: Any?]) -> [String: Any?]? in
                guard let _ = msg["chat_date"] as? String else { return nil }
                return msg
            },
            by: { (msg: [String: Any?]) -> String in
                return msg["chat_date"] as! String
            }
        )
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            removeAllObjectBeforeDismissVC()
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

    public override func viewDidAppear(_ animated: Bool) {
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
        updateProfile()
        // The first page only covers the screen; topping it up now means the reader's first
        // flick upwards does not immediately run out of messages.
        DispatchQueue.main.async { [weak self] in
            self?.prefetchOlderMessagesIfIdle()
        }
        gettingDataMessage = false
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
        if isContactCenter {
            buttonAckConfidential.isHidden = true
            constraintLeftTextField.constant = 20
        } else {
            buttonAckConfidential.circle()
            buttonAckConfidential.addTarget(self, action: #selector(showChooserACKConfidential), for: .touchUpInside)
            buttonAckConfidential.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
            buttonAckConfidential.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        }
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
        
        tableChatView.register(UITableViewCell.self, forCellReuseIdentifier: "cellEditorPersonal")
        
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
        center.addObserver(self, selector: #selector(onUnfriend(notification:)), name: NSNotification.Name(rawValue: "onUpdatePersonInfo"), object: nil)
        center.addObserver(self, selector: #selector(onTyping(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerTypingChat), object: nil)
        center.addObserver(self, selector: #selector(onFailedSendMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.failedSendMessage), object: nil)
        center.addObserver(self, selector: #selector(onRefreshCallLog(notification:)), name: NSNotification.Name(rawValue: "refreshCallLog"), object: nil)
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
                sendChat(message_scope_id: MessageScope.WHISPER, status: "2", message_text: dataMessageForward![i]["message_text"]  as? String ?? "", credential: "0", attachment_flag: dataMessageForward![i]["attachment_flag"]  as? String ?? "", ex_blog_id: "", message_large_text: "", ex_format: "", image_id: dataMessageForward![i]["image_id"]  as? String ?? "", audio_id: dataMessageForward![i]["audio_id"]  as? String ?? "", video_id: dataMessageForward![i]["video_id"]  as? String ?? "", file_id: dataMessageForward![i]["file_id"]  as? String ?? "", thumb_id: dataMessageForward![i]["thumb_id"]  as? String ?? "", reff_id: "", read_receipts: dataMessageForward![i]["read_receipts"]  as? String ?? "", chat_id: "", is_call_center: "0", call_center_id: "", viewController: self, gif_id: dataMessageForward![i][TypeDataMessage.gif_id]  as? String ?? "", is_forwarded: isForwarded + 1, is_secret: (dataMessageForward![i][TypeDataMessage.is_secret] as? Int) ?? 0)
            }
            dataMessageForward = nil
        }
        
        tableMention.register(UITableViewCell.self, forCellReuseIdentifier: "cellMention")
        tableMention.dataSource = self
        tableMention.delegate = self
        tableMention.contentInset = UIEdgeInsets(top: -25, left: 0, bottom: 0, right: 0)
        
        tableChatView.rowHeight = UITableView.automaticDimension
        // A concrete estimate rather than automaticDimension, which makes the table measure
        // rows just to know where it is. estimatedHeightForRowAt refines it per row once a
        // row has been on screen.
        tableChatView.estimatedRowHeight = 72
        
        if isContactCenter && !isRequestContactCenter && !onGoingCC {
            var companyName = ""
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT first_name, last_name FROM BUDDY where official_account = '1'"), cursor.next() {
                        companyName = cursor.string(forColumnIndex: 0)! + " " + cursor.string(forColumnIndex: 1)!
                        companyName = companyName.trimmingCharacters(in: .whitespaces)
                        cursor.close()
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            self.dateStartCC = "\(Date().currentTimeMillis())"
            let myName = User.getData(pin: User.getMyPin() as String?)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
                sendChat(message_text: "Hi \(dataPerson["name"]!!), thank you for contacting \(companyName). My name is \(myName!.fullName.trimmingCharacters(in: .whitespaces)), how can I help you?".localized(), ex_format: "1", is_call_center: "1", call_center_id: complaintId, viewController: self, isAutoSendCC: true)
            })
            if channelContactCenter == "1" {
                if let pin = dataPerson["f_pin"] {
                    let controller = QmeraAudioViewController()
                    controller.user = User.getData(pin: pin)
                    controller.isOutgoing = true
                    controller.modalPresentationStyle = .overCurrentContext
                    present(controller, animated: true, completion: nil)
                }
            } else if channelContactCenter == "2" {
                let videoVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
                videoVC.dataPerson.append(dataPerson)
                self.show(videoVC, sender: nil)
            }
        }
        if isDirectCC {
            directCC()
        }
//        else if isContactCenter {
//            let buttonId = UIButton()
//            if channelContactCenter == "0" {
//                buttonId.tag = 0
//                ccAction(sender: buttonId)
//            } else if channelContactCenter == "1" {
//                buttonId.tag = 1
//                ccAction(sender: buttonId)
//            } else if channelContactCenter == "2" {
//                buttonId.tag = 2
//                ccAction(sender: buttonId)
//            }
//        }
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
            for timer in self.timerCredential.values {
                timer.invalidate()
            }
            self.timeoutCC.invalidate()
            SecureUserDefaults.shared.removeValue(forKey: "inEditorPersonal")
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func setRightButtonItem() {
        navigationItem.rightBarButtonItems = nil
        let actionDelete = UIAction(title: "Delete Conversation".localized(), handler: {(_) in
            if !self.isContactCenter {
                let alert = LibAlertController(title: "", message: "Are you sure to delete all message in this conversation?".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: nil))
                alert.addAction(UIAlertAction(title: "Delete".localized(), style: .destructive, handler: {(_) in
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "(f_pin='\(self.dataPerson["f_pin"]!!)' or l_pin='\(self.dataPerson["f_pin"]!!)') and (message_scope_id='\(MessageScope.WHISPER)' or message_scope_id='\(MessageScope.FORM)' or message_scope_id='\(MessageScope.CALL)' or message_scope_id='\(MessageScope.MISSED_CALL)') and is_call_center = 0")
                            _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(self.dataPerson["f_pin"]!!)'")
                            let l_pin = self.dataPerson["f_pin"]!!
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
            }
        })
        let actionSearch = UIAction(title: "Search".localized(), handler: {(_) in
            self.isSearching = true
            if self.reffId != nil {
                self.deleteReplyView()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                let cancelButton = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(self.cancelAction))
                cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], for: .normal)
                if self.dataPerson["f_pin"] != "-999" && !self.isContactCenter {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                if self.isContactCenter || self.fromNotification {
                    self.navigationItem.leftBarButtonItem = nil
                }
                self.changeAppBar()
                self.addMultipleSelectSession()
            }
        })
        let actionUnblock = UIAction(title: "Unblock".localized(), handler: {(_) in
            if !self.isContactCenter {
                DispatchQueue.global(qos: .userInitiated).async {
                    if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getUnBlock(l_pin: self.dataPerson["f_pin"]!!)) {
                        if !response.isOk() {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Unable to complete action".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                        } else {
                            DispatchQueue.main.async { [self] in
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                                            "ex_block" : "0"
                                        ], _where: "f_pin = '\(self.dataPerson["f_pin"]!!)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                containerAction.subviews.forEach({ $0.removeFromSuperview() })
                                containerAction.removeFromSuperview()
                                setRightButtonItem()
                                changeAppBar()
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                    }
                }
            }
        })
        let actionBlock = UIAction(title: "Block".localized(), handler: {(_) in
            if !self.isContactCenter {
                DispatchQueue.global(qos: .userInitiated).async {
                    if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getBlock(l_pin: self.dataPerson["f_pin"]!!)) {
                        if !response.isOk() {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Unable to complete action".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                        } else {
                            DispatchQueue.main.async { [self] in
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "BUDDY", cvalues: [
                                            "ex_block" : "1"
                                        ], _where: "f_pin = '\(self.dataPerson["f_pin"]!!)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                setRightButtonItem()
                                changeAppBar()
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                    }
                }
            }
        })
        var menu = UIMenu(title: "", children: [
            actionSearch,
            actionDelete
        ])
        let exblock = User.getDataCanNil(pin: self.dataPerson["f_pin"]!!)?.ex_block
        blocking = exblock == nil ? "0" : exblock!.isEmpty ? "0" : exblock!
        if blocking == "1" && self.dataPerson["f_pin"]!! != "-999" && self.dataPerson["isOfficial"]!! != "1" {
            menu = UIMenu(title: "", children: [
                actionSearch,
                actionUnblock,
                actionDelete
            ])
            blockedView(blocked: "1")
        } else if blocking == "0" {
            if self.dataPerson["f_pin"]!! != "-999" && complaintId.isEmpty && self.dataPerson["isOfficial"]!! != "1" {
                menu = UIMenu(title: "", children: [
                    actionSearch,
                    actionBlock,
                    actionDelete
                ])
            } else if  !complaintId.isEmpty{
                menu = UIMenu(title: "", children: [
                    actionSearch
                ])
            }
                else {
                menu = UIMenu(title: "", children: [
                    actionSearch,
                    actionDelete
                ])
            }
            if containerAction.isDescendant(of: self.view) {
                containerAction.subviews.forEach({ $0.removeFromSuperview() })
                containerAction.removeFromSuperview()
            }
        } else {
            blockedView(blocked: "-1")
            changeAppBar()
        }
        
        let moreIcon = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), menu: menu)
        let buttonAudioCall = UIBarButtonItem(image: UIImage(systemName: "phone", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(audioVideoCall(sender:)))
//        let buttonSearch = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(audioVideoCall(sender:)))
        buttonAudioCall.tag = 0
        let buttonVideoCall = UIBarButtonItem(image: UIImage(systemName: "video", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(audioVideoCall(sender:)))
        buttonVideoCall.tag = 1
        let buttonAddRoom = UIBarButtonItem(image: UIImage(systemName: "plus.message", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), style: .plain, target: self, action: #selector(addRoom(sender:)))
        if dataPerson["f_pin"] != "-999" && !isContactCenter && blocking == "0" && self.dataPerson["isOfficial"]!! != "1" {
            navigationItem.rightBarButtonItems = [moreIcon,buttonAudioCall,buttonVideoCall]
        } else if !isContactCenter {
            navigationItem.rightBarButtonItem = moreIcon
        } else if !complaintId.isEmpty { //!complaintId.isEmpty
            navigationItem.rightBarButtonItems = [moreIcon,buttonAddRoom]
        }
    }
    
    func loadData() {
        if (unique_l_pin != "" || isContactCenter) {
            getDataProfile(fPin: unique_l_pin)
            if isContactCenter && !isRequestContactCenter && users.count == 0 {
                if !unique_l_pin.isEmpty {
                    users.append(User.getData(pin: unique_l_pin) ?? User(pin: ""))
                }
            }
        }
        
        let pinPerson: String = (dataPerson["f_pin"] ?? "") ?? ""
        if onGoingCC {
            SecureUserDefaults.shared.set(self.fPinContacCenter, forKey: "inEditorPersonal")
        } else {
            SecureUserDefaults.shared.set(pinPerson, forKey: "inEditorPersonal")
        }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [pinPerson])
        
        if isContactCenter || fromNotification {
            let imageButton = UIImageView(frame: CGRect(x: -16, y: 0, width: 20, height: 44))
            imageButton.image = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default))?.withTintColor(.white)
            imageButton.contentMode = .left
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapExit))
            imageButton.isUserInteractionEnabled = true
            imageButton.addGestureRecognizer(tapGestureRecognizer)
            let leftItem = UIBarButtonItem(customView: imageButton)
            self.navigationItem.leftBarButtonItem = leftItem
        }
        
        if dataPerson["f_pin"] == "-999" {
            chatbot()
        }
        
        let dataUser = User.getData(pin: pinPerson)
        if dataUser == nil {
            blocking = "0"
        } else {
            let exblock = dataUser!.ex_block
            blocking = exblock!.isEmpty ? "0" : exblock!
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
            messageInfoVC.dataPerson = self.dataPerson
            return (messageInfoVC, navigation)
        }
        tableChatView.dataSource = self
        tableChatView.keyboardDismissMode = .interactive
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableChatView.addGestureRecognizer(tapGesture)
        
        if !isContactCenter {
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
                    remainingUnreadMarkerScrollPasses = EditorPersonal.unreadMarkerScrollPasses
                    applyPendingUnreadMarkerScroll()
                } else {
                    // The marker's message is not a row of its own after all (deleted, or
                    // hidden inside a collage). Opening at the newest message beats opening at
                    // the top of whatever happens to be loaded.
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
                            var stringMessage = ""
                            for i in idx..<dataMessages.count {
                                if dataMessages[i]["f_pin"] as? String != idMe && EditorGroup.conditionSendRead(scope: dataMessages[i][TypeDataMessage.message_scope_id] as! String, fPin: dataMessages[i][TypeDataMessage.f_pin] as! String, messageId: dataMessages[i]["message_id"]  as? String ?? "") {
                                    let id = dataMessages[i]["message_id"]  as? String ?? ""
                                    if !stringMessage.isEmpty {
                                        stringMessage += ",\(id)"
                                    } else {
                                        stringMessage += id
                                    }
                                }
                            }
                            if !stringMessage.isEmpty {
                                sendReadMessageStatus(
                                    chat_id: "",
                                    f_pin: dataPerson["f_pin"]!!,
                                    message_scope_id: MessageScope.WHISPER,
                                    message_id: stringMessage
                                )
                            }
                            if idx != 0 {
                                var stringMessage1 = ""
                                for i in 0..<idx {
                                    let status = dataMessages[i][TypeDataMessage.status] as? String
                                    if dataMessages[i]["f_pin"] as? String != idMe && status != "4" && status != "8" && EditorGroup.conditionSendRead(scope: dataMessages[i][TypeDataMessage.message_scope_id] as! String, fPin: dataMessages[i][TypeDataMessage.f_pin] as! String, messageId: dataMessages[i]["message_id"]  as? String ?? "") {
                                        let id = dataMessages[i]["message_id"]  as? String ?? ""
                                        if !stringMessage.isEmpty {
                                            stringMessage += ",\(id)"
                                        } else {
                                            stringMessage += id
                                        }
                                    }
                                }
                                if !stringMessage1.isEmpty {
                                    sendReadMessageStatus(
                                        chat_id: "",
                                        f_pin: dataPerson["f_pin"]!!,
                                        message_scope_id: MessageScope.WHISPER,
                                        message_id: stringMessage1
                                    )
                                }
                            }
                        }
                    }
                }
            } else {
                let l_pin = self.dataPerson["f_pin"] as? String ?? ""
                if let dataSaved: String = SecureUserDefaults.shared.value(forKey: "new_saved_\(l_pin)") {
                    let data = dataSaved
                    if let jsonData = data.data(using: .utf8),
                       let dataJson = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] {
                        let last_m = dataJson["text"] ?? ""
                        let last_r = dataJson["reffId"] ?? ""
                        let list_m = dataJson["list_mention"] as? [[String: String]] ?? []
                        
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
                            textFieldSend.attributedText = last_m.richText(isEditing: true, listMentionInTextField: listMentionInTextField)
                            textFieldSend.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black
                        }
                        
                        if !last_r.isEmpty {
                            handleReply(indexPath: IndexPath(row: 0, section: 0), reffId: last_r)
                        }
                    }
                }
                DispatchQueue.global(qos: .userInitiated).async{ [self] in
                    let idMe = User.getMyPin() as String?
                    var stringMessage = ""
                    for i in 0..<dataMessages.count {
                        let status = dataMessages[i][TypeDataMessage.status] as? String
                        if dataMessages[i]["f_pin"] as? String != idMe && status != "4" && status != "8" && EditorGroup.conditionSendRead(scope: dataMessages[i][TypeDataMessage.message_scope_id] as! String, fPin: dataMessages[i][TypeDataMessage.f_pin] as! String, messageId: dataMessages[i][TypeDataMessage.message_id] as! String) {
                            let id = dataMessages[i]["message_id"]  as? String ?? ""
                            if !stringMessage.isEmpty {
                                stringMessage += ",\(id)"
                            } else {
                                stringMessage += id
                            }
                        }
                    }
                    if !stringMessage.isEmpty {
                        sendReadMessageStatus(
                            chat_id: "",
                            f_pin: dataPerson["f_pin"]!!,
                            message_scope_id: MessageScope.WHISPER,
                            message_id: stringMessage
                        )
                    }
                }
                // No delay: with one page loaded there is nothing left to wait for. The same
                // scroll is repeated once the table has laid out (viewDidLayoutSubviews), so
                // the first frame drawn is already at the newest message.
                pendingInitialScrollToBottom = true
                tableChatView.scrollToBottom(isAnimated: false, delay: 0)
            }
        } else if isContactCenter && onGoingCC {
            DispatchQueue.global(qos: .userInitiated).async{ [self] in
                let idMe = User.getMyPin() as String?
                var stringMessage = ""
                for i in 0..<dataMessages.count {
                    if dataMessages[i]["f_pin"] as? String != idMe && EditorGroup.conditionSendRead(scope: dataMessages[i][TypeDataMessage.message_scope_id] as! String, fPin: dataMessages[i][TypeDataMessage.f_pin] as! String, messageId: dataMessages[i][TypeDataMessage.message_id] as! String) {
                        let id = dataMessages[i]["message_id"]  as? String ?? ""
                        if !stringMessage.isEmpty {
                            stringMessage += ",\(id)"
                        } else {
                            stringMessage += id
                        }
                    }
                }
                if !stringMessage.isEmpty {
                    sendReadMessageStatus(
                        chat_id: "",
                        f_pin: dataPerson["f_pin"]!!,
                        message_scope_id: MessageScope.WHISPER,
                        message_id: stringMessage
                    )
                }
            }
            pendingInitialScrollToBottom = true
            tableChatView.scrollToBottom(isAnimated: false, delay: 0)
        } else {
            pendingInitialScrollToBottom = true
            tableChatView.scrollToBottom(isAnimated: false, delay: 0)
        }
        // The table used to be faded in from alpha 0 after 0.6s + 0.5s of animation, which is
        // where the blank screen on opening a chat came from. It was hiding the load; there is
        // no load left to hide.
        DispatchQueue.main.async { [weak self] in
            self?.isInitialLoading = false
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
    
    private func chatbot() {
        let containerChatbot = UIView()
        self.view.addSubview(containerChatbot)
        containerChatbot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerChatbot.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerChatbot.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            containerChatbot.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            containerChatbot.heightAnchor.constraint(equalToConstant: 120)
        ])
        containerChatbot.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
        
        let labelChatbot = UILabel()
        containerChatbot.addSubview(labelChatbot)
        labelChatbot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelChatbot.centerYAnchor.constraint(equalTo: containerChatbot.centerYAnchor),
            labelChatbot.centerXAnchor.constraint(equalTo: containerChatbot.centerXAnchor),
        ])
        labelChatbot.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        labelChatbot.font = UIFont.systemFont(ofSize: 12 + offset()).bold
        labelChatbot.text = "Interactive chatbot. Coming soon".localized()
    }
    
    private func changeAppBar() {
        let viewAppBar = UIView()
        viewAppBar.frame.size = CGSize(width: self.view.frame.size.width, height: 44)
        
        if !isSearching {
            let imageProfile = UIImageView(frame: CGRect(x: 0, y: 7, width: 30, height: 30))
            imageProfile.circle()
            imageProfile.clipsToBounds = true
            let pictureImage = dataPerson["picture"]!
            var count = 0
            if isContactCenter {
                if fPinContacCenter.isEmpty && isRequestContactCenter {
                    getImage(name: dataPerson["picture"]!!, placeholderImage: UIImage(systemName: "person.circle.fill")!) { result, isDownloaded, image in
                        imageProfile.image = image
                    }
                    viewAppBar.addSubview(imageProfile)
                } else {
                    if users.count == 1 {
                        viewAppBar.addSubview(imageProfile)
                        getImage(name: users[0].thumb, placeholderImage: UIImage(systemName: "person.circle.fill")!) { result, isDownloaded, image in
                            imageProfile.image = image
                            imageProfile.contentMode = .scaleAspectFit
                        }
                    } else {
                        for user in users {
                            if count == 3 {
                                count += 1
                                continue
                            }
                            if count == 0 {
                                let pictures = UIImageView(frame: CGRect(x: 0, y: 7, width: 30, height: 30))
                                pictures.circle()
                                pictures.clipsToBounds = true
                                viewAppBar.addSubview(pictures)
                                getImage(name: user.thumb, placeholderImage: UIImage(systemName: "person.circle.fill")!) { result, isDownloaded, image in
                                    pictures.image = image
                                    pictures.contentMode = .scaleAspectFit
                                }
                            } else {
                                let pictures = UIImageView(frame: CGRect(x: count * 20 , y: 7, width: 30, height: 30))
                                pictures.circle()
                                pictures.clipsToBounds = true
                                viewAppBar.addSubview(pictures)
                                getImage(name: user.thumb, placeholderImage: UIImage(systemName: "person.circle.fill")!) { result, isDownloaded, image in
                                    pictures.image = image
                                    pictures.contentMode = .scaleAspectFit
                                }
                            }
                            count += 1
                        }
                    }
                }
            } else if dataPerson["f_pin"]!! == "-999" {
                viewAppBar.addSubview(imageProfile)
                if !Utils.getIconDock().isEmpty {
                    let urlString = Utils.getUrlDock()!
                    if let cachedImage = ImageCache.shared.image(forKey: urlString) {
                        let imageData = cachedImage
                        imageProfile.image = imageData
                    } else {
                        DispatchQueue.global().async{
                            Utils.fetchDataWithCookiesAndUserAgent(from: URL(string: urlString)!) { data, response, error in
                                guard let data = data, error == nil else { return }
                                DispatchQueue.main.async() {
                                    if UIImage(data: data) != nil {
                                        let imageData = UIImage(data: data)!
                                        imageProfile.image = imageData
                                        ImageCache.shared.save(image: imageData, forKey: urlString)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    imageProfile.image = UIImage(named: "pb_button", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                }
                imageProfile.contentMode = .scaleAspectFit
            }
            else if (pictureImage != "" && pictureImage != nil) {
                viewAppBar.addSubview(imageProfile)
                imageProfile.setImage(name: pictureImage!)
                imageProfile.contentMode = .scaleAspectFill
            } else {
                viewAppBar.addSubview(imageProfile)
                imageProfile.image = UIImage(systemName: "person")
                imageProfile.contentMode = .scaleAspectFit
                imageProfile.backgroundColor = .lightGray
            }
            
            var titleNavigation = UILabel(frame: CGRect(x: 35, y: 0, width: viewAppBar.frame.size.width - 250, height: 44))
            if blocking == "-1" || blocking == "1" {
                titleNavigation = UILabel(frame: CGRect(x: 35, y: 0, width: viewAppBar.frame.size.width - 150, height: 44))
            } else if isContactCenter {
                titleNavigation = UILabel(frame: CGRect(x: 35, y: 0, width: viewAppBar.frame.size.width - 150, height: 44))
                if users.count > 0 {
                    titleNavigation = UILabel(frame: CGRect(x: 35 * (CGFloat(users.count)) - (CGFloat((users.count - 1) * 15)), y: 0, width: viewAppBar.frame.size.width - 150 - (35 * (CGFloat(users.count - 1)) - (CGFloat((users.count - 1) * 15))), height: 44))
                }
            }
            viewAppBar.addSubview(titleNavigation)
            if ((User.isOfficial(official_account: (dataPerson["isOfficial"] ?? "")!) || User.isOfficialRegular(official_account: (dataPerson["isOfficial"] ?? "")!)) && !isContactCenter) || ((User.isOfficial(official_account: (dataPerson["isOfficial"] ?? "")!) || User.isOfficialRegular(official_account: (dataPerson["isOfficial"] ?? "")!)) && fPinContacCenter.isEmpty) {
                var name = dataPerson["name"]!!
                if (isContactCenter) {
                    name = name + " " + "Contact Center".localized()
                    titleNavigation.text = name
                } else {
                    titleNavigation.set(image: UIImage(named: "ic_official_flag", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(name)", size: 15, y: -4)
                }
            } else if User.isVerified(official_account: (dataPerson["isOfficial"] ?? "")!) && !isContactCenter {
                let name = dataPerson["name"]!!
                titleNavigation.set(image: UIImage(named: "ic_verified", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(name)", size: 15, y: -4)
            } else if User.isInternal(userType: (dataPerson["user_type"] ?? "")!) && !isContactCenter {
                let name = dataPerson["name"]!!
                titleNavigation.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "  \(name)", size: 15, y: -4)
            } else {
                if !isContactCenter {
                    titleNavigation.text = dataPerson["name"] as? String
                } else {
                    if users.count == 1 {
                        titleNavigation.text = users[0].fullName
                    } else {
                        var stringName = ""
                        for user in users {
                            if stringName.isEmpty {
                                stringName = user.fullName
                            } else {
                                stringName += ", \(user.fullName)"
                            }
                        }
                        titleNavigation.text = stringName
                    }
                }
            }
            titleNavigation.textColor = .white
            titleNavigation.font = UIFont.systemFont(ofSize: 12 + offset()).bold
            navigationItem.titleView = viewAppBar
            titleText = titleNavigation.text
        } else {
            searchBar = UISearchBar()
            searchBar.autocapitalizationType = .none
            searchBar.delegate = self
            searchBar.searchTextField.tintColor = .mainColor
            searchBar.searchTextField.textColor = .black
            searchBar.showsCancelButton = false
//            searchBar.setMagnifyingGlassColorTo(color: .white)
//            searchBar.updateHeight(height: 36, radius: 18)
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
    
    private func getDataProfile(fPin: String) {
        var query = "SELECT f_pin, first_name || ' ' || last_name, official_account, image_id, device_id, offline_mode, user_type FROM BUDDY where f_pin = '\(fPin)'"
        if (isContactCenter && isRequestContactCenter) {
            query = "SELECT group_id, f_name, official, image_id FROM GROUPZ where group_type = 1 AND official = 1"
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    if cursorData.next() {
                        dataPerson["f_pin"] = cursorData.string(forColumnIndex: 0) ?? ""
                        dataPerson["name"] = (cursorData.string(forColumnIndex: 1) ?? "").trimmingCharacters(in: .whitespaces)
                        dataPerson["picture"] = cursorData.string(forColumnIndex: 3) ?? ""
                        dataPerson["isOfficial"] = cursorData.string(forColumnIndex: 2) ?? ""
                        if isContactCenter && isRequestContactCenter {
                            dataPerson["user_type"] = "0"
                        } else {
                            dataPerson["user_type"] = cursorData.string(forColumnIndex: 6) ?? ""
                        }
                    } else {
                        dataPerson["f_pin"] = "-999"
                        dataPerson["name"] = "Bot"
                        dataPerson["picture"] = ""
                        dataPerson["isOfficial"] = ""
                        dataPerson["deviceId"] = ""
                        dataPerson["isOffline"] = "0"
                        dataPerson["user_type"] = "0"
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func addDataMessage() {
        multipleOffsetUp += 1
        let queryCount = "SELECT COUNT(*) FROM MESSAGE where (f_pin='\(dataPerson["f_pin"]!!)' or l_pin='\(dataPerson["f_pin"]!!)') AND (message_scope_id = '\(MessageScope.WHISPER)' OR message_scope_id = '\(MessageScope.FORM)' OR message_scope_id = '\(MessageScope.CALL)' OR message_scope_id = '\(MessageScope.MISSED_CALL)') AND is_call_center = 0"
        let query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, is_call_center, call_center_id, opposite_pin, last_edited, gif_id, is_forwarded_message, attachment_speciality, is_pinned, is_bot FROM MESSAGE where (f_pin='\(dataPerson["f_pin"]!!)' or l_pin='\(dataPerson["f_pin"]!!)') AND (message_scope_id = '\(MessageScope.WHISPER)' OR message_scope_id = '\(MessageScope.FORM)' OR message_scope_id = '\(MessageScope.CALL)' OR message_scope_id = '\(MessageScope.MISSED_CALL)') AND is_call_center = 0 order by server_date asc LIMIT CASE WHEN (\(queryCount))-\(dataMessages.count)>=20 THEN 20*\(multipleOffsetUp-1) ELSE (\(queryCount))-\(dataMessages.count) END OFFSET CASE WHEN (\(queryCount))>=\(20*multipleOffsetUp) THEN (\(queryCount))-\(20*multipleOffsetUp) ELSE 0 END"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    var tempData: [[String: Any?]] = []
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
                        row[TypeDataMessage.is_bot] = cursorData.string(forColumnIndex: 28)
                        if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE_STATUS WHERE message_id='\(row["message_id"]  as? String ?? "")'") {
                            while cursorStatus.next() {
                                row["status"] = cursorStatus.string(forColumnIndex: 0)
                            }
                            cursorStatus.close()
                        }
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["video_id"]  as? String ?? "")
                            let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["file_id"]  as? String ?? "")
                            if ((row["video_id"]  as? String ?? "") != "") {
                                if FileManager.default.fileExists(atPath: videoURL.path) || FileEncryption.shared.isSecureExists(filename: videoURL.lastPathComponent){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            } else {
                                if FileManager.default.fileExists(atPath: fileURL.path) || FileEncryption.shared.isSecureExists(filename: fileURL.lastPathComponent){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            }
                        }
                        row["chat_date"] = chatDate(stringDate: row["server_date"]  as? String ?? "")
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
                        tempData.append(row)
                    }
                    if tempData.count != 0 && (dataMessages.firstIndex(where: { $0["message_id"] as? String == tempData[0]["message_id"] as? String }) == nil) {
                        let lastIndex = tempData.count - 1
                        for i in 0..<tempData.count {
                            dataMessages.insert(tempData[lastIndex - i], at: 0)
                            if dataMessages.firstIndex(where: { $0["chat_date"] as? String == tempData[lastIndex - i]["chat_date"] as? String }) != nil {
                                tableChatView.insertRows(at: [IndexPath(row: 0, section: currentIndexpath!.section)], with: .top)
                            } else {
                                tableChatView.insertSections(IndexSet(integer: 0), with: .top)
                                tableChatView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                            }
                            tableChatView.layoutIfNeeded()
                        }
                    }
                    cursorData.close()
                    gettingDataMessage = false
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
        // The double force unwrap this inherited (dataPerson["f_pin"]!!) used to be evaluated
        // once, when the conversation was read. It is now asked for by counts, positions,
        // searches and every page turn - including while the reader scrolls - so a moment
        // where the profile is not in hand yet would be a crash rather than an empty result.
        let personPin = dataPerson["f_pin"] as? String ?? ""
        if isContactCenter {
            if complaintId.isEmpty {
                return "(f_pin='\(personPin)' or l_pin='\(personPin)') AND message_scope_id = '\(MessageScope.CHATROOM)' AND broadcast_flag = 0 AND is_call_center = 1"
            }
            return "message_scope_id = '\(MessageScope.CHATROOM)' AND broadcast_flag = 0 AND is_call_center = 1 AND call_center_id = '\(complaintId)'"
        }
        return "(f_pin='\(personPin)' or l_pin='\(personPin)') AND (message_scope_id = '\(MessageScope.WHISPER)' OR message_scope_id = '\(MessageScope.FORM)' OR message_scope_id = '\(MessageScope.CALL)' OR message_scope_id = '\(MessageScope.MISSED_CALL)') AND is_call_center = 0"
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

    /// Position of a message within this conversation counting from the oldest, or nil when
    /// this conversation does not have it.
    private func messagePosition(messageId: String) -> Int64? {
        guard !messageId.isEmpty else {
            return nil
        }
        var position: Int64?
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
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
        // Fix: MESSAGE_STATUS used to be queried once per message inside the loop below - a
        // whole extra round trip through the database for every row read. It is a subquery
        // now, taking the newest status row exactly as that loop did (it kept the last one it
        // read). A subquery rather than a join on purpose: a message can have several status
        // rows, and a join would hand back the message once per row.
        let query = "SELECT m.message_id, m.f_pin, m.l_pin, m.message_scope_id, m.server_date, ifnull((SELECT s.status FROM MESSAGE_STATUS s WHERE s.message_id = m.message_id ORDER BY s._id DESC LIMIT 1), m.status), m.message_text, m.audio_id, m.video_id, m.image_id, m.thumb_id, m.read_receipts, m.chat_id, m.file_id, m.attachment_flag, m.reff_id, m.lock, m.is_stared, m.blog_id, m.credential, m.is_call_center, m.call_center_id, m.opposite_pin, m.last_edited, m.gif_id, m.is_forwarded_message, m.attachment_speciality, m.is_pinned, m.is_bot FROM MESSAGE m where \(self.messageWhereClause()) order by m.server_date asc LIMIT \(limit) OFFSET \(offset)"
        // Only while nothing is loaded yet, which is the first read. The contact centre
        // channel picker is a row that exists on screen only, and paging calls getData again -
        // without this it would be added once per page.
        if isContactCenter, dataMessages.isEmpty {
            if isRequestContactCenter && !isDirectCC {
                viewButton.isHidden = true
                viewTextfield.isHidden = true
                var row: [String: Any?] = [:]
                row["f_pin"] = nil
                row["message_id"] = ""
                row["chat_date"] = "Today".localized()
                let listStringName: [String] = ["Messaging".localized(), "Secure SMS".localized(), "VoIP Call".localized(), "Email".localized(), "Video Call".localized(), "GSM Call".localized(), "GPT Chatbot".localized(), "WhatsApp"]
                var data : [CategoryCC] = []
                let channels : [String] = ["0", "4", "1", "3", "2", "5", "7", "6"]
                if Utils.getDefaultCC() == "No" {
                    let category = CategoryCC.getDatafromParent(parent: CategoryCC.default_parent)
                    for i in 0..<category.count {
                        data.append(CategoryCC(id: "level0_\(i)", service_id: category[i].service_id, service_name: category[i].service_name, parent: category[i].parent, description: category[i].description, is_tablet: "0"))
                    }
                } else {
                    for i in 0..<listStringName.count {
                        data.append(CategoryCC(id: "level0_\(channels[i])", service_id: "", service_name: listStringName[i], parent: "\(i)", description: "", is_tablet: "0"))
                    }
                    row["attachment_flag"] = "503"
                }
                row["category_cc"] = data
                dataDates.append("Today".localized())
                dataMessages.append(row)
            } else if isDirectCC {
                dataDates.append("Today".localized())
            }
        }
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
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
                        row[TypeDataMessage.is_call_center] = cursorData.string(forColumnIndex: 20) ?? ""
                        row[TypeDataMessage.call_center_id] = cursorData.string(forColumnIndex: 21) ?? ""
                        row[TypeDataMessage.opposite_pin] = cursorData.string(forColumnIndex: 22) ?? ""
                        row[TypeDataMessage.last_edit] = cursorData.longLongInt(forColumnIndex: 23)
                        row[TypeDataMessage.gif_id] = cursorData.string(forColumnIndex: 24) ?? ""
                        row[TypeDataMessage.is_forwarded] = Int(cursorData.int(forColumnIndex: 25))
                        row[TypeDataMessage.spec_file] = cursorData.string(forColumnIndex: 26) ?? ""
                        row[TypeDataMessage.is_pinned] = cursorData.string(forColumnIndex: 27) ?? ""
                        row[TypeDataMessage.is_bot] = Int (cursorData.string(forColumnIndex: 28) ?? "0")
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["video_id"] as? String ?? "")
                            let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["file_id"] as? String ?? "")
                            if ((row["video_id"]  as? String ?? "") != "") {
                                if FileManager.default.fileExists(atPath: videoURL.path) || FileEncryption.shared.isSecureExists(filename: videoURL.lastPathComponent){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            } else {
                                if FileManager.default.fileExists(atPath: fileURL.path) || FileEncryption.shared.isSecureExists(filename: fileURL.lastPathComponent){
                                    row["progress"] = 100.0
                                } else {
                                    row["progress"] = 0.0
                                }
                            }
                        }
                        row["chat_date"] = chatDate(stringDate: row["server_date"]  as? String ?? "")
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
                        let isCollageCandidate = row["image_id"] != nil
                            && !(row["image_id"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && (row["message_text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && (row["reff_id"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && (row["credential"] as? String ?? "") != "1"
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
                                    || tempImages.count >= EditorPersonal.maximumImagesInCollage
                            } else {
                                breaksRun = false
                            }
                            if breaksRun {
                                closeImageGroup(&tempImages, loaded: &loaded)
                            }
                            tempImages.append(ImageGrouping(messageId: row["message_id"]  as? String ?? "", thumbId: row["thumb_id"]  as? String ?? "", imageId: row["image_id"]  as? String ?? "", status: row["status"]  as? String ?? "", time: row["server_date"]  as? String ?? "", lPin: row["l_pin"]  as? String ?? "", dataMessage: row, dataPerson: dataPerson, dataGroup: [:], dataTopic: [:]))
                        } else {
                            closeImageGroup(&tempImages, loaded: &loaded)
                        }
                        if marksFirstAsUnread && idxOff == 0 {
                            self.markerCounter = row["message_id"] as? String
                        }
                        loaded.append(row)
                        idxOff+=1
                    }
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
        // A contact centre session that has not been answered yet shows its header with no
        // messages under it.
        if isContactCenter, isDirectCC, !dataDates.contains("Today".localized()) {
            dataDates.append("Today".localized())
        }
    }

    /// Reads the newest page of the conversation - enough to fill the screen, and never less
    /// than everything still unread, because the unread marker and the read receipts sent on
    /// open both need those messages in hand.
    private func loadInitialMessages() {
        let total = countMessages()
        let pageSize = max(EditorPersonal.initialMessagePageSize, Int64(counter) + 10)
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
    /// Offsets into the conversation move whenever a message is deleted, and that can happen
    /// anywhere - this screen, another device. Two counts make every page that follows line
    /// up, instead of tracking every place a message can appear or disappear.
    private func refreshWindowBounds() {
        // Skipping rows without an id: the contact centre channel picker is a synthetic row
        // that exists only on screen.
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

        let newOffset = max(0, loadedOffset - EditorPersonal.olderMessagePageSize)
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
        let newOffset = max(0, min(position - EditorPersonal.jumpWindowSize / 2, max(0, total - EditorPersonal.jumpWindowSize)))
        let limit = max(0, min(EditorPersonal.jumpWindowSize, total - newOffset))
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
        let newOffset = max(0, total - EditorPersonal.initialMessagePageSize)
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
        let batch = min(EditorPersonal.olderMessagePageSize, total - nextOffset)
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
        if position < loadedOffset, loadedOffset - position <= EditorPersonal.maxBridgedMessages {
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
        guard !copySession, !forwardSession, !deleteSession, !summarizeSession, !removed else {
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
            messageInfoVC.dataPerson = dataPerson
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

    func chatDate(stringDate: String) -> String {
        let date = Date(milliseconds: Int64(stringDate)!)
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
                let formatter = EditorPersonal.chatDateFormatter(format: "EEEE", cached: &EditorPersonal.dayNameFormatter)
                let stringFormat = formatter.string(from: date)
                if !dataDates.contains(stringFormat){
                    dataDates.append(stringFormat)
                }
                return stringFormat
            } else {
                let formatter = EditorPersonal.chatDateFormatter(format: "EE, dd MMM", cached: &EditorPersonal.dayDateFormatter)
                let stringFormat = formatter.string(from: date as Date)
                if !dataDates.contains(stringFormat){
                    dataDates.append(stringFormat)
                }
                return stringFormat
            }
        }
    }
    
    // `useFakeProgress` - the upload path only hears from the server a couple of times
    // per file, so it pads what it shows to keep the ring moving. A download reports
    // real bytes continuously and must not be padded, or it would jump straight to
    // full on its second callback (maxFakeProgMultip is 2).
    func updateProgress(_ data: [AnyHashable : Any], useFakeProgress: Bool = true){
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
                let progress = max(data["progress"] as! Double, fakeProgress)
                if(data["progress"] as! Double == 100.0){
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
                                    if let loading = containerView?.layer.sublayers?[1] as? CAShapeLayer {
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
                    let progress = max(data["progress"] as! Double, fakeProgress)
                    if(data["progress"] as! Double == 100.0){
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
            // What is missing is worked out from the loaded window rather than from
            // dataMessages.count - image collages take rows out of that list, and with paging
            // it no longer covers the whole conversation either.
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
    
    func dismissAllPresentedViewControllers(completion: (() -> Void)? = nil) {
        if let presented = self.presentedViewController {
            presented.dismiss(animated: true) {
                self.dismissAllPresentedViewControllers(completion: completion)
            }
        } else {
            completion?()
        }
    }
    
    @objc func onReceiveMessage(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let chatData = dataMessage.mBodies
                if (dataMessage.getCode() == CoreMessage_TMessageCode.PUSH_MEMBER_ROOM_CONTACT_CENTER && isContactCenter) {
                    let data = dataMessage.getBody(key: CoreMessage_TMessageKey.DATA)
                    if !data.isEmpty {
                        if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                            var members = ""
                            let idMe = User.getMyPin()!
                            var user : [User] = []
                            for json in jsonArray {
                                if "\(json)" != idMe {
                                    if members.isEmpty {
                                        members = "\(json)"
                                    } else {
                                        members += ",\(json)"
                                    }
                                    if let userData = User.getData(pin: "\(json)") {
                                        user.append(userData)
                                    } else {
                                        Nexilis.addFriend (fpin: "\(json)") { result in
                                            DispatchQueue.main.async {
                                                if result {
                                                    let userData = User.getData(pin: "\(json)")!
                                                    user.append(userData)
                                                } else {
                                                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                                    imageView.tintColor = .white
                                                    let banner = FloatingNotificationBanner(title: "Server busy, please try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                                    banner.show()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            self.users = user
                            self.fPinContacCenter = members
                            self.changeAppBar()
                            SecureUserDefaults.shared.set(members, forKey: "inEditorPersonal")
                        }
                    }
                } else if (dataMessage.getCode() == CoreMessage_TMessageCode.ACCEPT_CALL_CENTER) {
                    if !self.isRequestContactCenter || !isContactCenter {
                        return
                    }
                    SecureUserDefaults.shared.set(dataMessage.getBody(key: CoreMessage_TMessageKey.F_PIN), forKey: "inEditorPersonal")
                    let date = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                    self.fPinContacCenter = dataMessage.getBody(key: CoreMessage_TMessageKey.F_PIN)
                    self.complaintId = dataMessage.getBody(key: CoreMessage_TMessageKey.DATA)
                    self.channelContactCenter = dataMessage.getBody(key: CoreMessage_TMessageKey.CHANNEL)
                    var row: [String: Any?] = [:]
                    row["category_cc"] = "You are connecting with ".localized() + dataMessage.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME).trimmingCharacters(in: .whitespaces) + " at ".localized() + formatter.string(from: date as Date) + ".\n" + "In order to improve our service, all conversations will be recorded\naccording to state regulations".localized()
                    row["message_id"] = ""
                    row["message_text"] = "You are connecting with ".localized() + dataMessage.getBody(key: CoreMessage_TMessageKey.F_DISPLAY_NAME).trimmingCharacters(in: .whitespaces) + " at ".localized() + formatter.string(from: date as Date) + ".\n" + "In order to improve our service, all conversations will be recorded\naccording to state regulations".localized()
                    row["chat_date"] = "Today".localized()
                    self.dataMessages.append(row)
                    self.users.append(User.getData(pin: dataMessage.getBody(key: CoreMessage_TMessageKey.F_PIN))!)
                    self.changeAppBar()
                    self.setRightButtonItem()
                    self.dateStartCC = "\(Date().currentTimeMillis())"
                    self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.count - 1, section: 0)], with: .none)
                    self.tableChatView.layoutIfNeeded()
                    self.tableChatView.scrollToBottom()
                    SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
                    if dataMessage.getBody(key: CoreMessage_TMessageKey.CHANNEL) != "0" {
                        SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: "startTimeCC")
                        SecureUserDefaults.shared.set(dataMessage.getBody(key: CoreMessage_TMessageKey.CHANNEL), forKey: "channelCC")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                            self.dismiss(animated: true, completion: {
                                self.removeAllObjectBeforeDismissVC()
                            })
                        })
                    } else {
                        viewButton.isHidden = false
                        viewTextfield.isHidden = false
                    }
                } else if (dataMessage.getCode() == CoreMessage_TMessageCode.INVITE_END_CONTACT_CENTER || dataMessage.getCode() == CoreMessage_TMessageCode.END_CALL_CENTER || dataMessage.getCode() == CoreMessage_TMessageCode.INVITE_EXIT_CONTACT_CENTER  || dataMessage.getCode() == CoreMessage_TMessageCode.TIMEOUT_CONTACT_CENTER) && !fromVCAC {
                    let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                    if onGoingCC.isEmpty || !isContactCenter {
                        return
                    }
                    let requester = onGoingCC.components(separatedBy: ",")[0]
                    let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                    let fPin = dataMessage.getCode() == CoreMessage_TMessageCode.END_CALL_CENTER ? chatData[CoreMessage_TMessageKey.F_PIN] : dataMessage.getPIN()
                    if fPin == officer || fPin == requester {
                        DispatchQueue.global().async {
                            let date = "\(Date().currentTimeMillis())"
                            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                do {
                                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", cvalues: [
                                        "type" : self.channelContactCenter,
                                        "title" : "Contact Center".localized(),
                                        "time" : self.dateStartCC,
                                        "f_pin" : officer,
                                        "data" : self.complaintId,
                                        "time_end" : date,
                                        "complaint_id" : self.complaintId,
                                        "members" : "",
                                        "requester": requester
                                    ], replace: true)
                                } catch {
                                    rollback.pointee = true
                                    print("Access database error: \(error.localizedDescription)")
                                }
                            })
                        }
                        self.dismissKeyboard()
                        self.disableEditor()
                        SecureUserDefaults.shared.removeValue(forKey: "onGoingCC")
                        SecureUserDefaults.shared.removeValue(forKey: "membersCC")
                        SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Call Center Session has ended".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                        timeoutCC.invalidate()
                        self.dismissAllPresentedViewControllers {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                self.dismiss(animated: true, completion: {
                                    self.removeAllObjectBeforeDismissVC()
                                })
                            })
                        }
                    } else {
                        var members = ""
                        self.users.removeAll(where: {$0.pin == fPin})
                        for user in self.users {
                            if members.isEmpty {
                                members = "\(user.pin)"
                            } else {
                                members = ",\(user.pin)"
                            }
                        }
                        SecureUserDefaults.shared.set("\(members)", forKey: "membersCC")
                        self.fPinContacCenter = members
                        self.changeAppBar()
                    }
                }
                else if (chatData[CoreMessage_TMessageKey.F_PIN] == self.dataPerson["f_pin"]!! && !self.isContactCenter && (chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] == MessageScope.WHISPER)) || (self.isContactCenter && chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] == "5" && self.complaintId == chatData[CoreMessage_TMessageKey.CALL_CENTER_ID]) {
                    if chatData[CoreMessage_TMessageKey.F_PIN] == nil {
                        return
                    }
                    let idx = self.dataMessages.firstIndex(where: { $0[TypeDataMessage.message_id] as? String == chatData[CoreMessage_TMessageKey.MESSAGE_ID]})
                    if idx != nil {
                        self.dataMessages[idx!][TypeDataMessage.message_text] = chatData[CoreMessage_TMessageKey.MESSAGE_TEXT]
                        self.dataMessages[idx!][TypeDataMessage.last_edit] = Int64(chatData[CoreMessage_TMessageKey.LAST_EDIT]!)
                        self.dataMessages[idx!][TypeDataMessage.status] = chatData[CoreMessage_TMessageKey.STATUS]
                        let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                        let row = self.messages(onDate: self.dataMessages[idx!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                        if row != nil && section != nil  {
                            self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                        }
                        return
                    }
                    var row: [String: Any?] = [:]
                    row["message_id"] = chatData[CoreMessage_TMessageKey.MESSAGE_ID]
                    row["f_pin"] = chatData[CoreMessage_TMessageKey.F_PIN]
                    row["l_pin"] = chatData[CoreMessage_TMessageKey.L_PIN]
                    row["message_scope_id"] = chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]
                    row["server_date"] = chatData[CoreMessage_TMessageKey.SERVER_DATE]
                    row["status"] = chatData[CoreMessage_TMessageKey.STATUS]
                    row["message_text"] = chatData[CoreMessage_TMessageKey.MESSAGE_TEXT]
                    if (chatData.keys.contains(CoreMessage_TMessageKey.AUDIO_ID)) {
                        row["audio_id"] = chatData[CoreMessage_TMessageKey.AUDIO_ID]
                    } else {
                        row["audio_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.GIF_ID)) {
                        row["gif_id"] = chatData[CoreMessage_TMessageKey.GIF_ID]
                    } else {
                        row["gif_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.VIDEO_ID)) {
                        row["video_id"] = chatData[CoreMessage_TMessageKey.VIDEO_ID]
                    } else {
                        row["video_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.IMAGE_ID)) {
                        row["image_id"] = chatData[CoreMessage_TMessageKey.IMAGE_ID]
                    } else {
                        row["image_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.THUMB_ID)) {
                        row["thumb_id"] = chatData[CoreMessage_TMessageKey.THUMB_ID]
                    } else {
                        row["thumb_id"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.READ_RECEIPTS)) {
                        row["read_receipts"] = chatData[CoreMessage_TMessageKey.READ_RECEIPTS]
                    } else {
                        row["read_receipts"] = ""
                    }
                    if (chatData.keys.contains(CoreMessage_TMessageKey.CREDENTIAL)) {
                        row["credential"] = chatData[CoreMessage_TMessageKey.CREDENTIAL]
                    } else {
                        row["credential"] = ""
                    }
                    row["chat_id"] = ""
                    if (chatData.keys.contains(CoreMessage_TMessageKey.FILE_ID)) {
                        row["file_id"] = chatData[CoreMessage_TMessageKey.FILE_ID]
                    } else {
                        row["file_id"] = ""
                    }
                    row["progress"] = 0.0
                    row["attachment_flag"] = chatData[CoreMessage_TMessageKey.ATTACHMENT_FLAG]
                    row["reff_id"] = chatData[CoreMessage_TMessageKey.REF_ID] ?? ""
                    row["lock"] = ""
                    row["is_stared"] = "0"
                    row[TypeDataMessage.spec_file] = chatData[CoreMessage_TMessageKey.ATTACHMENT_SPECIALITY]
                    row[TypeDataMessage.is_forwarded] = Int(chatData[CoreMessage_TMessageKey.IS_FORWARDED_MESSAGE] ?? "0")
                    row[TypeDataMessage.is_bot] = Int(chatData[CoreMessage_TMessageKey.IS_BOT] ?? "0")
                    row["isSelected"] = false
                    // A message arriving while the reader is looking at an older part of the
                    // chat must not be spliced onto the end of a window that does not reach
                    // the newest message. It is in the database; the scroll-to-bottom button
                    // is the way to it.
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
                    if !self.dataDates.contains("Today".localized()) {
                        self.dataDates.append("Today".localized())
                        self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .none)
                    }
                    row["chat_date"] = "Today".localized()
                    row["blog_id"] = chatData[CoreMessage_TMessageKey.BLOG_ID]
//                    self.counter += 1
                    self.counter = 0
                    self.updateCounter(counter: self.counter)
                    if row["credential"] != nil && row["credential"]  as? String ?? "" == "1" {
                        self.listTimerCredential[row["message_id"]  as? String ?? ""] = 60
                    }
                    if let collageRow = self.foldIntoImageGroup(row) {
                        // Part of the run above it: no new row goes in, the row that draws the
                        // collage is redrawn to take it.
                        self.tableChatView.reloadRows(at: [collageRow], with: .none)
                    } else {
                        self.dataMessages.append(row)
                        self.tableChatView.insertRows(at: [IndexPath(row: self.messages(onDate: self.dataDates[self.dataDates.count - 1]).count - 1, section: self.dataDates.count - 1)], with: .none)
                    }
                    self.tableChatView.layoutIfNeeded()
                    if row["credential"] != nil && row["credential"]  as? String ?? "" == "1" {
                        var timer = Timer()
                        var minute = 60
                        self.timerCredential[row["message_id"]  as? String ?? ""] = timer
                        SecureUserDefaults.shared.set("\(Date().currentTimeMillis())", forKey: row["message_id"]  as? String ?? "")
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {_ in
                            minute -= 1
                            self.listTimerCredential[row["message_id"]  as? String ?? ""] = minute
                            if minute == 0 {
                                timer.invalidate()
                                self.listTimerCredential.removeValue(forKey: row["message_id"]  as? String ?? "")
                                self.timerCredential.removeValue(forKey: row["message_id"]  as? String ?? "")
                                SecureUserDefaults.shared.removeValue(forKey: row["message_id"]  as? String ?? "")
                                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == row["message_id"] as? String})
                                if idx != nil {
                                    self.dataMessages[idx!]["lock"] = "2"
                                    self.dataMessages[idx!]["reff_id"] = ""
                                }
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
                            }
                            let section = self.dataDates.firstIndex(of: self.dataDates[self.dataDates.count - 1])
                            let row = self.messages(onDate: self.dataDates[self.dataDates.count - 1]).firstIndex(where: { $0["message_id"] as? String == row["message_id"] as? String})
                            if row != nil && section != nil{
                                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                            }
                        })
                    }
                    if self.isContactCenter {
                        let idMe = User.getMyPin()!
                        let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                        let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                        if officer == idMe {
                            self.timeoutCC.invalidate()
                        } else if !fromVCAC {
                            if !self.showToast30s {
                                self.view.makeToast("Please reply within 60 seconds so the call center session doesn't end.".localized(), duration: 3)
                                sendTyping(l_pin: fPinContacCenter, isTyping: true)
                                self.showToast30s = true
                            }
                        }
                    }
                    if chatData[CoreMessage_TMessageKey.FORMAT] == "1" {
                        self.sendReadMessageStatus(chat_id: "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        self.tableChatView.scrollToBottom()
                    } else if self.currentIndexpath?.row == (self.dataMessages.count - 2) {
                        if (self.viewIfLoaded?.window != nil) {
                            self.sendReadMessageStatus(chat_id: "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        }
                        self.tableChatView.scrollToBottom()
                        if ( self.currentIndexpath!.section <= self.dataDates.count - 1 && self.currentIndexpath!.row <= self.messages(onDate: self.dataDates[self.dataDates.count - 1]).count - 1)  {
                            self.counter = 0
                            self.updateCounter(counter: self.counter)
                        }
                        let lastMarkerCounter = markerCounter
                        if self.markerCounter != nil {
                            self.markerCounter = nil
                        }
                        let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == lastMarkerCounter })
                        if indexMessage != nil {
                            let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "")
                            let row = self.messages(onDate: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                            if row != nil && section != nil  {
                                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                            }
                        }
                    }
                    else if self.currentIndexpath == nil {
                        self.counter = 0
                        self.updateCounter(counter: self.counter)
                        if (self.viewIfLoaded?.window != nil) {
                            self.sendReadMessageStatus(chat_id: "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        }
                    }
                    else if self.counter != 0 {
                        if !self.indicatorCounterBSTB.isDescendant(of: self.view) && self.buttonScrollToBottom.isDescendant(of: self.view) {
                            self.markerCounter = row["message_id"] as? String
                            DispatchQueue.main.async { [self] in
                                self.addCounterAtButttonScrollToBottom()
                            }
                            let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.markerCounter })
                            if indexMessage != nil {
                                let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "")
                                let row = self.messages(onDate: self.dataMessages[indexMessage!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                        } else if self.indicatorCounterBSTB.isDescendant(of: self.view) {
                            self.labelCounter.text = "\(self.counter)"
                        }
                    }
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                }
            } else if !self.isContactCenter {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
            }
        }
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
        labelDisable.text = "Call center session is over".localized()
    }
    
    @objc func onStatusChat(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let chatData = dataMessage.mBodies
                let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                let requester = onGoingCC.components(separatedBy: ",")[0]
                let idMe = User.getMyPin()!
                if chatData[CoreMessage_TMessageKey.F_PIN] == self.dataPerson["f_pin"]!! || chatData[CoreMessage_TMessageKey.L_PIN] == self.dataPerson["f_pin"]!! || chatData[CoreMessage_TMessageKey.L_PIN] == self.fPinContacCenter || requester == idMe {
                    if (chatData.keys.contains(CoreMessage_TMessageKey.MESSAGE_ID) && !(chatData[CoreMessage_TMessageKey.MESSAGE_ID]!).contains("-2,")) {
                        var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! })
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
    
    @objc func onRefreshCallLog(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            let messageId = data["message_id"]  as? String ?? ""
            let pin = data["pin"]  as? String ?? ""
            if pin == self.dataPerson["f_pin"]!! {
                self.appendNewMessage(messageId: messageId)
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
            if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential, is_call_center, call_center_id, opposite_pin, last_edited, gif_id, is_forwarded_message, attachment_speciality, is_pinned, is_bot from MESSAGE where message_id = '\(messageId)'"), cursorData.next() {
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
                row[TypeDataMessage.is_bot] = Int (cursorData.string(forColumnIndex: 28) ?? "0")
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
    
    private func updateStatusDelete(idx: Int?, chatData: [String: String]) {
        self.closeContextMenuIfNeeded()
        do {
            if self.dataMessages[idx!]["lock"] != nil && self.dataMessages[idx!]["lock"]  as? String ?? "" == "1" {
                return
            }
            self.dataMessages[idx!]["lock"] = "1"
            self.dataMessages[idx!]["reff_id"] = ""
            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
            let row = self.messages(onDate: self.dataMessages[idx!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
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
            let row = self.messages(onDate: self.dataMessages[idx!]["chat_date"]  as? String ?? "").firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
            if row != nil && section != nil  {
                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
            }
        } catch {
        }
    }
    
    @objc func onTyping(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            let message: TMessage = data["message"] as! TMessage
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            if !onGoingCC.isEmpty {
                let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                if message.getBody(key: CoreMessage_TMessageKey.F_PIN) != officer {
                    //print("RESET TIMER")
//                    timeoutCC.invalidate()
//                    timeoutCC = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false, block: {_ in
//                        let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
//                        imageView.tintColor = .white
//                        let banner = FloatingNotificationBanner(title: "Customer doesn't respond in 30 second, so call center session will be ended automatically.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
//                        banner.show()
//                        self.endCallCenter()
//                    })
                }
            } else {
                
            }
        }
    }
    
    @objc func onUnfriend(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        DispatchQueue.main.async { [self] in
            if data["state"] as! Int == 99 && (data["message"]  as? String ?? "").components(separatedBy: ",")[0] == "delete_buddy" {
                removed = true
                if forwardSession || copySession || deleteSession || summarizeSession || isSearching {
                    cancelAction()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {[self] in
                    navigationItem.rightBarButtonItem = nil
                    navigationItem.rightBarButtonItems = nil
                    changeAppBar()
                    view.addSubview(containerAction)
                    containerAction.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        containerAction.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        containerAction.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        containerAction.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                        containerAction.heightAnchor.constraint(equalToConstant: 120)
                    ])
                    containerAction.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
                    let labelUnfriend = UILabel()
                    containerAction.addSubview(labelUnfriend)
                    labelUnfriend.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        labelUnfriend.centerYAnchor.constraint(equalTo: containerAction.centerYAnchor),
                        labelUnfriend.centerXAnchor.constraint(equalTo: containerAction.centerXAnchor),
                    ])
                    labelUnfriend.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                    labelUnfriend.font = UIFont.systemFont(ofSize: 12 + offset()).bold
                    labelUnfriend.text = "You have unfriended this user".localized()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
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
            } else if data["state"] as! Int == 01 {
                if let dataMessage = try! JSONSerialization.jsonObject(with: (data["message"]  as? String ?? "").data(using: .utf8)!, options: []) as? [String: String] {
                    if(dataMessage["l_pin"] == dataPerson["f_pin"]!){
                        if let block = dataMessage["block"] {
                            if(block == "-1"){
                                dismissKeyboard()
                            }
                            blockedView(blocked: block)
                            if contactChatNav.viewIfLoaded?.window != nil {
                                contactChatNav.dismiss(animated: true)
                            }
                            cancelAction()
                        }
                    }
                    setRightButtonItem()
                }
            }
        }
    }
    
    func blockedView(blocked: String) {
        dismissKeyboard()
        view.addSubview(containerAction)
        containerAction.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerAction.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            containerAction.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            containerAction.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            containerAction.heightAnchor.constraint(equalToConstant: 120)
        ])
        containerAction.backgroundColor = .secondaryColor.withAlphaComponent(0.8)
        let labelBlocked = UILabel()
        containerAction.addSubview(labelBlocked)
        labelBlocked.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelBlocked.centerYAnchor.constraint(equalTo: containerAction.centerYAnchor),
            labelBlocked.centerXAnchor.constraint(equalTo: containerAction.centerXAnchor),
        ])
        labelBlocked.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        labelBlocked.font = UIFont.systemFont(ofSize: 12 + offset()).bold
        if blocked == "1" {
            labelBlocked.text = "You blocked this user".localized()
        } else {
            labelBlocked.text = "You have been blocked by this user".localized()
        }
    }
    
    @objc func seeProfileTapped() {
        if dataPerson["f_pin"] == "-999" || dataPerson["isOfficial"] == "1" || removed || copySession || forwardSession || deleteSession || summarizeSession || isContactCenter {
            return
        }
        dismissKeyboard()
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
        controller.data = dataPerson["f_pin"]!!
        controller.checkReadMessage = {
            self.dataPerson.removeAll()
            self.getDataProfile(fPin: self.unique_l_pin)
            self.changeAppBar()
            if self.currentIndexpath == nil {
                var listData = self.dataMessages
                listData = listData.filter({$0["status"]  as? String ?? "" != "4" && $0["status"]  as? String ?? "" != "8"})
                if listData.count != 0 && !self.isContactCenter {
                    let idMe = User.getMyPin() as String?
                    for i in 0...listData.count - 1 {
                        if listData[i]["f_pin"] as? String != idMe && EditorGroup.conditionSendRead(scope: listData[i][TypeDataMessage.message_scope_id] as! String, fPin: listData[i][TypeDataMessage.f_pin] as! String, messageId: listData[i][TypeDataMessage.message_id] as! String) {
                            self.sendReadMessageStatus(chat_id: "", f_pin: self.dataPerson["f_pin"]!!, message_scope_id: MessageScope.WHISPER, message_id: listData[i]["message_id"]  as? String ?? "")
                        }
                    }
                }
            } else {
                let dataMessages = self.messages(onDate: self.dataDates[self.currentIndexpath!.section])
                var listData = dataMessages
                listData = listData.filter({$0["status"]  as? String ?? "" != "4" && $0["status"]  as? String ?? "" != "8"})
                if listData.count != 0 && !self.isContactCenter {
                    let idMe = User.getMyPin() as String?
                    for i in 0...listData.count - 1 {
                        if listData[i]["f_pin"] as? String != idMe && EditorGroup.conditionSendRead(scope: listData[i][TypeDataMessage.message_scope_id] as! String, fPin: listData[i][TypeDataMessage.f_pin] as! String, messageId: listData[i][TypeDataMessage.message_id] as! String) {
                            self.sendReadMessageStatus(chat_id: "", f_pin: self.dataPerson["f_pin"]!!, message_scope_id: MessageScope.WHISPER, message_id: listData[i]["message_id"]  as? String ?? "")
                        }
                    }
                }
            }
        }
        navigationController?.show(controller, sender: nil)
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
        if isContactCenter && fPinContacCenter.isEmpty && isRequestContactCenter {
            return
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
                if isContactCenter && channelContactCenter == "2" {
                    self.view.makeToast("You can't take photo when Video Call".localized(), duration: 3)
                    return
                }
                imageVideoPicker.present(source: .imageCamera)
            case "videoCamera":
                if isContactCenter && channelContactCenter == "2" {
                    self.view.makeToast("You can't take video when Video Call".localized(), duration: 3)
                    return
                }
                imageVideoPicker.present(source: .videoCamera)
            default:
                break
            }
        }
    }
    
    @IBAction func photoTapped(_ sender: UIButton) {
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        if isContactCenter && fPinContacCenter.isEmpty && isRequestContactCenter {
            return
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
        if isContactCenter && fPinContacCenter.isEmpty && isRequestContactCenter {
            return
        }
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
        if isContactCenter && fPinContacCenter.isEmpty && isRequestContactCenter {
            return
        }
        if (self.constraintBottomAttachment.constant != 0.0) {
            constraintBottomAttachment.constant = 0.0
            self.viewSticker.removeConstraints(self.viewSticker.constraints)
            self.viewSticker.removeFromSuperview()
        }
        documentPicker.present()
    }
    
    @objc func sendTapped() {
        sendChat(message_text: textFieldSend.text!, viewController: self)
    }
    
    @objc func showChooserACKConfidential() {
//        dismissKeyboard()
        let alertController = LibAlertController(title: "Message Mode".localized(), message: "Select".localized() + " " + "Message Mode".localized(), preferredStyle: .actionSheet)
        let imageConfidential = resizeImage(image: UIImage(named: "pb_icon_conf_msg_on", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let imageAck = resizeImage(image: UIImage(named: "pb_icon_ack_msg_on", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
        let imageSecret = resizeImage(image: UIImage(named: "pb_icon_secret_msg_on", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal)
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
            if self.isSecret {
                self.isSecret = false
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
            if self.isSecret {
                self.isSecret = false
            }
        })
        let secretAction = UIAlertAction(title: "Secret Message".localized(), style: .default, handler: { (UIAlertAction) in
            self.isSecret = !self.isSecret
            if self.isSecret {
                self.buttonAckConfidential.setImage(imageSecret, for: .normal)
            } else {
                self.buttonAckConfidential.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white).withRenderingMode(.alwaysTemplate), for: .normal)
            }
            if self.isConfidential {
                self.isConfidential = false
            }
            if self.isAck {
                self.isAck = false
            }
        })
        let stickerAction = UIAlertAction(title: "Open Sticker".localized(), style: .default, handler: { (UIAlertAction) in
            self.stickerTapped(UIButton())
        })
        confidentialAction.setValue(imageConfidential, forKey: "image")
        ackAction.setValue(imageAck, forKey: "image")
        secretAction.setValue(imageSecret, forKey: "image")
        secretAction.setValue(imageSecret, forKey: "image")
        stickerAction.setValue(imageSticker, forKey: "image")
        alertController.addAction(confidentialAction)
        alertController.addAction(ackAction)
        alertController.addAction(secretAction)
//        alertController.addAction(stickerAction)
        alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (UIAlertAction) in
            self.isConfidential = false
            self.isAck = false
            self.isSecret = false
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
    
    @objc func addRoom(sender: UIBarButtonItem) {
        let controller = QmeraCallContactViewController()
        controller.isDismiss = { user in
            DispatchQueue.global().async {
                let myPin = User.getMyPin() ?? ""
                let myUser = User.getDataCanNil(pin: myPin)
                _ = Nexilis.write(message: CoreMessage_TMessageBank.getCCRoomInvite(l_pin: user.pin, ticket_id: self.complaintId, channel: self.channelContactCenter, f_name: myUser == nil ? user.fullName : myUser!.fullName, f_thumb: myUser == nil ? user.thumb : myUser!.thumb))
            }
        }
        controller.selectedUser.append(contentsOf: users)
        controller.isInviteCC = true
        self.navigationController?.show(controller, sender: nil)
    }
    
    @objc func audioVideoCall(sender: UIBarButtonItem) {
        if sender.tag == 0 {
            if APIS.blockedByCallInProgress() {
                return
            }
            if !Nexilis.checkingAccess(key: "audio_call") {
                self.view.makeToast("Feature disabled..".localized(), duration: 3)
                return
            }
            let goAudioCall = Nexilis.checkMicPermission()
            if !goAudioCall{
                let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow microphone permission in your settings".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {_ in
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }))
                self.navigationController?.present(alert, animated: true, completion: nil)
                return
            }
            if let pin = dataPerson["f_pin"] {
                if !CheckConnection.isConnectedToNetwork() {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                let controller = QmeraAudioViewController()
                controller.user = User.getData(pin: pin)
                controller.isOutgoing = true
                controller.modalPresentationStyle = .overCurrentContext
                present(controller, animated: true, completion: nil)
            }
        } else {
            if APIS.blockedByCallInProgress() {
                return
            }
            if !Nexilis.checkingAccess(key: "video_call") {
                self.view.makeToast("Feature disabled..".localized(), duration: 3)
                return
            }
            let goAudioCall = Nexilis.checkMicPermission()
            let goVideoCall = Nexilis.checkCameraPermission()
            if goVideoCall == 0 {
                let alert = LibAlertController(title: "Attention!".localized(), message: !goAudioCall && goVideoCall == 0 ? "Please allow microphone & camera permission in your settings".localized() : !goAudioCall ? "Please allow microphone permission in your settings".localized() : "Please allow camera permission in your settings", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {_ in
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }))
                self.navigationController?.present(alert, animated: true, completion: nil)
                return
            } else if goVideoCall == -1 {
                return
            }
            if !CheckConnection.isConnectedToNetwork() {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            let videoVC = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "videoVCQmera") as! QmeraVideoViewController
            videoVC.dataPerson.append(dataPerson)
            self.show(videoVC, sender: nil)
        }
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
    
    @objc func didTapExit() {
        if complaintId.isEmpty || fromVCAC {
            self.dismiss(animated: true, completion: {
                self.removeAllObjectBeforeDismissVC()
            })
        } else if !complaintId.isEmpty {
            let alert = LibAlertController(title: "Interaction with Call Center is in progress".localized(), message: "Are you sure you want to end the Call Center?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                self.endCallCenter()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func removeAllObjectBeforeDismissVC() {
        cancelAllReadStatusTasks()
        for timer in self.timerCredential.values {
            timer.invalidate()
        }
        self.timeoutCC.invalidate()
        SecureUserDefaults.shared.removeValue(forKey: "inEditorPersonal")
        NotificationCenter.default.removeObserver(self)
        self.removeFromParent()
        if !self.isContactCenter {
            let l_pin = self.dataPerson["f_pin"]!!
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
    }
    
    public func endCallCenter() {
        timeoutCC.invalidate()
        let complaintId = self.complaintId
        let idMe = User.getMyPin()!
        let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
        let requester = onGoingCC.components(separatedBy: ",")[0]
        let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
        DispatchQueue.global().async {
            let date = "\(Date().currentTimeMillis())"
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = try Database.shared.insertRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", cvalues: [
                        "type" : self.channelContactCenter,
                        "title" : "Contact Center".localized(),
                        "time" : self.dateStartCC,
                        "f_pin" : officer,
                        "data" : self.complaintId,
                        "time_end" : date,
                        "complaint_id" : self.complaintId,
                        "members" : "",
                        "requester": requester
                    ], replace: true)
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            if officer == idMe {
                _ = Nexilis.write(message: CoreMessage_TMessageBank.endCallCenter(complaint_id: complaintId, l_pin: requester))
            } else {
                if requester == idMe {
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.endCallCenter(complaint_id: complaintId, l_pin: officer))
                } else {
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.leaveCCRoomInvite(ticket_id: complaintId))
                }
            }
            SecureUserDefaults.shared.removeValue(forKey: "onGoingCC")
            SecureUserDefaults.shared.removeValue(forKey: "membersCC")
            SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
        }
        self.dismiss(animated: true, completion: {
            self.removeAllObjectBeforeDismissVC()
        })
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
                if isSearching {
                    // Search jumps to the newest match's end of the list on purpose.
                    self.tableChatView.scrollToBottom()
                }
            }
        } else if isEditingMessage {
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
    
    private func sendChat(message_scope_id:String =  MessageScope.WHISPER, status:String =  "1", message_text:String =  "", credential:String = "0", attachment_flag: String = "0", ex_blog_id: String = "", message_large_text: String = "", ex_format: String = "", image_id: String = "", audio_id: String = "", video_id: String = "", file_id: String = "", thumb_id: String = "", reff_id: String = "", read_receipts: String = "4", chat_id: String = "", is_call_center: String = "0", call_center_id: String = "", viewController: UIViewController, isAutoSendCC : Bool = false, gif_id: String = "", is_forwarded: Int = 0, is_secret: Int = 0) {
        if viewController is EditorPersonal && file_id == "" && dataMessageForward == nil && !isAutoSendCC{
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
        var is_call_center = is_call_center
        var call_center_id = call_center_id
        var l_pin = dataPerson["f_pin"]!!
        var message_scope_id = message_scope_id
        var chat_id = chat_id
        
        if (isContactCenter) {
            if fPinContacCenter.isEmpty && isRequestContactCenter {
                if textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized() && textFieldSend.textColor != UIColor.lightGray && constraintBottomAttachment.constant == 0 {
                    textFieldSend.text = "Send message".localized()
                    textFieldSend.textColor = UIColor.lightGray
                } else if constraintBottomAttachment.constant != 0 {
                    textFieldSend.text = ""
                }
                dismissKeyboard()
                self.view.makeToast("Unable to send message. Waiting for the officer to accept your request".localized(), duration: 3)
                return
            }
            is_call_center = "1"
            call_center_id = complaintId
            l_pin = fPinContacCenter
            message_scope_id = MessageScope.CHATROOM
            chat_id = complaintId
            if isAutoSendCC {
                timeoutCC = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false, block: {_ in
                    let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Customer doesn't respond in 60 second, so call center session will be ended automatically.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                    banner.show()
                    self.endCallCenter()
                })
            }
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
        var opposite_pin = ""
        if isContactCenter {
            opposite_pin = ""
        } else {
            opposite_pin = l_pin
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
        var is_secret = is_secret
        if isSecret {
            is_secret = 1
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
        sendTyping(l_pin: l_pin, isTyping: true)
        let message = CoreMessage_TMessageBank.sendMessage(l_pin: l_pin, message_scope_id: message_scope_id, status: status, message_text: message_text, credential: credential, attachment_flag: attachment_flag, ex_blog_id: ex_blog_id, message_large_text: message_large_text, ex_format: ex_format, image_id: image_id, audio_id: audio_id, video_id: video_id, file_id: file_id, thumb_id: thumb_id, reff_id: reff_id, read_receipts: read_receipts, chat_id: chat_id, is_call_center: is_call_center, call_center_id: call_center_id, opposite_pin: opposite_pin, gif_id: gif_id, isForwarded: "\(is_forwarded)", isSecret: "\(is_secret)", specFile: specFileString)
        Nexilis.addQueueMessage(message: message)
        let messageId = String(message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID]!)
        if credential == "1" {
            self.listTimerCredential[messageId] = 60
        }
        var row: [String: Any?] = [:]
        row["message_id"] = messageId
        row["f_pin"] = idMe
        row["l_pin"] = dataPerson["f_pin"]!!
        row["message_scope_id"] = message_scope_id
        row["server_date"] = "\(Date().currentTimeMillis())"
        row["status"] = status
        row["message_text"] = message_text
        row["audio_id"] = audio_id
        row["video_id"] = video_id
        row["image_id"] = image_id
        row["thumb_id"] = thumb_id
        row["read_receipts"] = read_receipts
        row["credential"] = credential
        row["chat_id"] = chat_id
        row["file_id"] = file_id
        row["blog_id"] = ex_blog_id
        row["attachment_flag"] = attachment_flag
        row["reff_id"] = reff_id
        row["progress"] = 0.0
        row["lock"] = "0"
        row["is_stared"] = "0"
        row["gif_id"] = gif_id
        row[TypeDataMessage.is_forwarded] = is_forwarded
        row["isSelected"] = false
        row[TypeDataMessage.is_call_center] = is_call_center
        row[TypeDataMessage.call_center_id] = call_center_id
        row[TypeDataMessage.opposite_pin] = opposite_pin
        row[TypeDataMessage.spec_file] = specFileString
        specFileString = ""
        lastTextLength = 0
        if !dataDates.contains("Today".localized()) {
            dataDates.append("Today".localized())
            tableChatView.insertSections(IndexSet(integer: dataDates.count - 1), with: .none)
        }
        row["chat_date"] = "Today".localized()
        if let collageRow = foldIntoImageGroup(row) {
            // Part of the run above it: no new row goes in, the row that draws the
            // collage is redrawn to take it.
            tableChatView.reloadRows(at: [collageRow], with: .none)
        } else {
            dataMessages.append(row)
            tableChatView.insertRows(at: [IndexPath(row: messages(onDate: dataDates[dataDates.count - 1]).count - 1, section: dataDates.count - 1)], with: .none)
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
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            self.timerFakeProgress = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//                self.updateProgress(row as [AnyHashable : Any])
//                if self.fakeProgMultip == self.maxFakeProgMultip {
//                    self.timerFakeProgress?.invalidate()
//                    self.fakeProgMultip = 0
//                }
//            }
//        }
    }
    
    @objc func addFriendReqAction(sender: UIButton) {
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        Nexilis.showLoader()
        let lPin = sender.restorationIdentifier?.components(separatedBy: ",")[0]
        let messageId = sender.restorationIdentifier?.components(separatedBy: ",")[1]
        let isAccept = (sender.tag == 0)
        DispatchQueue.global(qos: .userInitiated).async {
            if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getAddFriendApproval(lPin: lPin ?? "", isAccept: isAccept), timeout: 5 * 1000) {
                if response.isOk() {
                    self.deleteMessage(l_pin: self.dataPerson["f_pin"]!!, message_id: messageId ?? "", scope: MessageScope.WHISPER, type: "1", chat: "")
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == messageId})
                    if idx != nil {
                        self.dataMessages.remove(at: idx!)
                        if (idx == self.dataMessages.count - 1) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                        }
                        for i in 0..<self.dataDates.count {
                            if self.messages(onDate: self.dataDates[i]).count == 0 {
                                self.dataDates.remove(at: i)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        Nexilis.hideLoader {
                            if self.dataMessages.count == 0 {
                                if self.fromNotification {
                                    self.didTapExit()
                                } else {
                                    self.navigationController?.popViewController(animated: true)
                                }
                            } else {
                                self.tableChatView.reloadData()
                            }
                            UIApplication.shared.visibleViewController?.view.makeToast(sender.tag == 0 ? "Friend request has been accepted".localized() : "Friend request has been rejected".localized(), duration: 3)
                        }
                    }
                } else {
                    Nexilis.hideLoader {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            } else {
                Nexilis.hideLoader {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                }
            }
        }
    }
    
    @objc func ccAction(sender: UIButton) {
        if self.nowSelectedCategoryCC == "CantReturn" {
            if sender.tag == 503 {
                self.view.makeToast("You can't request Call Center more than one".localized(), duration: 3)
            } else if sender.tag == 504 {
                busyCCAction(sender: sender)
            }
            return
        }
        if self.nowSelectedCategoryCC == "endCC" {
            return
        }
        let id = sender.restorationIdentifier?.components(separatedBy: ",")[0]
        let service_id = sender.restorationIdentifier?.components(separatedBy: ",")[1]
        let level = id!.substring(from: 5, to: 5)
        let levelNow = self.nowSelectedCategoryCC.substring(from: 5, to: 5)
        var isRequest = false
        var channel = 0
        var row: [String: Any?] = [:]
        if nowSelectedCategoryCC.isEmpty || level > levelNow {
            if Utils.getDefaultCC() == "No" && !showToastTwiceClick {
                self.view.makeToast("You can press your choice again to change category".localized(), duration: 3)
                showToastTwiceClick = true
            }
            row["message_id"] = ""
            row["chat_date"] = "Today".localized()
            let dataChat: [CategoryCC] = CategoryCC.getDatafromParent(parent: service_id!)
            if dataChat.count != 0 {
                var data : [CategoryCC] = []
                for i in 0..<dataChat.count {
                    data.append(CategoryCC(id: "level\(Int(level)! + 1)_\(i)", service_id: dataChat[i].service_id, service_name: dataChat[i].service_name, parent: id!, description: dataChat[i].description, is_tablet: dataChat[i].is_tablet))
                }
                row["category_cc"] = data
            } else if dataMessages[Int(level)!]["attachment_flag"] == nil {
                let listStringName: [String] = ["Informasi Umum Produk Call 1500046", "Informasi Spesifik Produk"]
                var data : [CategoryCC] = []
                for i in 0..<listStringName.count {
                    data.append(CategoryCC(id: "level\(Int(level)! + 1)_\(i)", service_id: service_id!, service_name: listStringName[i], parent: id!, description: "", is_tablet: "0"))
                }
                row["category_cc"] = data
                row["attachment_flag"] = "502"
            } else if dataMessages[Int(level)!]["attachment_flag"] != nil && dataMessages[Int(level)!]["attachment_flag"]  as? String ?? "" == "502" {
                if id == "level\(Int(level)!)_0" {
                    if let url = URL(string: "tel://1500046") {
                        UIApplication.shared.open(url)
                    }
                    return
                } else {
                    let listStringName: [String] = ["Messaging".localized(), "Secure SMS".localized(), "VoIP Call".localized(), "Email".localized(), "Video Call".localized(), "GSM Call".localized(), "GPT Chatbot".localized(), "WhatsApp"]
//                    let listStringName: [String] = ["Chat with a Representative".localized(), "Video Call a Representative".localized(), "Call a Representative".localized()]
                    var data : [CategoryCC] = []
                    let channels : [String] = ["0", "4", "1", "3", "2", "5", "7", "6"]
                    for i in 0..<listStringName.count {
                        data.append(CategoryCC(id: "level\(Int(level)! + 1)_\(channels[i])", service_id: service_id!, service_name: listStringName[i], parent: id!, description: "", is_tablet: "0"))
                    }
                    row["category_cc"] = data
                    row["attachment_flag"] = "503"
                }
            } else {
                channel = Int((id?.components(separatedBy: "_")[1])!)!
                if channel == 1 || channel == 2 {
                    if channel == 2 {
                        let goAudioCall = Nexilis.checkMicPermission()
                        let goVideoCall = Nexilis.checkCameraPermission()
                        if goVideoCall == 0 {
                            let alert = LibAlertController(title: "Attention!".localized(), message: !goAudioCall && goVideoCall == 0 && channel == 2 ? "Please allow microphone & camera permission in your settings".localized() : !goAudioCall ? "Please allow microphone permission in your settings".localized() : "Please allow camera permission in your settings", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {_ in
                                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            }))
                            self.navigationController?.present(alert, animated: true, completion: nil)
                            return
                        } else if goVideoCall == -1 {
                            return
                        }
                    } else if channel == 1 {
                        let goAudioCall = Nexilis.checkMicPermission()
                        if !goAudioCall{
                            let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow microphone permission in your settings".localized(), preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {_ in
                                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            }))
                            self.navigationController?.present(alert, animated: true, completion: nil)
                            return
                        }
                    }
                } else if channel == 3 {
                    requestEmailContactCenter(channel)
                    return
                } else if channel == 4 {
                    requestSMSContactCenter(channel)
                    return
                } else if channel == 5 {
                    requestGSMCallContactCenter(channel)
                    return
                } else if channel == 6 {
                    requestWhatsappContactCenter(channel)
                    return
                } else if channel == 7 {
                    APIS.openSmartChatbot()
                    return
                }
                row["category_cc"] = "Please wait while we connect you\nto one of our service representatives".localized()
                isRequest = true
            }
            if dataMessages[Int(level)!]["attachment_flag"] == nil || dataMessages[Int(level)!]["attachment_flag"]  as? String ?? "" != "503" {
                dataMessages.append(row)
                self.nowSelectedCategoryCC = id!
                tableChatView.insertRows(at: [IndexPath(row: dataMessages.count - 1, section: 0)], with: .none)
                self.tableChatView.layoutIfNeeded()
            }
        } else {
            if id == self.nowSelectedCategoryCC {
                if level == "0" {
                    self.nowSelectedCategoryCC = ""
                } else {
                    let categoryCC = dataMessages[dataMessages.count - 2]["category_cc"] as! [CategoryCC]
                    self.nowSelectedCategoryCC = categoryCC[0].parent
                }
                dataMessages.remove(at: dataMessages.count - 1)
                tableChatView.deleteRows(at: [IndexPath(row: dataMessages.count - 1, section: 0)], with: .none)
                tableChatView.reloadData()
            } else {
                return
            }
        }
        if Utils.getDefaultCC() == "No" {
            if sender.backgroundColor != .orangeBNI {
                var button = dataMessages[dataMessages.count - 2]["category_cc"] as! [CategoryCC]
                if dataMessages[Int(level)!]["attachment_flag"] != nil && dataMessages[Int(level)!]["attachment_flag"]  as? String ?? "" == "503" {
                    button = dataMessages[dataMessages.count - 1]["category_cc"] as! [CategoryCC]
                }
                for i in button {
                    if i.id == id! {
                        i.isActive = true
                        break
                    }
                }
                sender.backgroundColor = .orangeBNI
                dataMessages[dataMessages.count - 2]["category_cc"] = button
            } else {
                let button = dataMessages[dataMessages.count - 1]["category_cc"] as! [CategoryCC]
                for i in button {
                    if i.id == id! {
                        i.isActive = false
                        break
                    }
                }
                sender.backgroundColor = .clear
                dataMessages[dataMessages.count - 1]["category_cc"] = button
            }
        }
        if isRequest {
            requestContactCenter(channel: channel, service_id: service_id!, row: row)
        } else {
            self.tableChatView.scrollToBottom()
        }
    }
    
    private func directCC() {
        if channelContactCenter == "1" || channelContactCenter == "2" {
            if channelContactCenter == "2" {
                let goAudioCall = Nexilis.checkMicPermission()
                let goVideoCall = Nexilis.checkCameraPermission()
                if goVideoCall == 0 {
                    let alert = LibAlertController(title: "Attention!".localized(), message: !goAudioCall && goVideoCall == 0 && channelContactCenter == "2" ? "Please allow microphone & camera permission in your settings".localized() : !goAudioCall ? "Please allow microphone permission in your settings".localized() : "Please allow camera permission in your settings", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {_ in
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }))
                    self.navigationController?.present(alert, animated: true, completion: nil)
                    return
                } else if goVideoCall == -1 {
                    return
                }
            } else if channelContactCenter == "1" {
                let goAudioCall = Nexilis.checkMicPermission()
                if !goAudioCall{
                    let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow microphone permission in your settings".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: {_ in
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }))
                    self.navigationController?.present(alert, animated: true, completion: nil)
                    return
                }
            }
        }
        var row: [String: Any?] = [:]
        row["message_id"] = ""
        row["chat_date"] = "Today".localized()
        row["category_cc"] = "Please wait while we connect you\nto one of our service representatives".localized()
        dataMessages.append(row)
        nowSelectedCategoryCC = "CantReturn"
        tableChatView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        tableChatView.layoutIfNeeded()
        requestContactCenter(channel: Int(channelContactCenter)!, service_id: serviceIdCC, row: row)
    }
    
    @objc func busyCCAction(sender: UIButton) {
        let id = sender.restorationIdentifier?.components(separatedBy: ",")[0]
        let service_id = sender.restorationIdentifier?.components(separatedBy: ",")[1]
        let level = id!.substring(from: 5, to: 5)
        var row: [String: Any?] = [:]
        if id == "level\(Int(level)!)_0" {
            SecureUserDefaults.shared.set(true, forKey: "waitingRequestCC")
            DispatchQueue.global().async {
                let message = CoreMessage_TMessageBank.getQueuingCallCenter(p_channel: Int(self.channelContactCenter)!)
                message.mBodies[CoreMessage_TMessageKey.CATEGORY_ID] = "\(service_id!)"
                _ = Nexilis.writeSync(message: message, timeout: 30 * 1000)
            }
            row["category_cc"] = "Thank you for contacting us,\none of our officers will contact you soon".localized()
        } else {
            row["category_cc"] = "Thank you for being awesome,\nhave a great day!".localized()
        }
        row["message_id"] = ""
        row["chat_date"] = "Today".localized()
        self.nowSelectedCategoryCC = "endCC"
        dataMessages.append(row)
        tableChatView.insertRows(at: [IndexPath(row: Int(level)!, section: 0)], with: .none)
        self.tableChatView.layoutIfNeeded()
        self.tableChatView.scrollToBottom()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
//            self.dismiss(animated: true)
//        })
    }
    
    func requestEmailContactCenter(_ channel: Int){
        let idMe = User.getMyPin() as String?
        let complaintId = "CMP_\(idMe!)_\(String(Date().currentTimeMillis()))EML"
        let message = CoreMessage_TMessageBank.getRequestEmailCallCenter(p_channel: channel)
        if let response = Nexilis.writeSync(message: message) {
            if (response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "00") {
                DispatchQueue.main.async {
                    let email = response.getBody(key: CoreMessage_TMessageKey.EMAIL, default_value: "")
                    let officer = response.getBody(key: CoreMessage_TMessageKey.L_PIN, default_value: "")
                    if email.isEmpty {
                        self.view.makeToast("Invalid Email Address".localized(), duration: 3)
                        return
                    }
                    // TODO: check if mail available
                    Nexilis.openmailAction(to: email)
                }
            }
        }
        
    }
    
    func requestSMSContactCenter(_ channel: Int){
//        let idMe = User.getMyPin()!
//        let complaintId = "CMP_\(idMe)_\(String(Date().currentTimeMillis()))SMS"
//        isRequestContactCenter = true
        var phone = Utils.getSMSCenter()
        if phone.substring(from: 0, to: 0) == "0" {
            phone = "+62" + phone.substring(from: 1, to: phone.count)
        }
        APIS.sendSMS(phoneNumber: phone)
//        let tmessage = TMessage()
//        tmessage.mCode = CoreMessage_TMessageCode.ACCEPT_CALL_CENTER
//        tmessage.mStatus = CoreMessage_TMessageUtil.getTID()
//        tmessage.mPIN = idMe
//        tmessage.mBodies[CoreMessage_TMessageKey.F_PIN] = me
//        tmessage.mBodies[CoreMessage_TMessageKey.UPLINE_PIN] = me
//        tmessage.mBodies[CoreMessage_TMessageKey.CHANNEL] = channel
//        tmessage.mBodies[CoreMessage_TMessageKey.CALL_CENTER_ID] = complaint_id
    }
    
    func requestGSMCallContactCenter(_ channel: Int){
        var phone = Utils.getCallCenter()
        if phone.substring(from: 0, to: 0) == "0" {
            phone = "+62" + phone.substring(from: 1, to: phone.count)
        }
        if let url = URL(string: "tel://\(phone)") {
            UIApplication.shared.open(url)
        }
    }
    
    func requestWhatsappContactCenter(_ channel: Int){
        var phone = Utils.getWhatsappCenter()
        if phone.substring(from: 0, to: 0) == "0" {
            phone = "+62" + phone.substring(from: 1, to: phone.count)
        }
        APIS.sendWhatsapp(phoneNumber: phone)
    }
    
    func requestContactCenter(channel: Int, service_id: String, row: [String: Any?]) {
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        DispatchQueue.global().async {
            let message = CoreMessage_TMessageBank.getRequestCallCenter(p_channel: channel, category_id: service_id)
            message.mBodies["wlc_device"] = "\(UIDevice.current.model)(\(UIDevice.current.name))"
            message.mBodies["wlc_time"] = "\(Date().currentTimeMillis())"
            message.mBodies["wlc_longitude"] = "\(self.longitude)"
            message.mBodies["wlc_latitude"] = "\(self.latitude)"
            if !self.contextCC.isEmpty {
                let dataSplit = self.contextCC.components(separatedBy: "~")
                var activity = ""
                var titleErr = ""
                if dataSplit.count > 1 {
                    activity = dataSplit[1]
                }
                if dataSplit.count > 2 {
                    titleErr = dataSplit[2]
                }
                message.mBodies["wlc_activity"] = "\(activity)"
                message.mBodies["wlc_error_description"] = "\(titleErr)"
            }
            if let response = Nexilis.writeSync(message: message) {
                if !self.isDirectCC {
                    DispatchQueue.main.async {
                        self.dataMessages.append(row)
                        self.nowSelectedCategoryCC = "CantReturn"
                        self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.count - 1, section: 0)], with: .none)
                        self.tableChatView.layoutIfNeeded()
                        self.tableChatView.scrollToBottom()
                    }
                }
                if (response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "00") {
                    DispatchQueue.main.async {
                        SecureUserDefaults.shared.set(true, forKey: "waitingRequestCC")
                        let data = response.getBody(key: CoreMessage_TMessageKey.DATA, default_value: "")
                        if data.isEmpty {
                            SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
                            var row: [String: Any?] = [:]
                            row["message_id"] = ""
                            row["chat_date"] = "Today".localized()
                            row["attachment_flag"] = "504"
                            let listStringName: [String] = ["Yes".localized(), "No".localized()]
                            var data : [CategoryCC] = []
                            for i in 0..<listStringName.count {
                                data.append(CategoryCC(id: "level\(self.dataMessages.count + 1)_\(i)", service_id: service_id, service_name: listStringName[i], parent: "", description: "", is_tablet: "0"))
                            }
                            row["category_cc"] = data
                            self.dataMessages.append(row)
                            self.channelContactCenter = "\(channel)"
                            self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.count - 1, section: 0)], with: .none)
                            self.tableChatView.layoutIfNeeded()
                            self.tableChatView.scrollToBottom()
                        } else {
                            self.fPinContacCenter = data
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
                        var row: [String: Any?] = [:]
                        row["message_id"] = ""
                        row["chat_date"] = "Today".localized()
                        row["attachment_flag"] = "504"
                        let listStringName: [String] = ["Yes".localized(), "No".localized()]
                        var data : [CategoryCC] = []
                        for i in 0..<listStringName.count {
                            data.append(CategoryCC(id: "level\(self.dataMessages.count + 1)_\(i)", service_id: service_id, service_name: listStringName[i], parent: "", description: "", is_tablet: "0"))
                        }
                        row["category_cc"] = data
                        self.dataMessages.append(row)
                        self.channelContactCenter = "\(channel)"
                        self.tableChatView.insertRows(at: [IndexPath(row: self.dataMessages.count - 1, section: 0)], with: .none)
                        self.tableChatView.layoutIfNeeded()
                        self.tableChatView.scrollToBottom()
                    }
                }
            }
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
//                            if let listGroupImages = self.groupImages.first(where: { $0.key == message_id }) {
//                                let valueListGroupImages = listGroupImages.value
//                                for i in 0..<valueListGroupImages.count {
//                                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
//                                        do {
//                                            _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
//                                                "status" : "4"
//                                            ], _where: "message_id = '\(valueListGroupImages[i].messageId)'")
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
            let tmessage = CoreMessage_TMessageBank.getUpdateTypingStatus(p_opposite: l_pin, p_scope: MessageScope.WHISPER, p_status: isTyping ? "3": "4")
            _ = Nexilis.write(message: tmessage)
        }
    }
    
    private func getCounter() {
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT counter FROM MESSAGE_SUMMARY where l_pin='\(dataPerson["f_pin"]!!)'"), c.next() {
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
                _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                    "counter" : "\(counter)"
                ], _where: "l_pin = '\(self.dataPerson["f_pin"] as? String ?? "")'")
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        // This chat's unread just changed; the icon counts every chat's, so it changed too.
        APIS.refreshApplicationBadgeSoon()
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
        labelCounter.font = UIFont.systemFont(ofSize: 11)
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
//            if !visibleMessages.isEmpty, !isContactCenter {
//                let myPin = User.getMyPin()
//                var stringMessage = ""
//                for msg in visibleMessages {
//                    if msg["f_pin"] as? String != myPin && EditorGroup.conditionSendRead(scope: msg[TypeDataMessage.message_scope_id] as! String, fPin: msg[TypeDataMessage.f_pin] as! String, messageId: msg["message_id"]  as? String ?? "") {
//                        if !stringMessage.isEmpty {
//                            stringMessage += ",\(msg["message_id"] as? String ?? "")"
//                        } else {
//                            stringMessage += msg["message_id"] as? String ?? ""
//                        }
//                    }
//                }
//                if !stringMessage.isEmpty {
//                    sendReadMessageStatus(
//                        chat_id: "",
//                        f_pin: dataPerson["f_pin"]!!,
//                        message_scope_id: MessageScope.WHISPER,
//                        message_id: stringMessage
//                    )
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
}

//EPV
extension EditorPersonal: PreviewAttachmentImageVideoDelegate, PHPickerViewControllerDelegate {
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
            previewImageVC.isCC = self.isContactCenter
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
                    previewImageVC.isCC = self.isContactCenter
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

//EQL
extension EditorPersonal: UIDocumentPickerDelegate, DocumentPickerDelegate, QLPreviewControllerDataSource {
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
                                    
                                    previewImageVC.delegate = self
                                    previewImageVC.isCC = self.isContactCenter
                                    att[0].isAck = self.isAck
                                    att[0].isConfidential = self.isConfidential
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
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.previewItem != nil ? 1 : 0
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem!
    }
}

//ETV
extension EditorPersonal: UITextViewDelegate, CustomTextViewPasteDelegate {
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
        previewImageVC.isCC = self.isContactCenter
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
            if isContactCenter && !fPinContacCenter.isEmpty {
                sendTyping(l_pin: fPinContacCenter, isTyping: true)
            } else {
                sendTyping(l_pin: dataPerson["f_pin"]!!, isTyping: true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
                self.allowTyping = true
            })
        }
        timerCheckLink?.invalidate()
        timerCheckLink = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {_ in
            self.checkLink(fullText: textView.text)
        })
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
        
        //indention code:
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
                if Utils.getGPTBotName().lowercased().contains(text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let gptUser = User(pin: "-997",
                                    firstName: Utils.getGPTBotName(),
                                    lastName: "",
                                    thumb: "",
                                    userType: "0",
                                    official: "1")
                    listMentionWithText.insert(gptUser, at: 0)
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
                        print("MASUK SINI KAH? :\(result)")
                        if result.title == nil {
                            self.checkLink(fullText: fullText)
                            return
                        }
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
                        print("onError? :\(error)")
                        self.deleteLinkPreview()
                    })
                }
            } else {
                deleteLinkPreview()
            }
        }
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
        titlePreview.font = UIFont.systemFont(ofSize: 14.0 + offset(), weight: .bold)
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
            textView.text = "Send message".localized()
            textView.textColor = UIColor.lightGray
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if listMentionInTextField.count > 0 {
            for i in 0..<listMentionInTextField.count {
                if lastPositionCursorMention == Int(listMentionInTextField[i].ex_block!)! + 1 {
                    let fulltextForMention = textView.text.substring(from: 0, to: lastPositionCursorMention - 1)
                    let diff = textView.text.count - fulltextForMention.count
                    var text = textView.text ?? ""
                    let nameMention = listMentionInTextField[i].fullName.trimmingCharacters(in: .whitespaces)
                    let rangeReplacement = NSRange(location: lastPositionCursorMention - nameMention.count - 1, length: nameMention.count + 1)
                    let replacementText = ""
                    
                    let copyAttributedText = text.richText(isEditing: true, listMentionInTextField: listMentionInTextField)
                    copyAttributedText.removeAttribute(.foregroundColor, range: rangeReplacement)
                    
                    textView.attributedText = copyAttributedText

                    // Replace the old text with the new text using the replaceSubrange(_:with:) method
                    if let startIndex = text.index(text.startIndex, offsetBy: rangeReplacement.location, limitedBy: text.endIndex),
                       let endIndex = text.index(startIndex, offsetBy: rangeReplacement.length, limitedBy: text.endIndex) {
                        text.replaceSubrange(startIndex..<endIndex, with: replacementText)
                    }
                    listMentionInTextField.remove(at: i)
                    
                    textView.attributedText = text.richText(isEditing: true, listMentionInTextField: listMentionInTextField)
                    
                    let newPosition = textView.position(from: textView.beginningOfDocument, offset: textView.text.count - diff)
                    textView.selectedTextRange = textView.textRange(from: newPosition!, to: newPosition!)
                    textViewDidChangeSelection(textView)
                    handleRichText(textView)
                    return false
                }
            }
        }
        let indent = handleIndent(textView, range, text)
        if !indent {
            handleRichText(textView)
            return indent
        }
        if (self.textFieldSend.text.count == 0) {
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
        textView.applyRichText(textView.text.richText(isEditing: true, listMentionInTextField: self.listMentionInTextField))
    }
    
    func isGIFData(_ data: Data) -> Bool {
        let gifSignature: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]
        let rawData = [UInt8](data.prefix(6))
        return rawData == gifSignature
    }
    
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

        // Fix: mirrors EditorGroup.swift's link handling (see its CHANGELOG entries
        // for the full history). With messageText.isSelectable = false, this delegate
        // method no longer fires at all for any interaction type - link tap handling
        // in UITextView is gated by isSelectable, same as text selection. Left in
        // place, unreachable in practice, purely as a defensive fallback in case that
        // iOS behavior ever changes - the real logic now lives in
        // handleMessageTextTap(_:) (taps, via a plain UITapGestureRecognizer) and
        // contextMenuInteraction(_:configurationForMenuAtLocation:) + handleLinkTouchHighlight(_:)
        // (long-press, via containerMessage's UIContextMenuInteraction for
        // suppressing the bubble menu, and a dedicated timer for the actual
        // LinkActionSheetViewController trigger).
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

//EUC
extension EditorPersonal: UIContextMenuInteractionDelegate {
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
        // configurable via public API). That's too fast for the requested "hold past
        // LinkHighlighting.longPressThreshold, like WhatsApp" behavior, so the actual
        // timing + sheet-triggering moved to handleLinkTouchHighlight's own timer
        // (tracked independently from the moment the finger touches down, via
        // LinkTouchHighlightGesture). This delegate method now ONLY suppresses the
        // bubble-wide Star/Reply/Forward/... menu when the touch is on a link - still
        // necessary, since containerMessage's interaction still recognizes over links
        // at its own faster threshold and would otherwise show that menu on top of
        // things well before the threshold is reached.
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
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
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
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
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
                var checkDataPinned = self.pinnedMessagesForBanner()
                checkDataPinned.sort {
                    let firstPinned = Int64($0[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
                    let secondPinned = Int64($1[TypeDataMessage.is_pinned] as? String ?? "0") ?? 0
                    return firstPinned < secondPinned
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                    let indexUnpinned = checkDataPinned.firstIndex(where: { $0[TypeDataMessage.message_id] as? String == dataMessages[indexPath!.row][TypeDataMessage.message_id] as? String })
                    self.proceedPinUnpinMessage(checkDataPinned: dataMessages[indexPath!.row], isPinned: false) { res in
                        if res {
                            let dataMessagesPin = self.pinnedMessagesForBanner()
                            DispatchQueue.main.async {
                                self.pinAllMessages(dataMessages: dataMessagesPin, isPinned: indexUnpinned ?? 0)
                            }
                        }
                    }
                })
            })
        }
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
                if self.dataPerson["f_pin"] != "-999" && !self.isContactCenter {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                if self.isContactCenter || self.fromNotification {
                    self.navigationItem.leftBarButtonItem = nil
                }
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
                if self.dataPerson["f_pin"] != "-999" && !self.isContactCenter {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                if self.isContactCenter || self.fromNotification {
                    self.navigationItem.leftBarButtonItem = nil
                }
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
                if self.dataPerson["f_pin"] != "-999" && !self.isContactCenter {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                if self.isContactCenter || self.fromNotification {
                    self.navigationItem.leftBarButtonItem = nil
                }
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
            messageInfoVC.dataPerson = self.dataPerson
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
                if self.dataPerson["f_pin"] != "-999" && !self.isContactCenter {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                if self.isContactCenter || self.fromNotification {
                    self.navigationItem.leftBarButtonItem = nil
                }
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
        let idMe = User.getMyPin() as String?
        if !(dataMessages[indexPath!.row]["audio_id"]  as? String ?? "").isEmpty {
            children.remove(at: 3)
        }
        if dataMessages[indexPath!.row]["status"]  as? String ?? "" == "0" {
            children = [resend, delete]
        } else if isContactCenter {
            if dataMessages[indexPath!.row]["attachment_flag"]  as? String ?? "" == "11" || (!(dataMessages[indexPath!.row]["image_id"]  as? String ?? "").isEmpty || !(dataMessages[indexPath!.row]["video_id"]  as? String ?? "").isEmpty || !(dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty) {
                children = [reply]
            }
            else {
                children = [reply, copy]
            }
        } else if (dataMessages[indexPath!.row]["lock"] != nil && dataMessages[indexPath!.row]["lock"] as? String == "1") || dataMessages[indexPath!.row]["message_scope_id"] as? String == MessageScope.FORM || dataPerson["f_pin"] == "-999" || dataMessages[indexPath!.row]["credential"]  as? String == "1" || dataMessages[indexPath!.row]["message_scope_id"] as? String == MessageScope.CALL || dataMessages[indexPath!.row]["message_scope_id"] as? String == MessageScope.MISSED_CALL || blocking == "1" || blocking == "-1" {
            children = [delete]
        } else if (groupImages[dataMessages[indexPath!.row]["message_id"]  as? String ?? ""] != nil) {
            forward.title = "Forward All".localized()
            delete.title = "Delete All".localized()
            children = [delete]
            if (Nexilis.checkingAccess(key: "secure_folder_forward") || (dataMessages[indexPath!.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward")) && dataMessages[indexPath!.row]["read_receipts"] as? String != "8" {
                children.insert(forward, at: 0)
            }
        } else {
            if (!(dataMessages[indexPath!.row]["image_id"]  as? String ?? "").isEmpty || !(dataMessages[indexPath!.row]["video_id"]  as? String ?? "").isEmpty || !(dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty) {
                var isEmpty = true
                let messageText = dataMessages[indexPath!.row][TypeDataMessage.message_text]  as? String ?? ""
                if !(dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty && !messageText.components(separatedBy: "|")[1].isEmpty {
                    isEmpty = false
                } else if (dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty && !messageText.isEmpty {
                    isEmpty = false
                }
                if isEmpty {
                    children = [star, reply , pin, delete]
                }
            } else if dataMessages[indexPath!.row]["attachment_flag"]  as? String ?? "" == "11" {
               children = [reply, delete]
            }
            if ((Nexilis.checkingAccess(key: "secure_folder_forward") && dataMessages[indexPath!.row]["attachment_flag"] as? String ?? "" != "11") || (!(dataMessages[indexPath!.row][TypeDataMessage.message_text]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["image_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["video_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["file_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath!.row]["audio_id"]  as? String ?? "").isEmpty) || (dataMessages[indexPath!.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward")) && dataMessages[indexPath!.row]["read_receipts"] as? String != "8" && dataMessages[indexPath!.row]["read_receipts"] as? String != "8" && dataMessages[indexPath!.row]["attachment_flag"] as? String ?? "" != "11" {
                children.insert(forward, at: 2)
            }
            if (dataMessages[indexPath!.row]["f_pin"]  as? String ?? "") == idMe {
                children.insert(info, at: children.count - 1)
            }
            if !(dataMessages[indexPath!.row][TypeDataMessage.message_text]  as? String ?? "").isEmpty {
                if (dataMessages[indexPath!.row]["f_pin"]  as? String ?? "") == idMe && ((dataMessages[indexPath!.row][TypeDataMessage.is_forwarded] as? Int) ?? 0) == 0 && (dataMessages[indexPath!.row][TypeDataMessage.attachment_flag] as? String ?? "") != "11" {
                    var textFile = dataMessages[indexPath!.row][TypeDataMessage.message_text] as? String ?? ""
                    if !(dataMessages[indexPath!.row][TypeDataMessage.file_id] as? String ?? "").isEmpty {
                        textFile = textFile.components(separatedBy: "|")[1]
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
                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getPinMessage(f_pin: User.getMyPin() ?? "", data: jsonString, oppositePin: self.unique_l_pin, chatId: "", scopeId: MessageScope.WHISPER)) {
                    if response.isOk() {
                        if isPinned {
                            let mId = Nexilis.saveMessageNotif(textMessage: "You".localized() + " " + "pinned a message".localized(), fPin: User.getMyPin() ?? "", lPin: self.unique_l_pin, chatId: "", scopeId: MessageScope.WHISPER)
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
    
    func showEditMessageView(at indexPath: IndexPath) {
        tempListMentionWithText = listMentionWithText
        tempListMentionInTextField = listMentionInTextField
        listMentionWithText.removeAll()
        listMentionInTextField.removeAll()
        let dataMessages = self.messages(onDate: dataDates[indexPath.section])
        var oldText = dataMessages[indexPath.row][TypeDataMessage.message_text]  as? String ?? ""
        if !(dataMessages[indexPath.row][TypeDataMessage.file_id] as? String ?? "").isEmpty {
            oldText = oldText.components(separatedBy: "|")[1]
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
                let pinRes = result.components(separatedBy: "@")[1]
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
            tapGesture.message_id = oldText
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
            editTextView.attributedText = oldText.richText(isEditing: true, listMentionInTextField: listMentionInTextField)
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
            messageText.attributedText = oldText.richText()
            
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
            self.isEditingMessage = false
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
            let data = self.dataMessages.filter({ $0["isSelected"] as? Bool == true })
            for i in 0..<data.count {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == data[i]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = false
                }
            }
            self.tableChatView.reloadData()
            self.setRightButtonItem()
            self.changeAppBar()
            if self.isContactCenter || self.fromNotification {
                let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(self.didTapExit))
                self.navigationItem.leftBarButtonItem = backButton
            }
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
            let countSelected = dataMessages.filter({ $0["isSelected"] as? Bool == true }).count
            title.text = "\(countSelected) " + "Selected".localized()
            title.textColor = .mainColor
            title.font = UIFont.systemFont(ofSize: 15.0).bold
            
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
                if countSelected == 0 {
                    button.tintColor = .gray
                } else {
                    button.tintColor = .mainColor
                }
            } else if forwardSession {
                button.image = UIImage(systemName: "arrowshape.turn.up.right")
                if countSelected == 0 {
                    button.tintColor = .gray
                } else {
                    button.tintColor = .mainColor
                }
            } else if deleteSession {
                button.image = UIImage(systemName: "trash")
                if countSelected == 0 {
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
            
            let selectedMessage = dataMessages.filter({ $0["isSelected"] as? Bool == true })
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
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as? Bool == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            var text = ""
            for i in 0..<countSelected {
                let stringDate = (dataMessages[i]["server_date"]  as? String ?? "")
                let date = Date(milliseconds: Int64(stringDate)!)
                let formatterDate = DateFormatter()
                let formatterTime = DateFormatter()
                formatterDate.dateFormat = "dd/MM/yy"
                formatterDate.locale = NSLocale(localeIdentifier: "id") as Locale?
                formatterTime.dateFormat = "HH:mm"
                formatterTime.locale = NSLocale(localeIdentifier: "id") as Locale?
                let dataProfile = getDataProfile(message_id: dataMessages[i]["message_id"]  as? String ?? "")
                let textCopied = (dataMessages[i]["message_text"]  as? String ?? "").richText(isEditing: true)
                if text.isEmpty {
                    text = "*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(textCopied.string)"
                } else {
                    text = text + "\n\n*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(textCopied.string)"
                }
            }
            text = text + "\n\n\nchat " + "Powered by Nexilis".localized()
            DispatchQueue.main.async {
                UIPasteboard.general.string = text
                self.view.makeToast("Text coppied to clipboard".localized(), duration: 3)
            }
            cancelAction()
        } else if forwardSession {
            var dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            let countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            for i in 0..<countSelected {
                if groupImages[dataMessages[i]["message_id"]  as? String ?? ""] != nil {
                    var tempData = dataMessages
                    tempData.remove(at: 0)
                    let dataMessageInGrouping = (groupImages[dataMessages[i]["message_id"]  as? String ?? ""]!).map({ $0.dataMessage })
                    tempData.insert(contentsOf: dataMessageInGrouping, at: i)
                    dataMessages = tempData
                }
            }
            contactChatNav.modalPresentationStyle = .custom
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
                    if scope == MessageScope.WHISPER || scope == MessageScope.CALL || scope == MessageScope.MISSED_CALL {
                        let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                        editorPersonalVC.unique_l_pin = pin
                        editorPersonalVC.dataMessageForward = dataMessages
                        self?.navigationController?.replaceAllViewController(with: editorPersonalVC, animated: true)
                    } else {
                        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                        editorGroupVC.unique_l_pin = pin
                        editorGroupVC.dataMessageForward = dataMessages
                        self?.navigationController?.replaceAllViewController(with: editorGroupVC, animated: true)
                    }
                }
            }
            self.present(contactChatNav, animated: true, completion: nil)
        } else if deleteSession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
            var countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            for i in 0..<countSelected {
                if let isGroupingImages = groupImages[dataMessages[i]["message_id"]  as? String ?? ""] {
                    countSelected += (isGroupingImages.count - 1)
                }
            }
            let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            if let action = self.actionDelete(for: "me", title: "Delete".localized() + " \(countSelected) " + "For Me".localized(), dataMessages: dataMessages) {
                alertController.addAction(action)
            }
            let idMe = User.getMyPin() as String?
            let dataFilterFpin = dataMessages.filter({ $0["l_pin"] as? String == idMe})
            let dataFilterLock = dataMessages.filter({ $0["lock"] as? String == "1" || $0["lock"] as? String == "2" })
            let dataFilterCall = dataMessages.filter({ $0[TypeDataMessage.message_scope_id] as? String == MessageScope.CALL || $0[TypeDataMessage.message_scope_id] as? String == MessageScope.MISSED_CALL })
//            let statusDataRead = dataMessages.filter({ Int($0["status"]  as? String ?? "")! >= 4})
            let statusFailed = dataMessages.filter({ Int($0["status"]  as? String ?? "")! == 0})
            if dataFilterFpin.count == 0 && dataFilterLock.count == 0 && statusFailed.count == 0 && dataFilterCall.count == 0 {
                if let action = self.actionDelete(for: "everyone", title: "Delete".localized() + " \(countSelected) " + "For Everyone".localized(), dataMessages: dataMessages) {
                    alertController.addAction(action)
                }
            }
            alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            self.present(alertController, animated: true)
        } else if summarizeSession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as! Bool == true })
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
                    let dataUser = User.getData(pin: message[TypeDataMessage.f_pin] as? String ?? "", lPin: self.dataPerson["f_pin"] as? String ?? "")
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
    
    private func getDataProfile(message_id: String) -> [String: String]{
        var data: [String: String] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "select f_display_name from MESSAGE where message_id = '\(message_id)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!
                c.close()
            } else {
                data["name"] = "Unknown".localized()
                data["image_id"] = ""
            }
        })
        return data
    }
    
    private func deleteMessage(l_pin: String, message_id: String, scope: String, type: String, chat: String) {
        let tmessage = CoreMessage_TMessageBank.deleteMessage(l_pin: l_pin, messageId: message_id, scope: scope, type: type, chat: chat)
        Nexilis.deleteQueueMessage(message: tmessage)
    }
    
    private func queryMessageReply(message_id: String) -> [String: Any?] {
        var dataQuery: [String: Any] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT message_id, f_pin, message_text, attachment_flag, thumb_id, image_id, video_id, file_id FROM MESSAGE where message_id='\(message_id)'"), c.next() {
                dataQuery["message_id"] = c.string(forColumnIndex: 0) ?? ""
                dataQuery["f_pin"] = c.string(forColumnIndex: 1) ?? ""
                dataQuery["message_text"] = c.string(forColumnIndex: 2) ?? ""
                dataQuery["attachment_flag"] = c.string(forColumnIndex: 3) ?? ""
                dataQuery["thumb_id"] = c.string(forColumnIndex: 4) ?? ""
                dataQuery["image_id"] = c.string(forColumnIndex: 5) ?? ""
                dataQuery["video_id"] = c.string(forColumnIndex: 6) ?? ""
                dataQuery["file_id"] = c.string(forColumnIndex: 7) ?? ""
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
    
    private func actionDelete(for type: String, title: String, dataMessages: [[String: Any?]]) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .destructive) { [unowned self] _ in
            for i in 0..<dataMessages.count {
                if (type == "me") {
                    if let groupingImages = groupImages[dataMessages[i]["message_id"]  as? String ?? ""] {
                        for i in 0..<groupingImages.count {
                            var pin = groupingImages[i].lPin
                            if pin == User.getMyPin() ?? "" {
                                pin = self.dataPerson["f_pin"] as? String ?? ""
                            }
                            self.deleteMessage(l_pin: pin, message_id: groupingImages[i].messageId, scope: MessageScope.WHISPER, type: "1", chat: "")
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == groupingImages[i].messageId })
                            if idx != nil {
                                self.dataMessages.remove(at: idx!)
//                                if (idx == self.dataMessages.count - 1) {
//                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
//                                }
                                for i in 0..<dataDates.count {
                                    if i > dataDates.count - 1 {
                                        continue
                                    }
                                    if self.messages(onDate: dataDates[i]).count == 0 {
                                        dataDates.remove(at: i)
                                    }
                                }
                            }
                        }
                        self.groupImages.removeValue(forKey: groupingImages[0].messageId)
                    } else {
                        var pin = dataMessages[i]["l_pin"]  as? String ?? ""
                        if pin == User.getMyPin() ?? "" {
                            pin = self.dataPerson["f_pin"] as? String ?? ""
                        }
                        self.deleteMessage(l_pin: pin, message_id: dataMessages[i]["message_id"]  as? String ?? "", scope: MessageScope.WHISPER, type: "1", chat: "")
                        let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[i]["message_id"] as? String})
                        if idx != nil {
                            self.dataMessages.remove(at: idx!)
//                            if (idx == self.dataMessages.count - 1) {
//                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
//                            }
                            for i in 0..<dataDates.count {
                                if i > dataDates.count - 1 {
                                    continue
                                }
                                if self.messages(onDate: dataDates[i]).count == 0 {
                                    dataDates.remove(at: i)
                                }
                            }
                        }
                    }
                } else {
                    if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    } else {
                        if let groupingImages = groupImages[dataMessages[i]["message_id"]  as? String ?? ""] {
                            for i in 0..<groupingImages.count {
                                self.deleteMessage(l_pin: groupingImages[i].lPin, message_id: groupingImages[i].messageId, scope: MessageScope.WHISPER, type: "2", chat: "")
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
                            self.deleteMessage(l_pin: dataMessages[i]["l_pin"]  as? String ?? "", message_id: dataMessages[i]["message_id"]  as? String ?? "", scope: MessageScope.WHISPER, type: "2", chat: "")
                            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[i]["message_id"] as? String})
                            if idx != nil {
                                self.dataMessages[idx!]["lock"] = "1"
                                self.dataMessages[idx!]["attachment_flag"] = "0"
                                self.dataMessages[idx!]["reff_id"] = ""
                            }
                        }
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
        }
    }
    
    private func updateProfile() {
        let idMe = User.getMyPin() as String?
        DispatchQueue.global().async {
            let message = CoreMessage_TMessageBank.getBatchBuddiesInfos(p_f_pin: idMe!, last_update: 0)
            let _ = Nexilis.write(message: message)
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
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
    
}

//ECL
extension EditorPersonal: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 76
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellSticker", for: indexPath)
        if (cell.contentView.subviews.count > 0) {
            cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
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
}

//ETB
extension EditorPersonal: UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate {
//    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        checkNewMessage(tableView: tableView)
//    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard tableView == tableChatView else {
            return
        }
        // Remember what each row actually measured, so the table estimates rows it has not
        // built yet from real numbers. That is what keeps the content from shifting under the
        // reader when a page of older messages is inserted above.
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
                        
                        nowTextField.attributedText = text.richText(isEditing: true, listMentionInTextField: listMentionInTextField)
                        
                        let newPosition = nowTextField.position(from: nowTextField.beginningOfDocument, offset: nowTextField.text.count - diff)
                        nowTextField.selectedTextRange = nowTextField.textRange(from: newPosition!, to: newPosition!)
                        
                        hideMention()
                        lastTextLength = nowTextField.text.count
                        return
                    }
                }
            }
        }
        if isContactCenter && indexPath.row == 0 && isRequestContactCenter {
            return
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
                        }  else if !fileChat.isEmpty && messageText.components(separatedBy: "|")[1].isEmpty {
                            return
                        }
                    }
                }
            }
            if (copySession || forwardSession || summarizeSession) && (dataMessages[indexPath.row]["lock"] as? String == "1" || (dataMessages[indexPath.row]["credential"] as? String) == "1" || (dataMessages[indexPath.row]["lock"] as? String) == "2" || dataMessages[indexPath.row]["f_pin"]  as? String ?? "" == "-999" || dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "11" || (dataMessages[indexPath.row]["message_id"] as! String).contains("NTFPIN_") || dataMessages[indexPath.row]["message_scope_id"] as? String == MessageScope.CALL) {
                return
            }
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath.row]["message_id"] as? String})
            if idx != nil {
                self.dataMessages[idx!]["isSelected"] = !(self.dataMessages[idx!]["isSelected"] as! Bool)
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
                            let message = Nexilis.checkingAccessAlert(key: "live_streaming").components(separatedBy: "|")[1]
                            APIS.nexilisShowAlertWithHTMLMessage(on: UIApplication.shared.visibleViewController ?? UIViewController(), title: title, message: message)
                        } else {
                            UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
                        }
                        return
                    }
                }
                let streamingController = (attachmentFlag == "27") ? QmeraCreateStreamingViewController() : CreateSeminarViewController()
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
                        if json["by"] as? String != User.getMyPin() as String? {
                            switch(attachmentFlag){
                                case "27":
                                    (streamingController as! QmeraCreateStreamingViewController).isJoin = true
                                default:
                                    (streamingController as! CreateSeminarViewController).isJoin = true
                            }
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
            } else if attachmentFlag == "25" {
                if !Nexilis.checkingAccess(key: "vconf_room") {
                    if Nexilis.checkingAccessAlert(key: "vconf_room") != "|" && !Nexilis.checkingAccessAlert(key: "vconf_room").isEmpty {
                        let title = Nexilis.checkingAccessAlert(key: "vconf_room").components(separatedBy: "|")[0]
                        let message = Nexilis.checkingAccessAlert(key: "vconf_room").components(separatedBy: "|")[1]
                        APIS.nexilisShowAlertWithHTMLMessage(on: UIApplication.shared.visibleViewController ?? UIViewController(), title: title, message: message)
                    } else {
                        UIApplication.shared.visibleViewController?.view.makeToast("Feature disabled".localized(), duration: 5)
                    }
                    return
                }
                let conferenceController = CreateSeminarViewController()
                if let messageText = message["message_text"],
                   let messageText = messageText as? String,
                   var json = try! JSONSerialization.jsonObject(with: messageText.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    if json["blog"] == nil {
                        json["blog"] = message["blog"] ?? nil
                    }
                    if json["members"] == nil {
                        json["members"] = message["members"] ?? nil
                    }
                    if json["by"] as? String != User.getMyPin() as String? {
                        conferenceController.isJoin = true
                    }
                    let start = json["time"] as? Int64 ?? 0
                    json["start"] = String(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm"))
                    conferenceController.data = json
                }
                let conferenceNav = CustomNavigationController(rootViewController: conferenceController)
                conferenceNav.modalPresentationStyle = .custom
                conferenceNav.navigationBar.tintColor = .white
                conferenceNav.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
                conferenceNav.navigationBar.isTranslucent = false
                conferenceNav.navigationBar.overrideUserInterfaceStyle = .dark
                conferenceNav.navigationBar.barStyle = .black
                let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
                UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                conferenceNav.navigationBar.titleTextAttributes = textAttributes
                conferenceNav.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
                conferenceNav.navigationBar.isTranslucent = false
                navigationController?.present(conferenceNav, animated: true, completion: nil)
            } else if  message["message_scope_id"] as? String == MessageScope.FORM {
                let formView = FormEditor()
                let messageText =  message["message_text"]  as? String ?? ""
                formView.jsonData = messageText
                formView.dataMessage = message
                formView.dataPerson = self.dataPerson
                formView.modalPresentationStyle = .custom
                formView.modalTransitionStyle = .crossDissolve
                formView.view.backgroundColor = .black.withAlphaComponent(0.2)
                self.present(formView, animated: true, completion: nil)
            }
        }
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
        if listViewOnSection.count == 0 || listViewOnSection.count - 1 < section {
            listViewOnSection.append(containerView)
        } else {
            listViewOnSection.remove(at: section)
            listViewOnSection.insert(containerView, at: section)
        }
        return containerView
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == tableMention || tableView == tableMentionEdit || tableView == tableViewConfigFile {
            return 0
        }
        return 30
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
        let dateKey = dataDates[indexPath.section]
        let dataMessages = messagesByDate[dateKey]!
        let profileMessage = UIImageView()
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellEditorPersonal", for: indexPath as IndexPath)
        cell.contentView.subviews.forEach({ $0.removeConstraints($0.constraints) })
        cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
        
        if isContactCenter && isRequestContactCenter && dataMessages[indexPath.row]["category_cc"] != nil {
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            
            if dataMessages[indexPath.row]["category_cc"] is [CategoryCC] {
                let category_cc = dataMessages[indexPath.row]["category_cc"] as! [CategoryCC]
                profileMessage.frame.size = CGSize(width: 35, height: 35)
                cell.contentView.addSubview(profileMessage)
                profileMessage.translatesAutoresizingMaskIntoConstraints = false
                profileMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
                profileMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15).isActive = true
                profileMessage.heightAnchor.constraint(equalToConstant: 37).isActive = true
                profileMessage.widthAnchor.constraint(equalToConstant: 35).isActive = true
                profileMessage.circle()
                profileMessage.clipsToBounds = true
                profileMessage.backgroundColor = .lightGray
                profileMessage.image = UIImage(systemName: "person")
                profileMessage.tintColor = .white
                profileMessage.contentMode = .scaleAspectFit
                getImage(name: dataPerson["picture"]!!, placeholderImage: UIImage(systemName: "person.circle.fill")!) { result, isDownloaded, image in
                    profileMessage.image = image
                }
                profileMessage.contentMode = .scaleAspectFill
                
                
                let containerMessage = UIView()
                cell.contentView.addSubview(containerMessage)
                containerMessage.translatesAutoresizingMaskIntoConstraints = false
                containerMessage.topAnchor.constraint(equalTo: profileMessage.bottomAnchor).isActive = true
                containerMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 5).isActive = true
                containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -60).isActive = true
                containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
//                containerMessage.backgroundColor = .grayColor
//                containerMessage.layer.cornerRadius = 10.0
//                containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
//                containerMessage.clipsToBounds = true
                
//                let timeMessage = UILabel()
//                cell.contentView.addSubview(timeMessage)
//                timeMessage.translatesAutoresizingMaskIntoConstraints = false
//                timeMessage.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
                
                let messageText = UILabel()
                containerMessage.addSubview(messageText)
                messageText.translatesAutoresizingMaskIntoConstraints = false
                messageText.numberOfLines = 0
                messageText.lineBreakMode = .byWordWrapping
                containerMessage.addSubview(messageText)
                messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 5).isActive = true
                messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                if !contextCC.isEmpty {
                    let dataSplit = contextCC.components(separatedBy: "~")
                    let contentErr = dataSplit[0]
                    var activity = ""
                    var titleErr = ""
                    if dataSplit.count > 1 {
                        activity = dataSplit[1]
                    }
                    if dataSplit.count > 2 {
                        titleErr = dataSplit[2]
                    }
                    var welcome = ""
                    let time = Utils.getGreetingsTimeDefaultWelcome()
                    if time == "1" {
                        welcome = "Selamat pagi"
                    } else if time == "2" {
                        welcome = "Selamat siang"
                    } else {
                        welcome = "Selamat malam"
                    }
                    var myName = ""
                    let myData = User.getDataCanNil(pin: User.getMyPin())
                    if myData != nil {
                        myName = myData!.fullName
                    }
                    messageText.attributedText = "_\(welcome) Pak/Bu *\(myName)*. Kami mendeteksi anda mengalami hambatan pada waktu *\(activity)*, dikarenakan *\(titleErr)*. Kami siap membantu anda untuk mensolusikan masalah yang dihadapi. Silahkan memilih cara interaksi yang diinginkan melalui tombol di bawah ini._".richText(fontSize: 14)
                } else if category_cc[0].id.contains("level0_") || dataMessages[indexPath.row]["attachment_flag"] != nil && dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "503" {
                    messageText.text = "Welcome to".localized() + " " + dataPerson["name"]!! + " " + "Contact Center".localized()
                     + "\n" + "Please choose your desired communication method...".localized()
                } else if category_cc[0].id.contains("level1_") {
                    messageText.text = "Please select your Consultation Topic:".localized()
                } else if !category_cc[0].id.contains("level1_") && dataMessages[indexPath.row]["attachment_flag"] == nil {
                    messageText.text = "Please select the type of topic that you chosen".localized()
                } else if dataMessages[indexPath.row]["attachment_flag"] != nil && dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "502" {
                    messageText.text = "Please select the information option:".localized()
                } else {
                    messageText.text = "Sorry, currently all our representatives are busy helping other customers. Do you want us to get back to you as soon as one of them is available?".localized()
                }
                if contextCC.isEmpty {
                    messageText.font = UIFont.systemFont(ofSize: 14 + offset(), weight: .medium)
                    messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
                }
                
//                let date = Date()
//                let formatter = DateFormatter()
//                formatter.dateFormat = "HH:mm"
//                formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
//                timeMessage.text = formatter.string(from: date as Date)
//                timeMessage.font = UIFont.systemFont(ofSize: 10, weight: .medium)
//                timeMessage.textColor = .lightGray
                
                let containerButton = UIView()
                cell.contentView.addSubview(containerButton)
                containerButton.translatesAutoresizingMaskIntoConstraints = false
                containerButton.topAnchor.constraint(equalTo: messageText.bottomAnchor, constant: 5).isActive = true
                containerButton.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
                containerButton.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15).isActive = true
                containerButton.widthAnchor.constraint(equalToConstant: self.view!.frame.size.width * 0.9).isActive = true
                containerButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 55).isActive = true
                containerButton.backgroundColor = .clear
                
                
                for i in 0..<category_cc.count {
                    let buttonChat = UIButton(type: .custom)
                    containerButton.addSubview(buttonChat)
                    buttonChat.translatesAutoresizingMaskIntoConstraints = false
                    buttonChat.widthAnchor.constraint(equalToConstant: self.view!.frame.size.width * 0.9 / 2 - 5).isActive = true
                    buttonChat.heightAnchor.constraint(greaterThanOrEqualToConstant: 55).isActive = true
                    if i % 2 == 0 {
                        if i / 2 + 1 == 1 {
                            buttonChat.topAnchor.constraint(equalTo: containerButton.topAnchor, constant: 5).isActive = true
                        } else {
                            var constantTop = (i / 2 - 1) * 50
                            if constantTop == 0 {
                                constantTop = 55
                            } else {
                                constantTop = constantTop + 55
                            }
                            buttonChat.topAnchor.constraint(equalTo: containerButton.topAnchor, constant: CGFloat(constantTop)).isActive = true
                        }
                        if i == category_cc.count - 1 {
                            buttonChat.bottomAnchor.constraint(equalTo: containerButton.bottomAnchor, constant: -5).isActive = true
                        }
                        buttonChat.leadingAnchor.constraint(equalTo: containerButton.leadingAnchor, constant: 5).isActive = true
                    } else {
                        let newi = i - 1
                        if newi / 2 + 1 == 1 {
                            buttonChat.topAnchor.constraint(equalTo: containerButton.topAnchor, constant: 5).isActive = true
                        } else {
                            var constantTop = (newi / 2 - 1) * 50
                            if constantTop == 0 {
                                constantTop = 55
                            } else {
                                constantTop = constantTop + 55
                            }
                            buttonChat.topAnchor.constraint(equalTo: containerButton.topAnchor, constant: CGFloat(constantTop)).isActive = true
                        }
                        if i == category_cc.count - 1 {
                            buttonChat.bottomAnchor.constraint(equalTo: containerButton.bottomAnchor, constant: -5).isActive = true
                        }
                        buttonChat.trailingAnchor.constraint(equalTo: containerButton.trailingAnchor, constant: -5).isActive = true
                    }
                    if category_cc[i].isActive  {
                        buttonChat.backgroundColor = .orangeBNI
                    }
                    var nameImage = "pb_cc_bg_messaging"
                    if i == 1 {
                        nameImage = "pb_cc_bg_sms"
                    } else if i == 2 {
                        nameImage = "pb_cc_bg_voip"
                    } else if i == 3 {
                        nameImage = "pb_cc_bg_email"
                    } else if i == 4 {
                        nameImage = "pb_cc_bg_videocall"
                    } else if i == 5 {
                        nameImage = "pb_cc_bg_gsmcall"
                    } else if i == 6 {
                        nameImage = "pb_cc_bg_gptchatbot"
                    } else if i == 7 {
                        nameImage = "pb_cc_bg_whatsapp"
                    }
                    buttonChat.setImage(resizeImage(image: UIImage(named: nameImage, in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: self.view!.frame.size.width * 0.9 / 2 - 5, height: 55)), for: .normal)
//                    buttonChat.setTitle(category_cc[i].service_name.localized(), for: .normal)
//                    buttonChat.setTitleColor(.black, for: .normal)
//                    buttonChat.setImage(resizeImage(image: UIImage(named: "pb_gpt_bot", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)), for: .normal)
//                    buttonChat.contentHorizontalAlignment = .left
//                    buttonChat.imageEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0) // Adjust left inset for the image
//                    buttonChat.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0) // Adjust left inset for the title
//                    buttonChat.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
//                    buttonChat.titleLabel?.numberOfLines = 0
//                    buttonChat.layer.borderWidth = 2
//                    buttonChat.layer.borderColor = UIColor.white.cgColor
//                    buttonChat.backgroundColor = .grayColor
//                    buttonChat.layer.cornerRadius = 8.0
//                    buttonChat.clipsToBounds = true
                    
                    buttonChat.restorationIdentifier = "\(category_cc[i].id),\(category_cc[i].service_id)"
                    if dataMessages[indexPath.row]["attachment_flag"] != nil {
                        buttonChat.tag = Int(dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "")!
                    }
                    buttonChat.addTarget(self, action: #selector(ccAction(sender:)), for: .touchUpInside)
                }
            } else {
                let messageWait = UILabel()
                cell.contentView.addSubview(messageWait)
                messageWait.translatesAutoresizingMaskIntoConstraints = false
                messageWait.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
                messageWait.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
                messageWait.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor, constant: 10).isActive = true
                messageWait.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor, constant: -10).isActive = true
                messageWait.text = dataMessages[indexPath.row]["category_cc"] as? String ?? dataMessages[indexPath.row]["message_text"] as? String ?? ""
                messageWait.numberOfLines = 0
                messageWait.font = UIFont.systemFont(ofSize: 12 + offset())
                messageWait.textColor = .gray
                messageWait.textAlignment = .center
            }
            
            return cell
        }
        
        let messageIdChat = (dataMessages[indexPath.row]["message_id"] as? String) ?? ""
        let thumbChat = (dataMessages[indexPath.row]["thumb_id"] as? String) ?? ""
        let imageChat = (dataMessages[indexPath.row]["image_id"] as? String) ?? ""
        let videoChat = (dataMessages[indexPath.row]["video_id"] as? String) ?? ""
        let fileChat = (dataMessages[indexPath.row]["file_id"] as? String) ?? ""
        let reffChat = (dataMessages[indexPath.row]["reff_id"] as? String) ?? ""
        let audioChat = (dataMessages[indexPath.row]["audio_id"] as? String) ?? ""
        let gifChat = (dataMessages[indexPath.row]["gif_id"] as? String) ?? ""
        let dataTimer = listTimerCredential[(dataMessages[indexPath.row]["message_id"]  as? String ?? "")]
        let is_bot = (dataMessages[indexPath.row][TypeDataMessage.is_bot] as? Int) ?? 0
        var textChat = (dataMessages[indexPath.row]["message_text"] as? String) ?? ""
        
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        let nameSender = UILabel()
        
        if isContactCenter || is_bot == 1 {
            profileMessage.frame.size = CGSize(width: 35, height: 35)
            cell.contentView.addSubview(profileMessage)
            profileMessage.translatesAutoresizingMaskIntoConstraints = false
            profileMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                profileMessage.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15).isActive = true
            } else {
                if copySession || forwardSession || deleteSession || summarizeSession {
                    profileMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 50).isActive = true
                } else {
                    profileMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15).isActive = true
                }
            }
            profileMessage.heightAnchor.constraint(equalToConstant: 37).isActive = true
            profileMessage.widthAnchor.constraint(equalToConstant: 35).isActive = true
            profileMessage.circle()
            profileMessage.clipsToBounds = true
            profileMessage.backgroundColor = .lightGray
            profileMessage.image = UIImage(systemName: "person")
            profileMessage.tintColor = .white
            profileMessage.contentMode = .scaleAspectFit
            if is_bot == 1 {
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
                nameSender.text = Utils.getGPTBotName()
            } else {
                let user = User.getData(pin: dataMessages[indexPath.row]["f_pin"] as? String)
                getImage(name: user?.thumb ?? "", placeholderImage: UIImage(systemName: "person.circle.fill")!, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                    profileMessage.image = image
                }
                nameSender.text = user?.fullName ?? ""
            }
            profileMessage.contentMode = .scaleAspectFill
            
            cell.contentView.addSubview(nameSender)
            nameSender.translatesAutoresizingMaskIntoConstraints = false
            if markerCounter != nil && dataMessages[indexPath.row]["message_id"] as? String == markerCounter {
                nameSender.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 35).isActive = true
            } else {
                nameSender.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
            }
            nameSender.font = UIFont.systemFont(ofSize: 12 + offset(), weight: UIFont.Weight(800))
            nameSender.textAlignment = .right
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                nameSender.trailingAnchor.constraint(equalTo:profileMessage.leadingAnchor, constant: -5).isActive = true
                nameSender.textColor = .systemBlue
            } else {
                nameSender.leadingAnchor.constraint(equalTo:profileMessage.trailingAnchor, constant: 5).isActive = true
                nameSender.textColor = .orangeColor
            }
        }
        
        var containerMessage = UIView()
        if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            containerMessage = SecureField().secureContainer!
        }
        cell.contentView.addSubview(containerMessage)
        containerMessage.translatesAutoresizingMaskIntoConstraints = false
        
        if messageIdChat.contains("NTFPIN_") {
            containerMessage.backgroundColor = .orangeColor
            containerMessage.anchor(top: cell.contentView.topAnchor, bottom: cell.contentView.bottomAnchor, paddingTop: 5, paddingBottom: 5, centerX: cell.contentView.centerXAnchor, minWidth: 40, maxWidth: UIScreen.main.bounds.width - 40)
            containerMessage.layer.cornerRadius = 8
            containerMessage.clipsToBounds = true
            
            let textMessage = UILabel()
            containerMessage.addSubview(textMessage)
            textMessage.textAlignment = .center
            textMessage.anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, right: containerMessage.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingBottom: 5, paddingRight: 10)
            textMessage.font = .systemFont(ofSize: 14)
            textMessage.text = dataMessages[indexPath.row][TypeDataMessage.message_text]  as? String ?? ""
            textMessage.textColor = .white
            return cell
        }
        
        let timeMessage = UILabel()
        timeMessage.numberOfLines = 0
        cell.contentView.addSubview(timeMessage)
        timeMessage.translatesAutoresizingMaskIntoConstraints = false
        if ((dataMessages[indexPath.row]["read_receipts"] as? String) == "8" ||
            (dataMessages[indexPath.row]["credential"] as? String) == "1" ||
            !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty) &&
            (dataMessages[indexPath.row]["lock"] as? String) != "2" &&
            (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            timeMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
        } else {
            timeMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
        }
        
        let statusMessage = UIImageView()
        
        if copySession || forwardSession || deleteSession || summarizeSession {
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
                        } else if !fileChat.isEmpty && textChat.components(separatedBy: "|")[1].isEmpty {
                            showSelectedImage = false
                        }
                    }
                }
            }
            if (copySession || forwardSession || summarizeSession) && (dataMessages[indexPath.row]["lock"] as? String == "1" || (dataMessages[indexPath.row]["credential"] as? String) == "1" || (dataMessages[indexPath.row]["lock"] as? String) == "2" || dataMessages[indexPath.row]["f_pin"]  as? String ?? "" == "-999" || dataMessages[indexPath.row]["attachment_flag"]  as? String ?? "" == "11" || messageIdChat.contains("NTFPIN_") || dataMessages[indexPath.row]["message_scope_id"] as? String == MessageScope.CALL) {
                showSelectedImage = false
            }
            
            if showSelectedImage {
                let selectedImage = UIImageView()
                cell.contentView.addSubview(selectedImage)
                selectedImage.translatesAutoresizingMaskIntoConstraints = false
                selectedImage.frame.size = CGSize(width: 20, height: 20)
                var leading = selectedImage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: -20)
                selectedImage.isHidden = true
                if copySession || forwardSession || deleteSession || summarizeSession {
                    leading = selectedImage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15)
                    selectedImage.isHidden = false
                }
                NSLayoutConstraint.activate([
                    leading,
                    selectedImage.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                    selectedImage.widthAnchor.constraint(equalToConstant: 20),
                    selectedImage.heightAnchor.constraint(equalToConstant: 20)
                ])
                selectedImage.circle()
                selectedImage.layer.borderWidth = 2
                selectedImage.layer.borderColor = UIColor.mainColor.cgColor
                if dataMessages[indexPath.row]["isSelected"] as! Bool {
                    selectedImage.image = UIImage(systemName: "checkmark.circle.fill")
                }
                selectedImage.tintColor = .mainColor
            }
        }
        
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            containerMessage.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 60).isActive = true
            if isContactCenter || is_bot == 1 {
                containerMessage.topAnchor.constraint(equalTo: nameSender.bottomAnchor).isActive = true
                containerMessage.trailingAnchor.constraint(equalTo: profileMessage.leadingAnchor, constant: -5).isActive = true
            } else {
                containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
                containerMessage.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15).isActive = true
            }
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if (dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "") {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .blueBubbleColor
            }
            containerMessage.layer.cornerRadius = 10.0
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            containerMessage.clipsToBounds = true
            
            timeMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            
            if (dataMessages[indexPath.row]["lock"] as? String == "0" || (dataMessages[indexPath.row]["lock"] as? String ?? "").isEmpty)  && dataMessages[indexPath.row][TypeDataMessage.message_scope_id] as? String != MessageScope.CALL && dataMessages[indexPath.row][TypeDataMessage.message_scope_id] as? String != MessageScope.MISSED_CALL {
                cell.contentView.addSubview(statusMessage)
                statusMessage.translatesAutoresizingMaskIntoConstraints = false
                statusMessage.bottomAnchor.constraint(equalTo: timeMessage.topAnchor).isActive = true
                statusMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
                statusMessage.widthAnchor.constraint(equalToConstant: 15).isActive = true
                statusMessage.heightAnchor.constraint(equalToConstant: 15).isActive = true
                if dataMessages[indexPath.row]["status"]!  as? String ?? "" == "0" {
                    statusMessage.image = UIImage(systemName: "xmark.circle")!.withTintColor(UIColor.red, renderingMode: .alwaysOriginal)
                }
                // Still waiting for the server to answer with "2": the message is written here
                // but nowhere else yet, and the clock says so.
                else if dataMessages[indexPath.row]["status"]!  as? String ?? "" == "1" {
                    statusMessage.image = UIImage(systemName: "clock.arrow.circlepath")!.withTintColor(UIColor.lightGray, renderingMode: .alwaysOriginal)

                }
                else if dataMessages[indexPath.row]["status"]!  as? String ?? "" == "2" {
                    statusMessage.image = UIImage(named: "checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else if (dataMessages[indexPath.row]["status"]!  as? String ?? "" == "3") {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.lightGray)
                } else if (dataMessages[indexPath.row]["status"]!  as? String ?? "" == "8") {
                    statusMessage.image = UIImage(named: "message_status_ack", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
                } else {
                    statusMessage.image = UIImage(named: "double-checklist", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(UIColor.systemBlue)
                }
            }
            
        } else {
            if markerCounter != nil && dataMessages[indexPath.row]["message_id"] as? String == markerCounter {
                if isContactCenter || is_bot == 1 {
                    containerMessage.topAnchor.constraint(equalTo: nameSender.bottomAnchor).isActive = true
                } else {
                    containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 35).isActive = true
                }
                
                let newMessagesView = UIView()
                cell.contentView.addSubview(newMessagesView)
                newMessagesView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newMessagesView.topAnchor.constraint(equalTo: newMessagesView.topAnchor),
                    newMessagesView.bottomAnchor.constraint(equalTo: containerMessage.topAnchor),
                    newMessagesView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
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
                if isContactCenter || is_bot == 1 {
                    containerMessage.topAnchor.constraint(equalTo: nameSender.bottomAnchor).isActive = true
                } else {
                    containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
                }
            }
            if isContactCenter || is_bot == 1 {
                containerMessage.leadingAnchor.constraint(equalTo: profileMessage.trailingAnchor, constant: 5).isActive = true
            } else {
                if copySession || forwardSession || deleteSession || summarizeSession {
                    containerMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 50).isActive = true
                } else {
                    containerMessage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15).isActive = true
                }
            }
            containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -60).isActive = true
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
        }
        
        if ((dataMessages[indexPath.row]["read_receipts"] as? String) == "8" ||
            (dataMessages[indexPath.row]["credential"] as? String) == "1" ||
            !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty) &&
            (dataMessages[indexPath.row]["lock"] as? String) != "2" &&
            (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            let containerBottomConstraint = containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40)
            containerBottomConstraint.priority = .defaultHigh
            containerBottomConstraint.isActive = true
        } else {
            let containerBottomConstraint = containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5)
            containerBottomConstraint.priority = .defaultHigh
            containerBottomConstraint.isActive = true
        }
        
        let imageStared = UIImageView()
        if dataMessages[indexPath.row]["is_stared"] as? String == "1" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" == "0") {
            cell.contentView.addSubview(imageStared)
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
        
        let imageAckView = UIImageView()
        let imageCredentialView = UIImageView()
        let imagePinView = UIImageView()
        if dataMessages[indexPath.row][TypeDataMessage.is_pinned] as? String != nil && dataMessages[indexPath.row][TypeDataMessage.is_pinned] as? String != "0" {
            cell.contentView.addSubview(imagePinView)
            imagePinView.translatesAutoresizingMaskIntoConstraints = false
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                if imageStared.isDescendant(of: cell.contentView){
                    imagePinView.bottomAnchor.constraint(equalTo: imageStared.topAnchor).isActive = true
                } else {
                    imagePinView.bottomAnchor.constraint(equalTo: statusMessage.topAnchor).isActive = true
                }
                imagePinView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            } else {
                if imageStared.isDescendant(of: cell.contentView){
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
            if dataMessages[indexPath.row]["status"] as? String == "8" {
                imageAck = UIImage(named: "ack_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            }
            imageAckView.image = imageAck
            cell.contentView.addSubview(imageAckView)
            imageAckView.translatesAutoresizingMaskIntoConstraints = false
            imageAckView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageAckView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            imageAckView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageAckView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            } else {
                imageAckView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
                let tap = ObjectGesture(target: self, action: #selector(tapAck(_:)))
                tap.indexPath = indexPath
                imageAckView.addGestureRecognizer(tap)
                imageAckView.isUserInteractionEnabled = true
            }
        }
        
        if (dataMessages[indexPath.row]["credential"] as? String) == "1" && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            let imageCredential = UIImage(named: "confidential_icon", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            imageCredentialView.image = imageCredential
            cell.contentView.addSubview(imageCredentialView)
            imageCredentialView.translatesAutoresizingMaskIntoConstraints = false
            imageCredentialView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageCredentialView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            imageCredentialView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                imageCredentialView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
            } else {
                imageCredentialView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
            }
        }
        
        if !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            let imageSpecFileView = UIImageView()
            let imageSpecFile = UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            imageSpecFileView.image = imageSpecFile
            cell.contentView.addSubview(imageSpecFileView)
            imageSpecFileView.translatesAutoresizingMaskIntoConstraints = false
            imageSpecFileView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageSpecFileView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            imageSpecFileView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
            if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                if imageAckView.isDescendant(of: cell.contentView) {
                    imageSpecFileView.leadingAnchor.constraint(equalTo: imageAckView.trailingAnchor, constant: 5).isActive = true
                } else if imageCredentialView.isDescendant(of: cell.contentView) {
                    imageSpecFileView.leadingAnchor.constraint(equalTo: imageCredentialView.trailingAnchor, constant: 5).isActive = true
                } else {
                    imageSpecFileView.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 30).isActive = true
                }
            } else {
                if imageAckView.isDescendant(of: cell.contentView) {
                    imageSpecFileView.trailingAnchor.constraint(equalTo: imageAckView.leadingAnchor, constant: -5).isActive = true
                } else if imageCredentialView.isDescendant(of: cell.contentView) {
                    imageSpecFileView.trailingAnchor.constraint(equalTo: imageCredentialView.leadingAnchor, constant: -5).isActive = true
                } else {
                    imageSpecFileView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
                }
            }
        }
        
        let messageText = UITextView()
        messageText.isEditable = false
        // Fix: isSelectable = false (was true) - like WhatsApp, no drag-to-select or
        // system text-selection UI on message text. Important side effect: a
        // UITextView's OWN built-in link-tap handling (shouldInteractWith) is gated
        // by isSelectable too - with it false, that delegate method never fires
        // anymore, so link taps are now handled by the dedicated tapGesture below
        // instead, entirely independent of isSelectable. (Mirrors the same change in
        // EditorGroup.swift - see its CHANGELOG entries for the full history of why
        // each piece here is the way it is.)
        messageText.isSelectable = false
        messageText.dataDetectorTypes = [.link]
        messageText.backgroundColor = .clear
        messageText.isScrollEnabled = false
        messageText.textContainerInset = UIEdgeInsets.zero
        messageText.contentInset = UIEdgeInsets.zero
        messageText.textDragInteraction?.isEnabled = false
        // Fix: with isSelectable = false, UITextView's own shouldInteractWith(...)
        // never fires for taps anymore - this plain tap recognizer replaces it,
        // entirely independent of isSelectable. Only acts when the tap actually lands
        // on a detected link (via linkHit(at:in:)); taps elsewhere in the message
        // text do nothing here.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMessageTextTap(_:)))
        messageText.addGestureRecognizer(tapGesture)

        // Fix: purely cosmetic - shows the highlight the instant a finger touches a
        // link (minimumPressDuration = 0), and also owns timing the "hold past
        // EditorGroup.linkLongPressThreshold -> show LinkActionSheetViewController"
        // decision (see handleLinkTouchHighlight). Never blocks any other gesture -
        // cancelsTouchesInView = false and the UIGestureRecognizerDelegate
        // conformance below (shouldRecognizeSimultaneouslyWith) keep it purely
        // observational alongside containerMessage's UIContextMenuInteraction.
        let touchHighlightGesture = LinkTouchHighlightGesture(target: self, action: #selector(handleLinkTouchHighlight(_:)))
        touchHighlightGesture.minimumPressDuration = 0
        touchHighlightGesture.textView = messageText
        touchHighlightGesture.delegate = self
        touchHighlightGesture.cancelsTouchesInView = false
        touchHighlightGesture.delaysTouchesBegan = false
        messageText.addGestureRecognizer(touchHighlightGesture)

        containerMessage.addSubview(messageText)
        messageText.translatesAutoresizingMaskIntoConstraints = false
        var topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15)
        topMarginText.priority = .defaultHigh
        messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        messageText.font = .systemFont(ofSize: 12 + offset())
        var messageRequestFriend: String!
        if dataMessages[indexPath.row]["attachment_flag"] as? String == "27" || dataMessages[indexPath.row]["attachment_flag"] as? String == "26" ||
            dataMessages[indexPath.row]["attachment_flag"] as? String == "25" || dataMessages[indexPath.row]["message_scope_id"] as? String == MessageScope.FORM {
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
            } else if dataMessages[indexPath.row]["attachment_flag"] as! String == "25" {
                imageLS.image = UIImage(named: "pb_vroom", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            } else if dataMessages[indexPath.row]["message_scope_id"] as? String == MessageScope.FORM {
                imageLS.image = UIImage(systemName: "doc.richtext.fill")
                imageLS.tintColor = .mainColor
            }
        } else if !audioChat.isEmpty {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 60).isActive = true
        } else {
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
        }
        if dataMessages[indexPath.row]["f_pin"] as? String == "-999" && (dataMessages[indexPath.row]["blog_id"] as? String) != nil && !(dataMessages[indexPath.row]["blog_id"]  as? String ?? "").isEmpty && (dataMessages[indexPath.row]["message_text"]  as? String ?? "").contains("Berikut QR Code dan detil booking Anda") {
            messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -115).isActive = true
            let imageQR = UIImageView()
            containerMessage.addSubview(imageQR)
            imageQR.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageQR.centerXAnchor.constraint(equalTo: containerMessage.centerXAnchor),
                imageQR.topAnchor.constraint(equalTo: messageText.bottomAnchor),
                imageQR.widthAnchor.constraint(equalToConstant: 100.0),
                imageQR.heightAnchor.constraint(equalToConstant: 100.0)
            ])
            imageQR.image = generateQRCode(from: dataMessages[indexPath.row]["blog_id"]  as? String ?? "")
        } else if dataMessages[indexPath.row]["attachment_flag"] as? String == "61" {
            messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -50).isActive = true
            let fPinFriend = dataMessages[indexPath.row]["blog_id"]  as? String ?? ""
            
            let buttonAccept = UIButton(type: .custom)
            buttonAccept.setTitle("Accept".localized(), for: .normal)
            buttonAccept.setBackgroundImage(UIImage(color: UIColor.clear), for: .normal)
            buttonAccept.setBackgroundImage(UIImage(color: UIColor.blueBubbleColor), for: .highlighted)
            buttonAccept.setTitleColor(.black, for: .normal)
            buttonAccept.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            buttonAccept.layer.borderWidth = 2.0
            buttonAccept.layer.borderColor = UIColor.blueBubbleColor.cgColor
            buttonAccept.layer.cornerRadius = 8.0
            buttonAccept.tag = 0
            buttonAccept.restorationIdentifier = "\(fPinFriend),\(messageIdChat)"
            buttonAccept.clipsToBounds = true
            containerMessage.addSubview(buttonAccept)
            buttonAccept.translatesAutoresizingMaskIntoConstraints = false
            
            buttonAccept.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            buttonAccept.topAnchor.constraint(equalTo: messageText.bottomAnchor, constant: 5).isActive = true
            buttonAccept.widthAnchor.constraint(equalToConstant: self.view!.frame.size.width/5).isActive = true
            buttonAccept.heightAnchor.constraint(equalToConstant: 30).isActive = true
            buttonAccept.addTarget(self, action: #selector(addFriendReqAction), for: .touchUpInside)
            
            let buttonDecline = UIButton(type: .custom)
            buttonDecline.setTitle("Decline".localized(), for: .normal)
            buttonDecline.setBackgroundImage(UIImage(color: UIColor.clear), for: .normal)
            buttonDecline.setBackgroundImage(UIImage(color: UIColor.blueBubbleColor), for: .highlighted)
            buttonDecline.setTitleColor(.black, for: .normal)
            buttonDecline.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            buttonDecline.layer.borderWidth = 2.0
            buttonDecline.tag = 1
            buttonDecline.restorationIdentifier = "\(fPinFriend),\(messageIdChat)"
            buttonDecline.layer.borderColor = UIColor.blueBubbleColor.cgColor
            buttonDecline.layer.cornerRadius = 8.0
            buttonDecline.clipsToBounds = true
            containerMessage.addSubview(buttonDecline)
            buttonDecline.translatesAutoresizingMaskIntoConstraints = false
            
            buttonDecline.leadingAnchor.constraint(equalTo: buttonAccept.trailingAnchor, constant: 10).isActive = true
            buttonDecline.topAnchor.constraint(equalTo: messageText.bottomAnchor, constant: 5).isActive = true
            buttonDecline.widthAnchor.constraint(equalToConstant: self.view!.frame.size.width/5).isActive = true
            buttonDecline.heightAnchor.constraint(equalToConstant: 30).isActive = true
            buttonDecline.addTarget(self, action: #selector(addFriendReqAction), for: .touchUpInside)
            
            let textName = textChat.components(separatedBy: "~")[0]
            let textAfterName = textChat.components(separatedBy: "~")[1]
            messageRequestFriend = textName + " " + textAfterName.localized()
        } else {
            let bottomConstraint = messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -15)
            bottomConstraint.priority = .defaultHigh
            bottomConstraint.isActive = true
        }
        messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
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
        var stringLS = ""
        if let attachmentFlag = dataMessages[indexPath.row]["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
            if attachmentFlag == "27" || attachmentFlag == "26" { // live streaming
                let data = textChat
                if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    let title = json["title"] as? String ?? ""
                    let description = json["description"] as? String ?? ""
                    let start = json["time"] as? Int64 ?? 0
                    let by = json["by"] as? String ?? ""
                    let textLS = "Live Streaming".localized()
                    var type = "*\(textLS)*"
                    if attachmentFlag == "26" {
                        let textSeminar = "Seminar".localized()
                        type = "*\(textSeminar)*"
                    }
                    if let c = User.getData(pin: by) {
                        let name = c.fullName
                        stringLS = "\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm")) \nBroadcaster: \(name)"
                    } else {
                        stringLS = ("\(type) \nTitle: \(title) \nDescription: \(description) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm"))")
                    }
                    messageText.attributedText = stringLS.richText()
                    messageText.isUserInteractionEnabled = false
                }
            }
            else if attachmentFlag == "25" {
                let data = textChat
                if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    let title = json["title"] as? String ?? ""
                    let blog = json["blog"] as? String ?? ""
                    let by = json["by"] as? String ?? ""
                    let start = json["time"] as? Int64 ?? 0
                    let textVCR = "Video Conference Room".localized()
                    var type = "*\(textVCR)*"
                    if let c = User.getData(pin: by) {
                        let name = c.fullName
                        stringLS = "\(type) \nTitle: \(title) \nStart: \(Date(milliseconds: start).format(dateFormat: "dd/MM/yyyy HH:mm")) \nInitiator: \(name) \n\n*^Room ID: ^*\n*^\(blog)^*"
                    }
                    messageText.attributedText = stringLS.richText()
                    messageText.isUserInteractionEnabled = false
                }
            }
            else if attachmentFlag == "61" {
                messageText.attributedText = messageRequestFriend.richText()
                messageText.isUserInteractionEnabled = false
            }
            else if attachmentFlag == "11" && dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1" && dataMessages[indexPath.row]["lock"] as? String != "2" {
                messageText.text = ""
                topMarginText.constant = topMarginText.constant + 100
                containerMessage.addSubview(imageSticker)
                imageSticker.translatesAutoresizingMaskIntoConstraints = false
                let data = queryMessageReply(message_id: reffChat)
                if reffChat.isEmpty || data.count == 0 {
                    imageSticker.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
                    imageSticker.widthAnchor.constraint(equalToConstant: 80).isActive = true
                } else {
                    imageSticker.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
                }
                imageSticker.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                imageSticker.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
                imageSticker.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
                var imageStickerBundle = UIImage(named: (textChat.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                if imageStickerBundle == nil {
                    imageStickerBundle = UIImage(named: (textChat.components(separatedBy: "/")[1]), in: Bundle.resourcesMediaBundle(for: Nexilis.self), with: nil)
                }
                imageSticker.image = imageStickerBundle //resourcesMediaBundle
                imageSticker.contentMode = .scaleAspectFit
            } else if dataMessages[indexPath.row]["message_scope_id"]  as? String ?? "" == MessageScope.FORM {
                let data = textChat
                if let jsonForm = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    let form_title = jsonForm["form_title"]  as? String ?? ""
                    let club_type = jsonForm["club_type"]  as? String ?? ""
                    let province = jsonForm["province"]  as? String ?? ""
                    let club = jsonForm["club"]  as? String ?? ""
                    messageText.attributedText = "*\(form_title.replacingOccurrences(of: "+", with: " "))* \nClub Type: \(club_type) \nProvince: \(province) \nClub Name: \(club) ".richText()
                    messageText.isUserInteractionEnabled = false
                }
            }
            else {
                messageText.attributedText = textChat.richText()
                modifyText(at: indexPath)
            }
        } else {
            messageText.attributedText = textChat.richText()
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
            let finalAttributed = NSMutableAttributedString(attributedString: text.richText())

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
        
        if dataMessages[indexPath.row][TypeDataMessage.message_scope_id] as? String == MessageScope.CALL || dataMessages[indexPath.row][TypeDataMessage.message_scope_id] as? String == MessageScope.MISSED_CALL{
            messageText.removeFromSuperview()
            
            let containerCall = UIButton(type: .custom)
            containerCall.backgroundColor = .white.withAlphaComponent(0.3)
            containerMessage.addSubview(containerCall)
            containerCall.anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, right: containerMessage.rightAnchor, paddingTop: 5, paddingLeft: 5, paddingBottom: 5, paddingRight: 5, height: 60)
            containerCall.layer.cornerRadius = 5
            containerCall.clipsToBounds = true
            
            var imageCall = "phone.fill.arrow.up.right"
            var textCall = "Audio call".localized()
            let isVideo = textChat.lowercased().contains("video")
            let isMissedCall = textChat.lowercased().contains("missed")
            let isImageLeft = textChat.lowercased().contains("incoming") || isMissedCall
            let longCall = textChat.components(separatedBy: " at ")[1]
            var subTextCall = longCall
            
            let contIconCall = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            containerCall.addSubview(contIconCall)
            contIconCall.anchor(top: containerCall.topAnchor, left: containerCall.leftAnchor, bottom: containerCall.bottomAnchor, paddingTop: 10, paddingLeft: 10, paddingBottom: 10, width: 40, height: 40)
            contIconCall.circle()
            if isImageLeft {
                contIconCall.backgroundColor = .white
            } else {
                contIconCall.backgroundColor = .black.withAlphaComponent(0.6)
            }
            
            if isVideo && isImageLeft {
                imageCall = "arrow.down.left.video.fill"
                if isMissedCall {
                    textCall = "Missed video call".localized()
                    subTextCall = "Tap to call back".localized()
                } else {
                    textCall = "Video call".localized()
                }
            } else if isVideo {
                imageCall = "arrow.up.right.video.fill"
                textCall = "Video call".localized()
                if longCall.trimmingCharacters(in: .whitespaces) == "0" {
                    subTextCall = "No answer".localized()
                }
            } else if isImageLeft {
                imageCall = "phone.fill.arrow.down.left"
                if isMissedCall {
                    textCall = "Missed audio call".localized()
                    subTextCall = "Tap to call back".localized()
                }
            } else if longCall.trimmingCharacters(in: .whitespaces) == "0" {
                subTextCall = "No answer".localized()
            }
            
            let iconCall = UIImageView()
            iconCall.image = UIImage(systemName: imageCall, withConfiguration: UIImage.SymbolConfiguration(pointSize: 18))
            contIconCall.addSubview(iconCall)
            if isMissedCall {
                iconCall.tintColor = .red
            }else if isImageLeft {
                iconCall.tintColor = .black
            } else {
                iconCall.tintColor = .white
            }
            iconCall.anchor(centerX: contIconCall.centerXAnchor, centerY: contIconCall.centerYAnchor)
            
            let titleCall = UILabel()
            containerCall.addSubview(titleCall)
            titleCall.anchor(top: containerCall.topAnchor, left: contIconCall.rightAnchor, right: containerCall.rightAnchor, paddingTop: 10, paddingLeft: 10, paddingRight: 10)
            titleCall.text = textCall
            titleCall.font = .systemFont(ofSize: 14)
            
            let subtitleCall = UILabel()
            containerCall.addSubview(subtitleCall)
            subtitleCall.anchor(top: titleCall.bottomAnchor, left: contIconCall.rightAnchor, right: containerCall.rightAnchor, paddingLeft: 10, paddingRight: 10)
            subtitleCall.text = subTextCall
            subtitleCall.font = .systemFont(ofSize: 13)
            subtitleCall.textColor = .gray
        }
        
        if !copySession && !forwardSession && !deleteSession && !summarizeSession && !self.removed {
            let interaction = UIContextMenuInteraction(delegate: self)
            containerMessage.addInteraction(interaction)
            containerMessage.isUserInteractionEnabled = true
        }
        
        if isSearching && textSearch.count > 1 && dataMessages[indexPath.row][TypeDataMessage.message_scope_id] as? String != MessageScope.CALL && dataMessages[indexPath.row][TypeDataMessage.message_scope_id] as? String != MessageScope.MISSED_CALL && dataMessages[indexPath.row][TypeDataMessage.attachment_flag] as? String != "11" && !(dataMessages[indexPath.row][TypeDataMessage.message_id] as! String).contains("NTFPIN_") {
            messageText.attributedText = messageRequestFriend != nil ? messageRequestFriend.richText(isSearching: true, textSearch: textSearch) : stringLS.isEmpty ? textChat.richText(isSearching: true, textSearch: textSearch) : stringLS.richText(isSearching: true, textSearch: textSearch)
        }
        
        let stringDate = (dataMessages[indexPath.row]["server_date"] as? String) ?? ""
        if !stringDate.isEmpty {
            if (dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2"  && dataMessages[indexPath.row]["lock"] as? String != "1" {
                if dataTimer != nil {
                    if dataTimer! >= 10 {
                        timeMessage.text = "00:\(dataTimer!)"
                    } else {
                        timeMessage.text = "00:0\(dataTimer!)"
                    }
                    timeMessage.textColor = .systemRed
                }
            } else {
                let date = Date(milliseconds: Int64(stringDate) ?? 100)
                timeMessage.text = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                timeMessage.textColor = .lightGray
            }
            timeMessage.font = UIFont.systemFont(ofSize: 10 + offset(), weight: .medium)
            if dataMessages[indexPath.row][TypeDataMessage.last_edit] != nil && dataMessages[indexPath.row][TypeDataMessage.last_edit] as! Int64 != 0 {
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
            var padTop: CGFloat = 15
            if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int != 0 {
                padTop = 35
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
                topMarginText.constant = topMarginText.constant + 205
                var constTop = 5.0
                if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int != 0 {
                    topMarginText.constant = topMarginText.constant + 10
                    constTop = 35.0
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
                    
                    if (dataMessages[indexPath.row]["f_pin"] as? String == idMe && dataMessages[indexPath.row][TypeDataMessage.message_scope_id] as? String != MessageScope.CALL && dataMessages[indexPath.row][TypeDataMessage.message_scope_id] as? String != MessageScope.MISSED_CALL) {
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
                        else if listImages[i].status == "2" {
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
                topMarginText.constant = topMarginText.constant + (getHeightImage < 40 ? 45 : getHeightImage + 5)
                
                containerMessage.addSubview(imageThumb)
                imageThumb.frame = CGRect(x: 0, y: 0, width: getWidthImage, height: getHeightImage)
                imageThumb.translatesAutoresizingMaskIntoConstraints = false
                let data = queryMessageReply(message_id: reffChat)
                if (reffChat.isEmpty || data.count == 0) && (dataMessages[indexPath.row][TypeDataMessage.is_forwarded] == nil || dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int == 0) {
                    imageThumb.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
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
                
                if (dataMessages[indexPath.row]["progress"] as! Double != 100.0 && dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
                    let container = UIView()
                    imageThumb.addSubview(container)
                    container.translatesAutoresizingMaskIntoConstraints = false
                    container.bottomAnchor.constraint(equalTo: imageThumb.bottomAnchor, constant: -10).isActive = true
                    container.leadingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: 10).isActive = true
                    container.widthAnchor.constraint(equalToConstant: 30).isActive = true
                    container.heightAnchor.constraint(equalToConstant: 30).isActive = true
                    container.backgroundColor = .white.withAlphaComponent(0.1)
                    let circlePath = UIBezierPath(arcCenter: CGPoint(x: 10, y: 20), radius: 15, startAngle: -(.pi / 2), endAngle: .pi * 2, clockwise: true)
                    let trackShape = CAShapeLayer()
                    trackShape.path = circlePath.cgPath
                    trackShape.fillColor = UIColor.black.withAlphaComponent(0.3).cgColor
                    trackShape.lineWidth = 3
                    trackShape.strokeColor = UIColor.mentionColor.withAlphaComponent(0.3).cgColor
                    container.backgroundColor = .clear
                    container.layer.addSublayer(trackShape)
                    let shapeLoading = CAShapeLayer()
                    shapeLoading.path = circlePath.cgPath
                    shapeLoading.fillColor = UIColor.clear.cgColor
                    shapeLoading.lineWidth = 3
                    shapeLoading.strokeEnd = 0
                    shapeLoading.strokeColor = UIColor.mentionColor.cgColor
                    container.layer.addSublayer(shapeLoading)
                    let imageupload = UIImageView(image: UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold, scale: .default)))
                    imageupload.tintColor = .white
                    container.addSubview(imageupload)
                    imageupload.translatesAutoresizingMaskIntoConstraints = false
                    imageupload.bottomAnchor.constraint(equalTo: imageThumb.bottomAnchor, constant: -10).isActive = true
                    imageupload.leadingAnchor.constraint(equalTo: imageThumb.leadingAnchor, constant: 10).isActive = true
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
                }
                
                if !copySession && !forwardSession && !deleteSession && !summarizeSession {
                    let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                    let sfs = (dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String) ?? ""
                    imageThumb.isUserInteractionEnabled = true
                    imageThumb.addGestureRecognizer(objectTap)
                    objectTap.image_id = imageChat
                    objectTap.video_id = videoChat
                    objectTap.gif_id = gifChat
                    objectTap.imageView = imageThumb
                    objectTap.specFile = sfs
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
                    if var dataFile = try? FileEncryption.shared.readSecure(filename: fileChat), textChat.isEmpty {
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
                }
            }
            
            containerMessage.addSubview(containerViewFile)
            containerViewFile.translatesAutoresizingMaskIntoConstraints = false
            let data = queryMessageReply(message_id: reffChat)
            if (reffChat.isEmpty || data.count == 0) && (dataMessages[indexPath.row][TypeDataMessage.is_forwarded] == nil || dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int == 0) {
                containerViewFile.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
            } else {
                containerViewFile.heightAnchor.constraint(equalToConstant: 50).isActive = true
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
            
            if (dataMessages[indexPath.row]["progress"] as! Double != 100.0) {
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
                trackShape.strokeColor = UIColor.mentionColor.withAlphaComponent(0.3).cgColor
                containerLoading.layer.addSublayer(trackShape)
                let shapeLoading = CAShapeLayer()
                shapeLoading.path = circlePath.cgPath
                shapeLoading.fillColor = UIColor.clear.cgColor
                shapeLoading.lineWidth = 3
                shapeLoading.strokeEnd = 0
                shapeLoading.strokeColor = UIColor.mentionColor.cgColor
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
                        let title = data["title"]  as? String ?? ""
                        let description = data["description"]  as? String ?? ""
                        let imageUrl = data["imageUrl"] as? String
                        let link = data["link"]  as? String ?? ""
                        
                        topMarginText.constant = topMarginText.constant + 85
                        
                        containerMessage.addSubview(containerLinkMessage)
                        containerLinkMessage.translatesAutoresizingMaskIntoConstraints = false
                        containerLinkMessage.leadingAnchor.constraint(equalTo:containerMessage.leadingAnchor, constant: 15).isActive = true
                        containerLinkMessage.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
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
                        
                        if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int != 0 {
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
        
        if (!reffChat.isEmpty && dataMessages[indexPath.row]["message_scope_id"]  as? String ?? "" != MessageScope.FORM) {
            let chatGroup = Chat.getMessageFromId(message_id: reffChat)
            if chatGroup.count != 0 {
                let containerReply = UIView()
                containerMessage.addSubview(containerReply)
                containerReply.translatesAutoresizingMaskIntoConstraints = false
                containerReply.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
                containerReply.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
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
                let f_pin = chatGroup[0].fpin
                if f_pin == idMe {
                    if chatGroup[0].messageScope != MessageScope.GROUP {
                        titleReply.text = "You".localized()
                    } else {
                        titleReply.text = "You".localized() + " ● " + "\(chatGroup[0].groupName)(\(chatGroup[0].name))"
                    }
                } else {
                    if isContactCenter {
                        let user: [User] = users.filter({$0.pin == f_pin})
                        titleReply.text = user.first!.fullName
                    } else {
                        if chatGroup[0].messageScope != MessageScope.GROUP {
                            titleReply.text = self.dataPerson["name"]!!
                        } else {
                            if let dataPerson = User.getData(pin: f_pin) {
                                let namePerson = dataPerson.fullName
                                titleReply.text = namePerson + " ● " + "\(chatGroup[0].groupName)(\(chatGroup[0].name))"
                            }
                        }
                    }
                }
                if dataMessages[indexPath.row]["f_pin"] as? String == idMe {
                    titleReply.textColor = .white
                    leftReply.backgroundColor = .white
                } else {
                    titleReply.textColor = .mainColor
                    leftReply.backgroundColor = .mainColor
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
                let message_text = chatGroup[0].messageText
                let attachment_flag = chatGroup[0].attachmentFlag
                let thumb_chat = chatGroup[0].thumb
                let image_chat = chatGroup[0].image
                let video_chat = chatGroup[0].video
                let file_chat = chatGroup[0].file
                if (attachment_flag == "0" && thumb_chat == "") {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.attributedText = message_text.richText()
                } else if (attachment_flag == "1" || image_chat != "") {
                    if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                        contentReply.text = "📷 Photo".localized()
                    } else {
                        contentReply.attributedText = message_text.richText()
                    }
                } else if (attachment_flag == "2" || video_chat != "") {
                    if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                        contentReply.text = "📹 Video".localized()
                    } else {
                        contentReply.attributedText = message_text.richText()
                    }
                } else if (attachment_flag == "6" || file_chat != ""){
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
                } else if (attachment_flag == "11") {
                    contentReply.text = "❤️ Sticker"
                }
                contentReply.textColor = .white.withAlphaComponent(0.8)
                
                if (attachment_flag == "1" || attachment_flag == "2" || image_chat != "" || video_chat != "") {
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(thumb_chat)
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
                }
                if (attachment_flag == "11" && message_text.components(separatedBy: "/").count > 1) {
                    let imageSticker = UIImageView(image: UIImage(named: (message_text.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil))
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
                    objectTap.message_id = chatGroup[0].messageId
                }
            }
        }
        if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int != 0 && !isLoadingShowLink {
            showForwardedSign()
        }
        
        func showForwardedSign() {
            topMarginText.constant = topMarginText.constant + 20
            
            let containerForwarded = UIView()
            containerMessage.addSubview(containerForwarded)
            containerForwarded.translatesAutoresizingMaskIntoConstraints = false
            containerForwarded.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            containerForwarded.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
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
                if data.count != 0 && (topMarginText.constant == 15.0 || topMarginText.constant == 100.0) {
                    addTopMargin = false
                }
            }
            if addTopMargin{
                topMarginText.isActive = true
            }
        }
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureCellAction))
//        panGestureRecognizer.delegate = self
//        cellMessage.addGestureRecognizer(panGestureRecognizer)
        return cell
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
        listGroupingImages.imageTapped = sender.indexImageTapped
        listGroupingImages.listGroupingImages = sender.listImageFromGrouping
        listGroupingImages.titleName = titleText
        listGroupingImages.isInitiator = sender.isInitiator
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
        if blocking == "1" {
            self.view.makeToast("You blocked this user".localized(), duration: 3)
            return
        }
        if blocking == "-1" {
            self.view.makeToast("You have been blocked by this user".localized(), duration: 3)
            return
        }
        let indexPath = sender.indexPath
        let dataMessages = self.messages(onDate: dataDates[indexPath.section])
        if dataMessages[indexPath.row]["status"]  as? String ?? "" == "8" {
            return
        }
        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
            imageView.tintColor = .white
            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
            banner.show()
            return
        }
        DispatchQueue.global().async {
            let result = Nexilis.write(message: CoreMessage_TMessageBank.getAckLocationMessage(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "", message_id: dataMessages[indexPath.row]["message_id"]  as? String ?? "", l_pin: dataMessages[indexPath.row]["l_pin"]  as? String ?? "", server_date: "\(Date().currentTimeMillis())", message_scope_id: dataMessages[indexPath.row]["message_scope_id"]  as? String ?? "", longitude: self.longitude, latitude: self.latitude, description: ""))
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
    
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        let velocity : CGPoint = gestureRecognizer.location(in: tableChatView)
//        if velocity.x < 0 {
//            return false
//        }
//        return abs(Float(velocity.x)) > abs(Float(velocity.y))
//    }
//
//    @objc func panGestureCellAction(recognizer: UIPanGestureRecognizer)  {
//        let translation = recognizer.translation(in: tableChatView)
//        let x = recognizer.view?.frame.origin.x ?? 0
//        if x >= -(recognizer.view?.frame.size.width ?? 0) * 0.05 {
//            recognizer.view?.center = CGPoint(
//                x: (recognizer.view?.center.x ?? 0) + translation.x,
//                y: (recognizer.view?.center.y ?? 0))
//            recognizer.setTranslation(CGPoint(x: 0, y: 0), in: view)
//            if (recognizer.view?.frame.origin.x ?? 0) > UIScreen.main.bounds.size.width * 0.9 {
//                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
//                    recognizer.view?.frame = CGRect(x: 0, y: recognizer.view?.frame.origin.y ?? 0, width: recognizer.view?.frame.size.width ?? 0, height: recognizer.view?.frame.size.height ?? 0)
//                })
//            }
//        }
//        if x <= -(recognizer.view?.frame.size.width ?? 0) * 0.05 {
//            let idMe = User.getMyPin() as String?
//            let indexPath = self.tableChatView.indexPath(for: recognizer.view! as! UITableViewCell)
//            let dataMessages = self.messages(onDate: dataDates[indexPath!.section])
//            if (dataMessages[indexPath!.row]["f_pin"] as? String == idMe) {
//                let messageInfoVC = MessageInfo()
//                messageInfoVC.data = dataMessages[indexPath!.row]
//                self.navigationController?.pushViewController(messageInfoVC, animated: true)
//                return
//            }
//        }
//        if x >= ((recognizer.view?.frame.size.width ?? 0) * 0.2) {
//            if !hapticSwipeLeft {
//                UINotificationFeedbackGenerator().notificationOccurred(.success)
//            }
//            hapticSwipeLeft = true
//        } else if x < ((recognizer.view?.frame.size.width ?? 0) * 0.2) {
//            hapticSwipeLeft = false
//        }
//        if recognizer.state == .ended {
//            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
//                recognizer.view?.frame = CGRect(x: 0, y: recognizer.view?.frame.origin.y ?? 0, width: recognizer.view?.frame.size.width ?? 0, height: recognizer.view?.frame.size.height ?? 0)
//            } completion: { (finished) in
//                if x > ((recognizer.view?.frame.size.width ?? 0) * 0.2) {
//                    self.hapticSwipeLeft = false
//
//                }
//            }
//        }
//    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == tableMention || tableView == tableMentionEdit || tableView == tableViewConfigFile {
            return 1
        }
        return dataDates.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tableMention || tableView == tableMentionEdit {
            return listMentionWithText.count
        }
        if tableView == tableViewConfigFile {
            return 2
        }
        let dateKey = dataDates[section]
        return messagesByDate[dateKey]?.count ?? 0
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
            if (Nexilis.checkingAccess(key: "secure_folder_share") || sender.specFile.contains("download") || sender.specFile.contains("share")) && dataMessages[indexPath.row]["credential"] as? String != "1" {
                let shareAction = UIAction { _ in
                    var activityViewController = UIActivityViewController(activityItems: [""], applicationActivities: nil)
                    if type == 1 {
                        activityViewController = UIActivityViewController(activityItems: [url ?? URL(string: "")!], applicationActivities: nil)
                    } else {
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ImageSharedNexilis-\(Date().currentTimeMillis())" + ".jpeg")
                        try? data!.write(to: tempURL)
                        activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                    }
                    activityViewController.popoverPresentationController?.sourceView = imageViewer.view
                    imageViewer.present(activityViewController, animated: true, completion: nil)
                }
                let shareButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "square.and.arrow.up"), primaryAction: shareAction, menu: nil)
                imageViewer.navigationItem.rightBarButtonItem = shareButton
            }
            
            let user = User.getData(pin: dataMessages[indexPath.row]["f_pin"] as? String)
            let name = user?.fullName
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
            navigationController.transitioningDelegate = transitionDelegate
            self.transitioningDelegateRef = transitionDelegate
            
            present(navigationController, animated: true) {
                imageViewer.animateBackgroundIn()
            }
        }
        if (sender.image_id != "") {
            if let dirPath = paths.first {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.image_id)
                if FileManager.default.fileExists(atPath: imageURL.path) {
                    self.previewItem = imageURL as NSURL
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
                    // Fix: this used to put a spinner of its own on the bubble. The progress ring
                    // cellForRow draws does that job now - for images as well as videos - so all this
                    // has left to do is redraw the row once the file is here.
                    Download().startHTTP(forKey: sender.image_id) { [weak self] (name, progress) in
                        guard progress >= 100 || progress < 0 else {
                            return
                        }
                        DispatchQueue.main.async {
                            self?.reloadMessageRow(withFileNamed: name)
                        }
                    }
                    // Draw the row again so the ring appears straight away, at whatever progress the
                    // transfer is already at.
                    reloadMessageRow(withFileNamed: sender.image_id)
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
                    // Fix: this also compared the index path, so the same file could be started
                    // again from a row that had shifted, stacking a second progress ring on the
                    // bubble. All that matters is whether this screen is already following it.
                    if downloadList[sender.video_id] != nil {
                        return
                    }
                    downloadList[sender.video_id] = sender.indexPath
                    // Fix: this used to build a progress ring by hand, onto the one cell instance that
                    // had been tapped - lost the moment that cell was recycled. cellForRow draws it now,
                    // and onDownloadChat moves it, so this only has to start the transfer.
                    Download().startHTTP(forKey: sender.video_id) { [weak self] (name, progress) in
                        guard progress >= 100 || progress < 0 else {
                            return
                        }
                        DispatchQueue.main.async {
                            guard let self = self else {
                                return
                            }
                            // A download that failed used to stay in downloadList forever, and the guard
                            // above this call then swallowed every retry.
                            self.downloadList.removeValue(forKey: name)
                            if progress >= 100, let idx = self.dataMessages.firstIndex(where: { $0["video_id"] as? String ?? "" == name }) {
                                self.dataMessages[idx]["progress"] = 100.0
                            }
                            self.reloadMessageRow(withFileNamed: name)
                        }
                    }
                    // Draw the row again so the ring appears straight away, at whatever progress the
                    // transfer is already at.
                    reloadMessageRow(withFileNamed: sender.video_id)
                }
            }
        } else if (sender.file_id != "") {
            func showFile(urlFile: URL, isFile: Bool = true) {
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
                    // Fix: this also compared the index path, so the same file could be started
                    // again from a row that had shifted, stacking a second progress ring on the
                    // bubble. All that matters is whether this screen is already following it.
                    if downloadList[sender.file_id] != nil {
                        return
                    }
                    downloadList[sender.file_id] = sender.indexPath
                    // Fix: this used to build a progress ring by hand, onto the one cell instance that
                    // had been tapped - lost the moment that cell was recycled. cellForRow draws it now,
                    // and onDownloadChat moves it, so this only has to start the transfer.
                    Download().startHTTP(forKey: sender.file_id) { [weak self] (name, progress) in
                        guard progress >= 100 || progress < 0 else {
                            return
                        }
                        DispatchQueue.main.async {
                            guard let self = self else {
                                return
                            }
                            // A download that failed used to stay in downloadList forever, and the guard
                            // above this call then swallowed every retry.
                            self.downloadList.removeValue(forKey: name)
                            if progress >= 100, let idx = self.dataMessages.firstIndex(where: { $0["file_id"] as? String ?? "" == name }) {
                                self.dataMessages[idx]["progress"] = 100.0
                            }
                            self.reloadMessageRow(withFileNamed: name)
                        }
                    }
                    // Draw the row again so the ring appears straight away, at whatever progress the
                    // transfer is already at.
                    reloadMessageRow(withFileNamed: sender.file_id)
                }
            }
        } else {
            let chatGroup = Chat.getMessageFromId(message_id: sender.message_id)
            if chatGroup.count > 0 && chatGroup[0].messageScope == "4" {
                let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                editorGroupVC.hidesBottomBarWhenPushed = true
                editorGroupVC.unique_l_pin = chatGroup[0].pin == chatGroup[0].groupId ? chatGroup[0].groupId : chatGroup[0].pin
                editorGroupVC.referenceMessageId = sender.message_id
                editorGroupVC.referenceChatDate = chatDate(stringDate: chatGroup[0].serverDate)
                navigationController?.show(editorGroupVC, sender: nil)
                return
            }
            DispatchQueue.main.async {
                // This is the jump to a quoted or pinned message. What is jumped to is by
                // nature older and may sit above the loaded window - without this the lookup
                // below finds nothing and the tap does nothing at all.
                self.ensureMessageLoaded(messageId: sender.message_id)
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == sender.message_id})
                if idx == nil {
                    return
                }
                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"]  as? String ?? "")
                if section == nil {
                    return
                }
                let row = self.messages(onDate: self.dataDates[section!]).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String})
                if row == nil {
                    return
                }
                let indexPath = IndexPath(row: row!, section: section!)
                self.tableChatView.safeScrollToRow(at: indexPath, at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        let containerMessage = cell.contentView.subviews[0]
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

    func highlightedText(for text: String, textView: UITextView) -> NSAttributedString {
        let mutableAttributedString = textView.attributedText!.mutableCopy() as! NSMutableAttributedString
        if let range = textView.attributedText.string.range(of: text) {
            let nsRange = NSRange(range, in: textView.attributedText.string)
            mutableAttributedString.addAttribute(.backgroundColor, value: UIColor.lightGray.withAlphaComponent(0.5), range: NSRange(range, in: text))
        }
        return mutableAttributedString
    }
    
    func removeHighlightedText(for text: String, textView: UITextView) -> NSAttributedString {
        let mutableAttributedString = textView.attributedText!.mutableCopy() as! NSMutableAttributedString
        if let range = textView.attributedText.string.range(of: text) {
            let nsRange = NSRange(range, in: textView.attributedText.string)
            mutableAttributedString.removeAttribute(.backgroundColor, range: NSRange(range, in: text))
        }
        return mutableAttributedString
    }
    
    // Fix: delegates to LinkOpener.swift - the single shared, corrected
    // implementation also used by EditorGroup, EditorStarMessages, ChatGPTBotView,
    // and MessageInfo. See LinkOpener.swift for the full list of bugs fixed
    // (broken custom instagram://twitter://youtube:// deep links that "succeeded"
    // but always landed on the app's home screen instead of the tapped content).
    @objc func tapMessageText(_ sender: ObjectGesture) {
        LinkOpener.open(urlString: sender.message_id)
    }

    // Fix: mirrors EditorGroup.swift's link popup/highlight glue - see its CHANGELOG
    // entries for the full history of why this code is shaped the way it is.
    // presentLinkActionSheet: WhatsApp-style bottom sheet via UISheetPresentationController
    // (iOS 15+), falling back to a plain UIAlertController action sheet on iOS 14.
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
        let chromeOpenURL = LinkHighlighting.chromeURL(for: urlString)
        let chromeInstalled = chromeOpenURL.map { UIApplication.shared.canOpenURL($0) } ?? false
        let openInChromeAction: (() -> Void)? = chromeInstalled ? { [weak self] in
            guard let chromeOpenURL = chromeOpenURL else { return }
            UIApplication.shared.open(chromeOpenURL, options: [:]) { success in
                if !success {
                    let gesture = ObjectGesture()
                    gesture.message_id = urlString
                    self?.tapMessageText(gesture)
                }
            }
        } : nil

        if #available(iOS 15.0, *) {
            let sheetVC = LinkActionSheetViewController(urlString: urlString, onOpen: openAction, onCopy: copyAction, onOpenInChrome: openInChromeAction)
            sheetVC.onDismissed = { [weak self] in self?.hideLinkHighlight() }

            if let sheet = sheetVC.sheetPresentationController {
                if #available(iOS 16.0, *) {
                    let contentHeight = sheetVC.preferredContentHeight(forWidth: self.view.bounds.width)
                    sheet.detents = [.custom(resolver: { _ in contentHeight })]
                } else {
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
            if let popover = alert.popoverPresentationController {
                popover.sourceView = sourceView
                popover.sourceRect = sourceRect
            }
            present(alert, animated: true)
        }
    }

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

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is LinkTouchHighlightGesture || otherGestureRecognizer is LinkTouchHighlightGesture {
            return true
        }
        return false
    }

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
                guard self.linkPressGeneration == thisGeneration else { return }
                self.suppressNextLinkTap = true
                self.suppressLinkTapToken += 1
                let myToken = self.suppressLinkTapToken
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
                hideLinkHighlight()
                linkPressGeneration += 1
            }

        case .ended, .cancelled, .failed:
            linkPressGeneration += 1
            hideLinkHighlight()

        default:
            break
        }
    }

    @objc private func handleMessageTextTap(_ sender: UITapGestureRecognizer) {
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
//        messageInfoVC.data = dataMessages[indexPath.row]
//        self.navigationController?.show(messageInfoVC, sender: nil)
//        return UISwipeActionsConfiguration()
//    }
//
//    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        if copySession || forwardSession || deleteSession || summarizeSession {
//            return nil
//        }
//        let action = UIContextualAction(style: .normal, title: "Reply") { [weak self] (action, view, completionHandler) in
//            let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
//            feedbackGenerator.impactOccurred()
//
//            self?.handleReply(indexPath: indexPath)
//            completionHandler(true)
//        }
//        action.title = nil
//        action.backgroundColor = .white
//        action.image = UIImage(systemName: "arrowshape.turn.up.left.circle.fill")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
//        let config = UISwipeActionsConfiguration(actions: [action])
//        config.performsFirstActionWithFullSwipe = false
//        return config
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
            label.attributedText = newText.richText(fontSize: 14)
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
        var chatGroup: [Chat] = []
        if reffId.isEmpty {
            self.deleteReplyView()
            if dataMessagesImage.count != 0 {
                dataMessages = [dataMessagesImage]
            } else {
                self.textFieldSend.becomeFirstResponder()
            }
            self.reffId = dataMessages[indexPath.row]["message_id"] as? String
        } else {
            dataMessages = self.dataMessages.filter({ $0["message_id"]  as? String ?? "" == reffId })
            if dataMessages.count == 0  {
                chatGroup = Chat.getMessageFromId(message_id: reffId)
            }
            self.reffId = reffId
        }
        if dataMessages.count == 0 && chatGroup.count == 0 {
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
        self.containerPreviewReply.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .secondaryColor
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
        let f_pin = chatGroup.count == 0 ? (dataMessages[indexPath.row]["f_pin"] as? String ?? "") : chatGroup[0].fpin
        if f_pin == idMe {
            titleReply.text = "You".localized()
        } else {
            if self.isContactCenter {
                let user: [User] = self.users.filter({$0.pin == dataMessages[indexPath.row]["f_pin"] as? String})
                titleReply.text = user.first!.fullName
            } else {
                if chatGroup.count == 0 {
                    titleReply.text = self.dataPerson["name"]!!
                } else {
                    if let dataPerson = User.getData(pin: f_pin) {
                        let namePerson = dataPerson.fullName
                        titleReply.text = namePerson + " ● " + "\(chatGroup[0].groupName)(\(chatGroup[0].name))"
                    }
                }
            }
        }
        titleReply.textColor = .orangeColor
        
        let contentReply = UILabel()
        self.containerPreviewReply.addSubview(contentReply)
        contentReply.translatesAutoresizingMaskIntoConstraints = false
        contentReply.leadingAnchor.constraint(equalTo: leftReply.leadingAnchor, constant: 10).isActive = true
        contentReply.trailingAnchor.constraint(equalTo: containerPreviewReply.trailingAnchor, constant: -20).isActive = true
        contentReply.topAnchor.constraint(equalTo: titleReply.bottomAnchor).isActive = true
        contentReply.font = UIFont.systemFont(ofSize: 10 + offset())
        let message_text = chatGroup.count == 0 ? (dataMessages[indexPath.row]["message_text"] as? String ?? "") : chatGroup[0].messageText
        let attachment_flag = chatGroup.count == 0 ? (dataMessages[indexPath.row]["attachment_flag"] as? String ?? "") : chatGroup[0].attachmentFlag
        let thumb_chat = chatGroup.count == 0 ? (dataMessages[indexPath.row]["thumb_id"] as? String ?? "") : chatGroup[0].thumb
        let image_chat = chatGroup.count == 0 ? (dataMessages[indexPath.row]["image_id"] as? String ?? "") : chatGroup[0].image
        let video_chat = chatGroup.count == 0 ? (dataMessages[indexPath.row]["video_id"] as? String ?? "") : chatGroup[0].video
        let file_chat = chatGroup.count == 0 ? (dataMessages[indexPath.row]["file_id"] as? String ?? "") : chatGroup[0].file
        if (attachment_flag == "0" && thumb_chat == "") {
            contentReply.attributedText = message_text.richText()
        } else if (attachment_flag == "1" || image_chat != "") {
            if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                contentReply.text = "📷 Photo".localized()
            } else {
                contentReply.attributedText = message_text.richText()
            }
        } else if (attachment_flag == "2" || video_chat != "") {
            if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                contentReply.text = "📹 Video".localized()
            } else {
                contentReply.attributedText = message_text.richText()
            }
        } else if (attachment_flag == "6" || file_chat != ""){
            contentReply.text = "📄 \(message_text.components(separatedBy: "|")[0])"
        } else if (attachment_flag == "11") {
            contentReply.text = "❤️ Sticker"
        }
        contentReply.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .gray
        
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
            let imageSticker = UIImageView(image: UIImage(named: (message_text.components(separatedBy: "/")[1]), in: Bundle.resourceBundle(for: Nexilis.self), with: nil))
            self.containerPreviewReply.addSubview(imageSticker)
            imageSticker.layer.cornerRadius = 2.0
            imageSticker.clipsToBounds = true
            imageSticker.translatesAutoresizingMaskIntoConstraints = false
            imageSticker.trailingAnchor.constraint(equalTo: buttonCancelReply.leadingAnchor, constant: -10).isActive = true
            imageSticker.centerYAnchor.constraint(equalTo: self.containerPreviewReply.centerYAnchor).isActive = true
            imageSticker.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageSticker.heightAnchor.constraint(equalToConstant: 30).isActive = true
        }
        if chatGroup.count > 0 {
            self.textFieldSend.becomeFirstResponder()
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

extension UITableView {

    // Fix: scrolling to a row that is no longer there throws NSRangeException and takes the
    // app down - "Attempted to scroll the table view to an out-of-bounds section (0) when
    // there are only 0 sections". The chat is full of scroll requests that were worked out
    // before a reload (a message deleted, a failed send removed, a jump to a search hit),
    // and by the time they run the row they name can be gone. Checking against what the
    // table actually has right now is the only thing that makes them safe.
    func safeScrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        guard indexPath.section >= 0,
              indexPath.section < numberOfSections,
              indexPath.row >= 0,
              indexPath.row < numberOfRows(inSection: indexPath.section) else {
            return
        }
        scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
    }

    /// - Parameter delay: how long to wait before scrolling. The default 0.6s for an
    ///   unanimated scroll is there for screens that load their whole history up front and
    ///   need the rows measured first; a screen that loads one page can pass 0 and land at
    ///   the bottom straight away.
    func scrollToBottom(isAnimated:Bool = true, delay: TimeInterval? = nil){

        DispatchQueue.main.asyncAfter(deadline: .now() + (delay ?? (isAnimated ? 0 : 0.6))) { [weak self] in
            guard let self = self, self.numberOfSections > 0 else { return }
            
            let lastSection = self.numberOfSections - 1
            let numberOfRows = self.numberOfRows(inSection: lastSection)
            
            guard numberOfRows > 0 else { return }
            
            let indexPath = IndexPath(row: numberOfRows - 1, section: lastSection)
            self.safeScrollToRow(at: indexPath, at: .bottom, animated: isAnimated)
        }
    }
    
    func scrollToTop(isAnimated:Bool = true) {
        
        DispatchQueue.main.async {
            // Fix: the old `if indexPath.row != -1` was always true - it tested a constant -
            // so an empty chat (every message deleted, for instance) went straight into
            // scrolling to section 0 of a table with no sections, and crashed.
            self.safeScrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: isAnimated)
        }
    }
}

extension UIImage {
    public func imageWithInsets(insets: UIEdgeInsets) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        let _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }
}

extension EditorPersonal: UISearchBarDelegate {
    
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


public class ObjectGesture: UITapGestureRecognizer {
    public var message_id = ""
    public var image_id = ""
    public var video_id = ""
    public var file_id = ""
    public var audio_id = ""
    public var gif_id = ""
    public var specFile = ""
    public var imageView = UIImageView()
    public var containerFile = UIView()
    public var labelFile = UILabel()
    public var videoURL: NSURL?
    public var indexPath = IndexPath()
    public var indexImageTapped: Int!
    public var listImageFromGrouping: [ImageGrouping]!
    public var isInitiator: Bool!
}

class navigationQLPreviewDocument: UIBarButtonItem {
    var navigation = UINavigationController()
}

class segmentedControllerObject: UISegmentedControl {
    var navigation = UINavigationController()
}

public class ImageGrouping {
    public var messageId = ""
    public var thumbId = ""
    public var imageId = ""
    public var status = ""
    public var time = ""
    public var lPin = ""
    public var dataMessage: [String: Any?] = [:]
    public var dataPerson: [String: String?] = [:]
    public var dataGroup: [String: Any?] = [:]
    public var dataTopic: [String: Any?] = [:]
    public var isSelected = false
    
    public init(messageId: String, thumbId: String, imageId: String, status: String, time: String, lPin: String, dataMessage: [String: Any?], dataPerson: [String: String?], dataGroup: [String: Any?], dataTopic: [String: Any?]) {
        self.messageId = messageId
        self.thumbId = thumbId
        self.imageId = imageId
        self.status = status
        self.time = time
        self.lPin = lPin
        self.dataMessage = dataMessage
        self.dataPerson = dataPerson
        self.dataGroup = dataGroup
        self.dataTopic = dataTopic
    }
}

public class TypeDataMessage {
    public static let message_id = "message_id"
    public static let f_pin = "f_pin"
    public static let l_pin = "l_pin"
    public static let message_scope_id = "message_scope_id"
    public static let server_date = "server_date"
    public static let status = "status"
    public static let message_text = "message_text"
    public static let audio_id = "audio_id"
    public static let video_id = "video_id"
    public static let image_id = "image_id"
    public static let thumb_id = "thumb_id"
    public static let read_receipts = "read_receipts"
    public static let chat_id = "chat_id"
    public static let file_id = "file_id"
    public static let attachment_flag = "attachment_flag"
    public static let reff_id = "reff_id"
    public static let lock = "lock"
    public static let is_stared = "is_stared"
    public static let blog_id = "blog_id"
    public static let credential = "credential"
    public static let progress = "progress"
    public static let chat_date = "chat_date"
    public static let is_call_center = "is_call_center"
    public static let call_center_id = "call_center_id"
    public static let opposite_pin = "opposite_pin"
    public static let last_edit = "last_edit"
    public static let gif_id = "gif_id"
    public static let is_forwarded = "is_forwarded"
    public static let is_pinned = "is_pinned"
    public static let is_secret = "is_secret"
    public static let spec_file = "spec_file"
    public static let is_bot = "is_bot"
}

extension String {
    var nilIfEmpty: String? {
        let v = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? nil : v
    }
}

// Fix: shared, stateless helpers for the link touch/highlight/long-press-sheet flow
// used by EditorGroup, EditorPersonal, and EditorStarMessages - extracted here so all
// three don't carry separate (and, over time, potentially drifting) copies of the same
// pure functions. Each hosting view controller still owns its own mutable state
// (currentLinkHighlightViews, suppressNextLinkTap, etc.) and its own gesture/delegate
// wiring, since those genuinely differ per screen (different table views, different
// bubble-menu actions) - only the parts with zero dependency on that state live here.
enum LinkHighlighting {

    /// Finds the link (if any) at `point` within `textView`, returning both its
    /// character range (needed to compute highlight rects) and its URL string.
    static func linkInfo(at point: CGPoint, in textView: UITextView) -> (range: NSRange, urlString: String)? {
        guard let attributedText = textView.attributedText, attributedText.length > 0 else { return nil }
        guard textView.bounds.contains(point) else { return nil }
        guard let textPosition = textView.closestPosition(to: point) else { return nil }
        let charIndex = textView.offset(from: textView.beginningOfDocument, to: textPosition)
        guard charIndex >= 0, charIndex < attributedText.length else { return nil }

        var effectiveRange = NSRange(location: 0, length: 0)
        // Fix: attribute(_:at:effectiveRange:) is only documented to return *an* effective
        // range, not the longest one - it stops at any attribute-run boundary, including ones
        // that have nothing to do with .link (a bold/italic/underline run inside the link
        // text, a search highlight over part of it). That is why a long link could highlight
        // only its first two lines and hand back a URL cut off at the same point. The
        // longestEffectiveRange variant always spans the whole link.
        guard let linkValue = attributedText.attribute(
            .link,
            at: charIndex,
            longestEffectiveRange: &effectiveRange,
            in: NSRange(location: 0, length: attributedText.length)
        ) else {
            return nil
        }

        let urlString: String
        if let url = linkValue as? URL {
            urlString = url.absoluteString
        } else if let str = linkValue as? String {
            urlString = str
        } else {
            return nil
        }
        return (effectiveRange, urlString)
    }

    /// Precise per-line rects (in `textView`'s coordinate space) covering just the
    /// glyphs of `range` - NOT a single bounding box. A single
    /// `boundingRect(forGlyphRange:in:)` union-rect over-highlights whenever the
    /// range spans more than one line (it'd cover the full width of every line in
    /// between) or sits mid-line next to regular text. `enumerateEnclosingRects` is
    /// the same API UIKit itself uses to draw text-selection highlighting, so it's
    /// already guaranteed to hug exactly the given characters, line by line.
    static func highlightRects(for range: NSRange, in textView: UITextView) -> [CGRect] {
        guard let attributedText = textView.attributedText, range.location != NSNotFound,
              range.location + range.length <= attributedText.length else { return [] }

        let glyphRange = textView.layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var rects: [CGRect] = []
        textView.layoutManager.enumerateEnclosingRects(
            forGlyphRange: glyphRange,
            withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
            in: textView.textContainer
        ) { rect, _ in
            var r = rect
            r.origin.x += textView.textContainerInset.left
            r.origin.y += textView.textContainerInset.top
            rects.append(r)
        }
        return rects
    }

    /// Single bounding rect for `range` - coarser than highlightRects(for:in:), used
    /// only where a single anchor rect is needed (e.g. the iPad popover source rect
    /// for the action sheet), not for drawing the highlight itself.
    static func boundingRect(for range: NSRange, in textView: UITextView) -> CGRect {
        let glyphRange = textView.layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var rect = textView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: textView.textContainer)
        rect.origin.x += textView.textContainerInset.left
        rect.origin.y += textView.textContainerInset.top
        return rect
    }

    /// Walks a view's subview tree to find the first UITextView - messageText is
    /// created fresh per-row inside each screen's cell setup code, so it has to be
    /// found this way rather than referenced directly from a delegate callback that
    /// only receives the containing bubble view.
    static func firstTextView(in view: UIView) -> UITextView? {
        if let textView = view as? UITextView { return textView }
        for subview in view.subviews {
            if let found = firstTextView(in: subview) { return found }
        }
        return nil
    }

    /// Finds the link (if any) under `location` (in `containerView`'s coordinate
    /// space) by locating the first UITextView inside it and checking there.
    static func linkHit(at location: CGPoint, in containerView: UIView?) -> (textView: UITextView, range: NSRange, urlString: String)? {
        guard let containerView = containerView, let textView = firstTextView(in: containerView) else { return nil }
        let pointInTextView = containerView.convert(location, to: textView)
        guard let info = linkInfo(at: pointInTextView, in: textView) else { return nil }
        return (textView, info.range, info.urlString)
    }

    /// Converts an http(s) URL string into Chrome's custom URL scheme format
    /// (googlechrome:// for http, googlechromes:// for https - Chrome's documented
    /// scheme, not a guess) so "Open in Chrome" launches the actual page rather than
    /// just Chrome's home screen.
    static func chromeURL(for urlString: String) -> URL? {
        if urlString.lowercased().hasPrefix("https://") {
            return URL(string: "googlechromes://" + urlString.dropFirst("https://".count))
        } else if urlString.lowercased().hasPrefix("http://") {
            return URL(string: "googlechrome://" + urlString.dropFirst("http://".count))
        }
        return nil
    }

    /// How long a link must be held before LinkActionSheetViewController appears
    /// instead of the touch being treated as a tap that opens the link. One shared
    /// constant so EditorGroup/EditorPersonal/EditorStarMessages can't drift out of
    /// sync with each other.
    static let longPressThreshold: TimeInterval = 0.3
}

// Fix: purely cosmetic gesture recognizer - shows/hides the link touch highlight the
// instant a finger goes down (minimumPressDuration = 0), independent of whatever
// gesture ends up actually handling the touch (the tap gesture for a quick tap,
// containerMessage's UIContextMenuInteraction for a long-press). Because this
// recognizer never triggers an action of its own - it only draws/erases a highlight -
// it's safe for it to lose any gesture-arbitration race against those: even if it
// gets cancelled partway through by a competing recognizer winning, the highlight it
// already drew simply gets cleared (see EditorGroup's handling), no action is lost or
// duplicated either way.
final class LinkTouchHighlightGesture: UILongPressGestureRecognizer {
    weak var textView: UITextView?
}

// Fix: custom bottom sheet for the "Open Link"/"Copy" popup, presented via
// UISheetPresentationController (see EditorGroup's presentLinkActionSheet) instead of
// a plain UIAlertController(style: .actionSheet). UISheetPresentationController is
// iOS 15+ only - this class is only ever instantiated inside an `if #available(iOS
// 15.0, *)` branch; on iOS 14 a plain UIAlertController is used instead.
//
// Layout mirrors iOS's own native "Select an action" link sheet (link icon top-left,
// title + full URL, close "X" top-right, then a card of tappable rows below) as
// requested, with an added "Open in Chrome" row that only appears when Chrome is
// actually installed on the device.
final class LinkActionSheetViewController: UIViewController {
    private let urlString: String
    private let onOpen: () -> Void
    private let onCopy: () -> Void
    private let onOpenInChrome: (() -> Void)?
    /// Called whenever this sheet leaves the screen, however that happened (an action
    /// was tapped, the close "X" was tapped, or the user swiped/tapped-outside to
    /// dismiss without choosing anything) - lets the presenter (EditorGroup) reliably
    /// hide its link highlight in every case, not just the explicit action paths.
    var onDismissed: (() -> Void)?

    init(urlString: String, onOpen: @escaping () -> Void, onCopy: @escaping () -> Void, onOpenInChrome: (() -> Void)? = nil) {
        self.urlString = urlString
        self.onOpen = onOpen
        self.onCopy = onCopy
        self.onOpenInChrome = onOpenInChrome
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground

        let header = makeHeader()

        var rows: [LinkActionRow] = []
        let openRow = LinkActionRow(title: "Open link".localized(), systemImageName: "safari")
        openRow.onTap = { [weak self] in self?.handleOpen() }
        rows.append(openRow)

        if onOpenInChrome != nil {
            // Fix: only shown when Chrome is actually installed - see
            // presentLinkActionSheet in EditorGroup, which checks
            // UIApplication.shared.canOpenURL against the "googlechrome" scheme
            // (declared in Info.plist's LSApplicationQueriesSchemes) before ever
            // passing a non-nil onOpenInChrome closure here.
            let chromeRow = LinkActionRow(title: "Open in Chrome".localized(), systemImageName: "globe")
            chromeRow.onTap = { [weak self] in self?.handleOpenInChrome() }
            rows.append(chromeRow)
        }

        let readingListRow = LinkActionRow(title: "Add to Reading List".localized(), systemImageName: "eyeglasses")
        readingListRow.onTap = { [weak self] in self?.handleAddToReadingList() }
        rows.append(readingListRow)

        let copyRow = LinkActionRow(title: "Copy".localized(), systemImageName: "doc.on.doc")
        copyRow.onTap = { [weak self] in self?.handleCopy() }
        rows.append(copyRow)

        let rowsCard = makeCard(rows: rows)

        let stack = UIStackView(arrangedSubviews: [header, rowsCard])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismissed?()
    }

    // MARK: - Header: link icon, title + URL, close button

    private func makeHeader() -> UIView {
        let iconBackground = UIView()
        iconBackground.backgroundColor = .tertiarySystemFill
        iconBackground.layer.cornerRadius = 20
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iconBackground.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let icon = UIImageView(image: UIImage(systemName: "link"))
        icon.tintColor = .label
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "Select an action".localized()
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        let urlLabel = UILabel()
        urlLabel.text = urlString
        urlLabel.font = .systemFont(ofSize: 14)
        urlLabel.textColor = .secondaryLabel
        urlLabel.numberOfLines = 4
        urlLabel.lineBreakMode = .byCharWrapping

        let textStack = UIStackView(arrangedSubviews: [titleLabel, urlLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let closeButton = LinkActionRow.makeCircularButton(systemImageName: "xmark")
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let row = UIStackView(arrangedSubviews: [iconBackground, textStack, closeButton])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .top
        return row
    }

    // MARK: - Rows card (rounded rect container, divider between each row)

    private func makeCard(rows: [LinkActionRow]) -> UIView {
        let card = UIView()
        card.backgroundColor = .tertiarySystemBackground
        card.layer.cornerRadius = 14
        card.clipsToBounds = true

        var arranged: [UIView] = []
        for (index, row) in rows.enumerated() {
            if index > 0 { arranged.append(makeDivider()) }
            arranged.append(row)
        }

        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        return card
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return divider
    }

    // MARK: - Actions

    @objc private func handleClose() {
        dismiss(animated: true)
    }

    private func handleOpen() {
        dismiss(animated: true) { [weak self] in self?.onOpen() }
    }

    private func handleOpenInChrome() {
        dismiss(animated: true) { [weak self] in self?.onOpenInChrome?() }
    }

    private func handleAddToReadingList() {
        dismiss(animated: true) { [weak self] in
            guard let self = self, let url = URL(string: self.urlString) else { return }
            try? UIApplication.shared.open(url, options: [:], completionHandler: nil)
            // Fix: there's no public API to add a URL to Safari's Reading List
            // directly from a third-party app (that capability was removed from the
            // SDK) - the closest available action is opening the link, same as
            // "Open Link". If a true Reading-List add is required, it needs a Share
            // Sheet (UIActivityViewController) with the Reading List activity type
            // instead - ask if you'd like that swapped in here.
        }
    }

    private func handleCopy() {
        dismiss(animated: true) { [weak self] in self?.onCopy() }
    }

    /// Content's natural height, used to size a `.custom` sheet detent (iOS 16+) to
    /// just this content instead of a generic `.medium()` that would leave a lot of
    /// empty space below - see presentLinkActionSheet in EditorGroup.
    func preferredContentHeight(forWidth width: CGFloat) -> CGFloat {
        view.frame.size.width = width
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        return view.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
    }
}

/// A single tappable "icon + title" row, styled to match the requested link-popup design.
private final class LinkActionRow: UIControl {
    var onTap: (() -> Void)?

    /// Small circular icon-only button, used for the header's close "X".
    static func makeCircularButton(systemImageName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .tertiarySystemFill
        button.tintColor = .label
        button.setImage(UIImage(systemName: systemImageName), for: .normal)
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        return button
    }

    init(title: String, systemImageName: String) {
        super.init(frame: .zero)

        let imageView = UIImageView(image: UIImage(systemName: systemImageName))
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17)
        label.textColor = .label

        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])

        addTarget(self, action: #selector(handleTouchUpInside), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.5 : 1.0 }
    }

    @objc private func handleTouchUpInside() {
        onTap?()
    }
}

// Fix: `tapMessageText` (opening a URL tapped inside a chat message) was duplicated,
// bugs and all, across EditorGroup, EditorPersonal, EditorStarMessages,
// ChatGPTBotView, and MessageInfo. See CHANGELOG for the full history:
// - EditorGroup/EditorPersonal/EditorStarMessages hand-built custom `instagram://`,
//   `twitter://`, `youtube://` deep links that don't match any route those apps
//   actually recognize, so the app "opened successfully" but always landed on its
//   home/feed screen instead of the tapped post/tweet/video.
// - MessageInfo lowercased the ENTIRE url string before opening it - since paths for
//   Instagram shortcodes, YouTube video ids, etc. are case-sensitive, this could send
//   the app to the wrong (or a nonexistent) piece of content even though `open`
//   "succeeded".
// - ChatGPTBotView had neither bug, but also had no secure_browser handling at all.
//
// Consolidated into one place so there's one implementation to get right, and one
// place to update the well-known-domain list / secure_browser behavior going forward.
enum LinkOpener {

    // Fix: known consumer-app domains should always deep-link into their native app
    // via Universal Links, even when "secure_browser" is on. Universal Links only
    // fire for `UIApplication.open(url)` - routing these through the in-app WKWebView
    // (`APIS.openUrl`) never triggers them, so the link would just render inside the
    // in-app browser and never reach the native app, regardless of any other fix.
    // `secure_browser` is a policy setting meant for arbitrary/untrusted links; these
    // are well-known, trusted destinations, so bypassing it here is intentional.
    private static let wellKnownAppDomains: [String] = [
        "instagram.com",
        "x.com", "twitter.com",
        "youtube.com", "youtu.be",
        "whatsapp.com", "wa.me",
        "facebook.com", "fb.com", "fb.watch",
        "tiktok.com",
        "linkedin.com",
        "t.me", "telegram.me", "telegram.org",
        "open.spotify.com",
        "maps.google.com", "goo.gl"
    ]

    private static func isWellKnownAppDomain(host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        return wellKnownAppDomains.contains { host == $0 || host.hasSuffix("." + $0) }
    }

    /// Opens a URL tapped inside a chat message. `urlString` is expected to be
    /// exactly what was detected in the message text (e.g. `sender.message_id` from
    /// the tap gesture) - may or may not have a scheme, may start with "www.".
    static func open(urlString: String) {
        var stringURl = urlString
        // Fix: only strip/rewrite a "www." PREFIX, never lowercase the whole string -
        // paths and query strings (Instagram shortcodes, YouTube video ids, etc.) are
        // case-sensitive.
        if stringURl.lowercased().hasPrefix("www.") {
            stringURl = "https://" + String(stringURl.dropFirst(4))
        }
        guard let url = URL(string: stringURl) else { return }

        let app = UIApplication.shared
        if isWellKnownAppDomain(host: url.host) {
            // Universal Link - iOS routes straight into the correct in-app screen
            // (the specific post/video/chat) if the app is installed and supports it,
            // and falls back to the browser automatically if not. No custom scheme
            // guessing needed.
            app.open(url)
        } else if Nexilis.checkingAccess(key: "secure_browser") {
            APIS.openUrl(url: stringURl)
        } else {
            app.open(url)
        }
    }
}

// MARK: - Transfers

extension EditorPersonal {
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
        guard let indexPath = indexPathForMessage(withFileNamed: name),
              indexPath.section < tableChatView.numberOfSections,
              indexPath.row < tableChatView.numberOfRows(inSection: indexPath.section) else {
            return
        }
        tableChatView.reloadRows(at: [indexPath], with: .none)
    }
}
