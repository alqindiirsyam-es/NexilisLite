//
//  EditorStarMessages.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 22/09/21.
//

import UIKit
import AVKit
import AVFoundation
import QuickLook
import Photos
@_implementationOnly import SwiftLinkPreview
import nuSDKService
@_implementationOnly import NotificationBannerSwift
import SDWebImage
import FMDB

public class EditorStarMessages: UIViewController, UITableViewDataSource, UITableViewDelegate, UIContextMenuInteractionDelegate, QLPreviewControllerDataSource, UITextViewDelegate, AVAudioPlayerDelegate, UIGestureRecognizerDelegate, ChatBubbleContextMenuPresenting {
    @IBOutlet var tableChatView: UITableView!
    var dataMessages: [[String: Any?]] = []
    var dataDates: [String] = []
    /// What the reader has typed into the search field, if anything.
    /// When set, only starred messages of this one conversation are listed.
    ///
    /// The clause is built by the screen that opened this one, from the very rule that
    /// conversation uses to pick its own messages out of MESSAGE - see groupScope and
    /// personalScope - so the two can never disagree about what belongs to it.
    public var conversationWhereClause: String?

    /// What picks one group conversation's messages, matching EditorGroup.messageWhereClause.
    /// A topic is keyed by its own chat_id; the group's Lounge is the messages with no chat_id.
    public static func groupScope(groupId: String, topicChatId: String) -> String {
        if !topicChatId.isEmpty {
            return "chat_id='\(topicChatId)'"
        }
        return "chat_id='' AND l_pin='\(groupId)'"
    }

    /// What picks one personal conversation's messages, matching EditorPersonal.messageWhereClause.
    public static func personalScope(personPin: String) -> String {
        return "(f_pin='\(personPin)' or l_pin='\(personPin)') AND (message_scope_id = '\(MessageScope.WHISPER)' OR message_scope_id = '\(MessageScope.FORM)' OR message_scope_id = '\(MessageScope.CALL)' OR message_scope_id = '\(MessageScope.MISSED_CALL)') AND is_call_center = 0"
    }

    /// How many messages of one conversation answer a condition.
    ///
    /// Lives here beside groupScope and personalScope so the figure a screen prints and the list
    /// that opens when it is tapped are counted by the same rule.
    public static func conversationCount(scope: String, and condition: String) -> Int {
        var total = 0
        Database.shared.database?.inTransaction({ fmdb, _ in
            if let c = Database.shared.getRecords(fmdb: fmdb, query: "SELECT COUNT(*) FROM MESSAGE where (\(scope)) AND \(condition)"), c.next() {
                total = Int(c.int(forColumnIndex: 0))
                c.close()
            }
        })
        return total
    }

    /// Pictures and videos only - the browser also holds links and documents, but the figure
    /// beside it counts what can be looked at.
    public static let mediaCountCondition =
        "((image_id IS NOT NULL AND image_id <> '') OR (video_id IS NOT NULL AND video_id <> '')) AND (lock IS NULL OR lock <> '1')"

    public static let starredCountCondition = "is_stared = 1"

    /// A count as the rows print it, with thousands grouped the way the rest of the app formats,
    /// or nil when there is nothing to count - a row saying 0 is a row saying nothing.
    public static func countLabel(_ value: Int) -> String? {
        guard value > 0 else {
            return nil
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "id")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var starSearchText = ""
    /// True from the moment a bubble's context menu starts appearing until it has finished going
    /// away. Unlike the conversations, a row on this screen is itself a button - it opens the
    /// message where it lives - so the long press that summons the menu and the tap that
    /// navigates are the same touch, and one of them has to stand down.
    private var bubbleMenuVisible = false
    private let starSearchBar = UISearchBar()
    var previewItem = NSURL()
    var fromNotification = false
    var timerCheckLink: Timer?
    var showMenuContext = false
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
    var touchedSubview = UIView()
    var lastTouchPoint: CGPoint = .zero
    
    var downloadList: [String: IndexPath] = [:]
    var transitioningDelegateRef: ZoomTransitioningDelegate?
    
    // Fix: the players, their timers and the row that is playing were all keyed by index path.
    // A row shifts whenever the list is filtered or reloaded, and the keys then point at bubbles
    // they have nothing to do with - audio carrying on under the wrong one, a pause that pauses
    // somebody else. A message does not move. Same keying as EditorPersonal.
    var audioPlayers: [String: AVAudioPlayer] = [:]
    var timers: [String: Timer] = [:]
    var playingAudioId: String?
    /// The controls of each audio bubble on screen, so something happening to the audio - it
    /// finishing, chiefly - can show on the bubble without rebuilding the row underneath whoever
    /// is touching it.
    var audioWaves: [String: AudioWaveformView] = [:]
    var audioSliders: [String: UISlider] = [:]
    var audioPlayButtons: [String: UIButton] = [:]
    var audioTimeLabels: [String: UILabel] = [:]
    /// The picture and the speed button that trade places in the left of the bubble.
    var audioSpeedPills: [String: UIButton] = [:]
    var audioAvatars: [String: UIView] = [:]
    /// The reading speed chosen for each note, which notes are being listened to, and the wait
    /// before the picture comes back once the audio has run out.
    var audioRates: [String: Float] = [:]
    var audioSessions: Set<String> = []
    var audioRestTimers: [String: Timer] = [:]
    var audioAwaitingRest: Set<String> = []
    var timerSearch: Timer?
    
    func offset() -> CGFloat{
        guard let fontSize = Int(SecureUserDefaults.shared.value(forKey: "font_size") ?? "0") else { return 0 }
        return CGFloat(fontSize)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // A recording carried in on the strip belongs to a bubble here again. Asked for now, and
        // once more a moment later: the screen being left tears its players down after this one
        // has already drawn, so the strip may not have been handed anything yet.
        reclaimPlayingAudioIfMine()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.reclaimPlayingAudioIfMine()
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Nothing left playing, and no timer left running, behind a screen that has been left - a
        // repeating timer outlives the screen that made it. Anything still playing goes to the
        // strip rather than being cut off.
        stopAllAudio()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

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
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor.mainColor
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.topItem?.title = ""
        self.title = "Favorite Messages".localized()
        
        let menu = UIMenu(title: "", children: [
            UIAction(title: "Unfavorite all messages".localized(), handler: {(_) in
                DispatchQueue.global().async {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = Database.shared.updateAllRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                                "is_stared" : 0
                            ])
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
                self.dataMessages.removeAll()
                self.tableChatView.reloadData()
            }),
        ])
        
        getData()
        
        let moreIcon = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: menu)
        navigationItem.rightBarButtonItem = moreIcon
        navigationItem.rightBarButtonItem?.tintColor = UIColor.secondaryColor
        
        // A search field across the top, as the reference has it: starred messages pile up, and
        // the list is only useful if the one being looked for can be found in it.
        starSearchBar.placeholder = "Search".localized()
        starSearchBar.delegate = self
        starSearchBar.searchBarStyle = .minimal
        starSearchBar.autocapitalizationType = .none
        // The Cancel button takes its colour from here, and the field sits on the chat wallpaper
        // rather than on a bar, so the system's default tint has nothing to stand out against.
        starSearchBar.tintColor = .mainColor
        // A header view keeps whatever frame it is handed and does not follow the table's width,
        // and in viewDidLoad the table is still at the width the storyboard drew it at. An
        // autoresizing mask settles it once: the header is stretched with the table from then on,
        // and the header never has to be handed to the table a second time.
        starSearchBar.frame = CGRect(x: 0, y: 0, width: tableChatView.bounds.width, height: 56)
        starSearchBar.autoresizingMask = [.flexibleWidth]
        tableChatView.tableHeaderView = starSearchBar

        // A line between rows: without one, two messages from the same person run together.
        // Fix: the table's own separators skipped rows - the last of each day among them, and any
        // row whose bubble shadow washed the hairline out. Each row draws its own now, so every
        // row has one and they all sit in the same place.
        tableChatView.separatorStyle = .none

