//
//  ChatTagSearch.swift
//  NexilisLite
//
//  Search by what a message carries - unread, photos, documents, links, videos, GIFs, audio -
//  rather than by the words in it.
//
//  This started life inside SecondTabViewController and is a component so that every screen
//  showing a chat list can offer the same search without a second copy of it. A host places
//  two views: `chipsView` wherever the filters belong, and `resultsView` over its own list.
//  Everything else - which filter is on, running the query, drawing the results and opening
//  what is tapped - belongs to the component.
//

import UIKit
import QuickLook
import AVFoundation
import SDWebImage

public protocol ChatTagSearchDelegate: AnyObject {
    /// A conversation in the results was tapped and the host should open it.
    func chatTagSearch(_ search: ChatTagSearch, didSelect chat: Chat)

    /// The unread filter found these conversations.
    ///
    /// Unlike the attachment filters, this one produces plain conversations - exactly what the
    /// host's own list is already built to draw, avatars and timestamps and unread badges and
    /// all. So they are handed over rather than drawn here, and an empty list means the filter
    /// is off and the host should go back to showing everything.
    func chatTagSearch(_ search: ChatTagSearch, showConversations chats: [Chat])
}

public final class ChatTagSearch: NSObject, UITableViewDataSource, UITableViewDelegate,
                                  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
                                  QLPreviewControllerDataSource, AVAudioPlayerDelegate {

    /// The badges a tile draws over its thumbnail - the download arrow, the play triangle.
    /// They are found by this tag so the progress ring can take their place while a transfer
    /// runs, rather than being drawn on top of them.
    private static let overlayBadgeTag = 748_214

    public static let unreadTag = 10
    public static let photosTag = 11
    public static let documentsTag = 12
    public static let linksTag = 13
    public static let videosTag = 14
    public static let gifsTag = 15
    public static let audiosTag = 16

    /// The row of filter chips. Give it a height of 40 and put it where the host wants it.
    public let chipsView = UIScrollView()
    /// Covers the host's own list while a filter is on, and hides itself when none is.
    public let resultsView = UIView()

    public weak var delegate: ChatTagSearchDelegate?
    /// Used to put a document preview or a media viewer on screen.
    public weak var presenter: UIViewController?
    /// Called after the reader picks a different filter, so the host can react (hiding its
    /// own search results, for one).
    public var onTagChanged: ((Int) -> Void)?

    public private(set) var selectedTag = 0
    /// Whether the component is drawing the results itself, ie whether the host's own list is
    /// covered. The unread filter is handed to the host instead, so it does not count.
    public var isShowingResults: Bool {
        return selectedTag != 0 && selectedTag != ChatTagSearch.unreadTag
    }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var gridView: UICollectionView!
    /// Shown instead of an empty table or grid, because a filter that finds nothing should say
    /// so rather than leave a blank screen.
    private let emptyLabel = UILabel()
    /// Photos, videos and GIFs come as a grid of thumbnails by default, and as a list with
    /// what was said alongside each one when the reader asks for it. The choice sticks for as
    /// long as the screen is open, the way it does elsewhere.
    private var showsCaptions = false
    private let captionToggle = UIButton(type: .system)
    private var captionToggleTopConstraint: NSLayoutConstraint?
    /// How much of the top of the results the host draws over itself. SecondTab keeps its
    /// segmented control there (it is its table's header view), and the results have to start
    /// below it rather than on top of it.
    public var resultsTopInset: CGFloat = 0 {
        didSet {
            guard resultsTopInset != oldValue else {
                return
            }
            captionToggleTopConstraint?.constant = resultsTopInset + ChatTagSearch.captionTogglePadding
            updateResultsVisibility()
        }
    }
    private static let captionToggleHeight: CGFloat = 30
    private static let captionTogglePadding: CGFloat = 8
    // Measured off WhatsApp's own media list, which is what these rows are modelled on: a 72pt
    // thumbnail with 14pt of air above and below it, text top-aligned with the thumbnail, and
    // 16pt margins on both sides.
    private static let captionRowHeight: CGFloat = 100
    private static let captionThumbSize: CGFloat = 72
    private static let captionMargin: CGFloat = 16
    private static let captionTopPadding: CGFloat = 12
    private static let captionSectionHeaderHeight: CGFloat = 50
    /// The month title is a subview of the first row of each month, so the thumbnail cannot be
    /// found by position any more.
    private static let captionThumbTag = 8801
    private var results: [Chat] = [] {
        didSet {
            rebuildSections()
        }
    }
    /// How the rows are laid out: one section per month in the captions list, the way WhatsApp
    /// groups media, and a single section holding everything in every other list.
    private struct ResultSection {
        let title: String
        let range: Range<Int>
    }
    private var sections: [ResultSection] = []
    /// Conversation names are looked up per row and never change while the results are on
    /// screen, so each one is only ever read from the database once.
    private var conversationNames: [String: String] = [:]
    /// What is already known about each link on screen. Same reason as the names above: a row
    /// is built again every time it comes back into view, and this is a database read.
    private var linkAnswers: [String: LinkPreviewStore.Answer] = [:]
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        // Same rule the rest of the screen's dates follow.
        let language: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
        if language == "id" {
            formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
        }
        return formatter
    }()
    private var searchText = ""
    private var chips: [UIView] = []
    private var previewItem: NSURL?
    /// The file a tap is waiting on, and the filter it was tapped under.
    private var pendingOpen: (fileName: String, tag: Int)?
    /// The recording this screen is playing, if any.
    ///
    /// The player itself belongs to AudioMiniPlayer, not here - one player per recording, kept in
    /// one place, so a note started in this list and then opened in its conversation carries on
    /// rather than starting again beside itself. All this screen keeps is which recording it is
    /// showing as playing, and what to keep up to date while it runs.
    private var playingAudioId = ""
    private var audioTicker: Timer?
    /// The rows showing each recording, so the one playing can be kept up to date without being
    /// rebuilt under the reader.
    private var audioRows: [String: AudioBubbleContent] = [:]
    /// What each play button stands for. A button carries nothing of its own, and the row it sits
    /// in is rebuilt as the list scrolls.
    private var audioButtonResults: [UIButton: Chat] = [:]

    public override init() {
        super.init()
        buildChips()
        buildResults()
        // Downloads report through here whoever started them, so a transfer that was already
        // running when these results were drawn keeps its ring moving.
        NotificationCenter.default.addObserver(self, selector: #selector(onDownloadProgress(_:)), name: Download.progressNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Downloads

    /// Whether the file is on the device already, encrypted or not.
    private func isFileOnDevice(_ fileName: String) -> Bool {
        guard !fileName.isEmpty else {
            return false
        }
        if FileEncryption.shared.isSecureExists(filename: fileName) {
            return true
        }
        guard let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return false
        }
        return FileManager.default.fileExists(atPath: URL(fileURLWithPath: dirPath).appendingPathComponent(fileName).path)
    }

    /// Fetches a file that is not here yet, and puts a progress ring on the box that was
    /// tapped.
    ///
    /// Tapping an attachment that still has to be downloaded used to do nothing at all - the
    /// transfer started in the background with no sign of it, so the only thing the reader
    /// could tell was that the app had ignored them.
    @discardableResult
    private func downloadIfMissing(_ fileName: String, showingProgressOn container: UIView?) -> Bool {
        guard !fileName.isEmpty, !isFileOnDevice(fileName) else {
            return false
        }
        // Only ever reached from a tap, so this is what the reader is waiting for: it opens by
        // itself the moment it lands. One at a time - a second tap replaces the first, rather
        // than opening two things at once when both finish.
        pendingOpen = (fileName: fileName, tag: selectedTag)
        if let container = container {
            // The arrow is what the reader just tapped; the ring is its answer, not something
            // to stack on top of it. A failed download reloads the row, which brings the arrow
            // straight back.
            setOverlayBadgesHidden(true, in: container)
            if ChatTransferRing.setProgress(Download.progress(forKey: fileName) ?? 0, in: container) == false {
                ChatTransferRing.add(to: container, fileName: fileName, progress: Download.progress(forKey: fileName) ?? 0)
            }
        }
        if !Download.isDownloading(forKey: fileName) {
            Download().startHTTP(forKey: fileName) { _, _ in }
        }
        return true
    }

    /// Takes the download arrow and the play triangle out of the way while a ring is on the
    /// tile, and puts them back when it goes.
    private func setOverlayBadgesHidden(_ hidden: Bool, in container: UIView) {
        for view in container.subviews {
            if view.tag == ChatTagSearch.overlayBadgeTag {
                view.isHidden = hidden
            }
            setOverlayBadgesHidden(hidden, in: view)
        }
    }

    /// Which result a transfer belongs to, so its ring can be found again. The grid and the
    /// table lay the same results out differently, so this answers with the position in the
    /// results and each view turns that into its own index path.
    private func resultIndex(forFileNamed name: String) -> Int? {
        return results.firstIndex(where: {
            $0.file == name || $0.audio == name || $0.image == name || $0.video == name || $0.gif == name || $0.thumb == name
        })
    }

    @objc private func onDownloadProgress(_ notification: Notification) {
        guard let name = notification.userInfo?["name"] as? String,
              let progress = notification.userInfo?["progress"] as? Double,
              let index = resultIndex(forFileNamed: name) else {
            return
        }
        // Both views lay the results out in the same sections, so one index path serves both.
        let rowPath = tableIndexPath(forResultIndex: index)
        let gridPath = rowPath
        // 0% is the first thing a transfer reports, not the end of one: only a negative
        // (failed) or a full 100 finishes it. Anything in between just moves the ring.
        guard progress < 0 || progress >= 100 else {
            var container: UIView?
            if showsGrid, let gridPath = gridPath {
                container = gridView.cellForItem(at: gridPath)?.contentView
            } else if let rowPath = rowPath {
                container = tableView.cellForRow(at: rowPath)?.contentView
            }
            guard let container = container else {
                return
            }
            ChatTransferRing.setProgress(progress, in: container)
            ChatTransferRing.updateSizeText(forFileNamed: name, in: container)
            return
        }
        // Done, or given up on. Either way the row is drawn again: with the file if it landed,
        // with the download arrow back in place if it did not.
        // Opening it is only right if this screen is still the one on show - a download
        // finishing while the reader is three screens away must not throw a preview at them.
        let isOnScreen = presenter?.view.window != nil
        let opensNow = progress >= 100 && isOnScreen && pendingOpen?.fileName == name && pendingOpen?.tag == selectedTag
        pendingOpen = nil
        if showsGrid {
            guard let gridPath = gridPath,
                  gridPath.section < gridView.numberOfSections,
                  gridPath.item < gridView.numberOfItems(inSection: gridPath.section) else {
                return
            }
            gridView.reloadItems(at: [gridPath])
            if opensNow {
                // The tile has the file now, so the same tap opens it the second time round.
                collectionView(gridView, didSelectItemAt: gridPath)
            }
            return
        }
        guard let rowPath = rowPath,
              rowPath.section < tableView.numberOfSections,
              rowPath.row < tableView.numberOfRows(inSection: rowPath.section) else {
            return
        }
        tableView.reloadRows(at: [rowPath], with: .none)
        if opensNow, index < results.count {
            let chat = results[index]
            if showsMedia {
                // A picture or a video: it is the thumbnail that was waiting on this file, so
                // it is the picture that opens - not the file preview the other lists use.
                openMedia(chat, thumbnailIn: tableView.cellForRow(at: rowPath)?.contentView.viewWithTag(ChatTagSearch.captionThumbTag))
                return
            }
            let tap = ObjectGesture()
            tap.file_id = chat.file
            tap.audio_id = chat.audio
            onContSearch(tap)
        }
    }

    // MARK: - Host API

    /// Re-runs the current filter for `text`. Call it whenever the search text changes.
    public func setSearchText(_ text: String) {
        searchText = text
        reloadResults()
    }

    /// Clears the filter and uncovers the host's list. Call it when search is closed.
    public func reset() {
        selectedTag = 0
        searchText = ""
        results = []
        // Rule one: the filter going takes its sound with it.
        stopOwnAudio()
        pendingOpen = nil
        updateChipSelection()
        updateResultsVisibility()
        reloadBothViews()
        delegate?.chatTagSearch(self, showConversations: [])
        // The host has to hear about this as well: it is what it acts on to hand scrolling
        // back to its own list, among other things. Leaving it out is why the list could not
        // be scrolled again after a filter was cleared.
        onTagChanged?(0)
    }

    /// Always both. A view that is not told its data went away keeps the item count UIKit
    /// cached for it, and asks for a row that is no longer there the next time it lays out or
    /// is scrolled - which is a crash, not an empty screen.
    private func reloadBothViews() {
        tableView.reloadData()
        gridView.reloadData()
    }

    // MARK: - Chips

    /// The height of a chip, and of the row it sits in. The hosts give the scroll view 40pt,
    /// which leaves this a margin either side.
    private static let chipHeight: CGFloat = 30

    private func buildChips() {
        chipsView.showsHorizontalScrollIndicator = false
        // Obvious at a glance that there is more of the row than fits, which on a 4.7" screen
        // there always is.
        chipsView.alwaysBounceHorizontal = true
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        chipsView.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // A little air at each end, so the first and last chip are not shaved flat against
            // the edge of the screen when the row is scrolled to either end.
            row.leadingAnchor.constraint(equalTo: chipsView.leadingAnchor, constant: 2),
            row.trailingAnchor.constraint(equalTo: chipsView.trailingAnchor, constant: -2),
            row.centerYAnchor.constraint(equalTo: chipsView.centerYAnchor),
            row.heightAnchor.constraint(equalToConstant: ChatTagSearch.chipHeight)
        ])

        let definitions: [(String, String, Int)] = [
            ("bubble.right", "Unread", ChatTagSearch.unreadTag),
            ("photo", "Photos", ChatTagSearch.photosTag),
            ("doc", "Documents", ChatTagSearch.documentsTag),
            ("link", "Links", ChatTagSearch.linksTag),
            ("video", "Videos", ChatTagSearch.videosTag),
            ("photo.on.rectangle", "GIFs", ChatTagSearch.gifsTag),
            ("music.note", "Audio", ChatTagSearch.audiosTag)
        ]
        for (icon, title, tag) in definitions {
            let chip = UIView()
            row.addArrangedSubview(chip)
            chip.translatesAutoresizingMaskIntoConstraints = false
            chip.heightAnchor.constraint(equalToConstant: ChatTagSearch.chipHeight).isActive = true
            chip.layer.cornerRadius = ChatTagSearch.chipHeight / 2
            chip.layer.borderColor = UIColor.gray.cgColor
            chip.layer.borderWidth = 0.5
            // The pill is the chip's edge: nothing inside it may be drawn past it.
            chip.layer.masksToBounds = true
            chip.isUserInteractionEnabled = true
            chip.tag = tag
            chip.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(chipTapped(_:))))

            let image = UIImageView()
            // Asked for at the size of the text beside it, and given a box of its own, so every
            // pill in the row is padded the same however wide its own symbol happens to draw.
            image.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .regular))
            image.contentMode = .scaleAspectFit
            chip.addSubview(image)
            image.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.text = title.localized()
            label.font = .systemFont(ofSize: 15)
            // Never expected to be needed - the pill is measured from this - but a tail is
            // better than a letter sliced down the middle if anything ever squeezes it.
            label.lineBreakMode = .byTruncatingTail
            // The pill is measured from the text; the text is never measured from the pill.
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            chip.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false

            // Fix: every pill used to be given a width in points, chosen by eye for the English
            // word inside it - 80 for "Links", 80 for "Audio", 100 for "Videos". Nothing held the
            // text to that width, and nothing else was ever measured, so a longer word simply ran
            // out through the side of its own pill and into the border of the next one: "Tautan"
            // for Links, "Belum dibaca" for Unread, and a couple that were already tight in
            // English. The pill is measured from what is in it now, in whatever language that is.
            NSLayoutConstraint.activate([
                image.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 11),
                image.centerYAnchor.constraint(equalTo: chip.centerYAnchor),
                image.widthAnchor.constraint(equalToConstant: 17),
                image.heightAnchor.constraint(equalToConstant: 17),

                label.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 6),
                label.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -13),
                label.centerYAnchor.constraint(equalTo: chip.centerYAnchor)
            ])

            chips.append(chip)
        }
        updateChipSelection()
    }

    @objc private func chipTapped(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag else {
            return
        }
        // Tapping the filter that is already on turns it off.
        apply(tag: selectedTag == tag ? 0 : tag)
    }

    /// Turns a filter on, or off with nought, leaving whatever is typed alone.
    ///
    /// Apart from a tap on the chips, this is how the host turns one off - a backspace in an
    /// empty search field, which is how a chip in any field gives way. Unlike reset(), the words
    /// the reader typed survive it: turning the filter off is meant to widen the search, not end
    /// it.
    public func apply(tag: Int) {
        guard tag != selectedTag else {
            return
        }
        selectedTag = tag
        // Changing filter is leaving the one that was on, so the same rule applies.
        stopOwnAudio()
        updateChipSelection()
        reloadResults()
        onTagChanged?(selectedTag)
    }

    private func updateChipSelection() {
        for chip in chips {
            let isOn = chip.tag == selectedTag
            chip.backgroundColor = isOn ? .black : (chipsView.traitCollection.userInterfaceStyle == .dark ? .clear : .white)
            chip.layer.borderColor = isOn ? UIColor.black.cgColor : UIColor.gray.cgColor
            for subview in chip.subviews {
                if let label = subview as? UILabel {
                    label.textColor = isOn ? .white : (chipsView.traitCollection.userInterfaceStyle == .dark ? .white : .black)
                } else if let image = subview as? UIImageView {
                    image.tintColor = isOn ? .white : (chipsView.traitCollection.userInterfaceStyle == .dark ? .white : .black)
                }
            }
        }
    }

    // MARK: - Results

    private func buildResults() {
        resultsView.backgroundColor = .clear
        resultsView.isHidden = true

        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .interactive
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "chatTagCell")
        if #available(iOS 15.0, *) {
            // Fix: iOS 15 gives every plain-table section header ~22pt of padding above it by
            // default. That is what opened a gap between the host's segmented control and the
            // pinned month strip - and it pushed the strip down out of line with the "show as
            // grid" toggle centred on it.
            tableView.sectionHeaderTopPadding = 0
        }
        resultsView.addSubview(tableView)
        tableView.anchor(top: resultsView.topAnchor, left: resultsView.leftAnchor, bottom: resultsView.bottomAnchor, right: resultsView.rightAnchor)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        layout.minimumLineSpacing = 1.0
        layout.minimumInteritemSpacing = 1.0
        // The month strip stays put while its media scrolls past it, the same as the list's.
        layout.sectionHeadersPinToVisibleBounds = true
        gridView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        gridView.backgroundColor = .clear
        gridView.keyboardDismissMode = .interactive
        gridView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "gridCell")
        gridView.register(UICollectionReusableView.self,
                          forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                          withReuseIdentifier: "gridHeader")
        gridView.dataSource = self
        gridView.delegate = self
        gridView.isHidden = true
        resultsView.addSubview(gridView)
        gridView.anchor(top: resultsView.topAnchor, left: resultsView.leftAnchor, bottom: resultsView.bottomAnchor, right: resultsView.rightAnchor)

        // Fix: this used to be a full-width bar pinned to the bottom of the results, where
        // both hosts have something of their own drawn over that edge - SecondTab's floating
        // tab bar, and ContactChat's bottom search field - so the toggle was hidden behind
        // them. The top edge of the results is the one area no host covers, so it lives there
        // now, as a compact pill that the results are inset below.
        captionToggle.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        captionToggle.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        captionToggle.layer.cornerRadius = ChatTagSearch.captionToggleHeight / 2
        captionToggle.clipsToBounds = true
        captionToggle.layer.borderWidth = 0.5
        captionToggle.addTarget(self, action: #selector(toggleCaptions), for: .touchUpInside)
        captionToggle.isHidden = true
        resultsView.addSubview(captionToggle)
        captionToggle.translatesAutoresizingMaskIntoConstraints = false
        // Kept as a constraint of its own because the host can have something of its own drawn
        // across the top of the results - SecondTab's segmented control is its table's header
        // view, which this used to land right on top of.
        let toggleTop = captionToggle.topAnchor.constraint(equalTo: resultsView.topAnchor, constant: resultsTopInset + ChatTagSearch.captionTogglePadding)
        captionToggleTopConstraint = toggleTop
        NSLayoutConstraint.activate([
            toggleTop,
            captionToggle.trailingAnchor.constraint(equalTo: resultsView.trailingAnchor, constant: -ChatTagSearch.captionTogglePadding),
            captionToggle.heightAnchor.constraint(equalToConstant: ChatTagSearch.captionToggleHeight)
        ])

        emptyLabel.text = "No Result".localized()
        emptyLabel.font = .systemFont(ofSize: 13 + String.offset())
        emptyLabel.textColor = .gray
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        resultsView.addSubview(emptyLabel)
        emptyLabel.anchor(left: resultsView.leftAnchor, right: resultsView.rightAnchor, paddingLeft: 20, paddingRight: 20, centerX: resultsView.centerXAnchor, centerY: resultsView.centerYAnchor)
    }

    /// Whether this filter is about media at all.
    private var showsMedia: Bool {
        return selectedTag == ChatTagSearch.photosTag || selectedTag == ChatTagSearch.videosTag || selectedTag == ChatTagSearch.gifsTag
    }

    /// Media is shown as a grid of thumbnails unless the reader asked for captions; anything
    /// else is always a list.
    private var showsGrid: Bool {
        return showsMedia && !showsCaptions
    }

    @objc private func toggleCaptions() {
        showsCaptions.toggle()
        // The captions list groups by month and the grid does not, so the sections have to be
        // rebuilt before either view is asked for its rows again.
        rebuildSections()
        updateResultsVisibility()
        reloadBothViews()
    }

    private func reloadResults() {
        // The rows are about to be built again, and what these hold are the ones that were.
        audioRows.removeAll()
        audioButtonResults.removeAll()
        linkAnswers.removeAll()
        switch selectedTag {
        case ChatTagSearch.unreadTag:
            results = Chat.getData(isUnread: true, withText: searchText)
        case ChatTagSearch.photosTag, ChatTagSearch.videosTag, ChatTagSearch.gifsTag:
            results = Chat.getData(isImage: selectedTag == ChatTagSearch.photosTag,
                                   isVideo: selectedTag == ChatTagSearch.videosTag,
                                   isGIF: selectedTag == ChatTagSearch.gifsTag,
                                   withText: searchText)
        case ChatTagSearch.documentsTag:
            results = Chat.getData(isDoc: true, withText: searchText)
        case ChatTagSearch.linksTag:
            results = Chat.getData(isLink: true, withText: searchText)
        case ChatTagSearch.audiosTag:
            results = Chat.getData(isAudio: true, withText: searchText)
        default:
            results = []
        }
        updateResultsVisibility()
        gridView.collectionViewLayout.invalidateLayout()
        reloadBothViews()
        // Unread is the host's to draw; everything else is drawn above.
        delegate?.chatTagSearch(self, showConversations: selectedTag == ChatTagSearch.unreadTag ? results : [])
    }

    /// Keeps `scrollView` resting below the toggle. A scroll view sitting at the very top has
    /// its offset at minus the inset, not at zero, so changing the inset without moving the
    /// offset with it would leave the first row scrolled up underneath the toggle.
    private func setResultsTopInset(_ inset: CGFloat, on scrollView: UIScrollView) {
        guard scrollView.contentInset.top != inset else {
            return
        }
        let wasAtTop = scrollView.contentOffset.y <= -scrollView.contentInset.top + 1
        scrollView.contentInset.top = inset
        scrollView.verticalScrollIndicatorInsets.top = inset
        if wasAtTop {
            scrollView.contentOffset.y = -inset
        }
    }

    // Worked out here rather than stored on the layout: when the results are first filled in
    // the view has not been laid out yet, and a size computed from a width of zero gave the
    // grid nothing it could draw.
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let available = collectionView.bounds.width > 0 ? collectionView.bounds.width : UIScreen.main.bounds.width
        if selectedTag == ChatTagSearch.gifsTag {
            return CGSize(width: available / 2 - 2, height: available / 2 - 62)
        }
        let side = available / 3 - 2
        return CGSize(width: side, height: side)
    }

    private func updateResultsVisibility() {
        resultsView.isHidden = !isShowingResults
        let nothingFound = results.isEmpty
        emptyLabel.isHidden = !nothingFound
        emptyLabel.textColor = resultsView.traitCollection.userInterfaceStyle == .dark ? .lightGray : .gray
        gridView.isHidden = !showsGrid || nothingFound
        tableView.isHidden = showsGrid || nothingFound
        // The toggle belongs to media, and only when there is something to look at.
        captionToggle.isHidden = !showsMedia || nothingFound
        captionToggle.setTitle(showsCaptions ? "Show as grid".localized() : "Show captions".localized(), for: .normal)
        let isDark = resultsView.traitCollection.userInterfaceStyle == .dark
        // The captions list already has a strip across the top - the pinned month title - so
        // the toggle sits on the right of that same line instead of stacking a second bar of
        // its own above it. Nothing to sit on in the grid, so there it keeps its own room and
        // its own fill.
        let sharesMonthHeaderLine = showsMedia && sectionTitle(0) != nil
        captionToggleTopConstraint?.constant = resultsTopInset + (sharesMonthHeaderLine
            ? (ChatTagSearch.captionSectionHeaderHeight - ChatTagSearch.captionToggleHeight) / 2
            : ChatTagSearch.captionTogglePadding)
        // Just enough fill to stay readable over whatever is scrolling past under it - the
        // results themselves are transparent. On the month line the header's own blur is
        // already behind it, so it reads as plain text on that line, the way WhatsApp's does.
        captionToggle.backgroundColor = sharesMonthHeaderLine ? .clear : (isDark ? UIColor.blackDarkMode : UIColor.white).withAlphaComponent(0.9)
        captionToggle.layer.borderWidth = sharesMonthHeaderLine ? 0 : 0.5
        captionToggle.layer.borderColor = (isDark ? UIColor.lightGray : UIColor.gray).withAlphaComponent(0.35).cgColor
        // Room above whichever view is scrolling for whatever the host draws over the top of
        // the results, and for the toggle when it has a line of its own, so the first row - and
        // the month header pinned above it - is not stuck underneath either of them.
        var topRoom = resultsTopInset
        if !captionToggle.isHidden && !sharesMonthHeaderLine {
            topRoom += ChatTagSearch.captionToggleHeight + ChatTagSearch.captionTogglePadding * 2
        }
        setResultsTopInset(topRoom, on: tableView)
        setResultsTopInset(topRoom, on: gridView)
        if !captionToggle.isHidden {
            resultsView.bringSubviewToFront(captionToggle)
        }
        if !resultsView.isHidden {
            // The host may have added this over a list that draws after it.
            resultsView.superview?.bringSubviewToFront(resultsView)
            resultsView.setNeedsLayout()
            resultsView.layoutIfNeeded()
        }
    }

    // MARK: - Sections

    /// Groups the results the way the current list draws them. Everything reads its rows
    /// through this, so the table can never be asked for a row that is not there.
    private func rebuildSections() {
        guard isShowingResults, !results.isEmpty else {
            sections = results.isEmpty ? [] : [ResultSection(title: "", range: 0..<results.count)]
            return
        }
        var built: [ResultSection] = []
        var start = 0
        var currentTitle = monthTitle(for: results[0])
        for index in 1..<results.count {
            let title = monthTitle(for: results[index])
            if title != currentTitle {
                built.append(ResultSection(title: currentTitle, range: start..<index))
                start = index
                currentTitle = title
            }
        }
        built.append(ResultSection(title: currentTitle, range: start..<results.count))
        sections = built
    }

    private func monthTitle(for data: Chat) -> String {
        let date = Date(milliseconds: Int64(data.serverDate) ?? 0)
        return ChatTagSearch.monthFormatter.string(from: date)
    }

    /// The result a row stands for, or nil when the table asks for one that has gone.
    private func result(at indexPath: IndexPath) -> Chat? {
        guard indexPath.section >= 0, indexPath.section < sections.count else {
            return nil
        }
        let range = sections[indexPath.section].range
        let index = range.lowerBound + indexPath.row
        guard indexPath.row >= 0, index < range.upperBound, index < results.count else {
            return nil
        }
        return results[index]
    }

    /// The other direction: where a result sits in the table it is drawn in.
    private func tableIndexPath(forResultIndex index: Int) -> IndexPath? {
        guard let section = sections.firstIndex(where: { $0.range.contains(index) }) else {
            return nil
        }
        return IndexPath(row: index - sections[section].range.lowerBound, section: section)
    }

    // MARK: - Rows

    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section >= 0, section < sections.count else {
            return 0
        }
        return sections[section].range.count
    }

    private func sectionTitle(_ section: Int) -> String? {
        guard section >= 0, section < sections.count, !sections[section].title.isEmpty else {
            return nil
        }
        return sections[section].title
    }

    /// The month title stays pinned at the top while its media scrolls past, so it is a section
    /// header rather than something drawn inside the first row.
    ///
    /// It sits on a blur rather than a solid fill: the results are transparent, and rows sliding
    /// along underneath a fully see-through title is unreadable.
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = sectionTitle(section) else {
            return nil
        }
        let header = UIView()
        buildMonthStrip(in: header, title: title, style: tableView.traitCollection.userInterfaceStyle)
        return header
    }

    /// The month strip itself, shared by the list and the grid so both read the same.
    private func buildMonthStrip(in header: UIView, title: String, style: UIUserInterfaceStyle) {
        // Fix: the month line was laid over an ultra-thin material, which on a plain light ground
        // reads as a flat grey strip rather than as glass - a band of colour across a screen that
        // is otherwise nothing but the results. The line carries no ground of its own now; it is
        // the month written over what is behind it.
        header.backgroundColor = .clear

        let label = UILabel()
        label.text = title
        // Not `.systemFont(weight: .bold)`: the framework swizzles the system font and only
        // boldSystemFont(ofSize:) actually maps to the bold face (see UIFont.libOverrideInitialize).
        label.font = .boldSystemFont(ofSize: 22 + String.offset())
        label.textColor = style == .dark ? .white : .black
        header.addSubview(label)
        // Centred rather than sitting on the bottom edge: the "show as grid" toggle is centred
        // on this same line, and two things centred on one line are what makes them level.
        label.anchor(left: header.leftAnchor, paddingLeft: ChatTagSearch.captionMargin, centerY: header.centerYAnchor)
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sectionTitle(section) == nil ? 0 : ChatTagSearch.captionSectionHeaderHeight
    }

    // The same heights the rows were drawn at before this moved out of the chat list: the
    // layouts below are built to them.
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if selectedTag == ChatTagSearch.unreadTag || selectedTag == 0 {
            return 75
        }
        if showsMedia {
            // Two lines of caption have to fit even when the reader has turned the text size
            // up, so the row grows with it rather than clipping.
            return ChatTagSearch.captionRowHeight + String.offset() * 2
        }
        return selectedTag == ChatTagSearch.linksTag ? 160.0 : 130.0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatTagCell", for: indexPath)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        let content = cell.contentView
        content.subviews.forEach { $0.removeFromSuperview() }
        guard let data = result(at: indexPath) else {
            return cell
        }
        if showsMedia {
            buildMediaCaptionCell(cell: cell, content: content, data: data)
            return cell
        }
                let title = UILabel()
                let subtitle = UILabel()
                title.textColor = .label
                subtitle.textColor = .secondaryLabel
                title.font = .systemFont(ofSize: 16 + String.offset(), weight: .medium)
                subtitle.font = .systemFont(ofSize: 14 + String.offset())
                content.addSubview(title)
                content.addSubview(subtitle)
                title.anchor(top: content.topAnchor, left: content.leftAnchor, paddingTop: 10, paddingLeft: 20)
                subtitle.anchor(top: title.bottomAnchor, left: content.leftAnchor, right: content.rightAnchor, paddingLeft: 20, paddingRight: 20)
                subtitle.numberOfLines = 2
                // Fix: this was data.name, which the query behind these results fills from the
                // *sender* - it joins BUDDY on m.f_pin. So the title of a group result was one
                // member's name and the conversation it belonged to was never said at all. The
                // title is the conversation, the same name the conversation itself carries; who
                // sent it belongs to the line under it.
                title.text = conversationName(for: data)
                subtitle.attributedText = resultSubtitle(for: data)
                
                let imageArrowRight = UIImageView(image: UIImage(systemName: "chevron.right"))
                content.addSubview(imageArrowRight)
                imageArrowRight.tintColor = .gray
                imageArrowRight.anchor(top: content.topAnchor, right: content.rightAnchor, paddingTop: 10, paddingRight: 20)
                
                let timeView = UILabel()
                content.addSubview(timeView)
                timeView.anchor(top: content.topAnchor, right: imageArrowRight.leftAnchor, paddingTop: 10, paddingRight: 20)
                timeView.textColor = .gray
                timeView.font = UIFont.systemFont(ofSize: 16 + String.offset())
                
                let date = Date(milliseconds: Int64(data.serverDate) ?? 0)
                let calendar = Calendar.current
                
                if (calendar.isDateInToday(date)) {
                    timeView.text = DateFormatterPool.shared.string(from: date as Date, format: "HH:mm", localeIdentifier: "id")
                } else {
                    let startOfNow = calendar.startOfDay(for: Date())
                    let startOfTimeStamp = calendar.startOfDay(for: date)
                    let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
                    let day = -(components.day!)
                    if day == 1 {
                        timeView.text = "Yesterday".localized()
                    } else {
                        if day < 7 {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "EEEE"
                            let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
                            if lang == "id" {
                                formatter.locale = NSLocale(localeIdentifier: "id") as Locale?
                            }
                            timeView.text = formatter.string(from: date)
                        } else {
                            let stringFormat = DateFormatterPool.shared.string(from: date as Date, format: "dd/MM/yy", localeIdentifier: "id")
                            timeView.text = stringFormat
                        }
                    }
                }
                
                cell.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
                
                let container = UIView()
                content.addSubview(container)
                // An audio row is taller than the rest: the picture stands 44 points and the
                // length is written under the line, which needs room below it.
                let panelHeight: CGFloat
                switch selectedTag {
                case ChatTagSearch.linksTag: panelHeight = 75
                case ChatTagSearch.audiosTag: panelHeight = 68
                default: panelHeight = 60
                }
                container.anchor(top: subtitle.bottomAnchor, left: content.leftAnchor, right: content.rightAnchor, paddingTop: 5, paddingLeft: 20, paddingRight: 20, height: panelHeight)
                // Fix: light grey at thirty per cent comes out around #E6E6E6 on a white ground -
                // a panel that reads as a slab. Sampled off the reference, the panel there is
                // #F2F1F2 against a #FDFCFC page, which is four and a half per cent darker than
                // what it sits on rather than eleven. Dark mode lifts by the same little amount
                // instead of darkening, there being nothing darker to go to.
                container.backgroundColor = tableView.traitCollection.userInterfaceStyle == .dark
                    ? UIColor.white.withAlphaComponent(0.08)
                    : UIColor.black.withAlphaComponent(0.045)
                container.layer.cornerRadius = 15
                container.clipsToBounds = true
                container.isUserInteractionEnabled = true
                
                if selectedTag == ChatTagSearch.documentsTag {
                    // Fix: a grey page glyph the same for every document, and a size line worked
                    // out by reading the whole file into memory to count its bytes - on the main
                    // thread, once per row that came into view. The bubble already draws a
                    // document properly: a page in the colour of its own kind with the extension
                    // written on it, and a size taken from what the sender said or from the file's
                    // own length without opening it. Both come from there now, so a document looks
                    // the same wherever it is shown.
                    let documentName = Utils.documentName(messageText: data.messageText, file: data.file)
                    // What kind it is: what the name says, and where the name says nothing,
                    // what the file itself says. See Utils.documentKind.
                    let documentKind = Utils.documentKind(named: documentName, file: data.file)
                    let imageFile = UIImageView(image: DocumentBadge.image(
                        of: documentKind,
                        size: CGSize(width: 34, height: 40)))
                    imageFile.contentMode = .scaleAspectFit
                    container.addSubview(imageFile)
                    imageFile.anchor(left: container.leftAnchor, paddingLeft: 10,
                                     centerY: container.centerYAnchor, width: 34, height: 40)

                    let nameFile = UILabel()
                    container.addSubview(nameFile)
                    nameFile.font = .systemFont(ofSize: 12 + String.offset(), weight: .medium)
                    nameFile.textColor = .label
                    nameFile.numberOfLines = 2
                    nameFile.anchor(top: container.topAnchor, left: imageFile.rightAnchor, right: container.rightAnchor, paddingTop: 5, paddingLeft: 10, paddingRight: 5)
                    nameFile.text = documentName

                    let fileSub = UILabel()
                    container.addSubview(fileSub)
                    fileSub.anchor(top: nameFile.bottomAnchor, left: imageFile.rightAnchor, bottom: container.bottomAnchor, paddingLeft: 10, paddingBottom: 5)
                    fileSub.font = .systemFont(ofSize: 10 + String.offset())
                    fileSub.textColor = .secondaryLabel
                    let fileType = Utils.documentType(of: documentKind)
                    var fileBytes = VideoNote.Facts.of(attachmentNamed: data.file).bytes
                    if fileBytes == 0 {
                        fileBytes = VideoNote.Facts.measuredSize(ofAttachmentNamed: data.file)
                    }
                    fileSub.text = fileBytes > 0
                        ? "\(VideoNote.Facts.humanSize(fileBytes)) \u{2022} \(fileType)"
                        : fileType
                    if fileBytes == 0 {
                        // Neither the sender nor a plain copy on disk could say. The one place left
                        // to look is the secure store, and looking there means opening the whole
                        // file - so it is done away from the main thread and the line fills itself
                        // in.
                        VideoNote.Facts.measureSize(ofAttachmentNamed: data.file) { [weak fileSub] bytes in
                            fileSub?.text = "\(VideoNote.Facts.humanSize(bytes)) \u{2022} \(fileType)"
                        }
                    }

                    let objectTap = ObjectGesture(target: self, action: #selector(onContSearch(_:)))
                    objectTap.file_id = data.file
                    objectTap.containerFile = container
                    container.addGestureRecognizer(objectTap)
                    // A transfer that is already running when this row is drawn shows its ring
                    // straight away, at the progress it has actually reached.
                    if Download.isDownloading(forKey: data.file) {
                        ChatTransferRing.add(to: container, fileName: data.file, progress: Download.progress(forKey: data.file) ?? 0)
                    }
                } else if selectedTag == ChatTagSearch.linksTag {
                    // Fix: the panel under a link result was a grey chain glyph and the address
                    // written out in small print - no picture, no title, nothing to say what was
                    // on the other end. The reference gives a link result the page's own picture
                    // at the left, its title over two lines, and the site under that; which is
                    // what the bubble in the conversation now draws too, so both read the page
                    // the same way. See LinkPreviewFacts.
                    let link = LinkPreviewFetcher.firstLink(in: data.messageText)

                    let objectTap = ObjectGesture(target: self, action: #selector(onContSearch(_:)))
                    objectTap.message_id = link
                    container.addGestureRecognizer(objectTap)

                    let imagePreview = UIImageView()
                    container.addSubview(imagePreview)
                    imagePreview.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        imagePreview.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                        imagePreview.topAnchor.constraint(equalTo: container.topAnchor),
                        imagePreview.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                        imagePreview.widthAnchor.constraint(equalToConstant: panelHeight)
                    ])
                    imagePreview.clipsToBounds = true
                    imagePreview.backgroundColor = tableView.traitCollection.userInterfaceStyle == .dark
                        ? UIColor.white.withAlphaComponent(0.08)
                        : UIColor.black.withAlphaComponent(0.05)

                    let titlePreview = UILabel()
                    titlePreview.font = .systemFont(ofSize: 14 + String.offset(), weight: .semibold)
                    titlePreview.textColor = .label
                    titlePreview.numberOfLines = 2

                    let hostPreview = UILabel()
                    hostPreview.font = .systemFont(ofSize: 12 + String.offset())
                    hostPreview.textColor = .secondaryLabel
                    hostPreview.numberOfLines = 1

                    let written = UIStackView(arrangedSubviews: [titlePreview, hostPreview])
                    written.axis = .vertical
                    written.spacing = 2
                    container.addSubview(written)
                    written.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        written.leadingAnchor.constraint(equalTo: imagePreview.trailingAnchor, constant: 12),
                        written.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
                        written.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                        written.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 6)
                    ])

                    /// A link nothing is known about yet, or nothing could be learned about: the
                    /// address itself, which is all there is to say.
                    func drawPlain() {
                        imagePreview.image = UIImage(systemName: "link",
                                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 26))
                        imagePreview.contentMode = .center
                        imagePreview.tintColor = .secondaryLabel
                        titlePreview.text = link
                        titlePreview.numberOfLines = 2
                        hostPreview.isHidden = true
                    }

                    func draw(_ facts: LinkPreviewFacts) {
                        titlePreview.text = facts.title.isEmpty ? link : facts.title
                        var site = facts.domain
                        if facts.isVideo {
                            let spoken = facts.spokenDuration
                            site += " \u{2022} " + (spoken.isEmpty ? facts.videoLabel : "\(facts.videoLabel) \(spoken)")
                        }
                        hostPreview.text = site
                        hostPreview.isHidden = site.isEmpty
                        // The picture as it already stands on this device - the conversation put
                        // it there when it drew the message. Nothing is downloaded for a row in a
                        // list that scrolls, and the disk is read away from the main thread: the
                        // shared image cache decrypts what it reads, which is not something a row
                        // can do between two frames.
                        imagePreview.image = UIImage(systemName: "link",
                                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 26))
                        imagePreview.contentMode = .center
                        imagePreview.tintColor = .secondaryLabel
                        LinkPreviewImage.onDisk(facts.imageUrl) { [weak imagePreview] picture in
                            guard let picture = picture, let imagePreview = imagePreview else {
                                return
                            }
                            imagePreview.contentMode = .scaleAspectFill
                            imagePreview.tintColor = nil
                            imagePreview.image = picture
                        }
                    }

                    // Fix: this list read every link it drew off the internet, a page per row as
                    // the rows came into view, and rebuilt each row when its page arrived - so
                    // scrolling the link filter dragged a queue of downloads and a queue of row
                    // reloads behind it, and the scrolling showed it. Nothing is fetched here any
                    // more: the list draws what is already known about a link, which is what the
                    // conversation itself wrote down when it drew the message. A link whose page
                    // has not been read yet reads as its own address, and reading the message in
                    // its conversation is what fills it in.
                    let known: LinkPreviewStore.Answer
                    if let held = linkAnswers[link] {
                        known = held
                    } else {
                        known = LinkPreviewStore.answer(link: link)
                        linkAnswers[link] = known
                    }
                    switch known {
                    case .read(let facts):
                        draw(facts)
                    case .nothingOnIt, .notAsked:
                        drawPlain()
                    }
                } else if selectedTag == ChatTagSearch.audiosTag {
                    // Fix: a music-note glyph and a file name, and a tap anywhere on the panel to
                    // start it - no play button, no waveform, no length, and nothing to say whose
                    // voice it is. The conversation already draws an audio row properly, in
                    // AudioBubbleContent, and the message info screen draws the same one; this
                    // makes three places rather than a fourth drawing of its own.
                    let isVoiceNote = data.attachmentFlag == "60"

                    // Fix: incoming: true was wrong for a list. That lays a bubble out mirrored -
                    // the sender's picture on the far side - which is right in a conversation where
                    // the two sides face each other, and wrong here where every row is somebody
                    // else's and they all read the same way. The reference has the picture leading.
                    let row = AudioBubbleContent(incoming: false,
                                                 isVoiceNote: isVoiceNote,
                                                 bubbleColour: container.backgroundColor ?? .white,
                                                 traits: tableView.traitCollection,
                                                 fontOffset: String.offset(),
                                                 stretchesTrack: true)
                    container.addSubview(row)
                    // Fix: the row was pinned to the panel's right edge as well, and it must not
                    // be. AudioBubbleContent ends where its own line ends - it says so with a
                    // required constraint, so that two screens showing the same note come out the
                    // same width - and pinning it to a wide panel as well asks for two widths at
                    // once. Auto Layout settles that by breaking something, and what it broke was
                    // the picture's own width: a 44-point circle stretched into a black stadium
                    // most of the row long. It hugs its content now and only the left edge and the
                    // height are given to it.
                    // The line runs to the row's own trailing edge now, so the row is given the
                    // panel's width and there is no second answer for Auto Layout to break.
                    row.anchor(top: container.topAnchor, left: container.leftAnchor,
                               bottom: container.bottomAnchor, right: container.rightAnchor,
                               paddingTop: 6, paddingLeft: 10, paddingBottom: 6, paddingRight: 14)
                    // Fix: data.thumb is the *message's* thumbnail, which a voice note does not
                    // have - so the picture was never given anything to load and every row drew the
                    // grey stand-in. The sender's own picture is data.profile: the query behind
                    // these results joins BUDDY on m.f_pin, so it is already whose voice it is.
                    row.setPicture(named: data.profile)
                    // The speed button belongs to a conversation, where a note is listened to at
                    // length; a result in a list is a thing to identify, not to sit through.
                    row.speedPill.isHidden = true
                    audioRows[data.messageId] = row

                    audioButtonResults[row.playButton] = data
                    row.playButton.addTarget(self, action: #selector(audioPlayTapped(_:)), for: .touchUpInside)

                    if let url = audioFileURL(named: data.audio) {
                        // What the row says is taken from the one player this recording has,
                        // whether this screen started it or a conversation did - see
                        // AudioMiniPlayer. Opening a second player for a recording already playing
                        // somewhere else is what leaves a row silent with a play button on it.
                        _ = AudioMiniPlayer.shared.player(for: data.messageId, openingFrom: url)
                        showAudioState(on: row, messageId: data.messageId, name: data.audio)
                        if isVoiceNote {
                            let key = data.audio
                            if let levels = AudioWaveformStore.levels(for: key) {
                                row.wave.levels = levels
                            } else {
                                AudioWaveformStore.read(url: url, key: key) { [weak row] levels in
                                    row?.wave.levels = levels
                                }
                            }
                        }
                        // Fix: this used to take the recording back off the strip the moment the
                        // row was built, copied from the conversation - which is right there,
                        // because a bubble showing a recording is the thing that should be showing
                        // it. It is wrong here: coming back from a conversation lands on this list,
                        // and the reader asked for the strip to be the one that carries on. So the
                        // row is drawn at rest and the recording stays with the strip until the
                        // play button asks for it - rule three.
                        if playingAudioId == data.messageId {
                            startAudioTicker()
                        }
                    } else if !Download.isDownloading(forKey: data.audio) {
                        Download().startHTTP(forKey: data.audio) { [weak self] (name, progress) in
                            guard progress == 100 else {
                                return
                            }
                            DispatchQueue.main.async {
                                self?.reloadBothViews()
                            }
                        }
                    }
                    if Download.isDownloading(forKey: data.audio) {
                        ChatTransferRing.add(to: container, fileName: data.audio, progress: Download.progress(forKey: data.audio) ?? 0)
                    }
                }
        return cell
    }

    /// One media result as a row: who sent it, what was said with it, and a thumbnail - the
    /// same information the grid carries, for when a wall of thumbnails is not enough to tell
    /// them apart.
    private func buildMediaCaptionCell(cell: UITableViewCell, content: UIView, data: Chat) {
        let topPadding = ChatTagSearch.captionTopPadding
        // A button rather than a plain image view: a touch that lands in a UIControl is one the
        // table view leaves alone, which is exactly the split that is wanted here - the picture
        // opens the picture, anywhere else on the row opens the conversation.
        let thumbButton = UIButton(type: .custom)
        thumbButton.tag = ChatTagSearch.captionThumbTag
        thumbButton.clipsToBounds = true
        thumbButton.layer.cornerRadius = 6
        thumbButton.backgroundColor = .lightGray.withAlphaComponent(0.3)
        thumbButton.addTarget(self, action: #selector(captionThumbTapped(_:)), for: .touchUpInside)
        content.addSubview(thumbButton)
        thumbButton.anchor(top: content.topAnchor, right: content.rightAnchor,
                           paddingTop: topPadding,
                           paddingRight: ChatTagSearch.captionMargin,
                           width: ChatTagSearch.captionThumbSize, height: ChatTagSearch.captionThumbSize)

        // Kept as the button's own first subview so the zoom that opens a photo has something
        // to grow out of, the same way the grid's tiles do.
        let thumbView = UIImageView()
        thumbView.contentMode = .scaleAspectFill
        thumbView.clipsToBounds = true
        thumbButton.addSubview(thumbView)
        thumbView.anchor(top: thumbButton.topAnchor, left: thumbButton.leftAnchor, bottom: thumbButton.bottomAnchor, right: thumbButton.rightAnchor)
        loadThumbnail(named: data.thumb, into: thumbView)

        let title = UILabel()
        title.text = conversationName(for: data)
        // Deliberately .medium, the weight the rest of this app's rows are titled in: the
        // framework swizzles the system font and maps .semibold to its *bold italic* face
        // (see UIFont.libOverrideInitialize), which is what made these titles come out slanted.
        title.font = .systemFont(ofSize: 17 + String.offset(), weight: .medium)
        title.textColor = content.traitCollection.userInterfaceStyle == .dark ? .white : .black
        title.lineBreakMode = .byTruncatingTail
        content.addSubview(title)
        title.anchor(top: content.topAnchor, left: content.leftAnchor, right: thumbButton.leftAnchor,
                     paddingTop: topPadding,
                     paddingLeft: ChatTagSearch.captionMargin, paddingRight: 12)

        let subtitle = UILabel()
        // Font and colour first: setting either after an attributed string is what re-applies
        // it across the whole string, which would undo the parts that carry their own.
        subtitle.font = .systemFont(ofSize: 15 + String.offset())
        subtitle.textColor = .gray
        subtitle.numberOfLines = 2
        subtitle.lineBreakMode = .byTruncatingTail
        subtitle.attributedText = resultSubtitle(for: data)
        content.addSubview(subtitle)
        subtitle.anchor(top: title.bottomAnchor, left: content.leftAnchor, right: thumbButton.leftAnchor,
                        paddingTop: 4, paddingLeft: ChatTagSearch.captionMargin, paddingRight: 12)

        cell.separatorInset = UIEdgeInsets(top: 0, left: ChatTagSearch.captionMargin, bottom: 0, right: ChatTagSearch.captionMargin)
    }

    /// "You: 📷 caption" the way WhatsApp writes it: who sent it (left out when the
    /// conversation is with that person and it is already in the title), then the kind of
    /// attachment as an icon, then whatever was said with it.
    /// Who sent it and what it is - the line under the conversation's name.
    ///
    /// Fix: this was only asked for by the photo and video rows. Documents, links and audio each
    /// wrote their own subtitle a few lines further down, and none of them said who sent it - so a
    /// group result gave no clue which of twenty people it came from. The rule about the sender is
    /// the same for all of them, and it is a rule worth stating once: in a group the sender is
    /// always named, because there are many; in a one-to-one conversation only "You" is worth
    /// saying, because the other name is already the title.
    private func resultSubtitle(for data: Chat) -> NSAttributedString {
        let font = UIFont.systemFont(ofSize: 15 + String.offset())
        let line = NSMutableAttributedString()
        let sender: String
        if !data.fpin.isEmpty, data.fpin == User.getMyPin() {
            sender = "You".localized() + ": "
        } else if isGroupResult(data), !data.name.trimmingCharacters(in: .whitespaces).isEmpty {
            sender = data.name.trimmingCharacters(in: .whitespaces) + ": "
        } else {
            sender = ""
        }
        if !sender.isEmpty {
            line.append(NSAttributedString(string: sender, attributes: [.font: font, .foregroundColor: UIColor.gray]))
        }

        let symbol: String
        let fallback: String
        // Whether the line ends with what was written alongside the attachment, or simply with
        // what the attachment is. A caption belongs to a picture; a document's message text is its
        // own file name, and a recording has none at all.
        var showsCaption = true
        switch selectedTag {
        case ChatTagSearch.videosTag:
            symbol = "video.fill"
            fallback = "Video".localized()
        case ChatTagSearch.gifsTag:
            symbol = "photo.fill"
            fallback = "GIF"
        case ChatTagSearch.documentsTag:
            symbol = "doc.fill"
            fallback = "Document".localized()
            showsCaption = false
        case ChatTagSearch.audiosTag:
            let isVoiceNote = data.attachmentFlag == "60"
            symbol = isVoiceNote ? "mic.fill" : "music.note"
            var said = isVoiceNote ? "Voice message".localized() : "Audio".localized()
            // The length, where it is known, exactly as the conversation list says it.
            if isVoiceNote, let seconds = AudioDurationStore.seconds(forFileNamed: data.audio) {
                said += String(format: " (%d:%02d)", seconds / 60, seconds % 60)
            }
            fallback = said
            showsCaption = false
        case ChatTagSearch.linksTag:
            symbol = "link"
            fallback = "Link".localized()
        default:
            symbol = "camera.fill"
            fallback = "Photo".localized()
        }
        if let icon = UIImage(systemName: symbol)?.withTintColor(.gray, renderingMode: .alwaysOriginal) {
            let attachment = NSTextAttachment()
            attachment.image = icon
            let height = font.pointSize * 0.9
            let width = height * (icon.size.width / max(icon.size.height, 1))
            attachment.bounds = CGRect(x: 0, y: font.descender * 0.5, width: width, height: height)
            line.append(NSAttributedString(attachment: attachment))
            line.append(NSAttributedString(string: " ", attributes: [.font: font]))
        }
        // What was written, less the part after the black square - that is carried along with some
        // messages for the app's own purposes and is not something anybody wrote.
        var written = data.messageText
        if written.contains("■") {
            written = written.components(separatedBy: "■")[0]
        }
        let caption = written.mentionsAsNames().trimmingCharacters(in: .whitespacesAndNewlines)
        let said = showsCaption && !caption.isEmpty ? caption : fallback
        line.append(NSAttributedString(string: said,
                                       attributes: [.font: font, .foregroundColor: UIColor.gray]))
        return line
    }

    /// Whether a result belongs to a group or forum rather than a one-to-one conversation.
    private func isGroupResult(_ data: Chat) -> Bool {
        return !(data.messageScope == MessageScope.WHISPER
                 || data.messageScope == MessageScope.CALL
                 || data.messageScope == MessageScope.MISSED_CALL)
    }

    /// The conversation a result belongs to, which is what the row is titled with - the same
    /// conversation tapping the row opens. `data.name` is the *sender's* name (the filter query
    /// joins the buddy table on the message's sender), so it cannot be used for this.
    private func conversationName(for data: Chat) -> String {
        let fallback = data.name.trimmingCharacters(in: .whitespaces)
        var key = data.pin
        if key.isEmpty || (!isGroupResult(data) && key == User.getMyPin()) {
            key = data.fpin
        }
        guard !key.isEmpty else {
            return fallback
        }
        if let cached = conversationNames[key] {
            return cached
        }
        var name = ""
        if isGroupResult(data) {
            // Fix: this answered with the topic's title alone, or with the group's name alone when
            // there was no topic - so two topics of the same group read as two unrelated
            // conversations, and a reader could not tell which group a result belonged to. The
            // conversation itself is named "group (topic)", and a result should carry the same name
            // the conversation carries.
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                var group = ""
                var topic = ""
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT c.f_name, b.title FROM DISCUSSION_FORUM b JOIN GROUPZ c ON b.group_id = c.group_id WHERE b.chat_id = '\(key)'"), cursor.next() {
                    group = cursor.string(forColumnIndex: 0) ?? ""
                    topic = cursor.string(forColumnIndex: 1) ?? ""
                    cursor.close()
                }
                if group.isEmpty, let cursor = Database.shared.getRecords(fmdb: fmdb, query: "SELECT f_name FROM GROUPZ WHERE group_id = '\(key)'"), cursor.next() {
                    group = cursor.string(forColumnIndex: 0) ?? ""
                    cursor.close()
                    // A group's own room, which the conversation calls Lounge.
                    topic = "Lounge".localized()
                }
                name = topic.trimmingCharacters(in: .whitespaces).isEmpty
                    ? group
                    : "\(group) (\(topic))"
            })
        } else if let user = User.getDataCanNil(pin: key) {
            name = user.fullName.trimmingCharacters(in: .whitespaces)
        }
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            name = fallback
        }
        conversationNames[key] = name
        return name
    }

    @objc private func captionThumbTapped(_ sender: UIButton) {
        var view: UIView? = sender
        while let current = view, !(current is UITableViewCell) {
            view = current.superview
        }
        guard let cell = view as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell),
              let data = result(at: indexPath) else {
            return
        }
        openMedia(data, thumbnailIn: sender)
    }

    /// The stored thumbnail for a message, from wherever it happens to live.
    private func loadThumbnail(named thumb: String, into imageView: UIImageView) {
        guard !thumb.isEmpty else {
            return
        }
        if let cached = Nexilis.imageCache.object(forKey: thumb as NSString) {
            imageView.image = cached
            return
        }
        var data: Data?
        if FileEncryption.shared.isSecureExists(filename: thumb) {
            if var secure = try? FileEncryption.shared.readSecure(filename: thumb) {
                if let decrypted = FileEncryption.shared.decryptFileFromServer(data: secure) {
                    secure = decrypted
                }
                data = secure
            }
        } else if let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            data = try? Data(contentsOf: URL(fileURLWithPath: dirPath).appendingPathComponent(thumb))
        }
        guard let data = data, let image = UIImage(data: data)?.resize(target: CGSize(width: 500, height: 500)) else {
            // Not here yet: the thumbnail is small, so it is simply fetched - the row redraws
            // itself when it lands, through the same progress notification everything else
            // listens to.
            if !Download.isDownloading(forKey: thumb) {
                Download().startHTTP(forKey: thumb) { _, _ in }
            }
            return
        }
        Nexilis.imageCache.setObject(image, forKey: thumb as NSString)
        imageView.image = image
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let data = result(at: indexPath) else {
            return
        }
        // Tapping the attachment inside a row opens the file itself - the thumbnail in the
        // media list is a button of its own, and the other lists have their own tap targets.
        // Tapping anywhere else opens the conversation at that message, and it is the host
        // that knows how.
        delegate?.chatTagSearch(self, didSelect: data)
    }

    // MARK: - Opening what was tapped

    @objc func onContSearch(_ sender: ObjectGesture) {
        if selectedTag == ChatTagSearch.photosTag {
            
        } else if selectedTag == ChatTagSearch.videosTag {
            
        } else if selectedTag == ChatTagSearch.documentsTag {
            // Not here yet: fetch it, and show that something is happening.
            if downloadIfMissing(sender.file_id, showingProgressOn: sender.containerFile) {
                return
            }
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if let dirPath = paths.first {
                let fileURL = URL(fileURLWithPath: dirPath).appendingPathComponent(sender.file_id)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    self.previewItem = fileURL as NSURL
                    let previewController = QLPreviewController()
                    let rightBarButton = UIBarButtonItem()
                    previewController.navigationItem.rightBarButtonItem = rightBarButton
                    previewController.dataSource = self
                    previewController.modalPresentationStyle = .custom
                    
                    presenter?.present(previewController, animated: true)
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
                            let previewController = QLPreviewController()
                            let rightBarButton = UIBarButtonItem()
                            previewController.navigationItem.rightBarButtonItem = rightBarButton
                            previewController.dataSource = self
                            previewController.modalPresentationStyle = .custom
                            presenter?.present(previewController,animated: true)
                        }
                    }
                    catch {
                        
                    }
                }
            }
        } else if selectedTag == ChatTagSearch.linksTag {
            var stringURl = sender.message_id
            if stringURl.lowercased().starts(with: "www.") {
                stringURl = "https://" + stringURl.replacingOccurrences(of: "www.", with: "")
            }
            guard URL(string: stringURl) != nil else { return }
            if Nexilis.checkingAccess(key: "secure_browser") {
                APIS.openUrl(url: stringURl)
            } else {
                guard let url = URL(string: stringURl) else { return }
                UIApplication.shared.open(url)
            }
        } else if selectedTag == ChatTagSearch.audiosTag {
            // Nothing here. A recording is started by its own play button, which is where the
            // reference puts it and the only thing that can say which recording is meant. This
            // used to open a player of its own - one per screen rather than one per recording - so
            // a note started in this list and then opened in its conversation played twice over.
            // See audioPlayTapped.
        }
    }

    // MARK: - Playing a result

    /// Where a recording can be played from, or nil while it is not on this device.
    ///
    /// A recording in the secure store has to be written out before anything can play it, and it
    /// is written to the caches directory under its own name so the same recording is only ever
    /// written out once.
    private func audioFileURL(named name: String) -> URL? {
        guard !name.isEmpty else {
            return nil
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let onDisk = documents.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: onDisk.path) {
            return onDisk
        }
        guard FileEncryption.shared.isSecureExists(filename: name) else {
            return nil
        }
        // .aac written out as .m4a: AVAudioPlayer reads the container by its extension, and a
        // recording from Android arrives as a raw stream with the wrong one.
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let written = caches.appendingPathComponent(
            name.contains(".aac") ? "\(name.components(separatedBy: ".")[0]).m4a" : name)
        if FileManager.default.fileExists(atPath: written.path) {
            return written
        }
        do {
            if var data = try FileEncryption.shared.readSecure(filename: name) {
                if let decrypted = FileEncryption.shared.decryptFileFromServer(data: data) {
                    data = decrypted
                }
                try data.write(to: written)
                return written
            }
        } catch {
            return nil
        }
        return nil
    }

    /// Puts a row in step with the one player its recording has: the button, the line and the
    /// length.
    private func showAudioState(on row: AudioBubbleContent, messageId: String, name: String) {
        let player = AudioMiniPlayer.shared.player(for: messageId)
        // Rule three: a recording the strip is holding is running, but it is not running *here*.
        // The strip is what says so, and two things saying it at once is one too many - so this row
        // shows it at rest until the reader takes it back with the play button.
        let heldByStrip = AudioMiniPlayer.shared.currentMessageId == messageId
        let playing = player?.isPlaying == true && !heldByStrip
        row.playButton.setImage(UIImage(systemName: playing ? "pause.fill" : "play.fill"), for: .normal)
        guard let player = player else {
            row.timeLabel.text = AudioDurationStore.seconds(forFileNamed: name)
                .map { ChatTagSearch.clock(TimeInterval($0)) } ?? ""
            return
        }
        // Fix: the pointer on a note is the slider's own thumb laid over the waveform - the two
        // views share the same place in AudioBubbleContent - and only the waveform was being
        // moved. So the played part of the wave crept along while the dot that marks it sat at the
        // beginning. Both, always: the wave says how much, the thumb says where.
        row.slider.maximumValue = Float(max(player.duration, 0.01))
        row.slider.value = Float(player.currentTime)
        if row.isVoiceNote {
            row.wave.progress = player.duration > 0 ? CGFloat(player.currentTime / player.duration) : 0
        }
        // What is left of it while it runs, and how long it is when it is not - which is what the
        // reference shows on a note nobody has started.
        row.timeLabel.text = ChatTagSearch.clock(player.isPlaying || player.currentTime > 0
                                                 ? player.currentTime
                                                 : player.duration)
    }

    private static func clock(_ seconds: TimeInterval) -> String {
        let whole = Int(seconds.rounded(.down))
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }

    /// Starts a recording, or stops the one that is running.
    @objc private func audioPlayTapped(_ sender: UIButton) {
        guard let data = audioButtonResults[sender], let row = audioRows[data.messageId] else {
            return
        }
        if downloadIfMissing(data.audio, showingProgressOn: row.superview ?? row) {
            return
        }
        guard let url = audioFileURL(named: data.audio),
              let player = AudioMiniPlayer.shared.player(for: data.messageId, openingFrom: url) else {
            return
        }
        // Rule three, the other half: the strip is holding this one, so pressing play here means
        // taking it back. Nothing stops and nothing starts again - the sound carries on from where
        // it is, and the strip goes because this row is showing it now.
        if AudioMiniPlayer.shared.currentMessageId == data.messageId {
            _ = AudioMiniPlayer.shared.reclaim(messageId: data.messageId)
            player.delegate = self
            playingAudioId = data.messageId
            startAudioTicker()
            showAudioState(on: row, messageId: data.messageId, name: data.audio)
            return
        }
        if player.isPlaying {
            player.pause()
            AudioPositionStore.remember(player.currentTime, for: data.messageId)
            playingAudioId = ""
            stopAudioTicker()
            showAudioState(on: row, messageId: data.messageId, name: data.audio)
            return
        }
        // One recording at a time, and that rule belongs to the app rather than to this screen:
        // what it stops may be another row here, or one still running on the strip from a
        // conversation that has been left. Both are settled in one call.
        for stopped in AudioMiniPlayer.shared.pauseAllExcept(data.messageId) {
            if let other = audioRows[stopped] {
                showAudioState(on: other, messageId: stopped, name: "")
            }
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
        player.delegate = self
        player.play()
        playingAudioId = data.messageId
        startAudioTicker()
        showAudioState(on: row, messageId: data.messageId, name: data.audio)
    }

    private func startAudioTicker() {
        guard audioTicker == nil else {
            return
        }
        audioTicker = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tickAudio()
        }
    }

    private func stopAudioTicker() {
        audioTicker?.invalidate()
        audioTicker = nil
    }

    private func tickAudio() {
        guard !playingAudioId.isEmpty,
              let player = AudioMiniPlayer.shared.player(for: playingAudioId) else {
            stopAudioTicker()
            return
        }
        // Fix: this went on ticking after the recording had been handed to the strip. Nothing ever
        // told it - the handover happens in the conversation that was left, and this screen was
        // not there to hear it - so the button showed the recording at rest, correctly, while the
        // thumb and the played part of the waveform carried on moving underneath it. The one thing
        // that can always be checked is who is holding the recording now, so it is checked here:
        // the strip holding it means this screen is no longer the one showing it, and it steps
        // aside where it stands.
        if AudioMiniPlayer.shared.currentMessageId == playingAudioId {
            let handedOver = playingAudioId
            playingAudioId = ""
            stopAudioTicker()
            if let row = audioRows[handedOver] {
                showAudioState(on: row, messageId: handedOver, name: "")
            }
            return
        }
        AudioPositionStore.remember(player.currentTime, for: playingAudioId)
        guard let row = audioRows[playingAudioId], row.window != nil else {
            // The row has scrolled away. The sound carries on - it is the strip's job to say so
            // once this screen is left - but there is nothing here to keep in step.
            return
        }
        showAudioState(on: row, messageId: playingAudioId, name: "")
    }

    /// Stops whatever this screen started, and forgets the recording so the next listen begins at
    /// the beginning.
    ///
    /// Rule one of the three: a filter cleared takes its sound with it. Anything a *conversation*
    /// started is left alone - it is not this screen's to stop.
    private func stopOwnAudio() {
        stopAudioTicker()
        guard !playingAudioId.isEmpty else {
            return
        }
        let wasPlaying = playingAudioId
        playingAudioId = ""
        AudioMiniPlayer.shared.release(wasPlaying)
        if let row = audioRows[wasPlaying] {
            showAudioState(on: row, messageId: wasPlaying, name: "")
        }
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard !playingAudioId.isEmpty else {
            return
        }
        let finished = playingAudioId
        playingAudioId = ""
        stopAudioTicker()
        AudioPositionStore.remember(0, for: finished)
        player.currentTime = 0
        if let row = audioRows[finished] {
            showAudioState(on: row, messageId: finished, name: "")
        }
    }

    // MARK: - Grid

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    public     func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section >= 0, section < sections.count else {
            return 0
        }
        return sections[section].range.count
    }

    /// The grid's month strip, drawn and pinned the same way the list's is.
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "gridHeader", for: indexPath)
        header.subviews.forEach { $0.removeFromSuperview() }
        guard let title = sectionTitle(indexPath.section) else {
            return header
        }
        buildMonthStrip(in: header, title: title, style: collectionView.traitCollection.userInterfaceStyle)
        return header
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard sectionTitle(section) != nil else {
            return .zero
        }
        // Same reasoning as sizeForItemAt: this is asked for before the view has been laid out,
        // and a width of zero draws nothing at all.
        let available = collectionView.bounds.width > 0 ? collectionView.bounds.width : UIScreen.main.bounds.width
        return CGSize(width: available, height: ChatTagSearch.captionSectionHeaderHeight)
    }

    public     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let data = result(at: indexPath) else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath)
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath)
        if cell.contentView.subviews.count > 0 {
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        }
        let thumb = data.thumb
        let imgData = data.image
        let vidData = data.video
        let gifData = data.gif
        // Whatever this tile stands for, if it is being fetched right now the tile says so -
        // including a transfer that was started from another screen entirely.
        let fileBeingFetched = [imgData, vidData, gifData].first { Download.isDownloading(forKey: $0) }
        let imageView = UIImageView()
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath = paths.first {
            if selectedTag == ChatTagSearch.gifsTag {
                let gifURL = URL(fileURLWithPath: dirPath).appendingPathComponent(gifData)
                if !FileManager.default.fileExists(atPath: gifURL.path) && !FileEncryption.shared.isSecureExists(filename: gifData) {
                    Download().startHTTP(forKey: gifData) { (name, progress) in
                        guard progress == 100 else {
                            return
                        }
                        collectionView.reloadItems(at: [indexPath])
                    }
                } else {
                    let imageGif = SDAnimatedImageView()
                    cell.contentView.addSubview(imageGif)
                    imageGif.contentMode = .scaleAspectFill
                    imageGif.clipsToBounds = true
                    imageGif.translatesAutoresizingMaskIntoConstraints = false
                    imageGif.anchor(top: cell.contentView.topAnchor, left: cell.contentView.leftAnchor, bottom: cell.contentView.bottomAnchor, right: cell.contentView.rightAnchor)
                    if FileManager.default.fileExists(atPath: gifURL.path) {
                        imageGif.image = SDAnimatedImage(contentsOfFile: gifURL.path)
//                        imageGif.shouldCustomLoopCount = true
//                        imageGif.animationRepeatCount = 4
                    } else if FileEncryption.shared.isSecureExists(filename: gifData){
                        do {
                            if var data = try FileEncryption.shared.readSecure(filename: gifData) {
                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                if dataDecrypt != nil {
                                    data = dataDecrypt!
                                }
                                if let imageData = SDAnimatedImage(data: data) {
                                    imageGif.image = imageData
    //                                imageGif.shouldCustomLoopCount = true
    //                                imageGif.animationRepeatCount = 4
                                }
                            }
                        }
                        catch {
                            print("Error reading secure file")
                        }
                    }
                }
                return cell
            }
            if FileEncryption.shared.isSecureExists(filename: thumb) {
                do {
                    if var data = try FileEncryption.shared.readSecure(filename: thumb) {
                        let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                        if dataDecrypt != nil {
                            data = dataDecrypt!
                        }
                        DispatchQueue.main.async {
                            let image : UIImage? =  {
                                if let img = Nexilis.imageCache.object(forKey: thumb as NSString) {
                                    return img
                                }
                                else if let img = UIImage(data: data)?.resize(target: CGSize(width: 500, height: 500)) {
                                    Nexilis.imageCache.setObject(img, forKey: thumb as NSString)
                                    return img
                                }
                                return nil
                            }()
                            imageView.image = image
                        }
                    }
                } catch {
                    
                }
            } else {
                Download().startHTTP(forKey: thumb) { (name, progress) in
                    guard progress == 100 else {
                        return
                    }
                    collectionView.reloadItems(at: [indexPath])
                }
            }
            cell.contentView.addSubview(imageView)
            
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imgData)
            let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(vidData)
            if (!FileManager.default.fileExists(atPath: imageURL.path) && !FileEncryption.shared.isSecureExists(filename: imageURL.lastPathComponent)) || (!FileManager.default.fileExists(atPath: videoURL.path) && !FileEncryption.shared.isSecureExists(filename: videoURL.lastPathComponent)) {
                let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
                let blurEffectView = UIVisualEffectView(effect: blurEffect)
                blurEffectView.frame = CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height)
                blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                imageView.addSubview(blurEffectView)
                if !imgData.isEmpty {
                    let imageDownload = UIImageView(image: UIImage(systemName: "arrow.down.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .default)))
                    imageDownload.tag = ChatTagSearch.overlayBadgeTag
                    imageView.addSubview(imageDownload)
                    imageDownload.tintColor = .black.withAlphaComponent(0.3)
                    imageDownload.translatesAutoresizingMaskIntoConstraints = false
                    imageDownload.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
                    imageDownload.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
                }
            }
            if (!vidData.isEmpty) {
                let imagePlay = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .default))?.imageWithInsets(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))?.withTintColor(.white))
                imagePlay.circle()
                imagePlay.tag = ChatTagSearch.overlayBadgeTag
                imageView.addSubview(imagePlay)
                imagePlay.backgroundColor = .black.withAlphaComponent(0.3)
                imagePlay.translatesAutoresizingMaskIntoConstraints = false
                imagePlay.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
                imagePlay.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
            }
        }
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.anchor(top: cell.contentView.topAnchor, left: cell.contentView.leftAnchor, bottom: cell.contentView.bottomAnchor, right: cell.contentView.rightAnchor)
        // Last, so the blur and the download arrow the tile may already carry do not sit on
        // top of it.
        if let fileBeingFetched = fileBeingFetched {
            setOverlayBadgesHidden(true, in: cell.contentView)
            ChatTransferRing.add(to: cell.contentView, fileName: fileBeingFetched, progress: Download.progress(forKey: fileBeingFetched) ?? 0)
        }

        return cell
    }

    /// Opens one media result - the picture, the video, the GIF - or fetches it first if it
    /// is not on the device yet. Shared by the grid and the caption list, because a tap means
    /// the same thing in both.
    private func openMedia(_ data: Chat, thumbnailIn container: UIView?) {
        let imgData = data.image
        let vidData = data.video
        let gifData = data.gif
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath = paths.first {
            if selectedTag == ChatTagSearch.photosTag {
                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(imgData)
                if FileManager.default.fileExists(atPath: imageURL.path) {
                    do {
                        APIS.openImageNexilis(imageView: (container?.subviews.first as? UIImageView) ?? UIImageView(), data: try Data(contentsOf: imageURL), nameSender: data.name, time: data.serverDate)
                    } catch {
                        
                    }
                } else if FileEncryption.shared.isSecureExists(filename: imgData) {
                    do {
                        if var dataImage = try FileEncryption.shared.readSecure(filename: imgData) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: dataImage)
                            if dataDecrypt != nil {
                                dataImage = dataDecrypt!
                            }
                            APIS.openImageNexilis(imageView: (container?.subviews.first as? UIImageView) ?? UIImageView(), data: dataImage, nameSender: data.name, time: data.serverDate)
                        }
                    }
                    catch {
                    }
                } else {
                    // The photo itself is not here yet - only its thumbnail was. Fetch it, and
                    // put a ring on the tile so the wait is visible.
                    downloadIfMissing(imgData, showingProgressOn: container)
                }
            } else if selectedTag == ChatTagSearch.videosTag {
                let videoURL = URL(fileURLWithPath: dirPath).appendingPathComponent(vidData)
                if FileManager.default.fileExists(atPath: videoURL.path) {
                    APIS.openVideoNexilis(imageView: (container?.subviews.first as? UIImageView) ?? UIImageView(), videoURL: videoURL, nameSender: data.name, time: data.serverDate)
                } else if FileEncryption.shared.isSecureExists(filename: vidData) {
                    do {
                        if var secureData = try FileEncryption.shared.readSecure(filename: vidData) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
                            if dataDecrypt != nil {
                                secureData = dataDecrypt!
                            }
                            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                            let tempPath = cachesDirectory.appendingPathComponent(vidData)
                            try secureData.write(to: tempPath)
                            APIS.openVideoNexilis(imageView: (container?.subviews.first as? UIImageView) ?? UIImageView(), videoURL: tempPath, nameSender: data.name, time: data.serverDate)
                        }
                    } catch {
                        
                    }
                } else {
                    downloadIfMissing(vidData, showingProgressOn: container)
                }
            } else {
                let gifURL = URL(fileURLWithPath: dirPath).appendingPathComponent(gifData)
                if FileManager.default.fileExists(atPath: gifURL.path) {
                    do {
                        let data = try Data(contentsOf: gifURL)
                        APIS.openImageNexilis(imageView: (container?.subviews.first as? UIImageView) ?? UIImageView(), data: data, isGIF: true)
                    } catch {
                        
                    }
                } else if FileEncryption.shared.isSecureExists(filename: gifData) {
                    do {
                        if var secureData = try FileEncryption.shared.readSecure(filename: gifData) {
                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
                            if dataDecrypt != nil {
                                secureData = dataDecrypt!
                            }
                            APIS.openImageNexilis(imageView: (container?.subviews.first as? UIImageView) ?? UIImageView(), data: secureData, isGIF: true, nameSender: data.name, time: data.serverDate)
                        }
                    } catch {
                        
                    }
                } else {
                    downloadIfMissing(gifData, showingProgressOn: container)
                }
            }
        }
    }

    public     func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let data = result(at: indexPath) else {
            return
        }
        openMedia(data, thumbnailIn: collectionView.cellForItem(at: indexPath)?.contentView)
    }

    // MARK: - QLPreviewControllerDataSource

    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        // QLPreviewController only ever asks after previewItem was set, but a nil here would
        // be a crash rather than an empty preview.
        return previewItem ?? (URL(fileURLWithPath: "") as NSURL)
    }
}
