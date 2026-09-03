//
//  VideoNoteComposer.swift
//  NexilisLite
//
//  The screen for recording a round video note, built to match the reference recording:
//  press and hold the camera in the input bar, slide up to lock, slide left to cancel, then
//  review what was taken before sending it.
//
//  This is the making of one. What the finished note looks like in a bubble, and how it is sent,
//  are deliberately not here: `onFinish` hands over a file and its length and stops there.
//

import UIKit
import AVFoundation
import ObjectiveC

public final class VideoNoteComposer: UIView {

    // MARK: - Handing back

    /// Recording finished and the reader asked to send it: the file, and how many seconds it runs.
    public var onFinish: ((URL, Int) -> Void)?
    /// Nothing is being sent - thrown away, slid to cancel, or refused for want of permission.
    public var onCancel: (() -> Void)?

    /// The reference stops at a minute, and so does this.
    public static let maximumDuration: TimeInterval = 60
    /// Shorter than this and there is nothing worth sending - the reader has tapped, not held.
    private static let minimumDuration: TimeInterval = 1.0

    // MARK: - Where the interaction has got to

    private enum Stage {
        /// The finger is still down; letting go finishes, sliding up locks, sliding left cancels.
        case holding
        /// The finger is gone and the recording carries on by itself.
        case locked
        /// Recording is over; what was taken can be played back, thrown away or sent.
        case review
    }

    private var stage: Stage = .holding {
        didSet { applyStage() }
    }

