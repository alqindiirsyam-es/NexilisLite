//
//  ChatGPTBotView.swift
//  NexilisLite
//
//  Created by Maronakins on 21/09/23.
//

import UIKit
@_implementationOnly import Alamofire
@_implementationOnly import NotificationBannerSwift
import nuSDKService

public class ChatGPTBotView: UIViewController, UIGestureRecognizerDelegate {
    public var dataPerson : [String: String?] = [
        "f_pin" : "-997",
        "firstName" : Utils.getGPTBotName(),
        "picture" : ""
    ]
    var dataMessages: [[String: Any?]] = []
    var dataDates: [String] = []
    var chatGPTMessages: [[String: Any?]] = []
    
    @IBOutlet var tableChatView: UITableView!
    @IBOutlet var viewTextField: UIView!
    @IBOutlet var buttonSendChat: UIButton!
    @IBOutlet var textFieldSend: CustomTextView!
    @IBOutlet var heightTextFieldSend: NSLayoutConstraint!
    
    @IBOutlet var constraintBottomTableViewWithTextfield: NSLayoutConstraint!
    @IBOutlet var constraintTopTextField: NSLayoutConstraint!
    @IBOutlet var constraintViewTextField: NSLayoutConstraint!
    
    
    var gettingDataMessage = true
    var listViewOnSection: [UIView] = []
    var currentIndexpath: IndexPath?
    
    public var unique_l_pin = ""
    var counter = 0
    var markerCounter: String?
    /// How many messages the band above the marker says are waiting. Kept beside
    /// `markerCounter` because `counter` is cleared as soon as the chat opens.
    var markerCount = 0
    var buttonScrollToBottom = UIButton()
    let indicatorCounterBSTB = UIView()
    let labelCounter = UILabel()
    var titleText: String!
    
    var isSearching = false
    var searchBar: UISearchBar!
    
    let containerMultpileSelectSession = UIView()
    var constraintBottomContainerMultpileSelectSession = NSLayoutConstraint()
    
    var copySession = false
    var deleteSession = false
    
    var showMenuContext = false
    var touchedSubview = UIView()
    
    var titleSearchMatches: UILabel!
    var textSearch = ""
    var countMatchesSearch = 0
    var lastScrollIdxSearch = 0
    var buttonUp: UIButton!
    var buttonDown: UIButton!
    var amountTx = "0"
    var autoText = ""
    
    public var fromNotification = true
    
    var lastY: CGFloat = 0
    
    var allowTyping = true
    var loadingResponse = false

    /// The bubble that still owes an arrival animation: which message, which side it grows from,
    /// and when the growing started. Kept until the growing has finished rather than started,
    /// because a row rebuilt in the middle - the answer replacing the three dots, say - throws
    /// its bubble away, and the new one picks the animation up where the old one left off.
    private var pendingBubbleArrival: (messageId: String, outgoing: Bool, startedAt: Date?, pushesList: Bool)?

    /// The bubble growing right now, and the row it is in, so a redraw does not wipe the
    /// transforms out from under them.
    private weak var arrivingBubble: UIView?
    private weak var arrivingCell: UITableViewCell?

    /// True while the first page is being put on screen; what the old `alpha != 1` checks
    /// were really asking.
    private var isInitialLoading = true
    /// Makes sure the first frame the table lays out is already at the newest message.
    ///
    /// Fix: this screen hid its table at alpha 0, waited half a second and faded it in over
    /// another half - so opening the bot showed a blank screen first, and the fade was there to
    /// cover the jump as the rows found their real heights. Both editors were taken off that a
    /// while ago and this one was left behind. The placement is held instead, the same way, and
    /// the table is simply on screen from the start.
    private var pendingInitialScrollToBottom = false
    private var initialBottomDeadline: Date?
    private var initialBottomLastContentHeight: CGFloat = -1
    private var initialBottomStartedAt: Date?
    /// How long the opening placement stays in charge once the rows look settled.
    private static let initialBottomGrace: TimeInterval = 1.0

    /// The two views a selection session trades: the circle beside a bubble, and - on the screens
    /// that draw one - the sender's picture. Found by tag because the fade runs over
    /// `visibleCells` after the table has already built them.
    static let selectionMarkTag = 77_311
    static let selectionMarkHidden = CGAffineTransform(scaleX: 0.4, y: 0.4)
    private var selectionChromeShown = false
    /// What held the table's bottom before the selection bar took the input bar's place.
    private var bottomTableConstantBeforeSelection: CGFloat?
    /// Counts the bars this screen has put up, so a cancel that belongs to an earlier one does
    /// not take down the session that replaced it.
    private var selectionSessionToken = 0
    
    struct Payload: Encodable {
        let use_video : String
        let payload : [[String: String]]
    }
    
    func offset() -> CGFloat{
        guard let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0") else { return 0 }
        return CGFloat(fontSize)
    }
    
    /// Says that this conversation is the one on screen, so nothing raises a card about it.
    ///
    /// Fix: the same pair as in the two chat editors. Written once while the screen was built and
    /// deleted only when it was popped, the registration was wrong for every other way of leaving
    /// - and worse, the deletion took whatever was stored, including the registration a chat
    /// underneath had already made on its way back in.
    private func registerAsOpenConversation() {
        SecureUserDefaults.shared.set(openConversationValue, forKey: "inEditorPersonal")
        SecureUserDefaults.shared.removeValue(forKey: "inEditorGroup")
    }

    private func unregisterAsOpenConversation() {
        let stored: String? = SecureUserDefaults.shared.value(forKey: "inEditorPersonal") ?? nil
        guard stored == openConversationValue else {
            return
        }
        SecureUserDefaults.shared.removeValue(forKey: "inEditorPersonal")
    }

    private var openConversationValue: String {
        return (dataPerson["f_pin"] ?? "") ?? ""
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareNavigationBar()
        registerAsOpenConversation()
        // The placement is settled here, while the push animation still covers the screen,
        // rather than over the layout passes that follow it - see settleInitialBottomNow.
        settleInitialBottomNow()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // The rows have real heights only once the table has laid out. Placing the chat at its
        // newest message here means it is drawn in the right place the first time, with no
        // visible jump - which is what the old fade from alpha 0 was covering up.
        applyPendingInitialBottomScroll()
    }

    /// Makes the opening placement converge now instead of over the next few layout passes.
    ///
    /// A row the table has never drawn is guessed at, so the first placement is worked out from
    /// guesses and lands short of the newest message; the passes that follow correct it, and that
    /// correction is the drift seen as a chat opens. Only measuring replaces a guess, so the
    /// measuring is asked for here, while the screen is still sliding in and none of it is seen.
    private func settleInitialBottomNow() {
        guard pendingInitialScrollToBottom, tableChatView != nil,
              tableChatView.numberOfSections > 0 else {
            return
        }
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
        guard pendingInitialScrollToBottom, tableChatView != nil else {
            return
        }
        if initialBottomDeadline == nil {
            initialBottomDeadline = Date().addingTimeInterval(2.5)
            initialBottomStartedAt = Date()
        }
        if let deadline = initialBottomDeadline, Date() > deadline {
            endOpeningPlacement()
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
            endOpeningPlacement()
        }
    }

    /// Hands the list back to the reader.
    private func endOpeningPlacement() {
        pendingInitialScrollToBottom = false
        initialBottomDeadline = nil
        initialBottomStartedAt = nil
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterAsOpenConversation()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            unregisterAsOpenConversation()
            NotificationCenter.default.removeObserver(self)
            super.viewDidDisappear(true)
            self.removeFromParent()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    /// Puts the header in place: colours, the back button's tint, and the bar itself if the
    /// screen underneath had hidden it.
    ///
    /// Fix: all of this used to run in viewDidAppear - after the push had finished and the
    /// conversation had already been laid out to the full height of the screen. The bar then
    /// arrived, took its space out of the top, and everything the reader was looking at slid.
    /// The chat list hides the bar for itself, so opening the bot from there showed it every
    /// single time. Both editors were taken off that a while ago; this screen was left behind.
    /// Done before the screen appears, the messages are laid out under a header that is already
    /// there, and nothing moves.
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

    public override func viewDidAppear(_ animated: Bool) {
        prepareNavigationBar()
        gettingDataMessage = false
        // A row that changes height a beat later changes it inside the table, and that does not
        // always ask this screen to lay out again. So the opening placement is looked at by the
        // clock too, for as long as it is still in charge of where the list sits.
        for delay in [0.1, 0.25, 0.5, 0.8] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.applyPendingInitialBottomScroll()
            }
        }
//        let indexPath = tableChatView.indexPathsForVisibleRows?.first
//        if indexPath != nil {
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
        // Fix: this screen had no backdrop at all - no chat background, no wallpaper - so while
        // the table was still hidden the reader was shown the bare white of the window. Both
        // editors have drawn the same two behind their conversation for a long time.
        Utils.addBackground(view: self.view)
        addChatWallpaperIfAny()
        navigationController?.navigationBar.topItem?.title = Utils.getGPTBotName()
        if Nexilis.fromMAB {
            FloatingButton.setHidden(true)
        }
        
