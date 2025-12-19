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
            startView.isEnabled = false
            if let a = data["title"] as? String {
                titleView.isUserInteractionEnabled = false
                titleView.text = a
            }
            if let b = data["start"] as? String {
                startView.isUserInteractionEnabled = false
                startView.text = b
            }
            if let arrayUser = data["members"] as? [String] {
                users.append(User.getData(pin: data["by"] as? String) ?? User(pin: ""))
                for p in arrayUser {
                    users.append(User.getData(pin: p) ?? User(pin: ""))
                }
            }
        } else if !isJoin && !data.isEmpty {
            navigationItem.rightBarButtonItem?.title = "Start".localized()
            titleView.isEnabled = false
            startView.isEnabled = false
            if let a = data["title"] as? String {
                titleView.isUserInteractionEnabled = false
                titleView.text = a
            }
            if let b = data["start"] as? String {
                startView.isUserInteractionEnabled = false
                startView.text = b
            }
            if let arrayUser = data["members"] as? [String] {
                users.append(User.getData(pin: User.getMyPin()) ?? User(pin: ""))
                for p in arrayUser {
                    users.append(User.getData(pin: p) ?? User(pin: ""))
                }
            }
        } else {
            startTime = Date().currentTimeMillis()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            
            // Update the text field with the formatted date and time
            startView.text = formatter.string(from: Date())
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
        if !data.isEmpty {
            let timeStart = data["time"] as? Int64 ?? 0
            if Date().currentTimeMillis() < timeStart {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Conference room has not started yet. Please wait until the scheduled time.".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
        }
        let controller = VideoConferenceViewController()
        controller.isInisiator = !isJoin
        if isJoin {
            if let dataBlog = data["blog"] as? String {
                controller.roomId = dataBlog
                controller.fPin = data["by"] as? String ?? ""
//                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getIsInitiatorJoin(p_broadcaster: data["by"] as? String ?? "", p_category: "4", blog_id: dataBlog)) {
//                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD) != "00" {
//                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
//                        imageView.tintColor = .white
//                        let banner = FloatingNotificationBanner(title: "Conference room session hasn\'t started yet".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
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
            }
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
                data["by"] = User.getMyPin() ?? ""
                data["time"] = startTime
                data["blog"] = id
                
                if conferenceTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Video Conference title can't be empty".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                let members: [String] = users.map{ $0.pin }
                if members.count == 0 {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Please select at least 1 user".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                data["members"] = members
                guard let json = String(data: try! JSONSerialization.data(withJSONObject: data, options: []), encoding: String.Encoding.utf8) else {
                    return
                }
                
                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.createVCallConference(blog_id: id, data: json)) {
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
                Nexilis.saveMessageBot(textMessage: json, blog_id: id, attachment_type: "25")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                if Date().currentTimeMillis() < startTime {
                    navigationController?.dismiss(animated: true, completion: nil)
                    return
                }
            }
            controller.roomId = data["blog"] as! String
        }
        navigationController?.show(controller, sender: nil)
    }
    
    
    // MARK: - Table view data source
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
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
        case .participants:
            if indexPath.row == 0 && !isJoin && data.isEmpty {
                let controller = QmeraUserChooserViewController()
                controller.ignored.append(contentsOf: users)
                controller.isDismiss = { users in
                    self.users.append(contentsOf: users)
                }
                navigationController?.show(controller, sender: nil)
            }
        default: break
            
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
            cell.contentView.addSubview(startView)
            startView.anchor(top: cell.topAnchor, left: cell.leftAnchor, bottom: cell.bottomAnchor, right: cell.rightAnchor, paddingLeft: 20, paddingRight: 20)
            configureDatePicker()
        case .title:
            cell.contentView.addSubview(titleView)
            titleView.anchor(top: cell.topAnchor, left: cell.leftAnchor, bottom: cell.bottomAnchor, right: cell.rightAnchor, paddingLeft: 20, paddingRight: 20)
        case .participants:
            var content = cell.defaultContentConfiguration()
            if indexPath.row == 0 {
                if data.isEmpty {
                    content.image = UIImage(systemName: "plus.circle.fill")
                    content.imageProperties.tintColor = .mainColor
                    content.text = "Add user".localized()
                    content.textProperties.font = UIFont.systemFont(ofSize: 14)
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                } else {
                    content.text = "Participant".localized() + ": "
                }
            } else {
                let data = users[indexPath.row - 1]
                getImage(name: data.thumb, placeholderImage: UIImage(named: "Profile---Black", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                    content.image = image
                }
                var name = data.fullName
                if data.pin == User.getMyPin() {
                    name = name + " (" + "You".localized() + ")"
                }
                content.text = name
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
                tableView.reloadData()
            }
        default:
            return
        }
    }
    
    public override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 2 && data.isEmpty {
            return .delete
        }
        return .none
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