    // MARK: - Capture

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "io.nexilis.videonote.session")
    private let output = AVCaptureMovieFileOutput()
    /// Not used for anything that is recorded - it is here to answer one question the session
    /// cannot: has the camera actually started handing over pictures? A fixed wait was a guess,
    /// and a guess that is short by a frame is a note that opens on black.
    private let probe = AVCaptureVideoDataOutput()
    private let probeQueue = DispatchQueue(label: "io.nexilis.videonote.probe")
    private var sawFirstFrame = false
    private var videoInput: AVCaptureDeviceInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var usingFrontCamera = true

    private var fileURL: URL?
    /// Each stretch of recording between one camera and the next.
    ///
    /// A movie file output cannot survive its session being reconfigured - swapping the camera
    /// ends the take, which is why turning the lens round used to close the whole screen. So a
    /// flip closes one file and opens another, and the pieces are joined back into one note. The
    /// voice recorder in this app already works this way for the same reason.
    private var segments: [URL] = []
    /// Set across the moment a flip is closing one segment and opening the next, so the delegate
    /// knows the recording ending is a step rather than the end.
    private var isFlipping = false
    /// Seconds banked from the segments already closed.
    private var bankedTime: TimeInterval = 0
    /// The finished note - one segment, or all of them joined - for the still and for playback.
    private var reviewAsset: AVAsset?
    /// True only once frames are actually going into a file. The camera needs a moment after the
    /// session starts before it hands over anything, and recording through that moment is what put
    /// a black lead-in at the front of every note.
    private var isCapturing = false
    /// The longest the first frame is waited for before recording starts anyway. Only a backstop:
    /// in practice the camera answers in a fraction of this.
    private static let warmUpLimit: TimeInterval = 2.0
    private var startedAt: Date?
    private var elapsed: TimeInterval = 0
    private var ticker: Timer?

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    /// The buzz that says the note has been thrown away. A different shape from the impact that
    /// starts a recording, on purpose: one is "this began", the other "this is gone", and they
    /// should not feel like the same event.
    ///
    /// Fix: this was `UINotificationFeedbackGenerator`'s `.warning`, which is a two-tap pattern and
    /// read as too slight against the reference. The system presets are fixed shapes - `.warning`
    /// and `.success` are two taps, `.error` a longer burst - and none of them is three, so the
    /// three are struck here instead. Being written out also means the count, the spacing and the
    /// weight are all things that can be tuned by hand.
    private static let cancelTaps = 3
    private static let cancelTapGap: TimeInterval = 0.07

    /// Rigid rather than medium: short and crisp, so three of them read as three taps rather than
    /// as one long rumble.
    private static func playCancelHaptic() {
        // The generator is held by the closures below rather than by the view, so the last tap
        // still lands after the screen has been taken away - the dismissal is quicker than the
        // pattern is long.
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        for index in 0..<cancelTaps {
            let delay = Double(index) * cancelTapGap
            if delay == 0 {
                generator.impactOccurred()
                continue
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                generator.impactOccurred()
            }
        }
    }

    /// Set once the screen is finished with. Permission and session setup run off the main thread,
    /// so a reader who lets go before the camera is ready would otherwise have a recording start
    /// on a screen that is already gone.
    private var isFinished = false
    /// Send was pressed while the file was still being written. A movie file is closed
    /// asynchronously, so handing over the URL there and then hands over a partial file - it is
    /// handed over from the delegate below instead, once the file is actually complete.
    private var sendWhenClosed = false
    private var pendingSeconds = 0

    /// The camera glyph at the foot of the lock track, where the finger already is.
    private let lockCamera = UIImageView()

    /// A frame from the middle of what was just recorded. Shown the moment recording stops, so the
    /// camera can be shut down there and then instead of being left running behind a screen that
    /// is no longer recording anything.
    private let still = UIImageView()

    /// Watches playback so the clock and the ring can follow it.
    private var playbackObserver: Any?
    /// How long the finished recording runs, for the clock to sit at while nothing is playing.
    private var recordedLength: TimeInterval = 0

    // MARK: - Views

    // Thin rather than thick, and barely dimmed: the reference leaves the conversation clearly
    // readable behind the recording - shapes, colours and all - rather than hiding it.
    private let backdrop = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let dim = UIView()

    /// The round window the camera is seen through. Everything about a video note is this circle.
    private let circle = UIView()
    private let progress = CAShapeLayer()
    private let playOverlay = UIImageView()

    private let closeButton = UIButton(type: .system)
    private let timeLabel = PaddedLabel()

    /// Only while the finger is down.
    private let slideLabel = UILabel()
    private let lockTrack = UIView()
    private let lockIcon = UIImageView()

    private let flipButton = UIButton(type: .system)

    /// Only once the recording runs on its own.
    private let bottomBar = UIView()
    private let binButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)

    private var circleDiameter: NSLayoutConstraint!
    private var lockTrackBottom: NSLayoutConstraint!
    private var lockTrackCenterX: NSLayoutConstraint!

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
        ticker?.invalidate()
        if let observer = playbackObserver {
            player?.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
        // The session holds the camera open; leaving it running is a light on the reader's phone
        // for a screen that is no longer there.
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func build() {
        backgroundColor = .clear

        addSubview(backdrop)
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dim)
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.12)
        dim.translatesAutoresizingMaskIntoConstraints = false

        // --- the round window -------------------------------------------------------------
        addSubview(circle)
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        circle.layer.masksToBounds = true

        // The arc sits just outside the circle, so it is drawn on this view rather than on the
        // circle itself - a layer that masks to a circle cannot draw anything beyond it.
        progress.fillColor = UIColor.clear.cgColor
        progress.strokeColor = UIColor.white.withAlphaComponent(0.85).cgColor
        progress.lineWidth = 4
        progress.lineCap = .round
        progress.strokeEnd = 0
        layer.addSublayer(progress)

        still.contentMode = .scaleAspectFill
        still.clipsToBounds = true
        still.isHidden = true
        circle.addSubview(still)
        still.translatesAutoresizingMaskIntoConstraints = false

        playOverlay.image = UIImage(systemName: "play.circle.fill",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 54, weight: .regular))
        playOverlay.tintColor = UIColor.white.withAlphaComponent(0.85)
        playOverlay.contentMode = .center
        playOverlay.isHidden = true
        addSubview(playOverlay)
        playOverlay.translatesAutoresizingMaskIntoConstraints = false

        // --- top row ----------------------------------------------------------------------
        closeButton.setImage(UIImage(systemName: "xmark",
                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(discardTapped), for: .touchUpInside)
        closeButton.isHidden = true
        addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.font = .systemFont(ofSize: 17, weight: .regular)
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center
        timeLabel.text = "00:00"
        timeLabel.layer.cornerRadius = 4
        timeLabel.layer.masksToBounds = true
        addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        // --- the hold-only furniture ------------------------------------------------------
        slideLabel.text = "Slide to cancel".localized() + " ‹"
        slideLabel.font = .systemFont(ofSize: 15)
        slideLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        slideLabel.textAlignment = .center
        addSubview(slideLabel)
        slideLabel.translatesAutoresizingMaskIntoConstraints = false

        lockTrack.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        lockTrack.layer.cornerRadius = 21
        lockTrack.layer.masksToBounds = true
        addSubview(lockTrack)
        lockTrack.translatesAutoresizingMaskIntoConstraints = false

        lockIcon.image = UIImage(systemName: "lock.open.fill",
                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium))
        lockIcon.tintColor = UIColor.white.withAlphaComponent(0.8)
        lockIcon.contentMode = .center
        lockTrack.addSubview(lockIcon)
        lockIcon.translatesAutoresizingMaskIntoConstraints = false

        // The reference shows the camera itself at the foot of the track - the finger is still on
        // it, and the lock is what it slides up to.
        lockCamera.image = UIImage(systemName: "camera.fill",
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium))
        lockCamera.tintColor = .white
        lockCamera.contentMode = .center
        lockTrack.addSubview(lockCamera)
        lockCamera.translatesAutoresizingMaskIntoConstraints = false

        // --- flipping the camera ----------------------------------------------------------
        flipButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)), for: .normal)
        flipButton.tintColor = .white
        flipButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        flipButton.layer.cornerRadius = 20
        flipButton.addTarget(self, action: #selector(flipTapped), for: .touchUpInside)
        addSubview(flipButton)
        flipButton.translatesAutoresizingMaskIntoConstraints = false

        // --- the bar that appears once the finger is gone ---------------------------------
        bottomBar.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        bottomBar.isHidden = true
        addSubview(bottomBar)
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        binButton.setImage(UIImage(systemName: "trash",
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)), for: .normal)
        binButton.tintColor = .white
        binButton.addTarget(self, action: #selector(discardTapped), for: .touchUpInside)
        bottomBar.addSubview(binButton)
        binButton.translatesAutoresizingMaskIntoConstraints = false

        stopButton.setImage(UIImage(systemName: "stop.circle",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)), for: .normal)
        stopButton.tintColor = .systemRed
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        bottomBar.addSubview(stopButton)
        stopButton.translatesAutoresizingMaskIntoConstraints = false

        sendButton.setImage(UIImage(systemName: "paperplane.fill",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)), for: .normal)
        sendButton.tintColor = .white
        sendButton.backgroundColor = .mainColor
        sendButton.layer.cornerRadius = 20
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        bottomBar.addSubview(sendButton)
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        let tapCircle = UITapGestureRecognizer(target: self, action: #selector(circleTapped))
        circle.addGestureRecognizer(tapCircle)
        circle.isUserInteractionEnabled = true

        layoutPieces()
        applyStage()
    }

    private func layoutPieces() {
        // Measured off the reference at 3x and written back in points: the round window is the
        // screen's width less 20 either side, the top row sits 88 below the safe area, and the
        // bar at the foot stands 56 above whatever the home indicator leaves.
        circleDiameter = circle.widthAnchor.constraint(equalToConstant: 300)
        lockTrackBottom = lockTrack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -40)
        lockTrackCenterX = lockTrack.centerXAnchor.constraint(equalTo: trailingAnchor, constant: -86)

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: trailingAnchor),
            dim.topAnchor.constraint(equalTo: topAnchor),
            dim.bottomAnchor.constraint(equalTo: bottomAnchor),
            dim.leadingAnchor.constraint(equalTo: leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: trailingAnchor),

            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 76),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            timeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            circle.centerXAnchor.constraint(equalTo: centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 22),
            circleDiameter,
            circle.heightAnchor.constraint(equalTo: circle.widthAnchor),

            still.topAnchor.constraint(equalTo: circle.topAnchor),
            still.bottomAnchor.constraint(equalTo: circle.bottomAnchor),
            still.leadingAnchor.constraint(equalTo: circle.leadingAnchor),
            still.trailingAnchor.constraint(equalTo: circle.trailingAnchor),

            playOverlay.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            playOverlay.centerYAnchor.constraint(equalTo: circle.centerYAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -56),

            binButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 12),
            binButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 8),
            binButton.widthAnchor.constraint(equalToConstant: 40),
            binButton.heightAnchor.constraint(equalToConstant: 40),

            stopButton.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            stopButton.centerYAnchor.constraint(equalTo: binButton.centerYAnchor),
            stopButton.widthAnchor.constraint(equalToConstant: 40),
            stopButton.heightAnchor.constraint(equalToConstant: 40),

            sendButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: binButton.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40),

            flipButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            flipButton.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -8),
            flipButton.widthAnchor.constraint(equalToConstant: 40),
            flipButton.heightAnchor.constraint(equalToConstant: 40),

            slideLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            slideLabel.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -50),

            lockTrackCenterX,
            lockTrackBottom,
            lockTrack.widthAnchor.constraint(equalToConstant: 42),
            lockTrack.heightAnchor.constraint(equalToConstant: 118),

            lockIcon.centerXAnchor.constraint(equalTo: lockTrack.centerXAnchor),
            lockIcon.topAnchor.constraint(equalTo: lockTrack.topAnchor, constant: 14),
            lockIcon.widthAnchor.constraint(equalToConstant: 20),
            lockIcon.heightAnchor.constraint(equalToConstant: 20),

            lockCamera.centerXAnchor.constraint(equalTo: lockTrack.centerXAnchor),
            lockCamera.bottomAnchor.constraint(equalTo: lockTrack.bottomAnchor, constant: -12),
            lockCamera.widthAnchor.constraint(equalToConstant: 24),
            lockCamera.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let side = min(bounds.width - 40, bounds.height * 0.46)
        if abs(circleDiameter.constant - side) > 0.5 {
            circleDiameter.constant = side
        }
        circle.layer.cornerRadius = circle.bounds.width / 2
        previewLayer?.frame = circle.bounds
        playerLayer?.frame = circle.bounds

        // The arc rides 5pt outside the circle, opening from twelve o'clock.
        let radius = circle.bounds.width / 2 + 6
        let path = UIBezierPath(arcCenter: circle.center,
                                radius: radius,
                                startAngle: -.pi / 2,
                                endAngle: .pi * 1.5,
                                clockwise: true)
        progress.path = path.cgPath
    }

    /// Lines the lock track up under whichever button started the recording, so the finger slides
    /// straight up from where it already is.
    public func alignLockTrack(with button: UIView) {
        guard let host = superview else { return }
        let centre = button.convert(CGPoint(x: button.bounds.midX, y: button.bounds.midY), to: host)
        lockTrackCenterX.constant = centre.x - bounds.width
        lockTrackBottom.constant = -(bounds.height - centre.y) + 21
        setNeedsLayout()
    }

    // MARK: - Stages

    private func applyStage() {
        let recording = (stage == .holding || stage == .locked)
        // Red is the sign that something is being written down, so it waits for the camera the
        // same way the clock does. Between opening the screen and the first frame the clock reads
        // a plain 00:00, which is what the reference shows too.
        let writing = recording && isCapturing
        // Nothing has been recorded yet in that gap, so stopping or sending would hand over a note
        // with nothing in it - one that cannot even be played back. The bin stays live throughout:
        // backing out is always allowed.
        stopButton.isEnabled = isCapturing
        sendButton.isEnabled = (stage == .review) || isCapturing
        sendButton.alpha = sendButton.isEnabled ? 1 : 0.4
        stopButton.alpha = stopButton.isEnabled ? 1 : 0.4
        closeButton.isHidden = (stage == .holding)
        slideLabel.isHidden = (stage != .holding)
        lockTrack.isHidden = (stage != .holding)
        bottomBar.isHidden = (stage == .holding)
        stopButton.isHidden = (stage == .review)
        // While the finger is down the camera is the button being held, at the foot of the lock
        // track; a second one in the corner would be something the reader cannot reach anyway.
        flipButton.isHidden = (stage != .locked)
        playOverlay.isHidden = recording
        // The ring measures how far through a minute the recording has got, and later how far
        // through the note playback has got. Either way it needs something to measure, so it stays
        // out of the way until the camera is actually writing.
        progress.isHidden = recording && !isCapturing
        // Red only while something is actually being written down; plain the rest of the time.
        timeLabel.backgroundColor = writing ? UIColor.systemRed.withAlphaComponent(0.7) : .clear
        timeLabel.inset = writing ? UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8) : .zero
        timeLabel.invalidateIntrinsicContentSize()
    }

    // MARK: - Starting

    /// Asks for the camera and the microphone, wires the session up and starts recording.
    /// `ready(false)` means it never got going and the caller should take the screen away.
    public func begin(ready: @escaping (Bool) -> Void) {
        authorise { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                ready(false)
                return
            }
            guard !self.isFinished else {
                ready(false)
                return
            }
            self.sessionQueue.async {
                guard self.configureSession() else {
                    DispatchQueue.main.async { ready(false) }
                    return
                }
                self.session.startRunning()
                DispatchQueue.main.async {
                    guard !self.isFinished else {
                        self.stopSession()
                        return
                    }
                    self.attachPreview()
                    ready(true)
                    // Recording begins on the first frame out of the lens, not on a timer. The
                    // backstop below only covers a camera that never answers at all.
                    DispatchQueue.main.asyncAfter(deadline: .now() + VideoNoteComposer.warmUpLimit) { [weak self] in
                        self?.beginCapturing()
                    }
                }
            }
        }
    }

    private func authorise(_ done: @escaping (Bool) -> Void) {
        func askMicrophone(_ videoGranted: Bool) {
            guard videoGranted else {
                DispatchQueue.main.async { done(false) }
                return
            }
            AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
                DispatchQueue.main.async { done(audioGranted) }
            }
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            askMicrophone(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { askMicrophone($0) }
        default:
            DispatchQueue.main.async { done(false) }
        }
    }

    private func configureSession() -> Bool {
        session.beginConfiguration()
        // A video note is shown in a circle 190pt across, 250pt when it is opened - about 750
        // pixels at its very largest, and everything outside that circle is thrown away when it is
        // drawn. Recording at `.high` meant capturing 1920x1080 and sending it, for something that
        // is never seen at more than a fraction of it. VGA is still more than the circle can show
        // and roughly a seventh of the pixels, so nothing large is ever written in the first place.
        session.sessionPreset = .vga640x480

        guard let camera = camera(front: usingFrontCamera),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return false
        }
        session.addInput(input)
        videoInput = input

        if let mic = AVCaptureDevice.default(for: .audio),
           let micInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(micInput) {
            session.addInput(micInput)
        }

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return false
        }
        session.addOutput(output)

        if session.canAddOutput(probe) {
            probe.alwaysDiscardsLateVideoFrames = true
            probe.setSampleBufferDelegate(self, queue: probeQueue)
            session.addOutput(probe)
        }

        session.commitConfiguration()
        return true
    }

    private func camera(front: Bool) -> AVCaptureDevice? {
        let position: AVCaptureDevice.Position = front ? .front : .back
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                mediaType: .video,
                                                position: position).devices.first
            ?? AVCaptureDevice.default(for: .video)
    }

    private func attachPreview() {
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = circle.bounds
        circle.layer.insertSublayer(preview, at: 0)
        previewLayer = preview
    }

    // MARK: - Recording

    /// Called from whichever comes first - the first frame, or the backstop - and only acts once.
    private func beginCapturing() {
        guard !isCapturing, !isFinished, stage != .review, segments.isEmpty, fileURL == nil else { return }
        startRecording()
    }

    private func startRecording() {
        startSegment()

        isCapturing = true
        progress.strokeEnd = 0
        applyStage()
        startedAt = Date()
        elapsed = bankedTime
        tick()
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func startSegment() {
        let name = "VideoNote_\(Int(Date().timeIntervalSince1970 * 1000))_\(segments.count).mov"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
        try? FileManager.default.removeItem(at: url)
        fileURL = url

        applyConnectionSettings()
        output.startRecording(to: url, recordingDelegate: self)
    }

    private func tick() {
        guard let started = startedAt else { return }
        elapsed = bankedTime + Date().timeIntervalSince(started)
        timeLabel.text = VideoNoteComposer.clock(elapsed)
        progress.strokeEnd = min(CGFloat(elapsed / VideoNoteComposer.maximumDuration), 1)
        if elapsed >= VideoNoteComposer.maximumDuration {
            // A full minute is the limit, and reaching it does exactly what the red button does -
            // there is one way out of recording, not two that can drift apart.
            enterReview()
        }
    }

    private func finishRecording() {
        ticker?.invalidate()
        ticker = nil
        startedAt = nil
        isCapturing = false
        if output.isRecording {
            output.stopRecording()
        }
    }

    private static func clock(_ seconds: TimeInterval) -> String {
        let whole = Int(seconds)
        return String(format: "%02d:%02d", whole / 60, whole % 60)
    }

    // MARK: - The finger

    /// The recording has been running since the press began; this only decides what the movement
    /// of the finger means.
    public func holdMoved(to point: CGPoint, from origin: CGPoint) {
        guard stage == .holding else { return }
        let up = origin.y - point.y
        let left = origin.x - point.x
        if up > 70 {
            stage = .locked
            return
        }
        if left > 90 {
            cancelEverything()
            return
        }
        // Follows the finger the way the reference does, so the gesture feels attached to it.
        lockIcon.alpha = 1
        lockTrack.transform = CGAffineTransform(translationX: 0, y: -min(max(up, 0), 60))
        slideLabel.alpha = max(0, 1 - left / 90)
    }

    public func holdEnded() {
        guard stage == .holding else { return }
        lockTrack.transform = .identity
        // A tap rather than a hold: nothing worth keeping, and the reader gets told how it works.
        guard elapsed >= VideoNoteComposer.minimumDuration else {
            cancelEverything()
            return
        }
        enterReview()
    }

    // MARK: - Buttons

    @objc private func flipTapped() {
        guard !isFlipping, stage != .review else { return }
        flipButton.isEnabled = false

        guard isCapturing, output.isRecording else {
            // Nothing being written yet, so the lens can simply be changed.
            swapCamera { [weak self] in
                self?.flipButton.isEnabled = true
            }
            return
        }

        // Bank what has been recorded so far and close this piece. The next one opens from the
        // delegate, once the file is actually shut - starting it any earlier writes into a file
        // that is still being finished.
        isFlipping = true
        if let started = startedAt {
            bankedTime += Date().timeIntervalSince(started)
        }
        startedAt = nil
        output.stopRecording()
    }

    /// Changes which lens the session is reading from. Safe on its own; what it is not safe to do
    /// is run it while a movie file is open, which is what the caller above is careful about.
    private func swapCamera(_ done: @escaping () -> Void) {
        usingFrontCamera.toggle()
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            if let old = self.videoInput {
                self.session.removeInput(old)
            }
            if let camera = self.camera(front: self.usingFrontCamera),
               let input = try? AVCaptureDeviceInput(device: camera),
               self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoInput = input
            }
            self.session.commitConfiguration()
            DispatchQueue.main.async {
                self.applyConnectionSettings()
                done()
            }
        }
    }

    private func applyConnectionSettings() {
        guard let connection = output.connection(with: .video) else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        // Otherwise a note taken on the front camera plays back reversed, which reads as somebody
        // else's recording rather than your own.
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = usingFrontCamera
        }
    }

    @objc private func stopTapped() {
        guard stage == .locked else { return }
        enterReview()
    }

    /// Recording is over. The stage changes straight away so the buttons do; the camera is shut
    /// down and the still put up once the file is actually closed, which is a moment later.
    private func enterReview() {
        guard stage != .review else { return }
        recordedLength = elapsed
        stage = .review
        timeLabel.text = VideoNoteComposer.clock(recordedLength)
        // The ring has finished saying how much of the minute was used; from here it belongs to
        // playback, and playback has not started.
        progress.strokeEnd = 0
        finishRecording()
    }

    /// Puts a frame from the middle of the recording in the circle and turns the camera off. Until
    /// this runs the preview layer is still showing whatever the lens sees, which is a camera left
    /// running on a screen that has stopped recording.
    private func prepareReview() {
        stopSession()
        guard let asset = composedNote() else { return }
        reviewAsset = asset

        // Fix: the ring measured playback against the stopwatch that ran while recording, and the
        // two are not the same number - the file is always a little shorter than the wall clock
        // that timed it, because the camera stops handing over frames before stopRecording()
        // returns. Dividing by the longer of the two meant the ring ran out of video before it ran
        // out of circle and could never close. The file's own duration is what playback is
        // actually measured against, so that is what the ring is drawn from.
        let duration = CMTimeGetSeconds(asset.duration)
        if duration.isFinite, duration > 0 {
            recordedLength = duration
            timeLabel.text = VideoNoteComposer.clock(duration)
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        // The very first frame, exactly - no tolerance, or the generator is free to hand back the
        // nearest keyframe instead of the one asked for.
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let firstFrame = CMTime.zero
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let cg = try? generator.copyCGImage(at: firstFrame, actualTime: nil) else { return }
            let image = UIImage(cgImage: cg)
            DispatchQueue.main.async {
                guard let self = self, self.stage == .review else { return }
                self.still.image = image
                self.still.isHidden = false
                self.previewLayer?.removeFromSuperlayer()
                self.previewLayer = nil
            }
        }
    }

    @objc private func discardTapped() {
        cancelEverything()
    }

    @objc private func sendTapped() {
        guard !isFinished else { return }
        pendingSeconds = Int(elapsed.rounded())
        // Sending is not this screen's job. The file and its length go back to whoever asked for
        // the recording, and what happens to them from there is written elsewhere.
        if output.isRecording {
            // Still being written. stopRecording() returns straight away and the file is closed
            // afterwards, so the handover waits for the delegate rather than passing on a movie
            // that has no end yet.
            sendWhenClosed = true
            finishRecording()
            return
        }
        finishRecording()
        deliver()
    }

    private func deliver() {
        guard !isFinished else { return }
        isFinished = true
        releasePlayback()
        stopSession()

        guard !segments.isEmpty else {
            onCancel?()
            return
        }
        if segments.count == 1 {
            onFinish?(segments[0], pendingSeconds)
            return
        }
        // Several pieces, because the camera was turned round part way. What is handed over has to
        // be one note, so they are written out as one before anybody else sees them.
        let composed = composedNote()
        let destination = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("VideoNote_\(Int(Date().timeIntervalSince1970 * 1000)).mov")
        guard let asset = composed,
              let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            onFinish?(segments[0], pendingSeconds)
            return
        }
        export.outputURL = destination
        export.outputFileType = .mov
        export.exportAsynchronously { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if export.status == .completed {
                    self.onFinish?(destination, self.pendingSeconds)
                } else {
                    self.onFinish?(self.segments[0], self.pendingSeconds)
                }
            }
        }
    }

    @objc private func circleTapped() {
        guard stage == .review, let asset = reviewAsset else { return }
        if player == nil {
            let item = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            let layer = AVPlayerLayer(player: item)
            layer.videoGravity = .resizeAspectFill
            layer.frame = circle.bounds
            // Above the still, which stays underneath as what the circle falls back to whenever
            // nothing is playing.
            circle.layer.addSublayer(layer)
            player = item
            playerLayer = layer
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(playbackEnded),
                                                   name: .AVPlayerItemDidPlayToEndTime,
                                                   object: item.currentItem)
            // The clock and the ring both follow the playhead rather than a timer of their own, so
            // they cannot drift away from what is actually on screen.
            let interval = CMTime(seconds: 0.03, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            playbackObserver = item.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self else { return }
                let played = CMTimeGetSeconds(time)
                guard played.isFinite else { return }
                self.timeLabel.text = VideoNoteComposer.clock(played)
                let total = self.recordedLength > 0 ? self.recordedLength : VideoNoteComposer.maximumDuration
                // The last observation lands a frame short of the end, so anything inside the last
                // twentieth of a second closes the ring rather than leaving a visible gap in it.
                let fraction = (total - played) < 0.05 ? 1 : played / total
                self.progress.strokeEnd = min(CGFloat(fraction), 1)
            }
        }
        guard let player = player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            playOverlay.isHidden = false
            return
        }
        // Fix: this always seeked to the start, so pausing halfway and tapping again threw the
        // first half away and played it over. A pause is a pause - it carries on from where it
        // stopped. Only a note that has already run to the end starts again from the top.
        let played = CMTimeGetSeconds(player.currentTime())
        let total = recordedLength > 0 ? recordedLength : 0
        let atEnd = !played.isFinite || (total > 0 && played >= total - 0.05)
        if atEnd {
            player.seek(to: .zero)
            progress.strokeEnd = 0
        }
        player.play()
        playOverlay.isHidden = true
        playerLayer?.isHidden = false
    }

    @objc private func playbackEnded() {
        player?.pause()
        // Nothing is put back. The clock stays at the full length and the ring stays closed, which
        // is what the note actually is; resetting them read as though the recording had been
        // thrown away. Playing again seeks to the start and they follow it down from there.
        progress.strokeEnd = 1
        timeLabel.text = VideoNoteComposer.clock(recordedLength)
        playOverlay.isHidden = false
    }

    // MARK: - Ending

    private func cancelEverything() {
        guard !isFinished else { return }
        isFinished = true
        // Before the session is torn down, not after: an audio session in a recording category
        // deprioritises haptics, so the buzz is asked for while the engine can still answer.
        VideoNoteComposer.playCancelHaptic()
        sendWhenClosed = false
        releasePlayback()
        finishRecording()
        stopSession()
        for url in segments {
            try? FileManager.default.removeItem(at: url)
        }
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        segments = []
        fileURL = nil
        onCancel?()
    }

    private func releasePlayback() {
        if let observer = playbackObserver {
            player?.removeTimeObserver(observer)
            playbackObserver = nil
        }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    /// The whole note as one asset. One piece is itself; several are laid end to end, which is
    /// what the camera having been turned round mid-recording leaves behind.
    private func composedNote() -> AVAsset? {
        guard !segments.isEmpty else { return nil }
        if segments.count == 1 {
            return AVURLAsset(url: segments[0])
        }
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        var cursor = CMTime.zero
        for url in segments {
            let piece = AVURLAsset(url: url)
            let span = CMTimeRange(start: .zero, duration: piece.duration)
            if let source = piece.tracks(withMediaType: .video).first {
                try? videoTrack?.insertTimeRange(span, of: source, at: cursor)
                // Each piece carries its own camera's orientation, so the first one's transform is
                // the one the whole note is read with.
                if cursor == .zero {
                    videoTrack?.preferredTransform = source.preferredTransform
                }
            }
            if let source = piece.tracks(withMediaType: .audio).first {
                try? audioTrack?.insertTimeRange(span, of: source, at: cursor)
            }
            cursor = CMTimeAdd(cursor, piece.duration)
        }
        return composition
    }

    private func stopSession() {
        player?.pause()
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VideoNoteComposer: AVCaptureVideoDataOutputSampleBufferDelegate {
    /// The first buffer to arrive is the camera saying it is ready. Everything after it is ignored
    /// as cheaply as a boolean check - the probe is not reading the frames, only their arrival.
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard !sawFirstFrame else { return }
        sawFirstFrame = true
        DispatchQueue.main.async { [weak self] in
            self?.beginCapturing()
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension VideoNoteComposer: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput,
                           didFinishRecordingTo outputFileURL: URL,
                           from connections: [AVCaptureConnection],
                           error: Error?) {
        // A recording can stop with an error and still have written a perfectly good file - the
        // system says so with this flag. Treating every error as a failure is what closed the whole
        // screen the moment the camera was turned round.
        let usable: Bool
        if let error = error as NSError? {
            usable = (error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool) ?? false
        } else {
            usable = true
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if usable {
                self.segments.append(outputFileURL)
            } else {
                try? FileManager.default.removeItem(at: outputFileURL)
            }

            if self.isFlipping {
                self.isFlipping = false
                guard !self.isFinished, self.stage != .review else {
                    self.flipButton.isEnabled = true
                    return
                }
                // The file is shut; now the lens can change and the next piece can begin.
                self.swapCamera {
                    guard !self.isFinished, self.stage != .review else {
                        self.flipButton.isEnabled = true
                        return
                    }
                    self.startSegment()
                    self.startedAt = Date()
                    self.flipButton.isEnabled = true
                }
                return
            }

            guard !self.segments.isEmpty else {
                self.cancelEverything()
                return
            }

            if self.sendWhenClosed {
                self.sendWhenClosed = false
                self.deliver()
                return
            }
            // Everything is written, so a frame can be pulled out of it and the camera let go.
            if self.stage == .review {
                self.prepareReview()
            }
        }
    }
}

/// A label that can carry padding, so the timer can wear a pill while it is recording and nothing
/// while it is not.
public final class PaddedLabel: UILabel {
    public var inset: UIEdgeInsets = .zero {
        didSet { setNeedsDisplay() }
    }

    public override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: inset))
    }

    public override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + inset.left + inset.right,
                      height: size.height + inset.top + inset.bottom)
    }
}