        buttonSendChat.setImage(resizeImage(image: self.traitCollection.userInterfaceStyle == .dark ? UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withTintColor(.blackDarkMode) : UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, targetSize: CGSize(width: 30, height: 30)).withRenderingMode(.alwaysOriginal), for: .normal)
        GlassLook.imageChanged(buttonSendChat)
        buttonSendChat.circle()
        buttonSendChat.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        buttonSendChat.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .mainColor
        // Wrapped rather than made a glass button: the microphone shares its glass with the
        // camera beside it (see VideoNoteEntryPoint), and only a wrapping glass can be shared.
        GlassLook.wrap(buttonSendChat, tint: buttonSendChat.backgroundColor)
        textFieldSend.layer.cornerRadius = textFieldSend.maxCornerRadius()
        textFieldSend.layer.borderWidth = 1.0
        textFieldSend.text = "Send message".localized()
        textFieldSend.textColor = UIColor.lightGray
        textFieldSend.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        textFieldSend.textContainerInset = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 40)
        textFieldSend.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        textFieldSend.font = UIFont.systemFont(ofSize: 12 + offset())
        textFieldSend.delegate = self
        textFieldSend.allowsEditingTextAttributes = true
        // After the font: the one-line height below is measured off it.
        // The glass takes the field's place in the bar, so the outlets that move the field must
        // now move the glass.
        let fieldGlass = GlassLook.adopt(textFieldSend, tint: nil, radius: textFieldSend.layer.cornerRadius)
        // Fix: crashed on the bot chat, whose scene never connected this outlet - the field
        // there has no reply preview to make room for. An outlet that is nil has nothing to
        // re-home.
        if let top = constraintTopTextField {
            constraintTopTextField = fieldGlass.rehomed(top)
        }
        if #available(iOS 26.0, *) {
            // The field's right end runs on under the send button; the scroll indicator that
            // appears once the text is taller than the field stands clear of it, as the
            // reference's does, rather than hiding behind the button.
            textFieldSend.verticalScrollIndicatorInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: textFieldSend.textContainerInset.right)
        }
        if #available(iOS 26.0, *), let pins = fieldGlass.pins {
            // Fix: the margin above and below the text used to be the text view's own inset, and
            // an inset is only an offset of the content - once the field scrolled, the tail of the
            // line above ran on into the top margin and was cut there, mid-glyph. The margin is
            // the glass's now: the text view is 11pt in from the glass's top and bottom and has no
            // vertical inset of its own, so whatever scrolls is clipped at the text's own edge
            // and the margin is always empty, scrolled or not - which is the reference's look.
            // Fix: measured before the font was set, the one-line field opened at the storyboard
            // font's height and shrank to the smaller font's the first time it was edited. The
            // block runs after the font now, and a line is centred in the 18pt that make a
            // 40pt capsule with the glass's margins, so one line is 40pt whichever font.
            let line = ceil((textFieldSend.font ?? UIFont.systemFont(ofSize: 12 + offset())).lineHeight)
            let pad = max(0, (18 - line) / 2)
            textFieldSend.textContainerInset.top = pad
            textFieldSend.textContainerInset.bottom = pad
            pins.top.constant = 11
            pins.bottom.constant = -11
            // The text view's clip is a plain rectangle now - the rounding is the glass's, and a
            // 20pt radius on a view one line tall would eat into the first letters.
            textFieldSend.layer.cornerRadius = 0
            heightTextFieldSend.constant = fieldHeight(for: textFieldSend)
        }
        
        navigationItem.rightBarButtonItem?.tintColor = UIColor.secondaryColor
        
        tableChatView.register(UITableViewCell.self, forCellReuseIdentifier: "cellEditorPersonal")
        
        loadData()
        setRightButtonItem()
        
        addGreeting()
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil)
        center.addObserver(self, selector: #selector(onStatusChat(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusChat), object: nil)
        center.addObserver(self, selector: #selector(onTyping(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerTypingChat), object: nil)
        
        
    }
    
    /// The wallpaper the reader chose, behind the conversation.
    ///
    /// The two editors take theirs from an image view in the storyboard; this scene has none, so
    /// one is put in at the back here. Same picture, same place in the stack: behind everything,
    /// in front of the chat background.
    private func addChatWallpaperIfAny() {
        guard let data = UserDefaults.standard.data(forKey: "chatWallpaper"),
              let wallpaper = UIImage(data: data) else {
            return
        }
        let wallpaperView = UIImageView(image: wallpaper)
        wallpaperView.contentMode = .scaleAspectFill
        wallpaperView.clipsToBounds = true
        view.addSubview(wallpaperView)
        view.sendSubviewToBack(wallpaperView)
        wallpaperView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wallpaperView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wallpaperView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wallpaperView.topAnchor.constraint(equalTo: view.topAnchor),
            wallpaperView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func addGreeting() {
        guard let me = User.getMyPin() else {
            return
        }
        if dataMessages.count > 0 { // && (dataMessages[dataMessages.count - 1]["read_receipts"] as? String ?? "0") == "0"
            return
        }
        var user_id:String? = ""
        let message_id = me + CoreMessage_TMessageUtil.getTID()
        let server_date = String(Date().currentTimeMillis())
        
        var gptRow : [String: String] = [:]
        gptRow["role"] = "assistant"
        gptRow["content"] = Utils.getChatbotGreetings()
        chatGPTMessages.append(gptRow)
        
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select user_id from BUDDY where f_pin = '\(me)'"), cursor.next() {
                    user_id = cursor.string(forColumnIndex: 0)
                    cursor.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                    "message_id" : message_id ,
                    "f_pin" : "-997",
                    "f_display_name" : Utils.getGPTBotName(),
                    "l_pin" : me,
                    "l_user_id" : String(user_id!),
                    "message_scope_id" : "31",
                    "server_date" : server_date,
                    "status" : "4",
                    "message_text" : gptRow["content"],
                    "audio_id" : "",
                    "video_id" : "",
                    "image_id" : "",
                    "file_id" : "",
                    "thumb_id" : "",
                    "opposite_pin" : "",
                    "format" : "",
                    "blog_id" : "",
                    "read_receipts" : "0",
                    "chat_id" : "",
                    "account_type" : "1",
                    "credential" :"",
                    "reff_id" : "",
                    "message_large_text" : "",
                    "attachment_flag" : "0",
                    "local_timestamp" : String(Date().currentTimeMillis())
                ], replace: true)
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        let pin = "-997"
        var pinned = 0
        var archived = 0
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select pinned, archived from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                    pinned = Int(cursor.int(forColumnIndex: 0))
                    archived = Int(cursor.int(forColumnIndex: 1))
                }
                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                    "l_pin" : pin,
                    "message_id" : message_id,
                    "counter" : 0,
                    "pinned" : pinned,
                    "archived" : archived
                ], replace: true)
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        var row: [String: Any?] = [:]
        row["message_id"] = message_id
        row["f_pin"] = "-997"
        row["l_pin"] = me
        row["message_scope_id"] = "31"
        row["server_date"] = server_date
        row["status"] = "3"
        row["message_text"] = gptRow["content"]
        row["audio_id"] = ""
        row["video_id"] = ""
        row["image_id"] = ""
        row["thumb_id"] = ""
        row["read_receipts"] = "0"
        row["credential"] = ""
        row["file_id"] = ""
        row["reff_id"] = ""
        row["progress"] = 100.0
        row["attachment_flag"] = "0"
        row["lock"] = ""
        row["is_stared"] = "0"
        row["isSelected"] = false
        if !self.dataDates.contains("Today".localized()) {
            self.dataDates.append("Today".localized())
            self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .none)
        }
        row["chat_date"] = "Today".localized()
        row["blog_id"] = "0"
        // Written down before the insert so the bubble is small the first time it is drawn - see
        // pendingBubbleArrival.
        self.expectBubbleArrival(messageId: message_id, outgoing: false)
        self.tableChatView.beginUpdates()
        self.dataMessages.append(row)
        let greeted = IndexPath(row: self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)
        self.tableChatView.insertRows(at: [greeted], with: .none)
        self.tableChatView.endUpdates()
        self.retryPendingBubbleArrival(at: greeted)
        // The arrival takes the list up with it; this only finishes the job if it never played.
        self.slideToNewestMessage()
    }
    
    @objc func sendTapped() {
        if self.chatGPTMessages.last?["confirmation"] as? String == "1" {
            DispatchQueue.global().async {
                var dataTxn = Utils.getTxnLevel()
                var policyLevel = "1,2"
                dataTxn = dataTxn.replacingOccurrences(of: "\\\"", with: "\"")
                                            .replacingOccurrences(of: "\"[", with: "[")
                                            .replacingOccurrences(of: "]\"", with: "]")
                if !dataTxn.isEmpty {
                    if let data = dataTxn.data(using: .utf8) {
                        do {
                            // Parse to generic JSON array
                            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                                for json in jsonArray {
                                    let min = json["min"] as? Double ?? 0
                                    let max = json["max"] as? Double ?? 0
                                    let policy = json["policy"] as? String ?? ""
                                    let amount = Double(self.amountTx) ?? 0.0
                                    if max == -1 {
                                        if amount >= min {
                                            policyLevel = policy
                                            break
                                        }
                                    } else {
                                        if amount >= min && amount <= max {
                                            policyLevel = policy
                                            break
                                        }
                                    }
                                }
                            }
                        } catch {
                            print("Error converting string to JSONArray:", error)
                        }
                    }
                }
                var isBiometricOn = false
                var result = false
                if policyLevel == MFAViewController.STEP_FIDO_BIOFINGER || policyLevel == MFAViewController.STEP_FIDO_BIOFACE {
                    isBiometricOn = true
                }
                if isBiometricOn {
                    let semaphore = DispatchSemaphore(value: 0)

                    Utils.authenticateWithBioOrPass { success, errorMessage in
                        if success {
                            result = true
                        }
                        semaphore.signal()
                    }

                    semaphore.wait()
                } else if policyLevel == MFAViewController.STEP_FIDO_PWD || policyLevel == MFAViewController.STEP_FIDO_PWD_BIOFACE || policyLevel == MFAViewController.STEP_FIDO_PWD_BIOFINGER {
                    let semaphore = DispatchSemaphore(value: 0)
                    APIS.setMFACallback { res in
                        if res == 0 {
                            result = true
                        }
                        semaphore.signal()
                    }
                    DispatchQueue.main.async {
                        let controller = MFAViewController()
                        controller.METHOD = ""
                        controller.STEP_NEEDED = policyLevel
                        let navigationController = CustomNavigationController(rootViewController: controller)
                        navigationController.defaultStyle()
                        
                        if UIApplication.shared.visibleViewController?.navigationController != nil {
                            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
                        } else {
                            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
                        }
                    }
                    semaphore.wait()
                } else {
                    result = true
                }

                DispatchQueue.main.async { [self] in
                    if !result {
                        return
                    }
                    sendChat(message_text: textFieldSend.text!, viewController: self)
                }
            }
            return
        }
        sendChat(message_text: textFieldSend.text!, viewController: self)
    }
    
    @objc func didTapExit() {
        self.dismiss(animated: true)
//        if complaintId.isEmpty || fromVCAC {
//            for timer in self.timerCredential.values {
//                timer.invalidate()
//            }
//            self.timeoutCC.invalidate()
//            NotificationCenter.default.removeObserver(self)
//            self.dismiss(animated: true, completion: nil)
//        } else if !complaintId.isEmpty {
//            let alert = LibAlertController(title: "Interaction with Call Center is in progress".localized(), message: "Are you sure you want to end the Call Center?".localized(), preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
//            alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
//                self.endCallCenter()
//            }))
//            self.present(alert, animated: true, completion: nil)
//        }
    }
    
    private func sendChat(message_scope_id:String =  MessageScope.GPT_CHATBOT, status:String =  "4", message_text:String =  "", credential:String = "0", attachment_flag: String = "0", ex_blog_id: String = "", message_large_text: String = "", ex_format: String = "", image_id: String = "", audio_id: String = "", video_id: String = "", file_id: String = "", thumb_id: String = "", reff_id: String = "", read_receipts: String = "4", chat_id: String = "", is_call_center: String = "0", call_center_id: String = "", viewController: UIViewController) {
        if viewController is ChatGPTBotView {
            if ((textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) == "Send message".localized() && textFieldSend.textColor == UIColor.lightGray && attachment_flag != "11") || textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ) {
                dismissKeyboard()
                viewController.view.makeToast("Write Messages".localized(), duration: 3)
                if (textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized()) {
                    textFieldSend.text = ""
                }
                let oneLine = self.fieldHeight(for: self.textFieldSend)
                if (self.heightTextFieldSend.constant != oneLine) {
                    self.heightTextFieldSend.constant = oneLine
                }
                return
            }
        }
        let l_pin = dataPerson["f_pin"]!!
        let message_scope_id = message_scope_id
        let chat_id = chat_id
        let message_text = message_text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let idMe = User.getMyPin() as String?
        let opposite_pin = idMe ?? ""
        sendTyping(l_pin: l_pin, isTyping: true)
        let message = CoreMessage_TMessageBank.sendMessage(l_pin: l_pin, message_scope_id: message_scope_id, status: status, message_text: message_text, credential: credential, attachment_flag: attachment_flag, ex_blog_id: ex_blog_id, message_large_text: message_large_text, ex_format: ex_format, image_id: image_id, audio_id: audio_id, video_id: video_id, file_id: file_id, thumb_id: thumb_id, reff_id: reff_id, read_receipts: read_receipts, chat_id: chat_id, is_call_center: is_call_center, call_center_id: call_center_id, opposite_pin: opposite_pin, specFile: "")
        Nexilis.saveMessage(message: message)
        let messageId = String(message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID]!)
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
        row["attachment_flag"] = attachment_flag
        row["reff_id"] = reff_id
        row["progress"] = 0.0
        row["lock"] = "0"
        row["is_stared"] = "0"
        row["isSelected"] = false
        if !dataDates.contains("Today".localized()) {
            dataDates.append("Today".localized())
            tableChatView.insertSections(IndexSet(integer: dataDates.count - 1), with: .none)
        }
        row["chat_date"] = "Today".localized()
        let sentId = row["message_id"] as? String ?? ""
        if loadingResponse {
            expectBubbleArrival(messageId: sentId, outgoing: true)
            self.tableChatView.beginUpdates()
            dataMessages.insert(row, at: dataMessages.count - 2)
            let sent = IndexPath(row: dataMessages.filter({ $0["chat_date"] as! String == dataDates[dataDates.count - 1]}).count - 2, section: dataDates.count - 1)
            tableChatView.insertRows(at: [sent], with: .none)
            self.tableChatView.endUpdates()
            retryPendingBubbleArrival(at: sent)
        } else {
            row["is_loading"] = false
            expectBubbleArrival(messageId: sentId, outgoing: true)
            self.tableChatView.beginUpdates()
            dataMessages.append(row)
            let sent = IndexPath(row: dataMessages.filter({ $0["chat_date"] as! String == dataDates[dataDates.count - 1]}).count - 1, section: dataDates.count - 1)
            tableChatView.insertRows(at: [sent], with: .none)
            self.tableChatView.endUpdates()
            retryPendingBubbleArrival(at: sent)
            row["is_loading"] = true
            row["f_pin"] = dataPerson["f_pin"]!!
            row["l_pin"] = idMe
            // No arrival for the three dots. They are the same row as the message just sent -
            // only `is_loading` and the two pins are changed - so they carry the same message_id,
            // and the arrival is remembered by id: the two rows would be indistinguishable to it,
            // and a redraw of the sent bubble could pick up the placeholder's animation instead.
            // They are a placeholder that the answer replaces a moment later anyway.
            self.tableChatView.beginUpdates()
            dataMessages.append(row)
            tableChatView.insertRows(at: [IndexPath(row: dataMessages.filter({ $0["chat_date"] as! String == dataDates[dataDates.count - 1]}).count - 1, section: dataDates.count - 1)], with: .none)
            self.tableChatView.endUpdates()
        }
        var gptRow : [String: String] = [:]
        gptRow["role"] = "user"
        gptRow["content"] = row["message_text"] as? String
        chatGPTMessages.append(gptRow)
        request(mesage: row["message_text"] as! String)
        if textFieldSend.text!.trimmingCharacters(in: .whitespacesAndNewlines) != "Send message".localized() && textFieldSend.textColor != UIColor.lightGray && constraintViewTextField.constant == 0 {
            textFieldSend.text = "Send message".localized()
            textFieldSend.textColor = UIColor.lightGray
        } else if constraintViewTextField.constant != 0 {
            if textFieldSend.text.lowercased().contains("@bsb") {
                textFieldSend.text = "@bsb "
            } else {
                textFieldSend.text = ""
            }
            heightTextFieldSend.constant = fieldHeight(for: textFieldSend)
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        // The arrival takes the list up with it; this only finishes the job if it never played.
        self.slideToNewestMessage()
    }
    
    private func request(mesage: String) {
        if !loadingResponse {
            loadingResponse = true
        }
        DispatchQueue.global().async {
            do {
                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.requestGPTBot(message: mesage), timeout: 30000) {
                    if response.isOk() {
                        let data = response.getBody(key: CoreMessage_TMessageKey.DATA)
                        if let json = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: []) as? [String: Any?] {
                            DispatchQueue.main.async {
                                self.dataMessages.removeAll(where: { $0["is_loading"] as? Bool == true })
                                self.tableChatView.reloadData()
                                if json["parameters"] != nil {
                                    let param = json["parameters"] as! [String: Any]
                                    self.amountTx = param["amount"] as? String ?? "0"
                                }
                                self.chatGPTMessages.append(json)
                                guard let me = User.getMyPin() else {
                                    return
                                }
                                
                                var user_id:String? = ""
                                let message_id = me + CoreMessage_TMessageUtil.getTID()
                                let server_date = String(Date().currentTimeMillis())
                                
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select user_id from BUDDY where f_pin = '\(me)'"), cursor.next() {
                                            user_id = cursor.string(forColumnIndex: 0)
                                            cursor.close()
                                        }
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                            "message_id" : message_id ,
                                            "f_pin" : "-997",
                                            "f_display_name" : Utils.getGPTBotName(),
                                            "l_pin" : me,
                                            "l_user_id" : String(user_id!),
                                            "message_scope_id" : "31",
                                            "server_date" : server_date,
                                            "status" : "4",
                                            "message_text" : json["content"],
                                            "audio_id" : "",
                                            "video_id" : "",
                                            "image_id" : "",
                                            "file_id" : "",
                                            "thumb_id" : "",
                                            "opposite_pin" : "",
                                            "format" : "",
                                            "blog_id" : "",
                                            "read_receipts" : "4",
                                            "chat_id" : "",
                                            "account_type" : "1",
                                            "credential" :"",
                                            "reff_id" : "",
                                            "message_large_text" : "",
                                            "attachment_flag" : "0",
                                            "local_timestamp" : String(Date().currentTimeMillis())
                                        ], replace: true)
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                let pin = "-997"
                                var pinned = 0
                                var archived = 0
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select pinned, archived from MESSAGE_SUMMARY where l_pin = '\(pin)'"), cursor.next() {
                                            pinned = Int(cursor.int(forColumnIndex: 0))
                                            archived = Int(cursor.int(forColumnIndex: 1))
                                        }
                                        _ = try Database.shared.insertRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                                            "l_pin" : pin,
                                            "message_id" : message_id,
                                            "counter" : 0,
                                            "pinned" : pinned,
                                            "archived" : archived
                                        ], replace: true)
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                //print("insert db message summary \(message_id)")
                                var row: [String: Any?] = [:]
                                row["message_id"] = message_id
                                row["f_pin"] = "-997"
                                row["l_pin"] = me
                                row["message_scope_id"] = "31"
                                row["server_date"] = server_date
                                row["status"] = "3"
                                row["message_text"] = json["content"]
                                row["audio_id"] = ""
                                row["video_id"] = ""
                                row["image_id"] = ""
                                row["thumb_id"] = ""
                                row["read_receipts"] = "4"
                                row["credential"] = ""
                                row["file_id"] = ""
                                row["reff_id"] = ""
                                row["progress"] = 100.0
                                row["attachment_flag"] = "0"
                                row["lock"] = ""
                                row["is_stared"] = "0"
                                row["isSelected"] = false
                                if !self.dataDates.contains("Today".localized()) {
                                    self.dataDates.append("Today".localized())
                                    self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .none)
                                }
                                row["chat_date"] = "Today".localized()
                                row["blog_id"] = "0"
                                self.counter += 1
                                self.expectBubbleArrival(messageId: message_id, outgoing: false)
                                self.tableChatView.beginUpdates()
                                self.dataMessages.append(row)
                                let answered = IndexPath(row: self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)
                                self.tableChatView.insertRows(at: [answered], with: .none)
                                self.tableChatView.endUpdates()
                                self.retryPendingBubbleArrival(at: answered)
                                // The arrival takes the list up with it; this only finishes the
                                // job if it never played.
                                self.slideToNewestMessage()
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                                self.loadingResponse = false
                            }
                        }
                    }
                }
            } catch {
                print("Error encoding data: \(error.localizedDescription)")
            }
        }
    }
    
    func loadData(){
        SecureUserDefaults.shared.set(dataPerson["f_pin"]!, forKey: "inEditorPersonal")
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [dataPerson["f_pin"]!!])
        
        if self.fromNotification {
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
        getData()
        
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
        // Fix: iOS 26 blurs the top edge of a scroll view that runs under a bar - a soft white
        // band across the first row, over whatever the wallpaper and the topmost bubble were.
        // It read as the date header having a background, and it does not: the header's
        // container is clear. The list is meant to show through to the bar, the way the media
        // viewer already does, so the effect is switched off the same way it is there.
        if #available(iOS 26.0, *) {
            tableChatView.topEdgeEffect.isHidden = true
            tableChatView.bottomEdgeEffect.isHidden = true
        }
        tableChatView.dataSource = self
        tableChatView.keyboardDismissMode = .interactive
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableChatView.addGestureRecognizer(tapGesture)
        let idMe = User.getMyPin() as String?
        for i in 0..<dataMessages.count {
            if dataMessages[i]["f_pin"] as? String != idMe {
                sendReadMessageStatus(chat_id: "", f_pin: dataPerson["f_pin"]!!, message_scope_id: "3", message_id: dataMessages[i]["message_id"] as! String)
            }
        }
        // The table used to be hidden here and faded in half a second later, which is where the
        // white flash on opening the bot came from. The placement is held instead - see
        // applyPendingInitialBottomScroll - and there is nothing left to hide.
        pendingInitialScrollToBottom = true
        tableChatView.scrollToBottom(isAnimated: false)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isInitialLoading = false
            if !self.autoText.isEmpty {
                self.textFieldSend.text = self.autoText
                self.sendChat(message_text: self.textFieldSend.text, viewController: self)
            }
        }
    }
    
    private func changeAppBar() {
        let viewAppBar = UIView()
        viewAppBar.frame.size = CGSize(width: self.view.frame.size.width, height: 44)
        
        if !isSearching {
            let imageProfile = UIImageView(frame: ChatHeaderMetrics.pictureFrame())
            imageProfile.circle()
            imageProfile.clipsToBounds = true
//            var count = 0
            viewAppBar.addSubview(imageProfile)
            if let urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") {//resourcesMediaBundle
                imageProfile.sd_setImage(with: urlGif) { (image, error, cacheType, imageURL) in
                    if error == nil {
                        imageProfile.animationImages = image?.images
                        imageProfile.animationDuration = image?.duration ?? 0.0
                        imageProfile.animationRepeatCount = 0
                        imageProfile.startAnimating()
                    }
                }
            } else if let urlGif = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") {
                imageProfile.sd_setImage(with: urlGif) { (image, error, cacheType, imageURL) in
                    if error == nil {
                        imageProfile.animationImages = image?.images
                        imageProfile.animationDuration = image?.duration ?? 0.0
                        imageProfile.animationRepeatCount = 0
                        imageProfile.startAnimating()
                    }
                }
            }
            // The bar sizes itself to whatever is free between the buttons - see
            // `ChatHeaderMetrics.layoutTitleView`, called once everything is in it.
            let titleNavigation = MarqueeLabel()
            viewAppBar.addSubview(titleNavigation)
            titleNavigation.text = Utils.getGPTBotName()
            titleNavigation.textColor = .white
            titleNavigation.font = UIFont.systemFont(ofSize: ChatHeaderMetrics.titleFontSize + offset()).bold
            
            ChatHeaderMetrics.layoutTitleView(viewAppBar, title: titleNavigation)
            navigationItem.titleView = viewAppBar
            titleText = titleNavigation.text
        } else {
            searchBar = ChatSearchBar()
            searchBar.autocapitalizationType = .none
            searchBar.delegate = self
            searchBar.searchTextField.tintColor = .mainColor
            searchBar.searchTextField.textColor = .mainColor
//            searchBar.updateHeight(height: 36, radius: 18)
            searchBar.showsCancelButton = false
//            searchBar.setMagnifyingGlassColorTo(color: .white)
            // Fix: this was still drawing the old nx_search_bar bitmap, which is 30pt tall and
            // stretched to whatever width it is given - so its rounded ends came out as ellipses
            // and it stood a good deal shorter than the button beside it. The same field the two
            // conversation editors use, for the same reasons - see
            // ChatHeaderMetrics.dressSearchBar.
            ChatHeaderMetrics.dressSearchBar(searchBar, fill: UIColor(red: 248.0 / 255.0, green: 252.0 / 255.0, blue: 254.0 / 255.0, alpha: 1.0))
            navigationItem.titleView = searchBar
            self.definesPresentationContext = true
        }
        
        if copySession || deleteSession || isSearching {
            navigationItem.hidesBackButton = true
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            navigationItem.hidesBackButton = false
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
    
    private func getData() {
        let query = "SELECT message_id, f_pin, l_pin, message_scope_id, server_date, status, message_text, audio_id, video_id, image_id, thumb_id, read_receipts, chat_id, file_id, attachment_flag, reff_id, lock, is_stared, blog_id, credential FROM MESSAGE where (f_pin='\(dataPerson["f_pin"]!!)' or l_pin='\(dataPerson["f_pin"]!!)') AND message_scope_id = '\(MessageScope.GPT_CHATBOT)' order by server_date asc"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    while cursorData.next() {
                        var row: [String: Any?] = [:]
                        row["message_id"] = cursorData.string(forColumnIndex: 0) ?? ""
                        row["f_pin"] = cursorData.string(forColumnIndex: 1) ?? ""
                        row["l_pin"] = cursorData.string(forColumnIndex: 2) ?? ""
                        row["message_scope_id"] = cursorData.string(forColumnIndex: 3) ?? ""
                        row["server_date"] = cursorData.string(forColumnIndex: 4) ?? ""
                        row["status"] = cursorData.string(forColumnIndex: 5) ?? ""
                        row["message_text"] = cursorData.string(forColumnIndex: 6) ?? ""
                        row["audio_id"] = cursorData.string(forColumnIndex: 7) ?? ""
                        row["video_id"] = cursorData.string(forColumnIndex: 8) ?? ""
                        row["image_id"] = cursorData.string(forColumnIndex: 9) ?? ""
                        row["thumb_id"] = cursorData.string(forColumnIndex: 10) ?? ""
                        row["read_receipts"] = cursorData.string(forColumnIndex: 11) ?? ""
                        row["chat_id"] = cursorData.string(forColumnIndex: 12) ?? ""
                        row["file_id"] = cursorData.string(forColumnIndex: 13) ?? ""
                        row["attachment_flag"] = cursorData.string(forColumnIndex: 14) ?? ""
                        row["reff_id"] = cursorData.string(forColumnIndex: 15) ?? ""
                        row["lock"] = cursorData.string(forColumnIndex: 16) ?? ""
                        row["is_stared"] = cursorData.string(forColumnIndex: 17) ?? ""
                        row["blog_id"] = cursorData.string(forColumnIndex: 18) ?? ""
                        row["credential"] = cursorData.string(forColumnIndex: 19) ?? ""
                        if let cursorStatus = Database.shared.getRecords(fmdb: fmdb, query: "SELECT status FROM MESSAGE_STATUS WHERE message_id='\(row["message_id"] as! String)'") {
                            while cursorStatus.next() {
                                row["status"] = cursorStatus.string(forColumnIndex: 0)
                            }
                            cursorStatus.close()
                        }
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["video_id"] as? String ?? "")
                            let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["file_id"] as? String ?? "")
                            do {
                                if ((row["video_id"] as! String) != "") {
                                    if FileManager.default.fileExists(atPath: videoURL.path) || FileEncryption.shared.isSecureExists(filename: row["video_id"] as? String ?? ""){
                                        row["progress"] = 100.0
                                    } else {
                                        row["progress"] = 0.0
                                    }
                                } else {
                                    if FileManager.default.fileExists(atPath: fileURL.path) || FileEncryption.shared.isSecureExists(filename: row["file_id"] as? String ?? ""){
                                        row["progress"] = 100.0
                                    } else {
                                        row["progress"] = 0.0
                                    }
                                }
                            }
                        }
                        row["chat_date"] = chatDate(stringDate: row["server_date"] as? String ?? "")
                        row["isSelected"] = false
                        dataMessages.append(row)
                        var gptRow : [String: String] = [:]
                        gptRow["role"] = row["f_pin"] as! String == "-997" ? "assistant" : "user"
                        gptRow["content"] = row["message_text"] as? String ?? ""
                        chatGPTMessages.append(gptRow)
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    private func setRightButtonItem() {
        navigationItem.rightBarButtonItems = nil
        let actionDelete = UIAction(title: "Delete Conversation".localized(), handler: {(_) in
            let alert = LibAlertController(title: "", message: "Are you sure to delete all message in this conversation?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete".localized(), style: .destructive, handler: {(_) in
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "f_pin='\(self.dataPerson["f_pin"]!!)' or l_pin='\(self.dataPerson["f_pin"]!!)'")
                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(self.dataPerson["f_pin"]!!)'")
                        let l_pin = self.dataPerson["f_pin"]!!
                        SecureUserDefaults.shared.removeValue(forKey: "saved_\(l_pin)")
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                        self.navigationController?.popViewController(animated: true)
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
            }))
            self.present(alert, animated: true, completion: nil)
        })
        let actionSearch = UIAction(title: "Search".localized(), handler: {(_) in
            self.isSearching = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                // Fix: a cancel button was put in the navigation bar here, beside a search field
                // laid out by the search bar - two layouts, and they disagreed by 5pt. The search
                // bar carries its own now, so the row is left empty for it to fill.
                self.navigationItem.rightBarButtonItems = nil
                self.navigationItem.rightBarButtonItem = nil
                self.changeAppBar()
                self.addMultipleSelectSession()
            }
        })
        var menu = UIMenu(title: "", children: [
            actionSearch,
            actionDelete
        ])
        
        let moreIcon = UIBarButtonItem(image: UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular, scale: .default)), menu: menu)
        navigationItem.rightBarButtonItem = moreIcon
    }
    
    @objc func dismissKeyboard() {
        if isSearching {
            searchBar.resignFirstResponder()
        } else {
            textFieldSend.resignFirstResponder() // dismiss keyoard
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil {
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            self.constraintViewTextField.constant = 0
            self.constraintBottomContainerMultpileSelectSession.constant = 0
            UIView.animate(withDuration: TimeInterval(duration), animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if self.viewIfLoaded?.window != nil {
            let info:NSDictionary = notification.userInfo! as NSDictionary
            let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            let keyboardHeight: CGFloat = keyboardSize.height
            
            let duration: CGFloat = info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber as! CGFloat
            
            if self.constraintViewTextField.constant != -keyboardHeight {
                self.constraintViewTextField.constant = -keyboardHeight
                if isSearching {
                    self.constraintViewTextField.constant = self.constraintViewTextField.constant - 60
                    self.constraintBottomContainerMultpileSelectSession.constant = -keyboardHeight
                }
                UIView.animate(withDuration: TimeInterval(duration), animations: {
                    self.view.layoutIfNeeded()
                })
                if isSearching {
                    self.tableChatView.scrollToBottom()
                } else {
                    if (self.currentIndexpath != nil) {
                        self.tableChatView.scrollToRow(at: IndexPath(row: self.currentIndexpath!.row, section: self.currentIndexpath!.section), at: .none, animated: false)
                    } else {
                        self.tableChatView.scrollToBottom()
                    }
                }
            }
        }
    }
    
    @objc func onReceiveMessage(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let chatData = dataMessage.mBodies
                if (chatData[CoreMessage_TMessageKey.F_PIN] == self.dataPerson["f_pin"]!! && (chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID] == "3")) {
                    if chatData[CoreMessage_TMessageKey.F_PIN] == nil {
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
                    row["isSelected"] = false
                    if !self.dataDates.contains("Today".localized()) {
                        self.dataDates.append("Today".localized())
                        self.tableChatView.insertSections(IndexSet(integer: self.dataDates.count - 1), with: .none)
                    }
                    row["chat_date"] = "Today".localized()
                    row["blog_id"] = chatData[CoreMessage_TMessageKey.BLOG_ID]
                    self.counter += 1
                    // Written down before the insert so the bubble is small the first time it is
                    // drawn - see pendingBubbleArrival.
                    self.expectBubbleArrival(messageId: row["message_id"] as? String ?? "", outgoing: false)
                    self.tableChatView.beginUpdates()
                    self.dataMessages.append(row)
                    let arrived = IndexPath(row: self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1, section: self.dataDates.count - 1)
                    self.tableChatView.insertRows(at: [arrived], with: .none)
                    self.tableChatView.endUpdates()
                    self.retryPendingBubbleArrival(at: arrived)
                    if chatData[CoreMessage_TMessageKey.FORMAT] == "1" {
                        self.sendReadMessageStatus(chat_id: "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        // The arrival above has already taken the list up with it, on the same
                        // clock as the bubble; this only finishes the job if it never played.
                        // scrollToBottom would start a second scroll of its own and fight it.
                        self.slideToNewestMessage()
                    } else if self.currentIndexpath?.row == (self.dataMessages.count - 2) {
                        if (self.viewIfLoaded?.window != nil) {
                            self.sendReadMessageStatus(chat_id: "", f_pin: chatData[CoreMessage_TMessageKey.F_PIN]!, message_scope_id: chatData[CoreMessage_TMessageKey.MESSAGE_SCOPE_ID]!, message_id: chatData[CoreMessage_TMessageKey.MESSAGE_ID]!)
                        }
                        self.slideToNewestMessage()
                        if ( self.currentIndexpath!.section <= self.dataDates.count - 1 && self.currentIndexpath!.row <= self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[self.dataDates.count - 1]}).count - 1)  {
                            self.counter = 0
                            self.updateCounter(counter: self.counter)
                        }
                        let lastMarkerCounter = markerCounter
                        if self.markerCounter != nil {
                            self.markerCounter = nil
                        }
                        let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == lastMarkerCounter })
                        if indexMessage != nil {
                            let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"] as! String)
                            let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[indexMessage!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
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
                            self.markerCount = self.counter
                            self.addCounterAtButttonScrollToBottom()
                            let indexMessage = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == self.markerCounter })
                            if indexMessage != nil {
                                let section = self.dataDates.firstIndex(of: self.dataMessages[indexMessage!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[indexMessage!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[indexMessage!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                        } else if self.indicatorCounterBSTB.isDescendant(of: self.view) {
                            self.labelCounter.text = "\(self.counter)"
                        }
                    }
                }
            }
        }
    }
    
    @objc func onStatusChat(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                let chatData = dataMessage.mBodies
                let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                let requester = onGoingCC.components(separatedBy: ",")[0]
                let idMe = User.getMyPin()!
                if chatData[CoreMessage_TMessageKey.F_PIN] == self.dataPerson["f_pin"]!! || chatData[CoreMessage_TMessageKey.L_PIN] == self.dataPerson["f_pin"]!! || requester == idMe {
                    if (chatData.keys.contains(CoreMessage_TMessageKey.MESSAGE_ID) && !(chatData[CoreMessage_TMessageKey.MESSAGE_ID]!).contains("-2,")) {
                        var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == chatData[CoreMessage_TMessageKey.MESSAGE_ID]! })
                        if (idx != nil) {
                            if (chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] == "1") {
                                self.dataMessages[idx!]["lock"] = "1"
                                self.dataMessages[idx!]["reff_id"] = ""
                                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            } else {
                                self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                        }
                    }
                    else if (chatData.keys.contains("message_id")) {
                        var idx = self.dataMessages.firstIndex(where: { "'\(String(describing: $0["message_id"] as? String))'" == chatData["message_id"]! })
                        if (idx != nil) {
                            if (chatData[CoreMessage_TMessageKey.DELETE_MESSAGE_FLAG] == "1") {
                                self.dataMessages[idx!]["lock"] = "1"
                                self.dataMessages[idx!]["reff_id"] = ""
                                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            } else {
                                self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                                if row != nil && section != nil  {
                                    self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                                }
                            }
                        }
                    }
                    else {
                        let messageId = chatData[CoreMessage_TMessageKey.MESSAGE_ID]!.split(separator: ",")[1]
                        var idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String ?? "" == messageId })
                        if (idx != nil) {
                            self.dataMessages[idx!]["status"] = chatData[CoreMessage_TMessageKey.STATUS]!
                            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                            let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataMessages[idx!]["chat_date"] as! String}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String })
                            if row != nil && section != nil  {
                                self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func onTyping(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            let message: TMessage = data["message"] as! TMessage
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            if !onGoingCC.isEmpty {
                let officer = onGoingCC.isEmpty ? "" : onGoingCC.component(1, separatedBy: ",")
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
    
    private func sendReadMessageStatus(chat_id: String, f_pin: String, message_scope_id: String, message_id: String) {
        let message = CoreMessage_TMessageBank.getUpdateRead(p_chat_id: chat_id, p_f_pin: f_pin, p_scope_id: message_scope_id, qty: 1)
        let fPin = message.getBody(key: CoreMessage_TMessageKey.F_PIN)
        let scope = message.getBody(key: CoreMessage_TMessageKey.SCOPE_ID)
        message.mBodies[CoreMessage_TMessageKey.SERVER_DATE] = String(Date().currentTimeMillis())
        if (fPin.elementsEqual("-999") || scope.elementsEqual("16") || scope.elementsEqual("15")){
            return
        }
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                        "status" : "4"
                    ], _where: "message_id = '\(message_id)'")
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            message.mStatus = CoreMessage_TMessageUtil.getTID()
            message.mBodies[CoreMessage_TMessageKey.L_PIN] = f_pin
            message.mBodies[CoreMessage_TMessageKey.MESSAGE_ID] = "-2,\(message_id)"
            _ = Nexilis.write(message: message)
        }
        if let index = dataMessages.firstIndex(where: {$0["message_id"] as? String == message_id}) {
            dataMessages[index]["status"] = "4"
        }
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
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                if lang == "id" {
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                }
                if !dataDates.contains(formatter.string(from: date)){
                    dataDates.append(formatter.string(from: date))
                }
                return formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = ChatDayLabel.format(for: date)
                let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                if lang == "id" {
                    formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                }
                let stringFormat = formatter.string(from: date as Date)
                if !dataDates.contains(stringFormat){
                    dataDates.append(stringFormat)
                }
                return stringFormat
            }
        }
    }
    
    private func updateCounter(counter: Int) {
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", cvalues: [
                        "counter" : "\(counter)"
                    ], _where: "l_pin = '\(self.dataPerson["f_pin"]!!)'")
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
        }
    }
    
    private func addButtonScrollToBottom() {
        self.view.addSubview(buttonScrollToBottom)
        buttonScrollToBottom.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonScrollToBottom.bottomAnchor.constraint(equalTo: buttonSendChat.topAnchor, constant: -50),
            buttonScrollToBottom.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            buttonScrollToBottom.widthAnchor.constraint(equalToConstant: 60),
            buttonScrollToBottom.heightAnchor.constraint(equalToConstant: 30.0)
        ])
        buttonScrollToBottom.backgroundColor = .greenColor
        buttonScrollToBottom.setImage(UIImage(systemName: "chevron.down.circle"), for: .normal)
        buttonScrollToBottom.imageView?.contentMode = .scaleAspectFit
        buttonScrollToBottom.imageView?.tintColor = .white
        buttonScrollToBottom.contentVerticalAlignment = .fill
        buttonScrollToBottom.contentHorizontalAlignment = .fill
        buttonScrollToBottom.imageEdgeInsets.top = 2.0
        buttonScrollToBottom.imageEdgeInsets.bottom = 2.0
        buttonScrollToBottom.layer.cornerRadius = 10.0
        buttonScrollToBottom.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        buttonScrollToBottom.clipsToBounds = true
        buttonScrollToBottom.addTarget(self, action: #selector(scrollTobottomAction), for: .touchUpInside)
    }
    
    private func addCounterAtButttonScrollToBottom() {
        self.view.addSubview(indicatorCounterBSTB)
        indicatorCounterBSTB.translatesAutoresizingMaskIntoConstraints = false
        indicatorCounterBSTB.backgroundColor = .systemRed
        indicatorCounterBSTB.layer.cornerRadius = 7.5
        indicatorCounterBSTB.clipsToBounds = true
        indicatorCounterBSTB.layer.borderWidth = 0.5
        indicatorCounterBSTB.layer.borderColor = UIColor.secondaryColor.cgColor
        NSLayoutConstraint.activate([
            indicatorCounterBSTB.bottomAnchor.constraint(equalTo: buttonScrollToBottom.topAnchor, constant: 5),
            indicatorCounterBSTB.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -50),
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
        tableChatView.scrollToBottom()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            if buttonScrollToBottom.isDescendant(of: self.view) {
                buttonScrollToBottom.removeConstraints(buttonScrollToBottom.constraints)
                buttonScrollToBottom.removeFromSuperview()
                if indicatorCounterBSTB.isDescendant(of: self.view) {
                    indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
                    indicatorCounterBSTB.removeFromSuperview()
                }
            }
        }
    }
    
    private func checkNewMessage(tableView: UITableView) {
//        let indexPathFirst = tableView.indexPathsForVisibleRows?.first
//        if indexPathFirst != nil {
//            let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPathFirst!.section] })
//            if self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPathFirst!.row]["message_id"] as? String }) == 0 && !gettingDataMessage {
//                gettingDataMessage = true
//                addDataMessage()
//            }
//        }
        currentIndexpath = tableView.indexPathsForVisibleRows?.last
        if currentIndexpath != nil {
            let dataMessages = dataMessages.filter({ $0["chat_date"] as! String == dataDates[currentIndexpath!.section] })
            if dataMessages.count == 0 || dataMessages.count - 1 < currentIndexpath!.row {
                return
            }
            if currentIndexpath!.section == dataDates.count - 1 && currentIndexpath!.row != dataMessages.count - 1 && currentIndexpath!.row != dataMessages.count - 2 && !buttonScrollToBottom.isDescendant(of: self.view) {
                addButtonScrollToBottom()
                addCounterAtButttonScrollToBottom()
            } else if currentIndexpath!.section == dataDates.count - 1 && currentIndexpath!.row == dataMessages.count - 1 {
                if buttonScrollToBottom.isDescendant(of: self.view) {
                    buttonScrollToBottom.removeConstraints(buttonScrollToBottom.constraints)
                    buttonScrollToBottom.removeFromSuperview()
                    if indicatorCounterBSTB.isDescendant(of: self.view) {
                        indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
                        indicatorCounterBSTB.removeFromSuperview()
                    }
                }
            }
//            let indexPathFirst = tableChatView.indexPathsForVisibleRows?.first
//            if indexPathFirst != nil && listViewOnSection.count != 0 && listViewOnSection.count - 1 >= indexPathFirst!.section {
//                let headerView = listViewOnSection[indexPathFirst!.section]
//                if headerView.isHidden {
//                    headerView.isHidden = false
//                }
//            }
            var listData = dataMessages[0...currentIndexpath!.row]
            listData = listData.filter({$0["status"] as? String != "4" && $0["status"] as? String != "8"})
            if listData.count != 0 {
                let idMe = User.getMyPin() as String?
                for i in 0...listData.count - 1 {
                    if listData[i]["f_pin"] as? String != idMe {
                        sendReadMessageStatus(chat_id: "", f_pin: dataPerson["f_pin"]!!, message_scope_id: "31", message_id: listData[i]["message_id"] as! String)
                    }
                }
            }
        }
        if counter == 0 && indicatorCounterBSTB.isDescendant(of: self.view) {
            indicatorCounterBSTB.removeConstraints(indicatorCounterBSTB.constraints)
            indicatorCounterBSTB.removeFromSuperview()
        } else if counter != 0 && currentIndexpath != nil {
            let dataFilter = dataMessages.filter({ $0["chat_date"] as! String == dataDates[currentIndexpath!.section] })
            if dataFilter.count == 0 {
                return
            }
            let idx = dataMessages.firstIndex(where: { $0["message_id"] as? String == dataFilter[currentIndexpath!.row]["message_id"] as? String})
            if idx == nil {
                return
            }
            if (dataMessages.count - counter) <= idx! {
                let countUpdate = idx! - (dataMessages.count - counter)
                counter = counter - (countUpdate + 1)
                if indicatorCounterBSTB.isDescendant(of: self.view) {
                    labelCounter.text = "\(counter)"
                }
                updateCounter(counter: counter)
            }
        }
    }
    
    private func sendTyping(l_pin: String, isTyping: Bool = false) {
        DispatchQueue.global().async {
            let tmessage = CoreMessage_TMessageBank.getUpdateTypingStatus(p_opposite: l_pin, p_scope: "3", p_status: isTyping ? "3": "4")
            _ = Nexilis.write(message: tmessage)
        }
    }

}

