//
//  TransferStopControl.swift
//  NexilisLite
//

import UIKit

/// The stop and its ring, for a transfer running under a picture.
///
/// A video note wears this same control at the foot of its circle, small, because the foot of a
/// circle is all the room there is. A photo is wide enough to carry it in the middle, where the
/// reference puts it, and to make it a comfortable thing to press. What it does is unchanged: a
/// ground of its own so the arc reads over a picture of any colour, an arc that turns while there
/// is nothing yet to measure and grows once there is, and a stop that means stop.
///
/// It follows the transfer itself rather than waiting to be told. That is the lesson of the note's
/// stop control: a row is rebuilt into a brand new bubble whenever anything about the message
/// changes, and a control that only knows what the view that made it knew loses the transfer every
/// time. This one is handed the name of the file and listens for it.
public final class TransferStopControl: UIView {

    /// Across the disc. The note's is 24 - it has a circle's foot to fit into; this one has the
    /// middle of a photograph.
    public static let side: CGFloat = 46

    /// The least time the control stays on screen once the bytes are done.
    ///
    /// A picture already on the server goes up in a blink, and a stop that is drawn and taken away
    /// inside two frames is a stop nobody could ever have pressed.
    private static let minimumOnScreen: TimeInterval = 2.0

    /// The reader has asked for the transfer to stop. The bytes are already halted by then; this
    /// is what the conversation makes of it.
    public var onStop: (() -> Void)?

    /// The transfer is over and the control has taken itself down.
    public var onFinished: (() -> Void)?

    private let button = UIButton(type: .system)
    private let track = CAShapeLayer()
    private let arc = CAShapeLayer()
    /// The files this control is following. A collage is fetched as one thing, so one control
    /// stands for several transfers and reports where they have got to between them.
    private var following: [String] = []
    private var raisedAt = Date.distantPast
    /// Which notification carries this transfer's progress.
    private enum Direction { case up, down }
    private var direction: Direction = .up
    /// How wide this one is. A picture has its middle to give; a file bubble has a fifty-point
    /// strip and room only where the arrow used to sit.
    private let side: CGFloat

    public init(side: CGFloat = TransferStopControl.side) {
        self.side = side
        super.init(frame: .zero)
        build()
    }

    public override convenience init(frame: CGRect) {
        self.init(side: TransferStopControl.side)
    }

