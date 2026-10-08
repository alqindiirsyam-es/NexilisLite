//
//  Callback.swift
//  Runner
//
//  Created by Yayan Dwi on 15/04/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import UIKit
import nuSDKService
import Network
import NexilisZTA
@_implementationOnly import NotificationBannerSwift
class Callback : CallBack {
    var sID: String = "Callback"
    
    func connectionStateChanged(sUserID: String!, sDeviceID: String!, bConState: Bool!, nConType: Int!, nConSubType: Int!, nCLMConStat: UInt8!) {
        //print(sUserID, "/", sDeviceID, "/", bConState, "/", nConType, "/", nConSubType, "/", nCLMConStat)
        if let dispatch = Nexilis.dispatch, bConState {
            dispatch.leave()
        }
        if let delegate = Nexilis.shared.connectionDelegate {
            delegate.connectionStateChanged(userId: sUserID, deviceId: sDeviceID, state: bConState)
        }
        InquiryThread.default.set(wait: nCLMConStat == 0)
        OutgoingThread.default.set(wait: nCLMConStat == 0)
        if nCLMConStat != 0 {
            // The link is up: anything still sitting at status "1" never got its "2" and is
            // worth another try now.
            OutgoingThread.default.resendPending()
        }
    }
    
    func gpsStateChanged(nState: Int!) {
        
    }
    
    func sleepStateChanged(bState: Bool!) {
        
    }
    
    func callStateChanged(nState: Int!, sMessage: String!) -> Int {
        NexilisCallDiagnostics.record("sdk.callback state=\(nState ?? 0) delegate=\(Nexilis.shared.callDelegate != nil) library_ui=\(Nexilis.showLibraryNotification) push=\(Nexilis.callAPNActivated)")
//        print(nState,"/",sMessage)
        if nState == Nexilis.AUDIO_CALL_INCOMING || nState == Nexilis.VIDEO_CALL_INCOMING {
            if let delegate = Nexilis.shared.callDelegate {
                if !Nexilis.showLibraryNotification || Nexilis.callAPNActivated {
                    delegate.onStatusCall(state: nState, message: sMessage)
                } else {
                    delegate.onIncomingCall(state: nState, message: sMessage)
                }
            }
        } else {
            if let delegate = Nexilis.shared.callDelegate {
                delegate.onStatusCall(state: nState, message: sMessage)
            }
        }
        
        return 1
    }
    
    func bcastStateChanged(nState: Int!, sMessage: String!) -> Int {
        //print("LS CALLBACK ",nState,"/",sMessage)
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onStartLS(state: nState, message: sMessage)
        }
        if let delegate = Nexilis.shared.streamingDelagate {
            delegate.onJoinLS(state: nState, message: sMessage)
        }
        if let delegate = Nexilis.shared.seminarDelegate {
            delegate.onStartSeminar(state: nState, message: sMessage)
        }
        if let delegate = Nexilis.shared.seminarDelegate {
            delegate.onJoinSeminar(state: nState, message: sMessage)
        }
        return 1
    }
    
    func sshareStateChanged(nState: Int!, sMessage: String!) -> Int {
        //print("Screen sharing state: ",nState,"/",sMessage)
        switch nState {
            case 0:
                if (sMessage.starts(with: "Initiating")){
                    if let delegate = Nexilis.shared.screenSharingDelegate {
                        delegate.onStartScreenSharing(state: nState, message: sMessage)
                    }
                }
            case 12:
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onStartScreenSharing(state: nState, message: sMessage)
                }
            case 22:
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onJoinScreenSharing(state: nState, message: sMessage)
                }
            case 88:
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onStartScreenSharing(state: nState, message: sMessage)
                }
                if let delegate = Nexilis.shared.screenSharingDelegate {
                    delegate.onJoinScreenSharing(state: nState, message: sMessage)
                }
            default:
                break
        }
        return 1
    }
    
    func incomingData(sPacketID: String!, oData: AnyObject!) throws {
        guard let packetId = sPacketID, let data = oData else {
            return
        }
        Nexilis.incomingData(packetId: packetId, data: data)
    }
    
    func lateResponse(sPacketID: String!, sResponse: String!) throws {
        
    }
    
    func asycnACKReceived(sPacketID: String!) throws {
        //print("asycnACKReceived: \(sPacketID)")
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    OutgoingThread.default.delOutgoing(fmdb: fmdb, packageId: sPacketID)
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
    }
    
    func locationUpdated(lTime: Int64!, sLocationInfo: String!) {
        
    }
    
    func resetDB() {
        
    }
    
}