extension ChatGPTBotView: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        if showMenuContext {
            showMenuContext = false
            interaction.view!.removeInteraction(interaction)
        }
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if textFieldSend.isFirstResponder {
            textFieldSend.resignFirstResponder()
        }
        let indexPath = self.tableChatView.indexPathForRow(at: interaction.view!.convert(location, to: self.tableChatView))
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath!.section]})
        let copy = UIAction(title: "Copy".localized(), image: UIImage(systemName: "doc.on.doc.fill"), handler: {(_) in
            if self.isSearching {
                self.cancelAction()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.copySession = true
                let cancelButton = self.selectionCancelBarButton()
                if self.dataPerson["f_pin"] != "-999" {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.startMultipleSelectSession()
            }
        })
        let info = UIAction(title: "Info".localized(), image: UIImage(systemName: "info.circle.fill"), handler: {(_) in
            let messageInfoVC = MessageInfo()
            messageInfoVC.data = dataMessages[indexPath!.row]
            messageInfoVC.dataPerson = self.dataPerson
            self.navigationController?.pushViewController(messageInfoVC, animated: true)
        })
        let delete = UIAction(title: "Delete".localized(), image: UIImage(systemName: "trash.fill"), attributes: .destructive, handler: {(_) in
            if self.isSearching {
                self.cancelAction()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.deleteSession = true
                let cancelButton = self.selectionCancelBarButton()
                if self.dataPerson["f_pin"] != "-999" {
                    self.navigationItem.rightBarButtonItems = nil
                }
                self.navigationItem.rightBarButtonItem = cancelButton
                self.changeAppBar()
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath!.row]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = true
                }
                self.startMultipleSelectSession()
            }
        })
        
        let children: [UIMenuElement] = [copy, delete]
