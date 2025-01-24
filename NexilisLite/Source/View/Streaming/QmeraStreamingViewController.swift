//
//  QmeraStreamingViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 19/10/21.
//

import UIKit
import nuSDKService
import NotificationBannerSwift

class QmeraStreamingViewController: UIViewController {
    
    var data: String = ""
    
    var streamingData: [String: Any] = [:]
    
    var isLive: Bool = false
    
    private var textViewHeightConstraint: NSLayoutConstraint!
    
    private let keyboardLayoutGuide = UILayoutGuide()
    
    private var keyboardTopAnchorConstraint: NSLayoutConstraint!
    
    private let cellIdentifier = "reuseCell"
    
    private var frontCamera = true
    
    private var liked = false
    
    private var heightTableView: NSLayoutConstraint?
    
    private let templateTagline = "Stay Alert, Stay Safe, Keep Clean and don't Panic. #stayhome".localized()
    private var isEmptyTagline = false
    
    private var chats: [StreamingChat] = [] {
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
    
    lazy var status: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .mainColor
        label.textAlignment = .center
        label.text = streamingData["title"] as? String
        return label
    }()
    
    lazy var tagline: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .left
        let taglinetext = (streamingData["tagline"] as? String) ?? ""
        if !taglinetext.isEmpty {
            label.text = taglinetext
        } else {
            isEmptyTagline = true
            label.text = templateTagline
        }
        return label
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
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
    
