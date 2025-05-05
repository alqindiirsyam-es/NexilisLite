//
//  OutgoingViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 07/10/21.
//

import UIKit
import AVFoundation
import nuSDKService
import NotificationBannerSwift
import MediaPlayer

class QmeraAudioViewController: UIViewController {
    
    static private var nMaxSPOn: Float! = 20.0
    static private var nMaxSPOff: Float! = 20.0
    static private var volumeView: MPVolumeView!
    static private var lastVolume: Float! = AVAudioSession.sharedInstance().outputVolume
    static private var bSpeakerPhone: Bool! = false
    private var tempSpeaker = false
    private var timerSpeaker: Timer?
    private var canChangeSpeaker = false
    static private var isLoop = false
    
    
    let stackViewToolbar2 = UIStackView()
    var onScreenConstraintWB = [NSLayoutConstraint]()
    let buttonWB = UIButton()
    let buttonChat = UIButton()
    var wbVC : WhiteboardViewController?
    var wbTimer = Timer()
    var wbBlink = false
    var wbRoomId = ""
    var callFCM = true
    var autoAcceptAPN = false
    var timeStartCall = ""
    var idCall = ""
    
    
    let buttonSize: CGFloat = 70
    
    lazy var data: String = "" {
        didSet {
            getUserData { user in
                self.user = user
            }
        }
    }
    
    var user: User?
    
    var isAddCall = ""
        
    private var users: [User] = [] {
        didSet {
            DispatchQueue.main.async {
                if oldValue.count > self.users.count { // remove
                    let remove = oldValue.filter { !self.users.contains($0) }
                    remove.forEach { user in
                        if let subviews = self.profiles.subviews as? [ProfileView] {
                            subviews.forEach { p in
                                if p.user == user {
                                    self.profiles.removeArrangeSubview(view: p)
                                }
                            }
                        }
                    }
                } else {
                    if let user = self.users.last {
                        let profile = ProfileView(image: UIImage(systemName: "person.circle.fill"))
                        profile.user = user
                        self.profiles.addArrangedSubview(view: profile)
                    }
                }
                self.name.text = self.users.map { $0.fullName }.joined(separator: ", ")
            }
        }
    }
    
    var isOutgoing: Bool = true
    
    var isOnGoing: Bool = false
    
    var ticketId: String = ""
    
    private var timer: Timer?
    
    private var firstCall: Bool = true
    
//    private var isSpeaker: Bool = false
    
    private var isMuted: Bool = false
    
    var listRemoteViewFix: [UIImageView] = [
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView(),
        UIImageView()
    ]
    
    let zoomView = UIImageView()
    let cameraView = UIImageView()
    
