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

class QmeraVideoViewController: UIViewController {
    
    static private var volumeView: MPVolumeView!
    static private var bSpeakerPhone: Bool! = false
    static private var lastVolume: Float! = AVAudioSession.sharedInstance().outputVolume
    
    
    var dataPerson: [[String: String?]] = []
    var fPin = ""
    var wbRoomId = ""
    var isInisiator = true
    var isSpeaker = true
    var isMuted = false
    var isPresent = false
    var callFCM = true
    var isNavigationHidden = false
    var listRemoteViewFix: [UIImageView] = [
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
        UIView()
    ]
    var imageMuted: [UIImageView] = [
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
    let myImage = UIImageView()
    let name = UILabel()
    let profileImage = UIImageView()
    let labelIncomingOutgoing = UILabel()
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
    let buttonAddParticipant = UIButton()
    let buttonSpeaker = UIButton()
    let buttonRotate = UIButton()
    let buttonMuted = UIButton()
    var showStackViewToolbar = true
    let scrollRemoteView = UIScrollView()
    var isAutoAccept = false
    var wbTimer = Timer()
    var wbBlink = false
    var showNotifCCEnd = false
    var transformZoomAfterNewUserMore2 = false
    var isAddCall = ""
    var ticketId = ""
    var autoAcceptAPN = false
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
    
    static func turnSpeakerOn(bSpeakerOn: Bool!) {
        bSpeakerPhone = bSpeakerOn
        var volume:Float! = 0
        if (bSpeakerPhone) {
            volume = 50
        } else {
            volume = 3
        }
        API.adjustVolume(fValue: volume)
    }
    
    deinit {
        navigationController?.changeAppearance(clear: false)
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.topItem?.backBarButtonItem = nil
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        NotificationCenter.default.removeObserver(self)
        Nexilis.floatingButton.isHidden = false
        Nexilis.callAPNActivated = false
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
        Nexilis.callAPNActivated = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Nexilis.setWhiteboardReceiver(receiver: self)
        Nexilis.floatingButton.isHidden = true
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        navigationController?.changeAppearance(clear: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onStatusCall(_:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusCall), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onCallFCM(notification:)), name: NSNotification.Name(rawValue: Nexilis.callFCM), object: nil)
        
        view.backgroundColor = .clear
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        navigationItem.setHidesBackButton(true, animated: false)
        if fPin != ""{
            getDataProfile(fPin: fPin)
        }
        
        addZoomView()
        addCameraView()
        addListRemoteView()
        addBackgroundIncoming()
        addProfileNameCalling()
        Calling()
        addToolbar()
        addTimerVC()
        addImageMutedOnZoom()
        if isAutoAccept {
            didTapAcceptCallButton()
        }
        if autoAcceptAPN {
//            API.receiveCCall(sParty: dataPerson[0]["f_pin"]!, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView,ivRemoteZ: zoomView)
            DispatchQueue.global().async {
                if let response1 = Nexilis.writeSync(message: CoreMessage_TMessageBank.getNotifyCalling(fPin: self.fPin, lPin: User.getMyPin()!, type: "1")) {
                    if response1.isOk() {
                    }
                }
            }
        }
        
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
    //                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getAddFriendQRCode(fpin: fPin)), response.isOk() {
    //                    self.getDataProfile(fPin: fPin)
    //                }
    //                Nexilis.addFriend (fpin: "\(fPin)") { result in
    //                    if result {
    //                        self.getDataProfile(fPin: fPin)
    //                    } else {
    //                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
    //                        imageView.tintColor = .white
    //                        let banner = FloatingNotificationBanner(title: "Server busy, please try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
    //                        banner.show()
    //                    }
    //                }
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
    }
    