/// Keeps the messaging link alive while the phone itself is online.
///
/// Fix: two things can be down, and only one of them was ever noticed. The phone can be online -
/// a request to google.com answers - while nuSDK's own link (`nGetCLXConnState()`) is down. When
/// that happened in the foreground nothing brought the link back: OutgoingThread is told to wait
/// for it (Callback.connectionStateChanged), a message sent meanwhile sat on its clock, and it only
/// went out after the reader swiped the app away and came back. This looks at both once a second
/// while the app is in front of the reader. The SDK being down shows the "Connecting..." strip; the
/// SDK staying down while the internet really answers gets the link rebuilt (backing off from ten
/// seconds to a minute), and the SDK's own "connected" callback then lets the queue go - see
/// Callback.connectionStateChanged and OutgoingThread.resendPending.
final class ConnectionWatch {

    static let shared = ConnectionWatch()

    private var timer: Timer?
    /// The phone's own network, as the system reports it - the moment it changes.
    private let pathMonitor = NWPathMonitor()
    /// Whether the phone has any route out at all. Optimistic until the monitor first answers.
    private var pathSatisfied = true
    /// When the phone was first seen without any route out, in this run of being without one.
    private var pathDownSince: Date?
    /// When the SDK's link was first seen down, in this run of being down.
    private var sdkDownSince: Date?
    /// Whether the internet itself answered the last time it was asked.
    private var internetAnswers = false
    private var lastProbe: Date?
    /// When the last probe came back - so "the internet does not answer" is only believed once an
    /// answer has actually come back while the link was down.
    private var lastProbeAnswered: Date?
    private var isProbing = false
    /// A conversation on screen has been told it closes in five seconds - see closeConversationsWhileBlocked.
    private var isClosingConversations = false
    /// The check for missing keys after a key pull (Android's checkOfflineInvState) is waiting.
    private var invalidStateCheck: DispatchWorkItem?
    private var isShowingInvalidState = false
    /// Its keys are being pulled and it is being opened again.
    private var isReopening = false
    private var lastReopenAttempt: Date?
    /// How long the link may stay down, with the internet up, before it is rebuilt.
    private var rebuildAfter: TimeInterval = ConnectionWatch.firstRebuildAfter
    private var lastRebuild: Date?
    private var isRebuilding = false
    private static let firstRebuildAfter: TimeInterval = 10
    private let rebuildQueue = DispatchQueue(label: "io.nexilis.connectionWatch.rebuild", qos: .utility)
    private lazy var probeSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 4
        configuration.timeoutIntervalForResource = 5
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: configuration)
    }()

    private init() {}

    /// Starts watching. Called when Lite connects; calling it again does nothing.
    func start() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.start() }
            return
        }
        guard timer == nil else {
            return
        }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer.tolerance = 0.3
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        // Fix: the strip waited for nuSDK to notice the link had gone, and nuSDK takes several
        // seconds to notice - so with airplane mode on, or Wi-Fi and data both off, nothing said
        // so until then. The phone's own network is known the moment it changes, and with no route
        // at all there is nothing to wait for.
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let wasSatisfied = self.pathSatisfied
                self.pathSatisfied = path.status == .satisfied
                if self.pathSatisfied {
                    self.pathDownSince = nil
                    // Online again: reading is allowed again straight away, as Android does on
                    // onAvailable - the keys never left memory, so nothing has to be pulled first.
                    self.endOfflineBlock()
                    if !wasSatisfied {
                        // The SDK gets its own chance to reconnect over the route that is back
                        // before the watch steps in and rebuilds it.
                        self.sdkDownSince = nil
                        self.rebuildAfter = ConnectionWatch.firstRebuildAfter
                        // What was waiting to go out does not have to wait to be noticed.
                        OutgoingThread.default.resendPending()
                    }
                } else {
                    self.internetAnswers = false
                }
                self.tick()
            }
        }
        pathMonitor.start(queue: DispatchQueue(label: "io.nexilis.connectionWatch.path", qos: .utility))
        let center = NotificationCenter.default
        center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            // Nobody is looking, and the system is about to suspend the link anyway. Closing and
            // reopening the database from here on is APIS.enterBackground / enterForeground's.
            self?.sdkDownSince = nil
            self?.invalidStateCheck?.cancel()
            self?.invalidStateCheck = nil
            ConnectingStrip.shared.hide()
        }
        center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.tick()
        }
        center.addObserver(forName: Nexilis.featureAccessDidFinish, object: nil, queue: .main) { [weak self] _ in
            self?.checkInvalidStateSoon()
        }
    }

    private func tick() {
        guard UIApplication.shared.applicationState == .active, Utils.getSetProfile(), User.getMyPin() != nil else {
            sdkDownSince = nil
            ConnectingStrip.shared.hide()
            return
        }
        if !pathSatisfied {
            // No route out at all: the strip goes up straight away, without waiting for the SDK.
            // A second's grace covers the hand-over from Wi-Fi to cellular, which passes through
            // "no route" for a moment. There is nothing to rebuild the link over, so nothing else
            // is tried until a route is back.
            let since = pathDownSince ?? Date()
            pathDownSince = since
            let offlineFor = Date().timeIntervalSince(since)
            if offlineFor >= 1 {
                ConnectingStrip.shared.show()
                beginOfflineBlock()
            }
            closeConversationsWhileBlocked()
            return
        }
        if API.nGetCLXConnState() == 1 {
            sdkDownSince = nil
            endOfflineBlock()
            reopenDatabaseIfNeeded()
            rebuildAfter = ConnectionWatch.firstRebuildAfter
            ConnectingStrip.shared.hide()
            return
        }
        let since = sdkDownSince ?? Date()
        sdkDownSince = since
        let downFor = Date().timeIntervalSince(since)
        // A moment's grace, so a link that drops and comes straight back does not flash the strip.
        if downFor >= 2 {
            ConnectingStrip.shared.show()
        }
        probeInternetIfDue()
        // A route that goes nowhere - no data left on the plan, a hotspot with nothing behind it -
        // is offline as much as no route at all, once a probe sent while the link was down has
        // come back unanswered.
        if downFor >= 3, !internetAnswers, let answered = lastProbeAnswered, answered > since {
            beginOfflineBlock()
        } else if internetAnswers {
            endOfflineBlock()
        }
        closeConversationsWhileBlocked()
        guard internetAnswers, downFor >= rebuildAfter, !isRebuilding, !Nexilis.sAPIKey.isEmpty,
              !API.bAVisOngoing() else {
            return
        }
        if let last = lastRebuild, Date().timeIntervalSince(last) < rebuildAfter {
            return
        }
        rebuildLink()
    }

    // MARK: - Offline, where the keys are never kept on the device

    /// Stops all reading because the phone is offline, the way Android does it.
    ///
    /// Where OfflinePolicy applies - secure folder encryption on, and the keys never kept on the
    /// device (secure_folder_offline "0", or HSA mode whatever the server says) - a phone with no
    /// connection reads nothing: every database query answers nil and no secure file is opened
    /// (Database.getRecords, FileEncryption.readSecure), as Android's CoreDataSqliteDB.fetch and
    /// SecureFileUtil do. The database stays open and the keys stay in memory - cut in four, see
    /// FileEncryption.aesKey - so reading starts again the moment the phone is online, with
    /// nothing to pull first. The chat lists empty themselves and say why; a conversation on
    /// screen is told it closes in five seconds, and then closes.
    ///
    /// This replaces closing the database and letting go of the keys, which made coming back
    /// online wait for the SDK and a fresh key pull before anything could be read again.
    private func beginOfflineBlock() {
        guard !OfflinePolicy.isBlocking, Utils.getSetProfile(), OfflinePolicy.applies else {
            return
        }
        OfflinePolicy.setBlocking(true)
        NXLogger.general.publicInfo("[Connect] offline saat app aktif - baca DB/berkas aman diblokir sampai online")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "disconnected_nexilis"), object: nil, userInfo: nil)
        closeConversationsWhileBlocked()
    }

    /// Reading is allowed again; the lists read the database again.
    private func endOfflineBlock() {
        guard OfflinePolicy.isBlocking else {
            return
        }
        OfflinePolicy.setBlocking(false)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "disconnected_nexilis"), object: nil, userInfo: nil)
        OutgoingThread.default.resendPending()
    }

    /// While reading is blocked, a conversation on screen - one that was open, or one opened from a
    /// notification - is told it cannot be read offline and closes five seconds later, as Android's
    /// ChatView/ChatWhisper do. Back online within those five seconds, it stays.
    private func closeConversationsWhileBlocked() {
        guard OfflinePolicy.isBlocking, !isClosingConversations, !API.bAVisOngoing() else {
            return
        }
        let screens = onScreenControllers()
        let hasConversation = screens.presented.contains(where: holdsConversation)
            || screens.stacks.contains(where: { $0.viewControllers.contains(where: ConnectionWatch.isConversation) })
        guard hasConversation else {
            return
        }
        isClosingConversations = true
        presentToast("You cannot open a chat when you're offline. The conversation will automatically close in 5 seconds.".localized(), duration: 5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            guard OfflinePolicy.isBlocking else {
                self.isClosingConversations = false
                return
            }
            self.closeOpenConversations {
                self.isClosingConversations = false
            }
        }
    }

    // MARK: - Missing keys (Android's checkOfflineInvState)

    /// After a key pull has finished, gives the keys ten seconds to be in place; if they are not,
    /// the app cannot be used and says so.
    private func checkInvalidStateSoon() {
        guard invalidStateCheck == nil, !isShowingInvalidState else {
            return
        }
        let work = DispatchWorkItem { [weak self] in
            self?.invalidStateCheck = nil
            self?.showInvalidStateIfKeysMissing()
        }
        invalidStateCheck = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: work)
    }

    /// Android's InvStateActivity: the keys a mode that never keeps them on the device needs could
    /// not be had, so nothing in the app can be read. The reader is told to reopen the app on a
    /// stable connection, and the app stops.
    private func showInvalidStateIfKeysMissing() {
        guard UIApplication.shared.applicationState == .active, !isShowingInvalidState,
              Utils.getSetProfile(), OfflinePolicy.applies,
              FileEncryption.shared.aesKey == nil || FileEncryption.shared.aesIV == nil,
              let host = UIApplication.shared.visibleViewController else {
            return
        }
        isShowingInvalidState = true
        let alert = LibAlertController(title: "Invalid App State!".localized(),
            message: "Please re-open app again, the application will automatically stop. To try again, please use stable connection!".localized(),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            exit(0)
        })
        host.present(alert, animated: true)
    }

    /// Opens the database again once the link is back, when it is closed and ought to be open.
    ///
    /// Covers a key pull on becoming active that failed for want of a connection (under the same conditions APIS.enterForeground pulls
    /// it). The keys are pulled, the database is opened with them as soon as they arrive, and the
    /// chat lists are told to read it again once it has its tables - not before.
    private func reopenDatabaseIfNeeded() {
        // Cheap questions first: this is asked every second while the link is up.
        guard !isReopening, Database.shared.database == nil else {
            return
        }
        guard Utils.getSecureFolderOffline() == "0", Utils.getSetProfile() else {
            return
        }
        // Only after a return from the background, never during a cold start - the start-up flow
        // opens the database itself, and a second opening racing it is what this must not cause.
        let afterForegroundPull = APIS.afterEnterBackground && Database.shared.database == nil && !Utils.isHSAMode()
        guard afterForegroundPull else {
            return
        }
        if let last = lastReopenAttempt, Date().timeIntervalSince(last) < 10 {
            return
        }
        isReopening = true
        lastReopenAttempt = Date()
        Nexilis.getFeatureAccess()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // The keys arrive with the feature-access answer.
            var waited: TimeInterval = 0
            while waited < 15, FileEncryption.shared.aesKey == nil || FileEncryption.shared.aesIV == nil {
                Thread.sleep(forTimeInterval: 0.1)
                waited += 0.1
            }
            guard FileEncryption.shared.aesKey != nil, FileEncryption.shared.aesIV != nil else {
                DispatchQueue.main.async { self?.isReopening = false }
                return
            }
            // An instance started on the return to the app may still be waiting for these very
            // keys and open itself a moment later; a second one is only made when it does not.
            waited = 0
            while waited < 1, Database.shared.database == nil {
                Thread.sleep(forTimeInterval: 0.1)
                waited += 0.1
            }
            if Database.shared.database == nil {
                Database.recreateInstance()
            }
            waited = 0
            while waited < 10, !Database.shared.isReady {
                Thread.sleep(forTimeInterval: 0.1)
                waited += 0.1
            }
            let ready = Database.shared.isReady
            DispatchQueue.main.async {
                self?.isReopening = false
                guard ready else {
                    return
                }
                // The lists found no database when they last read; this is them reading it again
                // (onDisconnected reloads from the database).
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "disconnected_nexilis"), object: nil, userInfo: nil)
                OutgoingThread.default.resendPending()
            }
        }
    }

    /// Takes every conversation off the screen, then runs `done`.
    ///
    /// A presented screen that is, or holds, a conversation is dismissed - with everything over
    /// it. Then any conversation pushed onto a navigation stack is popped back to the screen it
    /// was opened from, once anything presented over it has gone.
    private func closeOpenConversations(then done: @escaping () -> Void) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let screens = onScreenControllers()
        if let holder = screens.presented.first(where: { $0 !== screens.root && holdsConversation($0) }),
           let presenter = holder.presentingViewController {
            presenter.dismiss(animated: true) {
                self.popConversations()
                done()
            }
            return
        }
        if let pushed = onScreenControllers().stacks.first(where: { $0.viewControllers.contains(where: ConnectionWatch.isConversation) }),
           let over = pushed.presentedViewController {
            over.dismiss(animated: false) {
                self.popConversations()
                done()
            }
            return
        }
        popConversations()
        done()
    }

    /// A conversation this closes - not a Contact Center one, whose session is ContactCenterSession's.
    private static func isConversation(_ controller: UIViewController) -> Bool {
        if let personal = controller as? EditorPersonal {
            return !personal.isContactCenter
        }
        return controller is EditorGroup
    }

    private func holdsConversation(_ controller: UIViewController) -> Bool {
        if ConnectionWatch.isConversation(controller) {
            return true
        }
        return (controller as? UINavigationController)?.viewControllers.contains(where: ConnectionWatch.isConversation) ?? false
    }

    /// The app window's root, everything presented on it in order, and every navigation stack
    /// among them - the tabs' included.
    private func onScreenControllers() -> (root: UIViewController?, presented: [UIViewController], stacks: [UINavigationController]) {
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
        let root = windows.first(where: { $0.windowLevel == .normal && !$0.isHidden && $0.rootViewController != nil })?.rootViewController
        var presented: [UIViewController] = []
        var stacks: [UINavigationController] = []
        var next = root
        for _ in 0..<20 {
            guard let current = next else { break }
            presented.append(current)
            if let navigation = current as? UINavigationController {
                stacks.append(navigation)
            }
            if let tabs = current as? UITabBarController {
                stacks.append(contentsOf: (tabs.viewControllers ?? []).compactMap { $0 as? UINavigationController })
            }
            next = current.presentedViewController
        }
        return (root, presented, stacks)
    }

    private func popConversations() {
        for navigation in onScreenControllers().stacks {
            guard let first = navigation.viewControllers.firstIndex(where: ConnectionWatch.isConversation), first > 0 else {
                continue
            }
            navigation.popToViewController(navigation.viewControllers[first - 1], animated: true)
        }
    }

    /// Asks google.com whether the internet is really there - reachability only says a route exists.
    private func probeInternetIfDue() {
        if isProbing {
            return
        }
        if let last = lastProbe, Date().timeIntervalSince(last) < 5 {
            return
        }
        guard CheckConnection.isConnectedToNetwork(), let url = URL(string: "https://www.google.com/generate_204") else {
            internetAnswers = false
            return
        }
        isProbing = true
        lastProbe = Date()
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        probeSession.dataTask(with: request) { [weak self] _, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            DispatchQueue.main.async {
                self?.internetAnswers = error == nil && (200..<400).contains(status)
                self?.lastProbeAnswered = Date()
                self?.isProbing = false
            }
        }.resume()
    }

    /// Takes the SDK's link down and brings it up again - what a trip to the background and back
    /// amounts to, without the reader having to make it.
    private func rebuildLink() {
        isRebuilding = true
        lastRebuild = Date()
        rebuildAfter = min(rebuildAfter * 2, 60)
        NXLogger.general.publicInfo("[Connect] CLX terputus sementara internet tersedia - koneksi dibangun ulang")
        rebuildQueue.async { [weak self] in
            API.deinitConnection()
            Nexilis.hasInit = false
            _ = Nexilis.justInit(isChecking: true)
            DispatchQueue.main.async {
                self?.isRebuilding = false
            }
        }
    }
}