//        let copyOption = self.copyOption(indexPath: indexPath!)
//        let idMe = User.getMyPin() as String?
//        if (dataMessages[indexPath!.row]["lock"] != nil && dataMessages[indexPath!.row]["lock"] as! String == "1") || dataMessages[indexPath!.row]["message_scope_id"] as! String == "18" || dataPerson["f_pin"] == "-999" || dataMessages[indexPath!.row]["credential"] as! String == "1" {
//            children = [delete]
//        } else {
//            if (dataMessages[indexPath!.row]["f_pin"] as! String) == idMe {
//                children.insert(info, at: children.count - 1)
//            }
//        }
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "", children: children)
        }
    }
    
    @objc func cancelAction() {
        let token = selectionSessionToken
        DispatchQueue.main.async {
            guard token == self.selectionSessionToken else { return }
            if self.copySession {
                self.copySession = false
            } else if self.deleteSession {
                self.deleteSession = false
            } else if self.isSearching {
                self.countMatchesSearch = 0
                self.isSearching = false
            }
            if self.viewTextField.isHidden {
                self.viewTextField.isHidden = false
            }
            // Fix: closing a session scrolled to the last row it had seen, which threw away
            // wherever the reader had actually scrolled to. The table only changes height by
            // whatever the bar takes; giving that room back without moving the conversation is
            // all this needs to do.
            if let restored = self.bottomTableConstantBeforeSelection {
                let readingPlace = self.distanceFromNewestMessage()
                self.constraintBottomTableViewWithTextfield.constant = restored
                self.bottomTableConstantBeforeSelection = nil
                self.view.layoutIfNeeded()
                self.restoreDistanceFromNewestMessage(readingPlace)
            }
            let data = self.dataMessages.filter({ $0["isSelected"] as? Bool ?? false == true })
            for i in 0..<data.count {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == data[i]["message_id"] as? String})
                if idx != nil{
                    self.dataMessages[idx!]["isSelected"] = false
                }
            }
            self.setRightButtonItem()
            self.changeAppBar()
            if self.fromNotification {
                let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(self.didTapExit))
                self.navigationItem.leftBarButtonItem = backButton
            }
            // The circles leave the way they arrived, and the table is only built again once that
            // has finished - a rebuild in the middle of the fade would cut it short.
            self.setSelectionChrome(shown: false, animated: true) {
                self.tableChatView.reloadDataKeepingPlace()
                self.checkNewMessage(tableView: self.tableChatView)
            }
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn, .allowUserInteraction], animations: {
                self.containerMultpileSelectSession.alpha = 0
            }, completion: { _ in
                // A session opened again while this was running owns the bar now.
                guard !self.copySession, !self.deleteSession, !self.isSearching else { return }
                self.containerMultpileSelectSession.removeFromSuperview()
                self.containerMultpileSelectSession.alpha = 1
            })
        }
    }
    
    private func addMultipleSelectSession() {
        selectionSessionToken += 1
        viewTextField.isHidden = true
        // Fix: the bar hung off the bottom of the window, so on a device with a home indicator
        // the button on it sat underneath. It stands on the safe area now, in the place the input
        // bar had, and the table is given back exactly the room that leaves.
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
        // Nothing is painted behind the capsule on iOS 26 - it floats over the chat.
        if #available(iOS 26.0, *) {
            containerMultpileSelectSession.backgroundColor = .clear
        } else {
            containerMultpileSelectSession.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .white
        }
        addSubviewMultipleSession()
        containerMultpileSelectSession.alpha = 0
        view.layoutIfNeeded()
        restoreDistanceFromNewestMessage(readingPlace)
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            self.containerMultpileSelectSession.alpha = 1
        })
    }

    /// Opens a selection session on screen: the bar at the bottom, every row built again with its
    /// circle still hidden, and then the fade that brings the circles in.
    private func startMultipleSelectSession() {
        selectionChromeShown = false
        addMultipleSelectSession()
        tableChatView.reloadDataKeepingPlace()
        setSelectionChrome(shown: true, animated: true)
    }

    /// Fades the selection circles in or out over the rows that are on screen.
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

    /// Puts one cell into whichever of the two states the screen is in.
    private func applySelectionChrome(to cell: UITableViewCell) {
        if let mark = cell.contentView.viewWithTag(ChatGPTBotView.selectionMarkTag) {
            mark.alpha = selectionChromeShown ? 1 : 0
            mark.transform = selectionChromeShown ? .identity : ChatGPTBotView.selectionMarkHidden
        }
        if let shift = selectionShift(of: cell) {
            let wanted = selectionChromeShown ? ChatGPTBotView.bubbleLeadingInSession : ChatGPTBotView.bubbleLeadingNormal
            if shift.constant != wanted {
                shift.constant = wanted
                // Inside the fade this travels with the circle; outside it - a cell handed back
                // from the cache - it simply lands in the right place.
                cell.contentView.layoutIfNeeded()
            }
        }
        // Fix: a link answered a tap of its own while a session was open, so a tap meant to tick a
        // message opened a browser instead. Nothing inside a bubble answers while messages are
        // being picked; the tap falls through to the row, which is what the session is for.
        cell.contentView.isUserInteractionEnabled = !isSelectionSessionActive
    }

    /// Where an incoming bubble sits when there is no picture to its left, with a session open
    /// and without one.
    ///
    /// A bubble that already starts at the left edge has no free column beside it, so unlike a
    /// group's - where the circle simply takes the sender's picture's place - it has to make room.
    /// The shift is animated together with the circle rather than arriving with a redraw, which
    /// is what made it read as the whole conversation jumping sideways.
    static let bubbleLeadingNormal: CGFloat = 15
    static let bubbleLeadingInSession: CGFloat = 50

    private static var selectionShiftKey: UInt8 = 0
    private static var bubbleSignatureKey: UInt8 = 0

    /// The tag the bubble carries so an arrival animation can find it again in a built cell.
    static let bubbleTag = 77_301

    /// How long a bubble takes to grow, measured off the reference. The same as the two editors.
    static let bubbleArrivalDuration: TimeInterval = 0.18


    /// Everything the drawing of one bubble depends on, in one string.
    ///
    /// Fix: a bubble was emptied and built again from nothing every time the table asked for a
    /// row, and it asks for every row of every redraw - not only for rows that are new to the
    /// screen. A message arriving, a status changing, an answer streaming in: each of those
    /// redraws rows whose bubbles are already correct and already in front of the reader. Both
    /// editors have been holding on to a built cell for a while; this screen was still throwing
    /// its work away. When the cell in hand was built for this message in this state, it is
    /// already the answer.
    ///
    /// The whole message goes in, not a chosen few of its fields. Choosing which fields matter
    /// is exactly how a bubble ends up showing yesterday's state, and a field costs nothing to
    /// include.
    private func bubbleSignature(for message: [String: Any?], at indexPath: IndexPath) -> String {
        let messageId = message["message_id"] as? String ?? ""
        var parts: [String] = ["\(indexPath.section).\(indexPath.row)"]
        for key in message.keys.sorted() {
            parts.append("\(key)=" + (message[key].map { String(describing: $0) } ?? "nil"))
        }
        // ...and the state of the screen around it, which the drawing reads just as much.
        // `selectionChromeShown` is deliberately not here: a cell handed back is put into
        // whichever of the two states the screen is in by applySelectionChrome, and a fade that
        // rebuilt every row would be no fade at all.
        parts.append("session=\(copySession)\(deleteSession)")
        parts.append("search=\(isSearching)|\(textSearch)")
        parts.append("marker=\(markerCounter == messageId)")
        parts.append("font=\(offset())")
        // Width decides where a bubble ends; appearance decides half the colours. Neither is in
        // the message, and both change under the reader.
        parts.append("width=\(Int(view.frame.size.width))")
        parts.append("appearance=\(traitCollection.userInterfaceStyle.rawValue)")
        return parts.joined(separator: ";")
    }

    /// What the cell in hand was last built for, or nil when it holds nothing built.
    private func builtSignature(of cell: UITableViewCell) -> String? {
        return objc_getAssociatedObject(cell, &ChatGPTBotView.bubbleSignatureKey) as? String
    }

    private func setBuiltSignature(_ signature: String?, on cell: UITableViewCell) {
        objc_setAssociatedObject(cell, &ChatGPTBotView.bubbleSignatureKey, signature, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    /// Takes a cell back to empty, ready to be built into.
    private func emptyBubbleCell(_ cell: UITableViewCell) {
        setBuiltSignature(nil, on: cell)
        setSelectionShift(nil, on: cell)
        cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
    }

    private func setSelectionShift(_ constraint: NSLayoutConstraint?, on cell: UITableViewCell) {
        objc_setAssociatedObject(cell, &ChatGPTBotView.selectionShiftKey, constraint, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func selectionShift(of cell: UITableViewCell) -> NSLayoutConstraint? {
        return objc_getAssociatedObject(cell, &ChatGPTBotView.selectionShiftKey) as? NSLayoutConstraint
    }

    /// Whether messages are being picked out right now, whatever the picking is for.
    private var isSelectionSessionActive: Bool {
        return copySession || deleteSession
    }

    /// How far the reader is from the newest message, in points - 0 when sitting at the bottom.
    private func distanceFromNewestMessage() -> CGFloat {
        return max(0, tableChatView.contentSize.height + tableChatView.adjustedContentInset.bottom
                      - tableChatView.bounds.height - tableChatView.contentOffset.y)
    }

    /// Puts the reader back that far from the newest message once the table has been resized.
    private func restoreDistanceFromNewestMessage(_ distance: CGFloat) {
        let maximum = tableChatView.contentSize.height + tableChatView.adjustedContentInset.bottom
            - tableChatView.bounds.height
        let minimum = -tableChatView.adjustedContentInset.top
        tableChatView.contentOffset.y = min(max(maximum - distance, minimum), max(maximum, minimum))
    }

    /// The button that closes a selection session.
    ///
    /// iOS 26 closes a mode with a round button of glass carrying an x; older releases keep the
    /// word, which is what they draw everywhere else. The item is left plain on purpose - the bar
    /// draws the glass circle around it, and a button carrying its own would be a second one.
    private func selectionCancelBarButton() -> UIBarButtonItem {
        if #available(iOS 26.0, *) {
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
        // iOS 26 floats a bar like this clear of the edges as a capsule of glass; before it, the
        // bar stays the full-width block with the shadow.
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
            } else if deleteSession {
                button.image = UIImage(systemName: "trash")
                if countSelected == 0 {
                    button.tintColor = .gray
                } else {
                    button.tintColor = .red
                }
            }
            let buttonGesture = UITapGestureRecognizer(target: self, action: #selector(sessionAction))
            button.isUserInteractionEnabled = true
            button.addGestureRecognizer(buttonGesture)
            
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
            var text = ""
            for i in 0..<countSelected {
                let stringDate = (dataMessages[i]["server_date"] as! String)
                let date = Date(milliseconds: Int64(stringDate)!)
                let formatterDate = DateFormatter()
                let formatterTime = DateFormatter()
                formatterDate.dateFormat = "dd/MM/yy"
                formatterDate.locale = NSLocale(localeIdentifier: "id") as Locale?
                formatterTime.dateFormat = "HH:mm"
                formatterTime.locale = NSLocale(localeIdentifier: "id") as Locale?
                let dataProfile = getDataProfile(message_id: dataMessages[i]["message_id"] as! String)
                // Fix: the raw field was copied, so a link handed over the preview's own details
                // after the "■" - see `ChatMessageText`. What is copied is what the bubble shows.
                let spoken = ChatMessageText.spoken(of: dataMessages[i])
                let line = "*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(spoken)"
                text = text.isEmpty ? line : text + "\n\n" + line
            }
            text = text + "\n\n\nchat " + "Powered by Nexilis".localized()
            DispatchQueue.main.async {
                UIPasteboard.general.string = text
                self.view.makeToast("Text coppied to clipboard".localized(), duration: 3)
            }
            cancelAction()
        } else if deleteSession {
            let dataMessages = self.dataMessages.filter({ $0["isSelected"] as? Bool ?? false == true })
            var countSelected = dataMessages.count
            if countSelected == 0 {
                return
            }
            let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            if let action = self.actionDelete(for: "me", title: "Delete".localized() + " \(countSelected) " + "For Me".localized(), dataMessages: dataMessages) {
                alertController.addAction(action)
            }
            let idMe = User.getMyPin() as String?
            let dataFilterFpin = dataMessages.filter({ $0["l_pin"] as? String == idMe})
            let dataFilterLock = dataMessages.filter({ $0["lock"] as? String == "1" || $0["lock"] as? String == "2" })
            let statusDataRead = dataMessages.filter({ Int($0["status"] as! String)! >= 4})
            if dataFilterFpin.count == 0 && dataFilterLock.count == 0 && statusDataRead.count == 0 {
                if let action = self.actionDelete(for: "everyone", title: "Delete".localized() + " \(countSelected) " + "For Everyone".localized(), dataMessages: dataMessages) {
                    alertController.addAction(action)
                }
            }
            alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            self.present(alertController, animated: true)
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
        if (dataMessages[indexPath.row]["message_text"] as! String).isEmpty {
            ratingButtonTitles = ["Image".localized()]
        }
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section]})
        let copyActions = ratingButtonTitles
            .enumerated()
            .map { index, title in
                return UIAction(
                    title: title,
                    identifier: nil,
                    handler: {(_) in
                        if (dataMessages[indexPath.row]["message_text"] as! String).isEmpty {
                            DispatchQueue.main.async {
                                let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                                let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                                let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                                if let dirPath = paths.first {
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"] as! String)
                                    if FileManager.default.fileExists(atPath: imageURL.path) || FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent) {
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
                                    let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"] as! String)
                                    if FileManager.default.fileExists(atPath: imageURL.path) || FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent ) {
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
                    self.deleteMessage(l_pin: dataMessages[i]["l_pin"] as! String, message_id: dataMessages[i]["message_id"] as! String, scope: "3", type: "1", chat: "")
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[i]["message_id"] as? String})
                    if idx != nil {
                        self.dataMessages.remove(at: idx!)
                        if (idx == self.dataMessages.count - 1) {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                        }
                        for i in 0..<dataDates.count {
                            if self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[i] }).count == 0 {
                                dataDates.remove(at: i)
                            }
                        }
                    }
                } else {
                    self.deleteMessage(l_pin: dataMessages[i]["l_pin"] as! String, message_id: dataMessages[i]["message_id"] as! String, scope: "3", type: "2", chat: "")
                    let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[i]["message_id"] as? String})
                    if idx != nil {
                        self.dataMessages[idx!]["lock"] = "1"
                        self.dataMessages[idx!]["attachment_flag"] = "0"
                        self.dataMessages[idx!]["reff_id"] = ""
                    }
                }
            }
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
    
}

