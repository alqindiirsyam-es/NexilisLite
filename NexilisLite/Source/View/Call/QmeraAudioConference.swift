//
//  QmeraAudioConference.swift
//  NexilisLite
//
//  Created by Qindi on 14/04/22.
//

import UIKit
import AVFoundation
import nuSDKService
import NotificationBannerSwift

class QmeraAudioConference: UIViewController {
    
    let buttonSize: CGFloat = 70
    
//    lazy var data: String = "" {
//        didSet {
//            getUserData { user in
//                self.user = user
//            }
//        }
//    }
    
//    var user: User?
    
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
    
    var roomId = ""
    
    private var timer: Timer?
    
    private var firstCall: Bool = true
    
    private var isSpeaker: Bool = false
    
    let status: UILabel = {
        let label = UILabel()
        label.text = "Waiting for participant..."
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
    
    let stack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    public override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            NotificationCenter.default.removeObserver(self)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(onStatusCall(_:)), name: NSNotification.Name(rawValue: Nexilis.listenerStatusCall), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onReceiveMessage(notification:)), name: NSNotification.Name(rawValue: Nexilis.listenerReceiveChat), object: nil)
        
        if isOutgoing {
            users.append(User.getData(pin: User.getMyPin()!)!)
            API.initiateCR(sConfRoom: roomId)
            outgoingView()
        } else {
            users.append(User.getData(pin: User.getMyPin()!)!)
            API.joinCR(sConfRoom: roomId)
            ongoingView()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        end.circle()
        reject.circle()
        accept.circle()
        invite.circle()
        speaker.circle()
    }
    
