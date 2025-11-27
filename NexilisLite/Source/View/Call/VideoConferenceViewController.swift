//
//  VideoViewControllerQmera.swift
//  Qmera
//
//  Created by Akhmad Al Qindi Irsyam on 07/10/21.
//

// Rn
// (Kedip whiteboard)
// extension Whiteboard
// wbVC!.close wbTimer wbBlink

import UIKit
import nuSDKService
import AVFoundation
import NotificationBannerSwift
import MediaPlayer

class VideoConferenceViewController: UIViewController {
    static private var nMaxSPOn: Float! = 20.0
    static private var nMaxSPOff: Float! = 20.0
    static private var volumeView: MPVolumeView!
    static private var lastVolume: Float! = AVAudioSession.sharedInstance().outputVolume
    static private var bSpeakerPhone: Bool! = false
    private var tempSpeaker = false
    private var timerSpeaker: Timer?
    static private var isLoop = false
    
    
    var dataPerson: [[String: String?]] = []
    var fPin = ""
    var wbRoomId = ""
    var isInisiator = true
    var isSpeaker = false
    var isMuted = false
    var isPresent = false
    var isNavigationHidden = false
    var rotateMyView = false
    var listRemoteViewFix: [UIImageView] = [
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView()
    ]
    var containerLabelName: [UIView] = [
        UIView(),
        UIView(),
        UIView(),
        UIView(),
        UIView(),
        UIView(),
        UIView(),
        UIView(),
        UIView(),
        UIView()
    ]
    var imageMuted: [UIImageView] = [
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView()
    ]
    var mutedZoom: UIImageView = {
        let image = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 40))
        image.contentMode = .scaleAspectFit
        image.image = UIImage(systemName: "mic.slash")
        image.tintColor = .red
        image.isHidden = true
        return image
    }()
    let buttonDecline = UIButton()
    let buttonAccept = UIButton()
    let zoomView = UIImageView()
    let cameraView = UIImageView()
    var constraintLeadingButtonDecline = NSLayoutConstraint()
    var constraintBottomButtonDecline = NSLayoutConstraint()
    var constraintBottomStackViewToolbar = NSLayoutConstraint()
    var constraintLeftStackViewToolbar2 = NSLayoutConstraint()
    let stackViewToolbar = UIStackView()
    let stackViewToolbar2 = UIStackView()
    let stackViewToolbar3 = UIStackView()
    var onScreenConstraintWB = [NSLayoutConstraint]()
    let buttonWB = UIButton()
    let buttonChat = UIButton()
    var wbVC : WhiteboardViewController?
    let buttonSpeaker = UIButton()
    let buttonRotate = UIButton()
    let buttonMuted = UIButton()
    let buttonZoom = UIButton()
    var showStackViewToolbar = true
    let scrollRemoteView = UIScrollView()
    var isAutoAccept = false
    var wbTimer = Timer()
    var wbBlink = false
    var showNotifCCEnd = false
    var transformZoomAfterNewUserMore2 = false
    var isAddCall = ""
    var ticketId = ""
    var roomId = ""
    var isCalled = false
    var isZoomIn = true
    private var frontCamera = true
    var users: [User] = []
    let poweredByView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 5
        return stackView
    }()
    private var vcTimer = Timer()
    private var containerTimerVC = UIView()
    private var labelTimerVC = UILabel()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Waiting for others\nto join"
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "video.fill"))
        imageView.tintColor = .darkGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let roomLabel: UILabel = {
        let label = UILabel()
        label.text = "Video Conference Room"
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "The meeting will start once others join"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()
    
    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            iconView,
            roomLabel,
            subtitleLabel
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = UIColor.systemGray5
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        return button
    }()
    
    let poweredByLabel: UILabel = {
        let label = UILabel()
        label.text = "Powered by Nexilis".localized()
        return label
    }()
    
    let nexilisLogo: UIButton = {
        let image = UIImage(named: "pb_powered_button", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
//        button.frame.size.width = 30
//        button.frame.size.height = 30
        return button
    }()
    
    private let animatedLabel: UILabel = {
        let label = UILabel()
        label.text = "Joining room"
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.startAnimating()
        return indicator
    }()

    private lazy var joiningStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            animatedLabel,
            activityIndicator
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        return stack
    }()
    
    private var joiningTimer: Timer?
    private var dotCount = 0
    private var blurView: UIVisualEffectView!
    
    static func turnSpeakerOn() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.overrideOutputAudioPort(bSpeakerPhone ? .speaker : .none)
        } catch {
            
        }
//        var bAudioEngineIsAvtive: Bool! = false
//        API.turnSpeakerPhone(bSPon: bSpeakerPhone)
//        repeat {
//            Thread.sleep(forTimeInterval : 0.3)
//            bAudioEngineIsAvtive = API.bAudioEngineIsRunning()
//            print("Audio Session State: \(bAudioEngineIsAvtive ? "Active" : "Inactive" )")
//            if (bAudioEngineIsAvtive) {
//                break
//            }
//            API.restartAudioEngine()
//        } while (!bAudioEngineIsAvtive)
//        var volume:Float! = 0
//        if (bSpeakerPhone) {
//            volume = lastVolume * nMaxSPOn
//        } else {
//            volume = lastVolume * nMaxSPOff
//        }
//        API.adjustVolume(fValue: volume)
    }