// MARK: - The camera in the input bar

/// Owns the camera button that sits beside the microphone, the press-and-hold that starts a
/// recording, and the screen it opens. One of these per conversation, so the two editors share the
/// behaviour instead of carrying a copy each.
public final class VideoNoteEntryPoint: NSObject, UIGestureRecognizerDelegate {

    /// A recording the reader asked to send: the file, and how many seconds it runs. Left for the
    /// caller to act on - this class knows how to make a video note, not how to send one.
    public var onFinish: ((URL, Int) -> Void)?
    /// Something worth telling the reader, in their language, ready to be shown as a toast.
    public var onHint: ((String) -> Void)?
    /// Called just before the screen goes up, so the keyboard and any open sheet can be put away.
    public var onWillPresent: (() -> Void)?

    public let button = UIButton(type: .system)

    /// Sits behind the camera and the microphone both, so the two read as one control with two
    /// halves rather than as two buttons that happen to be next to each other.
    private let capsule = UIView()

    private weak var owner: UIViewController?
    private weak var anchor: UIButton?
    private var composer: VideoNoteComposer?
    private var holdOrigin: CGPoint = .zero

    /// The tap that says the hold has been taken and recording is starting.
    ///
    /// It fires when the press is recognised rather than when the first frame lands, and that is
    /// deliberate on two counts. It is the moment the reader needs answered - their finger is down
    /// and nothing on screen has changed yet. And an audio session in a recording category
    /// deprioritises haptics, so a buzz asked for after the camera has taken the audio route may
    /// simply never be felt.
    private let tapBack = UIImpactFeedbackGenerator(style: .medium)