/// A slim "Connecting..." strip under the status bar, shown while the messaging link is down.
///
/// The same idea as the minimised-call strip, a third of its height: it sits in a window of its
/// own over every screen, and the screens underneath are moved down by its height so nothing is
/// hidden behind it.
final class ConnectingStrip {

    static let shared = ConnectingStrip()

    static let height: CGFloat = 26

    private var window: MiniCallBannerWindow?
    private var strip: UIView?
    private var stripTop: NSLayoutConstraint?
    private let insetControllers = NSHashTable<UIViewController>.weakObjects()
    private var insetTimer: Timer?

    private init() {}

    var isShowing: Bool {
        return window != nil
    }

    func show() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.show() }
            return
        }
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }
        let host = UIViewController()
        host.view.backgroundColor = .clear
        host.view.isUserInteractionEnabled = false

        let strip = UIView()
        strip.backgroundColor = .secondarySystemBackground
        strip.translatesAutoresizingMaskIntoConstraints = false
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        spinner.color = .secondaryLabel
        spinner.startAnimating()
        let label = UILabel()
        label.text = "Connecting...".localized()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        let row = UIStackView(arrangedSubviews: [spinner, label])
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        strip.addSubview(row)
        host.view.addSubview(strip)

        let window = MiniCallBannerWindow(windowScene: scene)
        window.backgroundColor = .clear
        window.windowLevel = .statusBar + 1
        window.rootViewController = host
        window.isHidden = false

        let top = strip.topAnchor.constraint(equalTo: host.view.safeAreaLayoutGuide.topAnchor, constant: topOffset())
        NSLayoutConstraint.activate([
            strip.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
            strip.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
            top,
            strip.heightAnchor.constraint(equalToConstant: ConnectingStrip.height),
            row.centerXAnchor.constraint(equalTo: strip.centerXAnchor),
            row.centerYAnchor.constraint(equalTo: strip.centerYAnchor)
        ])
        window.layoutIfNeeded()
        strip.alpha = 0
        UIView.animate(withDuration: 0.2) {
            strip.alpha = 1
        }
        self.window = window
        self.strip = strip
        self.stripTop = top
        refreshInsets()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.refreshInsets()
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        insetTimer = timer
    }

    func hide() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.hide() }
            return
        }
        guard let window = window else {
            return
        }
        insetTimer?.invalidate()
        insetTimer = nil
        for controller in insetControllers.allObjects {
            let restored = max(0, controller.additionalSafeAreaInsets.top - ConnectingStrip.height)
            UIView.animate(withDuration: 0.2) {
                controller.additionalSafeAreaInsets.top = restored
                controller.view.layoutIfNeeded()
            }
        }
        insetControllers.removeAllObjects()
        self.window = nil
        self.strip = nil
        self.stripTop = nil
        UIView.animate(withDuration: 0.2, animations: {
            window.rootViewController?.view.subviews.first?.alpha = 0
        }, completion: { _ in
            window.isHidden = true
            window.rootViewController = nil
        })
    }

    /// Below the minimised-call strip when there is one, so the two stack rather than overlap.
    private func topOffset() -> CGFloat {
        return MiniCallBannerManager.shared.isShowing ? MiniCallBanner.height : 0
    }

    /// Moves down every outermost screen that has not been moved down yet, as the call strip does.
    private func refreshInsets() {
        guard isShowing else {
            return
        }
        stripTop?.constant = topOffset()
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
        guard let root = windows.first(where: { !($0 is MiniCallBannerWindow) && !$0.isHidden && $0.rootViewController != nil })?.rootViewController else {
            return
        }
        var next: UIViewController? = root
        for _ in 0..<20 {
            guard let current = next else {
                break
            }
            if !(current is UIAlertController) && !insetControllers.contains(current) {
                insetControllers.add(current)
                UIView.animate(withDuration: 0.2) {
                    current.additionalSafeAreaInsets.top += ConnectingStrip.height
                    current.view.layoutIfNeeded()
                }
            }
            next = current.presentedViewController
        }
    }
}

