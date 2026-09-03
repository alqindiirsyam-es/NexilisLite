//
//  VideoNoteBubbleView.swift
//  NexilisLite
//
//  A round video note as it appears in a conversation, built to the reference:
//
//    sending   - the still in the circle, the upload's progress written under it
//    delivered - the note plays small and silent, three times round, with a muted mark and the
//                length under it
//    rested    - back to the still, with a play button in the middle and the length under it
//    opened    - tapped, the circle grows and a ring closes round it as the note plays
//
//  It owns nothing but its own presentation: the file is handed to it, and it reports a tap back.
//

import UIKit
import AVFoundation

public final class VideoNoteBubbleView: UIView, UIGestureRecognizerDelegate {

    // MARK: - What the bubble is doing

    public enum State {
        /// On its way out; the arc turns until it has gone.
        case sending(Double)
        /// Here, and playing itself the way the reference does.
        case delivered
        /// Shown, but not playable - Message Info quotes the note above the read receipts, and
        /// that screen is a record of a message rather than a place to watch one.
        case preview
    }

    /// The reference plays a delivered note three times before it settles.
    private static let autoPlayLoops = 3
    // ---------------------------------------------------------------------------------------
    // The two sizes of the circle, in points. These are the only two numbers that decide how big
    // a video note is - change them here and everything else follows, because the ring, the
    // footer and the row's height are all measured from the circle rather than set beside it.
    //
    //   restingSide - how it sits in the conversation
    //   openedSide  - after a tap, while it plays with sound
    //
    // The bubble is allowed roughly (screen width - 75) at most, about 327pt on a 6.1" phone:
    // past that the conversation's own margins win and the circle stops growing.
    // ---------------------------------------------------------------------------------------
    public static let restingSide: CGFloat = 190
    public static let openedSide: CGFloat = 250

    // How heavy the border and the progress that runs over it are drawn, in points. The progress
    // is the thicker of the two on purpose: it has to read clearly against the border it covers,
    // and a ring the same weight as its own track is hard to follow.
    //
    //   trackWidth - the border, always there, the path the progress runs along
    //   ringWidth  - the progress itself, and the arc that turns while a note is going out
    /// The stop-and-ring control in the footer. Fixed, because its ring is drawn from this rather
    /// than measured off the button after the fact.
    public static let cancelSide: CGFloat = 24
    public static let trackWidth: CGFloat = 3
    public static let ringWidth: CGFloat = 5

    // MARK: - Handing back

    // MARK: - Views

    private let circle = UIView()
    private let still = UIImageView()
    /// The video's own layer, rather than a plain view with a layer parked inside it.
    ///
    /// Fix: the layer's frame was set by hand from `playerHost.bounds` - once when it was made,
    /// which is during cellForRowAt when that view has no size at all, and again in layoutSubviews,
    /// which runs on this view before the circle inside it has laid out. So the frame stayed at
    /// zero and the video rendered nothing at all - the still showed through, and the note looked
    /// as though it had simply refused to play. Opening one gave the layer the small circle's old
    /// bounds, which is the little square off to one side. Making the layer the view's own backing
    /// layer hands all of that to UIKit: it is the view's bounds, always, with nothing to keep in
    /// step.
    private final class PlayerHostView: UIView {
        override class var layerClass: AnyClass { return AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { return layer as! AVPlayerLayer }
    }

    private let playerHost = PlayerHostView()
    private let playButton = UIImageView()
    /// Over the still while the note is still on the server: the picture is there to say what the
    /// note is, not to be watched, so it is blurred until the file arrives.
    /// Thin enough to still read the picture through - the reference blurs the note, it does not
    /// hide it.
    private let notDownloadedBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    /// The arrow and the spinner live in the footer beside the size, where the length would be -
    /// not in the middle of the circle. One line, in one place, whatever the note is doing.
    private let downloadIcon = UIImageView()
    /// Stop, with a ring round it that fills as the file comes in.
    ///
    /// A plain spinner says only "wait". This says how far along it is, and - because it is a
    /// button - it says the reader can change their mind. Its ring turns on the spot while the
    /// transfer has not reported anything yet, because at nought per cent there is nothing to
    /// draw and a still ring reads as stuck.
    private let cancelButton = UIButton(type: .system)
    /// The path the progress runs along - always there, so the arc has somewhere to be.
    private let cancelTrack = CAShapeLayer()
    /// The thick arc: turning while there is no progress to show, tracing the track once there is.
    private let cancelRing = CAShapeLayer()
    /// The path the progress runs along. It is not decoration: on the small circle it is the
    /// border, and when the note is opened the same circle is what fills in. Drawing it always
    /// means opening one does not make a ring appear from nowhere.
    private let track = CAShapeLayer()
    private let ring = CAShapeLayer()

    private let footer = UIStackView()
    private let mutedIcon = UIImageView()
    private let caption = UILabel()

    private var sideConstraint: NSLayoutConstraint!

    // MARK: - Playback

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var loopsLeft = 0
    private var videoURL: URL?
    /// The id the bubble is currently showing, so a rebuild of the same row is recognised even
    /// when the file has since moved between the plain and the encrypted store.
    private var noteId: String?
    /// Kept so the still can be re-read once the file arrives.
    private var stillId: String?
    /// Stills already asked for this session, so a row being rebuilt over and over does not ask
    /// for the same picture over and over.
    private static var thumbsRequested: Set<String> = []
    private var length: TimeInterval = 0