    public init(owner: UIViewController, anchor: UIButton) {
        self.owner = owner
        self.anchor = anchor
        super.init()
    }

    /// What the recording screen is hung on.
    ///
    /// Fix: this used to be the conversation's own view, which stops at the navigation bar - so the
    /// blur covered the messages and left the header sitting on top of it in full colour, which is
    /// not what the reference does. The window covers everything, header and status bar included.
    private var host: UIView? {
        return owner?.view.window ?? owner?.navigationController?.view ?? owner?.view
    }

    /// Puts the button in beside the microphone. Safe to call more than once.
    public func install() {
        guard button.superview == nil,
              let anchor = anchor,
              let bar = anchor.superview else {
            return
        }
        button.setImage(UIImage(systemName: "camera.fill",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))?
                            .withRenderingMode(.alwaysTemplate), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        capsule.translatesAutoresizingMaskIntoConstraints = false
        capsule.layer.cornerRadius = 20
        capsule.layer.masksToBounds = true
        capsule.isUserInteractionEnabled = false

        // Behind both, then the camera in front of it - the microphone is already there and keeps
        // its own place in the order.
        bar.insertSubview(capsule, belowSubview: anchor)
        bar.insertSubview(button, aboveSubview: capsule)
        NSLayoutConstraint.activate([
            // Flush against the microphone, so there is no seam between the two halves.
            button.trailingAnchor.constraint(equalTo: anchor.leadingAnchor),
            button.centerYAnchor.constraint(equalTo: anchor.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 40),

            capsule.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: -6),
            capsule.trailingAnchor.constraint(equalTo: anchor.trailingAnchor),
            capsule.topAnchor.constraint(equalTo: anchor.topAnchor),
            capsule.bottomAnchor.constraint(equalTo: anchor.bottomAnchor)
        ])