//    static func toggleSpeakerPhone() {
//        bSpeakerPhone = !bSpeakerPhone
//        var volume:Float! = 0
//        if (bSpeakerPhone) {
//            volume = lastVolume * nMaxSPOn
//        } else {
//            volume = lastVolume * nMaxSPOff
//        }
//        API.adjustVolume(fValue: volume)
//    }
    
    deinit {
        navigationController?.changeAppearance(clear: false)
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.topItem?.backBarButtonItem = nil
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        NotificationCenter.default.removeObserver(self)
        Nexilis.floatingButton.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            navigationController?.changeAppearance(clear: false)
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            navigationController?.navigationBar.titleTextAttributes = textAttributes
            navigationController?.navigationBar.topItem?.backBarButtonItem = nil
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            NotificationCenter.default.removeObserver(self)
        }
        Nexilis.floatingButton.isHidden = false
    }
    
    private func backToDefaultAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP, .mixWithOthers])
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setPreferredSampleRate(48000)
            try audioSession.setActive(true)
        } catch {
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Nexilis.setWhiteboardReceiver(receiver: self)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.changeAppearance(clear: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onStatusCall(_:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusCall), object: nil)
        
        view.backgroundColor = .clear
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        navigationItem.setHidesBackButton(true, animated: false)
        if fPin != ""{
            getDataProfile(fPin: fPin)
        }
        backToDefaultAudioSession()
        addZoomView()
        addCameraView()
        addListRemoteView()
        addToolbar()
        addTimerVC()
        if isInisiator && !isCalled {
            addWaitingForOthersView()
            initiateConfRoom()
        } else if !isCalled {
            addJoiningView()
            joinConfRoom()
        }
        isCalled = true
    }
    
    private func initiateConfRoom() {
        API.initiateCR(sConfRoom: roomId, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView, ivRemoteZ: zoomView)
        _ = Nexilis.write(message: CoreMessage_TMessageBank.startVCallConference(blog_id: roomId, time: "\(Date().currentTimeMillis())"))
    }
    
    private func joinConfRoom() {
        API.joinCR(sConfRoom: roomId, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView, ivRemoteZ: zoomView)
        _ = Nexilis.write(message: CoreMessage_TMessageBank.joinVCallConference(blog_id: roomId))
    }
    
    func getDataProfile(fPin: String) {
        let query = "SELECT f_pin, first_name, last_name, official_account, image_id, device_id, offline_mode, user_type FROM BUDDY where f_pin = '\(fPin)'"
        Database.shared.database?.inTransaction({ (fmdb, rollback) in
            do {
                if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                    var row: [String: String?] = [:]
                    if cursorData.next() {
                        row["f_pin"] = cursorData.string(forColumnIndex: 0)
                        var name = ""
                        if let firstname = cursorData.string(forColumnIndex: 1) {
                            name = firstname
                        }
                        if let lastname = cursorData.string(forColumnIndex: 2) {
                            name = name + " " + lastname
                        }
                        row["name"] = name
                        row["picture"] = cursorData.string(forColumnIndex: 4)
                        row["isOfficial"] = cursorData.string(forColumnIndex: 3)
                        row["deviceId"] = cursorData.string(forColumnIndex: 5)
                        row["isOffline"] = cursorData.string(forColumnIndex: 6)
                        row["user_type"] = cursorData.string(forColumnIndex: 7)
                        if fPin != User.getMyPin() {
                            dataPerson.append(row)
                        }
                    } else {
                        var row: [String: String?] = [:]
                        row["f_pin"] = fPin
                        row["name"] = "User".localized()
                        row["picture"] = ""
                        row["isOfficial"] = ""
                        row["deviceId"] = ""
                        row["isOffline"] = ""
                        row["user_type"] = ""
                        dataPerson.append(row)
                    }
                    cursorData.close()
                } else {
                    var row: [String: String?] = [:]
                    row["f_pin"] = fPin
                    row["name"] = "User".localized()
                    row["picture"] = ""
                    row["isOfficial"] = ""
                    row["deviceId"] = ""
                    row["isOffline"] = ""
                    row["user_type"] = ""
                    dataPerson.append(row)
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    func addTimerVC() {
        view.addSubview(containerTimerVC)
        containerTimerVC.anchor(top: view.safeAreaLayoutGuide.topAnchor, centerX: view.centerXAnchor, minHeight: 40, minWidth: 40)
        containerTimerVC.makeRoundedView(radius: 8)
        containerTimerVC.backgroundColor = .black.withAlphaComponent(0.3)
        containerTimerVC.addSubview(labelTimerVC)
        labelTimerVC.anchor(left: containerTimerVC.leftAnchor, right: containerTimerVC.rightAnchor, paddingLeft: 8, paddingRight: 8, centerX: containerTimerVC.centerXAnchor, centerY: containerTimerVC.centerYAnchor)
        labelTimerVC.textColor = .white
        containerTimerVC.isHidden = true
    }
    
    func addZoomView() {
        view.addSubview(zoomView)
        zoomView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zoomView.topAnchor.constraint(equalTo: view.topAnchor),
            zoomView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            zoomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            zoomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        zoomView.backgroundColor = .secondaryColor
        zoomView.isUserInteractionEnabled = true
        zoomView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideToolbar)))
    }
    
    func addCameraView() {
        view.addSubview(cameraView)
//        cameraView.frame = CGRect(x: view.frame.width - 130, y: 20, width: 120, height: 160)
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10.0),
            cameraView.widthAnchor.constraint(equalToConstant: 120.0),
            cameraView.heightAnchor.constraint(equalToConstant: 160.0)
        ])
        cameraView.backgroundColor = .secondaryColor
        cameraView.makeRoundedView(radius: 8)
    }
    
    func addListRemoteView() {
        view.addSubview(scrollRemoteView)
        scrollRemoteView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollRemoteView.topAnchor.constraint(equalTo: cameraView.bottomAnchor, constant: 10),
            scrollRemoteView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            scrollRemoteView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            scrollRemoteView.widthAnchor.constraint(equalToConstant: 120.0)
        ])
        
        scrollRemoteView.showsHorizontalScrollIndicator = false
        scrollRemoteView.showsVerticalScrollIndicator = false
        scrollRemoteView.contentSize.width = 120.0
        scrollRemoteView.backgroundColor = .clear
    }
    
    func addWaitingForOthersView() {
        view.addSubview(contentStack)
        view.addSubview(cancelButton)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),

            contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            cancelButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    func addJoiningView() {
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)
        
        view.addSubview(joiningStack)
        joiningStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            joiningStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            joiningStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            joiningStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            joiningStack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        joiningTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.dotCount = (self.dotCount + 1) % 4
            let dots = String(repeating: ".", count: self.dotCount)
            self.animatedLabel.text = "Joining room\(dots)"
        }
    }
    
    func addToolbar(resetToolbar: Bool = false) {
        view.addSubview(buttonDecline)
        buttonDecline.translatesAutoresizingMaskIntoConstraints = false
        buttonDecline.frame.size = CGSize(width: 70.0, height: 70.0)
        if isInisiator || resetToolbar {
            constraintLeadingButtonDecline = buttonDecline.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        } else {
            constraintLeadingButtonDecline = buttonDecline.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: view.frame.width * 0.2)
        }
        constraintBottomButtonDecline = buttonDecline.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60.0)
        NSLayoutConstraint.activate([
            constraintBottomButtonDecline,
            constraintLeadingButtonDecline,
            buttonDecline.widthAnchor.constraint(equalToConstant: 70.0),
            buttonDecline.heightAnchor.constraint(equalToConstant: 70.0)
        ])
        buttonDecline.backgroundColor = .red
        buttonDecline.circle()
        buttonDecline.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        buttonDecline.tintColor = .white
        buttonDecline.addTarget(self, action: #selector(didTapDeclineCallButton(sender:)), for: .touchUpInside)
        buttonDecline.isHidden = true
    }
    
    @objc private func cancelPressed() {
        endAllCall()
        if self.isInisiator && !self.isPresent {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func onReceiveMessage(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            if let dataMessage = data["message"] as? TMessage {
                if (dataMessage.getCode() == CoreMessage_TMessageCode.PUSH_MEMBER_ROOM_CONTACT_CENTER) {
                    let data = dataMessage.getBody(key: CoreMessage_TMessageKey.DATA)
                    if !data.isEmpty {
                        if let jsonArray = try! JSONSerialization.jsonObject(with: data.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [AnyObject] {
                            var members = ""
                            let idMe = User.getMyPin()!
                            for json in jsonArray {
                                if "\(json)" != idMe {
                                    if members.isEmpty {
                                        members = "\(json)"
                                    } else {
                                        members += ",\(json)"
                                    }
                                }
                            }
                            SecureUserDefaults.shared.set("\(members)", forKey: "membersCC")
                        }
                    }
                }
            }
        }
    }
    
    @objc func didTapDeclineCallButton(sender: AnyObject){
        let alert = LibAlertController(title: "End Conference Room".localized(), message: "Are you sure you want to end conference video call?".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
            if self.stackViewToolbar.isDescendant(of: self.view){
                self.stackViewToolbar.removeFromSuperview()
            }
            if self.stackViewToolbar2.isDescendant(of: self.view){
                self.stackViewToolbar2.removeFromSuperview()
            }
            if self.buttonWB.isDescendant(of: self.view){
                self.buttonWB.removeFromSuperview()
            }
            if self.buttonChat.isDescendant(of: self.view){
                self.buttonChat.removeFromSuperview()
            }
            if self.buttonDecline.isDescendant(of: self.view) {
                self.buttonDecline.removeFromSuperview()
            }
            if self.buttonAccept.isDescendant(of: self.view) {
                self.buttonAccept.removeFromSuperview()
            }
            if self.buttonRotate.isDescendant(of: self.view) {
                self.buttonRotate.removeFromSuperview()
            }
            if self.buttonMuted.isDescendant(of: self.view) {
                self.buttonMuted.removeFromSuperview()
            }
            if self.wbVC != nil{
                self.wbVC!.close?()
            }
            self.wbTimer.invalidate()
            self.vcTimer.invalidate()
            self.endAllCall()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.isInisiator && !self.isPresent {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }))
        self.present(alert, animated: true, completion: nil)
    
    }
    
    @objc func didTapAcceptCallButton() {
        if !isInisiator{
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
            joiningTimer?.invalidate()
            blurView.removeFromSuperview()
            joiningStack.removeFromSuperview()
        } else {
            contentStack.removeFromSuperview()
            cancelButton.removeFromSuperview()
        }
        DispatchQueue.main.async {
            NSLayoutConstraint.deactivate([
                self.constraintLeadingButtonDecline,
                self.constraintBottomButtonDecline
            ])
            self.buttonDecline.isHidden = false
            self.addToolbarAfterAccept()
            self.buttonDecline.setImage(UIImage(systemName: "phone.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            UIView.animate(withDuration: 1.0, animations: {
                self.view.layoutIfNeeded()
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.containerTimerVC.isHidden = false
                self.buttonRotate.isHidden = false
                self.buttonSpeaker.isHidden = false
                self.poweredByView.isHidden = false
                self.buttonMuted.isHidden = false
                let connectDate = Date()
                self.vcTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    let format = Utils.callDurationFormatter.string(from: Date().timeIntervalSince(connectDate))
                    self.labelTimerVC.text = format
                }
                self.vcTimer.fire()
            }
        }
        
    }
    
    @objc func didTapChatButton(){
        let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
        let members: String = SecureUserDefaults.shared.value(forKey: "membersCC") ?? ""
        let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
        let editorPersonalVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorPersonalVC") as! EditorPersonal
        editorPersonalVC.hidesBottomBarWhenPushed = true
        editorPersonalVC.unique_l_pin = officer
        editorPersonalVC.fromNotification = true
        editorPersonalVC.isContactCenter = true
        editorPersonalVC.fPinContacCenter = members
        editorPersonalVC.complaintId = ticketId
        editorPersonalVC.onGoingCC = true
        editorPersonalVC.isRequestContactCenter = false
        editorPersonalVC.users = users
        editorPersonalVC.fromVCAC = true
        let navigationController = CustomNavigationController(rootViewController: editorPersonalVC)
        navigationController.modalPresentationStyle = .overCurrentContext
        navigationController.navigationBar.tintColor = .white
//        navigationController.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.overrideUserInterfaceStyle = .dark
        navigationController.navigationBar.barStyle = .black
        let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController.navigationBar.titleTextAttributes = textAttributes
        if UIApplication.shared.visibleViewController?.navigationController != nil {
            UIApplication.shared.visibleViewController?.navigationController?.present(navigationController, animated: true, completion: nil)
        } else {
            UIApplication.shared.visibleViewController?.present(navigationController, animated: true, completion: nil)
        }
    }
    
    @objc func didTapWBButton(){
        if(wbVC == nil){
            wbVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "wbVC") as? WhiteboardViewController
            if(wbRoomId.isEmpty){
                let me = User.getMyPin()!
                let tid = CoreMessage_TMessageUtil.getTID()
                wbRoomId = "\(me)wbvc\(tid)"
                wbVC!.roomId = wbRoomId
                var destinations = [String]()
                var destString = ""
                for d in dataPerson{
                    destinations.append(d["f_pin"]!!)
                    if destString.isEmpty{
                        destString = d["f_pin"]!!
                    } else {
                        destString = destString + ",\(d["f_pin"]!!)"
                    }
                }
                wbVC!.destinations = destinations
                wbVC!.sendInit()
                SecureUserDefaults.shared.set("\(me),\(destString)", forKey: "wb_vc")
            }
            else {
                self.wbTimer.invalidate()
                self.buttonWB.backgroundColor = .lightGray
                wbVC!.roomId = wbRoomId
                wbVC!.sendJoin()
            }
        }
        wbVC!.close = {
            DispatchQueue.main.async {
                if self.wbVC!.view.isDescendant(of: self.view){
                    self.wbVC!.view.removeFromSuperview()
                }
                self.buttonDecline.isHidden = false
                self.buttonSpeaker.isHidden = false
                self.buttonRotate.isHidden = false
                self.buttonZoom.isHidden = false
//                if(!self.wbRoomId.isEmpty){
//                    DispatchQueue.main.async {
//                        self.wbTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.runTimer), userInfo: nil, repeats: true)
//                    }
//                }
            }
        }
        self.buttonDecline.isHidden = true
        self.buttonSpeaker.isHidden = true
        self.buttonRotate.isHidden = true
        self.buttonZoom.isHidden = true
        addChild(wbVC!)
        wbVC!.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wbVC!.view)
        onScreenConstraintWB = [
            wbVC!.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            wbVC!.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            wbVC!.view.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            wbVC!.view.leftAnchor.constraint(equalTo: self.view.leftAnchor),
        ]
           NSLayoutConstraint.activate(onScreenConstraintWB)
             
           // Notify the child view controller that the move is complete.
           wbVC!.didMove(toParent: self)