    lazy var like: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "heart")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.addTarget(self, action: #selector(liked(sender:)), for: .touchUpInside)
        return button
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
    
    var alert: UIAlertController?
    var textFields = [UITextField]()
    let statusView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.changeAppearance(clear: true)
        
        let buttonBack = UIButton()
        buttonBack.frame = CGRect(x:0, y:0, width:30, height:30)
        buttonBack.setImage(UIImage(systemName: "chevron.backward")?.withTintColor(.mainColor, renderingMode: .alwaysOriginal), for: .normal)
        buttonBack.backgroundColor = .white.withAlphaComponent(0.2)
        buttonBack.layer.cornerRadius = 15.0
        buttonBack.addTarget(self, action: #selector(close(sender:)), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: buttonBack)
        
        let taglineView = UIView()
        
        let size = status.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: status.frame.height))
        let width = size.width
        status.frame = CGRect(x: 0, y: 0, width: width + 10, height: 30)
        statusView.frame = CGRect(x: 0, y: 0, width: width + 10, height: 30)
        statusView.backgroundColor = .white.withAlphaComponent(0.2)
        statusView.layer.cornerRadius = 8.0
        statusView.layer.masksToBounds = true
        statusView.addSubview(status)
        if isLive {
            let tapGestureStatus = UITapGestureRecognizer(target: self, action: #selector(changeTitleOrTag(_:)))
            statusView.tag = 0
            statusView.isUserInteractionEnabled = true
            statusView.addGestureRecognizer(tapGestureStatus)
            
            let tapGestureTagline = UITapGestureRecognizer(target: self, action: #selector(changeTitleOrTag(_:)))
            taglineView.tag = 1
            taglineView.addGestureRecognizer(tapGestureTagline)
        }
        
        view.backgroundColor = .clear
        view.addSubview(imageView)
        navigationItem.titleView = statusView
        view.addSubview(taglineView)
        view.addSubview(stack)
        view.addLayoutGuide(keyboardLayoutGuide)
        
        addLikeView()
        if isLive {
            addCountViewerView()
        }
        
        keyboardTopAnchorConstraint = view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: 0)
        keyboardTopAnchorConstraint.isActive = true
        keyboardLayoutGuide.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
        
        imageView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor)
        
        taglineView.backgroundColor = .clear
        taglineView.addSubview(tagline)
        tagline.anchor(left: taglineView.leftAnchor, right: taglineView.rightAnchor, paddingLeft: 20, paddingRight: 20, centerX: taglineView.centerXAnchor, centerY: taglineView.centerYAnchor)
        taglineView.anchor(left: view.leftAnchor, bottom: keyboardLayoutGuide.topAnchor, right: view.rightAnchor, height: 30)
        stack.anchor(left: view.leftAnchor, bottom: keyboardLayoutGuide.topAnchor, right: view.rightAnchor, paddingLeft: 20, paddingBottom: 30, paddingRight: 20, height: 200)
        
        stack.addSubview(tableView)
        stack.addSubview(textView)
        stack.addSubview(send)
        stack.addSubview(like)
        
        send.layer.cornerRadius = 16.5
        send.layer.masksToBounds = true
        
        like.anchor(bottom: stack.bottomAnchor, right: stack.rightAnchor)
        textView.anchor(left: stack.leftAnchor, bottom: stack.bottomAnchor, right: like.leftAnchor, paddingRight: 10)
        send.anchor(bottom: textView.bottomAnchor, right: textView.rightAnchor, paddingBottom: 2, width: 33, height: 33)
        tableView.anchor(left: stack.leftAnchor, bottom: textView.topAnchor, right: stack.rightAnchor)
        heightTableView = tableView.heightAnchor.constraint(equalToConstant: 44.0)
        heightTableView?.isActive = true
        textView.layoutIfNeeded()
        
        like.anchor(width: textView.frame.height, height: textView.frame.height)
        
        textView.layer.cornerRadius = textView.frame.height / 2
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: textView.frame.height + 8)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onUpdateTitleOrTagline(notification:)), name: NSNotification.Name(rawValue: "liveStreamingUpdate"), object: nil)
        
        Nexilis.shared.streamingDelagate = self
        if isLive {
            let buttonRotate = UIButton()
            buttonRotate.frame = CGRect(x:0, y:0, width:30, height:30)
            buttonRotate.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera")?.withTintColor(.mainColor, renderingMode: .alwaysOriginal), for: .normal)
            buttonRotate.backgroundColor = .white.withAlphaComponent(0.2)
            buttonRotate.layer.cornerRadius = 15.0
            buttonRotate.addTarget(self, action: #selector(camera(sender:)), for: .touchUpInside)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonRotate)
            
            API.initiateBC(sTitle: data, nCamIdx: 0, nResIdx: 2, nVQuality: 4, ivLocalView: imageView)
        } else {
            API.joinBC(sBroadcasterID: data, ivRemoteView: imageView)
        }
    }
    
    func addLikeView() {
        let viewLiked = UIView()
        view.addSubview(viewLiked)
        viewLiked.anchor(top: view.safeAreaLayoutGuide.topAnchor, right: view.rightAnchor, paddingRight: 20, height: 40)
        viewLiked.backgroundColor = .white.withAlphaComponent(0.2)
        viewLiked.layer.cornerRadius = 8.0
        viewLiked.layer.masksToBounds = true
        
        let imageLiked = UIImageView()
        viewLiked.addSubview(imageLiked)
        imageLiked.anchor(left: viewLiked.leftAnchor, paddingLeft: 5.0, centerY: viewLiked.centerYAnchor)
        imageLiked.image = UIImage(systemName: "heart.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
        
        viewLiked.addSubview(count)
        count.anchor(left: imageLiked.rightAnchor, right:viewLiked.rightAnchor, paddingLeft: 5.0, paddingRight: 5.0, centerY: viewLiked.centerYAnchor)
        
    }
    
    func addCountViewerView() {
        let viewCountViewer = UIView()
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
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.changeAppearance(clear: false)
    }
    
    @objc func close(sender: Any?) {
        hideKeyboard()
        var alert = LibAlertController(title: "", message: "Are you sure you want to end Live Streaming?".localized(), preferredStyle: .alert)
        if !isLive {
            alert = LibAlertController(title: "", message: "Are you sure you want to leave Live Streaming?".localized(), preferredStyle: .alert)
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
    
    @objc func liked(sender: Any?) {
        guard let me = User.getDataCanNil(pin: User.getMyPin()) else {
            return
        }
        if liked {
            _ = Nexilis.write(message: CoreMessage_TMessageBank.getSendEmotionLP(p_pin: me.pin, l_pin: data, emotion_type: "3"))
            like.setImage(UIImage(systemName: "heart")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        } else {
            _ = Nexilis.write(message: CoreMessage_TMessageBank.getSendEmotionLP(p_pin: me.pin, l_pin: data, emotion_type: "2"))
            like.setImage(UIImage(systemName: "heart.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal), for: .normal)
        }
        liked = !liked
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
        chats.append(StreamingChat(name: "You".localized(), thumb: me.thumb, messageText: text.trimmingCharacters(in: .whitespacesAndNewlines)))
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
    
    @objc func onUpdateTitleOrTagline(notification: Notification) {
        DispatchQueue.main.async { [self] in
            let dataNotification:[AnyHashable : Any] = notification.userInfo!
            if let message = dataNotification["message"] as? TMessage {
                let broadcaster = message.getPIN()
                if broadcaster == data && User.getMyPin() != data {
                    let titleRaw = message.getBody(key: CoreMessage_TMessageKey.TITLE)
                    let tagline = message.getBody(key: CoreMessage_TMessageKey.TAGLINE, default_value: self.tagline.text!)
                    if !titleRaw.isEmpty || !tagline.isEmpty{
                        let titleWithChar = titleRaw.components(separatedBy: "~")[1]
                        let title = titleWithChar.components(separatedBy: "■")[0]
                        
                        self.status.text = title.toNormalString()
                        let size = self.status.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.status.frame.height))
                        let width = size.width
                        self.status.frame = CGRect(x: 0, y: 0, width: width + 10, height: 30)
                        self.statusView.frame = CGRect(x: 0, y: 0, width: width + 10, height: 30)
                        self.tagline.text = tagline
                    }
                }
            }
        }
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
        guard let tagline = streamingData["tagline"] as? String else {
            return
        }
        guard let blog = streamingData["blog"] as? String else {
            return
        }
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getStartLPInvited(title: title, type: type, typeValue: "", category: "3", blog_id: blog, tagline: tagline))
    }
    
    private func sendJoin() {
        let id = Date().currentTimeMillis().toHex()
        _ = Nexilis.write(message: CoreMessage_TMessageBank.joinLiveVideo(broadcast_id: data, request_id: id))
    }
    
    public func sendLeft() {
        let id = Date().currentTimeMillis().toHex()
        _ = Nexilis.write(message: CoreMessage_TMessageBank.leftLiveVideo(broadcast_id: data, request_id: id))
    }
    
    private func sendChat(text: String) {
        _ = Nexilis.write(message: CoreMessage_TMessageBank.getSendLSChat(l_pin: data, message_text: text))
    }
    
    @objc func changeTitleOrTag(_ sender: UITapGestureRecognizer) {
        if let tappedView = sender.view {
            let type = tappedView.tag
            self.alert = LibAlertController(title: "Title".localized(), message: nil, preferredStyle: .alert)
            if type == 1 {
                self.alert = LibAlertController(title: "Tagline".localized(), message: nil, preferredStyle: .alert)
            }
            self.textFields.removeAll()
            self.alert?.addTextField{ (texfield) in
                texfield.text = type == 0 ? (self.status.text!) : self.isEmptyTagline ? "" : (self.tagline.text!)
                texfield.addPadding(.right(40))
                self.textFields.append(texfield)
            }
            let submitAction = UIAlertAction(title: "Submit".localized(), style: .default, handler: { (action) -> Void in
                let textField = self.alert?.textFields![0]
                if textField!.text!.isEmpty {
                    self.view.makeToast((type == 0 ? "Title".localized() : "Tagline".localized()) + " " + "can't be empty".localized(), duration: 3)
                    return
                }
                if textField!.text! == (type == 0 ? (self.streamingData["title"] as! String) : (self.streamingData["tagline"] as! String)) {
                    return
                }
                if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                
                if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getUpdateLiveVideo(pTitle: type == 0 ? "\(self.frontCamera ? 1 : 0)~\(textField!.text!.toStupidString())" : "\(self.frontCamera ? 1 : 0)~\(self.status.text!.toStupidString())■", pTagline: type == 1 ? textField!.text! : self.tagline.text!.toStupidString())) {
                    if response.isOk() {
                        if type == 0 {
                            self.status.text = textField!.text!
                            let size = self.status.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.status.frame.height))
                            let width = size.width
                            self.status.frame = CGRect(x: 0, y: 0, width: width + 10, height: 30)
                            self.statusView.frame = CGRect(x: 0, y: 0, width: width + 10, height: 30)
                        } else {
                            self.tagline.text = textField!.text!
                        }
                        self.view.makeToast("Successfully changed".localized(), duration: 3)
                    }
                }
            })
            self.alert?.addAction(submitAction)
            self.alert?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            
            self.present(self.alert!, animated: true, completion: nil)
        }
    }
    
}