    /// Where the playable copy really is. Media in this app lives either as a plain file in
    /// Documents or inside the encrypted store, and every other screen checks both - this one only
    /// checked the first. Once a note had been filed away securely the file "did not exist", so
    /// playback fell straight through to settle(): a still, a play button, and nothing that would
    /// ever start. Decrypted once and kept, rather than on every rebuild of the row.
    private var decryptedCache: URL?

    private func playableURL(for videoId: String) -> URL? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let plain = documents.appendingPathComponent(videoId)
        if FileManager.default.fileExists(atPath: plain.path) {
            return plain
        }
        if let cached = decryptedCache, FileManager.default.fileExists(atPath: cached.path) {
            return cached
        }
        guard FileEncryption.shared.isSecureExists(filename: videoId),
              let bytes = try? FileEncryption.shared.readSecure(filename: videoId) else {
            return nil
        }
        let scratch = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoId)
        try? FileManager.default.removeItem(at: scratch)
        guard (try? bytes.write(to: scratch)) != nil else { return nil }
        decryptedCache = scratch
        return scratch
    }

    private func stillImage(for thumbId: String) -> UIImage? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let plain = documents.appendingPathComponent(thumbId)
        if let image = UIImage(contentsOfFile: plain.path) {
            return image
        }
        guard FileEncryption.shared.isSecureExists(filename: thumbId),
              let bytes = try? FileEncryption.shared.readSecure(filename: thumbId) else {
            return nil
        }
        return UIImage(data: bytes)
    }


    /// Set when the app goes away mid-play. iOS pauses a player on the way to the background and
    /// does not start it again on the way back, so without this a note left playing came back
    /// stopped on its first frame and stayed there.
    private var resumeOnReturn = false
    /// True while this note holds the audio route, so it is only given back by whoever took it.
    private var isOpenedAudioSession = false

    /// False on a screen that only shows the note rather than playing it.
    private var isPlayable = true

    /// True while this note is the big one.
    private(set) public var isOpened = false
    /// Catches taps anywhere while a note is open, without taking them from anything else.
    private var outsideTap: UITapGestureRecognizer?

    /// A note that should open itself as soon as a view for it is properly on screen.
    ///
    /// This is the whole of what is needed to survive a rebuild, and it is deliberately not more.
    /// A finished download makes the conversation redraw that row, which throws this view away and
    /// builds another - so opening from inside that rebuild means opening a view that is not on
    /// screen, has no window and no size. Everything that went wrong before came from trying to do
    /// the opening there. The id is left here instead, and the replacement opens itself from
    /// didMoveToWindow: the same conditions a tap would have, on a view that is genuinely ready.

    /// The row's height belongs to the conversation, so it is told rather than changed underneath.
    public var onToggleSize: ((Bool) -> Void)?

    // MARK: - Building

    public override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    deinit {
        detachPlayer()
        NotificationCenter.default.removeObserver(self)
    }

    private func build() {
        backgroundColor = .clear

        addSubview(circle)
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        circle.layer.masksToBounds = true

        still.contentMode = .scaleAspectFill
        still.clipsToBounds = true
        circle.addSubview(still)
        still.translatesAutoresizingMaskIntoConstraints = false

        playerHost.backgroundColor = .clear
        playerHost.isHidden = true
        circle.addSubview(playerHost)
        playerHost.translatesAutoresizingMaskIntoConstraints = false

        // These live outside the circle's own layer: a layer that masks to a circle cannot draw a
        // stroke that sits on its edge.
        track.fillColor = UIColor.clear.cgColor
        track.strokeColor = UIColor.mainColor.withAlphaComponent(0.85).cgColor
        track.lineWidth = VideoNoteBubbleView.trackWidth
        track.strokeEnd = 1
        layer.addSublayer(track)

        ring.fillColor = UIColor.clear.cgColor
        ring.strokeColor = UIColor.mainColor.cgColor
        ring.lineWidth = VideoNoteBubbleView.ringWidth
        ring.lineCap = .round
        ring.strokeEnd = 0
        ring.isHidden = true
        layer.addSublayer(ring)


        playButton.image = UIImage(systemName: "play.fill",
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold))
        playButton.tintColor = .white
        playButton.contentMode = .center
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        playButton.layer.masksToBounds = true
        // Its size is fixed, so its corner radius is too. Rounding it in layoutSubviews read the
        // button's bounds before the circle it lives in had laid out - which is zero, and a corner
        // radius of zero is the square button that turned up on coming back into a conversation.
        playButton.layer.cornerRadius = 23
        circle.addSubview(playButton)
        playButton.translatesAutoresizingMaskIntoConstraints = false

        notDownloadedBlur.isHidden = true
        circle.addSubview(notDownloadedBlur)
        notDownloadedBlur.translatesAutoresizingMaskIntoConstraints = false

        downloadIcon.image = UIImage(systemName: "arrow.down",
                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))
        downloadIcon.tintColor = .white
        downloadIcon.contentMode = .center
        downloadIcon.isHidden = true
        downloadIcon.setContentHuggingPriority(.required, for: .horizontal)

        cancelButton.setImage(UIImage(systemName: "stop.fill",
                                      withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .black))?
                                .withRenderingMode(.alwaysTemplate), for: .normal)
        cancelButton.tintColor = .black
        // A ground of its own, so the control does not depend on the video behind it being dark.
        // White track and white arc over a note of a pale hand on a white wall is a control that is
        // drawn and cannot be seen - which is what "the stop never appeared" turned out to mean.
        cancelButton.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        cancelButton.layer.cornerRadius = VideoNoteBubbleView.cancelSide / 2
        cancelButton.layer.masksToBounds = true
        cancelButton.isHidden = true
        cancelButton.addTarget(self, action: #selector(cancelDownloadTapped), for: .touchUpInside)
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.widthAnchor.constraint(equalToConstant: VideoNoteBubbleView.cancelSide),
            cancelButton.heightAnchor.constraint(equalToConstant: VideoNoteBubbleView.cancelSide)
        ])

        // The paths are built from the size the button is constrained to, not from its bounds.
        //
        // Fix: they were built in layoutSubviews from `cancelButton.bounds`, and this button is a
        // descendant - it sits in a stack view inside the circle - so its frame is not set until
        // after this view has laid out. The width was zero, the `> 0` guard skipped the whole
        // thing, and no path was ever assigned: there was no ring to see, at any percentage. The
        // play button's corner radius and the video layer's frame were both this same mistake.
        let box = CGRect(x: 0, y: 0, width: VideoNoteBubbleView.cancelSide, height: VideoNoteBubbleView.cancelSide)
        let ringPath = UIBezierPath(arcCenter: CGPoint(x: box.midX, y: box.midY),
                                    radius: box.width / 2 - 1.5,
                                    startAngle: -.pi / 2,
                                    endAngle: .pi * 1.5,
                                    clockwise: true).cgPath

        cancelTrack.fillColor = UIColor.clear.cgColor
        // Read against the white disc above, not against the video.
        cancelTrack.strokeColor = UIColor.black.withAlphaComponent(0.18).cgColor
        cancelTrack.lineWidth = 2
        cancelTrack.strokeEnd = 1
        cancelTrack.path = ringPath
        cancelTrack.frame = box
        cancelButton.layer.addSublayer(cancelTrack)

        cancelRing.fillColor = UIColor.clear.cgColor
        cancelRing.strokeColor = UIColor.mainColor.cgColor
        cancelRing.lineWidth = 2.5
        cancelRing.lineCap = .round
        cancelRing.strokeStart = 0
        cancelRing.strokeEnd = 0
        cancelRing.path = ringPath
        // Its frame is the button's box, so the turn is about the middle - where the stop sits.
        cancelRing.frame = box
        cancelButton.layer.addSublayer(cancelRing)

        // The mark and the length ride inside the circle, near its foot, as the reference has them.
        mutedIcon.image = UIImage(systemName: "speaker.slash.fill",
                                  withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))
        mutedIcon.tintColor = .white
        mutedIcon.contentMode = .center
        mutedIcon.setContentHuggingPriority(.required, for: .horizontal)

        caption.font = .systemFont(ofSize: 13, weight: .medium)
        caption.textColor = .white
        caption.textAlignment = .center

        footer.axis = .horizontal
        footer.spacing = 5
        footer.alignment = .center
        footer.addArrangedSubview(downloadIcon)
        footer.addArrangedSubview(cancelButton)
        footer.addArrangedSubview(mutedIcon)
        footer.addArrangedSubview(caption)
        circle.addSubview(footer)
        footer.translatesAutoresizingMaskIntoConstraints = false

        sideConstraint = circle.widthAnchor.constraint(equalToConstant: VideoNoteBubbleView.restingSide)
        NSLayoutConstraint.activate([
            circle.topAnchor.constraint(equalTo: topAnchor),
            circle.bottomAnchor.constraint(equalTo: bottomAnchor),
            circle.leadingAnchor.constraint(equalTo: leadingAnchor),
            circle.trailingAnchor.constraint(equalTo: trailingAnchor),
            sideConstraint,
            circle.heightAnchor.constraint(equalTo: circle.widthAnchor),

            still.topAnchor.constraint(equalTo: circle.topAnchor),
            still.bottomAnchor.constraint(equalTo: circle.bottomAnchor),
            still.leadingAnchor.constraint(equalTo: circle.leadingAnchor),
            still.trailingAnchor.constraint(equalTo: circle.trailingAnchor),

            playerHost.topAnchor.constraint(equalTo: circle.topAnchor),
            playerHost.bottomAnchor.constraint(equalTo: circle.bottomAnchor),
            playerHost.leadingAnchor.constraint(equalTo: circle.leadingAnchor),
            playerHost.trailingAnchor.constraint(equalTo: circle.trailingAnchor),

            notDownloadedBlur.topAnchor.constraint(equalTo: circle.topAnchor),
            notDownloadedBlur.bottomAnchor.constraint(equalTo: circle.bottomAnchor),
            notDownloadedBlur.leadingAnchor.constraint(equalTo: circle.leadingAnchor),
            notDownloadedBlur.trailingAnchor.constraint(equalTo: circle.trailingAnchor),

            playButton.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 46),
            playButton.heightAnchor.constraint(equalToConstant: 46),

            footer.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            footer.bottomAnchor.constraint(equalTo: circle.bottomAnchor, constant: -8)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true

        // Registered once, for the life of the view: both the note and its still arrive this way,
        // and the still arrives without anybody having asked for it by hand.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(downloadMoved(_:)),
                                               name: Download.progressNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(uploadMoved(_:)),
                                               name: NSNotification.Name(rawValue: "onUploadChat"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appLeaving),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appReturned),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window == nil else {
            // On screen at last. A note that was opened before it had anywhere to be opened can
            // now raise its pane, take the audio route and start playing.
            return
        }
        // Off the screen, by a swipe back or by scrolling away. A note that carries on playing to
        // nobody - with sound, if it had been opened - is the app talking over whatever the reader
        // moved on to. Everything stops, and the audio route is handed back.
        resumeOnReturn = false
        detachPlayer()
        releaseAudioRoute()
    }

    private func releaseAudioRoute() {
        guard isOpenedAudioSession else { return }
        isOpenedAudioSession = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let radius = circle.bounds.width / 2
        circle.layer.cornerRadius = radius

        // Just outside the circle, opening from twelve o'clock like the recorder's. All three run
        // the same circle, which is the point: the border and the progress are one path.
        let centre = CGPoint(x: circle.frame.midX, y: circle.frame.midY)
        // On the circle's own edge rather than floating outside it - the border and the video are
        // meant to read as one thing.
        let path = UIBezierPath(arcCenter: centre,
                                radius: radius,
                                startAngle: -.pi / 2,
                                endAngle: .pi * 1.5,
                                clockwise: true)
        track.path = path.cgPath
        ring.path = path.cgPath
    }

    // MARK: - Filling it in

    /// Everything the bubble needs. Called on every rebuild of the row, so it has to be cheap when
    /// nothing has changed - a note already playing is left playing rather than started over.
    public func configure(videoId: String, thumbId: String, state: State) {
        let sameNote = (noteId == videoId)

        if !sameNote {
            detachPlayer()
            noteId = videoId
            stillId = thumbId
            decryptedCache = nil
            videoURL = playableURL(for: videoId)
                sideConstraint.constant = VideoNoteBubbleView.restingSide
            still.image = stillImage(for: thumbId)
            fetchStillIfMissing(thumbId)
            length = videoURL.map { url in
                let seconds = CMTimeGetSeconds(AVURLAsset(url: url).duration)
                return seconds.isFinite ? seconds : 0
            } ?? 0
            // The bubble has the file open anyway; telling the store means the chat list and the
            // quote lines get the length without going looking for it themselves.
            VideoNote.remember(seconds: length, forVideoId: videoId)
        } else if videoURL == nil {
            // It was not there when the row was last built - an upload still running, or a file
            // only just filed away. Worth another look rather than staying broken for good.
            videoURL = playableURL(for: videoId)
            if let url = videoURL {
                let seconds = CMTimeGetSeconds(AVURLAsset(url: url).duration)
                length = seconds.isFinite ? seconds : 0
                VideoNote.remember(seconds: length, forVideoId: videoId)
            }
        }

        switch state {
        case .preview:
            isPlayable = false
        default:
            isPlayable = true
        }

        switch state {
        case .sending:
            // On its way out. The same control the download wears, for the same reason: a ring
            // round a stop reads as "this is moving, and it could be stopped", where a bare arc
            // over the picture only reads as "wait".
            notDownloadedBlur.isHidden = true
            downloadIcon.isHidden = true
            detachPlayer()
            playerHost.isHidden = true
            playButton.isHidden = true
            mutedIcon.isHidden = true
            footer.isHidden = false
            track.isHidden = false
            ring.isHidden = true
            still.alpha = 0.55
            caption.text = ""
            cancelButton.isUserInteractionEnabled = true
            controlStandsFor = .sending
            startCancelControl()
            // Nothing is guaranteed to redraw this row once the send lands - the second attempt
            // finishes so fast the status has already moved on before the row is rebuilt at all.
            // So the note settles itself: once the send is neither marked nor in flight, it goes
            // back to being an ordinary note. Reusing configure means there is one description of
            // what "delivered" looks like, not two.
            settleAfterSending(videoId: videoId, thumbId: thumbId)

        case .preview:
            // No player at all: nothing to start, nothing to leave running when the screen goes.
            notDownloadedBlur.isHidden = (videoURL != nil)
            downloadIcon.isHidden = true
            stopCancelControl()
            detachPlayer()
            footer.isHidden = false
            track.isHidden = false
            ring.isHidden = true
            mutedIcon.isHidden = true
            playButton.isHidden = true
            playerHost.isHidden = true
            caption.text = VideoNote.clockLength(length)

        case .delivered where videoURL == nil:
            cancelButton.isUserInteractionEnabled = true
            still.alpha = 1
            // Here as a message, but the file itself has not been fetched. Blurred, because the
            // still says what the note is rather than being something to watch, and the line
            // underneath says how big the download would be instead of how long it runs.
            detachPlayer()
            footer.isHidden = false
            track.isHidden = false
            ring.isHidden = true
            mutedIcon.isHidden = true
            playButton.isHidden = true
            playerHost.isHidden = true
            notDownloadedBlur.isHidden = false
            // Fix: this drew the offer - arrow and size - whether or not the file was already on
            // its way, and the row is drawn again the moment a transfer starts. So the control the
            // reader had just raised was replaced by the arrow within a frame or two, and the
            // progress that arrived afterwards had nothing left to draw into: the ring never came
            // back and the file landed with no sign it had ever been asked for. A download belongs
            // to the note, not to the view that happened to start it, so the view asks who is
            // running rather than trusting what it remembers.
            if Download.isDownloading(forKey: videoId) {
                controlStandsFor = .downloading
                downloadIcon.isHidden = true
                // The size answered "how big is this"; that question has been asked and answered.
                caption.text = ""
                startCancelControl()
                showTransferProgress(Download.progress(forKey: videoId) ?? 0)
            } else {
                // The arrow sits where the length would be, with the size beside it - one line
                // saying what this is and what fetching it would cost.
                downloadIcon.isHidden = false
                stopCancelControl()
                showNotDownloadedSize(for: videoId)
            }

        case .delivered:
            cancelButton.isUserInteractionEnabled = true
            still.alpha = 1
            notDownloadedBlur.isHidden = true
            downloadIcon.isHidden = true
            stopCancelControl()
            footer.isHidden = false
            track.isHidden = false
            // Muted is what a note in the conversation is - the mark goes away only when one is
            // opened and given sound.
            mutedIcon.isHidden = false
            caption.text = VideoNote.clockLength(length)
            guard !sameNote || player == nil else { return }
            // Fresh in front of the reader: the reference plays it three times and then rests.
            loopsLeft = VideoNoteBubbleView.autoPlayLoops
            startPlaying(muted: true, showRing: false)
        }
    }

    /// The picture under a note is a few kilobytes and is wanted the moment the note stops
    /// playing - which is before anybody would think to ask for it. So it is fetched by itself,
    /// quietly, rather than leaving a blank circle where the still should be.
    private func fetchStillIfMissing(_ thumbId: String) {
        guard !thumbId.isEmpty, still.image == nil else { return }
        guard !VideoNoteBubbleView.thumbsRequested.contains(thumbId) else { return }
        guard !Download.isDownloading(forKey: thumbId) else { return }
        VideoNoteBubbleView.thumbsRequested.insert(thumbId)
        Download().startHTTP(forKey: thumbId) { _, _ in }
    }

    /// How big the download would be, from whatever knows: what the sender said, what is on this
    /// device, or - failing both - what the server says when asked without fetching anything.
    private func showNotDownloadedSize(for videoId: String) {
        var bytes = VideoNote.Facts.of(attachmentNamed: videoId).bytes
        if bytes == 0 {
            bytes = VideoNote.Facts.measuredSize(ofAttachmentNamed: videoId)
        }
        if bytes == 0 {
            bytes = Download.knownRemoteSize(forKey: videoId) ?? 0
        }
        caption.text = VideoNote.Facts.humanSize(bytes)
        guard bytes == 0 else { return }
        Download.remoteSize(forKey: videoId) { [weak self] size in
            // The blur is still up while a download runs, so that alone does not say the offer is
            // still on screen - the control does. Without this, an answer that took longer than
            // the reader did wrote a file size over the progress of the download they had started.
            guard let self = self, self.noteId == videoId,
                  !self.notDownloadedBlur.isHidden, self.cancelButton.isHidden else { return }
            self.caption.text = VideoNote.Facts.humanSize(size)
        }
    }

    /// Turning while there is nothing to draw, then tracing the ring once there is.
    /// What the stop control is standing for.
    ///
    /// Fix: which transfer to cancel was worked out from `Network.isUploading` at the instant of
    /// the tap. Stop a send and start it again quickly enough and that answer is no - the upload
    /// has finished, or has not begun - so the tap fell through to the download path, which put a
    /// download arrow and a file size under a note the reader had just recorded themselves. The
    /// control knows what it was raised for; it does not need to ask the network.
    private enum Transfer { case sending, downloading }
    private var controlStandsFor: Transfer = .downloading

    /// When the stop control went up, so a download that finishes in a blink still shows it.
    private var cancelShownAt: Date?
    /// The least time the control stays on screen.
    ///
    /// This is not a cosmetic delay. A second send finishes almost the moment it is asked for -
    /// the file is already on the server - so the row is rebuilt as delivered straight away and
    /// the control is taken down again. The trace showed exactly that: raised, then lowered, with
    /// nothing wrong in between. Under a second is long enough to notice something flickered and
    /// far too short to reach for it, and this control exists to be pressed. Two seconds is the
    /// smallest window in which stopping a send is actually a thing the reader can do.
    private static let cancelMinimumOnScreen: TimeInterval = 2.0

    /// Leaving the screen ends this view's business with the note.
    ///
    /// The bubble is built fresh every time the row is drawn, so a detached one is always a view
    /// the reader has already stopped looking at. It keeps its buttons, its observers and its
    /// pending touches until it is released; none of them should reach the conversation.
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        // Only on the way out. Adding a bubble to a cell the table has not put on screen yet is
        // also a move to no window, and that one is a view about to be used, not finished with.
        guard newWindow == nil, window != nil else { return }
        cancelButton.isUserInteractionEnabled = false
        onCancelSend = nil
        onRequestDownload = nil
    }

    private func startCancelControl() {
        cancelShownAt = Date()
        controlRaisedAt = Date()
        cancelButton.isHidden = false
        cancelTrack.isHidden = false
        // A quarter of the circle, going round: there is nothing to measure yet, and a still ring
        // reads as stuck.
        cancelRing.strokeEnd = 0.25
        guard cancelRing.animation(forKey: "turn") == nil else { return }
        let turn = CABasicAnimation(keyPath: "transform.rotation.z")
        turn.fromValue = 0
        turn.toValue = CGFloat.pi * 2
        turn.duration = 1.1
        turn.repeatCount = .infinity
        turn.isRemovedOnCompletion = false
        cancelRing.add(turn, forKey: "turn")
    }

    private func stopCancelControl() {
        // Fix: this took the control down the instant the state moved on, and a send whose file is
        // already on the server finishes in a blink - the row is rebuilt as delivered almost at
        // once, so the stop and its ring were put up and taken away inside a frame or two. Nothing
        // to see, which is exactly what "it never appeared" meant. The download path already had
        // this guarantee; the send path never got it.
        guard !cancelButton.isHidden else {
            hideCancelControl()
            return
        }
        let shown = cancelShownAt.map { Date().timeIntervalSince($0) } ?? .greatestFiniteMagnitude
        let owed = VideoNoteBubbleView.cancelMinimumOnScreen - shown
        guard owed > 0 else {
            hideCancelControl()
            return
        }
        cancelRing.removeAnimation(forKey: "turn")
        cancelRing.strokeEnd = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + owed) { [weak self] in
            self?.hideCancelControl()
        }
    }

    private func settleAfterSending(videoId: String, thumbId: String) {
        let wait = VideoNoteBubbleView.cancelMinimumOnScreen + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in
            guard let self = self, self.noteId == videoId, !self.cancelButton.isHidden else { return }
            guard !Network.isUploading(name: videoId), !VideoNote.isSending(videoId: videoId) else {
                // Still going: look again rather than cutting it short.
                self.settleAfterSending(videoId: videoId, thumbId: thumbId)
                return
            }
            self.configure(videoId: videoId, thumbId: thumbId, state: .delivered)
        }
    }

    private func hideCancelControl() {
        cancelShownAt = nil
        cancelRing.removeAnimation(forKey: "turn")
        cancelButton.isHidden = true
        cancelTrack.isHidden = true
        cancelRing.strokeEnd = 0
    }

    /// The arc turns while the transfer is in its first quarter - there is a quarter of a circle
    /// to draw and no more, and a still quarter reads as stuck. Past that there is enough to
    /// measure, so it stops turning and simply grows to the end.
    private func showTransferProgress(_ percent: Double) {
        guard !cancelButton.isHidden else { return }
        let fraction = CGFloat(min(max(percent, 0) / 100, 1))
        if fraction < 0.25 {
            cancelRing.strokeEnd = 0.25
            return
        }
        cancelRing.removeAnimation(forKey: "turn")
        cancelRing.strokeEnd = fraction
    }

    @objc private func uploadMoved(_ notification: Notification) {
        guard let id = noteId,
              let name = notification.userInfo?["name"] as? String, name == id else {
            return
        }
        let progress = notification.userInfo?["progress"] as? Double ?? 0

        // This only moves a control that is already up. It must never raise one.
        //
        // It did, for a while, to cover a send too quick for the row's rebuild to catch - and the
        // trace written into the bubble showed what that cost: after a cancel the row was rebuilt
        // as delivered and the control hidden (cfgD>h), and then a late report from the transfer
        // winding down raised it again (>U) with nothing left to take it down. Two guards were
        // added and neither held, because the question "is something still in flight" has no
        // stable answer in the moment a transfer is being torn down.
        //
        // The same trace also showed the rebuild does hit the sending state on Send again
        // (cfgS>S). There was no window to cover. Deciding visibility in one place - configure -
        // is what makes this answerable at all.
        showTransferProgress(progress)
    }

    /// Asked to stop a send. What it means for the message - that it is now one that never left -
    /// belongs to the conversation, so it is told rather than decided here.
    public var onCancelSend: (() -> Void)?

    /// How long a freshly shown control ignores taps.
    ///
    /// A control that appears under a finger must not act on a touch that was never aimed at it.
    /// The trace caught exactly that: configured, raised, and its own action fired inside the same
    /// quarter second - far quicker than anyone can reach for a 24pt target that did not exist a
    /// moment earlier. It cancelled a send nobody asked to cancel, and because it happened while
    /// the row was still being built the cancellation had nowhere to go, so the note carried on
    /// and was sent. This is the standard guard for a control that materialises mid-interaction.
    private static let cancelIgnoresTapsFor: TimeInterval = 0.4
    /// When the control last went up. Unlike `cancelShownAt` this is never put back to nil, so a
    /// stray action cannot slip past the guard by arriving after something cleared that one.
    private var controlRaisedAt = Date.distantPast

    @objc private func cancelDownloadTapped() {
        guard let id = noteId else { return }
        // Fix: the stop answered for the note even after its view had been taken off the screen.
        // Rebuilding a row empties the cell and builds a new bubble into it, and the old one is
        // not gone the instant it is detached - it lives to the end of the run loop, still holding
        // whatever touch was on it. Its stop then reported a cancelled send against a note the
        // reader was, by then, watching a different view of: the control appeared and vanished
        // inside one frame, which is what "the second stop never shows up" was. A view that is not
        // in front of the reader is not the view that speaks for the note.
        guard window != nil else { return }
        // On the way out rather than in: stop the bytes, and let the conversation record what that
        // makes of the message.
        if controlStandsFor == .sending {
            // The window below belongs to sending alone. On a download the control appears under
            // the very finger that just tapped the note to fetch it, so a reader reaching for stop
            // is reaching inside those four-tenths of a second and their first press was swallowed
            // every time - stopping a download took two taps. Nothing raises this control under a
            // finger on the way out: the send begins somewhere else entirely.
            if Date().timeIntervalSince(controlRaisedAt) < VideoNoteBubbleView.cancelIgnoresTapsFor {
                return
            }
            // On the way out: stop the bytes, and let the conversation record what that makes of
            // the message. A note of our own never falls back to offering a download of itself.
            Network.cancelUpload(name: id)
            // Said plainly, so no late report from the transfer winding down can bring this
            // control back up.
            VideoNote.markStopped(videoId: id)
            // Straight down, not held: the hold exists so a transfer too quick to see is still
            // seen, and this one has just been stopped by hand. Holding a stop button over a
            // message that already reads as failed is the control outliving its own meaning.
            hideCancelControl()
            onCancelSend?()
            return
        }
        Download.cancel(forKey: id)
        // Fix: this held the control for the rest of its two seconds on screen, and the arrow was
        // put back underneath it at the same time - a stop button and a full ring sitting on top
        // of the offer they had just cancelled. Worse, `tapped` refuses to act while the control
        // is up, so asking for the file again did nothing at all until the hold ran out. The hold
        // is there so a transfer too quick to see is still seen; a stop by hand has been seen.
        hideCancelControl()
        // Back to the offer: the arrow, and how big it would be.
        downloadIcon.isHidden = false
        showNotDownloadedSize(for: id)
    }

    @objc private func downloadMoved(_ notification: Notification) {
        guard let name = notification.userInfo?["name"] as? String else { return }

        // The still landing: put it up wherever the note happens to be, and nothing else changes.
        if name == stillId {
            let progress = notification.userInfo?["progress"] as? Double ?? 0
            if progress < 0 {
                // Worth another go later rather than never again.
                VideoNoteBubbleView.thumbsRequested.remove(name)
                return
            }
            guard progress >= 100 else { return }
            still.image = stillImage(for: name)
            return
        }

        guard let id = noteId, name == id else {
            return
        }
        let progress = notification.userInfo?["progress"] as? Double ?? 0
        if progress < 0 {
            // It failed, or the reader stopped it. Straight back to the arrow, so it can be asked
            // for again at once - there is nothing left for the control to report.
            hideCancelControl()
            downloadIcon.isHidden = false
            showNotDownloadedSize(for: id)
            return
        }
        guard progress >= 100 else {
            showTransferProgress(progress)
            return
        }
        // The hold that keeps a blink-quick transfer visible lives in stopCancelControl now, so
        // this only has to wait for it before moving on.
        let shown = cancelShownAt.map { Date().timeIntervalSince($0) } ?? .greatestFiniteMagnitude
        let owed = VideoNoteBubbleView.cancelMinimumOnScreen - shown
        if owed > 0 {
            cancelRing.strokeEnd = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + owed) { [weak self] in
                guard let self = self, self.noteId == id else { return }
                self.finishDownload(id: id)
            }
            return
        }
        finishDownload(id: id)
    }

    private func finishDownload(id: String) {
        stopCancelControl()
        notDownloadedBlur.isHidden = true
        downloadIcon.isHidden = true
        // The file is here now; everything the note could not do a moment ago it can do.
        videoURL = playableURL(for: id)
        if let url = videoURL {
            let seconds = CMTimeGetSeconds(AVURLAsset(url: url).duration)
            length = seconds.isFinite ? seconds : 0
            VideoNote.remember(seconds: length, forVideoId: id)
        }
        still.image = stillId.flatMap { stillImage(for: $0) } ?? still.image
        caption.text = VideoNote.clockLength(length)
        mutedIcon.isHidden = false
        // Nothing clever on arrival: the note becomes an ordinary note. The conversation reloads
        // this row for the same reason anyway, and whichever view ends up on screen plays it the
        // way any note plays - quietly, three times over. Opening it from here meant opening a
        // view that was about to be thrown away, which was never going to work.
        loopsLeft = VideoNoteBubbleView.autoPlayLoops
        startPlaying(muted: true, showRing: false)
    }

    @objc private func appLeaving() {
        resumeOnReturn = (player?.timeControlStatus == .playing)
    }

    @objc private func appReturned() {
        // Only if it was actually running when the app went away, and only if this note is still
        // on screen - a cell scrolled off in the meantime has no business starting up again.
        guard resumeOnReturn, window != nil else { return }
        resumeOnReturn = false
        player?.play()
        playButton.isHidden = true
    }

    // MARK: - While it is going out

    // MARK: - Playing

    private func startPlaying(muted: Bool, showRing: Bool) {
        guard let url = videoURL ?? noteId.flatMap({ playableURL(for: $0) }) else {
            settle()
            return
        }
        videoURL = url
        if player == nil {
            let item = AVPlayer(url: url)
            // Never waits: this is a few seconds of local video, and waiting to minimise stalling
            // is what leaves an autoplay sitting there having never started.
            item.automaticallyWaitsToMinimizeStalling = false
            playerHost.playerLayer.videoGravity = .resizeAspectFill
            playerHost.playerLayer.player = item
            player = item
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(reachedEnd),
                                                   name: .AVPlayerItemDidPlayToEndTime,
                                                   object: item.currentItem)
            let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserver = item.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                self?.playheadMoved(to: CMTimeGetSeconds(time))
            }
        }
        player?.isMuted = muted
        // Seek first, then play from the callback: a seek asked of a player that is not ready yet
        // is simply dropped, and a play() racing it can end up neither at the start nor moving.
        player?.seek(to: .zero) { [weak self] _ in
            self?.player?.play()
        }
        player?.play()
        playerHost.isHidden = false
        playButton.isHidden = true
        ring.isHidden = !showRing
        if showRing {
            ring.strokeEnd = 0
        }
    }

    private func playheadMoved(to played: Double) {
        guard played.isFinite, length > 0, isOpened else { return }
        // The last observation lands a frame short of the end, so anything inside the last
        // twentieth of a second closes the ring rather than leaving a visible gap in it.
        let remaining = length - played
        ring.strokeEnd = remaining < 0.05 ? 1 : CGFloat(min(played / length, 1))
        caption.text = VideoNote.clock(played)
    }

    @objc private func reachedEnd() {
        // Opened by hand: one run through with sound, then it shrinks back and carries on the way
        // it sits in the conversation - quietly, three times over. Without this it ran out its one
        // loop and settled on a play button, still at full size.
        if isOpened {
            close()
            return
        }
        loopsLeft -= 1
        guard loopsLeft > 0 else {
            settle()
            return
        }
        player?.seek(to: .zero)
        player?.play()
    }

    /// Back to the still with a play button on it - what the note looks like when nothing is
    /// happening to it.
    private func settle() {
        player?.pause()
        // Back to the still with a play button over it - and the border stays, because the border
        // is what the circle looks like, not something playback puts there.
        playerHost.isHidden = true
        playButton.isHidden = false
        ring.isHidden = true
        ring.strokeEnd = 0
        track.isHidden = false
        caption.text = VideoNote.clockLength(length)
    }

    private func detachPlayer() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        player?.pause()
        playerHost.playerLayer.player = nil
        player = nil
    }

    // MARK: - Opening and closing

    /// Reported after a note has been asked for, so a conversation can refresh the row if it
    /// wants to. The fetching itself is done here - see `tapped`.
    public var onRequestDownload: ((String) -> Void)?

    @objc private func tapped() {
        // While a download is running the only control that means anything is the stop button, and
        // it has its own touches - nothing here should act on a tap meant for it.
        if !cancelButton.isHidden {
            return
        }
        // Not here yet: the tap is a request for it, and the ring turns until it lands.
        if !notDownloadedBlur.isHidden {
            guard let id = noteId else { return }
            // The reference turns a small spinner where the size is, not a ring round the circle -
            // there is no progress to trace out, only waiting to show.
            downloadIcon.isHidden = true
            controlStandsFor = .downloading
            startCancelControl()
            // The size answered "how big is this"; the reader has stopped asking that and started
            // waiting. One thing at a time on that line.
            caption.text = ""
            // Fix: this only ever turned the arc and told whoever was listening. Nobody was
            // listening, so nothing was ever fetched and the arc turned for good. The same
            // fetcher the rest of the app uses is started here, and the note watches for it to
            // land rather than waiting to be told.
            if !Download.isDownloading(forKey: id) {
                Download().startHTTP(forKey: id) { _, _ in }
            }
            onRequestDownload?(id)
            return
        }
        guard isPlayable else { return }
        // Fix: pausing was left to the recogniser on the window, and it never worked. This one -
        // the view's own - is the recogniser that opens a note in the first place, so it plainly
        // reaches this view. A tap on the circle is handled where taps on the circle already
        // arrive; the window's recogniser is left with the one thing this cannot hear, which is a
        // tap somewhere else entirely.
        if isOpened {
            togglePause()
            return
        }
        open()
    }

    // MARK: - While it is open

    /// Grows the circle where it stands, plays it with sound, and traces the ring round it.
    ///
    /// Only ever called on a view that is on screen. That is the whole lesson of the bugs before
    /// this: the conversation rebuilds this row when a download lands, and opening from inside
    /// that rebuild meant opening a view with no window, no size and no place in the table - which
    /// is what left the circle small, the picture frozen and the tap dead.
    private func open() {
        guard !isOpened, window != nil else { return }
        isOpened = true

        // Sound is the reason a note gets opened, and it will not have any if the session is left
        // wherever the last recording or call put it.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])
        isOpenedAudioSession = true

        raiseShield()
        sideConstraint.constant = VideoNoteBubbleView.openedSide
        onToggleSize?(true)
        UIView.animate(withDuration: 0.25) {
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
        }
        mutedIcon.isHidden = true
        loopsLeft = 1
        startPlaying(muted: false, showRing: true)
    }

    private func close() {
        guard isOpened else { return }
        isOpened = false
        dropShield()
        releaseAudioRoute()
        sideConstraint.constant = VideoNoteBubbleView.restingSide
        onToggleSize?(false)
        UIView.animate(withDuration: 0.25) {
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
        }
        mutedIcon.isHidden = false
        ring.isHidden = true
        ring.strokeEnd = 0
        caption.text = VideoNote.clockLength(length)
        // Back to how it sits in the conversation: playing itself quietly, three times over.
        loopsLeft = VideoNoteBubbleView.autoPlayLoops
        startPlaying(muted: true, showRing: false)
    }

    /// Hears taps anywhere while a note is open, and decides by where they landed: on the circle
    /// is pause and carry on, anywhere else is put it away.
    ///
    /// A recogniser on the window rather than a view over it: a view swallows every touch it
    /// covers, which left the back button, the swipe back and the conversation's own scrolling all
    /// dead while a note was open.
    private func raiseShield() {
        guard outsideTap == nil, let window = self.window else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(shieldTapped(_:)))
        tap.cancelsTouchesInView = false
        tap.delaysTouchesBegan = false
        tap.delaysTouchesEnded = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
        outsideTap = tap
    }

    private func dropShield() {
        if let tap = outsideTap {
            tap.view?.removeGestureRecognizer(tap)
        }
        outsideTap = nil
    }

    @objc private func shieldTapped(_ gesture: UITapGestureRecognizer) {
        guard let pane = gesture.view else { return }
        let point = gesture.location(in: pane)
        // Fix: this worked "inside or outside" out from the circle's centre and radius, and when
        // it got that wrong both recognisers acted on the same tap - the view's own paused it,
        // this one closed it, and closing restarts the quiet loop. What the reader saw was a tap
        // that made the note start over.
        //
        // Asking who was actually touched cannot disagree with itself: if the touch landed on this
        // note, the note's own tap has it and there is nothing here to do.
        if let touched = pane.hitTest(point, with: nil),
           touched === self || touched.isDescendant(of: self) {
            return
        }
        close()
    }

    /// Everything else on screen keeps working while a note is open - the back swipe most of all.
    /// Everything except this note's own tap: those two seeing the same tap is what let one pause
    /// it while the other closed it.
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        return other.view !== self
    }

    private func togglePause() {
        guard let player = player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            playButton.isHidden = false
        } else {
            player.play()
            playButton.isHidden = true
        }
    }

}