        let hold = UILongPressGestureRecognizer(target: self, action: #selector(held(_:)))
        hold.minimumPressDuration = 0.2
        hold.delegate = self
        button.addGestureRecognizer(hold)

        // Warmed on touch-down, a fifth of a second before the hold is recognised: an engine asked
        // cold answers late enough to feel disconnected from the finger.
        button.addTarget(self, action: #selector(warmHaptics), for: .touchDown)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.require(toFail: hold)
        button.addGestureRecognizer(tap)
    }

    /// Hidden as soon as there is something written: the bar then belongs to sending that, and the
    /// capsule shrinks back to the round button it was.
    public func setHidden(_ hidden: Bool) {
        button.isHidden = hidden
        capsule.isHidden = hidden
    }

    /// Takes the microphone's own colours rather than guessing at them, so the two halves cannot
    /// drift apart when the theme changes - and so the camera reads white on the same ground the
    /// microphone does.
    public func matchAppearance(background: UIColor?, tint: UIColor) {
        capsule.backgroundColor = background
        button.tintColor = tint
    }

    @objc private func warmHaptics() {
        tapBack.prepare()
    }

    @objc private func tapped() {
        onHint?("Hold to record a video note".localized())
    }

    @objc private func held(_ gesture: UILongPressGestureRecognizer) {
        guard let host = host else { return }
        switch gesture.state {
        case .began:
            present(in: host)
            if composer != nil {
                tapBack.impactOccurred()
            }
            holdOrigin = gesture.location(in: host)
        case .changed:
            composer?.holdMoved(to: gesture.location(in: host), from: holdOrigin)
        case .ended, .cancelled, .failed:
            composer?.holdEnded()
        default:
            break
        }
    }

    private func present(in host: UIView) {
        guard composer == nil else { return }
        // Camera and microphone at once, so a call rules it out twice over.
        if APIS.blockedByCallInProgress() {
            return
        }
        onWillPresent?()

        let screen = VideoNoteComposer()
        screen.translatesAutoresizingMaskIntoConstraints = false
        screen.alpha = 0
        host.addSubview(screen)
        host.bringSubviewToFront(screen)
        NSLayoutConstraint.activate([
            screen.topAnchor.constraint(equalTo: host.topAnchor),
            screen.bottomAnchor.constraint(equalTo: host.bottomAnchor),
            screen.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            screen.trailingAnchor.constraint(equalTo: host.trailingAnchor)
        ])
        host.layoutIfNeeded()
        screen.alignLockTrack(with: button)
        composer = screen

        screen.onCancel = { [weak self] in
            self?.dismiss()
        }
        screen.onFinish = { [weak self] url, seconds in
            self?.dismiss()
            self?.onFinish?(url, seconds)
        }
        screen.begin { [weak self] started in
            guard let self = self else { return }
            guard started else {
                self.dismiss()
                self.onHint?("Camera and microphone access is needed to record".localized())
                return
            }
            UIView.animate(withDuration: 0.2) { screen.alpha = 1 }
        }
        UIView.animate(withDuration: 0.2) { screen.alpha = 1 }
    }

    private func dismiss() {
        guard let screen = composer else { return }
        composer = nil
        UIView.animate(withDuration: 0.2, animations: {
            screen.alpha = 0
        }, completion: { _ in
            screen.removeFromSuperview()
        })
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        return false
    }
}

// MARK: - Naming and packaging a video note

/// What tells a video note apart from any other video, everywhere it travels.
///
/// The message itself carries no flag of its own for this - a note goes as an ordinary video, with
/// the same attachment flag and the same slots - so the name of the file is what says which it is.
/// Every bubble, every media list and every export reads it from here rather than matching the
/// string in place, so there is one spelling of the prefix in the codebase and not a dozen.
public enum VideoNote {

