//
//  CreateSeminarViewController.swift
//  NexilisLite
//
//  Created by Maronakins on 31/05/23.
//

import UIKit
import NotificationBannerSwift
import AVFoundation

public class CreateSeminarViewController: UITableViewController {
    
    var isJoin = false
    var startTime = 0
    
    var data: [String: Any] = [:]
    
    private enum Section {
        case title
        case start
        case participants
    }
    
    private var sections: [Section] = [
        .title,
        .start,
        .participants
    ]
    
    private var users: [User] = [] {
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
    
    lazy var startView: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Start".localized()
        textField.borderStyle = .none
        return textField
    }()
    
    let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime // Allows both date and time selection
        picker.preferredDatePickerStyle = .wheels // Optional: change the picker style
        return picker
    }()
    
    deinit {
        //print(#function, ">>>> TADAA1")
        NotificationCenter.default.removeObserver(self)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Video Conference Room".localized()
        
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(didTapCancel(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start".localized(), style: .plain, target: self, action: #selector(didTapRight(sender:)))
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        table.addGestureRecognizer(tapGesture)
        
        if isJoin {
            navigationItem.rightBarButtonItem?.title = "Join".localized()
            titleView.isEnabled = false
            if let a = data["title"] as? String {
                titleView.isUserInteractionEnabled = false
                titleView.text = a
            }
            if let b = data["start"] as? String {
                startView.isUserInteractionEnabled = false
                startView.text = b
            }
        } else if !isJoin && !data.isEmpty {
            navigationItem.rightBarButtonItem?.title = "Start".localized()
            titleView.isEnabled = false
            if let a = data["title"] as? String {
                titleView.text = a
            }
            if let b = data["start"] as? String {
                startView.text = b
            }
        }
        
        tableView = table
    }
    
    private func configureDatePicker() {
        // Set the date picker as the input view for the text field
        startView.inputView = datePicker
        
        // Create a toolbar with a "Done" button
        let toolbar = UIToolbar()
        toolbar.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        toolbar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.setItems([doneButton], animated: true)
        
        // Set the toolbar as the accessory view for the text field
        startView.inputAccessoryView = toolbar
    }
    
    @objc private func doneButtonTapped() {
        // Format the selected date and time
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        // Update the text field with the formatted date and time
        startTime = datePicker.date.currentTimeMillis()
        startView.text = formatter.string(from: datePicker.date)
        
        // Dismiss the date picker
        view.endEditing(true)
    }
    
    
    @objc func dismissKeyboard() {
        titleView.resignFirstResponder()
    }
    
    @objc func didTapCancel(sender: AnyObject) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapRight(sender: Any?) {
        let controller = VideoConferenceViewController()
        controller.isInisiator = !isJoin
//    TODO:    let controller = SeminarViewController()
//    TODO:    controller.isLive = !isJoin
        if isJoin {
//            guard let by = data["by"] as? String else {
//                return
//            }
            if let dataBlog = data["blog"] as? String {
                controller.roomId = dataBlog
            }
//            if dataBlog != nil {
//                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.joinVCallConference(blog_id: dataBlog!)) {
//                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD) != "00" {
//                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
//                            imageView.tintColor = .white
//                            let banner = FloatingNotificationBanner(title: "Conference call session hasn\'t started yet".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
//                            banner.show()
//                            return
//                        }
//                    } else {
//                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
//                        imageView.tintColor = .white
//                        let banner = FloatingNotificationBanner(title: "No Network. Please try again.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
//                        banner.show()
//                        return
//                    }
//                }
//      TODO:      controller.data = by
//      TODO:      controller.streamingData = data
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
                guard let conferenceTitle = titleView.text else {
                    return
                }
                
                let id = User.getMyPin()! +  CoreMessage_TMessageUtil.getTID()
                
                data["title"] = conferenceTitle
//         TODO:        data["start"]
                data["by"] = User.getMyPin() ?? ""
                data["time"] = Date().currentTimeMillis()
                data["blog"] = id
                
                if conferenceTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Video Conference title can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
//                
//                var type: String = "0" // Friend
                let members: [String] = users.map{ $0.pin }
//                switch chooser[0].id {
//                case 0:
//                    type = "7"
//                case 1:
//                    type = "8"
//                case 2:
//                    type = "3"
//                case 3:
//                    type = "6"
//                case 4:
//                    type = "5"
//                default:
//                    type = "0"
//                }
//                
                data["members"] = members
                
//                var notif: String = "0"
//                switch chooser[1].id {
//                case 0:
//                    notif = "1"
//                default:
//                    notif = "2"
//                }
                
//                data["broadcast_type"] = notif
                guard let json = String(data: try! JSONSerialization.data(withJSONObject: data, options: []), encoding: String.Encoding.utf8) else {
                    return
                }
                
                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.createVCallConference(blog_id: data["blog"] as! String, data: json)) {
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
                
//                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.startVCallConference(blog_id: data["blog"] as! String, time: data["time"] as! String), timeout: 30 * 1000) {
//                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD) != "00" {
//                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
//                        imageView.tintColor = .white
//                        let banner = FloatingNotificationBanner(title: "Server Busy. Please try again.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
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
                
//                Nexilis.saveMessageBot(textMessage: json, blog_id: data["blog"] as? String ?? "", attachment_type: "26")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
            }
//          TODO:  controller.data = User.getMyPin()!
//          TODO:  controller.streamingData = data
            controller.roomId = data["blog"] as! String
        }
//       TODO: navigationController?.show(controller, sender: nil)
        if !controller.isInisiator {
            var stack = navigationController?.viewControllers
            stack!.remove(at: (stack!.count) - 1)
            stack!.insert(controller, at: stack!.count)
            navigationController?.setViewControllers(stack!, animated: true)
        }
        else {
            navigationController?.show(controller, sender: nil)
        }
//        navigationController?.show(controller, sender: nil)
//        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Table view data source
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        if isJoin {
            return sections.count - 1
        }
        return sections.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .participants:
            return users.count + 1
        default:
            return 1
        }
    }
    
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
//        switch sections[indexPath.section] {
//        case .description:
//            return 100
//        default:
//            return 44
//        }
    }
    
    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if isJoin, sections[indexPath.section] == .participants {
            return nil
        }
        return indexPath
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section] {
        case .start:
            if !isJoin {
                sections.append(.participants)
                if users.count != 0{
                    users.removeAll()
                }
            }
//            if indexPath.row == 0 {
//                if isJoin || (!isJoin && !data.isEmpty){
//                    return
//                }
//                let chooser = chooser[indexPath.row]
//                let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "audienceView") as AudienceViewController
//                controller.selected = chooser.value
//                controller.isDismiss = { [weak self] index in
//                    chooser.id = index
//                    chooser.value = AudienceViewController().data[index]
//                    guard let sec = self?.sections else {
//                        return
//                    }
//                    if sec.count > 4 {
//                        self?.sections.removeLast()
//                    }
//                    if chooser.value == "Group".localized() {
//                        self?.sections.append(.groups)
//                        if self?.users.count != 0 {
//                            self?.users.removeAll()
//                        }
//                    } else if chooser.value == "User".localized() {
//                        self?.sections.append(.users)
//                        if self?.groups.count != 0{
//                            self?.groups.removeAll()
//                        }
//                    } else {
//                        if self?.users.count != 0 {
//                            self?.users.removeAll()
//                        } else if self?.groups.count != 0{
//                            self?.groups.removeAll()
//                        }
//                    }
//                    DispatchQueue.main.async {
//                        tableView.reloadData()
//                    }
//                }
//                navigationController?.show(controller, sender: nil)
//            }
        case .participants:
            if indexPath.row == 0 && !isJoin {
                let controller = QmeraUserChooserViewController()
                controller.ignored.append(contentsOf: users)
                controller.isDismiss = { users in
                    self.users.append(contentsOf: users)
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
        case .start:
//            var content = cell.defaultContentConfiguration()
//            let data = chooser[indexPath.row]
//            content.text = data.title
//            content.secondaryText = data.value
//            content.textProperties.font = UIFont.systemFont(ofSize: 14)
//            content.secondaryTextProperties.color = .systemGray
//            content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 14)
//            content.prefersSideBySideTextAndSecondaryText = true
//            cell.contentConfiguration = content
//            cell.accessoryType = .disclosureIndicator
//            cell.selectionStyle = .default
            cell.contentView.addSubview(startView)
            startView.anchor(top: cell.topAnchor, left: cell.leftAnchor, bottom: cell.bottomAnchor, right: cell.rightAnchor, paddingLeft: 20, paddingRight: 20)
            configureDatePicker()
        case .title:
            cell.contentView.addSubview(titleView)
            titleView.anchor(top: cell.topAnchor, left: cell.leftAnchor, bottom: cell.bottomAnchor, right: cell.rightAnchor, paddingLeft: 20, paddingRight: 20)
        case .participants:
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
        }
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .participants:
            if (editingStyle == .delete) {
                users.remove(at: indexPath.row - 1)
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

private class Chooser {
    
    let title: String
    var id: Int = 0
    var value: String?
    
    init(title: String, id: Int = 0, value: String?) {
        self.title = title
        self.id = id
        self.value = value
    }
    
}

extension CreateSeminarViewController: UITextViewDelegate {
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Title".localized()
            textView.textColor = UIColor.lightGray
        }
    }
}