        tableChatView.rowHeight = UITableView.automaticDimension
        // Must not be 0: a row sizes itself to its contents only while the table has an estimate
        // to start from, and 0 turns that off - every bubble collapses to the default 44pt.
        //
        // Fix: this used to be 72, refined per row by an estimatedHeightForRowAt that answered
        // from heights recorded in willDisplay. Those recordings came from cell.frame.height, and
        // with bubble reuse the cell handed back can still be carrying the height of the row it
        // held before - so rows were remembered taller than they are. The moment such a row
        // scrolls off, the table goes back to the estimate and adds that error into contentSize,
        // which is why the dead space at the end grew as the list was scrolled (138 on opening,
        // 204 after). No per-row estimate at all now, and a flat figure near the real average of
        // these rows, so there is nothing left to drift.
        tableChatView.estimatedRowHeight = 140
        // A plain-style table pads above every section header on its own account, and a header of
        // no height still gets the padding - so each new day began lower than the rows within it.
        if #available(iOS 15.0, *) {
            tableChatView.sectionHeaderTopPadding = 0
        }
        // Fix: these four were set to 0, and 0 on a section height is not zero - UITableView reads
        // it as "no preference" and falls back to the storyboard's 28pt. So the table sized its
        // content for a 28pt header and a 28pt footer on each of the four days, then laid those
        // out at the delegate's near-zero height: 4 x 56 of content that nothing occupies, all of
        // it ending up past the last row. leastNormalMagnitude is the value that actually means
        // zero here, and it is what the delegate returns, so the two now agree.
        tableChatView.estimatedSectionHeaderHeight = .leastNormalMagnitude
        tableChatView.estimatedSectionFooterHeight = .leastNormalMagnitude
        tableChatView.sectionHeaderHeight = .leastNormalMagnitude
        tableChatView.sectionFooterHeight = .leastNormalMagnitude
        tableChatView.register(UITableViewCell.self, forCellReuseIdentifier: "cellEditorStarMessages")
        tableChatView.delegate = self
        tableChatView.dataSource = self
        tableChatView.reloadData()
        
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(onRefreshData(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusChat), object: nil)
        center.addObserver(self, selector: #selector(onRefreshData(notification:)), name: NSNotification.Name(rawValue: "listenerStarMessage"), object: nil)
        // Fix: downloads broadcast their progress now, so a file fetched from another
        // screen (or before this one opened) still redraws its row here when it lands.
        center.addObserver(self, selector: #selector(onDownloadChat(notification:)), name: Download.progressNotification, object: nil)

    }
    
    @objc func onRefreshData(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            getData()
            tableChatView.reloadData()
        }
    }
    
    @objc func didTapExit() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // The floating date pill is gone from this screen. It belongs to a conversation, where it
    // says which day the messages under it were sent; here every row carries its own date at the
    // top right, so the pill only repeated what the rows already said.
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    // Fix: only the header was silenced. A section still carried the storyboard's 28pt footer,
    // and a footer under one day is space above the first row of the next - which is exactly
    // where the gap showed. Nothing is drawn under a day either, so it goes the same way.
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        dataDates.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = dataMessages.filter({ $0["chat_date"] as! String == dataDates[section] }).count
        return count
    }
    
    @objc func profilePersonTapped(_ sender: ObjectGesture) {
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
            }
        }
    }
    
    /// Group names already looked up, by group id. A bubble is drawn many times while the list
    /// scrolls, and this is a query.
    private var groupNames: [String: String] = [:]

    /// The group a starred message came from and the topic within it, as "Group (Topic)".
    ///
    /// Mirrors how EditorGroup works out what conversation it is showing (see getDataGroup), and
    /// for the same reason: a topic is not a group. An id that names a GROUPZ row is the group's
    /// own conversation, which the app calls the Lounge. An id that names none is a topic, and
    /// topics live in DISCUSSION_FORUM keyed by chat_id, carrying both their own title and the
    /// group they belong to.
    private func groupAndTopic(forConversationId id: String) -> String {
        guard !id.isEmpty else {
            return ""
        }
        if let known = groupNames[id] {
            return known
        }
        var groupTitle = ""
        var topicTitle = ""
        Database.shared.database?.inTransaction({ fmdb, _ in
            if let c = Database().getRecords(fmdb: fmdb, query: "SELECT f_name FROM GROUPZ WHERE group_id = '\(id)'"), c.next() {
                groupTitle = c.string(forColumnIndex: 0) ?? ""
                topicTitle = "Lounge".localized()
                c.close()
            } else if let c = Database().getRecords(fmdb: fmdb, query: "SELECT group_id, title FROM DISCUSSION_FORUM WHERE chat_id = '\(id)'"), c.next() {
                let owningGroup = c.string(forColumnIndex: 0) ?? ""
                topicTitle = c.string(forColumnIndex: 1) ?? ""
                c.close()
                if let g = Database().getRecords(fmdb: fmdb, query: "SELECT f_name FROM GROUPZ WHERE group_id = '\(owningGroup)'"), g.next() {
                    groupTitle = g.string(forColumnIndex: 0) ?? ""
                    g.close()
                }
            }
        })
        guard !groupTitle.isEmpty else {
            // Not remembered: an id that names nothing today may simply be one this screen asked
            // about before the group list had been read, and a remembered blank never retries.
            return ""
        }
        let composed = topicTitle.isEmpty ? groupTitle : groupTitle + " (" + topicTitle + ")"
        groupNames[id] = composed
        return composed
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
    
    // MARK: - Bubble reuse

    /// Bumped whenever a file arrives, so a bubble drawn against "not downloaded yet" is not
    /// mistaken for one that is still current.
    private static var transferTick = 0

    private static var bubbleSignatureKey: UInt8 = 0

    /// Everything the drawing of one bubble depends on, in one string.
    ///
    /// The whole message goes in, not a chosen few of its fields. Choosing which fields matter is
    /// exactly how a bubble ends up showing yesterday's state, and a field costs nothing to
    /// include - where the answer is "something changed", the bubble is simply built as before.
    private func bubbleSignature(for message: [String: Any?], at indexPath: IndexPath) -> String {
        let messageId = message["message_id"] as? String ?? ""
        var parts: [String] = ["\(indexPath.section).\(indexPath.row)"]
        for key in message.keys.sorted() {
            parts.append("\(key)=" + (message[key].map { String(describing: $0) } ?? "nil"))
        }
        // ...and the state of the screen around it, which the drawing reads just as much.
        parts.append("search=\(starSearchText)")
        // A long message folded or opened is the same message drawn two ways.
        parts.append("folded=\(LongMessage.isFolded(messageId, text: message["message_text"] as? String ?? ""))")
        parts.append("font=\(offset())")
        // Width decides how wide a picture is drawn and where a bubble ends; appearance decides
        // half the colours. Neither is in the message, and both change under the reader.
        parts.append("width=\(Int(view.frame.size.width))")
        parts.append("appearance=\(traitCollection.userInterfaceStyle.rawValue)")
        parts.append("files=\(EditorStarMessages.transferTick)")
        // What the audio is doing is not in the message either, and reclaiming a recording from
        // the strip asks for the row to be drawn again - which it would not be if this did not
        // change with it.
        parts.append("audio=\(playingAudioId == messageId)|\(audioSessions.contains(messageId))|\(audioRates[messageId] ?? 1)")
        return parts.joined(separator: ";")
    }

    /// What the cell in hand was last built for, or nil when it holds nothing built.
    private func builtSignature(of cell: UITableViewCell) -> String? {
        return objc_getAssociatedObject(cell, &EditorStarMessages.bubbleSignatureKey) as? String
    }

    private func setBuiltSignature(_ signature: String?, on cell: UITableViewCell) {
        objc_setAssociatedObject(cell, &EditorStarMessages.bubbleSignatureKey, signature, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    /// Takes a cell back to empty, ready to be built into. Taking a view out of the hierarchy
    /// already breaks the constraints that cross its edge, and the ones wholly inside it go when
    /// it does, so there is nothing else to undo.
    private func emptyBubbleCell(_ cell: UITableViewCell) {
        setBuiltSignature(nil, on: cell)
        cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let idMe = User.getMyPin() as String?
        let dataMessages = dataMessages.filter({$0["chat_date"]  as? String ?? "" == dataDates[indexPath.section]})
        
        let cellMessage = tableView.dequeueReusableCell(withIdentifier: "cellEditorStarMessages", for: indexPath)
        cellMessage.backgroundColor = .clear
        cellMessage.selectionStyle = .none
        // A bubble used to be emptied and built again from nothing every time this ran - dozens of
        // views and hundreds of constraints - and it runs for every row of every redraw, not only
        // for rows new to the screen. When the cell in hand was built for this message in this
        // state, it is already the answer.
        let signature = bubbleSignature(for: dataMessages[indexPath.row], at: indexPath)
        if builtSignature(of: cellMessage) == signature {
            return cellMessage
        }
        emptyBubbleCell(cellMessage)
        setBuiltSignature(signature, on: cellMessage)

        let rowSeparator = UIView()
        // .separator is a 29%-alpha hairline meant to sit on a plain white table; over the chat
        // wallpaper, and next to a bubble that now casts its own shadow, it read as nothing.
        rowSeparator.backgroundColor = .systemGray2
        cellMessage.contentView.addSubview(rowSeparator)
        rowSeparator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rowSeparator.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 16),
            rowSeparator.trailingAnchor.constraint(equalTo: cellMessage.contentView.trailingAnchor, constant: -16),
            rowSeparator.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor),
            rowSeparator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
        ])

        
        let profileMessage = UIImageView()
        profileMessage.frame.size = CGSize(width: 35, height: 35)
        cellMessage.contentView.addSubview(profileMessage)
        profileMessage.translatesAutoresizingMaskIntoConstraints = false
        let tapGestureRecognizer = ObjectGesture(target: self, action: #selector(profilePersonTapped(_:)))
        tapGestureRecognizer.message_id = dataMessages[indexPath.row]["f_pin"]  as? String ?? ""
        profileMessage.isUserInteractionEnabled = true
        profileMessage.addGestureRecognizer(tapGestureRecognizer)
        
        var containerMessage: UIView = BubbleView()
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
        // The date is placed with the name, at the top of the row.
        
        let messageText = UITextView()
        messageText.isEditable = false
        // Fix: mirrors EditorGroup.swift's isSelectable = false change - see its
        // CHANGELOG entries for the full history.
        messageText.isSelectable = false
        messageText.dataDetectorTypes = [.link]
        messageText.backgroundColor = .clear
        messageText.isScrollEnabled = false
        messageText.textContainerInset = UIEdgeInsets.zero
        messageText.contentInset = UIEdgeInsets.zero
        messageText.textDragInteraction?.isEnabled = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMessageTextTap(_:)))
        messageText.addGestureRecognizer(tapGesture)

        let touchHighlightGesture = LinkTouchHighlightGesture(target: self, action: #selector(handleLinkTouchHighlight(_:)))
        touchHighlightGesture.minimumPressDuration = 0
        touchHighlightGesture.textView = messageText
        touchHighlightGesture.delegate = self
        touchHighlightGesture.cancelsTouchesInView = false
        touchHighlightGesture.delaysTouchesBegan = false
        messageText.addGestureRecognizer(touchHighlightGesture)

        containerMessage.addSubview(messageText)
        messageText.translatesAutoresizingMaskIntoConstraints = false
        // 32 was the room the sender's name took inside the bubble; the name is above the
        // bubble now, so the text starts where a personal chat starts it.
        // The bubble's own top inset, kept in a constant because two decisions further down have
        // to recognise it again: whether the text has been pushed down by something above it, and
        // where the "Forwarded" strip goes. Both used to test against a hardcoded 32, which is
        // what this margin was before the row was redesigned - so both silently stopped matching.
        let baseTopMarginText: CGFloat = 15
        var topMarginText = messageText.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: baseTopMarginText)
        // Parity with EditorPersonal and EditorGroup: at required priority a bubble that also has
        // a quote above the text has no satisfiable layout at all, and Auto Layout resolves that
        // by dropping whichever constraint it likes.
        topMarginText.priority = .defaultHigh
        
        let dataProfile = getDataProfile(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "")
        let isMine = dataMessages[indexPath.row]["f_pin"] as? String == idMe

        // Fix: this row used to be the conversation's own layout - the reader's messages on the
        // right, everybody else's on the left, the name inside the bubble. Starred messages are a
        // list, not a conversation: every row reads the same way, left to right, so they can be
        // scanned. Picture and name across the top with the date at the far end, the bubble under
        // the name, and a chevron saying the row leads back to where the message came from.
        profileMessage.leadingAnchor.constraint(equalTo: cellMessage.contentView.leadingAnchor, constant: 16).isActive = true
        // Matched to the space under the bubble, so a row sits the same distance off the
        // separator above it as off the one below.
        profileMessage.topAnchor.constraint(equalTo: cellMessage.contentView.topAnchor, constant: 10).isActive = true
        profileMessage.widthAnchor.constraint(equalToConstant: 30).isActive = true
        profileMessage.heightAnchor.constraint(equalToConstant: 30).isActive = true
        profileMessage.circle()
        profileMessage.clipsToBounds = true
        profileMessage.backgroundColor = .lightGray
        profileMessage.image = UIImage(systemName: "person")
        profileMessage.tintColor = .white
        profileMessage.contentMode = .scaleAspectFit

        let pictureImage = dataProfile["image_id"]
        if dataMessages[indexPath.row]["f_pin"] as? String == "-999" {
            if !Utils.getIconDock().isEmpty {
                let dataImage = try? Data(contentsOf: URL(string: Utils.getUrlDock()!)!)
                if dataImage != nil {
                    profileMessage.image = UIImage(data: dataImage!)
                }
            } else {
                profileMessage.image = UIImage(named: "pb_button", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            }
            profileMessage.contentMode = .scaleAspectFill
        } else if dataMessages[indexPath.row]["f_pin"] as? String == "-997" {
            if let urlGif = Bundle.resourceBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif")
                ?? Bundle.resourcesMediaBundle(for: Nexilis.self).url(forResource: "pb_gpt_bot", withExtension: "gif") {
                profileMessage.sd_setImage(with: urlGif) { (image, error, cacheType, imageURL) in
                    if error == nil {
                        profileMessage.animationImages = image?.images
                        profileMessage.animationDuration = image?.duration ?? 0.0
                        profileMessage.animationRepeatCount = 0
                        profileMessage.startAnimating()
                    }
                }
            }
        } else if (pictureImage != "" && pictureImage != nil) {
            profileMessage.setImage(name: pictureImage!)
            profileMessage.contentMode = .scaleAspectFill
        }

        // The chevron, and the date, live at the far end of the row.
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        cellMessage.contentView.addSubview(chevron)
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.trailingAnchor.constraint(equalTo: cellMessage.contentView.trailingAnchor, constant: -16).isActive = true
        chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true
        chevron.heightAnchor.constraint(equalToConstant: 18).isActive = true

        // A moving line rather than a label: sender, group and topic together run past what is
        // left of the row once the date has taken its place, and a label answers that by cutting
        // off the end - which is where the group and the topic are.
        let nameSender = MarqueeLabel()
        cellMessage.contentView.addSubview(nameSender)
        nameSender.translatesAutoresizingMaskIntoConstraints = false
        nameSender.leadingAnchor.constraint(equalTo: profileMessage.trailingAnchor, constant: 10).isActive = true
        nameSender.centerYAnchor.constraint(equalTo: profileMessage.centerYAnchor).isActive = true
        nameSender.font = UIFont.systemFont(ofSize: 14 + offset()).bold
        nameSender.textColor = .label
        if isMine {
            nameSender.text = "You".localized()
        } else if dataMessages[indexPath.row]["f_pin"] as? String == "-999" {
            nameSender.text = "Bot"
        } else if dataMessages[indexPath.row]["f_pin"] as? String == "-997" {
            nameSender.text = Utils.getGPTBotName()
        } else {
            nameSender.text = dataProfile["name"]
        }

        // Who sent it is not enough to place a starred message: this list gathers them from every
        // conversation at once, so the same person appears under several groups. The group's own
        // name goes beside theirs, quieter than the name so the name still reads first.
        let scopeOfMessage = dataMessages[indexPath.row]["message_scope_id"] as? String ?? ""
        // WHISPER is the one-to-one chat, which is exactly how didSelectRowAt decides whether a
        // row opens a personal editor or a group one. Anything else is looked up as a group, and
        // a scope that has no GROUPZ row simply comes back empty.
        if scopeOfMessage != MessageScope.WHISPER {
            // Fix: this took chat_id and only fell back to l_pin when chat_id was empty - so a
            // message carrying a chat_id that is not a GROUPZ row (which is what the reader's own
            // messages were doing) found nothing and gave up, with l_pin holding the answer all
            // along. Both are tried now, in that order.
            let chatIdOfMessage = dataMessages[indexPath.row]["chat_id"] as? String ?? ""
            let lPinOfMessage = dataMessages[indexPath.row]["l_pin"] as? String ?? ""
            var groupTitle = groupAndTopic(forConversationId: chatIdOfMessage)
            if groupTitle.isEmpty {
                groupTitle = groupAndTopic(forConversationId: lPinOfMessage)
            }
            if !groupTitle.isEmpty {
                // One run of plain text rather than two styled ones: the group reads in the same
                // size, weight and colour as the name, so there is nothing left for an attributed
                // string to say that the label's own font and colour do not.
                nameSender.text = (nameSender.text ?? "") + " \u{00B7} " + groupTitle
            }
        }

        // The day this message was sent, at the far end of the name's line. This is what the
        // floating orange pill used to say, and saying it on the row itself means the list can be
        // read straight down without a banner interrupting every few messages.
        let dateMessage = UILabel()
        cellMessage.contentView.addSubview(dateMessage)
        dateMessage.translatesAutoresizingMaskIntoConstraints = false
        dateMessage.trailingAnchor.constraint(equalTo: cellMessage.contentView.trailingAnchor, constant: -16).isActive = true
        dateMessage.centerYAnchor.constraint(equalTo: nameSender.centerYAnchor).isActive = true
        dateMessage.font = UIFont.systemFont(ofSize: 12 + offset())
        dateMessage.textColor = .secondaryLabel
        dateMessage.textAlignment = .right
        dateMessage.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateMessage.text = dataMessages[indexPath.row]["chat_date"] as? String ?? ""
        nameSender.trailingAnchor.constraint(lessThanOrEqualTo: dateMessage.leadingAnchor, constant: -8).isActive = true

        // The time and the star stay beside the bubble, and on the same side for every row - the
        // reader's own messages included, which used to put them on the far side because the
        // bubble was over there.
        timeMessage.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
        timeMessage.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor).isActive = true
        timeMessage.textAlignment = .left
        // Fix: this label used to refuse to shrink (required) and to be barred from reaching the
        // chevron (required). Its leading edge is tied to the bubble's trailing edge by an
        // equality, so the only way to obey both was to drag the bubble's trailing edge leftwards
        // - and the text inside the bubble, being a text view at ordinary priority, lost every
        // time. The bubble collapsed to its 46pt minimum and the message wrapped one letter per
        // line. EditorPersonal never showed this because it has no chevron for the label to be
        // pushed away from. The bar is gone - the bubble's own 100pt reserve already leaves the
        // label 64pt of clear room - and the label yields before the message does.
        timeMessage.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        let imageStared = UIImageView(image: UIImage(systemName: "star.fill"))
        imageStared.tintColor = .systemYellow
        imageStared.backgroundColor = .clear
        cellMessage.contentView.addSubview(imageStared)
        imageStared.translatesAutoresizingMaskIntoConstraints = false
        imageStared.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: 8).isActive = true
        imageStared.bottomAnchor.constraint(equalTo: timeMessage.topAnchor, constant: -2).isActive = true
        imageStared.widthAnchor.constraint(equalToConstant: 13).isActive = true
        imageStared.heightAnchor.constraint(equalToConstant: 13).isActive = true

        // The bubble sits under the name, and keeps the conversation's own colours so a starred
        // message still looks like the message it is.
        containerMessage.topAnchor.constraint(equalTo: profileMessage.bottomAnchor, constant: 8).isActive = true
        containerMessage.leadingAnchor.constraint(equalTo: profileMessage.trailingAnchor, constant: 10).isActive = true
        // The room the time, the star and the chevron need is a fixed amount, so it is reserved as
        // one rather than by pointing the bubble at the label beside it: 16 margin + 12 chevron +
        // 8 + 36 of time + 8. It was 100, which held back 20pt nobody was using - the bubble now
        // runs on until it is nearly under the chevron.
        containerMessage.trailingAnchor.constraint(lessThanOrEqualTo: cellMessage.contentView.trailingAnchor, constant: -80).isActive = true
        containerMessage.widthAnchor.constraint(greaterThanOrEqualToConstant: 46).isActive = true
        // Centred on the row, not on the bubble: a long message makes a bubble tall enough that
        // the chevron would drift into the middle of the text.
        chevron.centerYAnchor.constraint(equalTo: cellMessage.contentView.centerYAnchor).isActive = true
        if dataMessages[indexPath.row]["attachment_flag"] as? String == "11" && dataMessages[indexPath.row]["reff_id"] as? String == "" {
            containerMessage.backgroundColor = .clear
        } else {
            containerMessage.backgroundColor = isMine ? .blueBubbleColor : .whiteBubbleColor
        }
        containerMessage.layer.cornerRadius = 10.0
        // Every bubble is on the left here, so they all take the left-hand shape.
        containerMessage.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        containerMessage.clipsToBounds = true
        (containerMessage as? BubbleView)?.lift()
        
        if ((dataMessages[indexPath.row]["read_receipts"] as? String) == "8" ||
            (dataMessages[indexPath.row]["credential"] as? String) == "1" ||
            !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty) &&
            (dataMessages[indexPath.row]["lock"] as? String) != "2" &&
            (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            // 10 of room, plus the 35 the spec-file badge takes below the bubble.
            containerMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -45).isActive = true
        } else {
            containerMessage.bottomAnchor.constraint(equalTo: cellMessage.contentView.bottomAnchor, constant: -10).isActive = true
        }
        
        // Every message on this screen is starred, so a star on each row said nothing.
        if !(dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String ?? "").isEmpty && (dataMessages[indexPath.row]["lock"] as? String) != "2" && (dataMessages[indexPath.row]["lock"] as? String) != "1" {
            let imageSpecFileView = UIImageView()
            let imageSpecFile = UIImage(named: "pb_ic_attach_spc", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!.withRenderingMode(.alwaysOriginal)
            imageSpecFileView.image = imageSpecFile
            cellMessage.contentView.addSubview(imageSpecFileView)
            imageSpecFileView.translatesAutoresizingMaskIntoConstraints = false
            imageSpecFileView.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imageSpecFileView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            imageSpecFileView.topAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: 5).isActive = true
            // The reader's own messages used to sit on the right, so this hung off the other edge
            // for them. Every row is on the left now, so there is only one edge to hang from.
            imageSpecFileView.leadingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -30).isActive = true
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
        // Parity with EditorPersonal and EditorGroup: required, this fights whatever else claims
        // the bottom of the bubble - the audio player, a quote's minimum height - and Auto Layout
        // settles the fight by dropping a constraint of its own choosing.
        let bottomConstraint = messageText.bottomAnchor.constraint(equalTo: containerMessage.bottomAnchor, constant: -15)
        bottomConstraint.priority = .defaultHigh
        bottomConstraint.isActive = true
        messageText.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
        
        messageText.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        messageText.font = .systemFont(ofSize: 12 + offset())
        
        var textChat = dataMessages[indexPath.row]["message_text"] as? String ?? ""
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
                if let json = try! JSONSerialization.jsonObject(with: textChat.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    Database.shared.database?.inTransaction({ fmdb, rollback in
                        let title = json["title"]  as? String ?? ""
                        let description = json["description"]  as? String ?? ""
                        let start = json["time"] as! Int64
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
            else if attachmentFlag == "11" {
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
                var imageStickerBundle = UIImage(named: (textChat.component(1, separatedBy: "/")), in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
                if imageStickerBundle == nil {
                    imageStickerBundle = UIImage(named: (textChat.component(1, separatedBy: "/")), in: Bundle.resourcesMediaBundle(for: Nexilis.self), with: nil)
                }
                imageSticker.image = imageStickerBundle //resourcesMediaBundle
                imageSticker.contentMode = .scaleAspectFit
            }
            else {
                applyReadMore(to: messageText, text: textChat, messageId: messageIdChat)
                modifyText(at: indexPath)
            }
        } else {
            applyReadMore(to: messageText, text: textChat, messageId: messageIdChat)
            modifyText(at: indexPath)
        }
        
        func modifyText(at indexPath: IndexPath) {
            guard !textChat.isEmpty else { return }
            guard indexPath.row >= 0, indexPath.row < dataMessages.count else {
                print("⚠️ modifyText: Invalid index \(indexPath.row), total: \(dataMessages.count)")
                return
            }

            // The fold has to survive this: it rebuilds the whole attributed string to add link
            // attributes, so working from the full text here would hand the message its whole
            // self back and throw the "Read more" away.
            var text = LongMessage.visibleText(textChat, messageId: messageIdChat)
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

            if LongMessage.isFolded(messageIdChat, text: textChat) {
                finalAttributed.append(LongMessage.suffix(fontSize: 12 + offset()))
            }
            messageText.attributedText = finalAttributed
            messageText.delegate = self
        }
        
        let interaction = UIContextMenuInteraction(delegate: self)
        containerMessage.addInteraction(interaction)
        containerMessage.isUserInteractionEnabled = true
        
        // Last, once every path that writes into the bubble has had its turn.
        highlightSearchMatches(in: messageText)
        
        let stringDate = (dataMessages[indexPath.row]["server_date"]  as? String ?? "")
        if !stringDate.isEmpty {
            let date = Date(milliseconds: Int64(stringDate) ?? 100)
            timeMessage.text = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
            timeMessage.textColor = .lightGray
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
            // Hidden or not, the label is still laid out, and with a long file name behind it it
            // demanded a width the audio row never asked for - which is how the same note came out
            // at two different widths on two screens. It yields instead.
            messageText.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            messageText.setContentHuggingPriority(.defaultLow, for: .horizontal)
            // The sender's name sits above the bubble on this screen, so nothing inside it
            // needs to hold room for a name any more.
            var padTop: CGFloat = 15
            if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int != 0 {
                padTop = 35
            }

            // A voice note and an ordinary audio file are two different things, and the flag they
            // travel under is what tells them apart - a recording is sent as 60.
            let isVoiceNoteAudio = (dataMessages[indexPath.row][TypeDataMessage.attachment_flag] as? String) == "60"
            // Not mirrored by sender the way a conversation mirrors it: every row on this screen
            // reads left to right, so the picture stays on the left for everybody.
            let contAudio = AudioBubbleContent(incoming: false,
                                               isVoiceNote: isVoiceNoteAudio,
                                               bubbleColour: containerMessage.backgroundColor ?? .white,
                                               traits: traitCollection,
                                               fontOffset: offset())
            containerMessage.addSubview(contAudio)
            contAudio.anchor(top: containerMessage.topAnchor, left: containerMessage.leftAnchor, bottom: containerMessage.bottomAnchor, right: containerMessage.rightAnchor, paddingTop: max(padTop, 10), paddingLeft: 10, paddingBottom: 10, paddingRight: 12)
            contAudio.setPicture(named: dataProfile["image_id"] ?? "")

            let avatarBoxAudio = contAudio.avatarBox
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
                    // One player per recording, kept by the service - never opened here. A bubble
                    // that opened its own would be a second player for a recording that may already
                    // be playing somewhere else, which is what let a starred note and a note in a
                    // conversation talk over each other.
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
                    // Taken from the player on every pass, not only the one that opened the file:
                    // a bubble scrolled back to would otherwise show a bare 0:00.
                    if let player = audioPlayer {
                        progressSliderAudio.maximumValue = Float(player.duration)
                        progressSliderAudio.value = Float(player.currentTime)
                        timeLabelAudio.text = formatTime(player.currentTime > 0 ? player.currentTime : player.duration)
                    }
                    // What the player is doing is the only thing that decides which button shows.
                    if let player = audioPlayer, player.isPlaying {
                        playButtonAudio.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                    } else {
                        playButtonAudio.setImage(UIImage(systemName: "play.fill"), for: .normal)
                    }

                    // Held so that audio running out on its own can put the bubble back to rest
                    // where it stands, instead of rebuilding the row under a finger.
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
                            // Asked for on any pass that has no line yet, and answered to whichever
                            // view stands for the message by the time the answer comes.
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
                        // button nor the drawn line is registered.
                        audioWaves[messageIdChat] = nil
                        audioSpeedPills[messageIdChat] = nil
                        audioAvatars[messageIdChat] = nil
                    }

                    // Play/Pause Button Action
                    playButtonAudio.addAction(UIAction { _ in
                        self.playPauseAudio(messageId: messageIdChat, playButton: playButtonAudio, progressSlider: progressSliderAudio, timeLabel: timeLabelAudio)
                    }, for: .touchUpInside)

                    // While the finger is down only the writing moves; the player is sent to the
                    // new place once, when the finger lifts - seeking on every twitch is the lag.
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
        
        if (!thumbChat.isEmpty && dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1" && dataMessages[indexPath.row]["lock"] as? String != "2") {
            // One measurement, not two: the width and the height come from the same look
            // at the file.
            let thumbSize = ListGroupImages.getImageSize(image: thumbChat, screenWidth: self.view.frame.size.width * 0.6, screenHeight: 305)
            let getHeightImage: CGFloat = thumbSize.height
            let getWidthImage: CGFloat = thumbSize.width
            topMarginText.constant = topMarginText.constant + (getHeightImage < 40 ? 45 : getHeightImage + 5)
            
            containerMessage.addSubview(imageThumb)
            imageThumb.translatesAutoresizingMaskIntoConstraints = false
            imageThumb.frame = CGRect(x: 0, y: 0, width: getWidthImage, height: getHeightImage)
            let data = queryMessageReply(message_id: reffChat)
            if (reffChat.isEmpty || data.count == 0) && (dataMessages[indexPath.row][TypeDataMessage.is_forwarded] == nil || dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int == 0) {
                imageThumb.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
            }
            imageThumb.leadingAnchor.constraint(equalTo: containerMessage.leadingAnchor, constant: 15).isActive = true
            imageThumb.bottomAnchor.constraint(equalTo: messageText.topAnchor, constant: -5).isActive = true
            imageThumb.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            // The picture asks for its own width, but never past what the bubble is allowed to be:
            // required, the ask alone contradicts the bubble's maximum width and there is no
            // layout that satisfies both.
            let imgWidthConstraint = imageThumb.widthAnchor.constraint(equalToConstant: getWidthImage)
            imgWidthConstraint.priority = .defaultHigh
            imgWidthConstraint.isActive = true
            let imgMaxWidthConstraint = imageThumb.widthAnchor.constraint(lessThanOrEqualTo: containerMessage.widthAnchor, constant: -30)
            imgMaxWidthConstraint.priority = .required
            imgMaxWidthConstraint.isActive = true
            imageThumb.layer.cornerRadius = 5.0
            imageThumb.clipsToBounds = true
            imageThumb.contentMode = .scaleAspectFill
            // An image view carries the size of the picture inside it, and this one is held
            // between the top of the bubble and the text below rather than by a height of its
            // own. Without this, an arriving thumbnail's own size pushes the bubble open.
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
                    if !imageChat.isEmpty, !Download.isDownloading(forKey: imageChat) {
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
            
            // Progress read back from the database starts at 0, so "not 100" marked every picture
            // this phone had ever sent as still uploading. The message's own status settles it:
            // still being sent (1) means a transfer really is running. The force cast went with
            // it - a row without a progress column used to be a crash.
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
            }
            
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
            if (reffChat.isEmpty || data.count == 0) && (dataMessages[indexPath.row][TypeDataMessage.is_forwarded] == nil || dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int == 0) {
                containerViewFile.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: 15).isActive = true
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
            
            let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
            let sfs = (dataMessages[indexPath.row][TypeDataMessage.spec_file] as? String) ?? ""
            containerViewFile.addGestureRecognizer(objectTap)
            objectTap.containerFile = containerViewFile
            objectTap.labelFile = nameFile
            objectTap.file_id = fileChat
            objectTap.specFile = sfs
            objectTap.indexPath = indexPath
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
                        
                        if dataMessages[indexPath.row][TypeDataMessage.is_forwarded] != nil && dataMessages[indexPath.row][TypeDataMessage.is_forwarded] as! Int != 0 {
                            showForwardedSign()
                        }
                        
                        let objectTap = ObjectGesture(target: self, action: #selector(tapMessageText(_:)))
                        objectTap.message_id = text
                        containerLinkMessage.addGestureRecognizer(objectTap)
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
                let quoteOverlay: UIColor = isDarkQuote
                    ? .black.withAlphaComponent(0.22)
                    : UIColor(white: 0.784, alpha: 0.22)
                let quotedTextColour: UIColor = isDarkQuote
                    ? .white.withAlphaComponent(0.87)
                    : .black.withAlphaComponent(0.77)

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
                containerReply.backgroundColor = quoteOverlay
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
                } else {
                    if data["f_pin"] as? String != "-999" {
                        let dataProfile = getDataProfile(f_pin: data["f_pin"]  as? String ?? "")
                        titleReply.text = dataProfile["name"]
                    } else {
                        titleReply.text = "Bot"
                    }
                }
                // The name and the bar take the colour of whoever is being quoted, the way
                // WhatsApp gives everyone in a group one of their own. White only worked here
                // while the quote sat on a black overlay; on the bubble's own colour it went.
                // Starred messages come from every conversation at once, so the conversation a
                // quote belongs to has to be read off the message. l_pin is the group for a group
                // message; in a one-to-one chat it is whoever received it, so the other party is
                // the sender when that was not me.
                let quoteScope = dataMessages[indexPath.row]["message_scope_id"] as? String ?? ""
                let quoteLPin = dataMessages[indexPath.row]["l_pin"] as? String ?? ""
                let quoteFPin = dataMessages[indexPath.row]["f_pin"] as? String ?? ""
                let conversationOfQuote = quoteScope == MessageScope.GROUP
                    ? quoteLPin
                    : (quoteFPin == idMe ? quoteLPin : quoteFPin)
                let quoteGround = UIColor.composite(quoteOverlay, over: containerMessage.backgroundColor ?? .white)
                let quoteAccent = UIColor.participant(pin: data["f_pin"] as? String ?? "", conversation: conversationOfQuote,
                                                      members: quoteScope == MessageScope.GROUP ? [] : [conversationOfQuote],
                                                      on: quoteGround)
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
                contentReply.font = UIFont.systemFont(ofSize: 11 + offset())
                let message_text = data["message_text"] as? String ?? ""
                let attachment_flag = data["attachment_flag"] as? String  ?? ""
                let thumb_chat = data["thumb_id"] as? String ?? ""
                let image_chat = data["image_id"] as? String ?? ""
                let video_chat = data["video_id"] as? String ?? ""
                let file_chat = data["file_id"] as? String ?? ""
                if (attachment_flag == "0" && thumb_chat == "") {
                    contentReply.trailingAnchor.constraint(equalTo: containerReply.trailingAnchor, constant: -20).isActive = true
                    contentReply.attributedText = message_text.richText(fontSize: 11 + offset())
                } else if (attachment_flag == "1" || image_chat != "") {
                    if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                        contentReply.text = "📷 Photo".localized()
                    } else {
                        contentReply.attributedText = message_text.richText(fontSize: 11 + offset())
                    }
                } else if (attachment_flag == "2" || video_chat != "") {
                    if (message_text.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                        contentReply.text = "📹 Video".localized()
                    } else {
                        contentReply.attributedText = message_text.richText(fontSize: 11 + offset())
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
// WhatsApp writes the quote in the foreground colour held back a little, not in a
                // colour of its own: #303237 on that #D3E1F2 quote is black at 77%. Its dark
                // theme does the same the other way round, white at 60%.
                contentReply.textColor = quotedTextColour
                
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
                
                let objectTap = ObjectGesture(target: self, action: #selector(contentMessageTapped(_:)))
                containerReply.addGestureRecognizer(objectTap)
                objectTap.indexPath = indexPath
                objectTap.message_id = data["message_id"]  as? String ?? ""
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
            containerForwarded.topAnchor.constraint(equalTo: containerMessage.topAnchor, constant: baseTopMarginText).isActive = true
            containerForwarded.trailingAnchor.constraint(equalTo: containerMessage.trailingAnchor, constant: -15).isActive = true
            containerForwarded.heightAnchor.constraint(equalToConstant: 20).isActive = true
            if thumbChat != "" && (dataMessages[indexPath.row]["lock"] == nil || dataMessages[indexPath.row]["lock"]  as? String ?? "" != "1") {
                containerForwarded.bottomAnchor.constraint(equalTo: imageThumb.topAnchor, constant: -5).isActive = true
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
            audioPlayer.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            timers[messageId]?.invalidate()
            timers[messageId] = nil
            playingAudioId = nil
        } else {
            // One recording at a time, everywhere - including one still running in a conversation
            // that was left, which this screen cannot see. The service knows about every one of
            // them and stops the rest.
            for stopped in AudioMiniPlayer.shared.pauseAllExcept(messageId) {
                timers[stopped]?.invalidate()
                timers[stopped] = nil
                if playingAudioId == stopped {
                    playingAudioId = nil
                }
                endAudioSession(stopped)
                if let at = indexPath(forMessageId: stopped) {
                    tableChatView.reloadRows(at: [at], with: .none)
                }
            }

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {

            }

            audioPlayer.enableRate = true
            audioPlayer.rate = audioRates[messageId] ?? 1
            audioPlayer.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            playingAudioId = messageId
            beginAudioSession(messageId)
            startAudioTicker(messageId: messageId, progressSlider: progressSlider, timeLabel: timeLabel)
        }
    }

    /// Keeps a bubble's line, head and reading moving while its recording plays.
    func startAudioTicker(messageId: String,
                          progressSlider: UISlider,
                          timeLabel: UILabel,
                          wave: AudioWaveformView? = nil) {
        timers[messageId]?.invalidate()
        timers[messageId] = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self, weak progressSlider, weak timeLabel, weak wave] _ in
            guard let self = self, let audioPlayer = self.livePlayer(for: messageId) else {
                return
            }
            // Where it has got to is kept as it goes, so leaving at any moment leaves the bubble
            // knowing where it was.
            AudioPositionStore.remember(audioPlayer.currentTime, for: messageId)
            // While the thumb is being held, it is theirs - writing to it from here makes the
            // finger and the timer pull against each other.
            guard progressSlider?.isTracking != true else {
                return
            }
            // The bubble these belong to may have scrolled away and had its cell handed to another
            // message by now.
            guard self.audioViewsAlive(messageId) else {
                return
            }
            progressSlider?.value = Float(audioPlayer.currentTime)
            timeLabel?.text = self.formatTime(audioPlayer.currentTime)
            if audioPlayer.duration > 0 {
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

    /// Where a message sits in the table, or nil when it is not in the list - which it may not be,
    /// since a search narrows what the list holds.
    private func indexPath(forMessageId messageId: String) -> IndexPath? {
        guard let message = dataMessages.first(where: { $0["message_id"] as? String == messageId }),
              let section = dataDates.firstIndex(of: message["chat_date"] as? String ?? ""),
              let row = dataMessages
                  .filter({ ($0["chat_date"] as? String ?? "") == dataDates[section] })
                  .firstIndex(where: { $0["message_id"] as? String == messageId }) else {
            return nil
        }
        return IndexPath(row: row, section: section)
    }

    /// The views held for a message are only good while its bubble is on screen: the cell is handed
    /// to a different message the moment it scrolls away, and writing through a stale handle draws
    /// one note's progress onto another note's bubble.
    func audioViewsAlive(_ messageId: String) -> Bool {
        guard let at = indexPath(forMessageId: messageId) else {
            return false
        }
        return tableChatView.indexPathsForVisibleRows?.contains(at) == true
    }

    func audioRateLabel(_ rate: Float) -> String {
        return rate == rate.rounded() ? "\(Int(rate))\u{00D7}" : "\(rate)\u{00D7}"
    }

    /// While a note is being listened to, the sender's picture gives way to the speed button.
    func beginAudioSession(_ messageId: String) {
        audioRestTimers[messageId]?.invalidate()
        audioRestTimers[messageId] = nil
        audioAwaitingRest.remove(messageId)
        audioSessions.insert(messageId)
        showAudioSpeed(true, for: messageId)
    }

    /// The picture comes back, after a pause when one is asked for.
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

    /// Gives a recording that is still playing to the strip at the top of the screen, so leaving
    /// this list carries on listening instead of cutting it off.
    @discardableResult
    func handOverPlayingAudio() -> String? {
        guard let id = playingAudioId,
              let player = audioPlayers[id],
              player.isPlaying else {
            return nil
        }
        let message = dataMessages.first { ($0["message_id"] as? String) == id }
        let isVoiceNote = (message?["attachment_flag"] as? String) == "60"
        let pin = (message?["f_pin"] as? String) ?? ""
        // Every sender is a different person on this screen, so the name comes from the message
        // rather than from one profile the whole screen belongs to.
        let name = pin == User.getMyPin() ? "You".localized() : (getDataProfile(f_pin: pin)["name"] ?? "")
        let avatar = audioAvatars[id]?.subviews.compactMap { $0 as? UIImageView }.first?.image
        AudioMiniPlayer.shared.takeOver(player: player,
                                        messageId: id,
                                        name: name,
                                        avatar: isVoiceNote ? avatar : nil,
                                        isVoiceNote: isVoiceNote)
        return id
    }

    /// Takes back a recording that is still playing on the strip, now that this list is on screen.
    ///
    /// The bubble asks for it too as it is built, but that can be too early: UIKit builds the
    /// screen being opened before it tears down the screen being left.
    func reclaimPlayingAudioIfMine() {
        guard let id = AudioMiniPlayer.shared.currentMessageId,
              let at = indexPath(forMessageId: id),
              adoptFromMiniPlayerIfNeeded(id) != nil else {
            return
        }
        tableChatView.reloadRows(at: [at], with: .none)
    }

    /// The player behind a recording, wherever it currently lives. One place keeps the players, so
    /// there is only ever one answer here.
    func livePlayer(for messageId: String) -> AVAudioPlayer? {
        return AudioMiniPlayer.shared.player(for: messageId)
    }

    /// Takes ownership of a recording still held by the strip, so this screen drives it from now
    /// on. Does nothing when the recording is already this screen's.
    @discardableResult
    func adoptFromMiniPlayerIfNeeded(_ messageId: String) -> AVAudioPlayer? {
        guard let player = AudioMiniPlayer.shared.reclaim(messageId: messageId) else {
            return audioPlayers[messageId]
        }
        // The idle stand-in built while the strip still had the recording is thrown away; the one
        // that is actually playing takes its place.
        if let standIn = audioPlayers[messageId], standIn !== player {
            standIn.stop()
        }
        player.delegate = self
        audioPlayers[messageId] = player
        playingAudioId = messageId
        beginAudioSession(messageId)
        return player
    }

    /// Everything this screen was driving, let go of. Called when the list goes away, so no timer
    /// is left running behind it.
    func stopAllAudio() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
        audioRestTimers.values.forEach { $0.invalidate() }
        audioRestTimers.removeAll()
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

    // MARK: - Long messages

    /// Puts a long message in the bubble folded, with "Read more" after it. The rule itself is in
    /// LongMessage, shared with the conversations and message info.
    private func applyReadMore(to textView: UITextView, text: String, messageId: String) {
        guard LongMessage.isFolded(messageId, text: text) else {
            textView.attributedText = text.richText()
            return
        }
        let body = NSMutableAttributedString(attributedString: LongMessage.folded(text).richText())
        body.append(LongMessage.suffix(fontSize: 12 + offset()))
        textView.attributedText = body
        textView.isUserInteractionEnabled = true
        textView.addGestureRecognizer(ReadMoreTap(messageId: messageId, target: self, action: #selector(readMoreTapped(_:))))
    }

    @objc private func readMoreTapped(_ sender: UITapGestureRecognizer) {
        guard let tap = sender as? ReadMoreTap else {
            return
        }
        LongMessage.expand(tap.messageId)
        // Fix: this took the message's place in the flat list and reloaded that row of section 0.
        // The list is in sections by date, so anything below the first date reloaded the wrong row
        // - or a row that does not exist.
        if let at = indexPath(forMessageId: tap.messageId) {
            tableChatView.reloadRows(at: [at], with: .none)
        } else {
            tableChatView.reloadData()
        }
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
            // Played to the end, so there is no part-way point to come back to.
            AudioPositionStore.forget(finished)
            AudioMiniPlayer.shared.player(for: finished)?.currentTime = 0
            // Fix: this rebuilt the row. Audio reaching its end while the reader still had hold of
            // the slider therefore tore the control out from under their finger. The bubble is put
            // back to rest in place instead, and the player is kept.
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
    
    @objc func tapAck(_ sender: ObjectGesture) {
        let indexPath = sender.indexPath
        let dataMessages = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[indexPath.section]})
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
            let result = Nexilis.write(message: CoreMessage_TMessageBank.getAckLocationMessage(f_pin: dataMessages[indexPath.row]["f_pin"]  as? String ?? "", message_id: dataMessages[indexPath.row]["message_id"]  as? String ?? "", l_pin: dataMessages[indexPath.row]["l_pin"]  as? String ?? "", server_date: "\(Date().currentTimeMillis())", message_scope_id: dataMessages[indexPath.row]["message_scope_id"]  as? String ?? "", longitude: "", latitude: "", description: ""))
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
                        let row = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == self.dataDates[section!]}).firstIndex(where: { $0["message_id"]  as? String ?? "" == self.dataMessages[index]["message_id"]  as? String ?? ""})
                        if row != nil && section != nil {
                            self.tableChatView.reloadRows(at: [IndexPath(row: row!, section: section!)], with: .none)
                        }
                        self.view.makeToast("Confirmation Success.".localized(), duration: 3)
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
    // implementation also used by EditorGroup, EditorStarMessages, ChatGPTBotView,
    // and MessageInfo. See LinkOpener.swift for the full list of bugs fixed
    // (broken custom instagram://twitter://youtube:// deep links that "succeeded"
    // but always landed on the app's home screen instead of the tapped content).
    @objc func tapMessageText(_ sender: ObjectGesture) {
        LinkOpener.open(urlString: sender.message_id)
    }
    
    /// Whether a starred message answers what is being searched for.
    ///
    /// Matches the message itself and who sent it, which is how somebody looks for a starred
    /// message: either they remember a word of it, or they remember who wrote it.
    private func matchesStarSearch(_ row: [String: Any?], fmdb: FMDatabase) -> Bool {
        let query = starSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return true
        }
        let text = (row["message_text"] as? String) ?? ""
        if text.range(of: query, options: .caseInsensitive) != nil {
            return true
        }
        let sender = senderName(forPin: (row["f_pin"] as? String) ?? "", fmdb: fmdb)
        return sender.range(of: query, options: .caseInsensitive) != nil
    }

    /// Paints what is being searched for wherever it shows in a bubble.
    ///
    /// Applied over the finished text rather than woven into the building of it: a message may
    /// have come out of any of several paths - folded behind a "Read more", carrying mentions,
    /// with links already marked - and the highlight has to survive all of them.
    private func highlightSearchMatches(in textView: UITextView) {
        let query = starSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty,
              let existing = textView.attributedText,
              existing.length > 0 else {
            return
        }
        let painted = NSMutableAttributedString(attributedString: existing)
        let haystack = painted.string
        var from = haystack.startIndex
        while from < haystack.endIndex,
              let found = haystack.range(of: query, options: .caseInsensitive, range: from..<haystack.endIndex) {
            // The colour of the writing is pinned too: the bubble's own text is white in the dark
            // theme, and white on yellow cannot be read.
            painted.addAttributes([
                .backgroundColor: UIColor.systemYellow,
                .foregroundColor: UIColor.black
            ], range: NSRange(found, in: haystack))
            from = found.upperBound
        }
        textView.attributedText = painted
    }

    /// Names already looked up while searching, by pin. This runs once per starred message per
    /// keystroke, and it is a query.
    private var searchSenderNames: [String: String] = [:]

    /// Who sent a message, read on a transaction that is already open.
    ///
    /// Fix: this went through getDataProfile, which opens a transaction of its own. Called from
    /// inside getData's transaction, that is a dispatch_sync onto the queue this thread already
    /// holds - which libdispatch treats as a client bug and traps on, so every search crashed.
    /// The handle already in hand is passed down instead.
    private func senderName(forPin pin: String, fmdb: FMDatabase) -> String {
        guard !pin.isEmpty else {
            return ""
        }
        if pin == "-999" {
            return "Bot".localized()
        }
        if let known = searchSenderNames[pin] {
            return known
        }
        var found = ""
        if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || ifnull(last_name, '') from BUDDY where f_pin = '\(pin)'"), c.next() {
            found = (c.string(forColumnIndex: 0) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            c.close()
        }
        searchSenderNames[pin] = found
        return found
    }


    /// Narrows the list to one conversation when this screen was opened from inside one, and to
    /// nothing when it was opened from the menu. The column names are prefixed because the query
    /// this joins onto aliases MESSAGE as m.
    private func starredScopeClause() -> String {
        guard let clause = conversationWhereClause, !clause.isEmpty else {
            return ""
        }
        let qualified = clause
            .replacingOccurrences(of: "chat_id=", with: "m.chat_id=")
            .replacingOccurrences(of: "l_pin=", with: "m.l_pin=")
            .replacingOccurrences(of: "f_pin=", with: "m.f_pin=")
            .replacingOccurrences(of: "message_scope_id =", with: "m.message_scope_id =")
            .replacingOccurrences(of: "is_call_center =", with: "m.is_call_center =")
        return "AND (\(qualified))"
    }

    func getData() {
        if !dataMessages.isEmpty {
            dataMessages.removeAll()
        }
        // The sections are rebuilt from what is read, so yesterday's list of dates cannot be
        // carried into a narrower search.
        dataDates.removeAll()
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                // Fix: MESSAGE_STATUS used to be queried once per starred message inside the
                // loop below. It is a subquery now, taking the newest status row exactly as
                // that loop did (it kept the last one it read). A subquery rather than a join
                // on purpose: a message can have several status rows, and a join would hand
                // back the message once per row.
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: "SELECT m.message_id, m.f_pin, m.l_pin, m.message_scope_id, m.server_date, ifnull((SELECT s.status FROM MESSAGE_STATUS s WHERE s.message_id = m.message_id ORDER BY s._id DESC LIMIT 1), m.status), m.message_text, m.audio_id, m.video_id, m.image_id, m.thumb_id, m.read_receipts, m.chat_id, m.file_id, m.attachment_flag, m.reff_id, m.lock, m.is_stared, m.blog_id, m.attachment_speciality FROM MESSAGE m where m.is_stared=1 \(self.starredScopeClause()) order by m.server_date desc") {
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
                        row[TypeDataMessage.spec_file] = cursorData.string(forColumnIndex: 19)
                        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                        if let dirPath = paths.first {
                            let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["video_id"] as! String)
                            let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(row["file_id"] as! String)
                            if ((row["video_id"] as! String) != "") {
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
                        // Filtered before the date is worked out: a date section is only added
                        // when a message actually lands in it, so a search that matches nothing
                        // from Tuesday must not leave Tuesday standing empty in the list.
                        guard matchesStarSearch(row, fmdb: fmdb) else {
                            continue
                        }
                        row["chat_date"] = chatDate(stringDate: row["server_date"] as! String, messageId: row["message_id"] as! String)
                        dataMessages.append(row)
                    }
                    cursorData.close()
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
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

    /// Worded exactly as the conversations word it - "Today", "Yesterday", then the day's name,
    /// then "Mon, 18 Aug". A starred message opens the conversation it came from, and the two
    /// screens sitting either side of that jump should not name the same day two different ways.
    private func chatDate(stringDate: String, messageId: String) -> String {
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
                let formatter = EditorStarMessages.chatDateFormatter(format: "EEEE", cached: &EditorStarMessages.dayNameFormatter)
                let stringFormat = formatter.string(from: date)
                if !dataDates.contains(stringFormat){
                    dataDates.append(stringFormat)
                }
                return stringFormat
            } else {
                let formatter = EditorStarMessages.chatDateFormatter(format: "EE, dd MMM", cached: &EditorStarMessages.dayDateFormatter)
                let stringFormat = formatter.string(from: date as Date)
                if !dataDates.contains(stringFormat){
                    dataDates.append(stringFormat)
                }
                return stringFormat
            }
        }
    }
    
    @objc func contentMessageTapped(_ sender: ObjectGesture) {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
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
            if Nexilis.checkingAccess(key: "secure_folder_share") || sender.specFile.contains("download") || sender.specFile.contains("share") {
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
            
            let name = "Favorite Messages".localized()
            imageViewer.title = name
            
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
                            self?.tableChatView.reloadData()
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
                if Nexilis.checkingAccess(key: "secure_folder_share") || sender.specFile.contains("download") || sender.specFile.contains("share") {
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
                    vcHandleFile.title = sender.labelFile.text
                    vcHandleFile.addChild(previewController)
                    previewController.dataSource = self
                    previewController.view.frame = CGRect(x: 0, y: 0, width: viewVc.bounds.size.width, height: viewVc.bounds.size.height)
                    previewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    viewVc.addSubview(previewController.view)
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
            DispatchQueue.main.async {
                let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == sender.message_id})
                if idx == nil {
                    return
                }
                let section = self.dataDates.firstIndex(of: self.dataMessages[idx!]["chat_date"] as! String)
                if section == nil {
                    return
                }
                let row = self.dataMessages.filter({ $0["chat_date"] as! String == self.dataDates[section!]}).firstIndex(where: { $0["message_id"] as! String == self.dataMessages[idx!]["message_id"] as! String})
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
                            containerMessage.backgroundColor = .mainColor.withAlphaComponent(0.3)
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
    
    func getDataProfile(f_pin: String) -> [String: String]{
        var data: [String: String] = [:]
        Database.shared.database?.inTransaction({ fmdb, rollback in
            if let c = Database().getRecords(fmdb: fmdb, query: "select first_name || ' ' || last_name, image_id from BUDDY where f_pin = '\(f_pin)'"), c.next() {
                data["name"] = c.string(forColumnIndex: 0)!.trimmingCharacters(in: .whitespacesAndNewlines)
                data["image_id"] = c.string(forColumnIndex: 1)!
                c.close()
            }
            else if f_pin == "-999" {
                data["name"] = "Bot".localized()
                data["image_id"] = "pb_powered"
            }
            else {
                data["name"] = "Unknown".localized()
                data["image_id"] = ""
            }
        })
        return data
    }
    
    private func getDataProfileFromMessageId(message_id: String) -> [String: String]{
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
    
    @objc func onDownloadChat(notification: NSNotification) {
        guard let name = notification.userInfo?["name"] as? String,
              let progress = notification.userInfo?["progress"] as? Double,
              progress >= 0 else {
            return
        }
        if progress >= 100 {
            reloadMessageRow(withFileNamed: name)
            return
        }
        // Moves the ring cellForRow drew, on whatever cell is showing the message now.
        guard let indexPath = indexPathForMessage(withFileNamed: name),
              let cell = tableChatView.cellForRow(at: indexPath) else {
            return
        }
        ChatTransferRing.updateSizeText(forFileNamed: name, in: cell)
        ChatTransferRing.setProgress(progress, in: cell)
    }

    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        bubbleMenuVisible = true
    }

    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        // Lowered only once the menu has finished dismissing: the touch that dismisses it lands
        // on the row underneath, and a row that is still listening would open the conversation.
        if let animator = animator {
            animator.addCompletion { [weak self] in
                self?.bubbleMenuVisible = false
            }
        } else {
            bubbleMenuVisible = false
        }
        // The menu is going away and its UIActions own their handlers anyway - keeping the
        // duplicates here would just be a strong reference back to self that outlives it.
        contextMenuActionHandlers.removeAll()
        if showMenuContext {
            showMenuContext = false
            interaction.view!.removeInteraction(interaction)
        }
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        // Fix: mirrors EditorGroup.swift - suppresses the bubble-wide Unstar menu
        // when the touch is on a link, leaving it to handleLinkTouchHighlight's own
        // timer instead. See EditorGroup.swift's CHANGELOG entries for the full
        // history.
        if LinkHighlighting.linkHit(at: location, in: interaction.view) != nil {
            return nil
        }

        // Fix: these closures capture self strongly (they always have - they're the very
        // same closures that used to go straight into UIAction), so the ones registered
        // by the previous long-press are dropped here rather than piling up on self.
        contextMenuActionHandlers.removeAll()
        let indexPath = self.tableChatView.indexPathForRow(at: interaction.view!.convert(location, to: self.tableChatView))
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath!.section]})
        let star = chatMenuAction(title: "Unstar".localized(), image: UIImage(systemName: "star.slash"), handler: {(_) in
            DispatchQueue.global().async {
                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                    do {
                        _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE", cvalues: [
                            "is_stared" : 0
                        ], _where: "message_id = '\(dataMessages[indexPath!.row]["message_id"] as! String)'")
                    } catch {
                        rollback.pointee = true
                        print("Access database error: \(error.localizedDescription)")
                    }
                })
            }
            let idx = self.dataMessages.firstIndex(where: { $0["message_id"] as! String == dataMessages[indexPath!.row]["message_id"] as! String})
            if idx != nil{
                self.dataMessages[idx!]["is_stared"] = "0"
            }
            self.dataMessages.remove(at: idx!)
            self.tableChatView.deleteRows(at: [indexPath!], with: .fade)
            if self.dataMessages.filter({ $0["chat_date"] as! String == dataMessages[indexPath!.row]["chat_date"] as! String }).count == 0 {
                self.dataDates.remove(at: indexPath!.section)
                self.tableChatView.deleteSections(IndexSet(integer: indexPath!.section), with: .fade)
            }
            self.tableChatView.reloadData()
        })
        let forward = chatMenuAction(title: "Forward".localized(), image: UIImage(systemName: "arrowshape.turn.up.right"), handler: {(_) in
            let navigationController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactChatNav") as! UINavigationController
            Utils.addBackground(view: navigationController.view)
            // A card that slides up over the list rather than a full-screen takeover, the same as
            // the conversations and the media viewer present it.
            navigationController.modalPresentationStyle = .pageSheet
            if let sheet = navigationController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 20
            }
            navigationController.navigationBar.tintColor = .white
            navigationController.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.overrideUserInterfaceStyle = .dark
            navigationController.navigationBar.barStyle = .black
            let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            navigationController.navigationBar.titleTextAttributes = textAttributes
            if let controller = navigationController.viewControllers.first as? ContactChatViewController {
                controller.isChooser = { [weak self] scope, pin in
                    if scope == "3" {
                        let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
                        editorPersonalVC.unique_l_pin = pin
                        editorPersonalVC.dataMessageForward = [dataMessages[indexPath!.row]]
                        self?.navigationController?.replaceAllViewController(with: editorPersonalVC, animated: true)
                    } else {
                        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                        editorGroupVC.unique_l_pin = pin
                        editorGroupVC.dataMessageForward = [dataMessages[indexPath!.row]]
                        self?.navigationController?.replaceAllViewController(with: editorGroupVC, animated: true)
                    }
                }
            }
            self.present(navigationController, animated: true, completion: nil)
        })
        let copy = chatMenuAction(title: "Copy".localized(), image: UIImage(systemName: "doc.on.doc"), handler: {(_) in
            if (dataMessages[indexPath!.row]["attachment_flag"] as! String == "0") {
                DispatchQueue.main.async {
                    var text = ""
                    let stringDate = (dataMessages[indexPath!.row]["server_date"] as! String)
                    let date = Date(milliseconds: Int64(stringDate)!)
                    let formatterDate = DateFormatter()
                    let formatterTime = DateFormatter()
                    formatterDate.dateFormat = "dd/MM/yy"
                    formatterDate.locale = NSLocale(localeIdentifier: "id") as Locale?
                    formatterTime.dateFormat = "HH:mm"
                    formatterTime.locale = NSLocale(localeIdentifier: "id") as Locale?
                    let dataProfile = self.getDataProfileFromMessageId(message_id: dataMessages[indexPath!.row]["message_id"] as! String)
                    if text.isEmpty {
                        text = "*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(dataMessages[indexPath!.row]["message_text"] as! String)"
                    } else {
                        text = text + "\n\n*[\(formatterDate.string(from: date as Date)) \(formatterTime.string(from: date as Date))] \(dataProfile["name"]!):*\n\(dataMessages[indexPath!.row]["message_text"] as! String)"
                    }
                    text = text + "\n\n\nchat " + "Powered by Nexilis".localized()
                    DispatchQueue.main.async {
                        UIPasteboard.general.string = text
                        self.view.makeToast("Text coppied to clipboard".localized(), duration: 3)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
                    let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
                    let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
                    if let dirPath = paths.first {
                        let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath!.row]["image_id"] as! String)
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
                                    let image    = UIImage(data: imageData)
                                    UIPasteboard.general.image = image
                                    self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                }
                            } catch {
                                
                            }
                            
                        }
                    }
                }
            }
        })
        
        var children: [UIMenuElement] = [star, copy]
        if self.dataMessages[indexPath!.row]["f_pin"] as! String == "-999" || !(dataMessages[indexPath!.row]["image_id"] as! String).isEmpty || !(dataMessages[indexPath!.row]["video_id"] as! String).isEmpty || !(dataMessages[indexPath!.row]["file_id"] as! String).isEmpty || dataMessages[indexPath!.row]["attachment_flag"] as! String == "11" {
            children = [star]
        }
        if (Nexilis.checkingAccess(key: "secure_folder_forward") || (dataMessages[indexPath!.row][TypeDataMessage.spec_file] as? String ?? "").contains("forward")) && self.dataMessages[indexPath!.row]["f_pin"] as! String != "-999" && dataMessages[indexPath!.row]["read_receipts"] as? String != "8" {
            children.insert(forward, at: 1)
        }
        
        // Fix: the menu is ours, not UIKit's - see presentBubbleContextMenu(for:elements:).
        if let bubble = interaction.view,
           presentBubbleContextMenu(for: bubble, elements: children) {
            // That path puts up its own overlay and never reports back through this delegate, so
            // the row has to be told to stand down here, and told again when the overlay goes.
            bubbleMenuVisible = true
            let previousDismiss = longBubbleContextMenu?.onDismiss
            longBubbleContextMenu?.onDismiss = { [weak self] in
                previousDismiss?()
                self?.bubbleMenuVisible = false
            }
            return nil
        }
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "", children: children)
        }
    }
    
    private func copyOption(indexPath: IndexPath) -> UIMenu {
        let ratingButtonTitles = ["Text".localized(), "Image".localized()]
        let dataMessages = self.dataMessages.filter({ $0["chat_date"] as! String == dataDates[indexPath.section]})
        let copyActions = ratingButtonTitles
            .enumerated()
            .map { index, title in
                return UIAction(
                    title: title,
                    identifier: nil,
                    handler: {(_) in if (index == 0) {
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
                                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(dataMessages[indexPath.row]["image_id"] as! String)
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
                                            let image    = UIImage(data: imageData)
                                            UIPasteboard.general.image = image
                                            self.view.makeToast("Image coppied to clipboard".localized(), duration: 3)
                                        }
                                    } catch {
                                        
                                    }
                                    
                                }
                            }
                        }
                    }})
            }
        return UIMenu(
            title: "Copy".localized(),
            image: UIImage(systemName: "doc.on.doc.fill"),
            children: copyActions)
    }
    
    @objc private func cancelDocumentPreview(sender: navigationQLPreviewDocument) {
        sender.navigation.dismiss(animated: true, completion: nil)
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
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem as QLPreviewItem
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !bubbleMenuVisible
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // The long press that opened the menu is the same touch that would open the conversation.
        guard !bubbleMenuVisible else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        let dataMessages = self.dataMessages.filter({ $0["chat_date"]  as? String ?? "" == dataDates[indexPath.section]})
        let message = dataMessages[indexPath.row]
        if let attachmentFlag = message["attachment_flag"], let attachmentFlag = attachmentFlag as? String {
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
                let streamingController = QmeraCreateStreamingViewController()
                streamingController.isJoin = true
                if let messageText = message["message_text"],
                   let messageText = messageText as? String,
                   var json = try! JSONSerialization.jsonObject(with: messageText.data(using: String.Encoding.utf8)!, options: []) as? [String: Any] {
                    if json["blog"] == nil {
                        json["blog"] = message["blog_id"] ?? nil
                    }
                    streamingController.data = json
                }
                let streamingNav = CustomNavigationController(rootViewController: streamingController)
                streamingNav.modalPresentationStyle = .custom
                streamingNav.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
                streamingNav.navigationBar.tintColor = .white
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                streamingNav.navigationBar.titleTextAttributes = textAttributes
                streamingNav.navigationBar.isTranslucent = false
                navigationController?.present(streamingNav, animated: true, completion: nil)
            } else if attachmentFlag == "25" {
                if !Nexilis.checkingAccess(key: "vconf_room") {
                    if Nexilis.checkingAccessAlert(key: "vconf_room") != "|" && !Nexilis.checkingAccessAlert(key: "vconf_room").isEmpty {
                        let title = Nexilis.checkingAccessAlert(key: "vconf_room").components(separatedBy: "|")[0]
                        let message = Nexilis.checkingAccessAlert(key: "vconf_room").component(1, separatedBy: "|")
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
            }
        }
        if message[TypeDataMessage.message_scope_id] as? String == "3" {
            var pin = message[TypeDataMessage.l_pin] as? String ?? ""
            if pin == (User.getMyPin() ?? "") {
                pin = message[TypeDataMessage.f_pin] as? String ?? ""
            }
            let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
            editorPersonalVC.hidesBottomBarWhenPushed = true
            editorPersonalVC.unique_l_pin = pin
            editorPersonalVC.referenceMessageId = message[TypeDataMessage.message_id] as? String ?? ""
            // Fix: this used to hand over the date this screen prints on the row, and the editor
            // looks the message up by matching that string against its own section titles. The two
            // screens word their dates differently - this one says "Monday" or "18/08/26", a
            // conversation says "Today" or "Mon, 18 Aug" - so the lookup found nothing and the
            // jump landed wherever it landed. Left empty, the editor works the date out from the
            // message's own server_date in its own wording, which is always right.
            navigationController?.show(editorPersonalVC, sender: nil)
        } else {
            var pin = message[TypeDataMessage.chat_id] as? String ?? ""
            if pin.isEmpty {
                pin = message[TypeDataMessage.l_pin] as? String ?? ""
            }
            let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
            editorGroupVC.hidesBottomBarWhenPushed = true
            editorGroupVC.unique_l_pin = pin
            editorGroupVC.referenceMessageId = message[TypeDataMessage.message_id] as? String ?? ""
            navigationController?.show(editorGroupVC, sender: nil)
        }
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
        // method no longer fires at all - left in place as a defensive fallback only.
        // Real logic: handleMessageTextTap(_:) (taps) and
        // contextMenuInteraction(_:configurationForMenuAtLocation:) + handleLinkTouchHighlight(_:)
        // (long-press).
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

    // MARK: - Link popup/highlight glue (mirrors EditorGroup.swift - see its
    // CHANGELOG entries for the full history of why this code is shaped this way)

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
}

// MARK: - Transfers

extension EditorStarMessages {
    // Fix: a transfer reports back long after it was started, and the index path it was
    // started from is only good at that one moment - a message arriving or being deleted
    // shifts it, and leaving and re-entering the chat rebuilds the table from scratch. So
    // the row is looked up again, by the file the transfer is for, every time it reports.
    func indexPathForMessage(withFileNamed name: String) -> IndexPath? {
        guard !name.isEmpty else {
            return nil
        }
        let fileKeys = ["image_id", "video_id", "file_id", "audio_id", "thumb_id", "gif_id"]
        guard let index = dataMessages.lastIndex(where: { message in
            return fileKeys.contains(where: { (message[$0] as? String ?? "") == name })
        }) else {
            return nil
        }
        guard let section = dataDates.firstIndex(of: dataMessages[index]["chat_date"] as? String ?? "") else {
            return nil
        }
        let messageId = dataMessages[index]["message_id"] as? String
        guard let row = dataMessages
            .filter({ $0["chat_date"] as? String ?? "" == dataDates[section] })
            .firstIndex(where: { $0["message_id"] as? String == messageId }) else {
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
        // The bubble is drawn differently once the file is there, and nothing in the message says
        // so - without this the row would be redrawn into exactly what it already was.
        EditorStarMessages.transferTick += 1
        guard let indexPath = indexPathForMessage(withFileNamed: name),
              indexPath.section < tableChatView.numberOfSections,
              indexPath.row < tableChatView.numberOfRows(inSection: indexPath.section) else {
            return
        }
        tableChatView.reloadRows(at: [indexPath], with: .none)
    }
}


extension EditorStarMessages: UISearchBarDelegate {

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // Kept while a search is still narrowing the list, even though the keyboard has gone -
        // dismissing it by scrolling would otherwise leave a filtered list with no way back.
        let stillFiltering = !(searchBar.text ?? "").isEmpty
        searchBar.setShowsCancelButton(stillFiltering, animated: true)
    }

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        starSearchText = searchText
        getData()
        tableChatView.reloadData()
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        starSearchText = ""
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        getData()
        tableChatView.reloadData()
    }
}
