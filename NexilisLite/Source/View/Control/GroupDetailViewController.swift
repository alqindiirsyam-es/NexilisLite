//
//  GroupViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 24/09/21.
//

import UIKit
import NotificationBannerSwift
import nuSDKService

class GroupDetailViewController: UITableViewController {
    
    enum Flag {
        case edit
        case view
    }
    
    var flag: Flag = .edit
    
    var data: String = ""
    
    static let SUBGROUP_LEVEL_LIMIT = 10
    
    private var group: Group?
    
    private var isAdmin: Bool = false
    
    private var imageVideoPicker : ImageVideoPicker!
    
    private var tempImage: UIImage?
    
    private let imageAdmin = UIImageView()
    
    private let imageAddContact = UIImageView()
    
    private enum Section {
        case profile
        case description
        case access
        case topic
        case detail
        case member
        case exit
    }
    
    private var sections: [Section] = [
        .profile,
        .description,
        .access,
        .topic,
        .detail
    ]
    
    var checkReadMessage: (() -> ())?
    
    private let idSubGroup = Date().currentTimeMillis().toHex()
    
    var fromNotification = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageVideoPicker = ImageVideoPicker(presentationController: self, delegate: self)
        
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.topItem?.backButtonTitle = ""
        
        if fromNotification {
            let imageButton = UIImageView(frame: CGRect(x: -16, y: 0, width: 20, height: 44))
            imageButton.image = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default))?.withTintColor(.white)
            imageButton.contentMode = .left
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapExit))
            imageButton.isUserInteractionEnabled = true
            imageButton.addGestureRecognizer(tapGestureRecognizer)
            let leftItem = UIBarButtonItem(customView: imageButton)
            self.navigationItem.leftBarButtonItem = leftItem
        }
        
        reload()
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(updateData(notification:)), name: NSNotification.Name(rawValue: "onGroup"), object: nil)
        center.addObserver(self, selector: #selector(updateData(notification:)), name: NSNotification.Name(rawValue: "onTopic"), object: nil)
        center.addObserver(self, selector: #selector(updateData(notification:)), name: NSNotification.Name(rawValue: "onMember"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            self.checkReadMessage?()
        }
    }
    var alert2: UIAlertController?
    var textFields = [UITextField]()
    
    // MARK: - Data source
    
    @objc func didTapExit() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func reload() {
        getData { group in
            self.group = group
            if let myData = self.group?.members.first(where: { member in
                return member.pin == User.getMyPin()!
            }) {
                if myData.position == "1" {
                    self.isAdmin = true
                } else {
                    self.isAdmin = false
                }
            }
            if self.sections.count == 5, group.groupType != "1" {
                self.sections.append(.member)
                self.sections.append(.exit)
            }
            DispatchQueue.main.async {
                self.title = group.name
                
                self.tableView.reloadData()
                
                if group.official == "1" && !group.parent.isEmpty {
                    Database.shared.database?.inTransaction({ (fmdb, rollback) in
                        do {
                            if let cursorImage = Database.shared.getRecords(fmdb: fmdb, query: "SELECT image_id FROM GROUPZ where group_type = 1 AND official = 1"), cursorImage.next() {
                                self.group?.profile = cursorImage.string(forColumnIndex: 0)!
                                cursorImage.close()
                            }
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
                
                if self.isAdmin && group.official != "1" {
                    var children : [UIAction] = []
                    if Int(group.level)! <= GroupDetailViewController.SUBGROUP_LEVEL_LIMIT {
                        children.append(UIAction(title: "Add Sub Group".localized(), handler: {(_) in
                            self.createSubGroup()
                        }))
                    }
                    children.append(UIAction(title: "Change Name Group".localized(), handler: {(_) in
                        self.edit()
                    }))
                    let menu = UIMenu(title: "", children: children)
                    let moreIcon = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), menu: menu)
                    self.navigationItem.rightBarButtonItem = moreIcon
                }
            }
        }
    }
    
    func createSubGroup() {
        self.alert2 = LibAlertController(title: "Create Sub Group".localized(), message: nil, preferredStyle: .alert)
        self.textFields.removeAll()
        self.alert2?.addTextField{ (texfield) in
            texfield.placeholder = "Group's Name".localized()
            texfield.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        }
        let submitAction = UIAlertAction(title: "Create".localized(), style: .default, handler: { (action) -> Void in
            let textField = self.alert2?.textFields![0]
            if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            var level = self.group!.level
            if level.isEmpty || level == "-1"{
                level = "2"
            } else {
                level = "\(Int(level)! + 1)"
            }
            //print("level: \(level)")
            DispatchQueue.main.async {
                if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getCreateSubGroup(group_id: self.idSubGroup, group_name: textField!.text!, parent_id: self.group!.id, level: level)) {
                    if response.isOk() {
                        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "groupDetailView") as! GroupDetailViewController
                        controller.data = self.idSubGroup
                        self.navigationController?.show(controller, sender: nil)
                        self.navigationController?.viewControllers.removeSubrange(1...(self.navigationController?.viewControllers.count)! - 2)
                    } else {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            }
        })
        self.alert2?.addAction(submitAction)
        self.alert2?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        
        self.present(self.alert2!, animated: true, completion: nil)
    }
    
    func edit() {
        let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "groupNameView") as! GroupNameViewController
        controller.data = self.data
        controller.name = group?.name
        controller.isDismiss = {
            self.reload()
        }
        let navController = CustomNavigationController(rootViewController: controller)
        let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        navController.navigationBar.titleTextAttributes = textAttributes
        navigationController?.present(navController, animated: true)
    }
    
    @objc func updateData(notification: NSNotification) {
        let data:[AnyHashable : Any] = notification.userInfo!
        if data["code"] as! String == "A008" && data["member"] as! String == User.getMyPin()! {
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        } else if data["f_pin"] as! String != User.getMyPin()! || data["code"] as! String == "BD" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.reload()
            }
        }
    }
    
    private func getData(completion: @escaping (Group) -> ()) {
        DispatchQueue.global().async {
            let query = "select g.group_id, g.f_name, g.image_id, g.quote, g.created_by, g.created_date, g.parent, g.group_type, g.is_open, g.official, g.level from GROUPZ g where g.group_id = '\(self.data)'"
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    if let cursor = Database.shared.getRecords(fmdb: fmdb, query: query), cursor.next() {
                        let group = Group(id: cursor.string(forColumnIndex: 0) ?? "",
                                           name: cursor.string(forColumnIndex: 1) ?? "",
                                           profile: cursor.string(forColumnIndex: 2) ?? "",
                                           quote: cursor.string(forColumnIndex: 3) ?? "",
                                           by: cursor.string(forColumnIndex: 4) ?? "",
                                           date: cursor.string(forColumnIndex: 5) ?? "",
                                           parent: cursor.string(forColumnIndex: 6) ?? "",
                                           groupType: cursor.string(forColumnIndex: 7) ?? "",
                                           isOpen: cursor.string(forColumnIndex: 8) ?? "",
                                           official: cursor.string(forColumnIndex: 9) ?? "",
                                        level: cursor.string(forColumnIndex: 10) ?? "")
                        cursor.close()
                        
                        group.topics.append(Topic(chatId: "", title: "Lounge".localized(), thumb: ""))
                        
                        if let cursorTopic = Database.shared.getRecords(fmdb: fmdb, query: "select chat_id, title, thumb from DISCUSSION_FORUM where group_id = '\(self.data)'") {
                            while cursorTopic.next() {
                                let topic = Topic(chatId: cursorTopic.string(forColumnIndex: 0) ?? "",
                                                  title: cursorTopic.string(forColumnIndex: 1) ?? "",
                                                  thumb: cursorTopic.string(forColumnIndex: 2) ?? "")
                                group.topics.append(topic)
                            }
                            cursorTopic.close()
                        }
                        
                        if let cursorMember = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin, first_name, last_name, thumb_id, position from GROUPZ_MEMBER where group_id = '\(self.data)' order by 2 asc") {
                            while cursorMember.next() {
                                let member = Member(pin: cursorMember.string(forColumnIndex: 0) ?? "",
                                                firstName: cursorMember.string(forColumnIndex: 1) ?? "",
                                                lastName: cursorMember.string(forColumnIndex: 2) ?? "",
                                                thumb: cursorMember.string(forColumnIndex: 3) ?? "",
                                                position: cursorMember.string(forColumnIndex: 4) ?? "")
                                if let cursorUser = Database.shared.getRecords(fmdb: fmdb, query: "SELECT user_type, official_account FROM BUDDY where f_pin='\(member.pin)'"), cursorUser.next() {
                                    member.userType = cursorUser.string(forColumnIndex: 0)
                                    member.official = cursorUser.string(forColumnIndex: 1)
                                    cursorUser.close()
                                }
                                group.members.append(member)
                            }
                            cursorMember.close()
                        }
                        
                        completion(group)
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
    }
    
    // MARK: - Cell selected
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        switch sections[indexPath.section] {
        case .profile:
            if isAdmin {
                let alert = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Take Photo".localized(), style: .default, handler: { action in
                    self.imageVideoPicker.present(source: .imageCamera)
                }))
                alert.addAction(UIAlertAction(title: "Choose Photo".localized(), style: .default, handler: { action in
                    self.imageVideoPicker.present(source: .imageAlbum)
                }))
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { action in
                    
                }))
                navigationController?.present(alert, animated: true)
            }
        case .description:
            if let g = group, isAdmin {
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "groupDescView") as! GroupDescViewController
                controller.data = g.id
                controller.quote = g.quote
                controller.isDismiss = {
                    self.reload()
                }
                let navController = CustomNavigationController(rootViewController: controller)
                let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
                UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                navController.navigationBar.titleTextAttributes = textAttributes
                navigationController?.present(navController, animated: true)
            }
            
        case .access:
            if let g = group, isAdmin, g.official != "1" {
                var currentAccess = g.isOpen
                if currentAccess.isEmpty || currentAccess == "0" {
                    currentAccess = "1"
                } else {
                    currentAccess = "0"
                }
                Nexilis.showLoader()
                self.changeOpenGroup(open: currentAccess) { result in
                    if result {
                        DispatchQueue.main.async {
                            Nexilis.hideLoader(completion: {
                                g.isOpen = currentAccess
                                tableView.reloadRows(at: [indexPath], with: .none)
                            })
                        }
                    } else {
                        DispatchQueue.main.async {
                            Nexilis.hideLoader(completion: {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                banner.show()
                            })
                        }
                    }
                }
            }
        case .topic:
            if let g = group, isAdmin, indexPath.row == 0 {
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "groupTopicView") as! GroupTopicViewController
                controller.data = g.id
                controller.isDismiss = {
                    self.reload()
                }
                let navController = CustomNavigationController(rootViewController: controller)
                let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
                UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                navController.navigationBar.titleTextAttributes = textAttributes
                navigationController?.present(navController, animated: true)
            } else if let g = group, isAdmin {
                let topic = g.topics[indexPath.row - 1]
                if topic.chatId.isEmpty {
                    if let controller = self.previousViewController as? EditorGroup {
                        if controller.dataTopic["chat_id"] as! String == topic.chatId {
                            self.navigationController?.popViewController(animated: true)
                            return
                        }
                        controller.unique_l_pin = g.id
                        controller.loadData()
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                        editorGroupVC.hidesBottomBarWhenPushed = true
                        editorGroupVC.unique_l_pin = g.id
                        self.navigationController?.viewControllers.first?.show(editorGroupVC, sender: nil)
                    }
                    return
                }
                let alert = LibAlertController(title: nil, message: topic.title, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Enter Topic", style: .default, handler: { action in
                    if let controller = self.previousViewController as? EditorGroup {
                        if controller.dataTopic["chat_id"] as! String == topic.chatId {
                            self.navigationController?.popViewController(animated: true)
                            return
                        }
                        controller.unique_l_pin = topic.chatId
                        controller.loadData()
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                        editorGroupVC.hidesBottomBarWhenPushed = true
                        editorGroupVC.unique_l_pin = topic.chatId
                        self.navigationController?.viewControllers.first?.show(editorGroupVC, sender: nil)
                    }
                }))
                alert.addAction(UIAlertAction(title: "Rename Topic", style: .default, handler: { action in
                    self.alert2 = LibAlertController(title: "Change Topic's Name".localized(), message: nil, preferredStyle: .alert)
                    self.textFields.removeAll()
                    self.alert2?.addTextField{ (texfield) in
                        texfield.text = topic.title
                        texfield.placeholder = "Topic's Name"
                        texfield.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
                    }
                    let submitAction = UIAlertAction(title: "Rename".localized(), style: .default, handler: { (action) -> Void in
                        let textField = self.alert2?.textFields![0]
                        if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                            return
                        }
                        if textField!.text! == topic.title {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Topic name has been used. Enter another topic name".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                            return
                        }
                        if textField!.text! == "Lounge" || textField!.text! == "Beranda" {
                            let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                            imageView.tintColor = .white
                            let banner = FloatingNotificationBanner(title: "Topic already registered".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                            banner.show()
                            return
                        }
                        DispatchQueue.main.async {
                            if let g = self.group, let _ = Nexilis.write(message: CoreMessage_TMessageBank.getUpdateChat(p_chat_id: topic.chatId, p_f_pin: g.id, p_title: textField!.text!, p_anonym: "", p_image: topic.thumb)) {
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Successfully changed".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                        }
                    })
                    self.alert2?.addAction(submitAction)
                    self.alert2?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                    
                    self.present(self.alert2!, animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Remove Topic".localized(), style: .destructive, handler: { action in
                    let message = "Remove \(topic.title) from the \"\(g.name)\" group?"
                    let notif = LibAlertController(title: nil, message: message, preferredStyle: .actionSheet)
                    notif.addAction(UIAlertAction(title: "Remove".localized(), style: .destructive, handler: { notifAction in
                        self.removeTopic(chatId: topic.chatId) { result in
                            if result, let index = g.topics.firstIndex(of: topic) {
                                Database.shared.database?.inTransaction({ (fmdb, rollback) in
                                    do {
                                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "DISCUSSION_FORUM", _where: "chat_id = '\(topic.chatId)'")
                                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE", _where: "chat_id='\(topic.chatId)'")
                                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "MESSAGE_SUMMARY", _where: "l_pin='\(topic.chatId)'")
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                var data: [AnyHashable : Any] = [:]
                                data["code"] = CoreMessage_TMessageCode.DELETE_CHAT
                                data["f_pin"] = User.getMyPin()!
                                data["topicId"] = topic.chatId
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "onTopic"), object: nil, userInfo: data)
                                DispatchQueue.main.async {
                                    tableView.beginUpdates()
                                    tableView.deleteRows(at: [indexPath], with: .none)
                                    g.topics.remove(at: index)
                                    tableView.endUpdates()
                                }
                            }
                        }
                    }))
                    notif.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { notifAction in
                        
                    }))
                    self.navigationController?.present(notif, animated: true, completion: nil)
                }))
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { action in
                    
                }))
                navigationController?.present(alert, animated: true)
            } else if let g = group {
                let topic = g.topics[indexPath.row]
                if topic.chatId.isEmpty {
                    if let controller = self.previousViewController as? EditorGroup {
                        if controller.dataTopic["chat_id"] as! String == topic.chatId {
                            self.navigationController?.popViewController(animated: true)
                            return
                        }
                        controller.unique_l_pin = g.id
                        controller.loadData()
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                        let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                        editorGroupVC.hidesBottomBarWhenPushed = true
                        editorGroupVC.unique_l_pin = g.id
                        self.navigationController?.viewControllers.first?.show(editorGroupVC, sender: nil)
                    }
                    return
                }
                else if let controller = self.previousViewController as? EditorGroup {
                    if controller.dataTopic["chat_id"] as! String == topic.chatId {
                        self.navigationController?.popViewController(animated: true)
                        return
                    }
                    controller.unique_l_pin = topic.chatId
                    controller.loadData()
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.navigationController?.popViewController(animated: true)
                    let editorGroupVC = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "editorGroupVC") as! EditorGroup
                    editorGroupVC.hidesBottomBarWhenPushed = true
                    editorGroupVC.unique_l_pin = topic.chatId
                    self.navigationController?.viewControllers.first?.show(editorGroupVC, sender: nil)
                }
            }
        case .member:
            if let g = group, isAdmin, indexPath.row == 0 {
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(identifier: "groupMemberView") as! GroupMemberViewController
                controller.group = g
                if g.official == "1" && g.level == "3" {
                    controller.isContactCenterInvite = true
                }
                controller.isDismiss = {
                    self.reload()
                }
                let navController = CustomNavigationController(rootViewController: controller)
                let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
                UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
                let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
                navController.navigationBar.titleTextAttributes = textAttributes
                navController.navigationBar.largeTitleTextAttributes = textAttributes
                navigationController?.present(navController, animated: true)
            } else if let g = group, isAdmin {
                let member = g.members[indexPath.row - 1]
                if member.pin != User.getMyPin()! {
                    if member.pin == g.by {
                        let dataUser = User.getDataCanNil(pin: member.pin)
                        if dataUser != nil {
                            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                            controller.flag = .friend
                            controller.user = member
                            controller.name = member.fullName
                            controller.data = member.pin
                            controller.picture = member.thumb
                            self.navigationController?.show(controller, sender: nil)
                        } else {
                            print("Add friend")
                        }
                        return
                    }
                    let alert = LibAlertController(title: nil, message: "\(member.firstName) \(member.lastName)", preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: "Info".localized(), style: .default, handler: { action in
                        let data = User.getDataCanNil(pin: member.pin)
                        let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                        controller.flag = data == nil ? .invite : .friend
                        controller.user = member
                        controller.name = member.fullName
                        controller.data = member.pin
                        controller.picture = member.thumb
                        controller.isDismiss = {
                            self.reload()
                        }
                        self.navigationController?.show(controller, sender: nil)
                    }))
                    alert.addAction(UIAlertAction(title: member.position == "0" ? "Make Group Admin".localized() : "Remove Group Admin".localized(), style: member.position == "0" ? .default : .destructive, handler: { action in
                        let message = "\(member.position == "0" ? "Make" : "Remove") \(member.fullName) from the \"\(g.name)\" group Admin?"
                        let notif = LibAlertController(title: nil, message: message, preferredStyle: .actionSheet)
                        notif.addAction(UIAlertAction(title: member.position == "0" ? "Make".localized() : "Remove".localized(), style: member.position == "0" ? .default : .destructive, handler: { notifAction in
                            self.changePosition(pin: member.pin, isAdmin: member.position == "0") { result in
                                if result {
                                    DispatchQueue.main.async {
                                        tableView.beginUpdates()
                                        member.position = member.position == "1" ? "0" : "1"
                                        tableView.reloadRows(at: [indexPath], with: .none)
                                        tableView.endUpdates()
                                    }
                                }
                            }
                        }))
                        notif.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { notifAction in
                            
                        }))
                        self.navigationController?.present(notif, animated: true, completion: nil)
                    }))
                    alert.addAction(UIAlertAction(title: "Remove From Group".localized(), style: .destructive, handler: { action in
                        let message = "Remove \(member.fullName) from the \"\(g.name)\" group?"
                        let notif = LibAlertController(title: nil, message: message, preferredStyle: .actionSheet)
                        notif.addAction(UIAlertAction(title: "Remove".localized(), style: .destructive, handler: { notifAction in
                            self.exitGroup(pin: member.pin) { result in
                                if result, let index = g.members.firstIndex(of: member) {
                                    DispatchQueue.main.async {
                                        tableView.beginUpdates()
                                        tableView.deleteRows(at: [indexPath], with: .none)
                                        g.members.remove(at: index)
                                        tableView.endUpdates()
                                    }
                                }
                            }
                        }))
                        notif.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { notifAction in
                            
                        }))
                        self.navigationController?.present(notif, animated: true, completion: nil)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { action in
                        
                    }))
                    navigationController?.present(alert, animated: true)
                }
            } else if let g = group {
                let member = g.members[indexPath.row]
                if member.pin == User.getMyPin() {
                    // skip self profile
                    return
                }
                let dataUser = User.getDataCanNil(pin: member.pin)
                if dataUser != nil {
                    let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                    controller.flag = .friend
                    controller.user = member
                    controller.name = member.fullName
                    controller.data = member.pin
                    controller.picture = member.thumb
                    controller.isDismiss = {
                        self.reload()
                    }
                    self.navigationController?.show(controller, sender: nil)
                } else {
                    let alert = LibAlertController(title: nil, message: "do you want to add".localized() + " \(member.fullName) " + "as friend?".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Yes".localized(), style: .default, handler: { action in
                        self.didTapAdd(member.pin)
                    }))
                    alert.addAction(UIAlertAction(title: "No".localized(), style: .cancel, handler: nil))
                    navigationController?.present(alert, animated: true)
                }
            }
        case .exit:
            if let g = group {
                let idMe = User.getMyPin() as String?
                let admins = g.members.filter { member in
                    return member.position == "1"
                }
                var isDeleted = false
                if admins.count == 1 {
                    if admins.first?.pin == idMe {
                        isDeleted = true
                    }
                }
                let message: String
                if isDeleted {
                    message = "Are you sure want to delete the group?".localized()
//                    message = "Are you sure want to delete the \"\(g.name)\" group?".localized()
                } else {
                    message = "Are you sure want to exit the group?".localized()
//                    message = "Are you sure want to exit the \"\(g.name)\" group?".localized()
                }
                let alert = LibAlertController(title: nil, message: message, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: isDeleted ? "Delete Group".localized() : "Exit Group".localized(), style: .destructive, handler: { action in
                    self.exitGroup(pin: isDeleted ? "ALL": User.getMyPin()!) { result in
                        if result {
                            DispatchQueue.main.async {
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        }
                    }
                }))
                alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { action in
                    
                }))
                navigationController?.present(alert, animated: true)
            }
        default:
            //print("No handler..")
            break
        }
    }
    
    private func didTapAdd(_ pin: String) {
        Nexilis.showLoader()
        addFriend(pin) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                Nexilis.hideLoader { [self] in
                    if result {
                        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: Nexilis.checkingAccess(key: "friend_request_approval") ? "Friend request has been sent".localized() : "Successfully add friend".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                        banner.show()
                        self.reload()
                    } else {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Server busy, please try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                        banner.show()
                    }
                }
            })
        }
    }
    
    private func addFriend(_ pin: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            guard !self.data.isEmpty else {
                completion(false)
                return
            }
            var dataMessage = CoreMessage_TMessageBank.getAddFriendQRCode(fpin: pin)
            if Nexilis.checkingAccess(key: "friend_request_approval"){
                dataMessage = CoreMessage_TMessageBank.getAddFriendRequest(fPin: pin)
            }
            if let response = Nexilis.writeAndWait(message: dataMessage), response.isOk() {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    @objc func alertTextFieldDidChange(_ sender: UITextField) {
        if(!textFields.isEmpty){
            alert2?.actions[0].isEnabled = textFields[0].text!.trimmingCharacters(in: .whitespaces).count > 0
        }
        else {
            alert2?.actions[0].isEnabled = sender.text!.trimmingCharacters(in: .whitespaces).count > 0
        }
    }
    
    private func removeTopic(chatId: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            var result: Bool = false
            if let g = self.group, let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getDeleteChat(chat_id: chatId, f_pin: g.id)), response.isOk() {
                result = true
            }
            completion(result)
        }
    }
    
    private func changePosition(pin: String, isAdmin: Bool = true, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            var result: Bool = false
            if let g = self.group, let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangeGroupMemberPosition(p_group_id: g.id, p_pin: pin, p_position: isAdmin ? "1" : "0")), response.isOk() {
                result = true
            }
            completion(result)
        }
    }
    
    private func exitGroup(pin: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            var result: Bool = false
            if let g = self.group, let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getExitGroup(p_group_id: g.id, p_pin: pin)), response.isOk() {
                result = true
            }
            completion(result)
        }
    }
    
    private func changeOpenGroup(open: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            var result: Bool = false
            if let g = self.group, let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangeGroupInfo(p_group_id: g.id, p_open: open)), response.isOk() {
                    result = true
            } else {
                result = false
            }
            completion(result)
        }
    }
    
    private func checkIsFriend(pin: String) -> Bool {
        var isFriend = true
        Database.shared.database?.inTransaction({ fmdb, rollback in
            do {
                if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select f_pin from BUDDY where f_pin = '\(pin)'"), cursor.next() {
                    cursor.close()
                } else {
                    isFriend = false
                }
            } catch {
                rollback.pointee = true
                print("Access database error: \(error.localizedDescription)")
            }
        })
        return isFriend
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let g = group else {
            return 1
        }
        switch sections[section] {
        case .topic:
            return isAdmin ? g.topics.count + 1 : g.topics.count
        case .detail:
            return 3
        case .member:
            return isAdmin ? g.members.count + 1 : g.members.count
        default:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .description:
            return "Description".localized()
        case .topic:
            return "Topic".localized()
        case .detail:
            return "Detail".localized()
        case .member:
            return "Member".localized()
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .profile:
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath) as! ProfileCell
            cell.cover.image = UIImage(named: "Sofa", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)
            guard let g = group else {
                return cell
            }
            if let image = tempImage {
                cell.profile.image = image
            } else {
                getImage(name: g.profile, placeholderImage: UIImage(systemName: "person.2.circle.fill"), tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                    cell.profile.image = image
                }
            }
            return cell
        case .description:
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
            var content = cell.defaultContentConfiguration()
            if let g = group {
                content.text = g.quote.isEmpty ? "No description".localized() : g.quote
            }
            cell.contentConfiguration = content
            cell.selectionStyle = .default
            return cell
        case .access:
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
            var content = cell.defaultContentConfiguration()
            if let g = group {
                if g.isOpen.isEmpty || g.isOpen == "0" {
                    content.text = "Private".localized()
                    content.secondaryText = "Only members can be access this group".localized()
                } else if g.isOpen == "1" {
                    content.text = "Public".localized()
                    content.secondaryText = "All user can be access this group".localized()
                }
                if isAdmin && group?.official != "1" {
                    let changeOpen = UISwitch()
                    changeOpen.isUserInteractionEnabled = false
                    if g.isOpen == "1" {
                        changeOpen.setOn(true, animated: true)
                    } else {
                        changeOpen.setOn(false, animated: true)
                    }
                    cell.accessoryView = changeOpen
                }
            }
            content.textProperties.color = .mainColor
            cell.contentConfiguration = content
            cell.accessoryType = .none
            return cell
        case .topic:
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
            cell.accessoryView = nil
            cell.accessoryType = .none
            var content = cell.defaultContentConfiguration()
            if let g = group {
                if indexPath.row == 0, isAdmin {
                    content.image = UIImage(systemName: "plus.circle")
                    content.imageProperties.tintColor = .mainColor
                    content.text = "Add Topic".localized()
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                } else {
                    let topic = g.topics[isAdmin ? indexPath.row - 1 : indexPath.row]
                    getImage(name: topic.thumb, placeholderImage: UIImage(systemName: "message.fill"), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                        content.image = image
                        if !result {
                            content.imageProperties.tintColor = .mainColor
                        }
                    }
                    content.text = topic.title
                    content.secondaryText = topic.description
                    cell.selectionStyle = isAdmin ? .default : .none
                }
            }
            cell.contentConfiguration = content
            return cell
        case .detail:
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
            cell.accessoryView = nil
            cell.accessoryType = .none
            cell.selectionStyle = .none
            var content = cell.defaultContentConfiguration()
            content.prefersSideBySideTextAndSecondaryText = true
            if let g = group {
                switch indexPath.row {
                case 1:
                    content.text = "Created date".localized()
                    content.secondaryText = Date(milliseconds: Int64(g.date)!).format(dateFormat: "dd, MMM yyyy")
                case 2:
                    content.text = "Members".localized()
                    content.secondaryText = String(g.members.count)
                default:
                    content.text = "Created by".localized()
                    Database.shared.database?.inTransaction({ fmdb, rollback in
                        do {
                            if let cursor = Database.shared.getRecords(fmdb: fmdb, query: "select first_name || ' ' || ifnull(last_name, '') from BUDDY where f_pin = '\(g.by)'") {
                                if cursor.next() {
                                    content.secondaryText = cursor.string(forColumnIndex: 0) ?? "Unknown".localized()
                                }
                                cursor.close()
                            }
                        } catch {
                            rollback.pointee = true
                            print("Access database error: \(error.localizedDescription)")
                        }
                    })
                }
            }
            cell.contentConfiguration = content
            return cell
        case .member:
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
            cell.selectionStyle = isAdmin ? .default : .none
            cell.accessoryView = nil
            var content = cell.defaultContentConfiguration()
            content.prefersSideBySideTextAndSecondaryText = true
            if let g = group {
                if indexPath.row == 0, isAdmin {
                    content.image = UIImage(systemName: "plus.circle")
                    content.imageProperties.tintColor = .mainColor
                    content.text = "Add Member".localized()
                    cell.accessoryType = .disclosureIndicator
                } else {
                    let member = g.members[isAdmin ? indexPath.row - 1 : indexPath.row]
                    content.imageProperties.maximumSize = CGSize(width: 20, height: 20)
                    getImage(name: member.thumb, placeholderImage: UIImage(systemName: "person.fill"), isCircle: true, tableView: tableView, indexPath: indexPath) { result, isDownloaded, image in
                        content.image = image
                        if !result {
                            content.imageProperties.tintColor = .mainColor
                        }
                    }
                    if member.userType == "23" || member.official == "1" {
                        content.attributedText = self.set(image: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: " " + (member.firstName + " " + member.lastName).trimmingCharacters(in: .whitespaces), size: 15, y: 0)
                    } else if member.userType == "24" {
                        content.attributedText = self.set(image: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: " " + (member.firstName + " " + member.lastName).trimmingCharacters(in: .whitespaces), size: 15, y: 0)
                    } else {
                        content.text = (member.firstName + " " + member.lastName).trimmingCharacters(in: .whitespaces)
                    }
                    if !checkIsFriend(pin: member.pin) {
                        if member.position == "1" {
                            content.secondaryAttributedText = self.set(image: UIImage(named: "pb_twsn_group_admin_11", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, image2:  UIImage(named: "pb_add_contact", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "", size: 20, y: 0, moreImage: true)
                        } else {
                            content.secondaryAttributedText = self.set(image: UIImage(named: "pb_add_contact", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "", size: 20, y: 0)
                        }
                    } else {
                        content.secondaryAttributedText = member.position == "1" ? self.set(image: UIImage(named: "pb_twsn_group_admin_11", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, with: "", size: 20, y: 0) : NSAttributedString(string: "")
                    }
                    cell.accessoryType = .none
                }
            }
            cell.contentConfiguration = content
            return cell
        case .exit:
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
            if let g = group {
                let idMe = User.getMyPin() as String?
                let admins = g.members.filter { member in
                    return member.position == "1"
                }
                var isDeleted = false
                if admins.count == 1 {
                    if admins.first?.pin == idMe {
                        isDeleted = true
                    }
                }
                cell.accessoryView = nil
                cell.accessoryType = .none
                var content = cell.defaultContentConfiguration()
                content.text = isDeleted ? "Delete Group".localized() : "Exit Group".localized()
                content.textProperties.color = .red
                cell.contentConfiguration = content
                cell.selectionStyle = .default
                return cell
            }
            return cell
        }
    }
    
    @objc func imageAddContactTapped() {
        print("Image View Tapped")
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section] {
        case .profile:
            return 200
        default:
            return UITableView.automaticDimension
        }
    }
    
}