extension ChatGPTBotView: UITableViewDelegate, UITableViewDataSource {
//    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        checkNewMessage(tableView: tableView)
//    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        lastY = scrollView.contentOffset.y
        // A finger on the list outranks the opening placement.
        if scrollView == tableChatView, scrollView.isDragging, pendingInitialScrollToBottom {
            endOpeningPlacement()
        }
        DispatchQueue.main.async { [self] in
            guard !isInitialLoading else { return }
            checkNewMessage(tableView: self.tableChatView)
        }
    }
    
    /// Whether one message can be picked out by a selection session.
    ///
    /// Fix: the rule lived only in `didSelectRowAt`, so nothing else agreed with it - a message
    /// the session could not take was still marked by the menu that opened the session. One
    /// answer now, asked by the row that draws the circle and by the tap that ticks it.
    private func canPickMessage(_ message: [String: Any?]) -> Bool {
        if message["is_loading"] as? Bool ?? false {
            return false
        }
        if deleteSession {
            return true
        }
        return (message["attachment_flag"] as? String ?? "0") == "0"
            && (message["lock"] as? String ?? "") != "1"
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section] })
        if isSelectionSessionActive {
            guard indexPath.row < dataMessages.count,
                  canPickMessage(dataMessages[indexPath.row]) else {
                return
            }
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == dataMessages[indexPath.row]["message_id"] as? String})
            if idx != nil {
                self.dataMessages[idx!]["isSelected"] = !(self.dataMessages[idx!]["isSelected"] as? Bool ?? false)
                self.tableChatView.reloadRowsKeepingPlace(at: [indexPath])
            }
            containerMultpileSelectSession.subviews.forEach({ $0.removeFromSuperview() })
            addSubviewMultipleSession()
            return
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let dateView = UIView()
        containerView.addSubview(dateView)
        dateView.translatesAutoresizingMaskIntoConstraints = false
        var topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor)
        topAnchor = dateView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10.0)
        NSLayoutConstraint.activate([
            topAnchor,
            dateView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10.0),
            dateView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//            dateView.heightAnchor.constraint(equalToConstant: 30),
            dateView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        dateView.backgroundColor = .orangeColor
        dateView.layer.cornerRadius = 15.0
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
        return 50
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idMe = User.getMyPin() as String?
        let dataMessages = dataMessages.filter({$0["chat_date"] as! String == dataDates[indexPath.section]})
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellEditorPersonal", for: indexPath as IndexPath)
        guard indexPath.row < dataMessages.count else {
            emptyBubbleCell(cell)
            return cell
        }
        // Searching tallies its matches as the rows are built - see countMatchesSearch below - so
        // a row handed back rather than built would not be counted. Searching does without this.
        let signature = bubbleSignature(for: dataMessages[indexPath.row], at: indexPath)
        if !isSearching, builtSignature(of: cell) == signature {
            applySelectionChrome(to: cell)
            return cell
        }
        emptyBubbleCell(cell)
        setBuiltSignature(signature, on: cell)

        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        let containerMessage = BubbleView()
        containerMessage.tag = ChatGPTBotView.bubbleTag
        cell.contentView.addSubview(containerMessage)
        containerMessage.translatesAutoresizingMaskIntoConstraints = false
        
        let timeMessage = UILabel()
        cell.contentView.addSubview(timeMessage)
        timeMessage.translatesAutoresizingMaskIntoConstraints = false
        if (dataMessages[indexPath.row]["read_receipts"] as? String) == "8" || ((dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
            timeMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
        } else {
            timeMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
        }
        
        let statusMessage = UIImageView()
        if (dataMessages[indexPath.row]["f_pin"] as? String == idMe) {
            containerMessage.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 60).isActive = true
            if (dataMessages[indexPath.row]["read_receipts"] as? String) == "8" || ((dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
            } else {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
            }
            containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
            containerMessage.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -15).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if (dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "") {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .blueBubbleColor
            }
            containerMessage.layer.cornerRadius = 18
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
            containerMessage.clipsToBounds = true
            (containerMessage as? BubbleView)?.lift()
            
            timeMessage.trailingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: -8).isActive = true
            
        } else {
            if markerCounter != nil && dataMessages[indexPath.row]["message_id"] as? String == markerCounter {
                containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: UnreadMarker.totalTopInset).isActive = true
                UnreadMarker.install(in: cell.contentView, count: markerCount, fontSize: 14 + offset())
                
            } else {
                containerMessage.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5).isActive = true
            }
            // Fix: the bubble was pushed aside for a circle this screen never drew - a session
            // shifted the conversation sideways and gave the reader nothing to tick. The circle
            // is drawn now, and the room it needs arrives with it rather than in a redraw - see
            // bubbleLeadingNormal.
            let bubbleLeading = containerMessage.leadingAnchor.constraint(
                equalTo: cell.contentView.leadingAnchor,
                constant: selectionChromeShown ? ChatGPTBotView.bubbleLeadingInSession : ChatGPTBotView.bubbleLeadingNormal)
            bubbleLeading.isActive = true
            setSelectionShift(bubbleLeading, on: cell)
            if (dataMessages[indexPath.row]["read_receipts"] as? String) == "8" || ((dataMessages[indexPath.row]["credential"] as? String) == "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -40).isActive = true
            } else {
                containerMessage.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -5).isActive = true
            }
            containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -60).isActive = true
            containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
            if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"]as? String == "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String != "1") {
                containerMessage.backgroundColor = .clear
            } else {
                containerMessage.backgroundColor = .whiteBubbleColor
            }
            containerMessage.layer.cornerRadius = 18
            containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            containerMessage.clipsToBounds = true
            (containerMessage as? BubbleView)?.lift()
            
            timeMessage.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
        }
        
        // The circle that says whether this message is picked. Drawn for every row a session can
        // take - see canPickMessage - and centred on the bubble rather than on the row, which also
        // carries the time underneath it.
        if canPickMessage(dataMessages[indexPath.row]) {
            let selectedImage = UIImageView()
            cell.contentView.addSubview(selectedImage)
            selectedImage.tag = ChatGPTBotView.selectionMarkTag
            selectedImage.translatesAutoresizingMaskIntoConstraints = false
            selectedImage.frame.size = CGSize(width: 20, height: 20)
            NSLayoutConstraint.activate([
                selectedImage.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 22.5),
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
            // Built in whichever state the screen is in, so a row that scrolls in during a session
            // is not caught halfway through a fade it never took part in.
            selectedImage.alpha = selectionChromeShown ? 1 : 0
            selectedImage.transform = selectionChromeShown ? .identity : ChatGPTBotView.selectionMarkHidden
        }
        cell.contentView.isUserInteractionEnabled = !isSelectionSessionActive

        let imageStared = UIImageView()
        if dataMessages[indexPath.row]["is_stared"] as? String == "1" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"] as! String == "0") {
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
        
        let messageText = UILabel()
        let textChat = (dataMessages[indexPath.row]["message_text"] as? String) ?? ""
        let isLoading = dataMessages[indexPath.row]["is_loading"] as? Bool ?? false
        if !isLoading {
            messageText.numberOfLines = 0
            messageText.lineBreakMode = .byWordWrapping
            containerMessage.addSubview(messageText)
            messageText.translatesAutoresizingMaskIntoConstraints = false
            let topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: BubbleTextInset.top)
            topMarginText.isActive = true
            messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
            messageText.font = .systemFont(ofSize: 12 + offset())
            messageText.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: BubbleTextInset.side).isActive = true
            messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -BubbleTextInset.bottom).isActive = true
            messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -BubbleTextInset.side).isActive = true
            let textChat = (dataMessages[indexPath.row]["message_text"] as? String) ?? ""
            messageText.attributedText = textChat.richText()
        } else {
            let gifTyping = UIImageView()
            containerMessage.addSubview(gifTyping)
            gifTyping.translatesAutoresizingMaskIntoConstraints = false
            gifTyping.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor).isActive = true
            gifTyping.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor).isActive = true
            gifTyping.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor).isActive = true
            gifTyping.topAnchor.constraint(equalTo: containerMessage.topAnchor).isActive = true
            gifTyping.widthAnchor.constraint(equalToConstant: 60).isActive = true
            gifTyping.heightAnchor.constraint(equalToConstant: 60).isActive = true
            if let urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_typing_chat", withExtension: "gif") {
                gifTyping.sd_setImage(with: urlGif) { (image, error, cacheType, imageURL) in
                    if error == nil {
                        gifTyping.animationImages = image?.images
                        gifTyping.animationDuration = image?.duration ?? 0.0
                        gifTyping.animationRepeatCount = 0
                        gifTyping.startAnimating()
                    }
                }
            } else if let urlGif = Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: "pb_typing_chat", withExtension: "gif") {
                gifTyping.sd_setImage(with: urlGif) { (image, error, cacheType, imageURL) in
                    if error == nil {
                        gifTyping.animationImages = image?.images
                        gifTyping.animationDuration = image?.duration ?? 0.0
                        gifTyping.animationRepeatCount = 0
                        gifTyping.startAnimating()
                    }
                }
            }
        }
        
        if !copySession && !deleteSession && !isLoading {
            let interaction = UIContextMenuInteraction(delegate: self)
            containerMessage.addInteraction(interaction)
            containerMessage.isUserInteractionEnabled = true
        }
        
        if isSearching && textSearch.count > 1 {
            // The link preview after the "■" is never drawn - see the same fix in the two
            // conversation editors and the rule in ChatMessageText.
            messageText.attributedText = ChatMessageText.withoutLinkPreview(textChat).richText(isSearching: true, textSearch: textSearch)
            if textChat.lowercased().contains(textSearch) {
                countMatchesSearch += 1
            }
        }
        
        let stringDate = (dataMessages[indexPath.row]["server_date"] as? String) ?? ""
        if !stringDate.isEmpty {
            let date = Date(milliseconds: Int64(stringDate) ?? 100)
            timeMessage.text = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
            timeMessage.textColor = .lightGray
            timeMessage.font = UIFont.systemFont(ofSize: 10 + offset(), weight: .medium)
        }
        return cell
    }
    
    @objc func tapAck(_ sender: ObjectGesture) {
        let indexPath = sender.indexPath
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section]})
        if dataMessages[indexPath.row]["status"] as! String == "8" {
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
            let result = Nexilis.write(message: CoreMessage_TMessageBank.getAckLocationMessage(f_pin: dataMessages[indexPath.row]["f_pin"] as! String, message_id: dataMessages[indexPath.row]["message_id"] as! String, l_pin: dataMessages[indexPath.row]["l_pin"] as! String, server_date: "\(Date().currentTimeMillis())", message_scope_id: dataMessages[indexPath.row]["message_scope_id"] as! String, longitude: "", latitude: "", description: ""))
            if result != nil {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                            "status" : "8"
                        ], _where: "message_id = '\(dataMessages[indexPath.row]["message_id"] as! String)'")
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
                DispatchQueue.main.async {
                    if let index = self.dataMessages.firstIndex(where: {$0["message_id"] as? String == dataMessages[indexPath.row]["message_id"] as? String}) {
                        self.dataMessages[index]["status"] = "8"
                        let section = self.dataDates.firstIndex(of: self.dataMessages[index]["chat_date"] as! String)
                        let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as! String == self.dataMessages[index]["message_id"] as! String})
                        if row != nil && section != nil {
                            self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                        }
                        self.view.makeToast("Confirmation Success.".localized(), duration: 3)
                    }
                }
            }
        }
    }
    
    // MARK: - A bubble arriving
    //
    // The same animation the two chat editors play, brought over so the bot's conversation does
    // not behave differently from every other one: the bubble grows out of the corner it belongs
    // to over 0.18s while the list moves up to meet it, and the row it is in is held still for as
    // long as that takes so the growing happens in full view rather than off the bottom.

    /// Written down before the row goes in, so the bubble is small the first time it is drawn.
    ///
    /// Whether the conversation moves up to meet it is decided here too, while it still can be: a
    /// message of ours always takes the reader to it, and one from the bot only if the reader was
    /// already at the end. Once the row is in, the list is no longer at its bottom and the
    /// question can no longer be asked.
    func expectBubbleArrival(messageId: String, outgoing: Bool) {
        guard !messageId.isEmpty else {
            return
        }
        pendingBubbleArrival = (messageId, outgoing, nil, outgoing || isAtNewestMessage())
    }

    /// Last chance, once the row is in: willDisplay may have fired before the cell had been
    /// measured and found a bubble with no size to grow from.
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

    /// The bubble goes from nothing to its full size over 0.18s, decelerating, with its top edge
    /// and the edge it belongs to held still - so it unfolds downwards out of the corner it came
    /// from. Ours grows out of its top-right corner, the bot's out of its top-left. It does not
    /// fade: the first frame it can be seen at all is already solid.
    ///
    /// Done with a transform rather than by moving the layer's anchor point: a transform sits on
    /// top of Auto Layout and undoes itself cleanly, where a moved anchor point is put back by
    /// the next layout pass and leaves the bubble somewhere it should not be.
    @discardableResult
    func playBubbleArrival(on cell: UITableViewCell, outgoing: Bool,
                           from progress: CGFloat, over duration: TimeInterval,
                           of messageId: String, pushingList: Bool) -> Bool {
        guard let bubble = cell.contentView.viewWithTag(ChatGPTBotView.bubbleTag) else {
            return false
        }
        // The size this is all worked out from has to be the settled one. willDisplay can run
        // while the row is still being measured, and a height read too early anchors the bubble
        // to the wrong corner.
        UIView.performWithoutAnimation {
            bubble.transform = .identity
            cell.contentView.layoutIfNeeded()
        }
        guard bubble.bounds.width > 0, bubble.bounds.height > 0 else {
            return false
        }
        // It starts from nothing, not from a bubble that is merely small. `progress` is only ever
        // above zero when a rebuild has interrupted the growing and this is picking it back up.
        let smallest: CGFloat = 0.05
        let scale = smallest + (1 - smallest) * max(0, min(1, progress))
        let shrink = (1 - scale) / 2
        // Keeps the corner it grows from where it already is: scaling about the centre pulls that
        // corner inwards, so it is pushed back out by the same amount. Up rather than down, so it
        // is the top edge that stays put and the bubble unfolds downwards.
        let dx = bubble.bounds.width * shrink * (outgoing ? 1 : -1)
        let dy = -bubble.bounds.height * shrink
        let start = CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scale, y: scale)
        UIView.performWithoutAnimation {
            bubble.transform = start
            bubble.alpha = 1
        }
        arrivingBubble = bubble
        arrivingCell = cell
        // With the conversation already at its end, the new row is added below what can be seen
        // and only the list moving up brings it in - so the bubble would do all its growing off
        // the bottom of the screen. The row is held back by exactly as far as the list is about
        // to move and released on the same curve, so the two cancel: on screen the row does not
        // move at all while the conversation slides up behind it.
        //
        // Both on the next turn of the run loop, together: this is called from willDisplay, in
        // the middle of the table laying itself out, and the scroll position is not something to
        // change from inside that.
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

    /// The message a row is drawing, or nil when the table is asking about a row this screen no
    /// longer has.
    func message(at indexPath: IndexPath) -> [String: Any?]? {
        guard indexPath.section >= 0, indexPath.section < dataDates.count else {
            return nil
        }
        let onDate = dataMessages.filter({ $0["chat_date"] as? String == dataDates[indexPath.section] })
        guard indexPath.row >= 0, indexPath.row < onDate.count else {
            return nil
        }
        return onDate[indexPath.row]
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
    func isAtNewestMessage() -> Bool {
        guard let table = tableChatView else {
            return false
        }
        let bottom = table.contentSize.height + table.adjustedContentInset.bottom - table.bounds.height
        return bottom - table.contentOffset.y <= 40
    }

    /// Slides the conversation up to the newest message.
    ///
    /// Not scrollToRow: with rows that size themselves the place it is aiming for is a guess that
    /// UIKit keeps correcting while the animation is already running, which is the bouncing. The
    /// bottom is measured from the content that has actually been laid out, and the offset is set
    /// once - to the same ease and, by default, the same length of time the bubble grows to, so
    /// when the two are started together the conversation moves up as the bubble fills out.
    func slideToNewestMessage(over duration: TimeInterval = ChatGPTBotView.bubbleArrivalDuration) {
        guard let table = tableChatView, table.numberOfSections > 0 else {
            return
        }
        let lowest = -table.adjustedContentInset.top
        let bottom = table.contentSize.height + table.adjustedContentInset.bottom - table.bounds.height
        let target = max(lowest, bottom)
        guard abs(table.contentOffset.y - target) > 0.5 else {
            return
        }
        UIView.animate(withDuration: duration, delay: 0,
                       options: [.curveEaseOut, .beginFromCurrentState],
                       animations: {
            table.contentOffset = CGPoint(x: table.contentOffset.x, y: target)
        }, completion: { _ in
            // contentSize is built from rows measured only as they are needed, so the bottom it
            // names is an estimate; scrollToRow knows where the last row actually is and closes
            // whatever gap is left, silently.
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

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard tableView == tableChatView else {
            return
        }
        // A bubble that has just been sent or has just arrived grows into place as its row comes
        // on screen - see pendingBubbleArrival.
        playPendingBubbleArrivalIfNeeded(for: cell, at: indexPath)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        dataDates.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = dataMessages.filter({ $0["chat_date"] as! String == dataDates[section] }).count
        return count
    }
    
    @objc func contentMessageTapped(_ sender: ObjectGesture) {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        DispatchQueue.main.async {
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as? String == sender.message_id})
            if idx == nil {
                return
            }
            let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
            if section == nil {
                return
            }
            let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as? String == self.dataMessages[idx!]["message_id"] as? String})
            if row == nil {
                return
            }
            let indexPath = IndexPath(row: row!, section: section!)
            self.tableChatView.scrollToRow(at: indexPath, at: .middle, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // One highlight, the same everywhere - see BubbleHighlight for what it is and why.
                if let cell = self.tableChatView.cellForRow(at: indexPath) {
                    BubbleHighlight.flash(in: cell, tag: ChatGPTBotView.bubbleTag)
                }
            }
        }
        
    }
    
    func getWordRange(at point: CGPoint, in label: UILabel) -> Range<String.Index>? {
        guard let text = label.text else { return nil }
        
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText ?? NSAttributedString())
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.size = label.bounds.size
        
        let characterIndex = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if characterIndex == text.count - 1 {
            return nil
        }
        var wordStartIndex = characterIndex
        while wordStartIndex > 0 && text[text.index(text.startIndex, offsetBy: wordStartIndex - 1)] != " " && text[text.index(text.startIndex, offsetBy: wordStartIndex - 1)] != "\n" {
            wordStartIndex -= 1
        }
        
        var wordEndIndex = characterIndex
        while wordEndIndex < text.count && text[text.index(text.startIndex, offsetBy: wordEndIndex)] != " " && text[text.index(text.startIndex, offsetBy: wordEndIndex)] != "\n" {
            wordEndIndex += 1
        }
        
        return text.index(text.startIndex, offsetBy: wordStartIndex)..<text.index(text.startIndex, offsetBy: wordEndIndex)
    }

    func highlightedText(for text: String, in range: Range<String.Index>, label: UILabel) -> NSAttributedString {
        let mutableAttributedString = label.attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.addAttribute(.backgroundColor, value: UIColor.lightGray.withAlphaComponent(0.5), range: NSRange(range, in: text))
        label.isHighlighted = true
        return mutableAttributedString
    }
    
    func removeHighlightedText(for text: String, in range: Range<String.Index>, label: UILabel) -> NSAttributedString {
        let mutableAttributedString = label.attributedText!.mutableCopy() as! NSMutableAttributedString
        mutableAttributedString.removeAttribute(.backgroundColor, range: NSRange(range, in: text))
        label.isHighlighted = false
        return mutableAttributedString
    }
    
    @objc func tapMessageText(_ sender: ObjectGesture) {
        LinkOpener.open(urlString: sender.message_id)
    }
    