    let status: UILabel = {
        let label = UILabel()
        label.text = "Calling..."
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let profiles: GroupView = {
        let groupView = GroupView()
        groupView.spacing = 50
        groupView.maxUser = 3
        return groupView
    }()
    
    let name: UILabel = {
        let label = UILabel()
        label.text = "uwitan"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let end: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "phone.down"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageView?.tintColor = .white
        button.setBackgroundColor(.red, for: .normal)
        button.setBackgroundColor(.white, for: .highlighted)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        return button
    }()
    
    let reject: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "xmark")
        button.setImage(image, for: .normal)
        let selectedImage = image?.withTintColor(.mainColor)
        button.setImage(selectedImage, for: .selected)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageView?.tintColor = .white
        button.setBackgroundColor(.red, for: .normal)
        button.setBackgroundColor(.white, for: .highlighted)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        return button
    }()
    
    let accept: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "checkmark")
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageView?.tintColor = .white
        button.setBackgroundColor(.greenColor, for: .normal)
        button.setBackgroundColor(.white, for: .highlighted)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        return button
    }()
    
    let invite: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "person.badge.plus")
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageView?.tintColor = .mainColor
        button.setBackgroundColor(.white, for: .normal)
        button.setBackgroundColor(.mainColor, for: .highlighted)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        return button
    }()
    
    let speaker: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "speaker.slash")?.withTintColor(.mainColor, renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(UIImage(systemName: "speaker.wave.3")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .selected)
        button.imageView?.contentMode = .scaleAspectFit
        button.setBackgroundColor(.white, for: .normal)
        button.setBackgroundColor(.mainColor, for: .highlighted)
        button.setBackgroundColor(.mainColor, for: .selected)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        return button
    }()
    
    let mic: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "mic")?.withTintColor(.mainColor, renderingMode: .alwaysOriginal), for: .normal)
        button.setImage(UIImage(systemName: "mic.slash")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .selected)
        button.imageView?.contentMode = .scaleAspectFit
        button.setBackgroundColor(.white, for: .normal)
        button.setBackgroundColor(.mainColor, for: .highlighted)
        button.setBackgroundColor(.mainColor, for: .selected)
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        return button
    }()
    
    let stack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    let stack2: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    let poweredByView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 5
        return stackView
    }()
    
    let poweredByLabel: UILabel = {
        let label = UILabel()
        label.text = "Powered by Nexilis".localized()
        return label
    }()
    
    let qmeraLogo: UIButton = {
        let image = UIImage(named: "Q-Button-PNG", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
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
    
    static func turnSpeakerOn() {
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
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.overrideOutputAudioPort(bSpeakerPhone ? .speaker : .none)
        } catch {
            
        }
        if (bSpeakerPhone) {
            DispatchQueue.main.async {
                UIDevice.current.isProximityMonitoringEnabled = false
            }
//            volume = lastVolume * nMaxSPOn
        } else {
            DispatchQueue.main.async {
                UIDevice.current.isProximityMonitoringEnabled = true
            }
//            volume = lastVolume * nMaxSPOff
        }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.isProximityMonitoringEnabled = false
        Nexilis.floatingButton.isHidden = false
    }
    
    deinit {
        UIDevice.current.isProximityMonitoringEnabled = false
        Nexilis.floatingButton.isHidden = false
        NotificationCenter.default.removeObserver(self)
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
    }
    
    private func backToDefaultAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .mixWithOthers])
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setPreferredSampleRate(44100)
            try audioSession.setActive(true)
        } catch {
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onShowAC"), object: nil, userInfo: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        QmeraAudioViewController.volumeView = MPVolumeView(frame: .zero)
        QmeraAudioViewController.volumeView.isHidden = true

        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
        
        Nexilis.floatingButton.isHidden = true
        
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        effectView.frame = view.frame
        view.insertSubview(effectView, at: 0)
        
        view.addSubview(status)
        view.addSubview(profiles)
        view.addSubview(name)
        
        status.anchor(left: view.leftAnchor, bottom: profiles.topAnchor, right: view.rightAnchor, paddingBottom: 30, centerX: view.centerXAnchor)
        profiles.anchor(centerX: view.centerXAnchor, centerY: view.centerYAnchor, width: 150, height: 150)
        name.anchor(top: profiles.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 5, paddingLeft: 20, paddingRight: 20, centerX: view.centerXAnchor)
        definesPresentationContext = true
        
        if isOutgoing {
            outgoingView()
        } else if isOnGoing || autoAcceptAPN {
            ongoingView()
        } else {
            incomingView()
        }
        
        UIDevice.current.isProximityMonitoringEnabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(onStatusCall(_:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusCall), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallFCM(notification:)), name: NSNotification.Name(rawValue: Nexilis.callFCM), object: nil)
        
        if let u = self.user {
            self.users.append(u)
            if isOutgoing && ticketId.isEmpty {
//                if onGoingCC.isEmpty {
//                    Nexilis.shared.callManager.startCall(handle: u.pin)
//                } else {
//                    API.initiateCCall(sParty: u.pin)
//                }
                if callFCM {
                    DispatchQueue.global().async {
                        if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getCalling(fPin: u.pin, type: "1"), timeout: 30 * 1000) {
                            if response.isOk() {
                                DispatchQueue.main.async {
                                    self.status.text = "Waiting for answer".localized()
                                }
                            } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "01" {
                                API.initiateCCall(sParty: u.pin)
                            } else {
                                DispatchQueue.main.async {
                                    Nexilis.stopRingbacktoneCall()
                                }
                                DispatchQueue.main.async {
                                    let longCall =  "0"
                                    Nexilis.saveMessageCall(idCall: self.idCall, textMessage: "Outgoing audio call".localized() + " at \(longCall)", fPin: User.getMyPin() ?? "", lPin: !self.data.isEmpty ? self.data : self.user != nil ? self.user!.pin : "", timeCall: self.timeStartCall, attachment_type: MessageScope.CALL)
                                    self.status.text = "Busy..."
                                    self.end.isEnabled = false
                                    if self.isOutgoing {
                                        Nexilis.playBusyCall()
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        Nexilis.stopBusyCall()
                                        self.didEnd(sender: false)
                                    }
                                }
                            }
                        } else {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                    }
                } else {
                    API.initiateCCall(sParty: u.pin)
                }
            } else if !ticketId.isEmpty {
                if isOutgoing {
                    self.backToDefaultAudioSession()
                    API.ccs(sTicketID: ticketId, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView, ivRemoteZ: zoomView, bCameraOn: false)
                    if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getIncomingCallCS(f_pin_opposite: u.pin), timeout: 30 * 1000){
                        if response.mBodies[CoreMessage_TMessageKey.ERRCOD] != "01" {
                            self.didEnd(sender: true)
                        }
                    }
                } else {
                    self.backToDefaultAudioSession()
                    API.csa(sTicketID: ticketId, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView, ivRemoteZ: zoomView, bCameraOn: false)
                }
            } else if autoAcceptAPN {
                DispatchQueue.global().async {
                    do {
                        if API.nGetCLXConnState() == 0 {
                            let id = Utils.getConnectionID()
                            try API.initConnection(sAPIK: Nexilis.sAPIKey, cbiI: Callback(), sTCPAddr: Nexilis.ADDRESS, nTCPPort: Nexilis.PORT, sUserID: id, sStartWH: "09:00")
                        }
                    } catch {
                        
                    }
                    self.backToDefaultAudioSession()
                    while API.nGetCLXConnState() == 0 {
                        Thread.sleep(forTimeInterval : 0.3)
                    }
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.getNotifyCalling(fPin: u.pin, lPin: User.getMyPin()!, type: "1"))
                }
            }
        }
        self.timeStartCall = String(Date().currentTimeMillis())
        self.idCall = (User.getMyPin() ?? "") + CoreMessage_TMessageUtil.getTID()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if (keyPath! == "outputVolume") {
                if let newKey = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                    QmeraAudioViewController.lastVolume = newKey.floatValue
                    if (QmeraAudioViewController.bSpeakerPhone) {
                        let volume = QmeraAudioViewController.lastVolume * QmeraAudioViewController.nMaxSPOn
                        API.adjustVolume(fValue: volume)
                    } else {
                        let volume = QmeraAudioViewController.lastVolume * QmeraAudioViewController.nMaxSPOff
                        API.adjustVolume(fValue: volume)
                    }
                }
            }
        }
    
    @objc func onCallFCM(notification: NSNotification) {
        DispatchQueue.main.async {
            let data:[AnyHashable : Any] = notification.userInfo!
            if let l_pin = data["l_pin"] as? String {
                if let f_pin = data["f_pin"] as? String {
                    if f_pin == User.getMyPin()!  {
                        API.initiateCCall(sParty: l_pin)
                    }
                }
            } else if data["call_cancel"] != nil {
                DispatchQueue.main.async {
                    Nexilis.stopRingbacktoneCall()
                }
                DispatchQueue.main.async {
                    let longCall =  "0"
                    Nexilis.saveMessageCall(idCall: self.idCall, textMessage: "Outgoing audio call".localized() + " at \(longCall)", fPin: User.getMyPin() ?? "", lPin: !self.data.isEmpty ? self.data : self.user != nil ? self.user!.pin : "", timeCall: self.timeStartCall, attachment_type: MessageScope.CALL)
                    self.status.text = "Busy..."
                    self.end.isEnabled = false
                    if self.isOutgoing {
                        Nexilis.playBusyCall()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        Nexilis.stopBusyCall()
                        self.didEnd(sender: false)
                    }
                }
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        end.circle()
        reject.circle()
        accept.circle()
        invite.circle()
        speaker.circle()
        mic.circle()
    }
    
    private func getUserData(completion: @escaping (User?) -> ()) {
        if let user = self.user {
            completion(user)
            return
        }
        var user: User?
        DispatchQueue.global().async {
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, first_name, last_name, image_id from BUDDY where f_pin = '\(self.data)'"), cursor.next() {
                        user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
                                    firstName: cursor.string(forColumnIndex: 1) ?? "",
                                    lastName: cursor.string(forColumnIndex: 2) ?? "",
                                    thumb: cursor.string(forColumnIndex: 3) ?? "")
                        cursor.close()
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
        completion(user)
    }
    
    private func resetViewToOutgoing() {
        self.timer?.invalidate()
        self.timer = nil
        self.firstCall = true
        status.removeFromSuperview()
        profiles.removeFromSuperview()
        name.removeFromSuperview()
        stack.removeFromSuperview()
        stack2.removeFromSuperview()
        stackViewToolbar2.removeFromSuperview()
        buttonWB.removeFromSuperview()
        buttonChat.removeFromSuperview()
        poweredByView.removeFromSuperview()
        
        view.addSubview(status)
        view.addSubview(profiles)
        view.addSubview(name)
        
        status.anchor(left: view.leftAnchor, bottom: profiles.topAnchor, right: view.rightAnchor, paddingBottom: 30, centerX: view.centerXAnchor)
        profiles.anchor(centerX: view.centerXAnchor, centerY: view.centerYAnchor, width: 150, height: 150)
        name.anchor(top: profiles.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 5, paddingLeft: 20, paddingRight: 20, centerX: view.centerXAnchor)
        status.text = "Connecting..."
        view.addSubview(end)
        end.anchor(bottom: view.bottomAnchor, paddingBottom: 60, centerX: view.centerXAnchor, width: buttonSize, height: buttonSize)
        
        end.addTarget(self, action: #selector(didPressEnd(sender:)), for: .touchUpInside)
    }
    
    private func outgoingView() {
//        Nexilis.setSpeakerphoneOn(isSpeaker)
        if ticketId.isEmpty {
            backToDefaultAudioSession()
            Nexilis.playRingbacktoneCall()
        }
        status.text = "Connecting..."
        view.addSubview(end)
        end.anchor(bottom: view.bottomAnchor, paddingBottom: 60, centerX: view.centerXAnchor, width: buttonSize, height: buttonSize)
        
        end.addTarget(self, action: #selector(didPressEnd(sender:)), for: .touchUpInside)
    }
    
    private func incomingView() {
        if ticketId.isEmpty {
            backToDefaultAudioSession()
            Nexilis.playRingtoneCall()
        }
        status.text = "Incoming..."
        
        stack.spacing = buttonSize
        
        view.addSubview(stack)
        
        stack.anchor(bottom: view.bottomAnchor, paddingBottom: 60, centerX: view.centerXAnchor, width: buttonSize * 3, height: buttonSize)
        
        stack.addArrangedSubview(reject)
        stack.addArrangedSubview(accept)
        
        reject.addTarget(self, action: #selector(didReject(sender:)), for: .touchUpInside)
        accept.addTarget(self, action: #selector(didAccept(sender:)), for: .touchUpInside)
    }
    
    private func ongoingView() {
        status.text = "Connecting..."
        
        stack.spacing = buttonSize / 2
        stack2.spacing = buttonSize / 2
        
        view.addSubview(stack)
        view.addSubview(stack2)
        
        stack.anchor(bottom: view.bottomAnchor, paddingBottom: 60, centerX: view.centerXAnchor, width: buttonSize * 4, height: buttonSize)
        stack2.anchor(bottom: stack.topAnchor, paddingBottom: 10, centerX: view.centerXAnchor, width: buttonSize, height: buttonSize)
        
        stack.addArrangedSubview(invite)
        stack.addArrangedSubview(end)
        stack.addArrangedSubview(speaker)
        stack2.addArrangedSubview(mic)
        
        invite.addTarget(self, action: #selector(didInvite(sender:)), for: .touchUpInside)
        end.addTarget(self, action: #selector(didPressEnd(sender:)), for: .touchUpInside)
        speaker.addTarget(self, action: #selector(didSpeaker(sender:)), for: .touchUpInside)
        mic.addTarget(self, action: #selector(didMute(sender:)), for: .touchUpInside)
        
        if !ticketId.isEmpty {
            self.view.addSubview(self.stackViewToolbar2)
            self.stackViewToolbar2.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.stackViewToolbar2.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                self.stackViewToolbar2.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 10.0)
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
            buttonWB.addTarget(self, action: #selector(didTapWBButton), for: .touchUpInside)
            
            view.addSubview(buttonChat)
            buttonChat.translatesAutoresizingMaskIntoConstraints = false
            buttonChat.frame.size = CGSize(width: 40.0, height: 40.0)
            NSLayoutConstraint.activate([
                buttonChat.widthAnchor.constraint(equalToConstant: 40.0),
                buttonChat.heightAnchor.constraint(equalToConstant: 40.0)
            ])
            buttonChat.backgroundColor = .lightGray
            buttonChat.setImage(UIImage(systemName: "bubble.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .default)), for: .normal)
            buttonChat.circle()
            buttonChat.tintColor = .black
            buttonChat.addTarget(self, action: #selector(didTapChatButton), for: .touchUpInside)
        }
        
        self.view.addSubview(poweredByView)
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
        stackViewToolbar2.addArrangedSubview(buttonWB)
        stackViewToolbar2.addArrangedSubview(buttonChat)
    }
    
    
    
    
    // MARK: - Action
    
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
        editorPersonalVC.channelContactCenter = "1"
        editorPersonalVC.users = users
        editorPersonalVC.fromVCAC = true
        let navigationController = CustomNavigationController(rootViewController: editorPersonalVC)
        navigationController.modalPresentationStyle = .overCurrentContext
        navigationController.navigationBar.tintColor = .white
        navigationController.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
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
                for d in users{
                    destinations.append(d.pin)
                    if destString.isEmpty{
                        destString = d.pin
                    } else {
                        destString = destString + ",\(d.pin)"
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
//                self.buttonDecline.isHidden = false
//                self.buttonSpeaker.isHidden = false
//                self.buttonAddParticipant.isHidden = false
//                self.buttonRotate.isHidden = false
//                if(!self.wbRoomId.isEmpty){
//                    DispatchQueue.main.async {
//                        self.wbTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.runTimer), userInfo: nil, repeats: true)
//                    }
//                }
            }
        }
//        self.buttonDecline.isHidden = true
//        self.buttonSpeaker.isHidden = true
//        self.buttonAddParticipant.isHidden = true
//        self.buttonRotate.isHidden = true
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
    
    @objc func didSpeaker(sender: Any?) {
        timerSpeaker?.invalidate()
        tempSpeaker = !tempSpeaker
        speaker.isSelected = tempSpeaker
        timerSpeaker = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {_ in
            if QmeraAudioViewController.bSpeakerPhone != self.tempSpeaker {
                QmeraAudioViewController.bSpeakerPhone = !QmeraAudioViewController.bSpeakerPhone
                self.tempSpeaker = QmeraAudioViewController.bSpeakerPhone
                DispatchQueue.global().async {
                    QmeraAudioViewController.turnSpeakerOn()
                }
            }
        })
    }
    
    @objc func didMute(sender: Any?) {
        isMuted = !isMuted
        mic.isSelected = isMuted
        API.mmc(int: 1, boolean: isMuted)
    }
    
    @objc func didInvite(sender: Any?) {
        let controller = QmeraCallContactViewController()
        controller.isDismiss = { user in
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            if !onGoingCC.isEmpty {
                DispatchQueue.global().async {
                    _ = Nexilis.write(message: CoreMessage_TMessageBank.getCCRoomInvite(l_pin: user.pin, ticket_id: onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[2], channel: "1"))
                }
                DispatchQueue.main.async {
                    self.isAddCall = user.pin
                }
            } else {
                self.users.append(user)
                if self.callFCM {
                    DispatchQueue.global().async {
                        if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getCalling(fPin: user.pin, type: "1"), timeout: 30 * 1000) {
                            if response.isOk() {
                            } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "01" {
                                API.initiateCCall(sParty: user.pin)
                                Nexilis.playRingbacktoneCall()
                            } else {
                                Nexilis.stopRingbacktoneCall()
                            }
                        } else {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                    }
                } else {
                    API.initiateCCall(sParty: user.pin)
                    Nexilis.playRingbacktoneCall()
                }
               
            }
        }
        controller.selectedUser.append(contentsOf: users)
        present(CustomNavigationController(rootViewController: controller), animated: true, completion: nil)
    }
    
    @objc func didPressEnd(sender: Any?) {
        if let sharedAudioPlayer = Nexilis.sharedAudioPlayer, sharedAudioPlayer.isPlaying {
            Nexilis.stopRingtoneCall()
            Nexilis.stopRingbacktoneCall()
        }
        let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
        if !onGoingCC.isEmpty {
            self.didEnd(sender: nil)
            return
        }
        let alert = LibAlertController(title: "End Audio Call".localized(), message: "Are you sure you want to end audio call?".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
            DispatchQueue.main.async {
                if self.timer == nil || self.isOutgoing {
                    let longCall = self.timer == nil ? "0" : self.status.text ?? ""
                    Nexilis.saveMessageCall(idCall: self.idCall, textMessage: "Outgoing audio call".localized() + " at \(longCall)", fPin: User.getMyPin() ?? "", lPin: !self.data.isEmpty ? self.data : self.user != nil ? self.user!.pin : "", timeCall: self.timeStartCall, attachment_type: MessageScope.CALL)
                } else if !self.isOutgoing {
                    Nexilis.saveMessageCall(idCall: self.idCall, textMessage: "Incoming audio call".localized() + " at \(self.status.text ?? "")", fPin: !self.data.isEmpty ? self.data : self.user != nil ? self.user!.pin : "", lPin: User.getMyPin() ?? "", timeCall: self.timeStartCall, attachment_type: MessageScope.CALL)
                }
                if self.callFCM && self.timer == nil {
                    DispatchQueue.global().async {
                        if let _ = Nexilis.writeSync(message: CoreMessage_TMessageBank.getCancelCall(fPin: self.user!.pin, type: "1"), timeout: 30 * 1000) {
                        } else {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                        }
                    }
                }
                self.timer?.invalidate()
                self.timer = nil
                self.status.text = "Audio Call Ended".localized()
                self.end.isEnabled = false
                self.invite.isEnabled = false
                self.speaker.isEnabled = false
                self.mic.isEnabled = false
            }
            self.didEnd(sender: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func didEnd(sender: Any?) {
        if let sharedAudioPlayer = Nexilis.sharedAudioPlayer, sharedAudioPlayer.isPlaying {
            Nexilis.stopRingtoneCall()
            Nexilis.stopRingbacktoneCall()
        }
        if APIS.uuidCall != nil {
            CallManager.shared.endCall(uuid: APIS.uuidCall!) {
                APIS.uuidCall = nil
            }
        }
        poweredByView.isHidden = true
        let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
        if !onGoingCC.isEmpty {
            if sender != nil && sender is Bool {
                let controller = self.presentedViewController
                if controller != nil {
                    controller!.dismiss(animated: true)
                }
                self.dismiss(animated: false, completion: nil)
                let requester = onGoingCC.components(separatedBy: ",")[0]
                let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                let complaintId = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[2]
                let startTimeCC: String = SecureUserDefaults.shared.value(forKey: "startTimeCC") ?? ""
                DispatchQueue.global().async {
                    if sender as! Bool == true {
                        let date = "\(Date().currentTimeMillis())"
                        Database.shared.database?.inTransaction({ (fmdb, rollback) in
                            do {
                                _ = try Database.shared.insertRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", cvalues: [
                                    "type" : "1",
                                    "title" : "Contact Center".localized(),
                                    "time" : startTimeCC,
                                    "f_pin" : officer,
                                    "data" : complaintId,
                                    "time_end" : date,
                                    "complaint_id" : complaintId,
                                    "members" : "",
                                    "requester": requester
                                ], replace: true)
                            } catch {
                                rollback.pointee = true
                                print("Access database error: \(error.localizedDescription)")
                            }
                        })
                    }
                    SecureUserDefaults.shared.removeValue(forKey: "onGoingCC")
                    SecureUserDefaults.shared.removeValue(forKey: "membersCC")
                    SecureUserDefaults.shared.removeValue(forKey: "startTimeCC")
                    SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
                }
                return
            }
            let alert = LibAlertController(title: "Interaction with Call Center is in progress".localized(), message: "Are you sure you want to end the Call Center?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                self.dismiss(animated: false, completion: nil)
                let requester = onGoingCC.components(separatedBy: ",")[0]
                let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                let complaintId = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[2]
                let idMe = User.getMyPin()!
                let startTimeCC: String = SecureUserDefaults.shared.value(forKey: "startTimeCC") ?? ""
                DispatchQueue.global().async {
                    let date = "\(Date().currentTimeMillis())"
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            _ = try Database.shared.insertRecord(fmdb: fmdb, table: "CALL_CENTER_HISTORY", cvalues: [
                                "type" : "1",
                                "title" : "Contact Center".localized(),
                                "time" : startTimeCC,
                                "f_pin" : officer,
                                "data" : complaintId,
                                "time_end" : date,
                                "complaint_id" : complaintId,
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
                    SecureUserDefaults.shared.removeValue(forKey: "startTimeCC")
                    SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
                }
                API.terminateCall(sParty: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            let controller = self.presentedViewController
            if controller != nil {
                controller!.dismiss(animated: true)
            }
            API.terminateCall(sParty: nil)
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @objc func didReject(sender: Any?) {
        if self.timer == nil {
            Nexilis.saveMessageCall(idCall: self.idCall, textMessage: "Missed audio call".localized() + " at 0", fPin: !self.data.isEmpty ? self.data : self.user != nil ? self.user!.pin : "", lPin: User.getMyPin() ?? "", timeCall: self.timeStartCall, attachment_type: MessageScope.MISSED_CALL)
        }
        didEnd(sender: sender)
    }
    
    @objc func didAccept(sender: Any?) {
        Nexilis.stopRingtoneCall()
        NSLayoutConstraint.deactivate(stack.constraints)
        stack.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        ongoingView()
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
        API.receiveCCall(sParty: user?.pin)
    }
    
    // MARK: - Communication
    
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
                            SecureUserDefaults.shared.set(members, forKey: "inEditorPersonal")
                            SecureUserDefaults.shared.set("\(members)", forKey: "membersCC")
                        }
                    }
                    self.users.append(User.getData(pin: dataMessage.getPIN())!)
                }
            }
        }
    }
    
    @objc func onStatusCall(_ notification: NSNotification) {
        if let data = notification.userInfo,
           let state = data["state"] as? Int,
           let message = data["message"] as? String
        {
            let arrayMessage = message.split(separator: ",")
            if state == Nexilis.AUDIO_CALL_INCOMING {
                if autoAcceptAPN {
                    API.receiveCCall(sParty: self.user?.pin)
                }
            }
            else if state == Nexilis.AUDIO_VIDEO_CALL_MUTED {
                DispatchQueue.main.async { [self] in
                    if let pin = arrayMessage.first, let index = users.firstIndex(of: User(pin: String(pin))) {
                        if arrayMessage[1] == "1" {
                            users[index].isMuted = true
                            if let profile = profiles.subviews[index] as? ProfileView {
                                profile.imageMuted.isHidden = false
                            }
                        } else {
                            users[index].isMuted = false
                            if let profile = profiles.subviews[index] as? ProfileView {
                                profile.imageMuted.isHidden = true
                            }
                        }
                    }
                }
            } else if state == Nexilis.STREAMING_SEMINAR_ENDED { // always call turnspeaker
//                QmeraAudioViewController.isLoop = true
//                DispatchQueue.global(qos: .userInitiated).async {
//                    repeat {
//                        Thread.sleep(forTimeInterval : 1)
//                        if (QmeraAudioViewController.isLoop && !API.bAudioEngineIsRunning()) {
//                            API.turnSpeakerPhone(bSPon: QmeraAudioViewController.bSpeakerPhone!)
//                        }
//                    } while (QmeraAudioViewController.isLoop)
//                }
//                DispatchQueue.main.async { [self] in
//                    QmeraAudioViewController.bSpeakerPhone = true
//                    self.tempSpeaker = true
//                    didSpeaker(sender: nil)
//                }
                if #available(iOS 15.0, *), Nexilis.firstCall {
                    DispatchQueue.main.async {
                        self.speaker.isEnabled = false
                    }
                    QmeraAudioViewController.isLoop = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        var countLoop = 0
                        repeat {
                            Thread.sleep(forTimeInterval : 0.5)
                            if (QmeraAudioViewController.isLoop && !API.bAudioEngineIsRunning()) {
                                API.restartAudioEngine()
                                Nexilis.firstCall = false
                                DispatchQueue.main.async {
                                    self.speaker.isEnabled = true
                                }
                                break
                            }
                            countLoop = countLoop + 1
                            if countLoop == 3 {
                                Nexilis.firstCall = false
                                DispatchQueue.main.async {
                                    self.speaker.isEnabled = true
                                }
                                break
                            }
                        } while (QmeraAudioViewController.isLoop)
                    }
                }
            } else if state == Nexilis.AUDIO_CALL_RINGING || (!ticketId.isEmpty && state == Nexilis.VIDEO_CALL_RINGING) {
                if users.count == 1 && !autoAcceptAPN {
                    DispatchQueue.main.async {
                        self.status.text = "Waiting for answer".localized()
                    }
                }
            } else if state == Nexilis.AUDIO_CALL_OFFHOOK || (!ticketId.isEmpty && state == Nexilis.VIDEO_CALL_OFFHOOK) {
                DispatchQueue.main.async {
                    Nexilis.stopRingbacktoneCall()
                }
                if users.count == 1 && firstCall {
                    DispatchQueue.main.async {
                        if !self.ticketId.isEmpty || (self.timer == nil && !self.stack.isDescendant(of: self.view)) {
                            NSLayoutConstraint.deactivate(self.stack.constraints)
                            self.stack.subviews.forEach { subview in
                                subview.removeFromSuperview()
                            }
                            UIView.animate(withDuration: 0.3, animations: {
                                self.view.layoutIfNeeded()
                            })
                        }
                        self.ongoingView()
                        let connectDate = Date()
                        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                            let format = Utils.callDurationFormatter.string(from: Date().timeIntervalSince(connectDate))
                            self.status.text = format
                        }
                        self.timer?.fire()
                        self.firstCall = false
                    }
                }
                if (!isOutgoing || !firstCall), users.count >= 1, let user = User.getData(pin: String(arrayMessage[1])), !users.contains(user) {
                    self.users.append(user)
                }
                users.forEach({ $0.isConnected = true })
            } else if state == Nexilis.AUDIO_CALL_END || (!ticketId.isEmpty && state == Nexilis.VIDEO_CALL_END) {
                DispatchQueue.main.async {
                    if let sharedAudioPlayer = Nexilis.sharedAudioPlayer, sharedAudioPlayer.isPlaying {
                        Nexilis.stopRingtoneCall()
                        Nexilis.stopRingbacktoneCall()
                    }
                }
                let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                if let pin = arrayMessage.first, let index = users.firstIndex(of: User(pin: String(pin))) {
                    users.remove(at: index)
                    if !onGoingCC.isEmpty && users.count != 0 {
                        let requester = onGoingCC.components(separatedBy: ",")[0]
                        let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                        if pin == requester || pin == officer {
                            DispatchQueue.main.async {
                                if !self.end.isEnabled {
                                    return
                                }
                                if self.buttonWB.isDescendant(of: self.view){
                                    self.buttonWB.removeFromSuperview()
                                }
                                if self.buttonChat.isDescendant(of: self.view){
                                    self.buttonChat.removeFromSuperview()
                                }
                                if self.viewIfLoaded?.window != nil {
                                    let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Call Center Session has ended".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                                    banner.show()
                                }
                                self.timer?.invalidate()
                                self.timer = nil
                                self.status.text = "Call Center Session has ended..."
                                self.end.isEnabled = false
                            }
                            QmeraAudioViewController.isLoop = false
                            QmeraAudioViewController.bSpeakerPhone = false
                            do { try AVAudioSession.sharedInstance().setActive(false) } catch {}
                            Nexilis.callAPNActivated = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.didEnd(sender: true)
                            }
                            return
                        }
                    } else if !onGoingCC.isEmpty && users.count == 0 {
                        DispatchQueue.main.async {
                            if !self.end.isEnabled {
                                return
                            }
                            if self.buttonWB.isDescendant(of: self.view){
                                self.buttonWB.removeFromSuperview()
                            }
                            if self.buttonChat.isDescendant(of: self.view){
                                self.buttonChat.removeFromSuperview()
                            }
                            if self.viewIfLoaded?.window != nil {
                                let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Call Center Session has ended".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                            self.timer?.invalidate()
                            self.timer = nil
                            self.status.text = "Call Center Session has ended..."
                            self.end.isEnabled = false
                        }
                        QmeraAudioViewController.isLoop = false
                        QmeraAudioViewController.bSpeakerPhone = false
                        do { try AVAudioSession.sharedInstance().setActive(false) } catch {}
                        Nexilis.callAPNActivated = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.didEnd(sender: true)
                        }
                        return
                    } else if users.count == 0 {
                        DispatchQueue.main.async {
                            if self.isOutgoing {
                                let longCall = self.timer == nil ? "0" : self.status.text ?? ""
                                Nexilis.saveMessageCall(idCall: self.idCall, textMessage: "Outgoing audio call".localized() + " at \(longCall)", fPin: User.getMyPin() ?? "", lPin: !self.data.isEmpty ? self.data : self.user != nil ? self.user!.pin : "", timeCall: self.timeStartCall, attachment_type: MessageScope.CALL)
                            } else {
                                if self.timer == nil {
                                    Nexilis.saveMessageCall(idCall: self.idCall, textMessage: "Missed audio call".localized() + " at 0", fPin: !self.data.isEmpty ? self.data : self.user != nil ? self.user!.pin : "", lPin: User.getMyPin() ?? "", timeCall: self.timeStartCall, attachment_type: MessageScope.MISSED_CALL)
                                } else {
                                    Nexilis.saveMessageCall(idCall: self.idCall, textMessage: "Incoming audio call".localized() + " at \(self.status.text ?? "")", fPin: !self.data.isEmpty ? self.data : self.user != nil ? self.user!.pin : "", lPin: User.getMyPin() ?? "", timeCall: self.timeStartCall, attachment_type: MessageScope.CALL)
                                }
                            }
                            self.timer?.invalidate()
                            self.timer = nil
                            self.status.text = "Audio Call Ended".localized()
                            self.end.isEnabled = false
                            self.invite.isEnabled = false
                            self.speaker.isEnabled = false
                            self.mic.isEnabled = false
                            let controller = self.presentedViewController
                            if controller != nil {
                                controller!.dismiss(animated: true)
                            }
                        }
                        QmeraAudioViewController.isLoop = false
                        QmeraAudioViewController.bSpeakerPhone = false
                        do { try AVAudioSession.sharedInstance().setActive(false) } catch {}
                        Nexilis.callAPNActivated = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.didEnd(sender: true)
                        }
                        return
                    } else if users.count == 1 {
                        if !users[0].isConnected{
                            DispatchQueue.main.async {
                                self.resetViewToOutgoing()
                            }
                        }
                    }
                    DispatchQueue.main.async{ [self] in
                        if users.count == 1 && !buttonWB.isEnabled {
                            buttonWB.isEnabled = true
                        }
                    }
                }
            } else if state == Nexilis.OFFLINE { // Offline
                DispatchQueue.main.async {
                    Nexilis.stopRingtoneCall()
                    Nexilis.stopRingbacktoneCall()
                }
                let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                if let pin = arrayMessage.first, let index = users.firstIndex(of: User(pin: String(pin))) {
                    users.remove(at: index)
                    if !onGoingCC.isEmpty && users.count != 0 {
                        DispatchQueue.main.async {
                            var members = ""
                            for user in self.users {
                                if members.isEmpty {
                                    members = "\(user.pin)"
                                } else {
                                    members = ",\(user.pin)"
                                }
                            }
                            SecureUserDefaults.shared.set("\(members)", forKey: "membersCC")
                        }
                    }
                    DispatchQueue.main.async { [self] in
                        if users.count == 1 && !buttonWB.isEnabled {
                            buttonWB.isEnabled = true
                        }
                    }
                }
                if users.count == 0 {
                    DispatchQueue.main.async {
                        self.status.text = "Offline..."
                        self.end.isEnabled = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.didEnd(sender: false)
                        }
                    }
                }
            } else if state == Nexilis.BUSY { // Busy
                let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
                if let pin = arrayMessage.first, let index = users.firstIndex(of: User(pin: String(pin))) {
                    users.remove(at: index)
                    if !onGoingCC.isEmpty && users.count != 0 {
                        DispatchQueue.main.async {
                            var members = ""
                            for user in self.users {
                                if members.isEmpty {
                                    members = "\(user.pin)"
                                } else {
                                    members = ",\(user.pin)"
                                }
                            }
                            SecureUserDefaults.shared.set("\(members)", forKey: "membersCC")
                        }
                    }
                    DispatchQueue.main.async { [self] in
                        if users.count == 1 && !buttonWB.isEnabled {
                            buttonWB.isEnabled = true
                        }
                    }
                }
                if users.count == 0 {
                    DispatchQueue.main.async {
                        let longCall =  "0"
                        Nexilis.saveMessageCall(idCall: self.idCall, textMessage: "Outgoing audio call".localized() + " at \(longCall)", fPin: User.getMyPin() ?? "", lPin: !self.data.isEmpty ? self.data : self.user != nil ? self.user!.pin : "", timeCall: self.timeStartCall, attachment_type: MessageScope.CALL)
                        self.status.text = "Busy..."
                        self.end.isEnabled = false
                        if self.isOutgoing {
                            Nexilis.playBusyCall()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.didEnd(sender: false)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        Nexilis.stopRingtoneCall()
                        Nexilis.stopRingbacktoneCall()
                    }
                }
            }
        }
    }
    
}

extension QmeraAudioViewController : WhiteboardReceiver {
    
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
            for d in users{
                if d.pin == roomId.components(separatedBy: "wbvc")[0] {
                    continue
                }
                if destString.isEmpty{
                    destString = d.pin
                } else {
                    destString = destString + ",\(d.pin)"
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
