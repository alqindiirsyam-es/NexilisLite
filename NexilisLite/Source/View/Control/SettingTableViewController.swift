//
//  SettingTableViewController.swift
//  Qmera
//
//  Created by Yayan Dwi on 16/09/21.
//

import UIKit
import NotificationBannerSwift
import nuSDKService
import Photos

public class SettingTableViewController: UITableViewController, UIGestureRecognizerDelegate {
    
    var language: [[String: String]] = [["Indonesia": "id"],["English": "en"]]
    var fontSizeSelection: [[String: String]] = [["Small": "0"],["Medium": "4"],["Large": "6"]]
    var alert: UIAlertController?
    var textFields = [UITextField]()
    var languagePickerView = UIPickerView()
    var fontSizePickerView = UIPickerView()
    
    var switchVibrateMode = UISwitch()
    var switchSaveToGallery = UISwitch()
    var switchAutoDownload = UISwitch()
    
    var notInTab = false
    
    var fromAPI = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.view.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .black : .white
        self.navigationController?.navigationBar.topItem?.backButtonTitle = ""
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.layoutMargins = .init(top: 0, left: 0, bottom: 0, right: 0)
//        tableView.separatorColor = .gray
        tableView.separatorStyle = .none
        
        if fromAPI {
            let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(self.didTapExit))
            self.navigationItem.leftBarButtonItem = backButton
        }
        
        switchVibrateMode.tintColor = .gray
        switchSaveToGallery.tintColor = .gray
        switchAutoDownload.tintColor = .gray
        switchVibrateMode.onTintColor = .mainColor
        switchSaveToGallery.onTintColor = .mainColor
        switchAutoDownload.onTintColor = .mainColor
        let vibrateMode: Bool = SecureUserDefaults.shared.value(forKey: "vibrateMode") ?? false
        let saveGallery: Bool = SecureUserDefaults.shared.value(forKey: "saveToGallery") ?? false
        let autoDownload: Bool = SecureUserDefaults.shared.value(forKey: "autoDownload") ?? false
        if vibrateMode {
            switchVibrateMode.setOn(true, animated: false)
        }
        if saveGallery {
            switchSaveToGallery.setOn(true, animated: false)
        }
        if autoDownload {
            switchAutoDownload.setOn(true, animated: false)
        }
        switchVibrateMode.addTarget(self, action: #selector(vibrateModeSwitch), for: .valueChanged)
        switchSaveToGallery.addTarget(self, action: #selector(saveToGallerySwitch), for: .valueChanged)
        switchAutoDownload.addTarget(self, action: #selector(autoDownloadSwitch), for: .valueChanged)
    }
    
    @objc func didTapExit() {
        self.dismiss(animated: true)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.topItem?.title = "Settings".localized()
        self.navigationController?.navigationBar.setNeedsLayout()
    }
    
    @objc func vibrateModeSwitch() {
        SecureUserDefaults.shared.set(switchVibrateMode.isOn, forKey: "vibrateMode")
    }
    
    @objc func saveToGallerySwitch() {
        if switchSaveToGallery.isOn {
            PHPhotoLibrary.requestAuthorization({status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        SecureUserDefaults.shared.set(self.switchSaveToGallery.isOn, forKey: "saveToGallery")
                    } else {
                        self.switchSaveToGallery.setOn(false, animated: true)
                    }
                }
            })
        } else {
            SecureUserDefaults.shared.set(self.switchSaveToGallery.isOn, forKey: "saveToGallery")
        }
    }
    
    @objc func autoDownloadSwitch() {
        SecureUserDefaults.shared.set(switchAutoDownload.isOn, forKey: "autoDownload")
    }
    
    func makeMenu(imageSignIn: String = ""){
        let isChangeProfile = Utils.getSetProfile()
        if Database.shared.database == nil {
            Item.menus["Personal"] = [
                Item(icon: UIImage(systemName: "person"), title: "Personal Information".localized()),
                Item(icon: UIImage(systemName: "arrow.up.and.person.rectangle.portrait"), title: "Sign-Up/Sign-In".localized()),
            ]
        } else {
            Database.shared.database?.inTransaction({ fmdb, rollback in
                do {
                    let idMe = User.getMyPin() as String?
                    if let cursorUser = Database.shared.getRecords(fmdb: fmdb, query: "SELECT user_type, image_id, official_account FROM BUDDY where f_pin='\(idMe!)'"), cursorUser.next() {
                        if (User.isInternal(userType: cursorUser.string(forColumnIndex: 0) ?? "") && User.isAdmin(fmdb: fmdb)) || User.isOfficial(official_account: cursorUser.string(forColumnIndex: 2) ?? "") || User.isOfficial(official_account: cursorUser.string(forColumnIndex: 2) ?? "") {
                            Item.menus["Personal"] = [
                                Item(icon: UIImage(systemName: "person"), title: "Personal Information".localized()),
                                Item(icon: UIImage(systemName: "textformat.abc"), title: "Change Language".localized()),
                                Item(icon: UIImage(systemName: "textformat.size"), title: "Chat Font Size".localized()),
                                Item(icon: UIImage(systemName: "photo"),
                                     title: "Chat Wallpaper".localized()),
                                Item(icon: UIImage(systemName: "lock"), title: "Secure Folder"),
//                                Item(icon: UIImage(systemName: "person.crop.rectangle"), title: "Change Admin / Internal Password".localized()),
                                Item(icon: UIImage(systemName: "laptopcomputer.and.iphone"), title: "Sign-In to Web".localized()),
//                                Item(icon: UIImage(named: "ic_internal", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, title: "Set Internal Account".localized()),
                                Item(icon: UIImage(named: "pb_call_center", in: Bundle.resourceBundle(for: Nexilis.self), with: nil)!, title: "Set CS Account".localized()),
                            ]
                        } else if User.isInternal(userType: cursorUser.string(forColumnIndex: 0) ?? "") || User.isCallCenter(userType: cursorUser.string(forColumnIndex: 0) ?? "") || User.isVerified(official_account: cursorUser.string(forColumnIndex: 2) ?? "") {
                            Item.menus["Personal"] = [
                                Item(icon: UIImage(systemName: "person"), title: "Personal Information".localized()),
                                Item(icon: UIImage(systemName: "textformat.abc"), title: "Change Language".localized()),
                                Item(icon: UIImage(systemName: "textformat.size"), title: "Chat Font Size".localized()),
                                Item(icon: UIImage(systemName: "photo"),
                                     title: "Chat Wallpaper".localized()),
                                Item(icon: UIImage(systemName: "lock"), title: "Secure Folder"),
                                Item(icon: UIImage(systemName: "laptopcomputer.and.iphone"), title: "Sign-In to Web".localized()),
                            ]
                        } else {
                            Item.menus["Personal"] = [
                                Item(icon: UIImage(systemName: "person"), title: "Personal Information".localized()),
                                    Item(icon: UIImage(systemName: "textformat.abc"), title: "Change Language".localized()),
                                Item(icon: UIImage(systemName: "textformat.size"), title: "Chat Font Size".localized()),
                                Item(icon: UIImage(systemName: "photo"),
                                     title: "Chat Wallpaper".localized()),
                                Item(icon: UIImage(systemName: "lock"), title: "Secure Folder"),
//                                Item(icon: UIImage(systemName: "person.badge.key"), title: "Access Admin / Internal Features".localized()),
                            ]
                        }
                        if !isChangeProfile {
                            Item.menus["Personal"]?.append(Item(icon: UIImage(systemName: "arrow.up.and.person.rectangle.portrait"), title: "Sign-Up/Sign-In".localized()))
                        } else if isChangeProfile {
                            if Nexilis.checkingAccess(key: "backup_restore") {
                                Item.menus["Personal"]?.append(Item(icon: UIImage(systemName: "arrow.clockwise.icloud"), title: "Backup & Restore".localized()))
                            }
                            if Utils.getLimitValidTrans() == "1" {
                                Item.menus["Personal"]?.insert(Item(icon: UIImage(systemName: "lessthan.circle"), title: "Validation Transaction Limit".localized()), at: 1)
                            }
                        }
                        let image = cursorUser.string(forColumnIndex: 1)
                        if image != nil {
                            if !image!.isEmpty {
                                do {
                                    let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                    let file = documentDir.appendingPathComponent(image!)
                                    if FileManager().fileExists(atPath: file.path) {
                                        let image = UIImage(contentsOfFile: file.path)
                                        Item.menus["Personal"]?[0].icon = image?.circleMasked
                                        if !imageSignIn.isEmpty {
                                            var dataImage: [AnyHashable : Any] = [:]
                                            dataImage["name"] = imageSignIn
                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                                        }
                                    } else if FileEncryption.shared.isSecureExists(filename: imageSignIn) {
                                        do {
                                            if var data = try FileEncryption.shared.readSecure(filename: imageSignIn) {
                                                let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                                if dataDecrypt != nil {
                                                    data = dataDecrypt!
                                                }
                                                let image = UIImage(data: data)
                                                Item.menus["Personal"]?[0].icon = image?.circleMasked
                                                if !imageSignIn.isEmpty {
                                                    var dataImage: [AnyHashable : Any] = [:]
                                                    dataImage["name"] = imageSignIn
                                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                                                }
                                            }
                                        } catch {
                                            
                                        }
                                    } else {
                                        Download().start(forKey: image!) { (name, progress) in
                                            guard progress == 100 else {
                                                return
                                            }

                                            DispatchQueue.main.async {
                                                if FileEncryption.shared.isSecureExists(filename: imageSignIn) {
                                                    do {
                                                        if var data = try FileEncryption.shared.readSecure(filename: imageSignIn) {
                                                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                                            if dataDecrypt != nil {
                                                                data = dataDecrypt!
                                                            }
                                                            let image = UIImage(data: data)
                                                            Item.menus["Personal"]?[0].icon = image?.circleMasked
                                                            if !imageSignIn.isEmpty {
                                                                var dataImage: [AnyHashable : Any] = [:]
                                                                dataImage["name"] = imageSignIn
                                                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                                                            }
                                                        }
                                                    } catch {
                                                        
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } catch {}
                            }
                        }
                        cursorUser.close()
                    } else {
                        Item.menus["Personal"] = [
                            Item(icon: UIImage(systemName: "person"), title: "Personal Information".localized()),
                                Item(icon: UIImage(systemName: "textformat.abc"), title: "Change Language".localized()),
                            Item(icon: UIImage(systemName: "textformat.size"), title: "Chat Font Size".localized()),
                            Item(icon: UIImage(systemName: "photo"),
                                 title: "Chat Wallpaper".localized()),
                            Item(icon: UIImage(systemName: "lock"), title: "Secure Folder"),
//                            Item(icon: UIImage(systemName: "person.badge.key"), title: "Access Admin / Internal Features".localized()),
                        ]
                        Item.menus["Personal"]?.append(Item(icon: UIImage(systemName: "arrow.up.and.person.rectangle.portrait"), title: "Sign-Up/Sign-In".localized()))
                        if !imageSignIn.isEmpty {
                            do {
                                let documentDir = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                                let file = documentDir.appendingPathComponent(imageSignIn)
                                if FileManager().fileExists(atPath: file.path) {
                                    let image = UIImage(contentsOfFile: file.path)
                                    Item.menus["Personal"]?[0].icon = image?.circleMasked
                                    var dataImage: [AnyHashable : Any] = [:]
                                    dataImage["name"] = imageSignIn
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                                } else if FileEncryption.shared.isSecureExists(filename: imageSignIn) {
                                    do {
                                        if var data = try FileEncryption.shared.readSecure(filename: imageSignIn) {
                                            let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                            if dataDecrypt != nil {
                                                data = dataDecrypt!
                                            }
                                            let image = UIImage(data: data)
                                            Item.menus["Personal"]?[0].icon = image?.circleMasked
                                            if !imageSignIn.isEmpty {
                                                var dataImage: [AnyHashable : Any] = [:]
                                                dataImage["name"] = imageSignIn
                                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                                            }
                                        }
                                    } catch {
                                        
                                    }
                                } else {
                                    Download().start(forKey: imageSignIn) { (name, progress) in
                                        guard progress == 100 else {
                                            return
                                        }
                                        DispatchQueue.main.async {
                                            if FileEncryption.shared.isSecureExists(filename: imageSignIn) {
                                                do {
                                                    if var data = try FileEncryption.shared.readSecure(filename: imageSignIn) {
                                                        let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                                                        if dataDecrypt != nil {
                                                            data = dataDecrypt!
                                                        }
                                                        let image = UIImage(data: data)
                                                        Item.menus["Personal"]?[0].icon = image?.circleMasked
                                                        if !imageSignIn.isEmpty {
                                                            var dataImage: [AnyHashable : Any] = [:]
                                                            dataImage["name"] = imageSignIn
                                                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                                                        }
                                                    }
                                                } catch {
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch {}
                        }
                    }
                } catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        }
        
        Item.menus["Config"] = [
            Item(icon: UIImage(systemName: "iphone"), title: "Create Your Own App".localized()),
            Item(icon: UIImage(systemName: "gearshape.circle"), title: "Configure Floating Button".localized())
        ]
        if !isChangeProfile || Utils.getEnableMobileBuilder() != "1" {
            if Item.menus["Config"]!.count > 1 {
                Item.menus["Config"]!.remove(at: 0)
            } else {
                Item.menus["Config"]!.removeAll()
            }
        }
        if !Nexilis.showButtonFB || !Nexilis.checkingAccess(key: "can_config_fb") {
            if Item.menus["Config"]!.count > 1 {
                Item.menus["Config"]!.remove(at: 1)
            } else {
                Item.menus["Config"]!.removeAll()
            }
        }
        if Utils.getIsLoadThemeFromOther() {
            Item.menus["Config"]?.insert(Item(icon: UIImage(systemName: "iphone"), title: "Back to Company App".localized()), at: 1)
        }
        
        Item.menus["Call"] = [
            Item(icon: UIImage(systemName: "message"), title: "Notification Message(s)".localized()),
            Item(icon: UIImage(systemName: "message"), title: "Notification Message(s) Group".localized()),
            Item(icon: UIImage(systemName: "iphone.homebutton.radiowaves.left.and.right"), title: "Vibrate Mode".localized()),
            Item(icon: UIImage(systemName: "photo.on.rectangle.angled"), title: "Save to Gallery".localized()),
            Item(icon: UIImage(systemName: "arrow.down.square"), title: "Auto Download".localized()),
        ]
        Item.menus["Version"] = [
            Item(icon: UIImage(systemName: "gear"), title: "Version".localized()),
            Item(icon: UIImage(named: "pb_powered_button", in: Bundle.resourceBundle(for: Nexilis.self), with: nil), title: "Powered by Nexilis".localized()),
        ]
        if isChangeProfile {
            if Nexilis.checkingAccess(key: "logout"){
                Item.menus["Version"]?.insert(Item(icon: UIImage(systemName: "rectangle.portrait.and.arrow.right"), title: "Sign-Out".localized()), at: 0)
            }
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
//        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black]
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: self.traitCollection.userInterfaceStyle == .dark ? .white : UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.overrideUserInterfaceStyle = self.traitCollection.userInterfaceStyle == .dark ? .dark : .light
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        tabBarController?.navigationItem.leftBarButtonItem = nil
        tabBarController?.navigationItem.searchController = nil
        tabBarController?.navigationItem.rightBarButtonItem = nil
        makeMenu()
    }
    
    // MARK: - Table view data source
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return Item.sections.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Item.menuFor(section: section).count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        let isChangeProfile = Utils.getSetProfile()
        cell.accessoryType = .none
        cell.indentationLevel = 0
        var content = cell.defaultContentConfiguration()
        content.textProperties.font = UIFont.systemFont(ofSize: 14)
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 14)
        content.secondaryTextProperties.color = .gray
        content.prefersSideBySideTextAndSecondaryText = true
        let section = Item.sections[indexPath.section]
        if let arr = Item.menus[section] {
            let menu = arr[indexPath.row]
            content.image = menu.icon
            content.imageProperties.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .black
            content.imageProperties.maximumSize = CGSize(width: 24, height: 24)
            content.text = menu.title
            cell.accessoryView = nil
            switch menu.title {
            case "Personal Information".localized():
                cell.accessoryType = .disclosureIndicator
            case "Secure Folder".localized():
                cell.accessoryType = .disclosureIndicator
            case "Access Admin / Internal Features".localized():
                cell.accessoryType = .disclosureIndicator
            case "Sign-In to Web".localized():
                cell.accessoryType = .disclosureIndicator
            case "Sign-Up/Sign-In".localized():
                cell.accessoryType = .disclosureIndicator
            case "Configure Floating Button".localized():
                cell.accessoryType = .disclosureIndicator
            case "Notification Message(s)".localized():
                cell.accessoryType = .disclosureIndicator
            case "Backup & Restore".localized():
                cell.accessoryType = .disclosureIndicator
            case "Validation Transaction Limit".localized():
                cell.accessoryType = .disclosureIndicator
            case "Create Your Own App".localized():
                cell.accessoryType = .disclosureIndicator
            case "Notification Message(s) Group".localized():
                cell.accessoryType = .disclosureIndicator
            case "Change Admin / Internal Password".localized():
                cell.accessoryType = .disclosureIndicator
            case "Change Language".localized():
                cell.accessoryType = .disclosureIndicator
            case "Chat Font Size".localized():
                cell.accessoryType = .disclosureIndicator
            case "Chat Wallpaper".localized():
                cell.accessoryType = .disclosureIndicator
            case "Set Internal Account".localized():
                cell.accessoryType = .disclosureIndicator
            case "Set CS Account".localized():
                cell.accessoryType = .disclosureIndicator
            case "Version".localized():
                let accessoryButton = UIButton(type: .custom)
                accessoryButton.setTitle(UIApplication.appVersion, for: .normal)
                accessoryButton.setTitleColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .black, for: .normal)
                accessoryButton.titleLabel?.font = .systemFont(ofSize: 18)
                accessoryButton.contentHorizontalAlignment = .right
                accessoryButton.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
                accessoryButton.contentMode = .scaleAspectFit
                cell.accessoryView = accessoryButton as UIView
            case "Vibrate Mode".localized():
                cell.accessoryView = switchVibrateMode
            case "Save to Gallery".localized():
                cell.accessoryView = switchSaveToGallery
            case "Auto Download".localized():
                cell.accessoryView = switchAutoDownload
            default:
                content.secondaryText = nil
            }
        }
        cell.contentConfiguration = content
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        if section != 3 {
            footerView.backgroundColor = .clear
            
            let lineView = UIView()
            lineView.backgroundColor = .gray
            lineView.translatesAutoresizingMaskIntoConstraints = false
            footerView.addSubview(lineView)
            
            NSLayoutConstraint.activate([
                lineView.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
                lineView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
                lineView.heightAnchor.constraint(equalToConstant: 1),
                lineView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor)
            ])
        }
        return footerView
    }
    
    public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        if (section == 2 && Item.menus["Config"]!.count > 0) || section == 3 || (section == 1 && Item.menus["Config"]!.count > 0) {
            headerView.backgroundColor = .clear
            
            let lineView = UIView()
            lineView.backgroundColor = .gray
            lineView.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(lineView)
            
            NSLayoutConstraint.activate([
                lineView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
                lineView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
                lineView.heightAnchor.constraint(equalToConstant: 1),
                lineView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
            ])
        }
        return headerView
    }
    
    public override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 || section == 3 || section == 1 {
            return 6
        }
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = Item.menuFor(section: indexPath.section)[indexPath.row]
        if item.title == "Personal Information".localized() {
            if(Nexilis.checkIsChangePerson()){
                let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "profileView") as! ProfileViewController
                controller.data = User.getMyPin()!
                controller.flag = .me
                controller.dismissImage = { image, imageName in
                    var dataImage: [AnyHashable : Any] = [:]
                    dataImage["name"] = imageName
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                    self.makeMenu()
                    self.tableView.reloadData()
                }
                navigationController?.show(controller, sender: nil)
            }
        } else if item.title == "Secure Folder" {
            APIS.openSecureFolder()
        } else if item.title == "Access Admin / Internal Features".localized() || item.title == "Change Admin / Internal Password".localized() {
            if(Nexilis.checkIsChangePerson()){
                if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                let alertController = LibAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                if(item.title.contains("Change")){
                    if let action = self.actionChangePassword(for: "admin", title: "Change Admin Password".localized()) {
                        alertController.addAction(action)
                    }
                    if let action = self.actionChangePassword(for: "internal", title: "Change Internal Password".localized()) {
                        alertController.addAction(action)
                    }
                }
                else {
                    if let action = self.actionLogin(for: "admin", title: "Access Admin Features".localized()) {
                        alertController.addAction(action)
                    }
                    if let action = self.actionLogin(for: "internal", title: "Access Internal Features".localized()) {
                        alertController.addAction(action)
                    }
                }
                alertController.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                self.present(alertController, animated: true)
            }
        } else if item.title == "Change Language".localized() {
            let vc = UIViewController()
            vc.preferredContentSize = CGSize(width: UIScreen.main.bounds.width - 10, height: 150)
            languagePickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 10, height: 150))
            languagePickerView.dataSource = self
            languagePickerView.delegate = self
            
            let lang: String = SecureUserDefaults.shared.value(forKey: "i18n_language") ?? "en"
            var index = 1
            if lang == "id" {
                index = 0
            }
            languagePickerView.selectRow(index, inComponent: 0, animated: false)
            
            vc.view.addSubview(languagePickerView)
            languagePickerView.translatesAutoresizingMaskIntoConstraints = false
            languagePickerView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
            languagePickerView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
            
            let alert = LibAlertController(title: "Select Language".localized(), message: "", preferredStyle: .actionSheet)
            
            alert.setValue(vc, forKey: "contentViewController")
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (UIAlertAction) in
            }))
            
            alert.addAction(UIAlertAction(title: "Select".localized(), style: .default, handler: { (UIAlertAction) in
                let selectedIndex = self.languagePickerView.selectedRow(inComponent: 0)
                let lang = self.language[selectedIndex].values.first
                SecureUserDefaults.shared.set(lang, forKey: "i18n_language")
                self.navigationController?.navigationBar.topItem?.title = "Settings".localized();
                self.navigationController?.navigationBar.setNeedsLayout()
                self.makeMenu()
                self.tableView.reloadData()
            }))
            self.present(alert, animated: true, completion: nil)
        } else if item.title == "Chat Font Size".localized() {
            let vc = UIViewController()
            vc.preferredContentSize = CGSize(width: UIScreen.main.bounds.width - 10, height: 150)
            fontSizePickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 10, height: 150))
            fontSizePickerView.dataSource = self
            fontSizePickerView.delegate = self
            
            let fontSize: String = SecureUserDefaults.shared.value(forKey: "font_size") ?? "0"
            var index = 0
            if fontSize == "4" {
                index = 1
            }
            else if fontSize == "6"{
                index = 2
            }
            fontSizePickerView.selectRow(index, inComponent: 0, animated: false)
            
            vc.view.addSubview(fontSizePickerView)
            fontSizePickerView.translatesAutoresizingMaskIntoConstraints = false
            fontSizePickerView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
            fontSizePickerView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
            
            let alert = LibAlertController(title: "Select Font Size".localized(), message: "", preferredStyle: .actionSheet)
            
            alert.setValue(vc, forKey: "contentViewController")
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (UIAlertAction) in
            }))
            
            alert.addAction(UIAlertAction(title: "Select".localized(), style: .default, handler: { (UIAlertAction) in
                let selectedIndex = self.fontSizePickerView.selectedRow(inComponent: 0)
                let lang = self.fontSizeSelection[selectedIndex].values.first
                SecureUserDefaults.shared.set(lang, forKey: "font_size")
                self.navigationController?.navigationBar.topItem?.title = "Settings".localized();
                self.navigationController?.navigationBar.setNeedsLayout()
                self.makeMenu()
                self.tableView.reloadData()
            }))
            self.present(alert, animated: true, completion: nil)
        } else if item.title == "Chat Wallpaper".localized() {
            APIS.openChatWallpaper()
        } else if item.title == "Sign-In".localized() {
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "changeDevice") as! ChangeDeviceViewController
            controller.isDismiss = { newThumb in
                self.makeMenu(imageSignIn: newThumb)
                self.tableView.reloadData()
            }
            navigationController?.show(controller, sender: nil)
        } else if item.title == "Sign-Up/Sign-In".localized() {
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "signupsignin") as! SignUpSignIn
            controller.isDismiss = { newThumb in
                self.makeMenu(imageSignIn: newThumb)
                self.tableView.reloadData()
            }
            navigationController?.show(controller, sender: nil)
        } else if item.title == "Sign-Out".localized() {
            let alert = LibAlertController(title: "Sign-Out".localized(), message: "Are you sure want to logout?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: .destructive, handler: {(_) in
                if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                Nexilis.showLoader()
                DispatchQueue.global().async {
                    let apiKey = Nexilis.sAPIKey
                    var id = Utils.getConnectionID()
                    if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignUpApi(api: apiKey, p_pin: id), timeout: 30 * 1000) {
                        id = response.getBody(key: CoreMessage_TMessageKey.F_PIN, default_value: "")
                        if(!id.isEmpty){
//                            Nexilis.changeUser(f_pin: id)
                            SecureUserDefaults.shared.set(id, forKey: "me")
                            APIS.sendPushToken(Utils.getTokenAPN(), isResend: true)
                            Nexilis.sendVersionToBE()
                            Utils.setProfile(value: false)
                            if Utils.getForceAnonymous() {
                                self.deleteAllRecordDatabase()
                                SecureUserDefaults.shared.removeValue(forKey: "device_id")
//                                FileEncryption.shared.wipeFolder()
                                Nexilis.destroyAll()
                                _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: id))
                            }
                            DispatchQueue.main.async {
                                Nexilis.hideLoader(completion: {
                                    let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Successfully Sign-Out".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                    banner.show()
                                    if Nexilis.showFB {
                                        Nexilis.floatingButton.removeFromSuperview()
                                        Nexilis.floatingButton = FloatingButton()
                                        let viewController = (UIApplication.shared.windows.first?.rootViewController)!
                                        Nexilis.addFB(viewController: viewController, fromMAB: true)
                                    }
                                    var dataImage: [AnyHashable : Any] = [:]
                                    dataImage["name"] = ""
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "imageFBUpdate"), object: nil, userInfo: dataImage)
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTabChats"), object: nil, userInfo: nil)
                                    self.makeMenu()
                                    self.tableView.reloadData()
                                    
                                    if !Utils.getForceAnonymous() {
                                        Nexilis.showForceSignIn()
                                    }
                                })
                            }
                        } else {
                            DispatchQueue.main.async {
                                Nexilis.hideLoader(completion: {
                                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                    banner.show()
                                })
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            Nexilis.hideLoader(completion: {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                banner.show()
                            })
                        }
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else if item.title == "Sign-In to Web".localized() {
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
            let controller = ScannerViewController()
            let navigationController = CustomNavigationController(rootViewController: controller)
            navigationController.navigationBar.tintColor = .white
            navigationController.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
            navigationController.navigationBar.isTranslucent = false
            let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            navigationController.navigationBar.titleTextAttributes = textAttributes
            navigationController.navigationBar.overrideUserInterfaceStyle = .dark
            navigationController.navigationBar.barStyle = .black
            navigationController.modalPresentationStyle = .custom
            self.present(navigationController, animated: true)
        } else if item.title == "Notification Message(s)".localized() || item.title == "Notification Message(s) Group".localized() {
            let controller = NotificationSound()
            if item.title != "Notification Message(s)".localized() {
                controller.isPersonal = false
            }
            let navigationController = CustomNavigationController(rootViewController: controller)
            navigationController.navigationBar.tintColor = .white
            navigationController.navigationBar.barTintColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : .mainColor
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.overrideUserInterfaceStyle = .dark
            navigationController.navigationBar.barStyle = .black
            let cancelButtonAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
            UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            navigationController.navigationBar.titleTextAttributes = textAttributes
            self.present(navigationController, animated: true)
        } else if item.title == "Backup & Restore".localized() {
            let controller = AppStoryBoard.Palio.instance.instantiateViewController(withIdentifier: "backupRestore") as! BackupRestoreView
            navigationController?.show(controller, sender: nil)
        } else if item.title == "Set Internal Account".localized() {
            let controller = SetInternalCSAccount()
            navigationController?.show(controller, sender: nil)
        } else if item.title == "Set CS Account".localized() {
            let controller = SetInternalCSAccount()
            controller.isSetCS = true
            navigationController?.show(controller, sender: nil)
        } else if item.title == "Configure Floating Button".localized() {
            let viewConfigureFB = ConfigureFloatingButton()
            viewConfigureFB.modalTransitionStyle = .crossDissolve
            viewConfigureFB.modalPresentationStyle = .custom
            self.present(viewConfigureFB, animated: true)
        } else if item.title == "Validation Transaction Limit".localized() {
            let controller = ValidationTransactionLimit()
            navigationController?.show(controller, sender: nil)
        } else if item.title == "Create Your Own App".localized() {
            let controller = BNIBookingWebView()
            controller.customUrl = Utils.getURLBase() + "mobile_MAB?f_pin="
            self.present(controller, animated: true)
        } else if item.title == "Back to Company App".localized() {
            let alert = LibAlertController(title: "", message: "Are you sure want to back to company app?".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertAction.Style.default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes".localized(), style: .destructive, handler: {(_) in
                if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                Nexilis.showLoader()
                DispatchQueue.global().async {
                    if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.backToSuperApp(), timeout: 30 * 1000) {
                        DispatchQueue.main.async {
                            if response.isOk() {
                                Utils.setMyTheme(value: "")
                                Utils.setIsLoadThemeFromOther(value: false)
                                Utils.resetValueSuperApp()
                                Utils.setValueInitialApp(data: Utils.getPrefTheme())
                                Database.shared.database?.inTransaction({ fmdb, rollback in
                                    do {
                                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ", _where: "")
                                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "GROUPZ_MEMBER", _where: "")
                                        _ = Database.shared.deleteRecord(fmdb: fmdb, table: "DISCUSSION_FORUM", _where: "")
                                        _ = Nexilis.write(message: CoreMessage_TMessageBank.getPostRegistration(p_pin: User.getMyPin() ?? ""))
                                    } catch {
                                        rollback.pointee = true
                                        print("Access database error: \(error.localizedDescription)")
                                    }
                                })
                                Nexilis.hideLoader {
                                    let alert = LibAlertController(title: "Successfully changed".localized(), message: "Please open the app again to see the changes".localized(), preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: {(_) in
                                        exit(0)
                                    }))
                                    self.present(alert, animated: true, completion: nil)
                                }
                            } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "10" {
                                Nexilis.hideLoader(completion: {
                                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Failed to back to Company App".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                    banner.show()
                                })
                            } else {
                                Nexilis.hideLoader(completion: {
                                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                    banner.show()
                                })
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            Nexilis.hideLoader(completion: {
                                let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Unable to access servers. Try again later".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                                banner.show()
                            })
                        }
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else if item.title == "Version".localized() {
            let alert = LibAlertController(title: "Version".localized(), message: API.sGetVersion() + "\nConnection: \(API.nGetCLXConnState() == 1)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss".localized(), style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func actionLogin(for type: String, title: String) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .default) { _ in
            self.alert = LibAlertController(title:"Access Admin Features".localized(), message: nil, preferredStyle: .alert)
            if type == "internal" {
                self.alert = LibAlertController(title: "Access Internal Features".localized(), message: nil, preferredStyle: .alert)
            }
            self.textFields.removeAll()
            self.alert?.addTextField{ (texfield) in
                texfield.placeholder = "Password".localized()
                texfield.isSecureTextEntry = true
                texfield.addPadding(.right(40))
                texfield.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
                
                let buttonHideUnhide = UIButton()
                buttonHideUnhide.tag = 0
                texfield.addSubview(buttonHideUnhide)
                buttonHideUnhide.anchor(top: texfield.topAnchor, right: texfield.rightAnchor, paddingTop: -7, width: 30, height: 30)
                buttonHideUnhide.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
                buttonHideUnhide.tintColor = .black
                buttonHideUnhide.addTarget(self, action: #selector(self.showPassword), for: .touchUpInside)
            }
            let submitAction = UIAlertAction(title: "Sign-In".localized(), style: .default, handler: { (action) -> Void in
                let textField = self.alert?.textFields![0]
                if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                Nexilis.showLoader()
                if type == "admin" {
                    self.signInAdmin(password: textField!.text!, completion: { result in
                        if result {
                            DispatchQueue.main.async {
                                Nexilis.hideLoader {
                                    self.makeMenu()
                                    self.tableView.reloadData()
                                    let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Successfully Sign-In Admin".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                    banner.show()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                Nexilis.hideLoader {}
                            }
                        }
                    })
                } else {
                    self.signInInternal(password: textField!.text!, completion: { result in
                        if result {
                            DispatchQueue.main.async {
                                Nexilis.hideLoader {
                                    self.makeMenu()
                                    self.tableView.reloadData()
                                    let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                    imageView.tintColor = .white
                                    let banner = FloatingNotificationBanner(title: "Successfully Sign-In Internal Team".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                    banner.show()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                Nexilis.hideLoader {}
                            }
                        }
                    })
                }
            })
            submitAction.isEnabled = false
            self.alert?.addAction(submitAction)
            self.alert?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            
            self.present(self.alert!, animated: true, completion: nil)
        }
    }
    
    private func actionChangePassword(for type: String, title: String) -> UIAlertAction? {
        return UIAlertAction(title: title, style: .default) { _ in
            self.alert = LibAlertController(title: "Change Admin Password".localized(), message: nil, preferredStyle: .alert)
            if type == "internal" {
                self.alert = LibAlertController(title: "Change Internal Password".localized(), message: nil, preferredStyle: .alert)
            }
            self.textFields.removeAll()
            self.alert?.addTextField{ (texfield) in
                texfield.placeholder = "Old Password"
                texfield.isSecureTextEntry = true
                texfield.addPadding(.right(40))
                texfield.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
                self.textFields.append(texfield)
                
                let buttonHideUnhide = UIButton()
                buttonHideUnhide.tag = 0
                texfield.addSubview(buttonHideUnhide)
                buttonHideUnhide.anchor(top: texfield.topAnchor, right: texfield.rightAnchor, paddingTop: -7, width: 30, height: 30)
                buttonHideUnhide.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
                buttonHideUnhide.tintColor = .black
                buttonHideUnhide.addTarget(self, action: #selector(self.showPassword), for: .touchUpInside)
            }
            self.alert?.addTextField{ (texfield) in
                texfield.placeholder = "New Password"
                texfield.isSecureTextEntry = true
                texfield.addPadding(.right(40))
                texfield.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: UIControl.Event.editingChanged)
                self.textFields.append(texfield)
                
                let buttonHideUnhide = UIButton()
                buttonHideUnhide.tag = 1
                texfield.addSubview(buttonHideUnhide)
                buttonHideUnhide.anchor(top: texfield.topAnchor, right: texfield.rightAnchor, paddingTop: -7, width: 30, height: 30)
                buttonHideUnhide.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
                buttonHideUnhide.tintColor = .black
                buttonHideUnhide.addTarget(self, action: #selector(self.showPassword), for: .touchUpInside)
            }
            let submitAction = UIAlertAction(title: "Change Password".localized(), style: .default, handler: { (action) -> Void in
                let textFieldOld = self.alert?.textFields![0]
                let textFieldNew = self.alert?.textFields![1]
                if !CheckConnection.isConnectedToNetwork()  || API.nGetCLXConnState() == 0 {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Check your connection".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .center)
                    banner.show()
                    return
                }
                if type == "admin" {
                    self.changePasswordAdmin(oldPassword: textFieldOld!.text!, newPassword: textFieldNew!.text!, completion: { result in
                        if result {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Admin password changed successfully".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                        }
                    })
                } else {
                    self.changePasswordInternal(oldPassword: textFieldOld!.text!, newPassword: textFieldNew!.text!, completion: { result in
                        if result {
                            DispatchQueue.main.async {
                                let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
                                imageView.tintColor = .white
                                let banner = FloatingNotificationBanner(title: "Internal password changed successfully".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .success, colors: nil, iconPosition: .center)
                                banner.show()
                            }
                        }
                    })
                }
            })
            submitAction.isEnabled = false
            self.alert?.addAction(submitAction)
            self.alert?.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
            
            self.present(self.alert!, animated: true, completion: nil)
        }
    }
    
    @objc func showPassword(_ sender:UIButton) {
        if alert!.textFields![sender.tag].isSecureTextEntry {
            alert!.textFields![sender.tag].isSecureTextEntry = false
            let buttonImage = alert!.textFields![sender.tag].subviews[0] as! UIButton
            buttonImage.setImage(UIImage(systemName: "eye.fill"), for: .normal)
        } else {
            alert!.textFields![sender.tag].isSecureTextEntry = true
            let buttonImage = alert!.textFields![sender.tag].subviews[0] as! UIButton
            buttonImage.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        }
    }
    
    @objc func alertTextFieldDidChange(_ sender: UITextField) {
        if(!textFields.isEmpty){
            //print("text count 0: \(textFields[0].text!.count)")
            //print("text count 1: \(textFields[1].text!.count)")
            alert?.actions[0].isEnabled = textFields[0].text!.count > 0 && textFields[1].text!.count > 0
        }
        else {
            alert?.actions[0].isEnabled = sender.text!.count > 0
        }
    }
    
    private func signInAdmin(password: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            let idMe = User.getMyPin() as String?
            let p_password = password
            let md5Hex = p_password
            var result: Bool = false
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignInApiAdmin(p_name: idMe!, p_password: md5Hex)) {
                if response.isOk() {
                    result = true
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                    banner.show()
                }
            }
            completion(result)
        }
    }
    
    private func signInInternal(password: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            let idMe = User.getMyPin() as String?
            let p_password = password
            let md5Hex = p_password
            var result: Bool = false
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getSignInApiInternal(p_name: idMe!, p_password: md5Hex)) {
                if response.isOk() {
                    result = true
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                    banner.show()
                }
            }
            completion(result)
        }
    }
    
    private func changePasswordAdmin(oldPassword: String, newPassword: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            let idMe = User.getMyPin() as String?
            let p_password = oldPassword
            let n_password = newPassword
            let md5Hex = p_password
            let md5HexNew = n_password
            var result: Bool = false
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getChangePasswordAdmin(p_f_pin: idMe!, pwd_en: md5HexNew, pwd_old: md5Hex)) {
                if response.isOk() {
                    result = true
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                    banner.show()
                }
            }
            completion(result)
        }
    }
    
    private func changePasswordInternal(oldPassword: String, newPassword: String, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            let idMe = User.getMyPin() as String?
            let p_password = oldPassword
            let n_password = newPassword
            let md5Hex = p_password
            let md5HexNew = n_password
            var result: Bool = false
            if let response = Nexilis.writeSync(message: CoreMessage_TMessageBank.getChangePasswordInternal(p_f_pin: idMe!, pwd_en: md5HexNew, pwd_old: md5Hex)) {
                if response.isOk() {
                    result = true
                }
                DispatchQueue.main.async {
                    if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "11" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Username or password does not match".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                        banner.show()
                    } else if response.getBody(key: CoreMessage_TMessageKey.ERRCOD, default_value: "99") == "20" {
                        let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                        imageView.tintColor = .white
                        let banner = FloatingNotificationBanner(title: "Invalid password".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                        banner.show()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let imageView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
                    imageView.tintColor = .white
                    let banner = FloatingNotificationBanner(title: "Unable to access servers".localized(), subtitle: nil, titleFont: UIFont.systemFont(ofSize: 16), titleColor: nil, titleTextAlign: .left, subtitleFont: nil, subtitleColor: nil, subtitleTextAlign: nil, leftView: imageView, rightView: nil, style: .danger, colors: nil, iconPosition: .top)
                    banner.show()
                }
            }
            completion(result)
        }
    }
}

// MARK: - Item

struct Item: Hashable {
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.title == rhs.title
    }
    
    var icon: UIImage?
    var title = ""
    
    static var sections: [String] {
        return ["Personal", "Config", "Call", "Version"]
    }
    
    static var menus: [String: [Item]] = [:]
    
    static func menuFor(section: Int) -> [Item] {
        let sec = sections[section]
        if let arr = menus[sec] {
            return arr
        }
        return []
    }
    
}

extension SettingTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == languagePickerView {
            return language.count
        }
        else {
            return fontSizeSelection.count
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 60
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 10, height: 30))
        if pickerView == languagePickerView {
            label.text = (language[row]).keys.first
        }
        else {
            label.text = (fontSizeSelection[row]).keys.first
        }
        label.sizeToFit()
        return label
    }
}