/// Android's "prevent offline" (UtilSecurity.isPreventOffline): where the keys are never kept on
/// the device, nothing is read while the phone is offline.
public enum OfflinePolicy {

    private static let lock = NSLock()
    private static var blocking = false

    /// Whether reading is blocked right now. Asked by every query, so it is a flag, not a lookup.
    public static var isBlocking: Bool {
        lock.lock()
        defer { lock.unlock() }
        return blocking
    }

    static func setBlocking(_ value: Bool) {
        lock.lock()
        blocking = value
        lock.unlock()
    }

    /// Whether this app is one where offline means no reading: secure folder encryption on, and
    /// the keys not kept on the device - secure_folder_offline "0", or HSA mode, which Android
    /// treats as "0" whatever the server sends (SharedObj.getEnableSecureFolderRegularMode).
    static var applies: Bool {
        return Nexilis.checkingAccess(key: "secure_folder_encrypt")
            && (Utils.getSecureFolderOffline() == "0" || Utils.isHSAMode())
    }

    /// What an emptied chat list shows while reading is blocked, and nothing once it is not -
    /// Android's "You cannot open a conversation when you're offline."
    public static func applyEmptyState(to tableView: UITableView) {
        guard isBlocking else {
            if tableView.backgroundView?.tag == OfflinePolicy.emptyStateTag {
                tableView.backgroundView = nil
            }
            return
        }
        if tableView.backgroundView?.tag == OfflinePolicy.emptyStateTag {
            return
        }
        let label = UILabel()
        label.text = "You cannot open a conversation when you're offline.".localized()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        let holder = UIView()
        holder.tag = OfflinePolicy.emptyStateTag
        holder.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: holder.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: holder.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: holder.trailingAnchor, constant: -32)
        ])
        tableView.backgroundView = holder
    }

    private static let emptyStateTag = 0x0FF11E
}