    public required init?(coder: NSCoder) {
        self.side = TransferStopControl.side
        super.init(coder: coder)
        build()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func build() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: side),
            heightAnchor.constraint(equalToConstant: side)
        ])

        // The note's control is 9 points of stop inside 24 of disc; these keep that proportion at
        // whatever size they are asked for.
        button.setImage(UIImage(systemName: "stop.fill",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: max(9, side * 0.3),
                                                                               weight: .black))?
                            .withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .black
        // A ground of its own. A white track and a white arc over a photograph of a white wall is
        // a control that is drawn and cannot be seen.
        button.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        button.layer.cornerRadius = side / 2
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Built from the size this control is constrained to, not from anybody's bounds. The paths
        // are wanted before the view has ever been laid out, and a path built from a zero-width
        // box is no path at all - which is how the ring on the note came to be invisible three
        // separate times. It is also why they hang off the button rather than off this view: the
        // conversation's own progress machinery walks a cell looking for the last shape layer on a
        // container and moves it, and this arc is not its to move.
        let box = CGRect(x: 0, y: 0, width: side, height: side)
        let stroke = max(2, side * 0.065)
        let path = UIBezierPath(arcCenter: CGPoint(x: box.midX, y: box.midY),
                                radius: box.width / 2 - stroke,
                                startAngle: -.pi / 2,
                                endAngle: .pi * 1.5,
                                clockwise: true).cgPath

        track.fillColor = UIColor.clear.cgColor
        // Read against the white disc under it, not against the picture.
        track.strokeColor = UIColor.black.withAlphaComponent(0.18).cgColor
        track.lineWidth = stroke
        track.strokeEnd = 1
        track.path = path
        track.frame = box
        button.layer.addSublayer(track)

        arc.fillColor = UIColor.clear.cgColor
        arc.strokeColor = UIColor.mainColor.cgColor
        arc.lineWidth = stroke + 0.5
        arc.lineCap = .round
        arc.strokeStart = 0
        arc.strokeEnd = 0
        arc.path = path
        // Its frame is the disc's box, so the turn is about the middle - where the stop sits.
        arc.frame = box
        button.layer.addSublayer(arc)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(uploadMoved(_:)),
                                               name: NSNotification.Name(rawValue: "onUploadChat"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(downloadMoved(_:)),
                                               name: Download.progressNotification,
                                               object: nil)
    }

    /// The face this control wears before anything is moving: the offer to fetch the file.
    ///
    /// The disc is the same disc, in the same place and at the same size, so accepting the offer
    /// changes the mark inside it and nothing else - no jump, nothing to line up twice.
    ///
    /// It takes no touches of its own. What starts a download on these bubbles is the tap the
    /// thumbnail already carries, and one place that knows how to start one is enough.
    public func showOffer() {
        following = []
        isHidden = false
        isUserInteractionEnabled = false
        arc.removeAnimation(forKey: "turn")
        arc.isHidden = true
        track.isHidden = true
        button.isUserInteractionEnabled = false
        button.setImage(UIImage(systemName: "arrow.down",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: max(11, side * 0.36),
                                                                               weight: .semibold))?
                            .withRenderingMode(.alwaysTemplate), for: .normal)
    }

    /// Raise the control for a transfer on its way out, at whatever it has already reached.
    public func begin(transferNamed name: String, progress: Double) {
        raise(names: [name], progress: progress, direction: .up)
    }

    /// The same, for one coming in.
    public func beginDownload(transferNamed name: String, progress: Double) {
        raise(names: [name], progress: progress, direction: .down)
    }

    /// And for several at once - the pictures of a collage, fetched together.
    public func beginDownload(all names: [String], progress: Double) {
        raise(names: names, progress: progress, direction: .down)
    }

    /// The same, going the other way: a collage is sent as one thing too.
    public func begin(all names: [String], progress: Double) {
        raise(names: names, progress: progress, direction: .up)
    }

    private func raise(names: [String], progress: Double, direction: Direction) {
        self.direction = direction
        following = names
        raisedAt = Date()
        isHidden = false
        isUserInteractionEnabled = true
        button.isUserInteractionEnabled = true
        arc.isHidden = false
        track.isHidden = false
        button.setImage(UIImage(systemName: "stop.fill",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: max(9, side * 0.3),
                                                                               weight: .black))?
                            .withRenderingMode(.alwaysTemplate), for: .normal)
        startTurning()
        show(progress)
    }

    private func startTurning() {
        guard arc.animation(forKey: "turn") == nil else { return }
        // A quarter of the circle, going round: there is nothing to measure yet, and a still ring
        // reads as stuck.
        arc.strokeEnd = 0.25
        let turn = CABasicAnimation(keyPath: "transform.rotation.z")
        turn.fromValue = 0
        turn.toValue = CGFloat.pi * 2
        turn.duration = 1.1
        turn.repeatCount = .infinity
        turn.isRemovedOnCompletion = false
        arc.add(turn, forKey: "turn")
    }

    /// The arc turns through the transfer's first quarter - there is a quarter of a circle to draw
    /// and no more - then stops turning and simply grows to the end.
    private func show(_ percent: Double) {
        let fraction = CGFloat(min(max(percent, 0) / 100, 1))
        guard fraction >= 0.25 else {
            arc.strokeEnd = 0.25
            return
        }
        arc.removeAnimation(forKey: "turn")
        // These arrive about once per percent; the default quarter-second fade would smear one
        // into the next.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        arc.strokeEnd = fraction
        CATransaction.commit()
    }

    @objc private func uploadMoved(_ notification: Notification) {
        guard direction == .up else { return }
        moved(notification)
    }

    @objc private func downloadMoved(_ notification: Notification) {
        guard direction == .down else { return }
        moved(notification)
    }

    private func moved(_ notification: Notification) {
        guard !following.isEmpty,
              let name = notification.userInfo?["name"] as? String, following.contains(name) else {
            return
        }
        var progress = notification.userInfo?["progress"] as? Double ?? 0
        if following.count > 1, progress >= 0 {
            // Several files, one arc: how far along they are between them. A file no longer moving
            // has arrived, and counts as done.
            var sum = 0.0
            var done = 0
            for one in following {
                switch direction {
                case .down:
                    if Download.isDownloading(forKey: one) {
                        sum += Download.progress(forKey: one) ?? 0
                    } else {
                        sum += 100
                        done += 1
                    }
                case .up:
                    if Network.isUploading(name: one) {
                        // Uploads are not asked how far along they are; they are weighed. What has
                        // gone out of what there is to send is the same fraction.
                        if let moved = TransferBytes.get(name: one), moved.total > 0 {
                            sum += Double(moved.completed) / Double(moved.total) * 100
                        }
                    } else {
                        sum += 100
                        done += 1
                    }
                }
            }
            progress = done == following.count ? 100 : sum / Double(following.count)
        }
        // Below zero is a transfer that failed or was called off. Either way there is nothing left
        // for this control to report, and whoever stopped it decides what the bubble says next.
        guard progress >= 0 else {
            takeDown()
            return
        }
        guard progress >= 100 else {
            show(progress)
            return
        }
        finish()
    }

    /// The bytes are done. The ring closes, waits out its minimum, and goes.
    private func finish() {
        arc.removeAnimation(forKey: "turn")
        arc.strokeEnd = 1
        let owed = TransferStopControl.minimumOnScreen - Date().timeIntervalSince(raisedAt)
        guard owed > 0 else {
            takeDown()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + owed) { [weak self] in
            self?.takeDown()
        }
    }

    private func takeDown() {
        isHidden = true
        onFinished?()
    }

    @objc private func stopTapped() {
        // A control that is not in front of the reader is not the control that speaks for this
        // message. Rebuilding a row leaves the old one alive to the end of the run loop, still
        // holding whatever touch was on it.
        //
        // Fix: there was a second guard here that ignored any press in the first four-tenths of a
        // second, put in early on against a stray touch arriving in the same frame the control
        // appeared. The trace that finally explained that bug showed this window never fired once
        // - the culprit was the detached view above - and on a download it was doing real harm: the
        // control appears under the finger that just tapped the picture to start the fetch, so a
        // reader who then reaches for stop is reaching within those four-tenths. Their first press
        // was swallowed every time, which is why stopping a video took two taps.
        guard window != nil else { return }
        // Straight down: the minimum on screen is there so a transfer too quick to see is still
        // seen, and this one has just been stopped by hand.
        isHidden = true
        onStop?()
    }
}
