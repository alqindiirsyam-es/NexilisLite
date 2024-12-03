//
//  SeminarViewController.swift
//  NexilisLite
//
//  Created by Maronakins on 01/06/23.
//

import UIKit
import nuSDKService

class SeminarViewController: UIViewController {
    
    var data: String = ""
    
    var streamingData: [String: Any] = [:]
    
    var isLive: Bool = false
    
    private var textViewHeightConstraint: NSLayoutConstraint!
    
    private let keyboardLayoutGuide = UILayoutGuide()
    
    private var keyboardTopAnchorConstraint: NSLayoutConstraint!
    
    private let cellIdentifier = "reuseCell"
    
    private var frontCamera = true
    
    private var hasRaiseHand = false
    
    private var mIsSwitch = false
    
    private var currentSpeakingBC = "-666"
    
    private var currentSpeakingVW = "-666"
    
    private var secondViewHeight = 0.0
    
    private var secondViewWidth = 0.0
    
    private var heightTableView: NSLayoutConstraint?
    
    var wbVC : WhiteboardViewController?
    
    private var viewers: [SeminarViewer] = []
    
    private var chats: [SeminarChat] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if self.tableView.contentSize.height <= 167.0 {
                    self.heightTableView?.constant = self.tableView.contentSize.height
                } else {
                    self.heightTableView?.constant = 167.0
                }
                self.tableView.scrollToBottom()
            }
        }
    }
    
    private var isOversized: Bool = false {
        didSet {
            guard oldValue != isOversized else {
                return
            }
            if isOversized {
                textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: textView.frame.height)
                NSLayoutConstraint.activate([textViewHeightConstraint])
            } else {
                NSLayoutConstraint.deactivate([textViewHeightConstraint])
            }
            textView.isScrollEnabled = isOversized
            textView.setNeedsUpdateConstraints()
        }
    }
    
    var statusView = UIView()
    var viewCountViewer = UIView()
    
    lazy var status: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .mainColor
        label.textAlignment = .center
        label.text = streamingData["title"] as? String
        return label
    }()
    
    lazy var tvCameraPreviewB: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        return imageView
    }()
    
    lazy var tvCameraPreviewS: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        return imageView
    }()
    
    lazy var ivRemoteViewS: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        return imageView
    }()
    
    lazy var ivRemoteViewM: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        return imageView
    }()
    
    var tvBRotation = 0.0
    var tvSRotation = 0.0
    var ivSRotation = 0.0
    var ivMRotation = 0.0
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.separatorInset = .zero
        tableView.tintColor = .clear
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor.white.cgColor
        textView.layer.backgroundColor = UIColor.clear.cgColor
        textView.isScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.text = "Send Comment".localized()
        textView.textColor = UIColor.secondaryColor
        return textView
    }()
    
    lazy var send: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Send-(White)", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.backgroundColor = .mainColor
        button.addTarget(self, action: #selector(sent(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var raiseHandBtn: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x:0, y:0, width:40, height:40)
        button.setImage(UIImage(named: "pb_raise_hand", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.cornerRadius = button.maxCornerRadius()
        button.backgroundColor = .mainColor
        button.addTarget(self, action: #selector(raiseHand(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var screenShareBtn: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x:0, y:0, width:40, height:40)
        button.setImage(UIImage(named: "pb_screen_share", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.cornerRadius = button.maxCornerRadius()
        button.backgroundColor = .mainColor
        button.addTarget(self, action: #selector(screenShare(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var whiteboardBtn: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x:0, y:0, width:40, height:40)
        button.setImage(UIImage(named: "pb_od_draw", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.cornerRadius = button.maxCornerRadius()
        button.backgroundColor = .mainColor
        button.addTarget(self, action: #selector(whiteboard(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var buttonRotate: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x:0, y:0, width:40, height:40)
        button.setImage(UIImage(named: "pb_ic_camera_rear", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.cornerRadius = button.maxCornerRadius()
        button.backgroundColor = .mainColor
        button.addTarget(self, action: #selector(camera(sender:)), for: .touchUpInside)
        return button
    }()
    
    // TODO: badges when raise hand to broadcaster
    lazy var handNotif: UIView = {
        let view = UIView()
        view.frame = CGRect(x:0, y:0, width:10, height:10)
        view.backgroundColor = hasRaiseHand ? .systemRed : .white.withAlphaComponent(0)
        view.layer.cornerRadius = view.maxCornerRadius()
        return view
    }()
    
    lazy var stack: UIView = {
        let stack = UIView()
        return stack
    }()
    
    lazy var count: UILabel = {
        let count = UILabel()
        count.text = "0"
        count.font = UIFont.systemFont(ofSize: 14)
        count.textColor = .mainColor
        return count
    }()
    
    lazy var countViewer: UILabel = {
        let count = UILabel()
        count.text = "0"
        count.font = UIFont.systemFont(ofSize: 14)
        count.textColor = .mainColor
        return count
    }()
    
    lazy var toolbarView : UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 10 // Adjust the spacing between buttons
        
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.changeAppearance(clear: true)
        
        let screenBounds = UIScreen.main.bounds

        let screenWidth = screenBounds.width
        let screenHeight = screenBounds.height
        
        secondViewWidth = screenWidth / 3.0
        secondViewHeight = screenHeight / 3.0
        
        let buttonBack = UIButton()
        buttonBack.frame = CGRect(x:0, y:0, width:30, height:30)
        buttonBack.setImage(UIImage(systemName: "chevron.backward")?.withTintColor(.mainColor, renderingMode: .alwaysOriginal), for: .normal)
        buttonBack.backgroundColor = .white.withAlphaComponent(0.2)
        buttonBack.layer.cornerRadius = 15.0
        buttonBack.addTarget(self, action: #selector(close(sender:)), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: buttonBack)
        
        
        view.backgroundColor = .clear
        if isLive {
            view.addSubview(tvCameraPreviewB)
            view.addSubview(ivRemoteViewS)
            addCountViewerView()
            tvCameraPreviewB.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
        }
        else {
            view.addSubview(tvCameraPreviewS)
            view.addSubview(ivRemoteViewM)
            view.addSubview(ivRemoteViewS)
            ivRemoteViewM.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
        }
        view.addSubview(statusView)
        statusView.backgroundColor = .white.withAlphaComponent(0.2)
        statusView.layer.cornerRadius = 8.0
        statusView.layer.masksToBounds = true
        statusView.addSubview(status)
        status.anchor(left: statusView.leftAnchor, right: statusView.rightAnchor, paddingLeft: 10, paddingRight: 10, centerX: statusView.centerXAnchor, centerY: statusView.centerYAnchor)
        statusView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 30, paddingLeft: 80, paddingRight: 80, centerX: view.centerXAnchor, height: 30, dynamicLeft: true, dynamicRight: true)
        view.addSubview(stack)
        view.addLayoutGuide(keyboardLayoutGuide)
        keyboardTopAnchorConstraint = view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: 0)
        keyboardTopAnchorConstraint.isActive = true
        keyboardLayoutGuide.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
        stack.anchor(left: view.leftAnchor, bottom: keyboardLayoutGuide.topAnchor,
                     right: view.rightAnchor, paddingLeft: 20, paddingBottom: 30, paddingRight: 20, height: 200)
        
        addToolbarView()
        
        stack.addSubview(tableView)
        stack.addSubview(textView)
        stack.addSubview(send)
        
        send.layer.cornerRadius = 16
        send.layer.masksToBounds = true
        
        textView.anchor(left: stack.leftAnchor, bottom: stack.bottomAnchor, right: stack.rightAnchor)
        send.anchor(bottom: textView.bottomAnchor, right: textView.rightAnchor, paddingBottom: 1, width: 32, height: 32)
        tableView.anchor(left: stack.leftAnchor, bottom: textView.topAnchor, right: stack.rightAnchor)
        heightTableView = tableView.heightAnchor.constraint(equalToConstant: 44.0)
        heightTableView?.isActive = true
        textView.layoutIfNeeded()
        
        textView.layer.cornerRadius = textView.frame.height / 2
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: textView.frame.height + 8)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        Nexilis.shared.seminarDelegate = self
        if isLive {
            API.ibca(sTitle: data, nCamIdx: 1, nResIdx: 2, nVQuality: 4, tvCameraPreview: tvCameraPreviewB, ivRemoteS: ivRemoteViewS)
        } else {
            API.iabc(nCamIdx: 1, nResIdx: 2, nVQuality: 4, tvCameraPreview: tvCameraPreviewS, sBroadcasterID: data, ivRemoteM: ivRemoteViewM, ivRemoteS: ivRemoteViewS)
        }
    }

    func addToolbarView(){
        if isLive {
            buttonRotate.widthAnchor.constraint(equalToConstant: 40).isActive = true
            buttonRotate.heightAnchor.constraint(equalToConstant: 40).isActive = true
            toolbarView.insertArrangedSubview(buttonRotate, at: 0)
        }
        else {
            raiseHandBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
            raiseHandBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
            toolbarView.insertArrangedSubview(raiseHandBtn, at: 0)
        }
        whiteboardBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
        whiteboardBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        screenShareBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
        screenShareBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        toolbarView.addArrangedSubview(whiteboardBtn)
        toolbarView.addArrangedSubview(screenShareBtn)
        
        // Add the stack view to the view controller's view
        view.addSubview(toolbarView)
        
        // Set constraints for the stack view
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            toolbarView.heightAnchor.constraint(equalToConstant: 140),
            toolbarView.widthAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    func switchRaiseHand(raiseHand: Bool){
        if hasRaiseHand {
            raiseHandBtn.removeFromSuperview()
            buttonRotate.widthAnchor.constraint(equalToConstant: 40).isActive = true
            buttonRotate.heightAnchor.constraint(equalToConstant: 40).isActive = true
            toolbarView.insertArrangedSubview(buttonRotate, at: 0)
        }
        else {
            buttonRotate.removeFromSuperview()
            raiseHandBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
            raiseHandBtn.heightAnchor.constraint(equalToConstant: 40).isActive = true
            toolbarView.insertArrangedSubview(raiseHandBtn, at: 0)
        }
    }
    
    func addCountViewerView() {
        view.addSubview(viewCountViewer)
        viewCountViewer.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingLeft: 20, height: 40)
        viewCountViewer.backgroundColor = .white.withAlphaComponent(0.2)
        viewCountViewer.layer.cornerRadius = 8.0
        viewCountViewer.layer.masksToBounds = true
        
        let imageEye = UIImageView()
        viewCountViewer.addSubview(imageEye)
        imageEye.anchor(left: viewCountViewer.leftAnchor, paddingLeft: 5.0, centerY: viewCountViewer.centerYAnchor)
        imageEye.image = UIImage(systemName: "eye.fill")?.withTintColor(.black, renderingMode: .alwaysOriginal)
        
        viewCountViewer.addSubview(countViewer)
        countViewer.anchor(left: imageEye.rightAnchor, right:viewCountViewer.rightAnchor, paddingLeft: 5.0, paddingRight: 5.0, centerY: viewCountViewer.centerYAnchor)
        viewCountViewer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showListViewer(sender:))))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.changeAppearance(clear: false)
    }
    
    @objc func close(sender: Any?) {
        hideKeyboard()
        var alert = LibAlertController(title: "", message: "Are you sure you want to end Seminar?".localized(), preferredStyle: .alert)
        if !isLive {
            alert = LibAlertController(title: "", message: "Are you sure you want to leave Seminar?".localized(), preferredStyle: .alert)
        }
        alert.addAction(UIAlertAction(title: "No".localized(), style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes".localized(), style: UIAlertAction.Style.default, handler: {[weak self] _ in
            DispatchQueue.global().async {
                API.terminateBC(sBroadcasterID: self?.isLive ?? true ? nil : self?.data)
                self?.sendLeft()
            }
            self?.navigationController?.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func camera(sender: Any?) {
        if frontCamera {
            API.changeCameraParam(nCameraIdx: 0, nResolutionIndex: 2, nQuality: 4)
            frontCamera = false
        } else {
            API.changeCameraParam(nCameraIdx: 1, nResolutionIndex: 2, nQuality: 4)
            frontCamera = true
        }
    }
    
    @objc func sent(sender: Any?) {
        if textView.textColor == UIColor.secondaryColor {
            return
        }
        guard let text = textView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        guard let me = User.getDataCanNil(pin: User.getMyPin()) else {
            return
        }
        chats.append(SeminarChat(name: "You".localized(), thumb: me.thumb, messageText: text.trimmingCharacters(in: .whitespacesAndNewlines)))
        if textViewHeightConstraint != nil {
            NSLayoutConstraint.deactivate([textViewHeightConstraint])
        }
        textView.isScrollEnabled = false
        textView.setNeedsUpdateConstraints()
        DispatchQueue.global().async {
            self.sendChat(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        textView.text = ""
    }
    
    @objc func screenShare(sender: Any?) {
        // TODO: implement screen sharing
        
    }
    
    @objc func whiteboard(sender: Any?) {
        // TODO: implement whiteboard
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getSeminarDraw(broadcaster: data, flag: "1"))
        
        
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    var isShow: Bool = false
    
    @objc func keyboardWillShow(notification: Notification) {
        if !isShow {
            isShow = true
            keyboard(notification: notification, show: true)
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        isShow = false
        keyboard(notification: notification, show: false)
    }
    
    private func keyboard(notification: Notification, show: Bool) {
        let keyboardFrameEnd = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let animationDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        let rawAnimationCurve = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uint32Value
        guard let animDuration = animationDuration,
              let keyboardFrame = keyboardFrameEnd,
              let rawAnimCurve = rawAnimationCurve else {
            return
        }
        keyboardTopAnchorConstraint.constant = show ? keyboardFrame.cgRectValue.height : 0
        view.setNeedsLayout()
        let rawAnimCurveAdjusted = UInt(rawAnimCurve << 16)
        let animationCurve = UIView.AnimationOptions(rawValue: rawAnimCurveAdjusted)
        UIView.animate(withDuration: animDuration, delay: 0.0, options: [.beginFromCurrentState, animationCurve], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func sendLive() {
        guard let title = streamingData["title"] as? String else {
            return
        }
        guard let type = streamingData["type"] as? String else {
            return
        }
        guard let blog = streamingData["blog"] as? String else {
            return
        }
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getStartSeminarInvited(title: "1~\(title)", type: type, typeValue: "", category: "3", blog_id: blog))
    }
    
    private func sendJoin() {
        let id = Date().currentTimeMillis().toHex()
        _ = Nexilis.write(message: CoreMessage_TMessageBank.joinSeminar(broadcast_id: data, request_id: id))
    }
    
    public func sendLeft() {
        let id = Date().currentTimeMillis().toHex()
        _ = Nexilis.write(message: CoreMessage_TMessageBank.leftSeminar(broadcast_id: data, request_id: id))
    }
    
    private func sendChat(text: String) {
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getSendSeminarChat(l_pin: data, message_text: text))
    }
    
    @objc func raiseHand(sender: Any?) {
        guard let me = User.getDataCanNil(pin: User.getMyPin()) else {
            return
        }
        let status = hasRaiseHand ? "0" : "1"
        hasRaiseHand = !hasRaiseHand
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getSeminarRaiseHand(p_pin: me.pin, l_pin: data, status: status))
    }

    @objc func showListViewer(sender: Any?){
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "seminarListNav") as! UINavigationController
        Utils.addBackground(view: controller.view)
        if let vc = controller.viewControllers.first as? SeminarListViewController {
            vc.data = viewers
            vc.makeSpeaker = { viewer in
                API.sabc(sAudienceID: viewer.f_pin)
                self.viewers.first(where: {$0.f_pin == viewer.f_pin})?.isRaise = false
                self.viewers.first(where: {$0.f_pin == viewer.f_pin})?.isSpeak = true
            }
            vc.removeSpeaker = { viewer in
                API.eabc(sAudienceID: viewer.f_pin)
                self.viewers.first(where: {$0.f_pin == viewer.f_pin})?.isSpeak = false
            }
        }
        self.navigationController?.present(controller, animated: true, completion: nil)
    }
    
    func switchBroadcaster() {
        if isLive {
            if(currentSpeakingBC == "-666") {
                // toast return
                return
            }
            mIsSwitch = !mIsSwitch
            if mIsSwitch {
                adjust(viewOnFront: tvCameraPreviewB, viewOnBack: ivRemoteViewS)
            } else {
                adjust(viewOnFront: ivRemoteViewS, viewOnBack: tvCameraPreviewB)
            }
        } else {
            if(currentSpeakingVW == "-666") {
                // toast return
                return
            }
            mIsSwitch = !mIsSwitch
            let me = User.getMyPin()
            if currentSpeakingVW == me {
                if mIsSwitch {
                    adjust(viewOnFront: ivRemoteViewM, viewOnBack: tvCameraPreviewS)
                }
                else {
                    adjust(viewOnFront: tvCameraPreviewS, viewOnBack: ivRemoteViewM)
                }
            }
            else {
                if mIsSwitch {
                    adjust(viewOnFront: ivRemoteViewM, viewOnBack: ivRemoteViewS)
                }
                else {
                    adjust(viewOnFront: ivRemoteViewS, viewOnBack: ivRemoteViewM)
                }
            }
        }
    }
    
    func forceRevertSwitch() {
        if isLive {
            adjust(viewOnFront: ivRemoteViewS, viewOnBack: tvCameraPreviewB)
            mIsSwitch = false
        } else {
            let me = User.getMyPin()
            if currentSpeakingVW == me {
                adjust(viewOnFront: tvCameraPreviewS, viewOnBack: ivRemoteViewS)
            } else {
                adjust(viewOnFront: ivRemoteViewS, viewOnBack: ivRemoteViewM)
            }
            mIsSwitch = false
        }
    }
    
    func adjust(viewOnFront: UIImageView, viewOnBack: UIImageView) {
        viewOnFront.removeConstraints(viewOnFront.constraints)
        viewOnBack.removeConstraints(viewOnBack.constraints)
        viewOnFront.anchor(bottom: view.bottomAnchor, right: view.rightAnchor, paddingBottom: 70.0, width: secondViewWidth, height: secondViewHeight)
        viewOnBack.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
        btf()
        view.bringSubviewToFront(viewOnFront)
    }
    
    func btf() {
        view.bringSubviewToFront(stack)
        view.bringSubviewToFront(statusView)
        view.bringSubviewToFront(toolbarView)
        if isLive {
            view.bringSubviewToFront(viewCountViewer)
        }
    }
    
}

extension SeminarViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        isOversized = textView.contentSize.height >= 100
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.secondaryColor {
            textView.text = nil
            textView.textColor = .white
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Send Comment".localized()
            textView.textColor = UIColor.secondaryColor
        }
    }
    
}

extension SeminarViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.tintColor = .clear
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        let chat = chats[indexPath.row]
        let content = cell.contentView
        content.subviews.forEach({ $0.removeFromSuperview() })
        let viewContent = UIView()
        content.addSubview(viewContent)
        viewContent.anchor(top: content.topAnchor, left: content.leftAnchor, bottom: content.bottomAnchor, right: content.rightAnchor)
        viewContent.backgroundColor = .clear
        if !chat.isInfo {
            let image = UIImageView()
            viewContent.addSubview(image)
            image.anchor(top: viewContent.topAnchor, left: viewContent.leftAnchor, width: 30, height: 30)
            if !chat.thumb.isEmpty {
                getImage(name: chat.thumb, placeholderImage: UIImage(systemName: "person.circle.fill")!, isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, imagePerson in
                    image.image = imagePerson
                })
            } else {
                image.image = UIImage(systemName: "person.circle.fill")!
                image.tintColor = .lightGray
            }
            let name = UILabel()
            viewContent.addSubview(name)
            name.anchor(top: viewContent.topAnchor, left: image.rightAnchor, paddingLeft: 3.0)
            name.numberOfLines = 1
            name.text = chat.name
            name.font = UIFont.boldSystemFont(ofSize: 14)
            name.textColor = .secondaryColor
            let message = UILabel()
            viewContent.addSubview(message)
            message.anchor(top: name.bottomAnchor, left: image.rightAnchor, bottom: content.bottomAnchor, right:viewContent.rightAnchor, paddingLeft: 3.0, paddingBottom: 5.0)
            message.numberOfLines = 0
            message.text = chat.messageText
            message.font = UIFont.systemFont(ofSize: 14)
            message.textColor = .white
        } else {
            let image = UIImageView()
            viewContent.addSubview(image)
            image.anchor(left: viewContent.leftAnchor, centerY: viewContent.centerYAnchor, width: 30, height: 30)
            if !chat.thumb.isEmpty {
                getImage(name: chat.thumb, placeholderImage: UIImage(systemName: "person.circle.fill")!, isCircle: true, tableView: tableView, indexPath: indexPath, completion: { result, isDownloaded, imagePerson in
                    image.image = imagePerson
                })
            } else {
                image.image = UIImage(systemName: "person.circle.fill")!
                image.tintColor = .lightGray
            }
            let name = UILabel()
            viewContent.addSubview(name)
            name.anchor(left: image.rightAnchor, paddingLeft: 3.0, centerY: viewContent.centerYAnchor)
            name.numberOfLines = 1
            name.text = chat.name
            name.font = UIFont.italicSystemFont(ofSize: 14)
            name.textColor = .secondaryColor
            let message = UILabel()
            viewContent.addSubview(message)
            message.anchor(left: name.rightAnchor, paddingLeft: 3.0, centerY: viewContent.centerYAnchor)
            message.numberOfLines = 0
            message.text = chat.messageText
            message.font = UIFont.italicSystemFont(ofSize: 14)
            message.textColor = .white
        }
        return cell
    }
    
}

extension SeminarViewController: SeminarDelegate {
    
    func onStartSeminar(state: Int, message: String) {
        if state == Nexilis.OUTGOING_CALL, message.contains("Initiating") {
            DispatchQueue.main.async {
                self.tvCameraPreviewB.transform = CGAffineTransform.init(scaleX: 1.6, y: 1.6)
            }
        } else if state == 12 {
            sendLive()
        }
    }
    
    func onJoinSeminar(state: Int, message: String) {
        if state == Nexilis.AUDIO_CALL_OFFHOOK {
            let m = message.split(separator: ",")
            let _ = String(m[0])
            let _ = String(m[1])
            let camera = Int(m[2])
            let platform = Int(m[3])
            if platform == 1 { // Android
                DispatchQueue.main.async {
                    self.ivRemoteViewM.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: camera == 1 ? (CGFloat.pi * 3)/2 : (CGFloat.pi)/2)
                }
            } else {
                DispatchQueue.main.async {
                    self.ivRemoteViewM.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: camera == 1 ? (CGFloat.pi * 5)/2 : (CGFloat.pi)/2)
                }
            }
            sendJoin()
        } else if state == Nexilis.AUDIO_CALL_RINGING {
            let m = message.split(separator: ",")
            let _ = String(m[0])
            let _ = String(m[1])
            let camera = Int(m[2])
            let platform = Int(m[3])
            if platform == 1 { // Android
                DispatchQueue.main.async {
                    self.ivRemoteViewM.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: camera == 1 ? (CGFloat.pi * 3)/2 : (CGFloat.pi)/2)
                }
            } else {
                DispatchQueue.main.async {
                    self.ivRemoteViewM.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: camera == 1 ? (CGFloat.pi * 5)/2 : (CGFloat.pi)/2)
                }
            }
        } else if state == Nexilis.VIDEO_CALL_OFFHOOK { // initBCA (3* is from Broadcaster PoV)
            DispatchQueue.main.async {
                self.tvCameraPreviewB.removeConstraints(self.tvCameraPreviewB.constraints)
                self.tvCameraPreviewB.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor)
                self.view.bringSubviewToFront(self.tvCameraPreviewB)
                self.btf()
            }
        } else if state == Nexilis.VIDEO_CALL_RINGING { // startAudience (3* is from Broadcaster PoV)
            let m = message.split(separator: ",")
            let f_pin = m[0]
            let camera = Int(m[1])
            DispatchQueue.main.async {
                let rotation = camera == 1 ? CGFloat.pi * 2.5 : CGFloat.pi * 0.5
                self.ivRemoteViewS.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: rotation)
                self.ivSRotation = rotation
            }
            if currentSpeakingBC != "-666" {
                viewers.first(where: {$0.f_pin == currentSpeakingBC})?.isRaise = false
                viewers.first(where: {$0.f_pin == currentSpeakingBC})?.isSpeak = false
            }
            if currentSpeakingBC != f_pin {
                DispatchQueue.main.async {
                    self.forceRevertSwitch()
                }
            }
            viewers.first(where: {$0.f_pin == currentSpeakingBC})?.isRaise = false
            viewers.first(where: {$0.f_pin == currentSpeakingBC})?.isSpeak = true
            // TODO: remove badge if no raise hand
            
        } else if state == Nexilis.VIDEO_CAMERA_PARAMS_CHANED { // endAudience (3* is from Broadcaster PoV)
            let m = message.split(separator: ",")
            let f_pin = m[0]
            if currentSpeakingBC == f_pin {
                DispatchQueue.main.async {
                    self.forceRevertSwitch()
                }
                currentSpeakingBC = "-666"
            }
            DispatchQueue.main.async {
                let rotation = -(self.ivSRotation)
                self.ivRemoteViewS.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: rotation)
                self.ivSRotation = 0
            }
            viewers.first(where: {$0.f_pin == f_pin})?.isRaise = false
            viewers.first(where: {$0.f_pin == f_pin})?.isSpeak = false
        } else if state == Nexilis.VIDEO_CALL_MUTE_UNMUTE || state == 46 { // audience change camera (3* is from Broadcaster PoV)
            let m = message.split(separator: ",")
            let camera = Int(m[2])
            let rotation = camera == 1 ? CGFloat.pi * 2.5 : CGFloat.pi * 0.5
            let scaleY = camera == 1 ? -1.0 : 1.0
            DispatchQueue.main.async {
                self.ivRemoteViewS.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9 * scaleY).rotated(by: rotation - self.ivSRotation)
                self.ivSRotation = rotation
            }
        } else if state == 42 { // joinBC (4* is from Audience PoV)
            let m = message.split(separator: ",")
            let camera = Int(m[2])
            var x = "NONE"
            if m.indices.contains(5){
                x = String(m[5])
            }
            let rotation = camera == 1 ? CGFloat.pi * 2.5 : CGFloat.pi * 0.5
            let rotation2 = -(self.ivSRotation)
            DispatchQueue.main.async {
               self.ivRemoteViewM.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: rotation - self.ivMRotation)
               self.ivMRotation = rotation
               self.ivRemoteViewM.removeConstraints(self.ivRemoteViewM.constraints)
               self.ivRemoteViewM.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor)
               self.view.bringSubviewToFront(self.ivRemoteViewM)
               self.ivRemoteViewS.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: rotation2)
               self.ivSRotation = 0
               if x != "NONE" {
                   let camera2 = Int(m[6])
                   let rotation3 = camera2 == 1 ? CGFloat.pi * 2.5 : CGFloat.pi * 0.5
                   let scaleY = camera2 == 1 ? -1.0 : 1.0
                   self.ivRemoteViewS.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9 * scaleY).rotated(by: rotation3 - self.ivSRotation)
                   self.ivSRotation = rotation3
                   self.view.bringSubviewToFront(self.ivRemoteViewS)
               }
               self.btf()
            }
            sendJoin()
        } else if state == 43 { // startAudience (4* is from Audience PoV)
            let m = message.split(separator: ",")
            let f_pin = String(m[0])
            let me = User.getMyPin()
            DispatchQueue.main.async {
                self.tvCameraPreviewS.removeConstraints(self.tvCameraPreviewS.constraints)
                self.tvCameraPreviewS.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor)
                self.currentSpeakingVW = f_pin
                
                if self.currentSpeakingVW == me {
                    self.hasRaiseHand = false
                    self.switchRaiseHand(raiseHand: false)
                }
                else {
                    self.switchRaiseHand(raiseHand: true)
                }
                // TODO: set whiteboard can draw here
            }
        } else if state == 44 { // endAudience (4* is from Audience PoV)
            let m = message.split(separator: ",")
            let f_pin = String(m[0])
            let camera = Int(m[1])
            let rotation = camera == 1 ? CGFloat.pi * 2.5 : CGFloat.pi * 0.5
            let scaleY = camera == 1 ? -1.0 : 1.0
            let rotation2 = -(self.ivSRotation)
            if f_pin != "NONE" {
                DispatchQueue.main.async {
                    if self.mIsSwitch {
                        self.forceRevertSwitch()
                    }
                    self.currentSpeakingVW = f_pin
                    self.ivRemoteViewS.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9 * scaleY).rotated(by: rotation - self.ivSRotation)
                    self.ivSRotation = rotation
                    self.view.bringSubviewToFront(self.ivRemoteViewS)
                }
            } else {
                DispatchQueue.main.async {
                    if self.mIsSwitch {
                        self.forceRevertSwitch()
                    }
                    let me = User.getMyPin()
                    if me == f_pin {
                        self.currentSpeakingVW = "-666"
                    }
                    self.ivRemoteViewS.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: rotation2)
                    self.ivSRotation = 0
                    
                    self.hasRaiseHand = false
                    self.switchRaiseHand(raiseHand: true)
                    // TODO: set whiteboard can draw here
                }
            }
        } else if state == 45 { // CCPb Br.ID Br.Title Br.CameraID Br.OS :  (4* is from Audience PoV) broadcaster change camera
            let m = message.split(separator: ",")
            let camera = Int(m[2])
            let rotation = camera == 1 ? CGFloat.pi * 2.5 : CGFloat.pi * 0.5
            DispatchQueue.main.async {
                self.ivRemoteViewM.transform = CGAffineTransform.init(scaleX: 1.9, y: 1.9).rotated(by: rotation - self.ivMRotation)
                self.ivMRotation = rotation
            }
        } else if state == Nexilis.STREAMING_SEMINAR_ENDED {
            DispatchQueue.main.async {
                self.status.text = "Seminar ended".localized()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.navigationController?.dismiss(animated: true, completion: nil)
            })
        } else if state == 95 { // chat
            let m = message.split(separator: ",", omittingEmptySubsequences: false)
            let name = m[3].trimmingCharacters(in: .whitespaces)
            let thumb = m[2].trimmingCharacters(in: .whitespaces)
            let text = m[4].trimmingCharacters(in: .whitespaces)
            chats.append(SeminarChat(name: name, thumb: thumb, messageText: text))
        } else if state == 96 { // raise hand
            let m = message.split(separator: ",", omittingEmptySubsequences: false)
            let f_pin = m[0].trimmingCharacters(in: .whitespaces)
            let broadcaster = m[1].trimmingCharacters(in: .whitespaces)
            let status = m[2].trimmingCharacters(in: .whitespaces)
            guard broadcaster == data else {
                return
            }
            if(status == "1"){
                hasRaiseHand = true
                viewers.first(where: { $0.f_pin == f_pin })?.isRaise = true
                // TODO: edit badges
            }
            else {
                viewers.first(where: { $0.f_pin == f_pin })?.isRaise = false
                if viewers.filter({ $0.isRaise }).count == 0 {
                    hasRaiseHand = false
                    // TODO: edit badges
                }
            }
        } else if state == 97 { // someone left
            let m = message.split(separator: ",", omittingEmptySubsequences: false)
            let name = m[3].trimmingCharacters(in: .whitespaces)
            let thumb = m[2].trimmingCharacters(in: .whitespaces)
            let f_pin = m[1].trimmingCharacters(in: .whitespaces)
            let text = "Left".localized()
            viewers.removeAll{ $0.f_pin == f_pin }
            chats.append(SeminarChat(name: name, thumb: thumb, messageText: text, isInfo: true))
            DispatchQueue.main.async {
                self.countViewer.text = "\(Int(self.countViewer.text!)! - 1)"
            }
        } else if state == 98 { // someone join
            let m = message.split(separator: ",", omittingEmptySubsequences: false)
            let name = m[3].trimmingCharacters(in: .whitespaces)
            let thumb = m[2].trimmingCharacters(in: .whitespaces)
            let text = "Joined".localized()
            let f_pin = m[1].trimmingCharacters(in: .whitespaces)
            viewers.append(SeminarViewer(f_pin: f_pin, thumb: thumb, name: name))
            chats.append(SeminarChat(name: name, thumb: thumb, messageText: text, isInfo: true))
            DispatchQueue.main.async {
                self.countViewer.text = "\(Int(self.countViewer.text!)! + 1)"
            }
        }
    }
    
}