//    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        if copySession || forwardSession || deleteSession {
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
//        if copySession || forwardSession || deleteSession {
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
    
    func scrollToFirstSearchMessage(indexScroll: Int = 1) {
        if textSearch.count < 2 {
            return
        }
        var lastIndex = 0
        let messageTextForSearch: [[String: Any?]] = self.dataMessages.reversed()
        for idx in 0..<messageTextForSearch.count {
            if (messageTextForSearch[idx]["message_text"] as! String).lowercased().contains(textSearch) {
                lastIndex += 1
                if lastIndex < indexScroll {
                    continue
                }
                lastScrollIdxSearch = lastIndex
                let section = self.dataDates.firstIndex(of: messageTextForSearch[idx]["chat_date"] as! String)
                if section == nil {
                    return
                }
                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as? String == messageTextForSearch[idx]["message_id"] as? String})
                if row == nil {
                    return
                }
                let indexPath = IndexPath(row: row!, section: section!)
                self.tableChatView.scrollToRow(at: indexPath, at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // One highlight, the same everywhere - see BubbleHighlight for what it is and why.
                    if let cell = self.tableChatView.cellForRow(at: indexPath) {
                        BubbleHighlight.flash(in: cell, tag: ChatGPTBotView.bubbleTag)
                    }
                }
                titleSearchMatches.isHidden = false
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
                break
            }
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