//    private func getUserData(completion: @escaping (User?) -> ()) {
//        if let user = self.user {
//            completion(user)
//            return
//        }
//        var user: User?
//        DispatchQueue.global().async {
//            Database.shared.database?.inTransaction({ fmdb, rollback in
//                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, first_name, last_name, image_id from BUDDY where f_pin = '\(self.data)'"), cursor.next() {
//                    user = User(pin: cursor.string(forColumnIndex: 0) ?? "",
//                                firstName: cursor.string(forColumnIndex: 1) ?? "",
//                                lastName: cursor.string(forColumnIndex: 2) ?? "",
//                                thumb: cursor.string(forColumnIndex: 3) ?? "")
//                    cursor.close()
//                }
//            })
//        }
//        completion(user)
//    }
    
    private func outgoingView() {
        view.addSubview(end)
        end.anchor(bottom: view.bottomAnchor, paddingBottom: 60, centerX: view.centerXAnchor, width: buttonSize, height: buttonSize)
        
        end.addTarget(self, action: #selector(didEnd(sender:)), for: .touchUpInside)
    }
    
    private func incomingView() {
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
        
        view.addSubview(stack)
        
        stack.anchor(bottom: view.bottomAnchor, paddingBottom: 60, centerX: view.centerXAnchor, width: buttonSize * 4, height: buttonSize)
        
        stack.addArrangedSubview(invite)
        stack.addArrangedSubview(end)
        stack.addArrangedSubview(speaker)
        
        invite.addTarget(self, action: #selector(didInvite(sender:)), for: .touchUpInside)
        end.addTarget(self, action: #selector(didEnd(sender:)), for: .touchUpInside)
        speaker.addTarget(self, action: #selector(didSpeaker(sender:)), for: .touchUpInside)
    }
    
    
    // MARK: - Action
    
    @objc func didSpeaker(sender: Any?) {
        isSpeaker = !isSpeaker
        speaker.isSelected = isSpeaker
//        do {
//            if "iPhone 6" == "\(UIDevice().type)" {
//                try AVAudioSession.sharedInstance().overrideOutputAudioPort(isSpeaker ? .speaker : .none)
//            }
//        } catch {
//        }
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
                // Start Calling
                Nexilis.shared.callManager.startCall(handle: user.pin)
            }
        }
        controller.selectedUser.append(contentsOf: users)
        present(CustomNavigationController(rootViewController: controller), animated: true, completion: nil)
    }
    
    @objc func didEnd(sender: Any?) {
        let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
        if !onGoingCC.isEmpty {
            if sender != nil && sender is Bool {
                self.dismiss(animated: false, completion: nil)
                let requester = onGoingCC.components(separatedBy: ",")[0]
                let officer = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[1]
                let complaintId = onGoingCC.isEmpty ? "" : onGoingCC.components(separatedBy: ",")[2]
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
                    if requester == idMe {
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.endCallCenter(complaint_id: complaintId, l_pin: officer))
                    } else {
                        _ = Nexilis.write(message: CoreMessage_TMessageBank.endCallCenter(complaint_id: complaintId, l_pin: requester))
                    }
                    SecureUserDefaults.shared.removeValue(forKey: "onGoingCC")
                    SecureUserDefaults.shared.removeValue(forKey: "membersCC")
                    SecureUserDefaults.shared.removeValue(forKey: "startTimeCC")
                    SecureUserDefaults.shared.removeValue(forKey: "waitingRequestCC")
                }
//                if let user = self.user, let call = Nexilis.shared.callManager.call(with: user.pin) {
//                    Nexilis.shared.callManager.end(call: call)
//                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
//            if let user = self.user, let call = Nexilis.shared.callManager.call(with: user.pin) {
//                Nexilis.shared.callManager.end(call: call)
//            }
            dismiss(animated: false, completion: nil)
        }
    }
    
    @objc func didReject(sender: Any?) {
        didEnd(sender: sender)
    }
    
    @objc func didAccept(sender: Any?) {
        NSLayoutConstraint.deactivate(stack.constraints)
        stack.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        ongoingView()
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
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
                        }
                    }
                    self.users.append(User.getData(pin: dataMessage.getPIN())!)
                }
            }
        }
    }
    
    private func checkParticipant(fPin: String) {
        if let user = User.getData(pin: fPin), !self.users.contains(user) {
            self.users.append(user)
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            if !onGoingCC.isEmpty {
                DispatchQueue.main.async {
                    var members = ""
                    for user in self.users {
                        if user.pin == User.getMyPin()! {
                            continue
                        } else if members.isEmpty {
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
    
    @objc func onStatusCall(_ notification: NSNotification) {
        if let data = notification.userInfo,
           let state = data["state"] as? Int,
           let message = data["message"] as? String {
            let arrayMessage = message.split(separator: ",")
            //print("UYY \(state) \(message)")
            if state == Nexilis.AUDIO_CALL_OFFHOOK {
                if users.count == 1 && firstCall {
                    DispatchQueue.main.async {
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
                if let _ = User.getData(pin: String(arrayMessage[1])) {
                    checkParticipant(fPin: String(arrayMessage[1]))
                } else {
                    if isOutgoing {
                        Nexilis.addFriend(fpin: String(arrayMessage[1])) { result in
                            if result {
                                self.checkParticipant(fPin: String(arrayMessage[1]))
                            }
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1, execute: {
                            Nexilis.addFriend(fpin: String(arrayMessage[1])) { result in
                                if result {
                                    self.checkParticipant(fPin: String(arrayMessage[1]))
                                }
                            }
                        })
                    }
                }
            }
//            if state == Nexilis.AUDIO_CALL_RINGING {
//                if users.count == 1 {
//                    DispatchQueue.main.async {
//                        self.status.text = "Ringing..."
//                    }
//                }
//            } else if state == Nexilis.AUDIO_CALL_OFFHOOK {
//                if users.count == 1 && firstCall {
//                    DispatchQueue.main.async {
//                        self.ongoingView()
//                        let connectDate = Date()
//                        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//                            let format = Utils.callDurationFormatter.string(from: Date().timeIntervalSince(connectDate))
//                            self.status.text = format
//                        }
//                        self.timer?.fire()
//                        self.firstCall = false
//                    }
//                }
//                if (!isOutgoing || !firstCall), users.count >= 1, let user = User.getData(pin: String(arrayMessage[1])), !users.contains(user) {
//                    self.users.append(user)
//                    if !onGoingCC.isEmpty {
//                        DispatchQueue.main.async {
//                            var members = ""
//                            for user in self.users {
//                                if members.isEmpty {
//                                    members = "\(user.pin)"
//                                } else {
//                                    members = ",\(user.pin)"
//                                }
//                            }
//                            SecureUserDefaults.shared.set("\(members)", forKey: "membersCC")
//                        }
//                    }
//                }
//            } else if state == Nexilis.AUDIO_CALL_END {
//                if let pin = arrayMessage.first, let index = users.firstIndex(of: User(pin: String(pin))) {
//                    users.remove(at: index)
//                    if !onGoingCC.isEmpty && users.count != 0 {
//                        let requester = onGoingCC.components(separatedBy: ",")[0]
//                        let officer = onGoingCC.components(separatedBy: ",")[1]
//                        if pin == requester || pin == officer {
//                            DispatchQueue.main.async {
//                                self.timer?.invalidate()
//                                self.timer = nil
//                                self.status.text = "Call Center Session has ended..."
//                                self.end.isEnabled = false
//                            }
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                                self.didEnd(sender: nil)
//                            }
//                            return
//                        }
//                    } else if !onGoingCC.isEmpty  && users.count == 0 {
//                        DispatchQueue.main.async {
//                            self.timer?.invalidate()
//                            self.timer = nil
//                            self.status.text = "Call Center Session has ended..."
//                            self.end.isEnabled = false
//                        }
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                            self.didEnd(sender: true)
//                        }
//                        return
//                    }
//                }
//                if users.count == 0 {
//                    DispatchQueue.main.async {
//                        self.dismiss(animated: false, completion: nil)
//                    }
//                }
//            } else if state == Nexilis.OFFLINE { // Offline
//                if let pin = arrayMessage.first, let index = users.firstIndex(of: User(pin: String(pin))) {
//                    users.remove(at: index)
//                    if !onGoingCC.isEmpty && users.count != 0 {
//                        DispatchQueue.main.async {
//                            var members = ""
//                            for user in self.users {
//                                if members.isEmpty {
//                                    members = "\(user.pin)"
//                                } else {
//                                    members = ",\(user.pin)"
//                                }
//                            }
//                            SecureUserDefaults.shared.set("\(members)", forKey: "membersCC")
//                        }
//                    }
//                }
//                if users.count == 0 {
//                    DispatchQueue.main.async {
//                        self.status.text = "Offline..."
//                        self.end.isEnabled = false
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                            self.didEnd(sender: nil)
//                        }
//                    }
//                }
//            } else if state == Nexilis.BUSY { // Busy
//                if let pin = arrayMessage.first, let index = users.firstIndex(of: User(pin: String(pin))) {
//                    users.remove(at: index)
//                    if !onGoingCC.isEmpty && users.count != 0 {
//                        DispatchQueue.main.async {
//                            var members = ""
//                            for user in self.users {
//                                if members.isEmpty {
//                                    members = "\(user.pin)"
//                                } else {
//                                    members = ",\(user.pin)"
//                                }
//                            }
//                            SecureUserDefaults.shared.set("\(members)", forKey: "membersCC")
//                        }
//                    }
//                }
//                if users.count == 0 {
//                    DispatchQueue.main.async {
//                        self.status.text = "Busy..."
//                        self.end.isEnabled = false
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                            self.didEnd(sender: nil)
//                        }
//                    }
//                }
//            }
        }
    }

}