// MARK: - Cell

class ProfileCell: UITableViewCell {
    
    @IBOutlet weak var cover: UIImageView!
    
    @IBOutlet weak var profile: UIImageView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profile.circle()
    }
    
}

// MARK: - Extension

extension GroupDetailViewController: ImageVideoPickerDelegate {
    
    func didSelect(imagevideo: Any?) {
        if let info = imagevideo as? [UIImagePickerController.InfoKey: Any], let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileCell, let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                imageView.tintColor = .white
                let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                banner.show()
                return
            }
            guard let g = group else {
                return
            }
            
            DispatchQueue.global().async {
                let resize = image.resize(target: CGSize(width: 800, height: 600))
                let documentDir = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let fileDir = documentDir.appendingPathComponent("THUMB_\(g.id)\(Date().currentTimeMillis().toHex())")
                if !FileManager.default.fileExists(atPath: fileDir.path), let data = resize.jpegData(compressionQuality: 0.8) {
                    try! data.write(to: fileDir)
                    DispatchQueue.main.async {
                        Nexilis.showLoader()
                    }
                    Network().uploadHTTP(name: fileDir.lastPathComponent) { result, progress in
                        guard result, progress == 100 else {
                            return
                        }
                        do {
                            try FileEncryption.shared.writeSecure(filename: fileDir.lastPathComponent)
                        } catch {
                            
                        }
                        if let response = Nexilis.writeAndWait(message: CoreMessage_TMessageBank.getChangeGroupInfo(p_group_id: g.id, p_thumb_id: fileDir.lastPathComponent)), response.isOk() {
                            Database.shared.database?.inTransaction({ fmdb, rollback in
                                do {
                                    _ = Database.shared.updateRecord(fmdb: fmdb, table: "GROUPZ", cvalues: ["image_id": fileDir.lastPathComponent], _where: "group_id = '\(g.id)'")
                                    DispatchQueue.main.async {
                                        Nexilis.hideLoader(completion: {
                                            self.tempImage = image
                                            cell.profile.image = self.tempImage
                                        })
                                    }
                                } catch {
                                    rollback.pointee = true
                                    print("Access database error: \(error.localizedDescription)")
                                }
                            })
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                        } else {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                                banner.show()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func set(image: UIImage, image2: UIImage = UIImage(), with text: String, size: CGFloat, y: CGFloat, moreImage: Bool = false) -> NSAttributedString {
        let attachment = NSTextAttachment()
        let attachment2 = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: y, width: size, height: size)
        attachment2.image = image2
        attachment2.bounds = CGRect(x: 0, y: y, width: size, height: size)
        let attachmentStr = NSAttributedString(attachment: attachment)
        let attachmentStr2 = NSAttributedString(attachment: attachment2)
        
        let mutableAttributedString = NSMutableAttributedString()
        if moreImage {
            mutableAttributedString.append(attachmentStr2)
        }
        mutableAttributedString.append(attachmentStr)
        
        let textString = NSAttributedString(string: text)
        mutableAttributedString.append(textString)
        
        return mutableAttributedString
    }
}
