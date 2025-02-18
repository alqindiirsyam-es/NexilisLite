//
//  CreateSeminarViewController.swift
//  NexilisLite
//
//  Created by Maronakins on 31/05/23.
//

import UIKit
import NotificationBannerSwift
import AVFoundation

public class CreateConferenceCallController: UITableViewController {
    
    var isJoin = false
    
    var data: [String: Any] = [:]
    
    private enum Section {
        case chooser
        case title
        case description
        case users
        case groups
    }
    
    private var sections: [Section] = [
        .chooser,
        .title,
        .description
    ]
    
    private var chooser: [ConfChooser] = [
        ConfChooser(title: "Target Audience".localized(), value: AudienceViewController().data.first),
        ConfChooser(title: "Promotion Type".localized(), value: TypeViewController().data.first)
    ]
    
    private var users: [User] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    private var groups: [Group] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    private let cellIdentifier = "reuseIdentifier"
    
    lazy var table: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        return tableView
    }()
    
    lazy var titleView: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.placeholder = "Title".localized()
        return textField
    }()
    
    lazy var descriptionView: UITextView = {
        let textView = UITextView()
        textView.text = "Description".localized()
        textView.textColor = UIColor.lightGray
        return textView
    }()
    
    deinit {
        //print(#function, ">>>> TADAA1")
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshView"), object: nil, userInfo: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Conference Call".localized()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(didTapCancel(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start".localized(), style: .plain, target: self, action: #selector(didTapRight(sender:)))
        
        descriptionView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        table.addGestureRecognizer(tapGesture)
        
        if isJoin {
            navigationItem.rightBarButtonItem?.title = "Join".localized()
            titleView.isEnabled = false
            descriptionView.isEditable = false
            if let a = data["type"] as? String {
                chooser[0].value = AudienceViewController().data[getTypeIndex(value: a)]
            }
            if let b = data["broadcast_type"] as? String {
                chooser[1].value = TypeViewController().data[getBroadcastIndex(value: b)]
            }
            if let c = data["title"] as? String {
                titleView.text = c
            }
            if let d = data["description"] as? String {
                descriptionView.text = d
            }
        } else if !isJoin && !data.isEmpty {
            navigationItem.rightBarButtonItem?.title = "Start".localized()
            titleView.isEnabled = false
            descriptionView.isEditable = false
            if let a = data["type"] as? String {
                chooser[0].value = AudienceViewController().data[getTypeIndex(value: a)]
            }
            if let b = data["broadcast_type"] as? String {
                chooser[1].value = TypeViewController().data[getBroadcastIndex(value: b)]
            }
            if let c = data["title"] as? String {
                titleView.text = c
            }
            if let d = data["description"] as? String {
                descriptionView.text = d
            }
        }
        
        tableView = table
    }
    
    @objc func dismissKeyboard() {
        titleView.resignFirstResponder()
        descriptionView.resignFirstResponder()
    }
    
    @objc func didTapCancel(sender: AnyObject) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapRight(sender: Any?) {
        let controller = SeminarViewController()
        controller.isLive = !isJoin
        if isJoin {
            guard let by = data["by"] as? String else {
                return
            }
            let dataBlog = data["blog"] as? String
//            if dataBlog != nil {
//                if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getIsInitiatorJoin(p_broadcaster: by, p_category: "3", blog_id: dataBlog!)) {
//                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD) != "00" {
//                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
//                        imageView.tintColor = .white
//                        let banner = FloatingNotificationBanner(title: "Seminar session hasn\'t started yet".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
//                        banner.show()
//                        return
//                    }
//                } else {
//                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
//                    imageView.tintColor = .white
//                    let banner = FloatingNotificationBanner(title: "No Network. Please try again.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
//                    banner.show()
//                    return
//                }
//            }
            controller.data = by
            controller.streamingData = data
        } else {
            let goAudioCall = Nexilis.checkMicPermission()
            if !goAudioCall {
                let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow microphone permission in your settings".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: { _ in
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }))
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
                }
                return
            }
            var permissionCheck = -1
            if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
                permissionCheck = 1
            } else if AVCaptureDevice.authorizationStatus(for: .video) ==  .denied {
                permissionCheck = 0
            } else {
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) -> Void in
                    if granted == true {
                        permissionCheck = 1
                    } else {
                        permissionCheck = 0
                    }
                })
            }
            
            while permissionCheck == -1 {
                sleep(1)
            }
            
            if permissionCheck == 0 {
                let alert = LibAlertController(title: "Attention!".localized(), message: "Please allow camera permission in your settings".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertAction.Style.default, handler: { _ in
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }))
                if UIApplication.shared.visibleViewController?.navigationController != nil {
                    UIApplication.shared.visibleViewController?.navigationController?.present(alert, animated: true, completion: nil)
                } else {
                    UIApplication.shared.visibleViewController?.present(alert, animated: true, completion: nil)
                }
                return
            }
            var data: [String: Any] = [:]
            if !isJoin && !self.data.isEmpty {
                data = self.data
            } else if self.data.isEmpty {
                guard let streamingTitle = titleView.text else {
                    return
                }
                guard let streamingDesc = descriptionView.text else {
                    return
                }
                
                let id = "LST\(Date().currentTimeMillis().toHex())"
                
                data["title"] = streamingTitle
                data["description"] = streamingDesc
                data["by"] = User.getMyPin() ?? ""
                data["time"] = Date().currentTimeMillis()
                data["blog"] = id
                
                if streamingTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Seminar title can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                } else if streamingDesc.trimmingCharacters(in: .whitespaces).isEmpty {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Seminar description can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                
                var type: String = "0" // Friend
                let groups: [String] = groups.map{ $0.id }
                let members: [String] = users.map{ $0.pin }
                switch chooser[0].id {
                case 0:
                    type = "7"
                case 1:
                    type = "8"
                case 2:
                    type = "3"
                case 3:
                    type = "6"
                case 4:
                    type = "5"
                default:
                    type = "0"
                }
                
                data["groups"] = groups
                data["members"] = members
                data["type"] = type
                
                var notif: String = "0"
                switch chooser[1].id {
                case 0:
                    notif = "1"
                default:
                    notif = "2"
                }
                
                data["broadcast_type"] = notif
                guard let json = String(data: try! JSONSerialization.data(withJSONObject: data, options: []), encoding: String.Encoding.utf8) else {
                    return
                }
                
                if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.createSeminar(title: "1~\(data["title"] ?? "")", type: data["type"] as! String, category: "4", notifType: data["broadcast_type"] as! String, blogId: data["blog"] as! String, data: json)) {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD) != "00" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Server Busy. Please try again.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                        return
                    }
                } else {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "No Network. Please try again.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                
//                Nexilis.saveMessageBot(textMessage: json, blog_id: data["blog"] as? String ?? "", attachment_type: "26")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
            }
            controller.data = User.getMyPin()!
            controller.streamingData = data
        }
        navigationController?.show(controller, sender: nil)
    }
    
    private func getTypeIndex(value: String) -> Int {
        var type = 0
        switch value {
        case "7":
            type = 0
        case "8":
            type = 1
        case "3":
            type = 2
        case "6":
            type = 3
        case "5":
            type = 4
        default:
            type = 0
        }
        return type
    }
    
    private func getBroadcastIndex(value: String) -> Int {
        var notif = 0
        switch value {
        case "1":
            notif = 0
        default:
            notif = 1
        }
        return notif
    }
    
    // MARK: - Table view data source
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .chooser:
            return 2
        case .users:
            return users.count + 1
        case .groups:
            return groups.count + 1
        default:
            return 1
        }
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section] {
        case .description:
            return 100
        default:
            return 44
        }
    }
    
    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if isJoin, sections[indexPath.section] == .chooser {
            return nil
        }
        return indexPath
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section] {
        case .chooser:
            if indexPath.row == 0 {
                if isJoin || (!isJoin && !data.isEmpty){
                    return
                }
                let chooser = chooser[indexPath.row]
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "audienceView") as AudienceViewController
                controller.selected = chooser.value
                controller.isDismiss = { [weak self] index in
                    chooser.id = index
                    chooser.value = AudienceViewController().data[index]
                    guard let sec = self?.sections else {
                        return
                    }
                    if sec.count > 4 {
                        self?.sections.removeLast()
                    }
                    if chooser.value == "Group".localized() {
                        self?.sections.append(.groups)
                        if self?.users.count != 0 {
                            self?.users.removeAll()
                        }
                    } else if chooser.value == "User".localized() {
                        self?.sections.append(.users)
                        if self?.groups.count != 0{
                            self?.groups.removeAll()
                        }
                    } else {
                        if self?.users.count != 0 {
                            self?.users.removeAll()
                        } else if self?.groups.count != 0{
                            self?.groups.removeAll()
                        }
                    }
                    DispatchQueue.main.async {
                        tableView.reloadData()
                    }
                }
                navigationController?.show(controller, sender: nil)
            } else if indexPath.row == 1 {
                if isJoin || (!isJoin && !data.isEmpty){
                    return
                }
                let chooser = chooser[indexPath.row]
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "typeView") as TypeViewController
                controller.selected = chooser.value
                controller.isDismiss = { index in
                    chooser.id = index
                    chooser.value = TypeViewController().data[index]
                    DispatchQueue.main.async {
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                }
                navigationController?.show(controller, sender: nil)
            }
        case .users:
            if indexPath.row == 0 {
                let controller = QmeraUserChooserViewController()
                controller.ignored.append(contentsOf: users)
                controller.isDismiss = { users in
                    self.users.append(contentsOf: users)
                }
                navigationController?.show(controller, sender: nil)
            }
        case .groups:
            if indexPath.row == 0 {
                let controller = QmeraGroupStreamingViewController()
                controller.ignored.append(contentsOf: groups)
                controller.isDismiss = { groups in
                    self.groups.append(contentsOf: groups)
                }
                navigationController?.show(controller, sender: nil)
            }
        default:
            return
        }
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.contentView.subviews.forEach{ NSLayoutConstraint.deactivate($0.constraints); $0.removeFromSuperview() }
        cell.contentConfiguration = nil
        cell.accessoryType = .none
        cell.selectionStyle = .none
        switch sections[indexPath.section] {
        case .chooser:
            var content = cell.defaultContentConfiguration()
            let data = chooser[indexPath.row]
            content.text = data.title
            content.secondaryText = data.value
            content.textProperties.font = UIFont.systemFont(ofSize: 14)
            content.secondaryTextProperties.color = .systemGray
            content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 14)
            content.prefersSideBySideTextAndSecondaryText = true
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case .title:
            cell.contentView.addSubview(titleView)
            titleView.anchor(top: cell.topAnchor, left: cell.leftAnchor, bottom: cell.bottomAnchor, right: cell.rightAnchor, paddingLeft: 20, paddingRight: 20)
        case .description:
            let stack = UIStackView()
            stack.axis = .vertical
            stack.distribution = .fill
            cell.contentView.addSubview(stack)
            stack.anchor(top: cell.topAnchor, left: cell.leftAnchor, bottom: cell.bottomAnchor, right: cell.rightAnchor, paddingTop: 8, paddingLeft: 20, paddingBottom: 8, paddingRight: 20)
            stack.addArrangedSubview(descriptionView)
        case .users:
            var content = cell.defaultContentConfiguration()
            if indexPath.row == 0 {
                content.image = UIImage(systemName: "plus.circle.fill")
                content.imageProperties.tintColor = .mainColor
                content.text = "Add user".localized()
                content.textProperties.font = UIFont.systemFont(ofSize: 14)
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            } else {
                let data = users[indexPath.row - 1]
                getImage(name: data.thumb, placeholderImage: UIImage(named: "Profile---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                    content.image = image
                }
                content.text = data.fullName
                content.textProperties.font = UIFont.systemFont(ofSize: 14)
            }
            cell.contentConfiguration = content
        case .groups:
            var content = cell.defaultContentConfiguration()
            if indexPath.row == 0 {
                content.image = UIImage(systemName: "plus.circle.fill")
                content.imageProperties.tintColor = .mainColor
                content.text = "Add group".localized()
                content.textProperties.font = UIFont.systemFont(ofSize: 14)
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            } else {
                let data = groups[indexPath.row - 1]
                getImage(name: data.profile, placeholderImage: UIImage(named: "Conversation---Purple", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                    content.image = image
                }
                content.text = data.name
                content.textProperties.font = UIFont.systemFont(ofSize: 14)
            }
            cell.contentConfiguration = content
        }
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .users:
            if (editingStyle == .delete) {
                users.remove(at: indexPath.row - 1)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .groups:
            if (editingStyle == .delete) {
                groups.remove(at: indexPath.row - 1)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        default:
            return
        }
    }
    
    public override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section < 4 {
            return .none
        } else if indexPath.section == 4 && indexPath.row == 0 {
            return .none
        }

        return .delete
    }
    
    @IBAction func result(unwind segue: UIStoryboardSegue) {
        
    }
    
}

private class ConfChooser {
    
    let title: String
    var id: Int = 0
    var value: String?
    
    init(title: String, id: Int = 0, value: String?) {
        self.title = title
        self.id = id
        self.value = value
    }
    
}

extension CreateConferenceCallController: UITextViewDelegate {
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Description".localized()
            textView.textColor = UIColor.lightGray
        }
    }
}