    public static let prefix = "NX_VIDEO_NOTE_"

    /// True when this video id belongs to a round note rather than an ordinary video.
    public static func isNote(_ videoId: String?) -> Bool {
        guard let videoId = videoId else { return false }
        return videoId.hasPrefix(prefix)
    }

    /// A fresh name for one. Millisecond clock plus a random tail, so two notes taken in the same
    /// millisecond on two devices still cannot collide.
    public static func newVideoId() -> String {
        let stamp = Int(Date().timeIntervalSince1970 * 1000)
        let tail = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12)
        return "\(prefix)\(stamp)_\(tail).mp4"
    }

    public static func thumbName(for videoId: String) -> String {
        return "THUMB_\(videoId.replacingOccurrences(of: ".mp4", with: "")).jpeg"
    }

    /// Writes the recording into Documents as an mp4 under a video-note name, with a still beside
    /// it, and hands both names back. Everything the conversation needs to send one.
    ///
    /// The recorder writes QuickTime because that is what the camera hands over; what is sent has
    /// to be mp4, so this is where the conversion belongs rather than in the recorder - the
    /// recorder's job ends at "here is a recording".
    public static func package(recording: URL, completion: @escaping (_ videoId: String?, _ thumbId: String?) -> Void) {
        let videoId = newVideoId()
        let thumbId = thumbName(for: videoId)
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoURL = documents.appendingPathComponent(videoId)
        let thumbURL = documents.appendingPathComponent(thumbId)

        let asset = AVURLAsset(url: recording)

        // The still first: it is wanted whether or not the conversion works out.
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        if let cg = try? generator.copyCGImage(at: .zero, actualTime: nil),
           let data = UIImage(cgImage: cg).jpegData(compressionQuality: 0.6) {
            try? data.write(to: thumbURL)
        }

        // Bounded rather than "medium": a medium-quality export of a large source is still a large
        // file, because the preset describes the encoding and not the size. This one caps the
        // dimensions as well, so the note that goes out cannot be bigger than the note anyone can
        // see.
        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset640x480) else {
            completion(nil, nil)
            return
        }
        try? FileManager.default.removeItem(at: videoURL)
        export.outputURL = videoURL
        export.outputFileType = .mp4
        export.shouldOptimizeForNetworkUse = true
        export.exportAsynchronously {
            DispatchQueue.main.async {
                guard export.status == .completed else {
                    completion(nil, nil)
                    return
                }
                try? FileManager.default.removeItem(at: recording)
                completion(videoId, thumbId)
            }
        }
    }

    /// What the sender said about an attachment, read back out of the message it arrived on.
    ///
    /// The length and the size travel with the message now, so a bubble can say both before the
    /// file has been downloaded. Asked by file name and remembered, because a scrolling list
    /// rebuilds its rows constantly and this must not become a database query per row.
    public enum Facts {
        private static var cache: [String: (duration: TimeInterval, bytes: Int64)] = [:]

        public static func of(attachmentNamed name: String) -> (duration: TimeInterval, bytes: Int64) {
            guard !name.isEmpty else { return (0, 0) }
            if let already = cache[name] { return already }
            var found: (duration: TimeInterval, bytes: Int64) = (0, 0)
            Database.shared.database?.inTransaction { fmdb, _ in
                let escaped = name.replacingOccurrences(of: "'", with: "''")
                let query = "SELECT content_duration, file_size_attch FROM MESSAGE "
                    + "WHERE video_id = '\(escaped)' OR audio_id = '\(escaped)' "
                    + "OR image_id = '\(escaped)' OR file_id = '\(escaped)' "
                    + "OR gif_id = '\(escaped)' LIMIT 1"
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query), cursor.next() {
                    found.duration = TimeInterval(cursor.string(forColumnIndex: 0) ?? "") ?? 0
                    found.bytes = cursor.longLongInt(forColumnIndex: 1)
                    cursor.close()
                }
            }
            // Only worth remembering once there is something to remember - a row still arriving
            // would otherwise be written off as empty for the rest of the session.
            if found.duration > 0 || found.bytes > 0 {
                cache[name] = found
            }
            return found
        }

        private static var measured: [String: Int64] = [:]

        /// The workaround the sender could not cover: nothing came with the message, so the size is
        /// taken from what actually landed on this device.
        ///
        /// A plain file is asked its size and never read - a byte count is an attribute of a file,
        /// and there is no reason to pull a two hundred megabyte document into memory to call
        /// `.count` on it. What lives in the secure store does have to be opened, because what sits
        /// on disk there is the encrypted form and its length is not the length of the file; that
        /// answer is remembered, so it is paid for once rather than on every pass of cellForRow.
        public static func measuredSize(ofAttachmentNamed name: String) -> Int64 {
            guard !name.isEmpty else { return 0 }
            if let already = measured[name] { return already }

            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = documents.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                guard let size = attributes?[.size] as? Int64, size > 0 else { return 0 }
                measured[name] = size
                return size
            }

            // What lives only in the secure store cannot be measured without opening it, and that
            // is not something to do while a cell is being drawn - see `measureSize`.
            return 0
        }

        /// Measures what is only in the secure store, away from the main thread, once ever.
        ///
        /// Fix: this used to happen inline, in cellForRowAt: the whole file read off disk and
        /// decrypted just to count its bytes, on the main thread, for every file bubble on screen.
        /// A five megabyte song is a visible stall on the first frames after a cold start, and it
        /// happened again on every cold start because the answer was only ever kept in memory. Now
        /// it is done off the main thread and written back into the message's own size column, so
        /// the next launch reads it straight out of the database like any other sender's figure.
        /// One at a time, and never in the shared line - decrypting a five megabyte file is not
        /// something to do beside work the reader is waiting on.
        private static let measuring = DispatchQueue(label: "nexilis.attachment.measure", qos: .background)

        public static func measureSize(ofAttachmentNamed name: String, then report: @escaping (Int64) -> Void) {
            guard !name.isEmpty, measured[name] == nil else { return }
            measuring.async {
                guard FileEncryption.shared.isSecureExists(filename: name),
                      var bytes = try? FileEncryption.shared.readSecure(filename: name, withoutBiometric: true) else {
                    return
                }
                if let plain = FileEncryption.shared.decryptFileFromServer(data: bytes) {
                    bytes = plain
                }
                let size = Int64(bytes.count)
                guard size > 0 else { return }
                let escaped = name.replacingOccurrences(of: "'", with: "''")
                Database.shared.database?.inTransaction { fmdb, _ in
                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "MESSAGE",
                                                     cvalues: ["file_size_attch": size],
                                                     _where: "(file_id = '\(escaped)' OR video_id = '\(escaped)' "
                                                        + "OR audio_id = '\(escaped)' OR image_id = '\(escaped)') "
                                                        + "AND (file_size_attch IS NULL OR file_size_attch = 0)")
                }
                DispatchQueue.main.async {
                    measured[name] = size
                    // So the next read of the sender's facts finds it too, without asking the
                    // database again.
                    let known = cache[name] ?? (duration: 0, bytes: 0)
                    cache[name] = (duration: known.duration, bytes: size)
                    report(size)
                }
            }
        }

        /// What a file is expected to weigh, asked for in the order that costs least.
        ///
        /// 1. what the sender said - measured off the real file at the one moment its size was
        ///    known for certain, so it is right before anything has been fetched or asked about;
        /// 2. what a transfer already measured on the way past;
        /// 3. what a previous ask of the server found out and kept.
        ///
        /// The fourth answer - asking the server now - is a round trip, so it belongs to whoever
        /// can wait for it: see `Download.remoteSize(forKey:)`.
        public static func expectedSize(ofAttachmentNamed name: String) -> Int64 {
            guard !name.isEmpty else { return 0 }
            var bytes = of(attachmentNamed: name).bytes
            if bytes == 0, let moved = TransferBytes.get(name: name), moved.total > 0 {
                bytes = moved.total
            }
            if bytes == 0 {
                bytes = Download.knownRemoteSize(forKey: name) ?? 0
            }
            return bytes
        }

        /// "3.4 MB", the way a download that has not happened yet describes itself.
        public static func humanSize(_ bytes: Int64) -> String {
            guard bytes > 0 else { return "" }
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            formatter.allowedUnits = [.useKB, .useMB, .useGB]
            return formatter.string(fromByteCount: bytes)
        }
    }

    /// Notes whose send the reader stopped by hand.
    ///
    /// The bubble raises its stop control whenever bytes are seen moving for a note, because
    /// waiting for the row to be rebuilt at the right instant is a window a quick send misses. But
    /// a cancelled transfer still reports on its way out - and the outgoing thread announces the
    /// give-up too - so those late reports raised the control again on a message that already read
    /// as failed, with nothing left to take it down. Asking the network whether something is in
    /// flight was not enough: that answer changes from moment to moment.
    ///
    /// This is not a guess about the network. It is what the reader decided, and it changes only
    /// when they decide otherwise.
    private static var stoppedByHand: Set<String> = []

    /// When a note was last handed to the queue.
    ///
    /// Reading the row's status at rebuild time is a race, and the trace proved it: the first send
    /// is slow enough to still read "1" when the row is redrawn, the second is already "2" because
    /// the file is on the server by then - so the second showed no stop control at all. When the
    /// reader pressed send is not a race, and it is the thing the control is actually reporting.
    private static var sendingSince: [String: Date] = [:]
    /// Long enough to outlast the stop control's own minimum on screen.
    ///
    /// The control promises to stay up for two seconds so it can actually be pressed, but that
    /// promise is kept by the bubble view, and a row is rebuilt into a brand new bubble whenever
    /// anything about the message changes - the server's answer, most of all, which for a second
    /// send arrives almost at once. The new bubble never made the promise, so the control went
    /// with the old one. This is the same window, kept where a rebuild cannot reach it, and a
    /// touch cuts it short by clearing the mark outright.
    private static let sendingGrace: TimeInterval = 2.2

    public static func markSending(videoId: String) {
        guard !videoId.isEmpty else { return }
        sendingSince[videoId] = Date()
        stoppedByHand.remove(videoId)
    }

    public static func clearSending(videoId: String) {
        sendingSince.removeValue(forKey: videoId)
    }

    /// True for a short while after a send was asked for, whatever the database has caught up to.
    public static func isSending(videoId: String) -> Bool {
        guard !videoId.isEmpty, let since = sendingSince[videoId] else { return false }
        guard Date().timeIntervalSince(since) < sendingGrace else {
            sendingSince.removeValue(forKey: videoId)
            return false
        }
        return true
    }

    public static func markStopped(videoId: String) {
        guard !videoId.isEmpty else { return }
        stoppedByHand.insert(videoId)
    }

    public static func clearStopped(videoId: String) {
        stoppedByHand.remove(videoId)
    }

    public static func isStopped(videoId: String) -> Bool {
        return stoppedByHand.contains(videoId)
    }

    /// Lengths already worked out, so a scrolling list asks the file system once per note rather
    /// than once per row it draws.
    private static var knownLengths: [String: TimeInterval] = [:]

    /// Records a length somebody else has already measured - the bubble knows it the moment it has
    /// the note open, and that saves the chat list going and looking for the file itself.
    public static func remember(seconds: TimeInterval, forVideoId videoId: String) {
        guard seconds > 0, !videoId.isEmpty else { return }
        knownLengths[videoId] = seconds
    }

    /// How long the note runs.
    ///
    /// Fix: this looked in Documents and nowhere else, so a note held in the encrypted store - or
    /// one whose plain copy had been tidied away - measured zero and the line read "Video note"
    /// with no length after it. A note can be in any of three places by the time it is asked
    /// about, and the decrypted copy the bubble writes counts as much as the original.
    public static func duration(ofVideoId videoId: String) -> TimeInterval {
        guard !videoId.isEmpty else { return 0 }
        if let already = knownLengths[videoId] {
            return already
        }
        // What another part of the app has already measured for this same file.
        if let seconds = VideoDurationStore.seconds(forFileNamed: videoId), seconds > 0 {
            knownLengths[videoId] = TimeInterval(seconds)
            return TimeInterval(seconds)
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let candidates = [documents.appendingPathComponent(videoId),
                          caches.appendingPathComponent(videoId),
                          URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoId)]
        guard let url = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            // No file here yet. The sender said how long it runs, so the length can still be shown
            // - which is the whole point of sending it.
            let told = Facts.of(attachmentNamed: videoId).duration
            if told > 0 {
                knownLengths[videoId] = told
            }
            return told
        }
        let seconds = CMTimeGetSeconds(AVURLAsset(url: url).duration)
        guard seconds.isFinite, seconds > 0 else { return 0 }
        knownLengths[videoId] = seconds
        return seconds
    }

    /// How a quoted video note reads: a camera and how long it runs, the way a quoted voice note
    /// gives a microphone and its length. Returns nil for an ordinary video, which is quoted the
    /// way it always was.
    public static func quotedLine(videoId: String, font: UIFont?, colour: UIColor) -> NSAttributedString? {
        guard isNote(videoId) else { return nil }
        let camera = NSTextAttachment()
        camera.image = UIImage(systemName: "video.fill")?.withTintColor(colour, renderingMode: .alwaysOriginal)
        camera.bounds = CGRect(x: 0, y: -1, width: 15, height: 11)
        var text = "Video note".localized()
        let length = duration(ofVideoId: videoId)
        if length > 0 {
            text += " (" + clockLength(length) + ")"
        }
        let line = NSMutableAttributedString(attachment: camera)
        var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: colour]
        if let font = font {
            attributes[.font] = font
        }
        line.append(NSAttributedString(string: " " + text, attributes: attributes))
        return line
    }

    /// The still for a quoted attachment, from wherever it happens to be - and fetched if it is
    /// nowhere yet.
    ///
    /// A quote used to read the plain file in Documents and nothing else. On the receiving side
    /// that file often does not exist: nobody downloads a thumbnail for a message they have only
    /// been shown a quote of. So a reply to a video note had an empty space where the round still
    /// belongs. The encrypted store is checked too, and a miss starts the small download that
    /// makes the next redraw of that row find one.
    public static func quotedStill(named name: String) -> UIImage? {
        guard !name.isEmpty else { return nil }
        if let cached = Nexilis.imageCache.object(forKey: name as NSString) {
            return cached
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if let image = UIImage(contentsOfFile: documents.appendingPathComponent(name).path)?
            .resize(target: CGSize(width: 500, height: 500)) {
            Nexilis.imageCache.setObject(image, forKey: name as NSString)
            return image
        }
        if FileEncryption.shared.isSecureExists(filename: name),
           let bytes = try? FileEncryption.shared.readSecure(filename: name),
           let image = UIImage(data: bytes) {
            Nexilis.imageCache.setObject(image, forKey: name as NSString)
            return image
        }
        fetchQuotedStill(named: name)
        return nil
    }

    private static var stillsRequested: Set<String> = []

    private static func fetchQuotedStill(named name: String) {
        guard !stillsRequested.contains(name), !Download.isDownloading(forKey: name) else { return }
        stillsRequested.insert(name)
        Download().startHTTP(forKey: name) { _, _ in }
    }

    /// Fills a quote's thumbnail in, now or when it arrives.
    ///
    /// Fix: asking for the picture and starting a download if it was missing was only half of it -
    /// nothing then told the quote its picture had landed. The bubble for a note watches for its
    /// own files; a quote had nobody watching, so the space stayed empty until that row happened
    /// to be redrawn for some other reason. The watcher below belongs to the image view and dies
    /// with it.
    public static func loadQuotedStill(named name: String, into view: UIImageView) {
        guard !name.isEmpty else {
            view.image = nil
            return
        }
        if let image = quotedStill(named: name) {
            view.image = image
            return
        }
        view.image = nil
        let watcher = QuotedStillWatcher(name: name, view: view)
        objc_setAssociatedObject(view, &QuotedStillWatcher.key, watcher, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private final class QuotedStillWatcher: NSObject {
        static var key: UInt8 = 0
        private let name: String
        private weak var view: UIImageView?

        init(name: String, view: UIImageView) {
            self.name = name
            self.view = view
            super.init()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(landed(_:)),
                                                   name: Download.progressNotification,
                                                   object: nil)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc private func landed(_ notification: Notification) {
            guard let arrived = notification.userInfo?["name"] as? String, arrived == name,
                  let progress = notification.userInfo?["progress"] as? Double, progress >= 100,
                  let view = view else {
                return
            }
            view.image = VideoNote.quotedStill(named: name)
        }
    }

    /// "0:24", the way the reference writes it under the circle.
    public static func clock(_ seconds: TimeInterval) -> String {
        // Fix: this rounded to the nearest second, so a note of 13.6 seconds was recorded as
        // "00:13" by the timer, sent as 13 in CONTENT_DURATION, and then drawn under the circle
        // as "0:14" - one note with two lengths, and neither matching the other side. Whole
        // seconds elapsed is also what a running timer means: 0:01 belongs at one second, not at
        // a half.
        let whole = max(0, Int(seconds.rounded(.down)))
        return String(format: "%d:%02d", whole / 60, whole % 60)
    }

    /// How long a note is, as the note itself reports it.
    ///
    /// The same arithmetic the send uses for CONTENT_DURATION - rounded down, and never less than
    /// a second once there is anything to measure - so a note reads the same before it has been
    /// fetched, after it has been fetched, and on the screen it was recorded on.
    public static func clockLength(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return clock(0) }
        return clock(max(1, seconds.rounded(.down)))
    }
}