    func addTimerVC() {
        view.addSubview(containerTimerVC)
        containerTimerVC.anchor(top: view.safeAreaLayoutGuide.topAnchor, centerX: view.centerXAnchor, minWidth: 40)
        containerTimerVC.makeRoundedView(radius: 8)
        containerTimerVC.backgroundColor = .black.withAlphaComponent(0.3)
        containerTimerVC.addSubview(labelTimerVC)
        labelTimerVC.anchor(left: containerTimerVC.leftAnchor, right: containerTimerVC.rightAnchor, paddingLeft: 8, paddingRight: 8, centerX: containerTimerVC.centerXAnchor, centerY: containerTimerVC.centerYAnchor)
        labelTimerVC.textColor = .white
        containerTimerVC.isHidden = true
    }
    
    func addImageMutedOnZoom() {
        view.addSubview(mutedZoom)
        mutedZoom.anchor(top: containerTimerVC.bottomAnchor, paddingTop: 10, centerX: view.centerXAnchor, width: 30, height: 40)
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
    
    func addBackgroundIncoming() {
        view.addSubview(myImage)
        myImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            myImage.topAnchor.constraint(equalTo: view.topAnchor),
            myImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            myImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            myImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        myImage.backgroundColor = .lightGray
        myImage.tintColor = .secondaryColor
        let image = dataPerson[0]["picture"]!!
        if image.isEmpty {
            myImage.image = UIImage(systemName: "person")
            myImage.contentMode = .scaleAspectFit
        } else {
            myImage.setImage(name: image)
            myImage.contentMode = .scaleAspectFill
        }
//        let idMe = User.getMyPin() as String?
//        Database().database?.inTransaction({ fmdb, rollback in
//            if let c = Database().getRecords(fmdb: fmdb, query: "select image_id from BUDDY where f_pin = '\(idMe!)'"), c.next() {
//                let image = c.string(forColumnIndex: 0)!
//                if image.isEmpty {
//                    myImage.image = UIImage(systemName: "person")
//                    myImage.contentMode = .scaleAspectFit
//                } else {
//                    myImage.setImage(name: image)
//                    myImage.contentMode = .scaleAspectFill
//                }
//                c.close()
//            }
//        })
    }
    
    func addProfileNameCalling() {
        view.addSubview(profileImage)
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        profileImage.frame.size = CGSize(width: 60.0, height: 60.0)
        NSLayoutConstraint.activate([
            profileImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            profileImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImage.widthAnchor.constraint(equalToConstant: 60.0),
            profileImage.heightAnchor.constraint(equalToConstant: 63.0)
        ])
        profileImage.backgroundColor = .lightGray
        profileImage.tintColor = .secondaryColor
        profileImage.circle()
        let image = dataPerson[0]["picture"]!!
        if image.isEmpty {
            profileImage.image = UIImage(systemName: "person")
            profileImage.contentMode = .scaleAspectFit
            profileImage.layer.borderWidth = 1
            profileImage.layer.borderColor = UIColor.secondaryColor.cgColor
        } else {
            profileImage.setImage(name: image)
            profileImage.contentMode = .scaleAspectFill
        }
        
        view.addSubview(name)
        name.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            name.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 5.0),
            name.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        name.font = UIFont.systemFont(ofSize: 12)
        name.backgroundColor = .black.withAlphaComponent(0.05)
        name.layer.cornerRadius = 5.0
        name.clipsToBounds = true
        name.textColor = .mainColor
        name.text = dataPerson[0]["name"]!?.trimmingCharacters(in: .whitespaces)
    }
    