class SeminarChat: Model {
    
    let name: String
    let thumb: String
    let messageText: String
    let isInfo: Bool
    
    init(viewer: SeminarViewer, messageText: String, isInfo: Bool = false) {
        self.name = viewer.name
        self.thumb = viewer.thumb
        self.messageText = messageText
        self.isInfo = isInfo
    }
    
    init(name: String, thumb: String, messageText: String, isInfo: Bool = false) {
        self.name = name
        self.thumb = thumb
        self.messageText = messageText
        self.isInfo = isInfo
    }
    
    static func == (lhs: SeminarChat, rhs: SeminarChat) -> Bool {
        return false
    }
    
    var description: String {
        return ""
    }
    
}

class SeminarViewer : Model {
    
    let f_pin: String
    let thumb: String
    let name: String
    var isRaise: Bool
    var isSpeak: Bool
    
    init(f_pin: String, thumb: String, name: String, isRaise: Bool = false, isSpeak: Bool = false){
        self.f_pin = f_pin
        self.thumb = thumb
        self.name = name
        self.isRaise = isRaise
        self.isSpeak = isSpeak
    }
    
    var description: String {
        return ""
    }
    
    static func == (lhs: SeminarViewer, rhs: SeminarViewer) -> Bool {
        lhs.f_pin == rhs.f_pin
    }
    
    
}