extension QmeraStreamingViewController: UITextViewDelegate {
    
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

extension QmeraStreamingViewController: UITableViewDataSource {
    
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

extension QmeraStreamingViewController: LiveStreamingDelegate {
    
    func onStartLS(state: Int, message: String) {
        if state == Nexilis.OUTGOING_CALL, message.contains("Initiating") {
            DispatchQueue.main.async {
                self.imageView.transform = CGAffineTransform.init(scaleX: 1.6, y: 1.6)
            }
        } else if state == 12 {
            sendLive()
        }
    }
    
    func onJoinLS(state: Int, message: String) {
        if state == Nexilis.AUDIO_CALL_OFFHOOK {
            let m = message.split(separator: ",")
            let _ = String(m[0])
            let _ = String(m[1])
            let camera = Int(m[2])
            let platform = Int(m[3])
            if platform == 1 { // Android
                DispatchQueue.main.async {
                    self.imageView.transform = CGAffineTransform.init(scaleX: 1.9, y: 2.2).rotated(by: camera == 1 ? (CGFloat.pi * 3)/2 : (CGFloat.pi)/2)
                }
            } else {
                DispatchQueue.main.async {
                    self.imageView.transform = CGAffineTransform.init(scaleX: 1.9, y: 2.2).rotated(by: camera == 1 ? (CGFloat.pi * 5)/2 : (CGFloat.pi)/2)
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
                    self.imageView.transform = CGAffineTransform.init(scaleX: 1.9, y: 2.2).rotated(by: camera == 1 ? (CGFloat.pi * 3)/2 : (CGFloat.pi)/2)
                }
            } else {
                DispatchQueue.main.async {
                    self.imageView.transform = CGAffineTransform.init(scaleX: 1.9, y: 2.2).rotated(by: camera == 1 ? (CGFloat.pi * 5)/2 : (CGFloat.pi)/2)
                }
            }
        } else if state == Nexilis.STREAMING_SEMINAR_ENDED {
            DispatchQueue.main.async {
                self.status.text = "Streaming ended".localized()
                let size = self.status.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.status.frame.height))
                let width = size.width
                self.status.frame = CGRect(x: 0, y: 0, width: width + 10, height: 30)
                self.statusView.frame = CGRect(x: 0, y: 0, width: width + 10, height: 30)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.navigationController?.dismiss(animated: true, completion: nil)
            })
        } else if state == 94 { // like
            let m = message.split(separator: ",", omittingEmptySubsequences: false)
            let countLike = m[2].trimmingCharacters(in: .whitespaces)
            DispatchQueue.main.async {
                self.count.text = countLike
            }
            
        } else if state == 95 { // chat
            let m = message.split(separator: ",", omittingEmptySubsequences: false)
            let name = m[3].trimmingCharacters(in: .whitespaces)
            let thumb = m[2].trimmingCharacters(in: .whitespaces)
            let text = m[4].trimmingCharacters(in: .whitespaces)
            chats.append(StreamingChat(name: name, thumb: thumb, messageText: text))
        } else if state == 97 { // someone left
            let m = message.split(separator: ",", omittingEmptySubsequences: false)
            let name = m[3].trimmingCharacters(in: .whitespaces)
            let thumb = m[2].trimmingCharacters(in: .whitespaces)
            let text = "Left".localized()
            chats.append(StreamingChat(name: name, thumb: thumb, messageText: text, isInfo: true))
            DispatchQueue.main.async {
                self.countViewer.text = "\(Int(self.countViewer.text!)! - 1)"
            }
        } else if state == 98 { // someone join
            let m = message.split(separator: ",", omittingEmptySubsequences: false)
            let name = m[3].trimmingCharacters(in: .whitespaces)
            let thumb = m[2].trimmingCharacters(in: .whitespaces)
            let text = "Joined".localized()
            chats.append(StreamingChat(name: name, thumb: thumb, messageText: text, isInfo: true))
            DispatchQueue.main.async {
                self.countViewer.text = "\(Int(self.countViewer.text!)! + 1)"
            }
        }
    }
    
}

class StreamingChat: Model {
    
    let name: String
    let thumb: String
    let messageText: String
    let isInfo: Bool
    
    init(name: String, thumb: String, messageText: String, isInfo: Bool = false) {
        self.name = name
        self.thumb = thumb
        self.messageText = messageText
        self.isInfo = isInfo
    }
    
    static func == (lhs: StreamingChat, rhs: StreamingChat) -> Bool {
        return false
    }
    
    var description: String {
        return ""
    }
    
}