    func Calling() {
        view.addSubview(labelIncomingOutgoing)
        labelIncomingOutgoing.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelIncomingOutgoing.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 40.0),
            labelIncomingOutgoing.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        if isInisiator {
            Nexilis.playRingbacktoneCall()
            labelIncomingOutgoing.text = "Connecting".localized()
            if ticketId.isEmpty {
                if callFCM {
                    DispatchQueue.global().async {
                        if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getCalling(fPin: self.dataPerson[0]["f_pin"]!!, type: "2"), timeout: 30 * 1000) {
                            if response.isOk() {
                                
                            } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "01" {
                                API.initiateCCall(sParty: self.dataPerson[0]["f_pin"]!, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: self.listRemoteViewFix, ivLocalView: self.cameraView, ivRemoteZ: self.zoomView)
                            } else {
                                DispatchQueue.main.async {
                                    if self.labelIncomingOutgoing.isDescendant(of: self.view) {
                                        self.labelIncomingOutgoing.text = "Busy".localized()
                                    }
                                    if self.buttonDecline.isDescendant(of: self.view) {
                                        self.buttonDecline.removeFromSuperview()
                                    }
                                    if self.buttonAccept.isDescendant(of: self.view) {
                                        self.buttonAccept.removeFromSuperview()
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
                    API.initiateCCall(sParty: dataPerson[0]["f_pin"]!, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView, ivRemoteZ: zoomView)
                }
            } else {
                API.ccs(sTicketID: ticketId, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView, ivRemoteZ: zoomView, bCameraOn: true)
                if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getIncomingCallCS(f_pin_opposite: users[0].pin), timeout: 30 * 1000){
                    if response.mBodies[CoreMessage_TMessageKey.ERRCOD] != "01" {
                        endAllCall()
                    }
                }
            }
        } else {
            Nexilis.playRingtoneCall()
            labelIncomingOutgoing.text = "Incoming video call".localized() + "..."
        }
        labelIncomingOutgoing.font = UIFont.systemFont(ofSize: 12)
        labelIncomingOutgoing.backgroundColor = .black.withAlphaComponent(0.05)
        labelIncomingOutgoing.layer.cornerRadius = 5.0
        labelIncomingOutgoing.clipsToBounds = true
        labelIncomingOutgoing.textColor = .mainColor
    }
    
    func addToolbar() {
        view.addSubview(buttonDecline)
        buttonDecline.translatesAutoresizingMaskIntoConstraints = false
        buttonDecline.frame.size = CGSize(width: 70.0, height: 70.0)
        if isInisiator {
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
        
        if !isInisiator{
            view.addSubview(buttonAccept)
            buttonAccept.translatesAutoresizingMaskIntoConstraints = false
            buttonAccept.frame.size = CGSize(width: 70.0, height: 70.0)
            NSLayoutConstraint.activate([
                buttonAccept.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60.0),
                buttonAccept.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(view.frame.width * 0.2)),
                buttonAccept.widthAnchor.constraint(equalToConstant: 70.0),
                buttonAccept.heightAnchor.constraint(equalToConstant: 70.0)
            ])
            buttonAccept.backgroundColor = .greenColor
            buttonAccept.circle()
            buttonAccept.setImage(UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            buttonAccept.tintColor = .white
            buttonAccept.addTarget(self, action: #selector(didTapAcceptCallButton), for: .touchUpInside)
        }
    }
    
    @objc func onCallFCM(notification: NSNotification) {
        DispatchQueue.main.async { [self] in
            let data:[AnyHashable : Any] = notification.userInfo!
            if let l_pin = data["l_pin"] as? String {
                if let f_pin = data["f_pin"] as? String {
                    if f_pin == User.getMyPin()!  {
                        labelIncomingOutgoing.text = "Waiting for answer".localized()
                        API.initiateCCall(sParty: l_pin, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView, ivRemoteZ: zoomView)
                    }
                }
            }
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
                            SecureUserDefaults.shared.set(members, forKey: "inEditorPersonal")
                            SecureUserDefaults.shared.set("\(members)", forKey: "membersCC")
                        }
                    }
                    self.users.append(User.getData(pin: dataMessage.getPIN())!)
                }
            }
        }
    }
    
    @objc func didTapDeclineCallButton(sender: AnyObject){
        let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
        if !onGoingCC.isEmpty {
            let alert = LibAlertController(title: "Interaction with Call Center is in progress".localized(), message: "Are you sure you want to end the Call Center?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                if(!self.wbRoomId.isEmpty){
                    DispatchQueue.main.async {
                        self.wbTimer.invalidate()
                        _ = Nexilis.getWhiteboardDelegate()?.terminate()
                    }
                }
                Nexilis.stopRingtoneCall()
                Nexilis.stopRingbacktoneCall()
                self.endAllCall()
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = LibAlertController(title: "End Video Call".localized(), message: "Are you sure you want to end video call?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {(_) in
                Nexilis.stopRingtoneCall()
                Nexilis.stopRingbacktoneCall()
                if self.labelIncomingOutgoing.isDescendant(of: self.view) {
                    self.labelIncomingOutgoing.text = "Video call is over".localized()
                }
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
                self.labelTimerVC.text = "Video call is over".localized()
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
//            Nexilis.startAudio()
            if ticketId.isEmpty {
                API.receiveCCall(sParty: dataPerson[0]["f_pin"]!, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView,ivRemoteZ: zoomView)
            } else {
                API.csa(sTicketID: ticketId, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: listRemoteViewFix, ivLocalView: cameraView, ivRemoteZ: zoomView, bCameraOn: true)
            }
        }
        DispatchQueue.main.async {
            self.myImage.removeFromSuperview()
            self.name.removeFromSuperview()
            self.profileImage.removeFromSuperview()
            self.labelIncomingOutgoing.removeFromSuperview()
            self.buttonAccept.removeFromSuperview()
            NSLayoutConstraint.deactivate([
                self.constraintLeadingButtonDecline,
                self.constraintBottomButtonDecline
            ])
            self.addToolbarAfterAccept()
            self.buttonDecline.setImage(UIImage(systemName: "phone.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            UIView.animate(withDuration: 1.0, animations: {
                self.view.layoutIfNeeded()
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.containerTimerVC.isHidden = false
                self.buttonRotate.isHidden = false
                self.buttonAddParticipant.isHidden = false
                self.buttonSpeaker.isHidden = false
                self.buttonWB.isHidden = false
                self.buttonChat.isHidden = false
                self.poweredByView.isHidden = false
                self.buttonMuted.isHidden = false
                let connectDate = Date()
                self.vcTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    let format = Utils.callDurationFormatter.string(from: Date().timeIntervalSince(connectDate))
                    self.labelTimerVC.text = format
                }
                self.vcTimer.fire()
                API.adjustVolume(fValue: 10.0)
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
        editorPersonalVC.channelContactCenter = "2"
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
                self.buttonAddParticipant.isHidden = false
                self.buttonRotate.isHidden = false
                self.buttonMuted.isHidden = false
//                if(!self.wbRoomId.isEmpty){
//                    DispatchQueue.main.async {
//                        self.wbTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.runTimer), userInfo: nil, repeats: true)
//                    }
//                }
            }
        }
        self.buttonDecline.isHidden = true
        self.buttonSpeaker.isHidden = true
        self.buttonMuted.isHidden = true
        self.buttonAddParticipant.isHidden = true
        self.buttonRotate.isHidden = true
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
        
        view.addSubview(buttonAddParticipant)
        buttonAddParticipant.translatesAutoresizingMaskIntoConstraints = false
        buttonAddParticipant.frame.size = CGSize(width: 70.0, height: 70.0)
        NSLayoutConstraint.activate([
            buttonAddParticipant.widthAnchor.constraint(equalToConstant: 70.0),
            buttonAddParticipant.heightAnchor.constraint(equalToConstant: 70.0)
        ])
        buttonAddParticipant.backgroundColor = .secondaryColor
        buttonAddParticipant.setImage(UIImage(systemName: "person.badge.plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        buttonAddParticipant.tintColor = .mainColor
        buttonAddParticipant.circle()
        buttonAddParticipant.isHidden = true
        buttonAddParticipant.addTarget(self, action: #selector(didTapAddParticipantButton(sender:)), for: .touchUpInside)
        
        view.addSubview(buttonSpeaker)
        buttonSpeaker.translatesAutoresizingMaskIntoConstraints = false
        buttonSpeaker.frame.size = CGSize(width: 70.0, height: 70.0)
        NSLayoutConstraint.activate([
            buttonSpeaker.widthAnchor.constraint(equalToConstant: 70.0),
            buttonSpeaker.heightAnchor.constraint(equalToConstant: 70.0)
        ])
        buttonSpeaker.setImage(UIImage(systemName: "speaker.wave.2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
        self.buttonSpeaker.backgroundColor = .lightGray
        self.buttonSpeaker.tintColor = .mainColor
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
        
        if !ticketId.isEmpty {
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
            buttonChat.isHidden = true
            buttonChat.addTarget(self, action: #selector(didTapChatButton), for: .touchUpInside)
        }
        
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
        
        stackViewToolbar.addArrangedSubview(buttonAddParticipant)
        stackViewToolbar.addArrangedSubview(buttonDecline)
        stackViewToolbar.addArrangedSubview(buttonSpeaker)
        stackViewToolbar2.addArrangedSubview(buttonWB)
        stackViewToolbar2.addArrangedSubview(buttonChat)
        stackViewToolbar3.addArrangedSubview(buttonRotate)
        stackViewToolbar3.addArrangedSubview(buttonMuted)
//        startFaceTimer()
    }
    
    func endAllCall() {
        let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
        if !onGoingCC.isEmpty {
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
                            "type" : "2",
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
        }
        API.terminateCall(sParty: nil)
        cameraView.image = nil
        zoomView.image = nil
        listRemoteViewFix.removeAll()
        dataPerson.removeAll()
    }
    
    func setSpeaker(isSpeaker: Bool) {
        QmeraVideoViewController.turnSpeakerOn(bSpeakerOn: isSpeaker)
        DispatchQueue.main.async {
            if (isSpeaker) {
                self.buttonSpeaker.backgroundColor = .lightGray
                self.buttonSpeaker.tintColor = .mainColor
                self.buttonSpeaker.setImage(UIImage(systemName: "speaker.wave.2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            } else {
                self.buttonSpeaker.backgroundColor = .secondaryColor
                self.buttonSpeaker.tintColor = .mainColor
                self.buttonSpeaker.setImage(UIImage(systemName: "speaker.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .default)), for: .normal)
            }
            self.isSpeaker = isSpeaker
        }
    }
    
    @objc func didTapSpeakerButton(sender: AnyObject){
        setSpeaker(isSpeaker: !(self.isSpeaker))
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
                        API.initiateCCall(sParty: data["f_pin"]!, nCamIdx: 1, nResIdx: 2, nVQuality: 4, ivRemoteView: self.listRemoteViewFix, ivLocalView: self.cameraView, ivRemoteZ: self.zoomView)
                    }
                }
            }
            present(CustomNavigationController(rootViewController: contactViewController), animated: true, completion: nil)
        }
    }
    
    @objc func camera(sender: Any?) {
        DispatchQueue.global().async { [self] in
            if frontCamera {
                API.changeCameraParam(nCameraIdx: 0, nResolutionIndex: 2, nQuality: 4)
                frontCamera = false
            } else {
                API.changeCameraParam(nCameraIdx: 1, nResolutionIndex: 2, nQuality: 4)
                frontCamera = true
            }
        }
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
                    if arrayMessage[1] == "1" {
                        mutedZoom.isHidden = false
                    } else {
                        mutedZoom.isHidden = true
                    }
                }
            }
        } else if (state == Nexilis.VIDEO_CALL_ZOOM) && self.dataPerson.count > 1 {
            DispatchQueue.main.async {
                if arrayMessage[0] == arrayMessage[3] {
                    self.zoomView.transform   = CGAffineTransform.init(scaleX: -1.9, y: 2.2).rotated(by: (-CGFloat.pi)/2)
                    self.zoomView.contentMode = .scaleAspectFit
                } else {
                    self.zoomView.transform   = CGAffineTransform.init(scaleX: -1.9, y: 2.2).rotated(by: (CGFloat.pi)/2)
                    self.zoomView.contentMode = .scaleAspectFit
                }
            }
        } else if (state == Nexilis.VIDEO_CAMERA_PARAMS_CHANED){
            if(arrayMessage[3] == "0"){
                DispatchQueue.main.async {
                    if self.dataPerson.count == 1 && arrayMessage[2] == "1" && arrayMessage[4] == "1" {
                        self.zoomView.transform = CGAffineTransform.init(scaleX: 1.9, y: 2.2).rotated(by: (-CGFloat.pi)/2)
                    } else {
                        self.zoomView.transform = CGAffineTransform.init(scaleX: 1.9, y: 2.2).rotated(by: (CGFloat.pi)/2)
                    }
                }
            }
        }
        else if (state == Nexilis.VIDEO_CALL_OFFHOOK) {
            DispatchQueue.main.async {
                Nexilis.stopRingtoneCall()
                Nexilis.stopRingbacktoneCall()
            }
            let channel = arrayMessage[3]
            remoteChannel[String(channel)] = String(arrayMessage[5])
            DispatchQueue.main.async {
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
                            self.buttonAddParticipant.isHidden = false
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
                
                if self.users.count >= 1, let user = User.getData(pin: String(arrayMessage[1])), !self.users.contains(user) {
                    self.users.append(user)
                }
                if arrayMessage[5] == "2" && self.dataPerson.count == 1 {
                    DispatchQueue.main.async {
                        self.zoomView.transform   = CGAffineTransform.init(scaleX: -1.9, y: 2.2).rotated(by: (CGFloat.pi)/2)
                        self.zoomView.contentMode = .scaleAspectFit
                    }
                }
                else if self.dataPerson.count == 1 {
                    DispatchQueue.main.async {
                        self.zoomView.transform   = CGAffineTransform.init(scaleX: 1.9, y: 2.2).rotated(by: (-CGFloat.pi)/2)
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
                if self.isInisiator && self.name.isDescendant(of: self.view) {
                    self.didTapAcceptCallButton()
                }
                let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[1]})
                if indexPerson != nil {
                    self.dataPerson[indexPerson!]["user_type"] = String(arrayMessage[5])
                }
            }
        } else if (state == Nexilis.VIDEO_CALL_END || state == Nexilis.AUDIO_CALL_END) {
            DispatchQueue.main.async {
                Nexilis.stopRingtoneCall()
                Nexilis.stopRingbacktoneCall()
            }
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            if !onGoingCC.isEmpty {
                let requester = onGoingCC.components(separatedBy: ",")[0]
                let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                if arrayMessage[0] == requester || arrayMessage[0] == officer {
                    DispatchQueue.main.async {
                        let controller = self.presentedViewController
                        if controller != nil {
                            controller!.dismiss(animated: true)
                        }
                        if !self.showNotifCCEnd{
                            let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Call Center Session has ended".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .info, colors: nil, iconPosition: .center)
                            banner.show()
                            self.showNotifCCEnd = true
                        }
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
                        _ = Nexilis.getWhiteboardDelegate()?.terminate()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.endAllCall()
                        self.dismiss(animated: true, completion: nil)
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                if (self.dataPerson.count == 1) {
                    if self.labelIncomingOutgoing.isDescendant(of: self.view) {
                        self.labelIncomingOutgoing.text = "Video call is over".localized()
                    }
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
                    self.labelTimerVC.text = "Video call is over".localized()
                    _ = Nexilis.getWhiteboardDelegate()?.terminate()
                    let controller = self.presentedViewController
                    if controller != nil {
                        controller!.dismiss(animated: true)
                    }
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
                            if !self.buttonWB.isEnabled {
                                self.buttonWB.isEnabled = true
                            }
                            if !self.buttonRotate.isEnabled {
                                self.buttonRotate.isEnabled = true
                            }
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
                    if !onGoingCC.isEmpty {
                        if let pin = arrayMessage.first, let index = self.users.firstIndex(of: User(pin: String(pin))) {
                            self.users.remove(at: index)
                        }
                    }
                    
                    if self.dataPerson.count == 1 {
                        self.transformZoomAfterNewUserMore2 = false
                        self.zoomView.transform   = CGAffineTransform.init(scaleX: 1.9, y: 2.2).rotated(by: (CGFloat.pi)/2)
                    }
                }
            }
        } else if (state == Nexilis.OFFLINE) {
            DispatchQueue.main.async {
                Nexilis.stopRingtoneCall()
                Nexilis.stopRingbacktoneCall()
            }
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            DispatchQueue.main.async {
                if (self.dataPerson.count == 1) {
                    if self.labelIncomingOutgoing.isDescendant(of: self.view) {
                        self.labelIncomingOutgoing.text = "Offline".localized()
                    }
                    if self.buttonDecline.isDescendant(of: self.view) {
                        self.buttonDecline.removeFromSuperview()
                    }
                    if self.buttonAccept.isDescendant(of: self.view) {
                        self.buttonAccept.removeFromSuperview()
                    }
                } else {
                    let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[0]})
                    if indexPerson != nil {
                        if (self.dataPerson.count == 2) {
                            self.containerLabelName.forEach({ $0.subviews.forEach({ $0.removeFromSuperview() }) })
                            self.scrollRemoteView.subviews.forEach({ $0.removeFromSuperview() })
                            if !self.buttonWB.isEnabled {
                                self.buttonWB.isEnabled = true
                            }
                            if !self.buttonRotate.isEnabled {
                                self.buttonRotate.isEnabled = true
                            }
                        } else {
                            self.containerLabelName[indexPerson! + indexPerson!].subviews.forEach({ $0.removeFromSuperview() })
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            self.containerLabelName[indexPerson! + indexPerson!].subviews.forEach({ $0.removeFromSuperview() })
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            if indexPerson! + 1 <= self.listRemoteViewFix.count {
                                let viewAfterRemote = self.listRemoteViewFix[indexPerson! + 1]
                                let viewAfterName = self.containerLabelName[indexPerson! + 1]
                                viewAfterRemote.frame.origin.y = viewAfterRemote.frame.origin.y - 170
                                viewAfterName.frame.origin.y = viewAfterName.frame.origin.y - 170
                                UIView.animate(withDuration: 0.35, animations: {
                                    self.scrollRemoteView.layoutIfNeeded()
                                })
                            }
                        }
                    }
                    if !onGoingCC.isEmpty {
                        if let pin = arrayMessage.first, let index = self.users.firstIndex(of: User(pin: String(pin))) {
                            self.users.remove(at: index)
                            if !onGoingCC.isEmpty && self.users.count != 0 {
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
                        }
                    }
                    self.dataPerson.remove(at: indexPerson!)
                }
            }
            if (self.dataPerson.count == 1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.endAllCall()
                    if self.isInisiator && onGoingCC.isEmpty && !self.isPresent {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        } else if (state == Nexilis.BUSY) {
            DispatchQueue.main.async {
                Nexilis.stopRingtoneCall()
                Nexilis.stopRingbacktoneCall()
            }
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            DispatchQueue.main.async { [self] in
                if (self.dataPerson.count == 1) {
                    if self.labelIncomingOutgoing.isDescendant(of: self.view) {
                        self.labelIncomingOutgoing.text = "Busy".localized()
                    }
                    if self.buttonDecline.isDescendant(of: self.view) {
                        self.buttonDecline.removeFromSuperview()
                    }
                    if self.buttonAccept.isDescendant(of: self.view) {
                        self.buttonAccept.removeFromSuperview()
                    }
                } else {
                    let indexPerson = self.dataPerson.firstIndex(where: {$0["f_pin"]!! == arrayMessage[0]})
                    if indexPerson != nil {
                        if (self.dataPerson.count == 2) {
                            self.containerLabelName.forEach({ $0.subviews.forEach({ $0.removeFromSuperview() }) })
                            self.scrollRemoteView.subviews.forEach({ $0.removeFromSuperview() })
                            if !self.buttonWB.isEnabled {
                                self.buttonWB.isEnabled = true
                            }
                            if !self.buttonRotate.isEnabled {
                                self.buttonRotate.isEnabled = true
                            }
                        } else {
                            self.containerLabelName[indexPerson! + indexPerson!].subviews.forEach({ $0.removeFromSuperview() })
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            self.containerLabelName[indexPerson! + indexPerson!].subviews.forEach({ $0.removeFromSuperview() })
                            self.scrollRemoteView.subviews[indexPerson! + indexPerson!].removeFromSuperview()
                            if indexPerson! + 1 <= self.listRemoteViewFix.count {
                                let viewAfterRemote = self.listRemoteViewFix[indexPerson! + 1]
                                let viewAfterName = self.containerLabelName[indexPerson! + 1]
                                viewAfterRemote.frame.origin.y = viewAfterRemote.frame.origin.y - 170
                                viewAfterName.frame.origin.y = viewAfterName.frame.origin.y - 170
                                UIView.animate(withDuration: 0.35, animations: {
                                    self.scrollRemoteView.layoutIfNeeded()
                                })
                            }
                        }
                    }
                    if !onGoingCC.isEmpty {
                        if let pin = arrayMessage.first, let index = self.users.firstIndex(of: User(pin: String(pin))) {
                            self.users.remove(at: index)
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
                        }
                    }
                    self.dataPerson.remove(at: indexPerson!)
                }
            }
            if (self.dataPerson.count == 1) {
                DispatchQueue.main.async {
                    Nexilis.playBusyCall()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    Nexilis.stopBusyCall()
                    self.endAllCall()
                    if self.isInisiator && onGoingCC.isEmpty && !self.isPresent {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        } else if (state == Nexilis.VIDEO_CALL_RINGING) {
            DispatchQueue.main.async {
                if (self.dataPerson.count > 1) {
                    if (self.dataPerson.count == 2) {
                        for i in 0...1{
                            self.scrollRemoteView.addSubview(self.listRemoteViewFix[i])
                            self.listRemoteViewFix[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 160)
                            self.listRemoteViewFix[i].backgroundColor = .clear
                            self.listRemoteViewFix[i].makeRoundedView(radius: 8.0)
                            self.scrollRemoteView.addSubview(self.containerLabelName[i])
                            self.containerLabelName[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 30)
                            self.containerLabelName[i].backgroundColor = .orangeBNI.withAlphaComponent(0.5)
                            self.containerLabelName[i].makeRoundedView(radius: 8.0)
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
                    } else {
                        let i = self.dataPerson.count - 1
                        self.scrollRemoteView.addSubview(self.listRemoteViewFix[i])
                        self.listRemoteViewFix[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 160)
                        self.listRemoteViewFix[i].backgroundColor = .clear
                        self.listRemoteViewFix[i].makeRoundedView(radius: 8.0)
                        self.scrollRemoteView.addSubview(self.containerLabelName[i])
                        self.containerLabelName[i].frame = CGRect(x: 0, y: 170 * i, width: 120, height: 30)
                        self.containerLabelName[i].backgroundColor = .orangeBNI.withAlphaComponent(0.5)
                        self.containerLabelName[i].makeRoundedView(radius: 8.0)
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
                    if self.buttonWB.isEnabled {
                        self.buttonWB.isEnabled = false
                    }
                    if self.buttonRotate.isEnabled {
                        self.buttonRotate.isEnabled = false
                    }
                }
            }
        }
    }
}

extension QmeraVideoViewController : WhiteboardReceiver {
    
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
            if !self.buttonWB.isEnabled {
                return
            }
            self.wbBlink = !self.wbBlink
            if(self.wbBlink){
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