extension ChatGPTBotView: UITextViewDelegate {

    /// Puts the field's scroll on a line boundary, once the layout that follows a change has run.
    ///
    /// Fix: the field's height is a whole number of lines now, but where it was scrolled to was
    /// not. A text view scrolls just far enough to show the caret when a line is added, and "just
    /// enough" is measured off the caret, which is shorter than its line - so the field came to
    /// rest a few points into a line: the top line cut, the margin under the last one gone, and
    /// six lines showing where five fit. Snapped to whole lines, the margins are always the insets.
    fileprivate func snapFieldScroll(_ textView: UITextView) {
        DispatchQueue.main.async {
            let layout = textView.layoutManager
            var range = NSRange()
            let pitch = layout.numberOfGlyphs > 0 ? layout.lineFragmentRect(forGlyphAt: 0, effectiveRange: &range).height : 0
            let farthest = max(0, textView.contentSize.height - textView.bounds.height)
            let now = textView.contentOffset.y
            let snapped = pitch > 0 ? min(max((now / pitch).rounded() * pitch, 0), farthest) : 0
            if abs(snapped - now) > 0.5 {
                textView.contentOffset.y = snapped
            }
        }
    }

    /// How tall the field should be for what is in it: its insets plus its lines, up to five of
    /// them - past five it scrolls, and what shows is then exactly five whole lines with the same
    /// margin above the first as below the last, the way the reference's field behaves.
    ///
    /// Fix: the cap was a number - 95pt, later five times the font's nominal line height - and
    /// the lines are not laid out at that height: the text's own font, its leading, a mention or
    /// a bold run all make a line taller than the nominal, so the cap fell mid-line and the
    /// field, scrolled to either end, showed a cut line and no margin. The lines are read off the
    /// layout itself now, so the height is always a whole number of them.
    fileprivate func fieldHeight(for textView: UITextView) -> CGFloat {
        let insets = textView.textContainerInset
        let layout = textView.layoutManager
        layout.ensureLayout(for: textView.textContainer)
        var lines: [CGRect] = []
        var index = 0
        while index < layout.numberOfGlyphs {
            var range = NSRange()
            lines.append(layout.lineFragmentRect(forGlyphAt: index, effectiveRange: &range))
            index = NSMaxRange(range)
        }
        // The empty line after a trailing newline is a line too.
        if layout.extraLineFragmentRect.height > 0 {
            lines.append(layout.extraLineFragmentRect)
        }
        let shown = lines.prefix(5)
        // One line at least: 18pt of text view on glass, where the margins are the glass's and
        // 18 + 22 is the 40pt capsule; the 40pt the field was drawn with everywhere else.
        let floor: CGFloat = GlassLook.glass(around: textView) != nil ? 18 : 40
        guard let last = shown.last else { return floor }
        return max(floor, ceil(insets.top + last.maxY + insets.bottom))
    }
    public func textViewDidChangeSelection(_ textView: UITextView) {
        let cursorPosition = textView.caretRect(for: self.textFieldSend.selectedTextRange!.start).origin
        let currentLine = Int(cursorPosition.y / self.textFieldSend.font!.lineHeight)
        UIView.animate(withDuration: 0.3) {
            let numberOfLines = textView.textContainer.lineBreakMode == .byWordWrapping ? Int(textView.contentSize.height / textView.font!.lineHeight) - 1 : 1
            // One rule for every size: the field is as tall as its lines, five at most.
            _ = (currentLine, numberOfLines)
            let height = self.fieldHeight(for: self.textFieldSend)
            if self.heightTextFieldSend.constant != height {
                self.heightTextFieldSend.constant = height
            }
            self.snapFieldScroll(self.textFieldSend)
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        if allowTyping {
            allowTyping = false
            sendTyping(l_pin: dataPerson["f_pin"]!!, isTyping: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
                self.allowTyping = true
            })
        }
        if textView.text.contains("*") || textView.text.contains("_") || textView.text.contains("^") || textView.text.contains("~") {
            // See UITextView.applyRichText - it is what keeps this from blinking and jumping
            // to the bottom of the box on every keystroke.
            textView.applyRichText(textView.text.richText(isEditing: true))
        }
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Send message".localized()
            textView.textColor = UIColor.lightGray
        }
    }
    
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) && (UIPasteboard.general.image != nil) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    public override func paste(_ sender: Any?) {
        
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (self.textFieldSend.text.count == 0) {
            return text != "\n"
        }
        return true
    }
}

extension ChatGPTBotView: UISearchBarDelegate {
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        cancelAction()
    }

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        textSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        countMatchesSearch = 0
        titleSearchMatches.isHidden = true
        tableChatView.reloadData()
        guard !textSearch.isEmpty else {
            // Nothing to look for: the highlight goes, the list stays where it is - see the same
            // guard in the two conversation editors.
            return
        }
        scrollToFirstSearchMessage()
    }
}