//        self.navigationController?.setNavigationBarHidden(false, animated: true)
//        controller.modalPresentationStyle = .overCurrentContext
//        self.navigationController?.present(controller, animated: true)
    }
    
    func addToolbarAfterAccept() {
        view.addSubview(self.stackViewToolbar)
        self.stackViewToolbar.translatesAutoresizingMaskIntoConstraints = false
        constraintBottomStackViewToolbar = self.stackViewToolbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -60.0)
        NSLayoutConstraint.activate([
            self.stackViewToolbar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            constraintBottomStackViewToolbar
        ])
        self.stackViewToolbar.axis = .horizontal
        self.stackViewToolbar.distribution = .equalSpacing
        self.stackViewToolbar.alignment = .center
        self.stackViewToolbar.spacing = 30
        
        view.addSubview(self.stackViewToolbar3)
        self.stackViewToolbar3.anchor(bottom: self.stackViewToolbar.topAnchor, paddingBottom: 10, centerX: self.view.centerXAnchor)
        self.stackViewToolbar3.axis = .horizontal
        self.stackViewToolbar3.distribution = .equalSpacing
        self.stackViewToolbar3.alignment = .center
        self.stackViewToolbar3.spacing = 30
        
        view.addSubview(buttonRotate)
        buttonRotate.translatesAutoresizingMaskIntoConstraints = false
        buttonRotate.frame.size = CGSize(width: 70.0, height: 70.0)
        NSLayoutConstraint.activate([
            buttonRotate.widthAnchor.constraint(equalToConstant: 70.0),
            buttonRotate.heightAnchor.constraint(equalToConstant: 70.0),
        ])
        buttonRotate.backgroundColor = .secondaryColor
        buttonRotate.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        buttonRotate.tintColor = .mainColor
        buttonRotate.circle()
        buttonRotate.isHidden = true
        buttonRotate.addTarget(self, action: #selector(camera(sender:)), for: .touchUpInside)
        
        view.addSubview(buttonMuted)
        buttonMuted.translatesAutoresizingMaskIntoConstraints = false
        buttonMuted.frame.size = CGSize(width: 70.0, height: 70.0)
        NSLayoutConstraint.activate([
            buttonMuted.widthAnchor.constraint(equalToConstant: 70.0),
            buttonMuted.heightAnchor.constraint(equalToConstant: 70.0),
        ])
        buttonMuted.backgroundColor = .secondaryColor
        buttonMuted.setImage(UIImage(systemName: "mic", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        buttonMuted.tintColor = .mainColor
        buttonMuted.circle()
        buttonMuted.isHidden = true
        buttonMuted.addTarget(self, action: #selector(muted(sender:)), for: .touchUpInside)
        
        view.addSubview(buttonSpeaker)
        buttonSpeaker.translatesAutoresizingMaskIntoConstraints = false
        buttonSpeaker.frame.size = CGSize(width: 70.0, height: 70.0)
        NSLayoutConstraint.activate([
            buttonSpeaker.widthAnchor.constraint(equalToConstant: 70.0),
            buttonSpeaker.heightAnchor.constraint(equalToConstant: 70.0)
        ])
        buttonSpeaker.backgroundColor = .secondaryColor
        buttonSpeaker.tintColor = .mainColor
        buttonSpeaker.setImage(UIImage(systemName: "speaker.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        buttonSpeaker.circle()
        buttonSpeaker.isHidden = true
        buttonSpeaker.addTarget(self, action: #selector(didTapSpeakerButton(sender:)), for: .touchUpInside)
        
        view.addSubview(self.stackViewToolbar2)
        self.stackViewToolbar2.translatesAutoresizingMaskIntoConstraints = false
        constraintLeftStackViewToolbar2 = self.stackViewToolbar2.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 10.0)
        NSLayoutConstraint.activate([
            self.stackViewToolbar2.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            constraintLeftStackViewToolbar2
        ])
        self.stackViewToolbar2.axis = .vertical
        self.stackViewToolbar2.distribution = .equalSpacing
        self.stackViewToolbar2.alignment = .center
        self.stackViewToolbar2.spacing = 5
        
        view.addSubview(buttonWB)
        buttonWB.translatesAutoresizingMaskIntoConstraints = false
        buttonWB.frame.size = CGSize(width: 40.0, height: 40.0)
        NSLayoutConstraint.activate([
            buttonWB.widthAnchor.constraint(equalToConstant: 40.0),
            buttonWB.heightAnchor.constraint(equalToConstant: 40.0)
        ])
        buttonWB.backgroundColor = .lightGray
        buttonWB.setImage(UIImage(systemName: "ipad.landscape", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)), for: .normal)
        buttonWB.circle()
        buttonWB.tintColor = .black
        buttonWB.isHidden = true
        buttonWB.addTarget(self, action: #selector(didTapWBButton), for: .touchUpInside)
        
        view.addSubview(poweredByView)
        self.poweredByView.translatesAutoresizingMaskIntoConstraints = false
        let constraintRightPowered =  self.poweredByView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -10.0)
        let constraintBottomPowered = self.poweredByView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10.0)
        NSLayoutConstraint.activate([
            constraintRightPowered,
            constraintBottomPowered,
            nexilisLogo.widthAnchor.constraint(equalToConstant: 30.0),
            nexilisLogo.heightAnchor.constraint(equalToConstant: 30.0)
        ])
        
        poweredByView.addArrangedSubview(poweredByLabel)
        poweredByView.addArrangedSubview(nexilisLogo)
        poweredByView.isHidden = true
        
        stackViewToolbar.addArrangedSubview(buttonDecline)
        stackViewToolbar.addArrangedSubview(buttonSpeaker)
        stackViewToolbar3.addArrangedSubview(buttonRotate)
        stackViewToolbar3.addArrangedSubview(buttonMuted)
    }
    
    @objc func muted(sender: Any?) {
        isMuted = !isMuted
        API.mmc(int: 1, boolean: isMuted)
        DispatchQueue.main.async {
            if (self.isMuted) {
                self.buttonMuted.backgroundColor = .lightGray
                self.buttonMuted.tintColor = .mainColor
                self.buttonMuted.setImage(UIImage(systemName: "mic.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            } else {
                self.buttonMuted.backgroundColor = .secondaryColor
                self.buttonMuted.tintColor = .mainColor
                self.buttonMuted.setImage(UIImage(systemName: "mic", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            }
        }
    }
    
    func endAllCall() {
        _ = Nexilis.write(message: CoreMessage_TMessageBank.endVCallConference(blog_id: roomId))
        API.terminateCall(sParty: nil)
        cameraView.image = nil
        zoomView.image = nil
        listRemoteViewFix.removeAll()
        dataPerson.removeAll()
    }
    
    func setSpeaker() {
        DispatchQueue.main.async {
            self.timerSpeaker?.invalidate()
            self.tempSpeaker = !self.tempSpeaker
            if (self.tempSpeaker) {
                self.buttonSpeaker.backgroundColor = .lightGray
                self.buttonSpeaker.tintColor = .mainColor
                self.buttonSpeaker.setImage(UIImage(systemName: "speaker.wave.2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            } else {
                self.buttonSpeaker.backgroundColor = .secondaryColor
                self.buttonSpeaker.tintColor = .mainColor
                self.buttonSpeaker.setImage(UIImage(systemName: "speaker.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            }
            self.timerSpeaker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {_ in
                if VideoConferenceViewController.bSpeakerPhone != self.tempSpeaker {
                    VideoConferenceViewController.bSpeakerPhone = !VideoConferenceViewController.bSpeakerPhone
                    self.tempSpeaker = VideoConferenceViewController.bSpeakerPhone
                    DispatchQueue.global().async {
                        VideoConferenceViewController.turnSpeakerOn()
                    }
                }
            })
        }
    }
    
    @objc func didTapSpeakerButton(sender: AnyObject){
        setSpeaker()
    }
    
    @objc func didTapZoomButton(sender: AnyObject){
        let scaleX = self.view.bounds.height / self.view.bounds.width
        let scaleY = self.view.bounds.width / self.view.bounds.height
        if isZoomIn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        UIView.animate(withDuration: 0.5, animations: {
                            self.zoomView.transform = CGAffineTransform(scaleX: -0.5 * scaleY, y: 0.5 * scaleX).rotated(by: -(CGFloat.pi * 3)/2)
                        })
                    }
            buttonZoom.setImage(UIImage(systemName: "plus.magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        UIView.animate(withDuration: 0.5, animations: {
                            self.zoomView.transform = CGAffineTransform(scaleX: -scaleY, y: scaleX).rotated(by: -(CGFloat.pi * 3)/2)
                        })
                    }
            buttonZoom.setImage(UIImage(systemName: "minus.magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        }
        isZoomIn = !isZoomIn
    }
    
    @objc func didTapAddParticipantButton(sender: AnyObject){
        if let contactViewController = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "contactSID") as? ContactCallViewController {
            contactViewController.isAddParticipantVideo = true
            contactViewController.connectedCall = dataPerson
            contactViewController.isDismiss = { data in
                let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                if !onGoingCC.isEmpty {
                    DispatchQueue.global().async {
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.getCCRoomInvite(l_pin: data["f_pin"]!!, ticket_id: onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[2], channel: "2"))
                    }
                    DispatchQueue.main.async {
                        self.isAddCall = data["f_pin"]!!
                    }
                } else {
                    DispatchQueue.main.async {
                        self.dataPerson.append(data)
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.inviteVCallConference(f_pin: data["f_pin"]!!, blog_id: self.roomId))
                    }
                }
            }
            present(CustomNavigationController(rootViewController: contactViewController), animated: true, completion: nil)
        }
    }
    
    @objc func camera(sender: Any?) {
        if frontCamera {
            API.changeCameraParam(nCameraIdx: 0, nResolutionIndex: 0, nQuality: 0)
            frontCamera = false
        } else {
            API.changeCameraParam(nCameraIdx: 1, nResolutionIndex: 0, nQuality: 0)
            frontCamera = true
        }
    }
    
    @objc func hideToolbar() {
        DispatchQueue.main.async {
            if self.showStackViewToolbar {
                self.showStackViewToolbar = false
                self.constraintBottomStackViewToolbar.constant = 150
                self.constraintLeftStackViewToolbar2.constant = -60
                UIView.animate(withDuration: 0.35, animations: {
                    self.view.layoutIfNeeded()
                })
            } else {
                self.showStackViewToolbar = true
                self.constraintBottomStackViewToolbar.constant = -60
                self.constraintLeftStackViewToolbar2.constant = 10
                UIView.animate(withDuration: 0.35, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    @objc func onStatusCall(_ notification: NSNotification) {
        let data = notification.userInfo
        let state = (data?["state"] ?? 0) as! Int
        let message = (data?["message"] ?? "") as! String
        var remoteChannel = [String:String]()
        let arrayMessage = message.split(separator: ",")
        if state == Nexilis.AUDIO_VIDEO_CALL_MUTED {
            DispatchQueue.main.async { [self] in
                if self.dataPerson.count == 1 {
                    var param = arrayMessage[1]
                    if arrayMessage[2] != "." {
                        param = arrayMessage[2]
                    }
                    if param == "1" {
                        mutedZoom.isHidden = false
                    } else {
                        mutedZoom.isHidden = true
                    }
                }
            }
        } else if (state == Nexilis.VIDEO_CALL_ZOOM) && self.dataPerson.count > 1 {
            DispatchQueue.main.async {
                if arrayMessage[0] != arrayMessage[3] && !self.rotateMyView {
                    self.zoomView.transform   = CGAffineTransform.init(scaleX: 1.9, y: 2.0).rotated(by: (CGFloat.pi)/2)
                    self.zoomView.contentMode = .scaleAspectFit
                } else {
                    self.rotateMyView = true
                    self.zoomView.transform   = CGAffineTransform.init(scaleX: 1.9, y: 2.0).rotated(by: (-CGFloat.pi)/2)
                    self.zoomView.contentMode = .scaleAspectFit
                }
            }
        } else if (state == Nexilis.VIDEO_CAMERA_PARAMS_CHANED){
            if(arrayMessage[3] == "0"){
                DispatchQueue.main.async {
                    if self.dataPerson.count == 1 && arrayMessage[2] == "1" && arrayMessage[4] == "1" {
                        self.zoomView.transform = CGAffineTransform.init(scaleX: 1.9, y: 2.0).rotated(by: (-CGFloat.pi)/2)
                    } else {
                        self.zoomView.transform = CGAffineTransform.init(scaleX: 1.9, y: 2.0).rotated(by: (CGFloat.pi)/2)
                    }
                }
            }
        }
        else if state == Nexilis.STREAMING_SEMINAR_ENDED { // always call turnspeaker
            DispatchQueue.main.async {
                self.buttonSpeaker.isEnabled = false
            }
            VideoConferenceViewController.isLoop = true
            DispatchQueue.global(qos: .userInitiated).async {
                var countLoop = 0
                repeat {
                    Thread.sleep(forTimeInterval : 0.5)
                    if (VideoConferenceViewController.isLoop && !API.bAudioEngineIsRunning()) {
                        API.restartAudioEngine()
                        DispatchQueue.main.async {
                            if !self.buttonSpeaker.isEnabled{
                                self.setSpeaker()
                                self.buttonSpeaker.isEnabled = true
                            } else if VideoConferenceViewController.bSpeakerPhone {
                                do {
                                    let audioSession = AVAudioSession.sharedInstance()
                                    try audioSession.overrideOutputAudioPort(.speaker)
                                } catch {
                                    
                                }
                            }
                        }
                    }
                    countLoop = countLoop + 1
                    if countLoop == 3 {
                        DispatchQueue.main.async {
                            if !self.buttonSpeaker.isEnabled{
                                self.setSpeaker()
                                self.buttonSpeaker.isEnabled = true
                            }
                        }
                    }
                } while (VideoConferenceViewController.isLoop)
            }
        }
        else if (state == Nexilis.VIDEO_CALL_OFFHOOK) {
            let channel = arrayMessage[3]
            remoteChannel[String(channel)] = String(arrayMessage[5])
            DispatchQueue.main.async {
                if self.dataPerson.count == 0 {
                    self.getDataProfile(fPin: String(arrayMessage[1]))
                }
                if (self.dataPerson.count == 1 && String(arrayMessage[1]) != self.dataPerson[0]["f_pin"]!!) {
                    self.getDataProfile(fPin: String(arrayMessage[1]))
                    for i in 0...1 {
                        self.scrollRemoteView.addSubview(self.listRemoteViewFix[i])
                        self.listRemoteViewFix[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 160)
                        self.listRemoteViewFix[i].backgroundColor = .clear
                        self.listRemoteViewFix[i].makeRoundedView(radius: 8.0)
                        self.scrollRemoteView.addSubview(self.containerLabelName[i])
                        self.containerLabelName[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 30)
                        self.containerLabelName[i].backgroundColor = .orangeBNI.withAlphaComponent(0.5)
                        self.containerLabelName[i].makeRoundedView(radius: 8.0)
                        if i == 0 {
                            if self.dataPerson[0]["user_type"] == "2" {
                                self.listRemoteViewFix[0].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi)/2)
                            } else {
                                self.listRemoteViewFix[0].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (-CGFloat.pi)/2)
                            }
                        } else {
                            if arrayMessage[5] == "2" {
                                self.listRemoteViewFix[1].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi)/2)
                            } else {
                                self.listRemoteViewFix[1].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (-CGFloat.pi)/2)
                            }
                        }
                        let pictureImage = self.dataPerson[i]["picture"] ?? ""
                        let namePerson = self.dataPerson[i]["name"] ?? ""
                        if (!pictureImage!.isEmpty) {
                            self.listRemoteViewFix[i].setImage(name: pictureImage!)
                            self.listRemoteViewFix[i].contentMode = .scaleAspectFill
                        } else {
                            self.listRemoteViewFix[i].image = UIImage(systemName: "person")
                            self.listRemoteViewFix[i].backgroundColor = UIColor.systemGray6
                            self.listRemoteViewFix[i].contentMode = .scaleAspectFit
                        }
                        let labelName = UILabel()
                        self.containerLabelName[i].addSubview(labelName)
                        labelName.anchor(left: self.containerLabelName[i].leftAnchor, right: self.containerLabelName[i].rightAnchor, paddingLeft: 5, paddingRight: 5, centerX: self.containerLabelName[i].centerXAnchor, centerY: self.containerLabelName[i].centerYAnchor)
                        labelName.text = namePerson
                        labelName.textAlignment = .center
                        labelName.textColor = .white
                    }
                    self.scrollRemoteView.contentSize.height = CGFloat(170 * 2)
                    if self.buttonWB.isEnabled {
                        self.buttonWB.isEnabled = false
                    }
                    if self.buttonRotate.isEnabled {
                        self.buttonRotate.isEnabled = false
                        if self.wbVC != nil && self.wbVC!.view.isDescendant(of: self.view){
                            self.wbVC!.view.removeFromSuperview()
                            self.buttonDecline.isHidden = false
                            self.buttonSpeaker.isHidden = false
                            self.buttonRotate.isHidden = false
                            self.buttonMuted.isHidden = false
                        }
                    }
                } else if self.dataPerson.count > 1 {
                    if self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[1]}) == nil {
                        self.getDataProfile(fPin: String(arrayMessage[1]))
                        let i = self.dataPerson.count - 1
                        self.scrollRemoteView.addSubview(self.listRemoteViewFix[i])
                        self.listRemoteViewFix[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 160)
                        self.listRemoteViewFix[i].backgroundColor = .clear
                        self.listRemoteViewFix[i].makeRoundedView(radius: 8.0)
                        self.scrollRemoteView.addSubview(self.containerLabelName[i])
                        self.containerLabelName[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 30)
                        self.containerLabelName[i].backgroundColor = .orangeBNI.withAlphaComponent(0.5)
                        self.containerLabelName[i].makeRoundedView(radius: 8.0)
                        if arrayMessage[5] == "2" {
                            self.listRemoteViewFix[i].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi)/2)
                        } else {
                            self.listRemoteViewFix[i].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (-CGFloat.pi)/2)
                        }
                        let pictureImage = self.dataPerson[self.dataPerson.count - 1]["picture"] ?? ""
                        let namePerson = self.dataPerson[self.dataPerson.count - 1]["name"] ?? ""
                        if (!pictureImage!.isEmpty) {
                            self.listRemoteViewFix[i].setImage(name: pictureImage!)
                            self.listRemoteViewFix[i].contentMode = .scaleAspectFill
                        } else {
                            self.listRemoteViewFix[i].image = UIImage(systemName: "person")
                            self.listRemoteViewFix[i].backgroundColor = UIColor.systemGray6
                            self.listRemoteViewFix[i].contentMode = .scaleAspectFit
                        }
                        self.scrollRemoteView.contentSize.height = CGFloat(170 * (i + 1))
                        let labelName = UILabel()
                        self.containerLabelName[i].addSubview(labelName)
                        labelName.anchor(left: self.containerLabelName[i].leftAnchor, right: self.containerLabelName[i].rightAnchor, paddingLeft: 5, paddingRight: 5, centerX: self.containerLabelName[i].centerXAnchor, centerY: self.containerLabelName[i].centerYAnchor)
                        labelName.text = namePerson
                        labelName.textAlignment = .center
                        labelName.textColor = .white
                    }
                }
                
                if let user = User.getData(pin: String(arrayMessage[1])) {
                    if !self.users.contains(user) {
                        user.isConnected = true
                        self.users.append(user)
                    } else if let userEx = self.users.firstIndex(where: { $0.pin == String(arrayMessage[1]) }) {
                        self.users[userEx].isConnected = true
                    }
                }
                if arrayMessage[5] == "2" && self.dataPerson.count == 1 {
                    DispatchQueue.main.async {
                        self.zoomView.transform   = CGAffineTransform.init(scaleX: -1.9, y: 2.0).rotated(by: (CGFloat.pi)/2)
                        self.zoomView.contentMode = .scaleAspectFit
                    }
                }
                else if self.dataPerson.count == 1 {
                    DispatchQueue.main.async {
                        self.zoomView.transform   = CGAffineTransform.init(scaleX: 1.9, y: 2.0).rotated(by: (-CGFloat.pi)/2)
                        self.zoomView.contentMode = .scaleAspectFit
                    }
                } else if self.dataPerson.count > 1 {
                    DispatchQueue.main.async {
                        for i in 0..<self.dataPerson.count {
                            self.listRemoteViewFix[i].image = nil
                            if self.dataPerson[i]["user_type"] == "2" || arrayMessage[5] == "2" {
                                self.listRemoteViewFix[i].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (CGFloat.pi)/2)
                            } else {
                                self.listRemoteViewFix[i].transform = CGAffineTransform.init(scaleX: 1.4, y: 1.3).rotated(by: (-CGFloat.pi)/2)
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                if self.contentStack.isDescendant(of: self.view) || self.joiningStack.isDescendant(of: self.view) {
                    self.didTapAcceptCallButton()
                    if VideoConferenceViewController.bSpeakerPhone {
                        DispatchQueue.main.async {
                            VideoConferenceViewController.bSpeakerPhone = false
                            self.setSpeaker()
                        }
                    }
                }
                let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[1]})
                if indexPerson != nil {
                    self.dataPerson[indexPerson!]["user_type"] = String(arrayMessage[5])
                }
            }
        }
        else if (state == Nexilis.VIDEO_CALL_END || state == Nexilis.AUDIO_CALL_END) {
            DispatchQueue.main.async {
                let pin = "\(arrayMessage[0])"
                if (self.dataPerson.count == 1 || (!self.fPin.isEmpty && pin == self.fPin)) {
                    if self.stackViewToolbar.isDescendant(of: self.view){
                        self.stackViewToolbar.removeFromSuperview()
                    }
                    if self.stackViewToolbar2.isDescendant(of: self.view){
                        self.stackViewToolbar2.removeFromSuperview()
                    }
                    if self.buttonWB.isDescendant(of: self.view){
                        self.buttonWB.removeFromSuperview()
                    }
                    if self.buttonChat.isDescendant(of: self.view){
                        self.buttonChat.removeFromSuperview()
                    }
                    if self.buttonDecline.isDescendant(of: self.view) {
                        self.buttonDecline.removeFromSuperview()
                    }
                    if self.buttonAccept.isDescendant(of: self.view) {
                        self.buttonAccept.removeFromSuperview()
                    }
                    if self.buttonRotate.isDescendant(of: self.view) {
                        self.buttonRotate.removeFromSuperview()
                    }
                    if self.buttonMuted.isDescendant(of: self.view) {
                        self.buttonMuted.removeFromSuperview()
                    }
                    if self.wbVC != nil{
                        self.wbVC!.close?()
                    }
                    self.wbTimer.invalidate()
                    self.vcTimer.invalidate()
                    _ = Nexilis.getWhiteboardDelegate()?.terminate()
                    let controller = self.presentedViewController
                    if controller != nil {
                        controller!.dismiss(animated: true)
                    }
                    VideoConferenceViewController.isLoop = false
                    VideoConferenceViewController.bSpeakerPhone = false
                    do { try AVAudioSession.sharedInstance().setActive(false) } catch {}
                    Nexilis.callAPNActivated = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.endAllCall()
                        if self.isInisiator && !self.isPresent {
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                } else {
                    let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[0]})
                    if indexPerson != nil {
                        if (self.dataPerson.count == 2) {
                            self.containerLabelName.forEach({ $0.subviews.forEach({ $0.removeFromSuperview() }) })
                            self.scrollRemoteView.subviews.forEach({ $0.removeFromSuperview() })
                        } else {
                            self.containerLabelName[indexPerson! + indexPerson!].subviews.forEach({ $0.removeFromSuperview() })
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            self.containerLabelName[indexPerson! + indexPerson!].subviews.forEach({ $0.removeFromSuperview() })
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            if indexPerson! + 1 <= self.listRemoteViewFix.count {
                                let iLoop = (self.listRemoteViewFix.count - 1) - (indexPerson! + 1)
                                if iLoop >= 0 {
                                    for i in 0...iLoop {
                                        let viewAfterRemote = self.listRemoteViewFix[(indexPerson! + i) + 1]
                                        let viewAfterName = self.containerLabelName[(indexPerson! + i) + 1]
                                        viewAfterRemote.frame.origin.y = viewAfterRemote.frame.origin.y - 170
                                        viewAfterName.frame.origin.y = viewAfterName.frame.origin.y - 170
                                        UIView.animate(withDuration: 0.35, animations: {
                                            self.scrollRemoteView.layoutIfNeeded()
                                        })
                                    }
                                }
                            }
                        }
                        self.dataPerson.remove(at: indexPerson!)
                    }
                    if let index = self.users.firstIndex(where: { $0.pin == pin }) {
                        self.users.remove(at: index)
                    }
                }
            }
        }
        else if state == Nexilis.OFFLINE {
            DispatchQueue.main.async {
                self.joiningTimer?.invalidate()
                self.activityIndicator.isHidden = true
                self.animatedLabel.text = "The room has not been started by the initiator".localized()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.endAllCall()
                    if self.isInisiator && !self.isPresent {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
}

extension VideoConferenceViewController : WhiteboardReceiver {
    
    func incomingWB(roomId: String) {
        //print("incoming wb")
        self.wbTimer.invalidate()
        if(wbRoomId.isEmpty){
            //print("wbroom empty")
            DispatchQueue.main.async {
                self.wbTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.runTimer), userInfo: nil, repeats: true)
            }
            let me = User.getMyPin()!
            var destString = ""
            for d in dataPerson{
                if d["f_pin"]!! == roomId.components(separatedBy: "wbvc")[0] {
                    continue
                }
                if destString.isEmpty{
                    destString = d["f_pin"]!!
                } else {
                    destString = destString + ",\(d["f_pin"]!!)"
                }
            }
            if destString.isEmpty {
                SecureUserDefaults.shared.set("\(roomId.components(separatedBy: "wbvc")[0]),\(me)", forKey: "wb_vc")
            } else {
                SecureUserDefaults.shared.set("\(roomId.components(separatedBy: "wbvc")[0]),\(me),\(destString)", forKey: "wb_vc")
            }
            wbRoomId = roomId
        }
    }
    
    func cancel(roomId: String) {
        DispatchQueue.main.async {
            self.wbTimer.invalidate()
            self.wbBlink = false
            self.buttonWB.backgroundColor = .lightGray
            self.buttonWB.setNeedsDisplay()
        }
        wbRoomId = ""
    }
    
    @objc func runTimer(){
        DispatchQueue.main.async {
            self.wbBlink = !self.wbBlink
            if(self.wbBlink){
                //print("set wb blink on")
                self.buttonWB.backgroundColor = .green
            }
            else {
                //print("set wb blink off")
                self.buttonWB.backgroundColor = .lightGray
            }
            self.buttonWB.setNeedsDisplay()
        }
    }
    
}
